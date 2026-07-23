# Workflow Rules Documentation

This document describes the individual rules and steps in the tobamo-snakemake workflow.

## Overview

The workflow consists of several rule files located in `workflow/rules/`:

- `trim.smk` - Quality control and adapter trimming
- `assembly.smk` - De novo assembly
- `diamond.smk` - Protein database searches  
- `filtering.smk` - Contig filtering and processing
- `megan6.smk` - Taxonomic classification

## Rule Details

### 1. Quality Control and Trimming (`trim.smk`)

#### `trim_pe` - Paired-end read trimming
- **Input:** Raw paired-end FASTQ files from SRA
- **Tool:** Trimmomatic
- **Parameters:**
  - ILLUMINACLIP: Adapter removal
  - LEADING:3 TRAILING:3: Quality trimming
  - MINLEN:36: Minimum read length
- **Output:** Paired and unpaired trimmed reads

#### `trim_se` - Single-end read trimming  
- **Input:** Raw single-end FASTQ files
- **Tool:** Trimmomatic
- **Output:** Trimmed single-end reads

### 2. Assembly (`assembly.smk`)

#### `megahit_pe` - MEGAHIT paired-end assembly
- **Input:** Trimmed paired-end reads
- **Tool:** MEGAHIT
- **Parameters:** Optimized for metagenomic data
- **Output:** Assembled contigs

#### `megahit_se` - MEGAHIT single-end assembly
- **Input:** Trimmed single-end reads
- **Tool:** MEGAHIT
- **Output:** Assembled contigs

#### `spades_isolate_pe` - SPAdes paired-end assembly
- **Input:** Trimmed paired-end reads
- **Tool:** SPAdes (isolate mode)
- **Output:** Alternative assembly contigs

#### `spades_isolate_se` - SPAdes single-end assembly
- **Input:** Trimmed single-end reads  
- **Tool:** SPAdes (isolate mode)
- **Output:** Alternative assembly contigs

### 3. Contig Processing (`filtering.smk`)

#### `unique_contigs` - Combine and deduplicate contigs
- **Input:** MEGAHIT and SPAdes assemblies
- **Process:** 
  - Combines contigs from both assemblers
  - Removes duplicates and short sequences
  - Filters by minimum length
- **Output:** Unique contig set

#### `filter_contigs` - Apply quality filters
- **Input:** Unique contigs
- **Process:**
  - Length filtering
  - Quality score filtering
  - Coverage filtering
- **Output:** High-quality filtered contigs

### 4. Database Searches (`diamond.smk`)

#### `diamond_tpdb2` - Tobamovirus protein search
- **Input:** Filtered contigs
- **Database:** `resources/tpdb2.dmnd` (tobamovirus proteins)
- **Tool:** Diamond BLASTx (`-k 20`, default sensitivity/e-value)
- **Fallback:** if the input FASTA is empty, `resources/empty.daa` is copied through instead of running Diamond
- **Output:** Viral protein matches (`.daa`)

#### `diamond_nr` - NCBI NR protein search
- **Input:** Only the contigs that had a `diamond_tpdb2` hit (selected via `select_contigs.py`)
- **Database:** `resources/nr.dmnd` (NCBI non-redundant)
- **Tool:** Diamond BLASTx (`-k 20 --unal 1`, default sensitivity/e-value)
- **Output:** Taxonomic protein matches (`.daa`) + tabular hit info (`.tsv`)

### 5. Taxonomic Classification (`megan6.smk`)

#### `meganizer` - Annotate Diamond NR results with taxonomy
- **Input:** `06_{accession}_diamond_nr.daa`
- **Tool:** MEGAN6 `daa-meganizer`
- **Process:** copies the `.daa` file, then annotates it in place against `resources/megan-map-Feb2022.db` (skipped if the file has zero hits)
- **Output:** `07_{accession}_meganizer_tpdb2.daa` (same `.daa` format, now taxonomy-annotated)

#### `megan_cli_export` - Export taxonomic classification tables
- **Input:** `07_{accession}_meganizer_tpdb2.daa`
- **Tool:** MEGAN6 `daa2info`
- **Process:** exports per-read taxonomy and per-class read counts
- **Output:** `08_{accession}_meganizer_tpdb2_read_classification.tsv` + `08_{accession}_meganizer_tpdb2_class_count.tsv`

#### `megan6_concat` - Build final per-sample results table
- **Input:** the read-classification TSV above, plus the tpdb2-selected FASTA and both Diamond info TSVs (tpdb2 + NR)
- **Tool:** `workflow/scripts/megan6_concat.py`
- **Process:** merges taxonomy, sequence, and both search results into one table
- **Output:** `09_{accession}_megan6_results.csv` (final per-sample results file)

## Resource Requirements

### Memory Requirements by Rule

> **Note:** The following memory requirements are estimates based on typical usage patterns and may vary depending on your specific data size, system configuration, and input parameters. Monitor actual resource usage and adjust accordingly for your environment.

| Rule | Memory | Notes |
|------|--------|--------|
| trim_pe/se | 4GB | Per sample |
| megahit_* | 16-32GB | Depends on data size |
| spades_* | 32-64GB | Memory-intensive |
| diamond_* | 8-16GB | Depends on database size |
| megan6_* | 8GB | Per sample |

### Thread Usage

| Rule | Threads | Scalability |
|------|---------|-------------|
| trim_* | 4 | Good |
| megahit_* | 8-16 | Excellent |
| spades_* | 8-16 | Good |
| diamond_* | 8-32 | Excellent |
| megan6_* | 1-4 | Limited |

## Runtime Estimates

Approximate runtime for different dataset sizes:

### Single Sample (typical SRA run)
- Trimming: 10-30 minutes
- Assembly: 1-4 hours
- Diamond searches: 2-8 hours
- MEGAN analysis: 30-60 minutes
- **Total: 4-13 hours per sample**

### Full Dataset (253 samples)
- With 32 cores: ~2-4 weeks
- With 64 cores: ~1-2 weeks
- Bottlenecks: Assembly and Diamond NR search

## Workflow Dependencies

```mermaid
graph TD
    A[SRA Data] --> B[trim_pe/se]
    B --> C[megahit_pe/se]
    B --> D[spades_isolate_pe/se]
    C --> E[unique_contigs]
    D --> E
    E --> F[filter_contigs]
    F --> G[diamond_tpdb2]
    F --> H[diamond_nr]
    G --> I[meganizer]
    H --> I
    I --> J[megan_cli_export]
    J --> K[megan6_concat]
```

## Error Handling

### Common Rule Failures

1. **Assembly failures:**
   - Usually due to insufficient memory
   - Check available RAM vs. requirements
   - Consider reducing thread count

2. **Diamond search timeouts:**
   - Large NR database searches can be slow
   - Monitor disk I/O and memory usage
   - Consider using faster storage (SSD)

3. **MEGAN processing errors:**
   - Check input file formats
   - Verify database file integrity
   - Ensure sufficient temporary space

### Recovery Strategies

```bash
# Restart failed jobs only
snakemake --use-conda -c32 -p -k --rerun-incomplete

# Force rerun specific rule
snakemake --use-conda -c32 -p -R diamond_nr

# Debug specific sample
snakemake --use-conda -c4 -p results/SRR1234567/09_SRR1234567_megan6_results.csv
```

## Customization

### Modifying Parameters

Edit rule files to customize:

1. **Quality thresholds:**
```snakemake
# In trim.smk
LEADING:3 TRAILING:3 MINLEN:36  # Adjust quality parameters
```

2. **Assembly parameters:**
```snakemake
# In assembly.smk
--min-contig-len 200  # Adjust minimum contig length
```

3. **Search sensitivity:**
```snakemake
# In diamond.smk
-k 20  # max target sequences per query; add e.g. --sensitive/--ultra-sensitive or --evalue as needed
```

### Adding New Rules

To add custom processing steps:

1. Create new rule file in `workflow/rules/`
2. Include in main `Snakefile`
3. Update dependencies and outputs
4. Test with dry run

## Performance Optimization

### For Different Systems

**High-memory systems:**
- Increase assembly memory allocation
- Run more samples in parallel

**High-CPU systems:**
- Increase thread counts for parallel rules
- Optimize Diamond search parallelization

**Storage-limited systems:**
- Clean intermediate files regularly
- Use temporary directories for large files
- Compress outputs when possible
