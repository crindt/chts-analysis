-- Function to determine the "TYPE" of a "place" based upon 
--   $1: the place name
--   $2: the activity type performed at that place
CREATE OR REPLACE FUNCTION canonical_place_type (VARCHAR(510),INTEGER) 
RETURNS character(1) AS $$
       SELECT (CASE WHEN $1 = 'HOME' THEN 'H'
                    WHEN $1 = 'WORK' OR $2 IN (9
                                              --,11,12,16,25
                                              ) THEN 'W'
                    -- NOTE:
                    -- 9=WORK/JOB DUTIES
                    -- 11=MEALS AT WORK 
                    -- 12=WORK-SPONSORED SOCIAL ACTIVITIES
                    -- 16=ALL OTHER WORK-RELATED ACTIVITIES AT MY WORK 
                    -- 25=WORK-RELATED (MEETING, SALES CALL, DELIVERY)
                    WHEN $2 IN (26,27,28,29) THEN 'S'
                    -- 26=SERVICE PRIVATE VEHICLE (GAS, OIL, LUBE, REPAIRS)
                    -- 27=ROUTINE SHOPPING (GROCERIES, CLOTHING...)
                    -- 28=SHOPPING FOR MAJOR PURCHASES OR SPECIALTY ITEMS...
                    -- 29=HOUSEHOLD ERRANDS (BANK, DRY CLEANING, ETC.)
                    ELSE 'O'
                    END)
$$ LANGUAGE SQL;

-- Convert directional trip types to canonical trip types
--   $1: A two character string representing the "place" "types" of a trip's
--       origin and destination
--
-- We follow standard conventions here:
--
--   * Any trips with an origin or destination at home is a home-based trip so
--     WH->HW, SH->HS, OH->HO.  Similarly, any trip with and origin or
--     destination at work but *without* an end at home is a work based trip so
--     OW->WO, SW->WS.  Everything else is an OO trip.
CREATE OR REPLACE FUNCTION canonical_trip_type (CHARACTER(2)) 
RETURNS character(2) AS $$
 SELECT (CASE WHEN $1 = 'WH' THEN 'HW'
            WHEN $1 = 'OH' THEN 'HO'
            WHEN $1 = 'SH' THEN 'HS'
            WHEN $1 = 'OW' THEN 'WO'
            WHEN $1 = 'SS' THEN 'OO'
            WHEN $1 = 'OS' THEN 'OO'
            WHEN $1 = 'SO' THEN 'OO'
            WHEN $1 = 'WS' THEN 'OO'
            WHEN $1 = 'SW' THEN 'OO'
            -- treat HH trips as HO, we see these in linked trips when someone
            -- drops people off and returns home
            WHEN $1 = 'HH' THEN 'HO'
            -- treat WW trips as WO, we see these in linked trips when someone
            -- drops people off and returns to work, and when someone travels to
            -- perform work-related business from their workplace
            WHEN $1 = 'WW' THEN 'WO'
            ELSE $1
            END);
$$ LANGUAGE SQL;

