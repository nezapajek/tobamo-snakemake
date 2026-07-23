import sys
import pandas as pd
import re
from Bio import SeqIO

# python megan6_concat.py {input.csv} {input.fasta} {input.info_out} {output}

megan = sys.argv[1]
fasta_file = sys.argv[2]
diamond_info_tpdb2 = sys.argv[3]
diamond_info_nr = sys.argv[4]
results = sys.argv[5]


def fasta_to_dataframe(fasta_file):
    records = SeqIO.parse(fasta_file, "fasta")
    data = [(record.id, str(record.seq)) for record in records]
    return pd.DataFrame(data, columns=["qseqid", "sequence"])


megan_df = pd.read_csv(megan, sep="\t", names=["qseqid", "megan_tax"])
fasta_df = fasta_to_dataframe(fasta_file)

# Define column names
columns = [
    "qseqid",
    "sseqid",
    "pident",
    "length",
    "mismatch",
    "gapopen",
    "qstart",
    "qend",
    "sstart",
    "send",
    "evalue",
    "bitscore",
]

tpdb2_df = pd.read_csv(diamond_info_tpdb2, sep="\t", header=None, names=columns)
nr_df = pd.read_csv(diamond_info_nr, sep="\t", header=None, names=columns)

tpdb2_df.columns = ["tpdb2_" + col if col != "qseqid" else col for col in tpdb2_df.columns]
nr_df.columns = ["nr_" + col if col != "qseqid" else col for col in nr_df.columns]
diamond = pd.concat([nr_df, tpdb2_df])

merged_df = pd.merge(megan_df, diamond, on="qseqid", how="inner").merge(fasta_df, on="qseqid", how="inner")

merged_df["SRR"] = merged_df["qseqid"].str.extract(r"_([A-Za-z0-9]+)$")

# save csv
if not merged_df.empty:
    merged_df.to_csv(results)
else:
    with open(results, "wt") as fout:
        pass
