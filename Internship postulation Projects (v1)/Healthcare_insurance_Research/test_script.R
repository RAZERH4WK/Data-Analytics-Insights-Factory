
#-----------------------------------------------------------------------------------------------------------------------
# SETUP

#Libraries
library(data.table)
library(ggplot2)
library(magick)
library(xts)
library(readxl)
library(tidyr)
library(dplyr)
library(stringr)
library(quantmod)
library(lubridate)
library(scales) # to adjust ggplot axis scales
library(treemap)
library(RColorBrewer)


#logos
mckLogo_raw <- image_read(path = "Images/mcLogo.png")
mckLogo <- mckLogo_raw %>%
  image_scale("300") %>% 
  image_background("grey", flatten = TRUE) %>%
  image_border("grey", "600x10") %>%
  image_annotate("Powered By R", color = "white", size = 30, 
                 location = "+10+50", gravity = "northeast")

#My theme

my_theme1 <- theme(rect = element_blank(), axis.line = element_line(color = "#DADADA"), 
                  axis.title = element_text(size = 10, color = "#505050", face = "italic"), 
                  axis.text = element_text(size = 9, color = "#505050"),
                  title = element_text(size = 13, color = "black"),
                  panel.grid.major.y = element_line(color = "#F3F3F3"),
                  legend.position = "top", legend.text = element_text(size = 9),
                  legend.title = element_text(size = 10, face = "bold"), legend.direction = "horizontal",
                  plot.caption = element_text(color = "black", size = "8", hjust = 0))



## Functions


#This appends my logos and save the plot as an image

logoApp <- function(graph, file, savePath, logo){
  #Remeber to have a folder in your wd named "Images"
  newgraph <- graph + ggsave(filename = file, width = 7, height = 6, dpi = 600, path = "Images/")
  baseIm <- image_read(path = savePath)
  imA <- image_append(image_scale(c(baseIm, logo), "700"), stack = TRUE)
  image_write(imA, savePath)
  return(imA)
}

#Data set up

#A1
#File
healP_gdp <- fread("Databases/hcstPricesYearly.csv")
# XTS constructor
ind <- seq(from = as.Date("2007-12-01"), to = as.Date("2018-03-01"), by = "month")
price_gdp <- xts(healP_gdp[,-1], order.by = ind)

#--------

### A2

# File, all the data is in THOUSANDS
HIC4 <- read_excel("Databases/HIC4cover.xls", range = "hic04_acs!A4:AT577", col_names = FALSE)
class(HIC4)
## Excel blooming

# Removes NA and spread the Nations and years
HIC4[2,2] <- "Estimate" #THIS was because of an emergent problem
HIC4[2,1] <- "Estimate" #THIS was because of an emergent problem
HIC4 <- HIC4[ ,which(HIC4[2,1:ncol(HIC4)] == "Estimate" | HIC4[2,1:ncol(HIC4)] == "Percent")]
HIC4[,1] <- na.locf(HIC4[,1])
HIC4[1,3:22] <- na.locf(as.numeric(HIC4[1,3:22])) #Convert to numbers the years

# Unite and rename the columns
newNames <- paste(HIC4[2,], HIC4[1,], sep = " ") # example: Estimate + 2018
names(HIC4) <- newNames
colnames(HIC4)[1] <- "State"
colnames(HIC4)[2] <- "Coverage"
 
# Remove old Estimate and year rows
HIC4 <- HIC4[-c(1,2),]

# # Gather the estimates as columns
HIC4 <- gather(HIC4, Estimate, Value, -c("State","Coverage"))

# Separate Estimate and year in two columns
HIC4 <- separate(HIC4, Estimate, into = c("Method", "Year"), sep = " ")

#Clear coverage names
HIC4$Coverage <- str_replace_all(HIC4$Coverage, "\\.", "")
HIC4$Coverage <- str_trim(HIC4$Coverage)

#Clean NAs and covert Value to number
HIC4 <- na.omit(HIC4)


# Filter the Private Coverage
private_HIC4 <- HIC4 %>% filter(Coverage == "Employer-based" | Coverage == "Direct-purchase" | Coverage == "TRICARE")%>% 
  mutate(Sector = "Private")

# Filter the Public Coverage
public_HIC4 <- HIC4 %>% filter(Coverage == "Medicaid" | Coverage == "Medicare" | Coverage == "VA Care") %>%
  mutate(Sector = "Public")

# Filter if is covered or not
covered_HIC4 <- HIC4 %>% filter(Coverage == "Any coverage" | Coverage == "Uninsured")
covered_HIC4 <- spread(covered_HIC4, Method, Value)
covered_HIC4 <- covered_HIC4[,-5]
covered_HIC4 <- covered_HIC4[-(which(is.na(covered_HIC4$Estimate))),] 
covered_HIC4 <- covered_HIC4[which(covered_HIC4$Estimate != "NA"),] 
covered_HIC4 <- covered_HIC4[which(covered_HIC4$Estimate != "N"),] 

# Making a Global for Public and Private only
global_HIC4 <- rbind(HIC4 %>% filter(Coverage == "Public") %>% mutate(Sector = "Public"), HIC4 %>% filter(Coverage == "Private")
                     %>% mutate(Sector = "Private"))
global_HIC4$Year <- str_replace(global_HIC4$Year, "NA", "2008")
global_HIC4 <- global_HIC4[,-2]
global_HIC4 <- spread(global_HIC4, Method, Value)



# #Clean Environment
rm(HIC4)




#--------

#### B2

##Importing financial data into a new environment

fin_env <- new.env()


# UnitedHealth Insurance Co, Anthem Inc, Cigna Corporation, Humana, Centene Corporation

getSymbols("UNH;ANTM;CI;HUM;CNC", auto.assign = TRUE, env = fin_env, , from = "2019-12-01")



# Close Price list, value per share

close_list <- lapply(fin_env, Cl)
close_price <- do.call(merge, close_list)

head(close_price)

close_df <- data.frame(date = index(close_price), coredata(close_price))
close_df <- close_df %>% mutate(date = ymd(date))
close_df <- gather(close_df, Corp, `Close Price`, -date)
close_df <- separate(close_df, Corp, into = c("Corporation", "Index"))
close_df <- close_df[,-3]
close_df$Corporation <- str_trim(close_df$Corporation)
close_df$Corporation <- str_replace(close_df$Corporation, "UNH", "UnitedHealth")
close_df$Corporation <- str_replace(close_df$Corporation, "ANTM", "Anthem")
close_df$Corporation <- str_replace(close_df$Corporation, "CI", "Cigna")
close_df$Corporation <- str_replace(close_df$Corporation, "HUM", "Humana")
close_df$Corporation <- str_replace(close_df$Corporation, "CNC", "Centene")

# Volume <- number of shares traded.
# Bid.Price <- price which I can sell the shares.
# Bid.Size <- number of shares I can sell.
# Ask.Price <- price which I can buy the shares.
# Ask.Size <- number of shares I can buy.



#--------

### B3

#EXPENDITURE

expenditure <- read_excel("Databases/PersonalHealthCareExpendituresNHE.xlsx", range = "A1:H15", col_names = TRUE)
expenditure <- gather(expenditure, Subject, Amount, -c(1,6,7,8))


#--------

### B4

#EXPENDITURE

## By Age, Child 0 to 18, Adults 19 to 64

age_An <- read_excel("Databases/ageCover.xlsx", range = "A1:D54", col_names = TRUE)
age_An <- age_An[,-4]
age_An <- gather(age_An, Group, Count,-1)

#-----------------------------------------------------------------------------------------------------------------------


## SECTION 1



# A1. Why to USA system coverage is so expensive

# Price of healthcare vs Grow Domestic Product of USA


colorsA <- c("Health care price" = "#309BF4", "GDP deflator" = "#F33160")

g_price_gdp <- ggplot(price_gdp, aes(x= index(price_gdp))) +
  geom_line(aes(y = price_gdp$`Health care price`, color = "Health care price")) +
  geom_line(aes(y = price_gdp$`GDP deflator`, color = "GDP deflator")) +
  scale_x_date("Years", date_labels = "%Y", date_breaks = "13 months", limits = c(as.Date("2007-12-01"), as.Date("2018-03-01"))) +
  scale_y_continuous("Cumulative percent change of Prices", limits = c(0,24)) +
  ggtitle("Prices for healthcare and Grow Domestic Product of USA") +
  labs(caption = "Source: Kaiser Family Foundation estimates based on the Census Bureau's American Community Survey, 2008-2018", color = "") +
  scale_color_manual(values = colorsA) +
  my_theme1


priceGdp <- logoApp(g_price_gdp, "g_price_gdp.png", "Images/g_price_gdp.png", mckLogo)
priceGdp



# A2. Why to USA system coverage is so expensive

# What is the propotion of Public and Private Insurance in the USA?


g_globPie <- global_HIC4 %>% filter(State == "UNITED STATES") %>% filter(Year == 2018 | Year == 2017 | Year == 2016) %>% ggplot(aes(x = "", y = Percent, fill = Sector)) +
  geom_bar(width = 1, stat = "identity") + coord_polar(theta = "y") +
  facet_wrap(~Year) + my_theme1 + theme(axis.text = element_blank()) +
  scale_x_discrete("") + ggtitle("Proportion of Insurance Type of Covarage by Year in US") +
  labs(caption = "Source: Kaiser Family Foundation estimates based on the Census Bureau's American Community Survey, 2008-2018")
g_globPie

g_globPie <- logoApp(g_globPie, "g_globPie.png", "Images/g_globPie.png", mckLogo)
g_globPie


# How many people use Private Insurance?

g_priv <- private_HIC4 %>% filter(State == "UNITED STATES")
g_priv <- g_priv[which(g_priv$Year != "NA"),]                  #!!!!!!!!!!!!!!!!!!! HIGH IMPORTANCE

g_priv <- g_priv %>% ggplot(aes(x= Year, y = as.numeric(Value), color = Coverage, fill = Coverage)) +
  geom_col(position = position_dodge(width = 0.6), alpha = 0.6) +
  my_theme1 + scale_color_manual(values = c( "#F33160", "#309BF4", "#D18F04"), aesthetics = c("color", "fill"))+
  ggtitle("US Population with Private Insurance") +
  labs(caption = "Source: Kaiser Family Foundation estimates based on the Census Bureau's American Community Survey, 2008-2018", y = "Population in thousands")

g_priv <- logoApp(g_priv, "g_priv.png", "Images/g_priv.png", mckLogo)
g_priv


# How many people use Public Insurance?

g_pub <- public_HIC4 %>% filter(State == "UNITED STATES")
g_pub <- g_pub[which(g_pub$Year != "NA"),]                  #!!!!!!!!!!!!!!!!!!! HIGH IMPORTANCE

g_pub <- g_pub %>% ggplot(aes(x= Year, y = as.numeric(Value), color = Coverage, fill = Coverage)) +
  geom_col(position = position_dodge(width = 0.6), alpha = 0.6) +
  my_theme1 + scale_color_manual(values = c( "#F33160", "#309BF4", "#D18F04"), aesthetics = c("color", "fill"))+
  ggtitle("US Population with Public Insurance") +
  labs(caption = "Kaiser Family Foundation estimates based on the Census Bureau's American Community Survey, 2008-2018"
       , y = "Population in thousands") 

g_pub <- logoApp(g_pub, "g_pub.png", "Images/g_pub.png", mckLogo)
g_pub



# How much people use the insurance by state


g_covered <- covered_HIC4 %>% filter(Year == "2018") %>% filter(State != "UNITED STATES")
g_covered$Estimate <- sapply(g_covered$Estimate, as.numeric)
g_covered <- g_covered %>% ggplot(aes(x = factor(State), y = as.numeric(Estimate), fill = Coverage, color = Coverage)) +
   geom_col(position = "fill", alpha = 0.6) + coord_flip() + facet_grid(.~Year, scale = "free_y", space = "free_y") + my_theme1 +
  ggtitle("US Population Covered with Insurance by State") +
  labs(caption = "Source: Kaiser Family Foundation estimates based on the Census Bureau's American Community Survey, 2008-2018", y = "Proportion of population", x = "State")+
  theme(axis.text = element_text(size = 7)) + scale_color_manual(values = c("#08D395", "#A1A1A1"), aesthetics = c("color", "fill"))

g_covered <- logoApp(g_covered, "g_covered.png", "Images/g_covered.png", mckLogo)
g_covered



# Plot the map in images







#-----------------------------------------------------------------------------------------------------------------------


## SECTION 2


# A quick look at the close price of the stock of Health Insurance Companies



g_close <- close_df %>% ggplot(aes(x = date, y = `Close Price`, color = Corporation)) + geom_line() +
  my_theme1 +
  geom_vline(xintercept = as.numeric(as.Date("2020-03-23")), linetype= 5, color = "#CB1952", size=0.9) +
  scale_x_date(labels = date_format("%b %Y")) + ggtitle("Close Stock Price per share of last 5 months") +
  labs(caption = "Source: Yahoo Finance, NYSE Delayed Price", y = "Close Price", x = "Period") +
  scale_color_manual(values = c("#7341FA","#4158FA","#41CAFA","#41FAA3", "#8FFA41"))


g_close <- logoApp(g_close, "g_close.png", "Images/g_close.png", mckLogo)
g_close





# Projected expenditure



g_expenditure <- expenditure %>% ggplot(aes(x = Year, y = Amount, color = Subject, shape = Subject)) + geom_point(size = 2) + geom_smooth(method = "lm", se = FALSE) +
  scale_x_continuous(breaks = c(2016, 2018, 2020, 2022, 2024, 2026, 2028), limits = c(2016, 2028)) +
  scale_color_manual(values = c("#8FFA41","#4158FA","#41CAFA","#41FAA3")) +
  scale_y_continuous(breaks = c(2000, 6000, 10000, 14000, 18000))  + my_theme1 +
  theme(legend.position = "bottom", legend.text = element_text(size = 8), legend.title = element_blank(),
        legend.direction = "vertical") + ggtitle("Expenditure Projection by Subject to 2028") +
  labs(caption = "Source: U.S. Centers for Medicare & Medicaid",
       y = "$ Amount", x = "Period")

#https://www.cms.gov/Research-Statistics-Data-and-Systems/Statistics-Trends-and-Reports/NationalHealthExpendData/NHE-Fact-Sheet

g_expenditure <- logoApp(g_expenditure, "g_expenditure.png", "Images/g_expenditure.png", mckLogo)
g_expenditure



# Age by state, TREEMAP


# age_An <- age_An %>% filter(Location != "United States")
# age_tree <- treemap(age_An, index = c("Location", "Group"), vSize = "Count", type = "index", fontsize.labels = c(9,7),
#                     border.col=c("black","#C0C0C0"), fontcolor.labels=c("black","#C0C0C0"),  align.labels=list(
#                       c("center", "center"), 
#                       c("right", "bottom")), title="Age distribution of Uninsured population by state of USA", fontsize.title=12, palette = "Blues")

