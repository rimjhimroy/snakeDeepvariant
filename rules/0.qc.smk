#!/usr/bin/env python

rule fastqc:
    input:
        R1=os.path.join(FILE_PATH,"{sample}_1.fastq"),
        R2=os.path.join(FILE_PATH,"{sample}_2.fastq")
    output:
        R1_zip=os.path.join(OUTPUTPATH,"analysis/qc/fastqc/{sample}_1_fastqc.zip"),
        R1_html=os.path.join(OUTPUTPATH,"analysis/qc/fastqc/{sample}_1_fastqc.html"),
        R2_zip=os.path.join(OUTPUTPATH,"analysis/qc/fastqc/{sample}_2_fastqc.zip"),
        R2_html=os.path.join(OUTPUTPATH,"analysis/qc/fastqc/{sample}_2_fastqc.html"),
    threads: config["fastqc_threads"]
    params:
        outputpath=os.path.join(OUTPUTPATH,"analysis/qc/fastqc/")
    benchmark:
        os.path.join(OUTPUTPATH,"benchmarks/fastqc/fastqc_{sample}.json")
    shell:
        """
        fastqc --quiet --outdir {params.outputpath} --noextract -t {threads} -f fastq {input.R1} {input.R2}
        """
