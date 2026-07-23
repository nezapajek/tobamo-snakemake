# Frequently Asked Questions (FAQ)

## General Questions

### Q: What is tobamo-snakemake?
**A:** tobamo-snakemake is a Snakemake workflow for identifying potential new tobamoviruses from metagenomic sequencing data. It processes SRA (Sequence Read Archive) datasets through quality control, assembly, and taxonomic classification to find viral sequences.

### Q: What type of data does this workflow process?
**A:** The workflow processes:
- Illumina sequencing data from SRA (SRR, ERR, DRR accessions)
- Both paired-end and single-end reads
- Metagenomic datasets from various environmental samples (plant, soil, water, and other environmental samples)

### Q: How long does the analysis take?
**A:** Runtime depends on dataset size:
- **Single sample:** 4-13 hours
- **Debug dataset (2 samples):** well under a day
- **Full dataset (253 samples):** 2-4 weeks with 32 cores

### Q: Does the debug sample set (`samples_debug.tsv`) download faster too?
**A:** No — `fasterq-dump` always downloads the complete SRA run regardless of debug or
production mode. `DEBUG=True` (a flag in `workflow/Snakefile`) only truncates each
downloaded FASTQ to its first 100k lines *after* download, to keep the pipeline itself
fast. Download time is the same either way; only downstream compute time is reduced.

## Installation and Setup

### Q: What are the system requirements?
**A:** Minimum requirements:
- **RAM:** 32GB (64GB+ recommended)
- **Storage:** 500GB free space
- **CPU:** 8+ cores recommended
- **OS:** Linux (Ubuntu 18.04+, CentOS 7+)

### Q: Can I run this on Windows or macOS?
**A:** The workflow is designed for Linux. For other systems:
- **Windows:** Use WSL2 (Windows Subsystem for Linux)
- **macOS:** Should work but untested (some tools may have issues)

## Configuration and Usage

### Q: What sample formats are supported?
**A:** Supported SRA accession formats:
- **SRR** (NCBI SRA)
- **ERR** (European Nucleotide Archive (ENA))
- **DRR** (DNA Data Bank of Japan (DDBJ))

### Q: Can I use local FASTQ files instead of SRA?
**A:** The workflow is designed for SRA data. For local files, you would need to:
1. Place files in `resources/SRA/` with naming convention `{accession}_1.fastq.gz`

### Q: How do I run only specific steps?
**A:** Use Snakemake targets:
```bash
# Run only trimming
snakemake --use-conda -c8 results/{sample}/01_{sample}_trim_pe.done

# Run up to assembly
snakemake --use-conda -c8 results/{sample}/03_{sample}_spades/contigs.fasta

# Run specific sample
snakemake --use-conda -c8 results/SRR1234567/09_SRR1234567_megan6_results.csv
```

## Performance and Optimization

### Q: The workflow is running slowly. How can I speed it up?
**A:** Optimization strategies:
1. **Increase threads if you have available resources:** `snakemake --use-conda -c64`
2. **Use faster storage:** SSD for databases and temp files
3. **Increase memory:** Especially for assembly steps
4. **Use cluster:** Submit to HPC scheduler
5. **Process in batches:** Split large sample lists

### Q: I'm getting out-of-memory errors. What should I do?
**A:** Memory solutions:
1. **Reduce threads:** `snakemake --use-conda -c16`
2. **Increase system RAM** or use swap space
3. **Process fewer samples:** Split sample list
4. **Optimize assembly parameters** in rule files
5. **Use cluster** with more memory per node

### Q: Can I run this on a cluster?
**A:** Yes! But it was not tested with this pipeline. Examples:
```bash
# SLURM cluster
snakemake --cluster "sbatch -c {threads} --mem={resources.mem_mb}" --jobs 100

# With Snakemake profiles
snakemake --profile slurm

# Torque/PBS
snakemake --cluster "qsub -l nodes=1:ppn={threads}"
```

## Results and Output

### Q: What do the output files contain?
**A:** Key output files:
- **`megan6_results_combined.csv`** - All samples combined, taxonomic classifications
- **`09_{sample}_megan6_results.csv`** - Per-sample results
- **`.daa` files** - Diamond search results (binary format, processed by MEGAN tools)
- **`.tsv` files** - Taxonomic classification and count tables from MEGAN
- **FASTA files** - Assembled contigs at various processing stages

### Q: How do I interpret the results?
**A:** The CSV results contain:
- **Contig ID** - Unique identifier for each assembled sequence
- **Taxonomy** - Assigned taxonomic classification
- **Score/E-value** - Quality metrics for matches
- **Length** - Contig sequence length
- See the companion [`tobamo-analysis`](https://github.com/nezapajek/tobamo-analysis) repository for detailed interpretation guides

### Q: No results were found. Is this normal?
**A:** This can be normal because:
- Many samples don't contain detectable viral sequences
- Stringent quality filters remove low-confidence matches
- Some samples may be low quality or contaminated
- Check log files for processing issues

### Q: Can I visualize the results?
**A:** Visualization options:
- Use MEGAN6 GUI to open `.daa` files (after meganizer processing)
- Run the post-processing scripts in the companion [`tobamo-analysis`](https://github.com/nezapajek/tobamo-analysis) repository
- Import CSV files into R, Python, or Excel
- Use built-in Snakemake report: `snakemake --report report.html`

## Troubleshooting

### Q: The workflow failed. How do I debug?
**A:** Debugging steps:
1. **Check log files:** `logs/` directory contains detailed error logs
2. **Rerun with verbose output:** `snakemake --use-conda -c8 -p`
3. **Restart failed jobs:** `snakemake --use-conda -c8 --rerun-incomplete`
4. **Test specific sample:** Focus on one sample to isolate issues
5. **Check system resources:** Monitor RAM, disk space, CPU usage

### Q: "Command not found" errors?
**A:** Common solutions:
1. **Activate conda environment:** `conda activate tobamo-snakemake`
2. **Install missing tools:** Check environment creation was successful
3. **Update conda:** `conda update conda`
4. **Recreate environment:** Delete and recreate conda environment

### Q: SRA download issues?
**A:** SRA troubleshooting:
1. **Check SRA accession validity** - verify IDs exist
2. **Network connectivity** - SRA servers can be slow
3. **Use prefetch manually:** `prefetch SRR1234567`
4. **Check NCBI SRA status** - servers occasionally down
5. **Alternative download methods** - use sra-tools directly

## Advanced Usage

### Q: How do I customize the analysis parameters?
**A:** Edit rule files in `workflow/rules/`:
- **Quality thresholds:** Modify trimming parameters
- **Assembly settings:** Adjust memory and sensitivity
- **Search parameters:** Change e-value cutoffs
- **Filtering criteria:** Modify contig length filters

### Q: Can I add additional analysis steps?
**A:** Yes, create custom rules:
1. Add new rule file in `workflow/rules/`
2. Include in main `Snakefile`
3. Define inputs, outputs, and dependencies
4. Test with dry run before full execution

### Q: How do I contribute to the project?
**A:** Contribution guidelines:
1. **Fork repository** on GitHub
2. **Create feature branch** for changes
3. **Test thoroughly** with small datasets
4. **Submit pull request** with description
5. **Follow code style** (snakefmt formatting)

## Data and Privacy

### Q: Is my data secure?
**A:** Data security considerations:
- All processing is local (no data uploaded)
- SRA data is public by definition
- Generated results remain on your system
- Follow your institution's data policies

### Q: Can I use proprietary/private data?
**A:** For private data:
- Workflow designed for public SRA data
- Local FASTQ files require workflow modification
- Ensure compliance with data use agreements
- Consider data anonymization requirements

## Getting Help

### Q: Where can I get additional support?
**A:** Support channels:
1. **Documentation:** Check README.md and guides
2. **GitHub Issues:** Report bugs and request features
3. **Workflow Catalog:** Snakemake community resources
4. **Scientific Literature:** Related publications and methods

### Q: How do I cite this workflow?
**A:** Citation information:
- Repository URL: https://github.com/nezapajek/tobamo-snakemake
- DOI: [To be added when available]
- Related publications: [To be added]
    - IAPV 2025 conference poster: https://doi.org/10.6084/m9.figshare.30999190
    - ViBioM 2025 conference poster: https://doi.org/10.6084/m9.figshare.30999328

## Updates and Maintenance

### Q: How do I update the workflow?
**A:** Update process:
```bash
# Update repository
git pull origin main

# Update conda environment
conda env update -n tobamo-snakemake

# Check for breaking changes
snakemake -n --configfile config/config.yaml
```

### Q: What if I encounter version compatibility issues?
**A:** Version management:
1. **Pin versions** in conda environment files
2. **Test updates** with small datasets first
3. **Keep backups** of working environments
4. **Check changelog** for breaking changes
5. **Use containers** for reproducibility
