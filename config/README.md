# Configuration Guide

This directory contains configuration files for the tobamo virus detection workflow.

## Configuration Files

### `config.yaml`

Main configuration file. The only key currently read by the workflow is `samples`:

```yaml
samples: config/samples_debug.tsv  # Path to sample list
```

By default this repo ships with `samples` pointing at the 2-sample debug set, so a
fresh clone is safe to run immediately. Switch to `config/samples.tsv` for the real,
253-sample production run (see [Basic Configuration](#basic-configuration) below).

### Sample Files

| File | Description | Samples | Use Case |
|------|-------------|---------|----------|
| `samples_debug.tsv` | Debug dataset (1 single-end + 1 paired-end) | 2 | Quick smoke test, troubleshooting |
| `samples.tsv` | Manuscript dataset | 253 | Production run reproducing the published results |

### Sample File Format

Sample files are tab-separated with a single column header:

```tsv
samples
SRR1234567
ERR2345678
DRR3456789
```

**Requirements:**
- First line must be `samples` (header)
- One SRA accession per line
- Supported prefixes: SRR, ERR, DRR
- No empty lines or comments

## Usage Examples

### Basic Configuration

1. **Switch to the production sample set:**
   ```bash
   echo "samples: config/samples.tsv" > config/config.yaml
   ```

2. **Or point at a custom sample file:**
   ```yaml
   samples: config/my_samples.tsv
   ```

### Custom Sample List

1. **Create custom sample file:**
   ```bash
   echo "samples" > config/custom_samples.tsv
   echo "SRR1234567" >> config/custom_samples.tsv
   echo "ERR2345678" >> config/custom_samples.tsv
   ```

2. **Update configuration:**
   ```yaml
   samples: config/custom_samples.tsv
   ```

## Validation

Before running the workflow, validate your configuration:

```bash
# Dry run: checks sample file format and that the whole DAG resolves
snakemake -n --configfile config/config.yaml
```

Downloading the corresponding SRA data is not wired into the Snakemake DAG — run it
explicitly before the dry run above:

```bash
workflow/scripts/download_sra.sh config/samples_debug.tsv   # or config/samples.tsv
```

## Advanced Configuration

**Note:** `config.yaml` currently supports only the `samples` key above — it is read
directly by `workflow/Snakefile` via a plain YAML load. Per-tool parameters like
memory limits or Diamond sensitivity are not yet exposed through `config.yaml`; to
change them, edit the relevant `workflow/rules/*.smk` file directly.

## Troubleshooting

### Common Configuration Issues

1. **Invalid sample format:**
   - Ensure header is exactly `samples`
   - Check for extra spaces or tabs
   - Verify SRA accession format

2. **File path issues:**
   - Use relative paths from project root
   - Ensure sample files exist before running

3. **Memory configuration:**
   - Adjust memory settings for your system
   - Monitor resource usage during runs
