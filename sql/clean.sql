

--- Here we create a view that generates linked trips and gives each a distinct,
--- ordered, ID
drop view if exists linked_trip_order cascade;
create or replace view linked_trip_order AS 
-- This query generates the ordered linked trips for each SAMPN, PERNO with
-- merged aggregates based upon the unique linked trip numbering generated in
-- the embedded subquery `q`
select 
       -- Rows for this view are ordered linked trips for each SAMPN, PERNO
       qq."SAMPN",qq."PERNO",qq.linked_tripno,

       --- We tack on some aggregated values for later use
       --- NOTE: array_agg is a postgresql function
       array_agg(qq."PLANO") jplano,  -- array of joined place numbers for this linked trip (1 or more)
       array_agg(qq."ACTNO") jactno,  -- array of joined activity numbers (1 or more)
       array_agg(qq."APURP") jpurp,   -- array of joined purposes (1 or more)
       array_agg(qq.adjtripno) jtrip, -- array of adjusted trip numbers [nulls -> 0] (1 or more)

       array_agg(dp."PERWGT") perwgt,
       array_agg(dp."EXPPERWGT") expperwgt,
       array_agg(dp."TCF") tcf,
       array_agg(dp."TCFPERWGT") tcfperwgt,
       array_agg(dp."EXPTCFPERWGT") exptcfperwgt,

       SUM(dp."TRIPDUR") trpdur,         -- sum of durations of joined trips
       SUM(dp."ACTDUR") jactdur           -- sum of activity durations of joined trips/activities
from (
        select *, 
               -- this record is the point of this subquery.  We sum the linked_tripcnt of the ordered query
               -- to generate a unique linked trip number for every activity
               sum(linked_tripcnt) OVER (ORDER BY "SAMPN","PERNO","PLANO","ACTNO",adjtripno) AS linked_tripno 
        from (
                --- this subquery generates an ordered listing of trips where
                --- adjacent pick-up/delivery or mode switches are collapsed
                --- into a single trip
                SELECT da."SAMPN",da."PERNO",da."PLANO",da."ACTNO",
                       null_to_zero("TRIPNO") adjtripno,  -- convert NULL tripno to 0 for later computation
                       da."APURP",

                       --- compute the linked trip counter...
                       --- linked_tripcnt is zero if...
                       case when 
                            -- the place number is the same
                                 -- this makes sure we capture all distinct
                                 -- *activities*, which means they might be
                                 -- occuring at the same location.
                                 -- "PLANO" = lag("PLANO") over (PARTITION BY "SAMPN","PERNO" ORDER BY null_to_zero("TRIPNO")) 
                                 false  -- not sure we want the above so omitting

                            -- OR the trip number differs from the last AND the trip purpse is 
                            --    APURP=21:Mode change/Transfer; 22:Pick-up/Drop off 
                                 OR (
                                        null_to_zero("TRIPNO") <> lag(null_to_zero("TRIPNO")) 
                                              OVER (PARTITION BY "SAMPN","PERNO" ORDER BY null_to_zero("TRIPNO")) 
                                        AND lag("APURP") 
                                              OVER (PARTITION BY "SAMPN","PERNO" ORDER BY null_to_zero("TRIPNO")) 
                                              NOT IN (21,22)
                                    ) 
                            THEN 1    -- increment the linked trip count
                            ELSE 0    -- DON'T increment the linked trip count
                            END AS linked_tripcnt

                FROM deliv_activity da
                ORDER BY null_to_zero("TRIPNO"),"PLANO","ACTNO"
             ) q
) qq 
     LEFT JOIN deliv_place dp USING ( "SAMPN","PERNO","PLANO")
     GROUP BY "SAMPN","PERNO",linked_tripno order by "SAMPN","PERNO",linked_tripno;


-- This is an intermediate view that we use to add the origin and destination
-- place/activity pairs to the linked_trip_order view
DROP VIEW IF EXISTS ltf CASCADE;
CREATE OR REPLACE VIEW ltf AS
SELECT linked_tripno -- unique linked trip number (to index)
       ,lto."SAMPN"  -- hh number (key)
       , lto."PERNO" -- person number in hh (key)

       -- Here, use window functions to get the last place/activity from the
       -- prior record for this person.  Since we've ordered the trips, this
       -- will be the source place/activity for this trip
       , last_elem(lag(jplano) OVER (PARTITION BY "SAMPN","PERNO" ORDER BY "SAMPN","PERNO",linked_tripno)) source_plano    -- origin "place" of this trip
       , last_elem(lag(jactno) OVER (PARTITION BY "SAMPN","PERNO" ORDER BY "SAMPN","PERNO",linked_tripno)) AS source_act   -- activity from which this trip leaves

       -- the dest place/activity is simply the last of the joined
       -- place/activities in this linked trip
       , last_elem(jplano) dest_plano   -- destination "place" of this trip
       , last_elem(jactno) as dest_act  -- activity to which this trip arrives

       -- pass along the place/activity arrays for convenience
       , jplano
       , jactno

       -- pass along the trip and activity durations for this linked trip
       , trpdur
       , jactdur

       -- pass along weights
       , perwgt
       , expperwgt
       , tcf
       , tcfperwgt
       , exptcfperwgt
       
FROM linked_trip_order lto;

-- this is the final view, that adds the details for the source and destination
-- ends of each linked trip
DROP VIEW IF EXISTS theone CASCADE;
CREATE OR REPLACE VIEW theone AS
SELECT ltf.* 
       , NULL dayno  -- legacy
       , NULL source_locno   -- legacy specification of geocoded source location
       , NULL dest_locno     -- legacy specification of geocoded destination location
       , NULL dtype          -- ?? Destination type?
       , dpdst."MODE" tmode  -- primary mode of travel---*last* mode of joined travel
       , NULL mapped_mode    -- primary mode mapped to reduced mode class

       -- HW, HO, HS, WO, OO
       , canonical_trip_type(canonical_place_type(dpsrc."PNAME",dasrc."APURP")
                             || canonical_place_type(dpdst."PNAME",dadst."APURP"))
         AS triptype

       , dpsrc."DEP_HR" dep_hr         -- depature hour
       , dpsrc."DEP_MIN" dep_min       -- depature min
       , dpdst."ARR_HR" arr_hr         -- arrival hour
       , dpdst."ARR_MIN" arr_min       -- arrival min
       , dpdst."ACTDUR" AS actdur      -- duration of activity at destination
       , jactdur - dpdst."ACTDUR" AS ignoredactdur  -- duration of transit/serve passenger type activities
       , null vehavail       -- ?? whether a vehicle was available to the traveler?
       , null vehno          -- ?? HH vehicle used?
       , null party          -- ?? number of travelers in party?, null or 1 if 1
       -- , null DOM_WDWGT
       -- , null DOM_WEWGT
       -- , null DOM_SDWGT
       -- , null DOM_AWDWGT
       -- , null DOM_ASDWGT
       -- , null Orig_DOM_AWDWGT
       -- , null Orig_DOM_WEWGT
       -- , null PHASE 
       from ltf

       -- join the activity and place tables for the source and destination ends
       -- of the trip
       left join deliv_activity dasrc 
            ON (ltf."SAMPN" = dasrc."SAMPN" AND ltf."PERNO" = dasrc."PERNO" 
                AND ltf.source_plano = dasrc."PLANO" AND ltf.source_act = dasrc."ACTNO" )
       left join deliv_activity dadst
            ON (ltf."SAMPN" = dadst."SAMPN" AND ltf."PERNO" = dadst."PERNO" 
                AND ltf.dest_plano = dadst."PLANO" AND ltf.dest_act = dadst."ACTNO" )
       left join deliv_place dpsrc
            ON (ltf."SAMPN" = dpsrc."SAMPN" AND ltf."PERNO" = dpsrc."PERNO" 
                AND ltf.source_plano = dpsrc."PLANO" )
       left join deliv_place dpdst
            ON (ltf."SAMPN" = dpdst."SAMPN" AND ltf."PERNO" = dpdst."PERNO" 
                AND ltf.dest_plano = dpdst."PLANO" )
       left join deliv_per p
            ON (ltf."SAMPN" = p."SAMPN" AND ltf."PERNO" = p."PERNO") 

       -- Omit records where the source place and destination place are
       -- identical or it's the first place/activity for the person (those
       -- aren't trips!)
       where ltf.source_plano != ltf.dest_plano AND ltf.source_plano IS NOT NULL AND ltf.source_act IS NOT NULL
       order by ltf."SAMPN", ltf."PERNO", source_plano, source_act;

--- Finally, create the linked trip table
drop table tbllinkedtrip;
select * into tbllinkedtrip from theone;
