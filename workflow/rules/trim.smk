rule trim_pe:
    input:
        r1="resources/SRA/{accession}_1.fastq.gz",
        r2="resources/SRA/{accession}_2.fastq.gz",
        iclip="resources/TruSeq3-PE.fa",
    output:
        tp1="results/{accession}/01_{accession}_trim_1_paired.fq.gz",
        tp2="results/{accession}/01_{accession}_trim_2_paired.fq.gz",
        tup1="results/{accession}/01_{accession}_trim_1_unpaired.fq.gz",
        tup2="results/{accession}/01_{accession}_trim_2_unpaired.fq.gz",
        check="results/{accession}/01_{accession}_trim_pe.done",
    log:
        logO="logs/trim_pe/{accession}.log",
        logE="logs/trim_pe/{accession}.err.log",
    conda:
        "../envs/trimmomatic.yaml"
    threads: 4
    shell:
        """
        trimmomatic PE -threads {threads} -phred33 {input.r1} {input.r2} {output.tp1} {output.tup1} {output.tp2} {output.tup2} ILLUMINACLIP:{input.iclip}:2:30:10:2:True LEADING:3 TRAILING:3 MINLEN:36 > {log.logO} 2> {log.logE}
        touch {output.check}
        """


rule trim_se:
    input:
        r="resources/SRA/{accession}.fastq.gz",
        iclip="resources/TruSeq3-SE.fa",
    output:
        tp="results/{accession}/01_{accession}_trim_single.fq.gz",
        check="results/{accession}/01_{accession}_trim_se.done",
    log:
        logO="logs/trim_se/{accession}.log",
        logE="logs/trim_se/{accession}.err.log",
    conda:
        "../envs/trimmomatic.yaml"
    threads: 4
    shell:
        """
        trimmomatic SE -threads {threads} -phred33 {input.r} {output.tp} ILLUMINACLIP:{input.iclip}:2:30:10:2:True LEADING:3 TRAILING:3 MINLEN:36 > {log.logO} 2> {log.logE}
        touch {output.check}
        """
