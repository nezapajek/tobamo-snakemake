# Snakemake workflow: `tobamo-snakemake`

[![Snakemake](https://img.shields.io/badge/snakemake-≥6.3.0-brightgreen.svg)](https://snakemake.github.io)
[![GitHub actions status](https://github.com/nezapajek/tobamo-snakemake/workflows/Tests/badge.svg?branch=main)](https://github.com/nezapajek/tobamo-snakemake/actions?query=branch%3Amain+workflow%3ATests)
[![Code style: snakefmt](https://img.shields.io/badge/code%20style-snakefmt-000000.svg)](https://github.com/snakemake/snakefmt)

## Overview

A Snakemake workflow for the preparation of a curated catalogue of sequences of possible new tobamoviruses by scanning large accumulated datasets from different metagenomics data repositories.

We integrate the Conda package management system with Snakemake to establish a modular, flexible, and reproducible workflow that ensures consistent software environments and traceable data processing.

**Project Website:** http://projects.nib.si/tobamo/

<p align="center">
  <img src="images/pipeline.png" alt=" Flowchart illustrating a five-stage viral discovery pipeline. The process begins with dataset discovery via viral RNA-dependent RNA polymerase mining, followed by automated assembly and contig discovery using Snakemake. Candidate contigs then undergo parallel tracks for manual curation, clustering for phylogenetic analysis, and automated classification using a supervised machine learning model" width="500">
</p>

This is the second of three repos this project's code/data was split into:

1. [tobamo-analysis](https://github.com/nezapajek/tobamo-analysis) —
   dataset discovery (Serratus PalmID query → 253 candidate SRRs), the step
   upstream of this Snakemake pipeline, plus everything downstream of it:
   manual curation, clustering/phylogenetic placement, and machine-learning
   classification.
2. **tobamo-snakemake** (this repo) — automated assembly and candidate
   contig discovery on those SRRs (quality control, *de novo* assembly,
   similarity search, preliminary taxonomic assignment).
3. [tobamo-supp-data](https://github.com/nezapajek/tobamo-supp-data) —
   supplementary tables, sequence alignments, and the supplementary methods
   document referenced by the article. Archived on Zenodo for a stable,
   citable DOI; not runnable code like the other two.

## Table of Contents

- [Overview](#overview)
- [Documentation](#documentation)
- [Quick Start](#quick-start)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
- [Snakemake Pipeline](#snakemake-pipeline)
- [Output](#output)
- [Analysis](#analysis)
- [Citation](#citation)
- [License](#license)
- [Contact](#contact)

## Documentation

### Complete Documentation

- [Quick Start Guide](QUICKSTART.md) - Get running in 15 minutes
- [Installation Guide](INSTALLATION.md) - Detailed setup instructions
- [Configuration Guide](config/README.md) - Sample and parameter configuration
- [Workflow Rules](workflow/RULES.md) - Detailed workflow documentation
- [FAQ](FAQ.md) - Frequently asked questions and troubleshooting

## Quick Start

```bash
# 1. Clone repository
git clone https://github.com/nezapajek/tobamo-snakemake.git
cd tobamo-snakemake

# 2. Install dependencies
conda create -n tobamo-snakemake snakemake=7.32.4 python=3.10 sra-tools=3.0.6 -c conda-forge -c bioconda
conda activate tobamo-snakemake

# 3. Download SRA data for the shipped debug set (REQUIRED, safe default: 2 samples)
workflow/scripts/download_sra.sh config/samples_debug.tsv

# 4. Dry run to check the workflow resolves
snakemake -n --configfile config/config.yaml

# 5. Real run on the debug set
snakemake --use-conda -c4 -p

# 6. Full production run (253-sample manuscript dataset)
echo "samples: config/samples.tsv" > config/config.yaml
workflow/scripts/download_sra.sh config/samples.tsv
snakemake --use-conda -c32 -p -k
```

`config/config.yaml` ships pointed at `config/samples_debug.tsv` by default, so steps 3-5
above are safe to run immediately on a fresh clone. Step 6 explicitly repoints it at the
full 253-sample dataset used in the manuscript — only do this once you're ready for a
production-scale run (see [Configuration](#configuration)).

**Note on runtime:** downloading SRA data takes the same amount of time whether you use
the debug set's accessions or the full dataset — `fasterq-dump` always downloads the
complete run. Only the debug *pipeline* itself (trimming/assembly/etc.) is fast, because
each debug FASTQ is truncated to its first 100k lines after download.

## Installation

### Prerequisites

- [Conda/Miniconda](https://docs.conda.io/en/latest/miniconda.html)
- [Snakemake ≥6.3.0](https://snakemake.readthedocs.io/)
- Minimum 32GB RAM recommended for the full 253-sample run (the 2-sample debug set runs on a laptop)
- ~500GB free disk space for the full analysis

### Environment Setup

```bash
# Create and activate the Snakemake environment
conda create -n tobamo-snakemake snakemake=7.32.4 python=3.10 sra-tools=3.0.6 -c conda-forge -c bioconda
conda activate tobamo-snakemake
```

Snakemake manages each rule's own tool environment automatically from `workflow/envs/`
when run with `--use-conda` — no separate per-tool installation is needed. The one
exception is `sra-tools`: `workflow/scripts/download_sra.sh` runs outside the Snakemake
DAG (see [Configuration](#configuration)), so `fasterq-dump` must be installed directly
into this environment, as shown above.

Post-processing and the machine-learning classifier are covered in the companion
[`tobamo-analysis`](https://github.com/nezapajek/tobamo-analysis) repository, which has
its own installation instructions.

## Configuration

### Sample Configuration

`config/config.yaml` has a single `samples` key pointing at one of:

- `samples_debug.tsv` - Debug dataset (2 samples, 1 single-end (SE) + 1 paired-end (PE)) - the shipped default
- `samples.tsv` - Manuscript dataset used for production analysis (253 samples)

See [Configuration Guide](config/README.md) for details.

### SRA Data Download

**IMPORTANT:** SRA data must be downloaded before running the workflow.

```bash
# Download SRA data for a given samples file (defaults to config/samples.tsv if omitted)
workflow/scripts/download_sra.sh config/samples_debug.tsv
```

**What this does:**
- Downloads full-size FASTQ files for every sample listed in the given samples file
- Handles both paired-end and single-end sequencing data
- Compresses files and creates download markers
- Skips already downloaded samples (resumable)

**Requirements:**
- SRA Toolkit (`fasterq-dump`) - must be installed into the active conda environment (see [Installation](#installation)); it is not managed by Snakemake's `--use-conda`
- ~10-100GB free space (depending on dataset size)
- Stable internet connection

**Monitor progress:**
```bash
# Check download status
ls -la resources/SRA/

# Count downloaded vs total samples
wc -l config/samples*.tsv
ls resources/SRA/*.downloaded | wc -l
```

### Database Setup

**Note:** Databases need to be downloaded manually
#### Database Downloads

1. **NCBI BLAST Database**
```bash
# Create database directory
mkdir -p blast_db

# Download all BLAST databases
wget --directory-prefix=blast_db --cut-dirs=2 -Anr* ftp://ftp.ncbi.nlm.nih.gov/blast/db/*
```

2. **Tobamovirus Protein Database (tpdb2)**

The source protein set (`resources/tobamo_proteins.fasta`, 2177 curated tobamovirus
protein sequences) ships with this repo, so no external download is needed — just
build the Diamond database from it:
```bash
diamond makedb --in resources/tobamo_proteins.fasta -d resources/tpdb2
```
This creates `resources/tpdb2.dmnd`, which `diamond_tpdb2` requires unconditionally —
the pipeline will fail on the first real sample without it.

3. **MEGAN Mapping Database**
```bash
# Download MEGAN mapping files
wget -P resources/ https://software-ab.cs.uni-tuebingen.de/download/megan6/megan-map-Feb2022.db
```

## Usage

### Basic Usage

The usage of this workflow is described in the [Snakemake Workflow Catalog](https://snakemake.github.io/snakemake-workflow-catalog/?usage=nezapajek%2Ftobamo-snakemake).

### Command Examples

```bash
# Dry run to check workflow
snakemake -n

# Run with the configured samples file
snakemake --use-conda -c8 --configfile config/config.yaml

# Full production run
time snakemake --use-conda -c32 -p -k > output_$(date +%Y-%m-%d).txt 2>&1

# Generate workflow report
snakemake --report report.html
```

## Snakemake Pipeline

The snakemake pipeline consists of 5 main steps:

1. **Quality Control and Trimming** 
   - Tool: [Trimmomatic](http://www.usadellab.org/cms/?page=trimmomatic)
   - Removes adapters and low-quality sequences
   - Handles both paired-end and single-end reads

2. **De Novo Assembly**
   - Tools: [MEGAHIT](https://www.metagenomics.wiki/tools/assembly/megahit) and [SPAdes](https://github.com/ablab/spades)
   - Assembles trimmed reads into contigs
   - Optimized for metagenomic data

3. **Viral Protein Search**
   - Tool: [Diamond](https://bio.tools/diamond) BLASTx
   - Searches against tobamoviral protein sequences (tpdb2.dmnd)
   - Identifies potential viral contigs

4. **Taxonomic Search**
   - Tool: [Diamond](https://bio.tools/diamond) BLASTx
   - Searches against NCBI non-redundant (NR) protein database
   - Provides broader taxonomic context

5. **Taxonomy Assignment**
   - Tool: [MEGAN6](https://uni-tuebingen.de/fakultaeten/mathematisch-naturwissenschaftliche-fakultaet/fachbereiche/informatik/lehrstuehle/algorithms-in-bioinformatics/software/megan6/)
   - Assigns taxonomic classifications
   - Filters and curates results

## Output

### Main Output Files

- **`results/megan6_results_combined.csv`** - Combined results from all samples with taxonomic classifications
- **`results/{accession}/09_{accession}_megan6_results.csv`** - Individual sample results with:
  - Contig sequences and metadata
  - Viral protein search hits (tpdb2 database)
  - NR database taxonomic assignments
  - Quality scores and e-values
  - Contig length and coverage information
- **Intermediate files** - Complete processing chain preserved for reproducibility and debugging

### Output Structure

```
results/
├── megan6_results_combined.csv          # Main combined results from all samples
├── megan6_results_combined_add_nr_taxa.csv  # Combined results with NR taxonomy
└── {SAMPLE_ID}/                          # Individual sample directories (SRR*/ERR*/DRR*)
    │
    ├── 01_*_trim_*.done                  # Trimming completion flags
    ├── 01_*_trim_single.fq.gz            # Single-end trimmed reads (SE samples)
    ├── 01_*_trim_*_paired.fq.gz          # Paired trimmed reads (PE samples: R1, R2)
    ├── 01_*_trim_*_unpaired.fq.gz        # Unpaired trimmed reads (PE samples: R1, R2)
    │
    ├── 02_*_benchmark_*.txt               # Performance benchmarks
    ├── 02_*_spades_isolate_contigs.fasta # SPAdes assembly contigs
    ├── 02_*_megahit_contigs.fasta        # MEGAHIT assembly contigs  
    ├── 02_*_*.no_isolate                 # SPAdes failure flags
    ├── 02_*_*.no_megahit                 # MEGAHIT failure flags
    │
    ├── 03_*_contigs_combined.fasta       # Combined SPAdes + MEGAHIT contigs
    ├── 03_*_contigs_unique.fasta         # Deduplicated combined contigs
    │
    ├── 04_*_contigs_add_accession.fasta  # Contigs with sample ID prefixes
    ├── 04_*_contigs_filtered.fasta       # Length-filtered contigs (600-8000 bp)
    │
    ├── 05_*_benchmark_diamond_tpdb2.txt  # Diamond tpdb2 benchmark
    ├── 05_*_diamond_tpdb2.daa            # Tobamovirus protein search results
    │
    ├── 06_*_benchmark_diamond_nr.txt     # Diamond NR benchmark
    ├── 06_*_diamond_info.tsv             # tpdb2 search summary (tabular)
    ├── 06_*_diamond_tpdb2_selected.fasta # Contigs with viral hits (for NR search)
    ├── 06_*_diamond_nr.daa               # NR protein database search results
    ├── 06_*_diamond_nr_info.tsv          # NR search summary (tabular)
    │
    ├── 07_*_benchmark_meganizer_tpdb2.txt # MEGAN processing benchmark
    ├── 07_*_meganizer_tpdb2.daa          # MEGAN-processed search results
    │
    ├── 08_*_meganizer_tpdb2_read_classification.tsv  # Per-contig taxonomic classification
    ├── 08_*_meganizer_tpdb2_class_count.tsv          # Taxonomic summary counts
    │
    └── 09_*_megan6_results.csv           # Final integrated results (main output)
```

## Analysis

Post-processing, clustering, phylogenetic placement, and the machine-learning
classification model that operate on this workflow's output live in the companion
[`tobamo-analysis`](https://github.com/nezapajek/tobamo-analysis) repository.

### Log Files

Check logs in the `logs/` directory for detailed error information:
- `logs/trim_pe/` - Trimming logs
- `logs/megahit_*/` - Assembly logs  
- `logs/diamond_*/` - Database search logs

## Citation

If you use this workflow in a paper, please cite:

- This repository: `https://github.com/nezapajek/tobamo-snakemake`
- The workflow DOI: [Add DOI when available]
- Related publication: [Add publication when available]

If you publish results based on this workflow, we recommend creating a release-tagged archive (for example via Zenodo) so reviewers can reference an immutable version.

## License

This project is licensed under [LICENSE](LICENSE).

## Contact

For questions and support, please open an issue on GitHub or contact neza.pajekarambasic@fri.uni-lj.si
