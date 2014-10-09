
# Load one of the many Postgresql interface library
library(RPostgreSQL)

# create an PostgreSQL instance and create one connection.
drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname="chts-2010", user="postgres", port=5433)

# query the linked trip table and put into a data frame
rs <- dbSendQuery(con,
                  paste("select tmode as \"MODE\", ","triptype,\"DOW\",",
                           "array_avg(exptcfperwgt) as weight, perwgt[1], tcf, ",
                           "tcfperwgt[1] tcfperwgt, hh.\"AREA\" ",
                        "from tbllinkedtrip",
                        " left join deliv_hh hh using (\"SAMPN\")"))
df <- fetch(rs, n = -1)

# assign factor labels
df$triptype <- factor(
   df$triptype,
   levels=c("HW","HO","HS","WO","OO"),
   labels=c("Home-Work","Home-Other","Home-Shop","Work-Other","Other-Other")
    );

df$DOW <- factor(
    df$DOW,
    levels=c(1,2,3,4,5,6,7),
    labels=c("Mo","Tu","We","Th","Fr","Sa","Su")
    )

df$MODE <- factor(
    df$MODE,
    levels=seq(1,29),
    labels=c(
        "Walk",
        "Bike",
        "Wheelchair / Mobility Scooter",
        "Other Non-Motorized",
        "Auto / Van / Truck Driver",
        "Auto / Van / Truck Passenger",
        "Carpool / Vanpool",
        "Motorcycle / Scooter / Moped",
        "Taxi / Hired Car / Limo",
        "Rental Car/Vehicle",
        "Private shuttle (SuperShuttle, employer, hotel, etc.)",
        "Greyhound Bus",
        "Plane",
        "Other Private Transit",
        "Local Bus, Rapid Bus",
        "Express Bus / Commuter Bus (AC Transbay, Golden Gate Transit, etc)",
        "Premium Bus ( Metro Orange / Silver Line )",
        "School Bus",
        "Public Transit Shuttle (DASH, Emery Go Round, etc.)",
        "AirBART / LAX FlyAway",
        "Dial-a-Ride / Paratransit (Access Services, etc.)",
        "Amtrak Bus",
        "Other Bus",
        "BART, Metro Red / Purple Line",
        "ACE, Amtrak, Caltrain, Coaster, Metrolink",
        "Metro Blue / Green / Gold Line, Muni Metro, Sacramento Light Rail, San Diego Sprinter / Trolley / Orange/Blue/Green, VTA Light Rail",
        "Street Car / Cable Car",
        "Other Rail",
        "Ferry / Boat"))

df$AREA <- factor (
    df$AREA,
    levels=seq(1,39),
    labels=c(
        "Alpine",
        "Amador",
        "AMBAG",
        "Butte",
        "Calaveras",
        "Colusa",
        "Del Norte",
        "Fresno",
        "Glenn",
        "Humboldt",
        "Inyo",
        "Kern",
        "Kings",
        "Lake",
        "Lassen",
        "Madera",
        "Mariposa",
        "Mendocino",
        "Merced",
        "Modoc",
        "Mono",
        "MTC",
        "Nevada",
        "Plumas",
        "SACOG",
        "San Joaquin",
        "San Luis Obispo",
        "SANDAG",
        "Santa Barbara",
        "SCAG",
        "Shasta",
        "Sierra",
        "Siskiyou",
        "Stanislaus",
        "Tehama",
        "TMPO",
        "Trinity",
        "Tulare",
        "Tuolumne"))
