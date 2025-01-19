setwd("D:/RADseq/nodiflorum")
library(magrittr)

# this is a reference table for the unique internal index combination for each
# well in a 96-well plate

# Note that the i5 index has an extra AT
# and the i7 index has an extra T
# I manually added these, based on the sequencing results
index_reference = readxl::read_excel("internal_index_ref.xlsx")
sample_ids = readxl::read_excel("sample_info.xlsx")

head(index_reference)
head(sample_ids)

# generate a table that has allocated the correct internal index to each sample
matched_samples <- sample_ids %>%
  dplyr::left_join(index_reference, by = "well") %>%
  dplyr::select(sample_id, i5_index, i7_index)

head(matched_samples)

write.table(matched_samples, 
           file = "internal_indexes_plate_1.txt", 
           sep = "\t",             # Use a tab space as the separator
           row.names = FALSE,     # Do not write row names
           col.names = FALSE,      # Write column names
           quote = FALSE,         # Avoid quoting character data
           eol = "\n")            # Ensure Unix line endings

