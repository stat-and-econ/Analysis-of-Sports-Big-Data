library(ggplot2)
library(tidyverse)

## Question 1

library(Lahman)

People %>%
  filter(birthCountry == "South Korea") %>%
  select(debut, finalGame, birthDate, nameFirst, nameLast, birthCountry) %>%
  arrange(debut)


library(retrosheet)
gamelog_2019 <- getRetrosheet("game", 2019)
gamelog_2019 %>%
  filter(Date == 20190507 & HmTm == "LAN")

## Question 5 (based on given R scripts)
## Add the following before running the scripts.
crcblue <- "#2905a1" #The reason of an unknown error

## Question 6

judge_hr <- statcast2017 %>% 
  filter(player_name == "Judge, Aaron", events == "home_run") %>%
  mutate(is_fb = pitch_type %in% c("FF", "FT", "SI", "FC"))

plate_width <- 17 + 2 * (9/pi)
k_zone_plot <- ggplot(NULL, aes(x = plate_x, y = plate_z)) + 
  geom_rect(xmin = -(plate_width/2)/12, 
            xmax = (plate_width/2)/12, 
            ymin = 1.5, 
            ymax = 3.6, color=crcblue, fill = "lightgray", 
            linetype = 2, alpha = 0.01) + 
  coord_equal() + 
  scale_x_continuous("Horizontal location (ft.)", 
                     limits = c(-1.5, 1.5)) + 
  scale_y_continuous("Vertical location (ft.)", 
                     limits = c(1, 4))

k_zone_plot %+% judge_hr +
  aes(color = is_fb) + 
  geom_point() + 
  scale_color_manual("Type", values = c(crcblue,"gray60"),
                     labels = c("off-speed", "fastball")
  )