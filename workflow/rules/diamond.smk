rule diamond_tpdb2:
    input:
        "results/{accession}/04_{accession}_contigs_filtered.fasta",
    output:
        "results/{accession}/05_{accession}_diamond_tpdb2.daa",
    log:
        logO="logs/diamond_tpdb2/{accession}.log",
        logE="logs/diamond_tpdb2/{accession}.err.log",
    benchmark:
        "results/{accession}/05_{accession}_benchmark_diamond_tpdb2.txt"
    conda:
        "../envs/diamond-megan.yaml"
    threads: 2
    shell:
        """
        if [ -s {input} ]; then
            diamond blastx --threads 10 -d resources/tpdb2.dmnd -k 20 -q {input} --daa {output} > {log.logO} 2> {log.logE}
        else
            cp -f resources/empty.daa {output}
        fi
        """


rule diamond_nr:
    input:
        d="results/{accession}/05_{accession}_diamond_tpdb2.daa",
        f="results/{accession}/04_{accession}_contigs_filtered.fasta",
    output:
        info="results/{accession}/06_{accession}_diamond_info.tsv",
        selected="results/{accession}/06_{accession}_diamond_tpdb2_selected.fasta",
        out="results/{accession}/06_{accession}_diamond_nr.daa",
    log:
        logO="logs/diamond_nr/{accession}.log",
        logE="logs/diamond_nr/{accession}.err.log",
    benchmark:
        "results/{accession}/06_{accession}_benchmark_diamond_nr.txt"
    conda:
        "../envs/diamond-megan.yaml"
    threads: 3
    shell:
        """
        diamond view --daa {input.d} --outfmt 6 > {output.info}
        python workflow/scripts/select_contigs.py {input.f} {output.info} {output.selected} > {log.logO} 2> {log.logE}
        if [ -s {output.info} ]; then
            diamond blastx -d resources/nr.dmnd -q {output.selected} --threads 10 -k 20 --unal 1 --daa {output.out} >> {log.logO} 2>> {log.logE}
        else
            cp -f {input.d} {output.out}
        fi
        """


rule diamond_nr_get_info:
    input:
        "results/{accession}/06_{accession}_diamond_nr.daa",
    output:
        "results/{accession}/06_{accession}_diamond_nr_info.tsv",
    log:
        logO="logs/diamond_nr/{accession}_info.log",
        logE="logs/diamond_nr/{accession}_info.err.log",
    conda:
        "../envs/diamond-megan.yaml"
    threads: 2
    shell:
        """
        diamond view --daa {input} --outfmt 6 > {output}
        """
