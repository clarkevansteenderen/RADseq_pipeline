# RADseq Pipeline
## 🧬 **Linux and R scripts for a RADseq analysis pipeline**

Contact Clarke van Steenderen at vsteenderen@gmail.com or clarke.vansteenderen@ru.ac.za for queries
<br><br> 
                        
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

We ended up requesting datashring via BaseSpace.

## File organisation

The main project folder should contain a folder for each plate's fastq.gz data (here **plate_1** and **plate_2**), and a **barcodes** folder, containing the internal indexes for the samples on each plate (here internal_indexes_plate_1.txt and internal_indexes_plate_2.txt), and the population assignments (pops_all.txt file). You need to create the internal index and populations files beforehand, using the R scripts provided in the **R_scripts** folder (internal_index_generator.R and pop_file_generator.R). The internal_index_ref.xlsx file is universal, assuming that the same internal indexes are used for all projects. Otherwise, change this accordingly. The pop_file_generator.R script will need the relevant sample information (sample_info.xlsx) for the particular project. Once these files have been generated, your project file structure should look like this for two plates: 

```plaintext
your_repository/  
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
```

For clarity, one plate of data will look like this:

```plaintext
your_repository/  
└── your_RADseq_data_folder/  
    ├── plate_1/  
    │   ├── filenameA_R1_001.fastq.gz  
    │   └── filenameA_R2_001.fastq.gz  
    └── barcodes/  
    │   ├── internal_indexes_plate_1.txt     
    │   └── pops_all.txt  
```

## Viewing data - quick overview

**Read 1:**

```
zcat plate_1/filenameA_R1_001.fastq | head
```

Example output:

@LH00504:37:22MMNWLT3:2:1101:48146:1016 1:N:0:ACGTTACC+TTGTCGGT
TNATGGTCAATCGGGTGGAAATGTGGGGTGTAGGCTGCCTGGCCGAGCGGCCAAAGTGCTGATGCTGCTGATTTGGGGCGCCTGACCGGGCGCTTTTGCACAAACTGTGCTGCACACCCAACTAATGACTTATGGAGCGTTTTNCACTAT
+
I#IIIIII-99I9IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII9IIIIIIIIIIIIIIIIIIIIIII9IIIIIIIIIIIIIIIII9IIIIIIII9IIIIIIIIII#9III9I
@LH00504:37:22MMNWLT3:2:1101:48164:1016 1:N:0:ACGTTACC+TTGTCGGT
TNATGGTCAATCGGGTGGAAATGTGGGGTGTAGGCTGCCTGGCCGAGCGGCCAAAGTGCTGATGCTGCTGATTTGGGGCGCCTGACCGGGCGCTTTTGCACAAACTGTGCTGCACACCCAACTAATGACTTATGGAGCGTTTTTAACTAT

**Read 2:**

```
zcat plate_1/filenameA_R2_001.fastq | head
```

@LH00504:37:22MMNWLT3:2:1101:48146:1016 2:N:0:ACGTTACC+TTGTCGGT
GNTCGTTGTAATTCAATGATCTCAAGTTATGTGCACAAATTGGAACCAACGACTTAGCCTTGTGTTCTTGCCATTTTGACACCTGTTCGATGTTTCGGCTATAACTTCTTCGTTTGCGCTCTAAATGAGGCAGTTCAAGAGGCNGTGNAA
+
I#IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII-I-IIIIIIIIIIIIIIIIIIIIIIIIII9IIIIIIIIIIIIIIIIIIIIIII-IIIII9IIIIIIIIIIIII-IIIIII-IIIIIIII-IIII9IIIII#-II#-I
@LH00504:37:22MMNWLT3:2:1101:48164:1016 2:N:0:ACGTTACC+TTGTCGGT
GNTCGTTGTAATTCAATGATCTCAAGTTATGTGCACAAATTGGAAACAACGACTTAGCCTTGTGTTCTTGCCATTTTGACACCTGTTCGATGTTTCGGCTATAACTTCTTCGTTTGAGCTCTAAATGAGGCAGTTCAAGAGGCNGTGNAA

# 🗒️ Scripts

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

## 🔵 DENOVO (no reference genome)

### 🔵 Assembly: denovo

### 🔵 Additional population assignment/s

## 🟡 REFERENCE GENOME

### 🟡 Preparing a reference genome (if available!)

### 🟡 Assembly: reference genome

### 🟡 Additional population assignments

## DOWNSTREAM

### fastSTRUCTURE

