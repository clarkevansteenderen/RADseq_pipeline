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
your_repository/
└── your_data_folder/
    ├── plate_1/
    │   ├── filenameA_R1_001.fastq
    │   └── filenameA_R2_001.fastq
    └── plate_2/
        ├── filenameB_R1_002.fastq
        └── filenameB_R2_002.fastq
```

:bulb: **NB: each plate folder has to be named plate_1, plate_2, up to plate_n**

## Viewing data - quick overview

**Read 1:**

```
zcat data/file/path/filenameA_R1_001.fastq | head
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
zcat data/file/path/filenameA_R2_001.fastq | head
```

@LH00504:37:22MMNWLT3:2:1101:48146:1016 2:N:0:ACGTTACC+TTGTCGGT
GNTCGTTGTAATTCAATGATCTCAAGTTATGTGCACAAATTGGAACCAACGACTTAGCCTTGTGTTCTTGCCATTTTGACACCTGTTCGATGTTTCGGCTATAACTTCTTCGTTTGCGCTCTAAATGAGGCAGTTCAAGAGGCNGTGNAA
+
I#IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII-I-IIIIIIIIIIIIIIIIIIIIIIIIII9IIIIIIIIIIIIIIIIIIIIIII-IIIII9IIIIIIIIIIIII-IIIIII-IIIIIIII-IIII9IIIII#-II#-I
@LH00504:37:22MMNWLT3:2:1101:48164:1016 2:N:0:ACGTTACC+TTGTCGGT
GNTCGTTGTAATTCAATGATCTCAAGTTATGTGCACAAATTGGAAACAACGACTTAGCCTTGTGTTCTTGCCATTTTGACACCTGTTCGATGTTTCGGCTATAACTTCTTCGTTTGAGCTCTAAATGAGGCAGTTCAAGAGGCNGTGNAA

# 🗒️ Scripts

## Subsampling

## FASTQC

## Demultiplexing

# 🔵 DENOVO (no reference genome)

## 🔵 Assembly: denovo

## 🔵 Additional population assignment/s

# 🟡 REFERNCE GENOME

## 🟡 Preparing a reference genome (if available!)

## 🟡 Assembly: reference genome

## 🟡 Additional population assignments

# DOWNSTREAM

## fastSTRUCTURE

