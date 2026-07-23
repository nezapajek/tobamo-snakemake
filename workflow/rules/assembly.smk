rule spades_isolate_pe:
    input:
        tp1="results/{accession}/01_{accession}_trim_1_paired.fq.gz",
        tp2="results/{accession}/01_{accession}_trim_2_paired.fq.gz",
    output:
        d=temp(directory("results/{accession}/{accession}_spades_isolate")),
        f="results/{accession}/02_{accession}_spades_isolate_contigs.fasta",
    log:
        logO="logs/spades_isolate_pe/{accession}.log",
        logE="logs/spades_isolate_pe/{accession}.err.log",
    benchmark:
        "results/{accession}/02_{accession}_benchmark_spades_isolate_pe.txt"
    conda:
        "../envs/spades.yaml"
    threads: 8
    shell:
        """
        rm -Rf {output.d}
        if [ -e "results/{wildcards.accession}/02_{wildcards.accession}_spades_isolate_pe_contigs.fasta.no_isolate" ]; then
            mkdir -p results/{wildcards.accession}/{wildcards.accession}_spades_isolate
            cp -f resources/empty.fasta results/{wildcards.accession}/{wildcards.accession}_spades_isolate/contigs.fasta
        else
            set +e
            spades.py --isolate --threads {threads} -1 {input.tp1} -2 {input.tp2} -o {output.d} > {log.logO} 2> {log.logE}
            exitcode=$?
            set -e
            if [ $exitcode -ne 0 ]; then
                mkdir -p results/{wildcards.accession}/{wildcards.accession}_spades_isolate
                touch "results/{wildcards.accession}/02_{wildcards.accession}_spades_isolate_pe_contigs.fasta.no_isolate"
                cp -f resources/empty.fasta results/{wildcards.accession}/{wildcards.accession}_spades_isolate/contigs.fasta
            fi
        fi
        cp -f results/{wildcards.accession}/{wildcards.accession}_spades_isolate/contigs.fasta {output.f}
        """


rule spades_isolate_se:
    input:
        tp="results/{accession}/01_{accession}_trim_single.fq.gz",
    output:
        d=temp(directory("results/{accession}/{accession}_spades_isolate")),
        f="results/{accession}/02_{accession}_spades_isolate_contigs.fasta",
    log:
        logO="logs/spades_isolate_se/{accession}.log",
        logE="logs/spades_isolate_se/{accession}.err.log",
    benchmark:
        "results/{accession}/02_{accession}_benchmark_spades_isolate_se"
    conda:
        "../envs/spades.yaml"
    threads: 8
    shell:
        """
        rm -Rf {output.d}
        if [ -e "results/{wildcards.accession}/02_{wildcards.accession}_spades_isolate_se_contigs.fasta.no_isolate" ]; then
            mkdir -p results/{wildcards.accession}/{wildcards.accession}_spades_isolate
            cp -f resources/empty.fasta results/{wildcards.accession}/{wildcards.accession}_spades_isolate/contigs.fasta
        else
            set +e
            spades.py --isolate --threads {threads} -s {input.tp} -o {output.d} > {log.logO} 2> {log.logE}
            exitcode=$?
            set -e
            if [ $exitcode -ne 0 ]; then
                mkdir -p results/{wildcards.accession}/{wildcards.accession}_spades_isolate
                touch "results/{wildcards.accession}/02_{wildcards.accession}_spades_isolate_se_contigs.fasta.no_isolate"
                cp -f resources/empty.fasta results/{wildcards.accession}/{wildcards.accession}_spades_isolate/contigs.fasta
            fi
        fi
        cp -f results/{wildcards.accession}/{wildcards.accession}_spades_isolate/contigs.fasta {output.f}
        """


rule megahit_pe:
    input:
        r1="results/{accession}/01_{accession}_trim_1_paired.fq.gz",
        r2="results/{accession}/01_{accession}_trim_2_paired.fq.gz",
        f="results/{accession}/02_{accession}_spades_isolate_contigs.fasta",
    output:
        d=temp(directory("results/{accession}/{accession}_megahit")),
        f="results/{accession}/02_{accession}_megahit_contigs.fasta",
    log:
        logO="logs/megahit_pe/{accession}.log",
        logE="logs/megahit_pe/{accession}.err.log",
    conda:
        "../envs/megahit.yaml"
    threads: 6
    shell:
        """
        rm -Rf {output.d}
        if [ -e "results/{wildcards.accession}/02_{wildcards.accession}_spades_isolate_pe_contigs.fasta.no_isolate" ]; then
            if [ -e "results/{wildcards.accession}/02_{wildcards.accession}_megahit_contigs.fasta.no_megahit" ]; then
                mkdir -p results/{wildcards.accession}/{wildcards.accession}_megahit
                cp -f resources/empty.fasta results/{wildcards.accession}/{wildcards.accession}_megahit/final.contigs.fa
            else
                set +e
                megahit -t {threads} -1 {input.r1} -2 {input.r2} -o {output.d} > {log.logO} 2> {log.logE}
                exitcode=$?
                set -e
                if [ $exitcode -ne 0 ]; then
                    mkdir -p "results/{wildcards.accession}/{wildcards.accession}_megahit"
                    touch "results/{wildcards.accession}/02_{wildcards.accession}_megahit_contigs.fasta.no_megahit"
                    cp -f resources/empty.fasta "results/{wildcards.accession}/{wildcards.accession}_megahit/final.contigs.fa"
                fi
            fi
        else
            mkdir -p results/{wildcards.accession}/{wildcards.accession}_megahit
            cp -f resources/empty.fasta results/{wildcards.accession}/{wildcards.accession}_megahit/final.contigs.fa
        fi
        cp results/{wildcards.accession}/{wildcards.accession}_megahit/final.contigs.fa {output.f}
        """


rule megahit_se:
    input:
        r="results/{accession}/01_{accession}_trim_single.fq.gz",
        f="results/{accession}/02_{accession}_spades_isolate_contigs.fasta",
    output:
        d=temp(directory("results/{accession}/{accession}_megahit")),
        f="results/{accession}/02_{accession}_megahit_contigs.fasta",
    log:
        logO="logs/megahit_se/{accession}.log",
        logE="logs/megahit_se/{accession}.err.log",
    conda:
        "../envs/megahit.yaml"
    threads: 6
    shell:
        """
        rm -Rf {output.d}
        if [ -e "results/{wildcards.accession}/02_{wildcards.accession}_spades_isolate_se_contigs.fasta.no_isolate" ]; then
            if [ -e "results/{wildcards.accession}/02_{wildcards.accession}_megahit_se_contigs.fasta.no_megahit" ]; then
                mkdir -p results/{wildcards.accession}/{wildcards.accession}_megahit
                cp -f resources/empty.fasta results/{wildcards.accession}/{wildcards.accession}_megahit/final.contigs.fa
            else
                set +e
                megahit -t {threads} -r {input.r} -o {output} > {log.logO} 2> {log.logE}
                exitcode=$?
                set -e
                if [ $exitcode -ne 0 ]; then
                    mkdir -p results/{wildcards.accession}/{wildcards.accession}_megahit
                    touch "results/{wildcards.accession}/02_{wildcards.accession}_megahit_se_contigs.fasta.no_megahit"
                    cp -f resources/empty.fasta results/{wildcards.accession}/{wildcards.accession}_megahit/final.contigs.fa
                fi
            fi
        else
            mkdir -p results/{wildcards.accession}/{wildcards.accession}_megahit
            cp -f resources/empty.fasta "results/{wildcards.accession}/{wildcards.accession}_megahit/final.contigs.fa"
        fi
        cp results/{wildcards.accession}/{wildcards.accession}_megahit/final.contigs.fa {output.f}
        """
