# Load Hmisc for %nin% operator
library(Hmisc)

weekend <- df$DOW %in% c("Sa","Su")
weekday <- df$DOW %nin% c("Sa","Su")

# Per CHTS 2001:
# * Person trips include all trips except walk, bicycle, airplane-commercial,
#   Airplane private, and "other" mode trips.
# * Driver trips include automobile, pickup truck, RV, Sport Utility Vehicle,
#   van, truck, and motorcycle/Moped driver trips
persontrip <- df$MODE %nin% c("Walk","Bike", "Wheelchair / Mobility Scooter",
                              "Other Non-Motorized", "Other Private Transit",
                              "Other Bus", "Other Rail")

drivertrip  <- df$MODE %in% c("Auto / Van / Truck Driver", "Motorcycle / Scooter / Moped")

# side by side plots
par(mfrow=c(1,2),mar=c(1.5,1.5,2,1.5))

# create cross tabulation of summed weights grouped by triptype
# ...and filtered for non weekend days
xt<-xtabs(weight~triptype, data=df[weekday & persontrip,]);
pie(xt/sum(xt),
    main=paste("Person Trips","\n",paste("(",prettyNum(sum(xt),big.mark=",",scientific=F)," total weighted trips",")",sep=""),sep=""),
    labels=paste(names(xt),"\n", sprintf("%1.2f%%",xt/sum(xt)*100,sep="")))

xt<-xtabs(weight~triptype, data=df[weekday & drivertrip,])
pie(xt/sum(xt),
    main=paste("Driver Trips","\n",paste("(",prettyNum(sum(xt),big.mark=",",scientific=F)," total weighted trips",")",sep=""),sep=""),
    labels=paste(names(xt),"\n", sprintf("%1.2f%%",xt/sum(xt)*100,sep="")))

