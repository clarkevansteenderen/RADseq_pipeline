# RADseq Pipeline
## 🧬 **Linux and R scripts for a RADseq analysis pipeline**

Contact Clarke van Steenderen at vsteenderen@gmail.com or clarke.vansteenderen@ru.ac.za for queries
<br><br> 

# Table of Contents
- [Downloading data: FTP method via Linux](#downloading-data-ftp-method-via-linux)
- [File organisation](#file-organisation)
- [Viewing data - quick overview](#viewing-data---quick-overview)
- [Scripts](#scripts)
- [Subsampling](#subsampling)
- [FASTQC](#fastqc)
- [Demultiplexing](#demultiplexing)
- [Barcode file](#barcode-file)
- [ASSEMBLY](#assembly)
- [DENOVO (no reference genome)](#denovo-no-reference-genome)
- [REFERENCE GENOME](#reference-genome)
- [DOWNSTREAM](#downstream)
- [fastSTRUCTURE](#faststructure)
                        
## Downloading data: FTP method via Linux

To access data via the FTP approach, ssh into a DTN (data transfer node) on the HPC. Using ``nohup`` and ``--continue`` ensures that the connection is not interrupted during the downloading process.

``` 
ssh cvansteenderen@DTN.chpc.ac.za
password_here
cd /mnt/lustre/users/cvansteenderen/RADseq_nodiflorum/raw_data_ftp_continue
nohup wget -r -nH --cut-dirs=1 --user=Clarke.vanSteenderen --password=password_here --continue ftp://38.122.175.98:2223 > download.log 2>&1 &
```

Organise folders so that each plate has its own directory, for example:

```plaintext
your_RADseq_data_folder/  
└── your_data_folder/
    ├── plate_1/
    │   ├── filenameA_R1_001.fastq
    │   └── filenameA_R2_001.fastq
    └── plate_2/
        ├── filenameB_R1_002.fastq
        └── filenameB_R2_002.fastq
```

:bulb: **NB: each plate folder has to be named plate_1, plate_2, up to plate_n**

⚠️ I found that very large fastq files did not download completely, despite the log file and md5 sum file saying that it did. The fastqc program did not complete on these larger files, consistently giving this error at about 95% of the run:  

```plaintext
Failed to process file 24292FL-01-01_S1_L008_R2_001.fastq.gz  
uk.ac.babraham.FastQC.Sequence.SequenceFormatException: Ran out of data in the middle of a fastq entry.  Your file is probably truncated  
	at uk.ac.babraham.FastQC.Sequence.FastQFile.readNext(FastQFile.java:187)  
	at uk.ac.babraham.FastQC.Sequence.FastQFile.next(FastQFile.java:129)  
	at uk.ac.babraham.FastQC.Analysis.AnalysisRunner.run(AnalysisRunner.java:77)  
	at java.base/java.lang.Thread.run(Thread.java:833)
```

⚠️ **We ended up requesting datasharing via BaseSpace, which downloaded the full files.**

## ❗ File organisation: get this prepped before running any job scripts ❗

The main project folder should contain a folder for each plate's fastq.gz data (here **plate_1** and **plate_2**), and a **barcodes** folder, containing the internal indexes for the samples on each plate (here internal_indexes_plate_1.txt and internal_indexes_plate_2.txt), and the population assignments (pops_all.txt file). You need to create the internal index and populations files beforehand, using the R scripts provided in the **R_scripts** folder (internal_index_generator.R and pop_file_generator.R). The internal_index_ref.xlsx file is universal, assuming that the same internal indexes are used for all projects. Otherwise, change this accordingly. The pop_file_generator.R script will need the relevant sample information (sample_info.xlsx) for the particular project. Once these files have been generated, your project file structure should look like this for two plates: 

```plaintext
your_repository/
└── job_files/
	├── 1_seqkit_subsampling.job	
	├── 2_fastqc.job
	├── 3_stacks_demultiplex		
	├── 3.1_stacks_demultiplex_postprocess
	├── 4_stacks_denovo.job	
	├── 5_stacks_populations_denovo.job	
	├── 6_bowtie_indexing_refgenome.job			
	├── 7_bowtie_aligning_refgenome.job	
	├── 8_samtools_sort_stats_refgenome.job		
	├── 9_stacks_refgenome.job			
	├── 10_stacks_populations_refgenome.job	
└── ref_genome/	
	├── ncbi_dataset/ (other applicable folders here, if a reference genome is available)	
└── your_RADseq_data_folder/  
    ├── plate_1/  
    │   ├── filenameA_R1_001.fastq.gz  
    │   └── filenameA_R2_001.fastq.gz  
    └── plate_2/  
    │   ├── filenameB_R1_002.fastq.gz  
    │   └── filenameB_R2_002.fastq.gz  
    └── barcodes/  
    │   ├── internal_indexes_plate_1.txt  
    │   ├── internal_indexes_plate_2.txt  
    │   └── pops_all.txt
    └──ref_genome/	
	├── ncbi_dataset/ (other applicable folders here, if a reference genome is available) 

```

For clarity, one plate of data will look like this:

```plaintext
your_repository/
└── job_files/
	├── 1_seqkit_subsampling.job	
	├── 2_fastqc.job
	├── 3_stacks_demultiplex		
	├── 3.1_stacks_demultiplex_postprocess
	├── 4_stacks_denovo.job	
	├── 5_stacks_populations_denovo.job	
	├── 6_bowtie_indexing_refgenome.job			
	├── 7_bowtie_aligning_refgenome.job	
	├── 8_samtools_sort_stats_refgenome.job		
	├── 9_stacks_refgenome.job			
	├── 10_stacks_populations_refgenome.job	
└── your_RADseq_data_folder/  
    ├── plate_1/  
    │   ├── filenameA_R1_001.fastq.gz  
    │   └── filenameA_R2_001.fastq.gz  
    └── barcodes/  
    │   ├── internal_indexes_plate_1.txt     
    │   └── pops_all.txt
    └──ref_genome/	
	├── ncbi_dataset/ (other applicable folders here, if a reference genome is available) 
```

## Viewing data - quick overview

**Read 1:**

```
zcat plate_1/filenameA_R1_001.fastq | head
```

Example output showing the first fragment. The first bold section, **TNATGGTCAAT**, indicates the internal barcode on the Read 1 fragment, and the italics section, *CGG*, indicates the enzyme cut-site. Here, that is the MspI enzyme cut site. The EcoRI cut-site is AATTC.

@LH00504:37:22MMNWLT3:2:1101:48146:1016 1:N:0:**ACGTTACC+TTGTCGGT** ⬅️ external barcode, indicating which plate the fragment came from
**TNATGGTCAAT***CGG*GTGGAAATGTGGGGTGTAGGCTGCCTGGCCGAGCGGCCAAAGTGCTGATGCTGCTGATTTGGGGCGCCTGACCGGGCGCTTTTGCACAAACTGTGCTGCACACCCAACTAATGACTTATGGAGCGTTTTNCACTAT
+
I#IIIIII-99I9IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII9IIIIIIIIIIIIIIIIIIIIIII9IIIIIIIIIIIIIIIII9IIIIIIII9IIIIIIIIII#9III9I

**Read 2:**

```
zcat plate_1/filenameA_R2_001.fastq | head
```

@LH00504:37:22MMNWLT3:2:1101:48146:1016 2:N:0:**ACGTTACC+TTGTCGGT**
**GNTCGTTGT***AATTC*AATGATCTCAAGTTATGTGCACAAATTGGAACCAACGACTTAGCCTTGTGTTCTTGCCATTTTGACACCTGTTCGATGTTTCGGCTATAACTTCTTCGTTTGCGCTCTAAATGAGGCAGTTCAAGAGGCNGTGNAA
+
I#IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII-I-IIIIIIIIIIIIIIIIIIIIIIIIII9IIIIIIIIIIIIIIIIIIIIIII-IIIII9IIIIIIIIIIIII-IIIIII-IIIIIIII-IIII9IIIII#-II#-I

# Scripts

## Summary of the order of job submissions

⚠️ This is assuming that the above folder structure has been correctly set up, with all the correct indexes for samples, and associated population assignments in the **barcodes/** folder.
Each script defaults to the base directory (**BASE_DIR** in the scripts) shown as **your_RADseq_data_folder/** in the directory layout shown above. Be sure to change this to match your file structure before running.

This is an example of the full pipeline. Run each script to completion before running the next, as subsequent jobs often rely on the outputs of the previous job.

### Setting up

```plaintext
ssh -o "ServerAliveInterval 60" cvansteenderen@lengau.chpc.ac.za	
password_here	

cd your_repository/job_files
# on a HPC for example: cd /mnt/lustre/users/cvansteenderen/RADseq_nodiflorum/rawdata/job_files

✔️ # subsample the data into a smaller chunk to use for testing, if you want!
qsub 1_seqkit_subsampling.job

✔️ # run fastqc to get a quality report for your data
# specify how many plates you want to process (here it's set to 1)
qsub -v NUM_PLATES=1 2_fastqc.job 

✔️ # demultiplex samples, using the barcode index file to differentiate between samples
✔️ # check that the process_radtags function adheres to the parameters you want (enzyme choice, fragment length, etc.)
qsub -v NUM_PLATES=1 3_stacks_demultiplex.job

✔️ # process the outputs from the demultiplexing step ➡️ get the demultiplexed samples from all plates into one ready-to-go folder,
# remove abnormally small files, and update the barcodes/pops_all.txt to match the remaining samples
qsub -v NUM_PLATES=1 3.1_stacks_demultiplex_postprocess.job
```

### 🔵 Denovo assembly ▶️ run this if there is no reference genome available

Test run this to see how long the **4_stacks_denovo.job** script takes to process. If you're averaging 5 or 6 samples in 24 to 18 hours, then rather run ustacks, cstacks, sstacks, tsv2bam, gstacks and populations separately, rather than in the all-encompassing **denovo_map.pl** function. This approach is shown below this section.

🚀 For the all-in-one **denovo_map.pl** approach:

```
✔️ # if you do not have a reference genome, run the stacks denovo script via the loop below. Otherwise skip to the refgenome script further down
qsub 4_stacks_denovo.job	

✔️ # run the Stacks populations function again, this time to produce results in other file formats, and also to provide alternative groupings to your samples. E.g. maybe you want to group your samples broadly into
# countries of origin, invasive status, particular province or habitat type, etc. Be sure to add these alternative pop.txt files into the barcodes/ folder, and adjust the job file below accordingly
qsub 5_stacks_populations_denovo.job
```

🚀 If the all-in-one **denovo_map.pl** approach takes too long, you will need to run each Stacks command separately. The **ustacks.job** script below has been adapted so that each sample file in the **ready/** folder is taken individually, and passed into the ustacks function as a separate job. I haven't seen a sample take longer than 6 hours, but change the walltime after experimenting with the data. It seems to work well with ``#PBS -l select=2:ncpus=24`` , and the ``-t`` threads parameter in ustacks set to ``-t 24``.

```
✔️ # run ustacks separately, as this is what seems to require the most memory. You need to run each sample individually, as a separate job
# change the start and end to the range of sample files in the ready/ folder that you want to process. Here we're doing sample files 1 to 10
# provide the full file path to where your samples are
# check the max number of jobs allowed on the CHPC (seems to be 10). Work progressively through all the samples ➡️ change start to 11 and end to 21, until you get to the 84th sample (or however many you have)

# set the walltime dynamically here
WALLTIME="10:00:00"
# specify the sample range
start=1; end=10
# specify the file path to the samples
INFILES=/mnt/lustre/users/cvansteenderen/RADseq_nodiflorum/rawdata/basespace/stacksoutput/combined_plates/ready
# create a list of your samples for reference (you can use this to re-run particular samples that didn't finish due to too little walltime)
ls /mnt/lustre/users/cvansteenderen/RADseq_nodiflorum/rawdata/basespace/stacksoutput/combined_plates/ready/*.1.fq.gz | sed 's|.*/||; s/\.1\.fq\.gz$//' | nl -w2 -s'. '
# 🥳 this submits the job to the scheduler:
find $INFILES -type f -name "*.1.fq.gz" | sed -n "${start},${end}p" | while read file; do sample_name=$(basename "$file" .fq.gz); qsub -N ustacks_${sample_name} -v FILE="$file",SAMPLE_NAME="$sample_name" ustacks_loop.job; done

✔️
qsub cstacks.job
✔️
qsub sstacks.job
✔️
qsub tsv2bam.job
✔️
qsub gstacks.job
✔️ # edit accordingly (if you want additional populations assignments)
qsub 5_stacks_populations_denovo.job

```


### 🟡 With a reference genome available

Once you have a reference genome downloaded, it requires some preprocessing.
```
✔️ # index the genome using bowtie2. Indexing makes the aligning process a lot faster later on, as the genome is broken up into smaller more manageable parts that can be searched through rapidly
qsub 6_bowtie_indexing_refgenome.job

✔️ # align our sample fragments to the reference genome using bowtie2, and convert to BAM files using samtools
qsub 7_bowtie_aligning_refgenome.job

✔️ # sort the BAM files created after aligning in the previous step
qsub 8_samtools_sort_stats_refgenome.job
```

Each script is in the form of a .job file that can be run on a Linux system. These have been tailored to be submitted on a PBS on the CHPC server. Before submitting a script, make sure that the #PBS headers are correct for your particular project by editing the **-o** and **-e** output paths, the project code (**-P**), and your email address (**-M**). Also make sure that you **cd** into the correct directory. For example:

```plaintext
##############################################################
#PBS -l select=2:ncpus=24:mpiprocs=24:mem=120gb
#PBS -P CBBI1682 👈
#PBS -q normal
#PBS -l walltime=5:00:00
#PBS -o /mnt/lustre/users/cvansteenderen/RADseq_nodiflorum/rawdata/seqkitstdout.txt 👈
#PBS -e /mnt/lustre/users/cvansteenderen/RADseq_nodiflorum/rawdata/seqkitstderr.txt 👈
#PBS -N seqkit_subsampling
#PBS -M vsteenderen@gmail.com 👈
#PBS -m abe
##############################################################

module add chpc/BIOMODULES
module add seqkit

# Change the path here accordingly
cd /mnt/lustre/users/cvansteenderen/RADseq_nodiflorum/rawdata 👈

##############################################################
```

## Subsampling

This creates a subset of the larger datafile, so that you can test out your scripts and make sure that everything is working without having to wait hours for it to run on the full dataset. Adjust the number of plates to suit your needs (**NUM_PLATES**), which defaults to 1. Adjust the proportion of the dataset that you want to subsample (**NUM_READS**), defaulted to 0.01% (**NUM_READS=0.0001**). Change the name of the folder to which you want these subsamples to be written to (**SUB_FOLDER**).

## FASTQC

fastqc checks the quality and basic stats of the data, and produces HTML files as output. Change the **BASE_DIR** and **NUM_PLATES** parameters accordingly in the script.

## Demultiplexing

Demultiplexing is the step of extracting each individual sample from the huge data file by searching for its unique index combination (each well of a 96-well plate has a unique barcode/index, as per the lab protocol). The Stacks site details all the software parameters needed to run **process_radtags** here: https://catchenlab.life.illinois.edu/stacks/comp/process_radtags.php 
In this example, we used two restriction enzymes, namely MspI and EcoRI. 

After running **stacks_demultiplex.job**, the file organisation should resemble:

```plaintext
your_repository/  
└── your_RADseq_data_folder/  
    ├── plate_1/  
    │   ├── filenameA_R1_001.fastq.gz  
    │   └── filenameA_R2_001.fastq.gz  
    └── barcodes/  
    │   ├── internal_indexes_plate_1.txt     
    │   └── pops_all.txt
    └── stacksoutput/
```

This is the meat of the job script:

```
process_radtags -P -p ./$PLATE_DIR -b $BARCODE_FILE -o $OUTPUT_DIR -c -q -r -D -t 140 --inline_inline --renz_1 mspI --renz_2 ecoRI --barcode-dist-2 2 --filter-illumina
```

This will generate a folder called **stacks_output**, which will contain a sub-folder for each plate. Each plate folder will contain all the samples that have been demultiplexed.

The **stacks_demultiplex_postprocess.job** script automatically creates another new folder called **combined_plates**, into which it copies all the samples from all the plates to keep them all in the same place. It does this even if there was only one plate, such that the **combined_plates** folder is used downstream regardless. During the cleaning steps in process_radtags, some samples are removed due to low quality. The script also removes sample files with abnormally low sizes. Due to this, the script automatically generates a new file in the barcodes folder (**bothplates_pops.txt**) with the remaining sample names and their assigned populations. Once this is all done, all the processed and read-to-go samples will be in a folder called **ready**, i.e. **./stacksoutput/combined_plates/ready**

### Barcode file

The unique **internal** barcodes for each sample come from this reference table, showing just the first column of a 96-well plate (wells A1 - H1). These are universal, and the same across all projects. Different plates are differentiated by a unique **external** barcodes, otherwise sample A1 on plate 1 will not be distinguishable from sample A1 on plate 2, etc. These internal barcodes come from the supplementary files in the Adapterama III paper (https://pmc.ncbi.nlm.nih.gov/articles/PMC6791345/). We used the i7 iTru EcoRI indexes (Design 1) and i5 iTru ClaI indexes (Design 2) (see the **peerj-07-7724-s003.xlsx** supplementary file). We annealed the upper and lower oligos ourselves in the lab.

We used the external indexes **iTru5_01_A** and **iTru7_101_01** for our one plate (see the **iTru_i5_primers** and **iTru_i7_primers** tabs in the supplementary Adapterama III file).

Internal indexes for the first column of a 96-well plate:

| **row** | **col** | **well** | **i5_index** | **i7_index** |
|---|---|---|---|---|
| A | 1 | A1 | CCGAATAT | CTAACGT |
| B | 1 | B1 | TTAGGCAAT | CTAACGT |
| C | 1 | C1 | AACTCGTCAT | CTAACGT |
| D | 1 | D1 | GGTCTACGTAT | CTAACGT |
| E | 1 | E1 | GATACCAT | CTAACGT |
| F | 1 | F1 | AGCGTTGAT | CTAACGT |
| G | 1 | G1 | CTGCAACTAT | CTAACGT |
| H | 1 | H1 | TCATGGTCAAT | CTAACGT |

💡Notice the additional **AT** on the i5 indexes, and the additional **T** on the i7 indexes. I added these manually, based on inspection of the fragment sequences.

# ASSEMBLY

Once all the fragments have been grouped into their correct sample ID files, the fragments for each sample need to be assembled into partial genome sequences. This can be done with (guided by an existing genome of a close relative or the same species) or without (*denovo*) a reference. Both approaches are provided.

## DENOVO (no reference genome)

### 🔵 Assembly: denovo

The **stacks_denovo.job** script runs the Stacks **denovo_map.pl** function with these paramaters:

```plaintext
denovo_map.pl -m 3 -n 4 -M 3 -T 8 -o ./stacksoutput_denovo --popmap ./barcodes/bothplates_pops.txt --samples ./stacksoutput/combined_plates/ready --rm-pcr-duplicates --paired --min-samples-per-pop 0.75 --min-populations 2 -X "populations:--fstats"

```

### 🔵 Additional population assignment/s

Population assignments are made when denovo_map.pl is run, and so this **stacks_populations_denovo.job** script allows for **populations** to be run again with alternative population assignments (if desired), and additional output formats. For example, perhaps the initial populations file grouped samples into broad categories, for example countries. Perhaps now you want to re-run the analysis, but provide finer-scale categories, such as provinces within countries. Only the popmap file changes.

## REFERENCE GENOME

### 🟡 Preparing a reference genome (if available!)

### 🟡 Assembly: reference genome

### 🟡 Additional population assignments

## DOWNSTREAM

### fastSTRUCTURE

