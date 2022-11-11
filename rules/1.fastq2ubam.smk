#!/usr/bin/env python


rule custom_save_read_group:
    """
    Infer sample name, flow cell and barcode from the input FASTQ produced by Illumina sequencing.
    Write the information representing single read group to a dedicated file.
    """
    input:
        fastq = os.path.join(FILE_PATH,"{sample}_1.fastq")
    output:
        read_group = os.path.join(OUTPUTPATH,"reads/read_group/{sample}.txt") 
    params:
        script = "scripts/save_read_group.py"
    shell:
        """
        python3 \
            {params.script} \
            {input.fastq} \
            {output.read_group} \
            {wildcards.sample} 
        
        """

rule fastq2ubam:
    input:
        read_group = os.path.join(OUTPUTPATH,"reads/read_group/{sample}.txt"), 
        R1=os.path.join(FILE_PATH,"{sample}_1.fastq"),
        R2=os.path.join(FILE_PATH,"{sample}_2.fastq")
    output:
        bam=os.path.join(OUTPUTPATH,"data/ubam/{sample}.unaligned_reads.bam"),
	    bai=os.path.join(OUTPUTPATH,"data/ubam/{sample}.unaligned_reads.bam.bai")
    benchmark:
        os.path.join(OUTPUTPATH,"benchmarks/fastq2ubam/fastq2ubam_{sample}.json")
    params:
        path=OUTPUTPATH,
        tmp=TMP
    shell:
       """ 
        mkdir -p {params.path}/data/ubam/
        RG=$(<{input.read_group})
        RG="${{RG//$' '/ }}"
        RG=$(sed 's/@RG //g' <<< $RG)
        arrRG=(${{RG//' '/ }})
        ID=$(sed 's/ID://g' <<< ${{arrRG[0]}})
        LB=$(sed 's/LB://g' <<< ${{arrRG[1]}})
        PL=$(sed 's/PL://g' <<< ${{arrRG[2]}})
        SM=$(sed 's/SM://g' <<< ${{arrRG[3]}})
        picard FastqToSam \
         FASTQ={input.R1} \
         FASTQ2={input.R2} \
         OUTPUT={output.bam} \
         READ_GROUP_NAME=$ID \
         PLATFORM=$PL\
         PLATFORM_UNIT=$ID \
         LIBRARY_NAME=$LB \
         SAMPLE_NAME=$SM \
         PLATFORM_MODEL=$PL \
         CREATE_INDEX=True \
         TMP_DIR={params.tmp}
	    samtools index {output.bam}
	
        """

