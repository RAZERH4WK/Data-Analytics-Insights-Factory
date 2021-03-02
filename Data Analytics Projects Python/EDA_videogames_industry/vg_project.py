# -*- coding: utf-8 -*-
"""
Created on Sun Feb  7 13:31:15 2021

@author: rober
"""

# ----------------------------------------------------------------------------
## Import Packages
# ----------------------------------------------------------------------------


# To manage Dataframes
import pandas as pd 
# To manage the Year column
from datetime import datetime as dt
# To manage number operators
import numpy as np
# To manage plots
import matplotlib.pyplot as plt
# Package for more plots
import seaborn as sns
# To plot maps
import cartopy
import cartopy.crs as ccrs
# To do interactive visualizations
import plotly.express as px

# ----------------------------------------------------------------------------
## Import Data
# ----------------------------------------------------------------------------

# Import data frame of videogames
df = pd.read_csv("data/videogames.csv", na_values=["N/A","", " ", "nan"],
                 index_col=0)


# ----------------------------------------------------------------------------
## Mutating Data
# ----------------------------------------------------------------------------

# Transform Year column to a timestamp
df["Year_ts"] = pd.to_datetime(df["Year_of_Release"], format='%Y')

# Transform Year column to a string
df["Year_str"] = df["Year_of_Release"].apply(str).str.slice(stop=-2)



# ----------------------------------------------------------------------------
## Manipulating Data
# ----------------------------------------------------------------------------

# Mask to subset games from 1980 to 1985
games8086 = df["Year_of_Release"].isin(np.arange(1980,1986))
# Mask to subset games from 1980 to 1990
games8090 = df["Year_of_Release"].isin(np.arange(1980,1991))

# D1. Dataframe with the total sales from 1980 to 1985
df_sales = df[games8086].pivot_table(values = "Global_Sales", 
                        index = ["Year_of_Release", "Year_str", "Publisher"]) \
                .reset_index().sort_values(["Year_of_Release", "Global_Sales"],
                                           ascending = [True, False]) \
                    .groupby("Publisher")[["Global_Sales"]].sum() \
                        .sort_values("Global_Sales", ascending = False) \
                            .reset_index().head(10)
                            

# D2. Dataframe with the median sales from 1980 to 1985
df_sales_m = df[games8086].pivot_table(values = "Global_Sales", 
                        index = ["Year_of_Release", "Year_str", "Publisher"]) \
                .reset_index().sort_values(["Year_of_Release", "Global_Sales"],
                                           ascending = [True, False]) \
                    .groupby("Publisher")[["Global_Sales"]].median() \
                        .sort_values("Global_Sales", ascending = False) \
                            .reset_index().head(10)



# Top publishers between 1980 and 1990
top_pub = df[df["Year_of_Release"]<=1990].groupby("Publisher").sum("Global_Sales") \
    .sort_values("Global_Sales", ascending = False)["Global_Sales"].head(10)

# D3. Dataframe for Ridge Plot of most frequent companies
df_sales_ts = df[games8090][df["Publisher"].isin(top_pub.index)] \
                .pivot_table(values = "Global_Sales", 
                             index = ["Year_of_Release", "Year_str", "Year_ts",
                                      "Publisher","Platform", "Name"]) \
                .reset_index().sort_values("Year_of_Release", ascending = True)



# D4. Zone dataframe

df_long = df.melt(id_vars = ["Name","Platform","Year_of_Release","Genre",
                           "Publisher", "Developer", "Rating", "Year_str", "Year_ts",
                           "Country", "City"],
                  value_vars = ["NA_Sales", "EU_Sales","JP_Sales","Other_Sales"],
                  var_name = ["Location"],
                  value_name = "Sales")



df_long = df_long.replace({"Location": {"NA_Sales": "North America",
                                        "EU_Sales": "Europe",
                                        "JP_Sales": "Japan",
                                        "Other_Sales": "Rest of the World"} })

# To delete columns without sales registry
df_long =  df_long[df_long["Sales"] > 0].dropna(subset = ["Sales"])


# Mutate new column to plot map
df_long["Place"] =  df_long["Location"]

df_long = df_long.replace({"Place": {"North America": "United States",
                                        "Europe": "Italy",
                                        "Japan": "Japan",
                                        "Other_Sales": "Rest of the World"} })

# Dataframe used in map
df_map = df_long.dropna(subset = ["Year_of_Release"]).groupby(["Place", "Year_str"]) \
                    .sum().reset_index().drop(columns=["Year_of_Release"]) \
                        .rename(columns = {"Year_str":"Year"})



# for row in df_long90["Year_of_Release"]:
#     if row < 1986:
#         yearseg.append("Before")
#     else:
#         yearseg.append("After")
# df_long90["Time"] = yearseg      
    

# ----------------------------------------------------------------------------
# Exploring the data
# ----------------------------------------------------------------------------


df.info()
# <class 'pandas.core.frame.DataFrame'>
# RangeIndex: 16719 entries, 0 to 16718
# Data columns (total 18 columns):
#  #   Column           Non-Null Count  Dtype         
# ---  ------           --------------  -----         
#  0   Name             16717 non-null  object        
#  1   Platform         16719 non-null  object        
#  2   Year_of_Release  16450 non-null  float64       
#  3   Genre            16717 non-null  object        
#  4   Publisher        16665 non-null  object        
#  5   NA_Sales         16719 non-null  float64       
#  6   EU_Sales         16719 non-null  float64       
#  7   JP_Sales         16719 non-null  float64       
#  8   Other_Sales      16719 non-null  float64       
#  9   Global_Sales     16719 non-null  float64       
#  10  Critic_Score     8137 non-null   float64       
#  11  Critic_Count     8137 non-null   float64       
#  12  User_Score       7590 non-null   float64       
#  13  User_Count       7590 non-null   float64       
#  14  Developer        10096 non-null  object        
#  15  Rating           9950 non-null   object        
#  16  Year_ts          16450 non-null  datetime64[ns]
#  17  Year_str         16719 non-null  object        
# dtypes: datetime64[ns](1), float64(10), object(7)

# Valores Nulos

# Podemos observar que en su mayoria el dataset esta conformado por strings y 
#floats. Ahora analizaremos los valores nulos

# Function the plot the percentage of missing values
def na_counter(df):
    for i in df.columns: 
        percentage = 100 - ((len(df[i]) - df[i].isna().sum())/len(df[i]))*100
        if percentage > 5:
            print(i+" has "+ str(round(percentage)) +"% of Null Values")
        else:
            continue
na_counter(df)


df_na = df.isna().sum().reset_index()
df_na.columns = ["Column","Missing_Values"]

gna_df = sns.catplot(data = df_na[df_na["Missing_Values"] > 0].sort_values("Missing_Values", ascending = False),
                      y= "Missing_Values", x= "Column", 
                      kind = "bar", palette="BuGn_r",
                      linewidth = 0, dodge= False) \
                .set(xlabel = "Column Name", 
                     ylabel = "Missing Values") \
                .fig.suptitle("Total of Missing Values per column",
                              y = 1.01)
plt.xticks(rotation=45)

# Se aprecia un valor bastante significativo de valores nulos, principalmente
#en columnas relacionadas a criticas. Sin embargo estas al no ser categoricas
#no tendran un papel de identificador, sino para un estudio muestral posterior 

# Analisis descriptivo

# Los atributos categoricos indican que en los datos contamos con un total de 
#31 plataformas distintas, 12 géneros distintos, 11562 titulos, 582 publishers y
#con 8 de las categorias de Entertainment Software Rating Board (ESRB)
df.describe(include = [object])

# Por otra parte los atributos numericos nos indican que contamos con un total 
#de 40 anos en registros, donde la mediana nos indica que el 50% de los anos
#es menor o igual al ano 2007, indicando que gran parte de los registros se
#atribuyen a los primeros 27 anos
# Tambien se observa que el valor medio de ventas es superior en Norte America,
#pero su variacion es bastante alta por lo que deberia compararse de forma mas
#exhaustiva
df.describe()

# Ahora tanto el user score(0-10) como el critic score(0-100) muestran datos muy cerca de 
#lo que se considera un "juego bueno" mientras que los valores maximos indican
#que tambien estan aquellos muy cerca de ser un "Masterpiece".

# https://corp.ign.com/review-practices

# # Creacion de columna Critic_rate
# df["Critic_rate"] = df["Critic_Score"] / df["Critic_Count"]

# # Creacion de columna User_rate
# df["User_rate"] = ((df["User_Score"]*100)/10) / df["User_Count"]


# ----------------------------------------------------------------------------
## Visualizations
# ----------------------------------------------------------------------------

# Set theme and context
sns.set_theme(style="white", rc={"axes.facecolor": (0, 0, 0, 0)})
sns.set_context("paper")


## ORIGINS SECTION

# Explain that the only two publishers were Atari and Activision during 1980, both from north america
                                               
# G1. Graph with the total sales from 1980 to 1985
gsum8085 = sns.catplot(data = df_sales,
                      y= "Publisher", x= "Global_Sales", 
                      kind = "bar", hue = "Global_Sales",
                      legend=False, palette="GnBu",
                      linewidth = 0, dodge= False) \
                .set(xlabel = "Millions of units sold", 
                     ylabel = "Videogame Title") \
                .fig.suptitle("Total of Units Sold during Golden Age 1980-1985",
                              y = 1.01)



# G2. Graph with the median sales from 1980 to 1985
gmedian8085 = sns.catplot(data = df_sales_m,
                      y= "Publisher", x= "Global_Sales", 
                      kind = "bar", hue = "Global_Sales",
                      legend=False, palette="GnBu",
                      linewidth = 0, dodge= False) \
                .set(xlabel = "Millions of units sold", 
                     ylabel = "Videogame Title") \
                .fig.suptitle("Median Units Sold yearly during Golden Age 1980-1985",
                              y = 1.01)



# G3. Line Plot of Sales from 1980 to 1985
gline8090 = sns.relplot(data = df_sales_ts,
                        x = "Year_ts", y ="Global_Sales", kind = "line",
                        ci = None, style = "Publisher", hue = "Publisher",
                        dashes = False, markers = True) \
                .set(ylabel = "Millions of units sold", 
                     xlabel = "Year") \
                .fig.suptitle("Top Publisher's Units Sold yearly during Golden Age 1980-1990",
                              y = 1.01)
plt.axvline(pd.to_datetime(1986, format='%Y'), color='grey', linestyle='--')



#https://seaborn.pydata.org/examples/timeseries_facets.html

    


# Vs Stacked Barchart of Sales by Platform
df_long87 = df_long[df_long["Year_of_Release"] < 1988]


gsep87 = sns.catplot(data = df_long87.sort_values("Year_of_Release"),
                      x = "Year_str", y ="Sales",
                      hue = "Platform", kind = "bar", ci = None)\
                .set(ylabel = "Millions of units sold", 
                      xlabel = "Year") \
                .fig.suptitle("Videogame Sales by Platform before 1987",
                              y = 1.01)


# G4. Sales by zone
gboxzone = sns.catplot(data = df_long[(df_long["Year_of_Release"] < 1990)] \
                       .sort_values("Sales"),
                       y = "Location",x = "Sales", kind = "box", sym = "",
                       col = "Platform", col_wrap= 2,
                       col_order=['PC','2600', 'NES', 'GB'])

    
box = px.box(df_long[(df_long["Year_of_Release"] < 1990)].sort_values("Sales"),
             x="Location", y="Sales", color="Publisher")
box.update_traces(quartilemethod="exclusive") # or "inclusive", or "linear" by default
box.show()


# for row in df_long90["Year_of_Release"]:
#     if row < 1986:
#         yearseg.append("Before")
#     else:
#         yearseg.append("After")
# df_long90["Time"] = yearseg      
    
df_r = df[df["Rating"].isna() == False]


df_r = df_r.groupby(["Rating","Platform"]).count()["Name"] \
                                    .reset_index() \
                                    .pivot_table(values = "Name", index = "Rating",
                                                 columns = "Platform", aggfunc = [np.sum]) \
                                    .fillna(0)
                                    
                                    