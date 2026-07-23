#!python
from Bio import SeqIO
import sys
import os

#usage: python filter_FASTA_by_len.py in.fasta out.fasta min_len max_len

fin_name = sys.argv[1]
fout_name = sys.argv[2]
s_len_min = int(sys.argv[3])
s_len_max = int(sys.argv[4])


with open(fin_name, "r") as fin, open(fout_name, "w") as fout:
    in_seq = list(SeqIO.parse(fin, "fasta"))
    out_seq = [r for r in in_seq if s_len_min <= len(r.seq) <= s_len_max]
    too_short = [r for r in in_seq if len(r.seq) < s_len_min]
    SeqIO.write(out_seq, fout, "fasta")

    num_all = len(in_seq)
    num_out = len(out_seq)
    num_short = len(too_short)
    num_long = len(in_seq)-len(too_short)-len(out_seq)

    print(f'Contigs all = {num_all}')
    print(f'Contigs passed = {num_out}')
    print(f'Contigs shorter than {s_len_min} = {num_short}')
    print(f'Contigs longer than than {s_len_max} = {num_long}')