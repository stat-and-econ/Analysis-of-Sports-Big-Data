### Analysis of Sports Big Data HW 2 ###
### Jae-Hyun Lee, 2021311175 ###

# Run global configuration file firstly
library(ggplot2)
library(ggrepel)

### 3.5 Q1 ###

# a
Player <- c("RH", "LB", "TC", "EC", "MC", "JM", "LA", "PM", "RA")
SB <- c(1406,938,897,741,738,689,506,504,474)
CS <- c(335,307,212,195,109,162,136,131,114)
G <- c(3081,2616,3034,2826,2476,2649,2599,2683,2379)

# b
SB.Attempt <- SB + CS
SB.Attempt

# c
Success.Rate <- SB / SB.Attempt
Success.Rate

# d
SB.Game <- SB / G
SB.Game

# e
plot(SB.Game, Success.Rate)
Player[rank(Success.Rate) == 1] # Worst success rate
Player[rank(Success.Rate) == 9] # Best success rate
Player[rank(SB.Game) == 9] # Best number of stolen bases per game


### 3.5 Q2 ###

# a
library(Lahman)
head(Pitching, 1)

# b
career.pitching <- Pitching %>%
  group_by(playerID) %>%
  summarize(SO = sum(SO, na.rm = TRUE),
            BB = sum(BB, na.rm = TRUE),
            IPouts = sum(IPouts, na.rm = TRUE),
            midYear = median(yearID, na.rm = TRUE))
head(career.pitching)

Pitching <- inner_join(Pitching, career.pitching, by = "playerID")
head(Pitching, 1) #old: .x , new: .y

# c
Pitching %>%
  filter(IPouts.y >= 10000) -> career.10000

# d
ggplot(career.10000, aes(midYear, SO.y/BB.y)) +
  geom_point() +
  geom_smooth() +
  geom_text(data = filter(career.10000, SO.y/BB.y > 5),
                  aes(midYear, SO.y/BB.y, label = playerID))


### 3.5 Q3 ###

#library(Lahman)

get_birthyear <- function(Name) {
  Names <- unlist(strsplit(Name, " "))
  People %>%
    filter(nameFirst == Names[1],
           nameLast == Names[2]) %>%
    mutate(birthyear = ifelse(birthMonth >= 7,
                              birthYear + 1, birthYear),
           Player = paste(nameFirst, nameLast)) %>%
    select(playerID, Player, birthyear)
}

PlayerInfo <- bind_rows(get_birthyear("Babe Ruth"),
                        get_birthyear("Hank Aaron"),
                        get_birthyear("Barry Bonds"),
                        get_birthyear("Alex Rodriguez")
)

Batting %>%
  inner_join(PlayerInfo, by = "playerID") %>%
  mutate(Age = yearID - birthyear) %>%
  select(Player, Age, HR) %>%
  group_by(Player) %>%
  mutate(CHR = cumsum(HR)) -> HRdata

ggplot(HRdata, aes(x = Age, y = CHR, linetype = Player)) +
  geom_line()

ggplot(HRdata, aes(x = Age, y = CHR, linetype = Player)) +
  geom_line() +
  ylab("Career home runs") +
  geom_hline(data = HRdata, aes(yintercept = 600),
             color = crcblue) +
  geom_hline(data = HRdata, aes(yintercept = 700),
             color = crcblue)


### 3.5 Q4 ###

fields <- read_csv(file.choose()) # Click the fields.csv wherever it is in
data1998 <- read_csv(file.choose(),
                     col_names = pull(fields, Header))
#library(Lahman)

sosa_id <- People %>%
  filter(nameFirst == "Sammy", nameLast == "Sosa") %>%
  pull(retroID)
mac_id <- People %>%
  filter(nameFirst == "Mark", nameLast == "McGwire") %>%
  pull(retroID)

hr_race <- data1998 %>%
  filter(BAT_ID %in% c(sosa_id, mac_id))

library(lubridate)
cum_hr <- function(d) {
  d %>%
    mutate(Date = ymd(str_sub(GAME_ID, 4, 11))) %>%
    arrange(Date) %>%
    mutate(HR = ifelse(EVENT_CD == 23, 1, 0),
           cumHR = cumsum(HR)) %>%
    select(Date, cumHR)
}

hr_ytd <- hr_race %>%
  split(pull(., BAT_ID)) %>%
  map_df(cum_hr, .id = "BAT_ID") %>%
  inner_join(People, by = c("BAT_ID" = "retroID"))

ggplot(hr_ytd, aes(Date, cumHR, linetype = nameLast)) +
  geom_line() +
  geom_hline(yintercept = 62, color = crcblue) +
  annotate("text", ymd("1998-04-15"), 65,
           label = "62", color = crcblue) +
  ylab("Home Runs in the Season")

hr_ytd %>%
  filter(cumHR == 66) %>%
  select(BAT_ID, cumHR, Date)
  
hr_ytd %>%
  filter(Date == "1998-09-25" | Date == "1998-09-26") %>%
  select(BAT_ID, cumHR, Date) %>%
  arrange(Date)

ggplot(hr_ytd, aes(Date, cumHR, linetype = nameLast)) +
  geom_line() +
  geom_vline(xintercept = ymd("1998-09-25"), color = crcblue) +
  annotate("text", ymd("1998-09-01"), 3,
           label = "Both hit 66 on 09-25", color = crcblue) +
  ylab("Home Runs in the Season")


### 3.5 Q5 ###

#fields <- read_csv(file.choose()) # Click the fields.csv wherever it is in
#data1998 <- read_csv(file.choose(),
#                     col_names = pull(fields, Header))
#library(Lahman)

# a
sosa_id <- People %>%
  filter(nameFirst == "Sammy", nameLast == "Sosa") %>%
  pull(retroID)
mac_id <- People %>%
  filter(nameFirst == "Mark", nameLast == "McGwire") %>%
  pull(retroID)

data1998 %>%
  filter(BAT_ID == sosa_id) -> sosa.data

data1998 %>%
  filter(BAT_ID == mac_id) -> mac.data

# b
mac.data <- filter(mac.data, BAT_EVENT_FL == TRUE)
sosa.data <- filter(sosa.data, BAT_EVENT_FL == TRUE)

# c
mac.data <- mutate(mac.data, PA = 1:nrow(mac.data))
sosa.data <- mutate(sosa.data, PA = 1:nrow(sosa.data))

# d
mac.HR.PA <- mac.data %>%
  filter(EVENT_CD == 23) %>%
  pull(PA)
sosa.HR.PA <- sosa.data %>%
  filter(EVENT_CD == 23) %>%
  pull(PA)

# e
mac.spacings <- diff(c(0, mac.HR.PA))
sosa.spacings <- diff(c(0, sosa.HR.PA))

HR_Spacing <- rbind(cbind("Mark McGwire", mac.spacings),
                    cbind("Sammy Sosa", sosa.spacings))
colnames(HR_Spacing) <- c("Player", "Spacing")
HR_Spacing <- data.frame(HR_Spacing)
HR_Spacing <- transform(HR_Spacing, Spacing=as.numeric(Spacing))

ggplot(HR_Spacing, aes(x=Spacing, group=Player, fill=Player)) +
  geom_histogram(binwidth = 1, position = "dodge")


### 5.8 Q1 ###

fields <- read_csv(file.choose()) # Click the fields.csv whereever it is in
data2016 <- read_csv(file.choose(),
                     col_names = pull(fields, Header),
                     na = character())
#library(Lahman)

data2016 %>%
  mutate(RUNS = AWAY_SCORE_CT + HOME_SCORE_CT,
         HALF.INNING = paste(GAME_ID, INN_CT, BAT_HOME_ID),
         RUNS.SCORED = # Exceeding 3 means the runner scored
           (BAT_DEST_ID > 3) + (RUN1_DEST_ID > 3) +
           (RUN2_DEST_ID > 3) + (RUN3_DEST_ID > 3)) ->
  data2016
data2016 %>%
  select(RUNS, HALF.INNING, RUNS.SCORED, BAT_DEST_ID, RUN1_DEST_ID) %>%
  head(10)

data2016 %>%
  group_by(HALF.INNING) %>%
  summarize(Outs.Inning = sum(EVENT_OUTS_CT),
            Runs.Inning = sum(RUNS.SCORED),
            Runs.Start = first(RUNS),
            MAX.RUNS = Runs.Inning + Runs.Start) ->
  half_innings
half_innings %>%
  select(HALF.INNING, Outs.Inning, Runs.Inning, Runs.Start, MAX.RUNS) %>%
  head(10)

data2016 %>%
  inner_join(half_innings, by = "HALF.INNING") %>%
  mutate(RUNS.ROI = MAX.RUNS - RUNS) ->
  data2016

data2016 %>%
  mutate(BASES =
           paste(ifelse(BASE1_RUN_ID > '', 1, 0),
                 ifelse(BASE2_RUN_ID > '', 1, 0),
                 ifelse(BASE3_RUN_ID > '', 1, 0), sep = ""),
         STATE = paste(BASES, OUTS_CT)) ->
  data2016
data2016 %>%
  select(BASES, STATE, BASE1_RUN_ID, BASE2_RUN_ID, BASE3_RUN_ID) %>%
  head()

data2016 %>%
  mutate(NRUNNER1 =
           as.numeric(RUN1_DEST_ID == 1 | BAT_DEST_ID == 1),
         NRUNNER2 =
           as.numeric(RUN1_DEST_ID == 2 | RUN2_DEST_ID == 2 |
                        BAT_DEST_ID == 2),
         NRUNNER3 =
           as.numeric(RUN1_DEST_ID == 3 | RUN2_DEST_ID == 3 |
                        RUN3_DEST_ID == 3 | BAT_DEST_ID == 3),
         NOUTS = OUTS_CT + EVENT_OUTS_CT,
         NEW.BASES = paste(NRUNNER1, NRUNNER2,
                           NRUNNER3, sep = ""),
         NEW.STATE = paste(NEW.BASES, NOUTS)) ->
  data2016
data2016 %>%
  select(NRUNNER1, NRUNNER2, NRUNNER3, NEW.BASES, NEW.STATE) %>%
  head()

data2016 %>%
  filter((STATE != NEW.STATE) | (RUNS.SCORED > 0)) ->
  data2016

data2016 %>%
  filter(Outs.Inning == 3) -> data2016C

data2016C %>%
  group_by(STATE) %>%
  summarize(Mean = mean(RUNS.ROI)) %>%
  mutate(Outs = substr(STATE, 5, 5)) %>% # subtracting outs information
  arrange(Outs) -> RUNS
RUNS

RUNS_out <- matrix(round(RUNS$Mean, 2), 8, 3)
dimnames(RUNS_out)[[2]] <- c("0 outs", "1 out", "2 outs")
dimnames(RUNS_out)[[1]] <- c("000", "001", "010", "011",
                             "100", "101", "110", "111")
RUNS_out

data2016 %>%
  left_join(select(RUNS, -Outs), by = "STATE") %>%
  rename(Runs.State = Mean) %>%
  left_join(select(RUNS, -Outs), # NEW.STATE in data2016 and STATE in RUNS
            by = c("NEW.STATE" = "STATE")) %>%
  rename(Runs.New.State = Mean) %>%
  replace_na(list(Runs.New.State = 0)) %>% # With 3 outs, RE = 0
  mutate(run_value = Runs.New.State - Runs.State +
           RUNS.SCORED) -> data2016
data2016 %>%
  select(STATE, NEW.STATE, Runs.State, Runs.New.State, run_value) %>% head()

data2016 %>% filter(BAT_EVENT_FL == TRUE) -> data2016b
data2016b %>%
  group_by(BAT_ID) %>% # for each player
  summarize(RE24 = sum(run_value), # RE24
            PA = length(run_value),
            # total starting runs potential (opportunities)
            Runs.Start = sum(Runs.State)) -> runs
runs %>%
  filter(PA >= 400) -> runs400 # restricting players
head(runs400)

runs400 %>%
  inner_join(People, by = c("BAT_ID" = "retroID")) -> runs400

ggplot(runs400, aes(Runs.Start, RE24)) +
  geom_point() +
  geom_smooth() +
  geom_hline(yintercept = 0, color = crcblue) +
  geom_text_repel(data = filter(runs400, RE24 >= 40),
                  aes(label = nameLast))

# a
ggplot(runs400, aes(Runs.Start, RE24)) +
  geom_point() +
  geom_smooth() +
  geom_hline(yintercept = 0, color = crcblue) +
  geom_text_repel(data = filter(runs400, RE24 < -20),
                  aes(label = nameLast))

# b
runs %>%
  filter(PA >= 502) -> runs502 # restricting players

runs502 %>%
  inner_join(People, by = c("BAT_ID" = "retroID")) -> runs502

ggplot(runs502, aes(Runs.Start, RE24)) +
  geom_point() +
  geom_smooth() +
  geom_hline(yintercept = 0, color = crcblue) +
  geom_text_repel(data = filter(runs502, RE24 >= 40),
                  aes(label = nameLast))


### 5.8 Q2 ###

#fields <- read_csv(file.choose()) # Click the fields.csv whereever it is in
#data2016 <- read_csv(file.choose(),
#                     col_names = pull(fields, Header),
#                     na = character())
#library(Lahman)

# doubles
data2016 %>% filter(EVENT_CD == 21) -> doubles

double_STATE <- cbind(
  matrix(table(doubles$STATE),8,3,byrow=T),
  matrix(round(prop.table(table(doubles$STATE)),2),8,3,byrow=T))
dimnames(double_STATE)[[2]] <- c("0 outs", "1 out", "2 outs", 
                                 "0 outs", "1 out", "2 outs")
dimnames(double_STATE)[[1]] <- c("000", "001", "010", "011",
                                 "100", "101", "110", "111")
double_STATE

mean_doubles <- doubles %>%
  summarize(mean_run_value = mean(run_value))
med_doubles <- doubles %>%
  summarize(median_run_value = median(run_value))
c(mean_doubles, med_doubles)

ggplot(doubles, aes(run_value)) +
  geom_histogram(bins = 40) +
  geom_vline(data = mean_doubles, color = crcblue,
             aes(xintercept = mean_run_value)) +
  annotate("text", 1, 2000,
           label = "Mean Run\nValue", color = crcblue)

doubles %>%
  group_by(STATE) %>%
  summarize(mean_run_value = mean(run_value)) -> double_RV_STATE
double_RV_STATE <- matrix(double_RV_STATE$mean_run_value, 8, 3, byrow = T)
dimnames(double_RV_STATE)[[2]] <- c("0 outs", "1 out", "2 outs")
dimnames(double_RV_STATE)[[1]] <- c("000", "001", "010", "011",
                                    "100", "101", "110", "111")
double_RV_STATE

# triples
data2016 %>% filter(EVENT_CD == 22) -> triples

triple_STATE <- cbind(
  matrix(table(triples$STATE),8,3,byrow=T),
  matrix(round(prop.table(table(triples$STATE)),2),8,3,byrow=T))
dimnames(triple_STATE)[[2]] <- c("0 outs", "1 out", "2 outs", 
                                 "0 outs", "1 out", "2 outs")
dimnames(triple_STATE)[[1]] <- c("000", "001", "010", "011",
                                 "100", "101", "110", "111")
triple_STATE

mean_triples <- triples %>%
  summarize(mean_run_value = mean(run_value))
med_triples <- triples %>%
  summarize(median_run_value = median(run_value))
c(mean_triples, med_triples)

ggplot(triples, aes(run_value)) +
  geom_histogram(bins = 40) +
  geom_vline(data = mean_triples, color = crcblue,
             aes(xintercept = mean_run_value)) +
  annotate("text", 1.2, 220,
           label = "Mean Run\nValue", color = crcblue)

triples %>%
  group_by(STATE) %>%
  summarize(mean_run_value = mean(run_value)) -> triple_RV_STATE

triple_RV_STATE <- matrix(triple_RV_STATE$mean_run_value, 8, 3, byrow = T)
dimnames(triple_RV_STATE)[[2]] <- c("0 outs", "1 out", "2 outs")
dimnames(triple_RV_STATE)[[1]] <- c("000", "001", "010", "011",
                                    "100", "101", "110", "111")
triple_RV_STATE