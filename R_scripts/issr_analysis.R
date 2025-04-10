library(magrittr)
library(dplyr)
library(poppr)

setwd("D:/RADseq/nodiflorum/issr")

issr.data = read.csv("ISSR_Nodi_Filtered_amova.csv")

issr.data[issr.data == "?"] = NA
issr.data[, -(1:3)] = lapply(issr.data[, -(1:3)], as.numeric)

# Extract matrix of binary data
binary.matrix = issr.data[, -(1:3)]
colnames(binary.matrix) = paste0("Locus", seq_len(ncol(binary.matrix)))

binary.matrix = binary.matrix %>%
  mutate_all(~ ifelse(is.na(.), "-9", .))

# Convert to genind
gen = adegenet::df2genind(binary.matrix, ploidy = 1, type = "PA",
                           ind.names = issr.data$Sample, NA.char = "-9")

strata(gen) = data.frame(Broad = issr.data$Broad,
                              Country = issr.data$Country)

gen

table(strata(gen, ~Broad))
table(strata(gen, ~Country))

# Run AMOVA on broad groups
amova_result = poppr::poppr.amova(gen, ~Broad/Country)
amova_result

# Get some summary stats
poppr::poppr(gen)

#?poppr::poppr
