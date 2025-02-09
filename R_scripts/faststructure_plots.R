library(ggplot2)
library(tidyr)
suppressMessages(library(dplyr))
library(RColorBrewer)
library(magrittr)

setwd("D:/RADseq/nodiflorum")

K2struc.file = "faststructure/fastStructure.2.meanQ"
K3struc.file = "faststructure/fastStructure.3.meanQ"
K4struc.file = "faststructure/fastStructure.4.meanQ"
K5struc.file = "faststructure/fastStructure.5.meanQ"
K6struc.file = "faststructure/fastStructure.6.meanQ"
K7struc.file = "faststructure/fastStructure.7.meanQ"
K8struc.file = "faststructure/fastStructure.8.meanQ"
K9struc.file = "faststructure/fastStructure.9.meanQ"
K10struc.file = "faststructure/fastStructure.10.meanQ"

sample.info = read.delim("faststructure/bothplates_pops.txt", header = F, sep = "\t")
names(sample.info) = c("id", "pop")
sample.info = sample.info %>%
  mutate(
    pop = case_when(
      pop == "South Africa" ~ "SA",
      pop == "Canary Islands" ~ "CI",
      pop == "Cyprus" ~ "CY",
      pop == "Egypt" ~ "EG",
      pop == "Mexico" ~ "MX",
      pop == "Morocco" ~ "MOR",
      pop == "Italy" ~ "IT",
      pop == "United States" ~ "USA",
      pop == "Crete" ~ "CRE",
      pop == "Tunisia" ~ "TUN",
      pop == "Malta" ~ "MLT",
      # Add more countries as needed
      TRUE ~ pop  # Keep the original name if it doesn't match any condition
    )
  )
head(sample.info)

gps.data = read.csv("R_scripts/nodiflorum_sample_localities.csv") %>%
  janitor::clean_names() %>%
  mutate(latitude = ifelse(latitude == "Not given", NA, latitude),
         longitude = ifelse(longitude == "None given", NA, longitude)) %>%
  dplyr::select(sample_id, latitude, longitude, origin) %>%
  rename(name = sample_id,
         lat = latitude, lon = longitude)

gps.data$lat = as.numeric(gps.data$lat)
gps.data$lon = as.numeric(gps.data$lon)


K2 = structure.plot(K2struc.file, sample.info)
K2hapmap = hapmap.global(K2struc.file, sample.info, gps.data)
K2hapmapSA = hapmap.sa(K2struc.file, sample.info, gps.data)

K3 = structure.plot(K3struc.file, sample.info)
K3hapmap = hapmap.global(K3struc.file, sample.info, gps.data)
K3hapmapSA = hapmap.sa(K3struc.file, sample.info, gps.data)

K4 = structure.plot(K4struc.file, sample.info)
K4hapmap = hapmap.global(K4struc.file, sample.info, gps.data, piesize = 1)
ggsave("figures/hapmap.world.png", K4hapmap, width = 10, height = 6, units = "in", dpi = 400)
ggsave("figures/hapmap.world.svg", K4hapmap, width = 10, height = 6, units = "in", dpi = 400)

K4hapmapSA = hapmap.sa(K4struc.file, sample.info, gps.data)
#ggsave("figures/hapmap.SA.png", K4hapmapSA, width = 12, height = 10, units = "in")

K5 = structure.plot(K5struc.file, sample.info)
K6 = structure.plot(K6struc.file, sample.info)
K7 = structure.plot(K7struc.file, sample.info)
K8 = structure.plot(K8struc.file, sample.info)
K10 = structure.plot(K10struc.file, sample.info)

strucplots = gridExtra::grid.arrange(K2, K3, K4, ncol=1)

#dir.create("figures")
ggsave("figures/structureplot.png", strucplots, width = 16, height = 8, units = "in")
ggsave("figures/structureplot.svg", strucplots, width = 16, height = 8, units = "in")

structure.plot = function(strucfile, sampleinfo){
  
  f <- readLines(strucfile, warn = FALSE)
  
  qmat <- read.delim(
    strucfile, 
    header = FALSE,
    sep = "",
    strip.white = TRUE
  )
  
  names(qmat) <- c(paste0("pop_",1:(ncol(qmat))))
  
  qmat$name = sample.info$id
  qmat$population = sample.info$pop
  
  qmat$population <- as.factor(qmat$population)
  qmat <- qmat %>% 
    pivot_longer(c(-name, -population), names_to = "group", values_to = "probability")
  
  #my_pal <- RColorBrewer::brewer.pal(n = 8, name = "Dark2")
  my_pal = c("black", "#D95F02", "#1B9E77", "yellow","#666666", "#7570B3", "#66A61E", "#A6761D",
              "#E7298A", "red")
 
  struc.plot = qmat %>% 
    ggplot(aes(x = name, y = probability, fill = group)) +
    geom_bar(stat = "identity", width = 1.0) +
    theme_bw() +
    #labs(title = "Posterior Membership Probability") +
    ylab("Probability") +
    xlab("") +
    #guides(fill=guide_legend(title="Membership")) +
    theme(legend.position = "none") +
    theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
    #theme(axis.text.x = element_blank(), axis.ticks.x = element_blank()) +
    coord_cartesian(ylim = c(0, 1), expand = FALSE, clip = "off") +
    scale_fill_manual(values=c(my_pal)) +
    facet_grid(~population, scales = "free_x", space = "free" )
  
  return(struc.plot)
  
}#structure.plot



#########################################################################
# MAPPING
#########################################################################

hapmap.global = function(struc.file, sample.info, gps.data, piesize = 0.85){
  
  f <- readLines(struc.file, warn = FALSE)
  
  qmat <- read.delim(
    struc.file, 
    header = FALSE,
    sep = "",
    strip.white = TRUE
  )
  
  names(qmat) <- c(paste0("pop_",1:(ncol(qmat))))
  
  qmat$name = sample.info$id
  qmat$population = sample.info$pop
  
  qmat$population <- as.factor(qmat$population)
  qmat <- qmat %>% 
    pivot_longer(c(-name, -population), names_to = "group", values_to = "probability")
  
  #my_pal <- RColorBrewer::brewer.pal(n = 8, name = "Dark2")
  my_pal = c("black", "#D95F02", "#1B9E77", "yellow","#666666", "#7570B3", "#66A61E", "#A6761D",
             "#E7298A", "red")
  
  qmat_merged <- qmat %>%
    group_by(name) %>%
    mutate(lat = gps.data$lat[match(name, gps.data$name)],
           lon = gps.data$lon[match(name, gps.data$name)]) %>%
    ungroup()
  
  qmat_merged$lat = as.numeric(qmat_merged$lat)
  qmat_merged$lon = as.numeric(qmat_merged$lon)
  
  # this is a summary for each individual sample
  qmat_wide <- qmat_merged %>%
    tidyr::pivot_wider(names_from = group, values_from = probability)
  
  # this averages all the data per unique group, across all samples for that group
  qmat_averaged <- qmat_wide %>%
    group_by(population) %>%
    summarize(
      lat = first(lat),      # Keep the first value of lat
      lon = first(lon),      # Keep the first value of lon
      across(starts_with("pop"), mean, na.rm = TRUE)  # Average pop_* columns
    ) %>%
    dplyr::rename(name = population) 
  
  qmat_averaged <- qmat_averaged %>%
    mutate(
      lat = ifelse(is.na(lat), 35.0, lat),  # Replace NA lat with Cyprus lat
      lon = ifelse(is.na(lon), 33.0, lon)   # Replace NA lon with Cyprus lon
    )
  
  world_map <- rnaturalearth::ne_countries(
    scale = "medium", 
    returnclass = "sf"
  ) 
  
  pies = ggplot() +
    
    geom_sf(data = world_map, alpha = 0.2) +
    
    scatterpie::geom_scatterpie(
      #data = na.omit(qmat_wide), # plot pies for each individual sample
      data = na.omit(qmat_averaged), # plot pies representing the average per group
      aes(x = lon, y = lat, group = name),
      #aes(x = lon, y = lat, group = name),
      cols = pop_cols <- grep("^pop_", colnames(qmat_wide), value = TRUE),
      #alpha = 0.3,
      #color = NA, # Remove borders for pie charts
      color = "black", # Remove borders for pie charts
      linewidth = 0.2,
      pie_scale = piesize # Adjust pie size if necessary
    ) +
    
    scale_fill_manual(values = my_pal) +
    
    coord_sf(
      ylim = c(95,-60),
      crs = 4326,
      expand = FALSE
    ) + 
    
    xlab("Longitude") + 
    ylab("Latitude") +
    theme_classic() +
    theme(legend.position = "none")
  
  return(pies)
} #hapmap.global

hapmap.sa = function(struc.file, sample.info, gps.data){
  
  f <- readLines(struc.file, warn = FALSE)
  
  qmat <- read.delim(
    struc.file, 
    header = FALSE,
    sep = "",
    strip.white = TRUE
  )
  
  names(qmat) <- c(paste0("pop_",1:(ncol(qmat))))
  
  qmat$name = sample.info$id
  qmat$population = sample.info$pop
  
  qmat$population <- as.factor(qmat$population)
  qmat <- qmat %>% 
    pivot_longer(c(-name, -population), names_to = "group", values_to = "probability")
  
  #my_pal <- RColorBrewer::brewer.pal(n = 8, name = "Dark2")
  my_pal = c("black", "#D95F02", "#1B9E77", "#E7298A")
  
  qmat_merged <- qmat %>%
    group_by(name) %>%
    mutate(lat = gps.data$lat[match(name, gps.data$name)],
           lon = gps.data$lon[match(name, gps.data$name)]) %>%
    ungroup()
  
  qmat_merged$lat = as.numeric(qmat_merged$lat)
  qmat_merged$lon = as.numeric(qmat_merged$lon)
  
  qmat_wide <- qmat_merged %>%
    tidyr::pivot_wider(names_from = group, values_from = probability)
  
  sa_ext <- rnaturalearth::ne_countries(scale = "medium",
                                        returnclass = "sf") %>%
    # dplyr::filter(name == c("South Africa", "Lesotho", "Swaziland"))
    dplyr::filter(name %in% c("South Africa", "Lesotho", "Swaziland"))
  
  sa_ext = sf::st_set_crs(sa_ext, 4326)
  
  provincial_borders <-rnaturalearth::ne_states(country = "South Africa", returnclass = "sf")
  
  pies = ggplot() +
    geom_sf(data = sa_ext, alpha = 0.5) +
    geom_sf(data = provincial_borders) +
    scatterpie::geom_scatterpie(
      data = na.omit(qmat_wide),
      aes(x = lon, y = lat, group = name),
      cols = c(paste0("pop_",1:(ncol(qmat_wide)-4))),
      color = NA, # Remove borders for pie charts
      pie_scale = 0.15 # Adjust pie size if necessary
    ) +
    scale_fill_manual(values = my_pal) +
    coord_sf(
      xlim = c(15, 34),
      ylim = c(-21, -36),
      crs = 4326,
      expand = FALSE
    ) +
    xlab("Longitude") + 
    ylab("Latitude") +
    theme_classic() +
    theme(legend.position = "none")
  
  return(pies)
} #hapmap.sa


###############################
# General GPS plotting
###############################

world_map <- rnaturalearth::ne_countries(
  scale = "medium", 
  returnclass = "sf"
) 

#my_pals = c("black", "#D95F02", "#1B9E77", "#E7298A")

# Plot GPS points on world map to check our locality data is correct 
global_distr = ggplot() +
  # Add raster layer of world map 
  geom_sf(data = world_map, alpha = 0.5) +
  # Add GPS points 
  geom_point(
    data = na.omit(gps.data), 
    size = 3, shape = 21,
    aes(x = lon, y = lat, fill = origin),  color = "black"
  )  +
  #scale_fill_manual(values = c(my_pals)) +
  # Set world map CRS 
  coord_sf(
    crs = 4326,
    expand = FALSE
  ) + 
  xlab("Longitude") + 
  ylab("Latitude") +
  theme_classic()

global_distr

  
