# RADseq_pipeline
Linux scripts for a RADseq analysis pipeline

## Downloading data: FTP method via Linux

``` 
ssh cvansteenderen@DTN.chpc.ac.za
password_here
cd /mnt/lustre/users/cvansteenderen/RADseq_nodiflorum/raw_data_ftp_continue
nohup wget -r -nH --cut-dirs=1 --user=Clarke.vanSteenderen --password=password_here --continue ftp://38.122.175.98:2223 > download.log 2>&1 &
```

Organise folders so that each plate has its own directory, for example:

your_repository/  
├── data/  
│   ├── plate_1/  
│   │   └── filenameA_R1_001.fastq    
│   │   └── filenameA_R2_001.fastq   
│   ├── plate_2/    
│   │   └── filenameB_R1_001.fastq    
│   │   └── filenameB_R2_001.fastq    

## Viewing data - quick overview

**Read 1:**

```
zcat data/file/path/filename_R1_002.fastq | head
```

Example output:

@LH00504:37:22MMNWLT3:2:1101:48146:1016 1:N:0:ACGTTACC+TTGTCGGT
TNATGGTCAATCGGGTGGAAATGTGGGGTGTAGGCTGCCTGGCCGAGCGGCCAAAGTGCTGATGCTGCTGATTTGGGGCGCCTGACCGGGCGCTTTTGCACAAACTGTGCTGCACACCCAACTAATGACTTATGGAGCGTTTTNCACTAT
+
I#IIIIII-99I9IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII9IIIIIIIIIIIIIIIIIIIIIII9IIIIIIIIIIIIIIIII9IIIIIIII9IIIIIIIIII#9III9I
@LH00504:37:22MMNWLT3:2:1101:48164:1016 1:N:0:ACGTTACC+TTGTCGGT
TNATGGTCAATCGGGTGGAAATGTGGGGTGTAGGCTGCCTGGCCGAGCGGCCAAAGTGCTGATGCTGCTGATTTGGGGCGCCTGACCGGGCGCTTTTGCACAAACTGTGCTGCACACCCAACTAATGACTTATGGAGCGTTTTTAACTAT

**Read 2:**

@LH00504:37:22MMNWLT3:2:1101:48146:1016 2:N:0:ACGTTACC+TTGTCGGT
GNTCGTTGTAATTCAATGATCTCAAGTTATGTGCACAAATTGGAACCAACGACTTAGCCTTGTGTTCTTGCCATTTTGACACCTGTTCGATGTTTCGGCTATAACTTCTTCGTTTGCGCTCTAAATGAGGCAGTTCAAGAGGCNGTGNAA
+
I#IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII-I-IIIIIIIIIIIIIIIIIIIIIIIIII9IIIIIIIIIIIIIIIIIIIIIII-IIIII9IIIIIIIIIIIII-IIIIII-IIIIIIII-IIII9IIIII#-II#-I
@LH00504:37:22MMNWLT3:2:1101:48164:1016 2:N:0:ACGTTACC+TTGTCGGT
GNTCGTTGTAATTCAATGATCTCAAGTTATGTGCACAAATTGGAAACAACGACTTAGCCTTGTGTTCTTGCCATTTTGACACCTGTTCGATGTTTCGGCTATAACTTCTTCGTTTGAGCTCTAAATGAGGCAGTTCAAGAGGCNGTGNAA




