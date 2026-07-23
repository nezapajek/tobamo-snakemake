import sys
from Bio import SeqIO
from Bio.SeqRecord import SeqRecord
from Bio.Seq import Seq

#usage: python unique_contigs.py {input.iso} {input.mega} {output}

fin = sys.argv[1]
fout = sys.argv[2]

seen = set()
records = {}

for record in SeqIO.parse(fin, "fasta"):
    if record.seq not in seen:
        seen.add(record.seq)
        records.setdefault(record.seq, set()).add(record.description.replace(' ','_')) #record.id (do we lose the description of megahit contigs?)

SeqIO.write([SeqRecord(k, id="_".join(v), description='') for k,v in records.items()], fout, "fasta") #Seq(k) --> k; (k=Seq("ACTG"))