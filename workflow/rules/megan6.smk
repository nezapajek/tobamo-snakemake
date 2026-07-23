rule meganizer:
    input:
        "results/{accession}/06_{accession}_diamond_nr.daa",
    output:
        "results/{accession}/07_{accession}_meganizer_tpdb2.daa",
    log:
        logO="logs/meganizer/{accession}.log",
        logE="logs/meganizer/{accession}.err.log",
    benchmark:
        "results/{accession}/07_{accession}_benchmark_meganizer_tpdb2.txt"
    conda:
        "../envs/diamond-megan.yaml"
    threads: 3
    shell:
        """
        cp {input} {output}
        if [[ $(diamond view --daa {output} | wc -l) -ge 1 ]]; then
            daa-meganizer --threads {threads} -i {output} -mdb resources/megan-map-Feb2022.db -supp 0 > {log.logO} 2> {log.logE}
        fi
        """


rule megan_cli_export:
    input:
        "results/{accession}/07_{accession}_meganizer_tpdb2.daa",
    output:
        taxon="results/{accession}/08_{accession}_meganizer_tpdb2_read_classification.tsv",
        class_count="results/{accession}/08_{accession}_meganizer_tpdb2_class_count.tsv",
    log:
        logO="logs/megan_cli_export/{accession}.log",
        logE="logs/megan_cli_export/{accession}.err.log",
    conda:
        "../envs/diamond-megan.yaml"
    shell:
        """
        daa2info -i {input} -r2c Taxonomy -p -o {output.taxon} > {log.logO} 2> {log.logE}
        daa2info -i {input} -c2c Taxonomy -p -o {output.class_count} >> {log.logO} 2>> {log.logE}
        """


rule megan6_concat:
    input:
        megan="results/{accession}/08_{accession}_meganizer_tpdb2_read_classification.tsv",
        fasta="results/{accession}/06_{accession}_diamond_tpdb2_selected.fasta",
        info_tpdb2="results/{accession}/06_{accession}_diamond_info.tsv",
        info_nr="results/{accession}/06_{accession}_diamond_nr_info.tsv",
    output:
        "results/{accession}/09_{accession}_megan6_results.csv",
    log:
        logO="logs/megan6_concat/{accession}.log",
        logE="logs/megan6_concat/{accession}.err.log",
    conda:
        "../envs/biopython.yaml"
    shell:
        """
        python workflow/scripts/megan6_concat.py {input.megan} {input.fasta} {input.info_tpdb2} {input.info_nr} {output} > {log.logO} 2> {log.logE}
        """
