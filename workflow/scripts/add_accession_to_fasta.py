import sys
from Bio import SeqIO

#usage: python add_sid_to_FASTA.py results/{wildcards.sid}/{wildcards.sid}_spades_default/contigs.fasta {output.f}

input_file = sys.argv[1]
output_file = sys.argv[2]
sid = sys.argv[3]

print(input_file)
print(output_file)
print(sid)

with open(output_file, "w") as outputs:
    for r in SeqIO.parse(input_file, "fasta"):
        r.id = (r.id + "_" + sid)  # zelo verjetno izgubimo "description", n.pr. >uniqueID description -> >uniqueID_{sid}
        r.description = ""
        SeqIO.write(r, outputs, "fasta")