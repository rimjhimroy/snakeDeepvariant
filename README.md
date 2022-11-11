**How to run:**

1. `conda env create -f environment.yml` 
2. modify config.yaml if needed.
3. create folders `/scratch/rchoudhu/training/slurm_out/` and `/scratch/rchoudhu/training/tmp/` 
4. Activate gatk4 `conda activate gatk4`
5. `snakemake -s SnakeDeepVariant -n -p` 
6. Create reference index in `/home/rchoudhu/Resources/genome` folder:
`gatk --java-options '-Xmx8g -Xms8g' CreateSequenceDictionary -R ref.fasta -O ref.dict`
`samtools faidx ref.fasta`
` bwa index -a bwtsw ref.fasta`

**To run on Slurm HPC:**

`nohup snakemake -s SnakeDeepVariant -p --cluster-config slurm_hpc.json --cluster "sbatch -J {cluster.name} -t {cluster.time} -c {cluster.cpu} --mem={cluster.mem} -p {cluster.partition} -o {cluster.output} -e {cluster.error}" --jobs 100 --latency-wait 5 &`


**To submit everything in one go:**
`snakemake -s SnakeDeepVariant -p -j 9999 --immediate-submit --notemp --cluster-config slurm_hpc.json --cluster "./parseJobID.py {dependencies}" --latency-wait 120`

`snakemake -s SnakeDeepVariant -p -j 9999 --immediate-submit --notemp --cluster-config slurm_hpc.json --cluster "./parseJobID.py {dependencies}" --latency-wait 120 --use-singularity --singularity-args "-B /scratch,/home" --use-conda --conda-frontend conda`

**Clean everything:**

`snakemake clean`