% 2010 California Household Travel Survey
% Linked Trip Summaries
% %%%DATE%%%

# Linking the trips


# connect to the database
```{r eval=TRUE,echo=TRUE,warning=FALSE,message=FALSE,fig.keep='none'}
library(RPostgreSQL)
con <- dbConnect(drv, dbname="chts-2010", user="postgres")

# query the linked trip table and put into a data frame
rs <- dbSendQuery(con,"select * from tbllinkedtrip")
df <- fetch(rs, n = -1)
```





