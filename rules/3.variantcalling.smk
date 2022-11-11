rule deepvariant_gvcf:
    input:
        bam=os.path.join(OUTPUTPATH,"markdup/{sample}_aligned_duplicates_marked.bam"),
        ref=REFERENCE
    output:
        vcf=os.path.join(OUTPUTPATH,"gvcf_calls/{sample}.vcf.gz"),
        gvcf=os.path.join(OUTPUTPATH,"gvcf_calls/{sample}.g.vcf.gz")
    params:
        model="WGS",   # {wgs, wes, pacbio, hybrid}
        sample="{sample}",
        tmp=config["tmpdir"]
    threads: config["deepvariant_threads"]
    log:
        os.path.join(OUTPUTPATH,"logs/deepvariant/{sample}/stdout.log")
    conda:
        "../env/singularity.yml"
    shell:
        """
        singularity exec --bind /scratch,/home docker://google/deepvariant:1.4.0 \
        /opt/deepvariant/bin/run_deepvariant --model_type WGS \
        --ref {input.ref} --reads {input.bam} --output_vcf {output.vcf} --output_gvcf {output.gvcf} \
        --num_shards {threads} --tmpdir {params.tmp}
        """
