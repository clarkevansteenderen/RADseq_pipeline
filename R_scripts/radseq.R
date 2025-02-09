library(adegenet) # for dapc
library(vcfR) # for reading in genetic data
library(tidyverse) # for manipulating and plotting data
#BiocManager::install("LEA")
library(LEA) # For sNMF
library(rnaturalearth) #for mapping
library(ggplot2)
library(ggalt)
library(dartR)

##############################################################
# DENOVO OUTPUT
##############################################################

denovo_assembly = vcfR::read.vcfR("denovo/populations_broad_groups/populations.snps.vcf")
denovo_assembly_genlight = vcfR::vcfR2genlight(denovo_assembly)

denovo_assembly_genlight

sample_info = read.delim("bothplates_pops_SA.txt", header = TRUE, sep = "\t")

num.k = adegenet::find.clusters(denovo_assembly_genlight)

dapc = adegenet::dapc(denovo_assembly_genlight, num.k$grp)
adegenet::scatter.dapc(dapc)

dapc_data_df <-
  # as_tibble() converts the ind.coord matrix to a special data frame called a tibble. 
  as_tibble(dapc$ind.coord, rownames = "individual") %>%
  # mutate changes or adds columns to a data frame. Here, we're adding the population and group assignment columns to the data frame
  mutate(population = sample_info$pop,
         group = dapc$grp)

head(dapc_data_df)

dapc_plot <-
  ggplot(dapc_data_df, aes(
    x = LD1,
    y = LD2,
    fill = group
  )) +
  geom_jitter(shape = 21, size = 2.5, height = 5, width = 5) +
  #ggforce::geom_mark_ellipse(aes(label = group, fill = group)) +  # Enhanced ellipses
  #ggrepel::geom_text_repel(aes(label = population), size = 3, max.overlaps = 50) +
  #reverse the color direction to better reflect Prates et al. 2018
  #scale_fill_viridis_d(direction = -1) + 
  scale_fill_manual(values = c("red", "black", "yellow", "green", "blue")) + 
  theme_bw(base_size = 16) +
  theme_classic()

dapc_plot

group1 = dplyr::filter(dapc_data_df, group == 1)
group2 = dplyr::filter(dapc_data_df, group == 2)
group3 = dplyr::filter(dapc_data_df, group == 3)
group4 = dplyr::filter(dapc_data_df, group == 4)
group5 = dplyr::filter(dapc_data_df, group == 5)

###################################################


##############################################################
# REFERENCE GENOME OUTPUT
##############################################################

refgen.alignment.stats = read.delim("refgenome/refgenome_alignment_stats.txt",
                                    header = FALSE)
names(refgen.alignment.stats) = c("id", "percentage")
refgenstats.plot = ggplot(refgen.alignment.stats, aes(x = id, y = percentage, group = 1)) +
  geom_line(lwd = 0.5, colour = "lightblue") +     # Line plot
  geom_point(shape = 21, size = 1, fill = "darkblue", aes(alpha = 0.2)) +    # Points at each K
  labs(x = "Sample", y = "Percentage") +
  theme_classic() +
  scale_y_continuous(breaks = seq(0, 100, by = 10)) +
  coord_cartesian(ylim = c(0, 100)) +
  theme(legend.position = "none") +
  theme(axis.text.x = element_text(angle = 90, hjust = 0.5)) 
ggsave("figures/refgenome_stats.png", refgenstats.plot, width = 8, height = 4, units = "in")

refgenome_assembly = vcfR::read.vcfR("refgenome/populations_broad_groups/populations.snps.vcf")
refgenome_assembly_genlight = vcfR::vcfR2genlight(refgenome_assembly)

refgenome_assembly_genlight

# export dist matrix to open in SplitsTree
# https://devonderaad.github.io/zosterops.rad/splitstree.html
refgenome_assembly_genlight@pop<-as.factor(refgenome_assembly_genlight@ind.names)
sample.div <- StAMPP::stamppNeisD(refgenome_assembly_genlight, pop = FALSE)
#export for splitstree
StAMPP::stamppPhylip(distance.mat=sample.div, 
                     file="refgenome/populations_broad_groups/iceplant_splits.txt")


sample_info = read.delim("bothplates_pops.txt", header = F, sep = "\t")
names(sample_info) = c("id", "pop")

refgen.num.k = adegenet::find.clusters(refgenome_assembly_genlight)
#refgen.num.k = adegenet::find.clusters.genlight(refgenome_assembly_genlight)
plot(refgen.num.k$Kstat)
# Convert to a data frame
kstat_df <- data.frame(
  K = as.numeric(gsub("K=", "", names(refgen.num.k$Kstat))),  # Extract numeric K values correctly
  Kstat = as.numeric(refgen.num.k$Kstat)                      # Kstat values
)
KVALS = ggplot(kstat_df, aes(x = K, y = Kstat)) +
  geom_line(lwd = 0.85, colour = "lightblue") +     # Line plot
  geom_point(shape = 21, size = 2, fill = "darkblue", aes(alpha = 0.2)) +    # Points at each K
  labs(x = "K value", y = "BIC") +
  scale_x_continuous(breaks = 1:8) +
  theme_classic() +
  theme(legend.position = "none")
#ggsave("figures/Kvals.png", KVALS, width = 6, height = 4, units = "in")
KVALS

refgen.dapc = adegenet::dapc(x = refgenome_assembly_genlight,
                             pop = refgen.num.k$grp)

ade4::scatter(refgen.dapc, scree.da=T, bg="white", 
                  posi.pca="topright", legend=TRUE,
        txt.leg=paste("group", 1:2), col=c("darkred","blue","forestgreen","yellow"))

refgen.dapc_data_df <-
  # as_tibble() converts the ind.coord matrix to a special data frame called a tibble. 
  as_tibble(refgen.dapc$ind.coord, rownames = "individual") %>%
  # mutate changes or adds columns to a data frame. Here, we're adding the population and group assignment columns to the data frame
  mutate(population = sample_info$pop,
         group = refgen.dapc$grp)

head(refgen.dapc_data_df)

refgen.dapc_plot <-
  ggplot(refgen.dapc_data_df, aes(
    x = LD1,
    y = LD2,
    fill = group
  )) +
  geom_jitter(shape = 21, size = 3, height = 5, width = 5) +
  #ggforce::geom_mark_ellipse(aes(label = group, fill = group)) +  # Enhanced ellipses
  #ggrepel::geom_text_repel(aes(label = population), size = 3, max.overlaps = 50) +
  #reverse the color direction to better reflect Prates et al. 2018
  #scale_fill_viridis_d(direction = -1) + 
  scale_fill_manual(values = c("#1B9E77", "orange", "black", "#E7298A", "white", "royalblue")) + 
  theme_bw(base_size = 16) +
  theme_bw()

refgen.dapc_plot

refgen.group1 = dplyr::filter(refgen.dapc_data_df, group == 1)
refgen.group2 = dplyr::filter(refgen.dapc_data_df, group == 2)
refgen.group3 = dplyr::filter(refgen.dapc_data_df, group == 3)
refgen.group4 = dplyr::filter(refgen.dapc_data_df, group == 4)
refgen.group5 = dplyr::filter(refgen.dapc_data_df, group == 5)
refgen.group6 = dplyr::filter(refgen.dapc_data_df, group == 6)

########################################################################

# SOME MAPPING

gps.data = read.csv("sample_gps.csv") %>%
  janitor::clean_names() %>%
  mutate(latitude = ifelse(latitude == "None given", NA, latitude),
         longitude = ifelse(longitude == "None given", NA, longitude)) %>%
  dplyr::select(sample_id, latitude, longitude) %>%
  rename(individual = sample_id,
         lat = latitude, lon = longitude)

refgen.dapc_data_df <- refgen.dapc_data_df %>%
  left_join(gps.data, by = "individual")

head(refgen.dapc_data_df)
refgen.dapc_data_df$lat = as.numeric(refgen.dapc_data_df$lat)
refgen.dapc_data_df$lon = as.numeric(refgen.dapc_data_df$lon)

str(refgen.dapc_data_df)

world_map <- rnaturalearth::ne_countries(
  scale = "medium", 
  returnclass = "sf"
) 

# Plot GPS points on world map to check our locality data is correct 
global_distr = ggplot() +
  # Add raster layer of world map 
  geom_sf(data = world_map, alpha = 0.5) +
  # Add GPS points 
  geom_point(
    data = na.omit(refgen.dapc_data_df), 
    size = 3, shape = 21,
    aes(x = lon, y = lat, fill = group),  color = "black"
  )  +
  scale_fill_manual(values = c("#1B9E77", "orange", "black", 
                                 "#E7298A", "white", "royalblue")) +
  # Set world map CRS 
  coord_sf(
    crs = 4326,
    expand = FALSE
  ) + 
  xlab("Longitude") + 
  ylab("Latitude") +
  theme_classic()

global_distr



sa_ext <- rnaturalearth::ne_countries(scale = "medium",
                                      returnclass = "sf") %>%
  # dplyr::filter(name == c("South Africa", "Lesotho", "Swaziland"))
  dplyr::filter(name %in% c("South Africa", "Lesotho", "Swaziland"))

sa_ext = sf::st_set_crs(sa_ext, 4326)

provincial_borders <- ne_states(country = "South Africa", returnclass = "sf")

ggplot() +
  # Add raster layer of world map 
  geom_sf(data = sa_ext, alpha = 0.5) +
  # Add GPS points 
  geom_point(
    data = na.omit(refgen.dapc_data_df), 
    size = 3, shape = 21,
    aes(x = lon, y = lat, fill = group),  color = "black"
  )  +
  scale_fill_manual(values = c("#1B9E77", "orange", "black", 
       "#E7298A", "white", "royalblue")) +
  # Set world map CRS 
  coord_sf(
    xlim = c(15, 34),
    ylim = c(-21, -36),
    crs = 4326,
    expand = FALSE
  ) +
  xlab("Longitude") + 
  ylab("Latitude") +
  theme_classic()

###########################################
# PCA
###########################################

# Perform PCA on genlight object
pca_result <- adegenet::glPca(refgenome_assembly_genlight, nf = 3)  # nf is the number of axes to retain
save(pca_result, file = "figures/pcaresult.RData")

ade4::scatter(pca_result, posi="bottomright")
tre <- ape::nj(dist(as.matrix(refgenome_assembly_genlight)))
tre
ape::plot.phylo(tre, cex = 0.6, type = "phylogram")



# Extract PCA eigen values
pca_eig = as.data.frame(pca_result$eig)
names(pca_eig) = c("eig")
head(pca_eig)
# Plot using ggplot, using row numbers as x-axis
eigvals.plot = ggplot(pca_eig, aes(x = seq_along(eig), y = eig)) +
  geom_bar(stat = "identity", fill = "lightblue") +
  labs(x = "Principal Component (PC)", y = "Eigenvalue") +
  theme_classic() +
  theme(axis.text.x = element_text(angle = 0, hjust = 1))
ggsave("figures/eigvals.png", eigvals.plot, width = 6, height = 4, units = "in")
ggsave("figures/eigvals.svg", eigvals.plot, width = 6, height = 4, units = "in")

# Extract PCA coordinates
pca_scores <- as.data.frame(pca_result$scores)

# Add sample information (assuming row order in both matches)
pca_scores$population <- sample_info$pop  # Add population info if available

my_pal = c("black", "#D95F02", "#1B9E77", "#E7298A", "#666666", "#7570B3", "#66A61E", "royalblue")

# Plot PCA using ggplot
PC1PC2 = ggplot(pca_scores, aes(x = PC1, y = PC2, fill = population)) +
  geom_jitter(shape = 21, size = 3.5, height = 0, width = 0, alpha = 0.5, 
              colour = "black", fill = "black") +
  #geom_point(alpha = 0.45, size = 3) +                      # Size of points
  #scale_fill_manual(values = c(my_pal)) +
  labs(x = "PC1", y = "PC2", title = "PCA of SNPs") +
  theme_classic() +
  geom_hline(yintercept = 0, linetype = "dashed", color = "black") +
  geom_vline(xintercept = 0, linetype = "dashed", color = "black") +
  scale_x_continuous(breaks = seq(-60, 80, by = 10)) +  # Adjust x-axis: from -10 to 10, step 2
  scale_y_continuous(breaks = seq(-50, 50, by = 10)) +
  coord_cartesian(xlim = c(-60, 80), ylim = c(-50, 50))

PC1PC2

PC1PC3 = ggplot(pca_scores, aes(x = PC1, y = PC3, fill = population)) +
  geom_jitter(shape = 21, size = 3.5, height = 0, width = 0, alpha = 0.5, 
              colour = "black", fill = "black") +
  #geom_point(alpha = 0.45, size = 3) +                      # Size of points
  scale_fill_manual(values = c(my_pal)) +
  labs(x = "PC1", y = "PC3", title = "PCA of SNPs") +
  theme_classic() +
  geom_hline(yintercept = 0, linetype = "dashed", color = "black") +
  geom_vline(xintercept = 0, linetype = "dashed", color = "black") +
  scale_x_continuous(breaks = seq(-60, 80, by = 10)) +  # Adjust x-axis: from -10 to 10, step 2
  scale_y_continuous(breaks = seq(-50, 50, by = 10)) +
  coord_cartesian(xlim = c(-60, 80), ylim = c(-50, 50))

PC1PC3

PC2PC3 = ggplot(pca_scores, aes(x = PC2, y = PC3, fill = population)) +
  geom_jitter(shape = 21, size = 3.5, height = 0, width = 0, alpha = 0.5, 
              colour = "black", fill = "black") +
  #geom_point(alpha = 0.45, size = 3) +                      # Size of points
  scale_fill_manual(values = c(my_pal)) +
  labs(x = "PC2", y = "PC3", title = "PCA of SNPs") +
  theme_classic() +
  geom_hline(yintercept = 0, linetype = "dashed", color = "black") +
  geom_vline(xintercept = 0, linetype = "dashed", color = "black") +
  scale_x_continuous(breaks = seq(-60, 80, by = 10)) +  # Adjust x-axis: from -10 to 10, step 2
  scale_y_continuous(breaks = seq(-50, 50, by = 10)) +
  coord_cartesian(xlim = c(-60, 80), ylim = c(-50, 50))

PC2PC3

ggsave("figures/PC1PC2.png", PC1PC2, width = 5, height = 5, units = "in")
ggsave("figures/PC1PC3.png", PC1PC3, width = 5, height = 5, units = "in")
ggsave("figures/PC2PC3.png", PC2PC3, width = 5, height = 5, units = "in")

pca_scores %>%
  dplyr::filter(PC1>30, PC2>10)

pca_scores %>%
  dplyr::filter(PC1>30, PC2<0)

pca_scores %>%
  dplyr::filter(PC1<0)

pca_scores %>%
  dplyr::filter(PC2<0, PC3>30)
pca_scores %>%
  dplyr::filter(PC2< -5, PC3<0)
pca_scores %>%
  dplyr::filter(PC2> -5, PC2< 5)

###############################################################
