# Load Hmisc for %nin% operator
library(Hmisc)
library(data.table)

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


cat(paste("\n\n## All Areas\n\n"))

# compute totals by type for each class of trip
xt.total<-xtabs(weight~triptype,
              data=df[weekday,]);
xt.person<-xtabs(weight~triptype,
                 data=df[weekday & persontrip,]);
xt.driver<-xtabs(weight~triptype,
                 data=df[weekday & drivertrip,]);

kable(data.table("Trip Type"=names(xt.total),"Total Trips"=xt.total, "% Total"=xt.total/sum(xt.total)*100,"Person Trips"=xt.person,"% Person Trips"=xt.person/sum(xt.person)*100,"Driver Trips"=xt.driver,"% Driver Trips"=xt.driver/sum(xt.driver)*100))

cat("\n")


for ( area in levels( df$AREA ) ) {

    inarea <- df$AREA == area

    # compute totals by type for each class of trip
    xt.total<-xtabs(weight~triptype,
                  data=df[weekday & inarea,]);
    xt.person<-xtabs(weight~triptype,
                     data=df[weekday & persontrip & inarea,]);
    xt.driver<-xtabs(weight~triptype,
                     data=df[weekday & drivertrip & inarea,]);

    cat(paste("\n\n##",area,"\n\n"))

    kable(data.table("Trip Type"=names(xt.total),"Total Trips"=xt.total, "% Total"=xt.total/sum(xt.total)*100,"Person Trips"=xt.person,"% Person Trips"=xt.person/sum(xt.person)*100,"Driver Trips"=xt.driver,"% Driver Trips"=xt.driver/sum(xt.driver)*100))

    cat("\n")
}
