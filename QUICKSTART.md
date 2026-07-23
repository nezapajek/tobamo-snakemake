# Quick Start Guide

Get up and running with tobamo-snakemake in 15 minutes.

## Prerequisites

- Linux system (the 2-sample debug run below is fine on a laptop; the full 253-sample run needs 32GB+ RAM)
- Conda/Miniconda installed
- ~10GB free disk space (for the debug run)

## 1. Installation

```bash
# Clone repository
git clone https://github.com/nezapajek/tobamo-snakemake.git
cd tobamo-snakemake

# Create conda environment
conda create -n tobamo-snakemake snakemake=7.32.4 python=3.10 -c conda-forge -c bioconda
conda activate tobamo-snakemake
```

## 2. Quick Test

`config/config.yaml` already ships pointed at the 2-sample debug set
(`config/samples_debug.tsv` - 1 single-end + 1 paired-end), so no editing is needed
for this step.

```bash
# IMPORTANT: download SRA data first (full-size download; only the pipeline
# itself is shortened in debug mode, see note below)
workflow/scripts/download_sra.sh config/samples_debug.tsv

# Dry run to check workflow
snakemake -n --configfile config/config.yaml

# Run test (should complete in ~10 minutes once data is downloaded)
snakemake --use-conda -c4 -p --configfile config/config.yaml
```

## 3. View Results

```bash
# Check main results file
head results/megan6_results_combined.csv

# Check individual sample results
ls results/*/09_*_megan6_results.csv
```

## 4. Full Production Run

```bash
# Switch to the full manuscript dataset (253 samples)
echo "samples: config/samples.tsv" > config/config.yaml

# Download all SRA data (this may take hours)
workflow/scripts/download_sra.sh config/samples.tsv

# Run full analysis (will take days)
nohup snakemake --use-conda -c32 -p --configfile config/config.yaml > output.log 2>&1 &

# Monitor progress
tail -f output.log
```

## Next Steps

1. **Explore Results:** Check `results/megan6_results_combined.csv`
2. **Customize:** Modify sample lists in `config/`
3. **Scale Up:** Use HPC cluster for large datasets
4. **Post-processing:** Continue with the companion [`tobamo-analysis`](https://github.com/nezapajek/tobamo-analysis) repository for clustering, phylogenetic placement, and ML classification

## Troubleshooting

### Quick Fixes

```bash
# Memory issues - reduce threads
snakemake --use-conda -c8 -p --configfile config/config.yaml

# Restart failed jobs
snakemake --use-conda -c32 -p --configfile config/config.yaml --rerun-incomplete

# Check specific sample
snakemake --use-conda -c4 -p results/SRR1234567/09_SRR1234567_megan6_results.csv
```

### Common Issues

1. **"Command not found"** → Activate conda environment
2. **"Out of memory"** → Reduce thread count or increase system RAM
3. **"Database not found"** → The BLAST/tpdb2/MEGAN databases are **not** downloaded automatically — set them up manually first, see [Database Setup](README.md#database-setup)

## Getting Help

- **Full Documentation:** [README.md](README.md)
- **Installation Issues:** [INSTALLATION.md](INSTALLATION.md)  
- **Configuration:** [config/README.md](config/README.md)
- **Bug Reports:** [GitHub Issues](https://github.com/nezapajek/tobamo-snakemake/issues)
