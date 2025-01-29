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

⚠️ **We ended up requesting datashring via BaseSpace.**

<br><br> 

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
# remove abnormally small files, update the barcodes/pops_all.txt to match the remaining samples, and create subsets of the demultiplexed samples so that many smaller jobs can be submitted at once
qsub -v NUM_PLATES=1 3.1_stacks_demultiplex_postprocess.job
```

### 🔵 Denovo assembly
```
✔️ # if you do not have a reference genome, run the stacks denovo script via the loop below. Otherwise skip to the refgenome script further down
# in this example, we have ended up with 17 subsetted folders of sample data, each folder containing five samples (the 17th folder contains 4 samples, as there was a total of 84)
# this loop automatically submits a separate job for each of the 17 subsetted data folders, and provides the associated pops.txt file that contains the specific 5 sample IDs with population assignments
# you can select any range of folders: perhaps you just want to do the first 5, then change it to {1..5}
for k in {1..17}; do qsub -N stacks_denovo_${k} -v K=${k},READY_FOLDER=ready_sub${k},POPS=sub${k}_pops.txt 4_stacks_denovo.job; done

✔️ # postprocessing of the denovo outputs (getting all the subsets back into one merged folder for further use)
qsub 4.1_stacks_denovo_postprocess.job

✔️ # run the Stacks populations function again, this time to produce results in other file formats, and also to provide alternative groupings to your samples. E.g. maybe you want to group your samples broadly into
# countries of origin, invasive status, particular province or habitat type, etc. Be sure to add these alternative pop.txt files into the barcodes/ folder, and adjust the job file below accordingly
qsub 5_stacks_populations_denovo.job
```

### 🟡 With a reference genome available
```

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

At this point, running the Stacks denovo job on a very large dataset takes forever (I found that it could take up to 48 hours to process just 10 samples!). The workaround I have implemented is to subdivide all the samples in the **ready/** folder (keeping the original intact, but making copies of the files), so that a new folder is created for every five samples. I.e. If there are 25 samples in the **ready/** folder, five new folders will be created, each containing five samples (or rather, five pairs of files, since there is a R1 and R2 file per sample). These will be called **ready_sub1** through to **ready_sub5**. The structure will look like this:

```plaintext

└── stacksoutput/
    ├── combined_plates/  
    │   ├── ready/  (contains all samples)	
    │   └── ready_sub1/	(contains the first five samples)
    │   └── ready_sub2/ (contains the second five samples)
.....
```

The script also creates subdivided population files in the **barcodes/** folder to match these, so that the denovo_map.pl function gets the correct population assignments for every group of five samples. This way, you can submit multiple jobs to the job queue, and run them all simultaneously.

To submit the stacks_denovo script as a loop for simultaneous jobs, use:

```plaintext
for k in {1..17}; do qsub -N stacks_denovo_${k} -v K=${k},READY_FOLDER=ready_sub${k},POPS=sub${k}_pops.txt 4_stacks_denovo.job; done
```

Where you need to change the ``{1..17}`` part depending on the number of subfolders you have (here, I had 84 samples that were divided into 17 subfolders). 

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

