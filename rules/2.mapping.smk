rule bwamem:
    input:
        ubam = os.path.join(OUTPUTPATH,"data/ubam/{sample}.unaligned_reads.bam"),
        reference=REFERENCE
    output:
        out=os.path.join(OUTPUTPATH,"analysis/mapping/{sample}.bam")
    benchmark:
        os.path.join(OUTPUTPATH,"benchmarks/SamToFastqAndBwaMem/SamToFastqAndBwaMem_{sample}.json")
    threads: config["bwa_threads"]
    log:
        os.path.join(OUTPUTPATH,"logs/{sample}.bwa.stderr.log")
    params:
        tmp=TMP
    shell:
        """
        # https://www.nature.com/articles/s41467-018-06159-4
        picard SamToFastq \
        INPUT={input.ubam} \
        FASTQ=/dev/stdout \
        INTERLEAVE=true \
        TMP_DIR={params.tmp} \
        NON_PF=true | \
        bwa mem -K 100000000 -p -v 3 -t {threads} -Y {input.reference} /dev/stdin - 2> >(tee {log} >&2) | \
        sambamba view -f bam -l 0 -S /dev/stdin -t {threads} | \
        sambamba sort -m 4GB -t {threads} -o {output.out} /dev/stdin
        """

rule validatebam:
    input:
        os.path.join(OUTPUTPATH,"analysis/mapping/{sample}.bam")
    output:
        os.path.join(OUTPUTPATH,"analysis/qc/validatebam/{sample}_validate.txt")
    benchmark:
        os.path.join(OUTPUTPATH,"benchmarks/validatebam/validatebam_{sample}.json")
    shell:
        """
        gatk ValidateSamFile I={input} MODE=SUMMARY O={output}
        """

rule MergeBamAlignment:
    input:
        unmerged_bam = os.path.join(OUTPUTPATH,"analysis/mapping/{sample}.bam"),
        unmapped_bam = os.path.join(OUTPUTPATH,"data/ubam/{sample}.unaligned_reads.bam"),
        reference = config["fasta_ref"]
    output:
        temp(os.path.join(config["tmpdir"],"{sample}_aligned_coordinatesorted.bam"))
    params:
        tmpdir = config["tmpdir"]
    benchmark:
         os.path.join(OUTPUTPATH,"benchmarks/MergeBamAlignment/MergeBamAlignment_{sample}.json")
    shell:
        """
        gatk --java-options "-Dsamjdk.compression_level=5 -Xms3000m" \
        MergeBamAlignment \
        --SORT_ORDER coordinate \
        --ALIGNED_BAM {input.unmerged_bam}  \
        --UNMAPPED_BAM {input.unmapped_bam} \
        --OUTPUT {output} \
        --REFERENCE_SEQUENCE {input.reference} \
        --INCLUDE_SECONDARY_ALIGNMENTS false \
        --CLIP_ADAPTERS false \
        --MAX_RECORDS_IN_RAM 2000000 \
        --UNMAPPED_READ_STRATEGY COPY_TO_TAG \
        --UNMAP_CONTAMINANT_READS true \
        --TMP_DIR {params.tmpdir} \
        --VALIDATION_STRINGENCY SILENT
        """

rule AddOrReplaceReadGroups:
    input:
        merged = os.path.join(config["tmpdir"],"{sample}_aligned_coordinatesorted.bam"),
        read_group = os.path.join(OUTPUTPATH,"reads/read_group/{sample}.txt"), 
    output:
        bam =  temp(os.path.join(config["tmpdir"],"{sample}_aligned_coordinatesorted_RG.bam"))
    params:
        tmpdir = config["tmpdir"]
    benchmark:
         os.path.join(OUTPUTPATH,"benchmarks/AddOrReplaceReadGroups/AddOrReplaceReadGroups_{sample}.json")
    shell:
        """
        RG=$(<{input.read_group})
        RG="${{RG//$' '/ }}"
        RG=$(sed 's/@RG //g' <<< $RG)
        arrRG=(${{RG//' '/ }})
        ID=$(sed 's/ID://g' <<< ${{arrRG[0]}})
        LB=$(sed 's/LB://g' <<< ${{arrRG[1]}})
        PL=ILLUMINA
        SM=$(sed 's/SM://g' <<< ${{arrRG[3]}})
        
        RUN="gatk AddOrReplaceReadGroups \
        -SO coordinate \
        --RGID $ID \
        --RGPL $PL \
        --RGPU $ID \
        --RGSM $SM\
        --RGLB $LB\
        --CREATE_INDEX true \
        --INPUT {input.merged} \
        --OUTPUT {output.bam} \
        --TMP_DIR {params.tmpdir}"

        echo $RUN
        eval $RUN 
        """

rule MarkDuplicates:
    input:
        os.path.join(config["tmpdir"],"{sample}_aligned_coordinatesorted_RG.bam")
    output:
        bam = os.path.join(OUTPUTPATH,"markdup/{sample}_aligned_duplicates_marked.bam"),
        metrics_filename = os.path.join(OUTPUTPATH,"analysis/mapping/{sample}.duplicate_metrics")
    params:
        tmp = config["tmpdir"]
    benchmark:
         os.path.join(OUTPUTPATH,"benchmarks/MarkDuplicates/MarkDuplicates_{sample}.json")
    shell:
        """
        gatk --java-options "-Dsamjdk.compression_level=5 -Xms24000m -XX:+UseParallelGC -XX:ParallelGCThreads=4" \
        MarkDuplicates \
        --CREATE_INDEX true \
        --INPUT {input} \
        --OUTPUT {output.bam} \
        --METRICS_FILE {output.metrics_filename} \
        --VALIDATION_STRINGENCY SILENT \
        --CREATE_MD5_FILE true \
        --TMP_DIR {params.tmp} 
        """