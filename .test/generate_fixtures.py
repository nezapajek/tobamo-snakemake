#!/usr/bin/env python3
"""Generate tiny synthetic CI fixtures for the Tier B (real-execution) test.

Run once from the repo root (`python .test/generate_fixtures.py`); the output
files are committed under `.test/resources/` so CI never needs to regenerate
them and needs no network access to do so.

Design: a made-up ~120 aa "tobamovirus-like" test protein (not a real
sequence) is reverse-translated into a CDS and embedded in two different
1000bp synthetic contigs (one for a paired-end sample, one for single-end).
Overlapping reads are tiled across each contig at high depth so SPAdes/
MEGAHIT can reassemble it, plus a few short fragments that read through into
the real TruSeq3 adapter sequences (from resources/TruSeq3-*.fa) so
Trimmomatic has something real to trim. The same test protein seeds the tiny
Diamond tpdb2/nr databases built at CI time, guaranteeing a real, meaningful
hit end-to-end.
"""
import gzip
import random
import textwrap
from pathlib import Path

random.seed(42)

HERE = Path(__file__).resolve().parent
OUT = HERE / "resources"
OUT.mkdir(parents=True, exist_ok=True)

BASES = "ACGT"

# One codon per amino acid (not codon-optimized; just needs to translate
# correctly in the forward frame diamond blastx will detect).
CODON = {
    "A": "GCT", "R": "CGT", "N": "AAT", "D": "GAT", "C": "TGT",
    "Q": "CAA", "E": "GAA", "G": "GGT", "H": "CAT", "I": "ATT",
    "L": "CTT", "K": "AAA", "M": "ATG", "F": "TTT", "P": "CCT",
    "S": "TCT", "T": "ACT", "W": "TGG", "Y": "TAT", "V": "GTT",
}

TEST_PROTEIN = (
    "MSTLKVDAIVGRVQSANQLARFCKSATEVAGISYGRQEIALVGQHIYDVLAGRPLTAQE"
    "LKKLADQITALTQSVNTQFVDPAVQRAIGDNLASLRTYVSKWISSVQKDFTDGDSAIGS"
)

# Real adapter sequences shipped in resources/TruSeq3-*.fa
PE_ADAPTER_R1 = "TACACTCTTTCCCTACACGACGCTCTTCCGATCT"
PE_ADAPTER_R2 = "GTGACTGGAGTTCAGACGTGTGCTCTTCCGATCT"
SE_ADAPTER = "AGATCGGAAGAGCACACGTCTGAACTCCAGTCAC"

READ_LEN = 100
FRAG_LEN = 250
STEP = 5


def revcomp(seq):
    comp = str.maketrans("ACGT", "TGCA")
    return seq.translate(comp)[::-1]


def random_seq(n):
    return "".join(random.choice(BASES) for _ in range(n))


def build_contig(flank5_len, flank3_len):
    cds = "".join(CODON[aa] for aa in TEST_PROTEIN)
    return random_seq(flank5_len) + cds + random_seq(flank3_len)


def fastq_record(name, seq, qual_char="I"):
    return f"@{name}\n{seq}\n+\n{qual_char * len(seq)}\n"


def write_gz(path, text):
    with gzip.open(path, "wt") as fh:
        fh.write(text)


def write_fasta(path, records):
    with open(path, "w") as fh:
        for name, seq in records.items():
            fh.write(f">{name}\n")
            fh.write("\n".join(textwrap.wrap(seq, 60)) + "\n")


# --- Paired-end sample (SRR0000001) ---
contig_pe = build_contig(300, 340)
r1_records, r2_records = [], []
i = idx = 0
while i + FRAG_LEN <= len(contig_pe):
    frag = contig_pe[i:i + FRAG_LEN]
    r1_records.append(fastq_record(f"SIM.{idx}/1", frag[:READ_LEN]))
    r2_records.append(fastq_record(f"SIM.{idx}/2", revcomp(frag[-READ_LEN:])))
    i += STEP
    idx += 1

# short fragments that read through into adapter (exercises Trimmomatic)
for j, short_len in enumerate([60, 70, 80]):
    frag = contig_pe[:short_len]
    r1 = (frag + PE_ADAPTER_R1)[:READ_LEN]
    r2 = (revcomp(frag) + PE_ADAPTER_R2)[:READ_LEN]
    r1_records.append(fastq_record(f"SIM.adapter{j}/1", r1))
    r2_records.append(fastq_record(f"SIM.adapter{j}/2", r2))

write_gz(OUT / "SRR0000001_1.fastq.gz", "".join(r1_records))
write_gz(OUT / "SRR0000001_2.fastq.gz", "".join(r2_records))

# --- Single-end sample (SRR0000002) ---
contig_se = build_contig(320, 320)
se_records = []
i = idx = 0
while i + READ_LEN <= len(contig_se):
    se_records.append(fastq_record(f"SIM.{idx}", contig_se[i:i + READ_LEN]))
    i += STEP
    idx += 1
for j, short_len in enumerate([50, 65]):
    r = (contig_se[:short_len] + SE_ADAPTER)[:READ_LEN]
    se_records.append(fastq_record(f"SIM.adapter{j}", r))

write_gz(OUT / "SRR0000002.fastq.gz", "".join(se_records))

# --- Tiny Diamond protein databases (built into resources/*.dmnd at CI time) ---
write_fasta(OUT / "tpdb2_test_proteins.fasta", {"test_tobamo_protein": TEST_PROTEIN})

decoys = {
    "decoy_1": "MAKQLEDKVEELLSKNYHLENEVARLKKLVGER",
    "decoy_2": "MSEQNNTEMTFQIQRIYTKDISFEAPNAPHVFQ",
    "decoy_3": "MADEEKLPPGWEKRMSRSSGRVYYFNHITNASQ",
}
nr_records = dict(decoys)
nr_records["test_tobamo_protein_nr_hit"] = TEST_PROTEIN
write_fasta(OUT / "nr_test_proteins.fasta", nr_records)

print(f"Wrote fixtures to {OUT}")
