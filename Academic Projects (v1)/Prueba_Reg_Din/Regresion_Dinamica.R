
library(fpp2) # Datasets packages
library(ggplot2)
library(forecast)
library(xts)
library(astsa) # Extras de analisis estadistico de series de tiempo

# Tema
my_theme1 <- theme(rect = element_blank(), axis.line = element_line(color = "#DADADA"), 
                   axis.title = element_text(size = 10, color = "#505050", face = "italic"), 
                   axis.text = element_text(size = 9, color = "#505050"),
                   title = element_text(size = 13, color = "black"),
                   panel.grid.major.y = element_line(color = "#F3F3F3"),
                   legend.position = "top", legend.text = element_text(size = 9),
                   legend.title = element_text(size = 10, face = "bold"), legend.direction = "horizontal",
                   plot.caption = element_text(color = "black", size = "8", hjust = 0))

## Ejemplo de Modelo de Consumo electrico acorde a variable exógena de ingresos

# Este es un ejemplo de datos estacionarios donde la media y la varianza se mantienen relativamente constantes en el tiempo
autoplot(uschange[,1:2], facets=TRUE) +
  xlab("Año") + ylab("") +
  ggtitle("Cambio cuatrimestral de consumo con respecto a ingresos en US") + my_theme1

# Ahora lo ajustamos a un modelo en donde no hay que especificar una diferencia en el argumento order puesto a que ya es estacionaria 
(modelo <- auto.arima(uschange[,"Consumption"],
                   xreg=uschange[,"Income"]))
#> Series: uschange[, "Consumption"] 
#> Regression with ARIMA(1,0,2) errors 
#> 
#> Coefficients:
#>         ar1     ma1    ma2  intercept   xreg
#>       0.692  -0.576  0.198      0.599  0.203
#> s.e.  0.116   0.130  0.076      0.088  0.046
#> 
#> sigma^2 estimated as 0.322:  log likelihood=-156.9
#> AIC=325.9   AICc=326.4   BIC=345.3

# Observamos que los residuos son de ruido blanco
cbind("Regression Errors" = residuals(modelo, type="regression"),
      "ARIMA errors" = residuals(modelo, type="innovation")) %>%
  autoplot(facets=TRUE) + my_theme1

# Una vista mas detallada con grafica de autocorrelacion
checkresiduals(modelo)
# Y probamos la aleatoriedad de los retardos, como podemos ver se acepta la hipotesis nula por lo que si es de ruido blanco



## Ejemplo de consumo electrico acorde a variable exogena de Temperatura ambiental maxima diaria

# Inicialemente estudiamos la correlacion de los datos tanto de consumo electrico como de temperatura
elec2 <- cbind(as.data.frame(elecdaily[,"Temperature"]), as.data.frame(elecdaily[,"Demand"]))
names(elec2) <- c("Temperature", "Demand")
ggplot(elec2, aes(x = elec2$Temperature, y = elec2$Demand)) + geom_point() +
ggtitle("Demanda electrica versus Temperatura maxima diaria en Victoria, Australia 2014") + 
  labs(x = "Temperatura maxima diaria", y = "Demanda electrica") + 
  my_theme1


# Vemos el comportamiento individual tanto de los ingresos como del consumo

cbind("Temperatura" = elecdaily[,"Temperature"], "Demanda Electrica" = elecdaily[,"Demand"]) %>%
  autoplot(facets=TRUE) + my_theme1


# Para corroborar hacemos la prueba de Ljung-Box

# En este caso implementaremos las variables exogenas de Temperatura, la Temperatura al cuadrado y la variable dummy que define si corresponde o no a un día laboral

xreg <- cbind(MaxTemp = elecdaily[, "Temperature"],
              MaxTempSq = elecdaily[, "Temperature"]^2,
              Workday = elecdaily[, "WorkDay"])
modelo2 <- auto.arima(elecdaily[, "Demand"], xreg = xreg)
checkresiduals(modelo2)


# Ahora hacemos una prediccion

fcast <- forecast(modelo2,
                  xreg = cbind(MaxTemp=rep(26,14), MaxTempSq=rep(26^2,14),
                               Workday=c(0,1,0,0,1,1,1,1,1,0,0,1,1,1)))
autoplot(fcast) + ylab("Demanda Electrica (GW)") + my_theme1



# Ahora como se apreciaría el modelo sin las variables exogenas de por medio?

modelo3 <- auto.arima(elecdaily[, "Demand"])

fcast <- forecast(modelo3)
autoplot(fcast) + ylab("Demanda Electrica sin variable de temperatura (GW)") + my_theme1
