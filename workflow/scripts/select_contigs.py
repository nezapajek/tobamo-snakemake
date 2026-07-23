import sys
from Bio import SeqIO
import pandas as pd
import os

#usage: python select_contigs.py {input.f} {output.info} {output.selected}

input_file = sys.argv[1]
info = sys.argv[2]
output_file = sys.argv[3]

if os.stat(info).st_size != 0:
    df_ids = pd.read_csv(info, sep='\t', usecols = [0], header=None)
    with open(input_file, "r") as fin, open(output_file, "w") as fout:
        selected_contings = set([el.strip() for el in df_ids[0]])
        records = SeqIO.parse(fin, "fasta")
        out_seq = (r for r in records if r.id in selected_contings)
        SeqIO.write(out_seq, fout, "fasta")
else:
    with open(output_file, 'wt') as fout:
        pass