setwd("D:/RADseq/nodiflorum")
library(magrittr)

# this is a reference table for the unique internal index combination for each
# well in a 96-well plate

# Note that the i5 index has an extra AT
# and the i7 index has an extra T
# I manually added these, based on the sequencing results
pop_info = readxl::read_excel("nodiflorum_sample_localities.xlsx") %>%
  janitor::clean_names()  %>%
  dplyr::select(sample_id, sample_origin)

write.table(pop_info, 
            file = "pops_all.txt", 
            sep = "\t",             # Use a tab space as the separator
            row.names = FALSE,     # Do not write row names
            col.names = FALSE,      # Write column names
            quote = FALSE,         # Avoid quoting character data
            eol = "\n")            # Ensure Unix line endings
