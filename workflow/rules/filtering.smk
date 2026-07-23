rule unique_contigs:
    input:
        iso="results/{accession}/02_{accession}_spades_isolate_contigs.fasta",
        mega="results/{accession}/02_{accession}_megahit_contigs.fasta",
    output:
        comb="results/{accession}/03_{accession}_contigs_combined.fasta",
        out="results/{accession}/03_{accession}_contigs_unique.fasta",
    log:
        logO="logs/unique_contigs/{accession}.log",
        logE="logs/unique_contigs/{accession}.err.log",
    conda:
        "../envs/biopython.yaml"
    threads: 1
    shell:
        """
        cat {input.iso} {input.mega} > {output.comb}
        python workflow/scripts/unique_contigs.py {output.comb} {output.out}  > {log.logO} 2> {log.logE}
        """


rule filter_contigs:
    input:
        "results/{accession}/03_{accession}_contigs_unique.fasta",
    output:
        add_accession="results/{accession}/04_{accession}_contigs_add_accession.fasta",
        filtered="results/{accession}/04_{accession}_contigs_filtered.fasta",
    log:
        logO="logs/filter_contigs/{accession}.log",
        logE="logs/filter_contigs/{accession}.err.log",
    conda:
        "../envs/biopython.yaml"
    threads: 1
    shell:
        """
        python workflow/scripts/add_accession_to_fasta.py {input} {output.add_accession} {wildcards.accession} > {log.logO} 2> {log.logE}
        python workflow/scripts/filter_fasta_by_len.py {output.add_accession} {output.filtered} 600 8000 >> {log.logO} 2>> {log.logE}
        """
