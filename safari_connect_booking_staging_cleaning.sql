schema safari_connect;
SET search_path TO safari_connect;


-- creating statging table "bookings_stagings"

CREATE TABLE IF NOT EXISTS bookings_staging (
    booking_id       TEXT,
    passenger_name    TEXT, 
    passenger_phone  TEXT,
    passenger_gender TEXT, 
    passenger_city    TEXT, 
    route_code       TEXT,
    route_from       TEXT, 
    route_to          TEXT, 
    vehicle_plate    TEXT,
    vehicle_type     TEXT, 
    driver_name       TEXT, 
    driver_rating    TEXT,
    departure_date   TEXT, 
    departure_time    TEXT, 
    seat_class       TEXT,
    seats_booked     TEXT, 
    fare_per_seat     TEXT, 
    total_fare       TEXT,
    payment_method   TEXT, 
    booking_status    TEXT, 
    trip_rating      TEXT
);

select * from safari_connect.bookings_staging bs ;

select count(*) from safari_connect.bookings_staging bs ;

select * from safari_connect.bookings_staging bs limit 10;



-- ===============================================================================================================================

-- 1. Name casing problems
SELECT DISTINCT passenger_name 
FROM safari_connect.bookings_staging 
ORDER BY passenger_name 
LIMIT 30;

-- leading whitespace
-- destanderdized case for the same name -should be uniform proper case -use initcap()

SELECT 
    booking_id, 
    passenger_name 
FROM safari_connect.bookings_staging
WHERE passenger_name != INITCAP(TRIM(passenger_name));  --INITCAP() turns the Names into Proper case, TRIM() removes the whitespaces in the names

UPDATE safari_connect.bookings_staging
SET passenger_name = INITCAP(TRIM(passenger_name))      -- removing leading whitespace and setting case to proper using INITCAP
WHERE passenger_name != INITCAP(TRIM(passenger_name));  -- where passenger_name not in proper case, with no leading whitespace


-- ===============================================================================================================================

--  2. Driver with issues count
select count(*) as driver_names_with_issues
from safari_connect.bookings_staging bs  
where bs.driver_name != initcap(trim(driver_name)); -- 12 driver names not in proper case, and/or having a leading whitespace

-- Updating driver names with issues
UPDATE safari_connect.bookings_staging
SET driver_name = INITCAP(TRIM(driver_name))
WHERE driver_name != INITCAP(TRIM(driver_name)); -- 12 rows/records updated


-- ===============================================================================================================================

-- 3. Gender variants - should be only Male/Female
SELECT 
    DISTINCT passenger_gender,
    COUNT(*) as gender_case_count
FROM safari_connect.bookings_staging 
GROUP BY passenger_gender;

-- F/M to be standerdozed to Female/Male
-- Case to be standerdized

UPDATE safari_connect.bookings_staging
SET passenger_gender = CASE
    WHEN UPPER(TRIM(passenger_gender)) IN ('MALE','M') THEN 'Male'
    WHEN UPPER(TRIM(passenger_gender)) IN ('FEMALE','F') THEN 'Female'
    ELSE passenger_gender
END;


-- ===============================================================================================================================

-- 4. seat_class variants

-- select statement to view and count the numbers for the seat_class case
SELECT 
    DISTINCT seat_class, 
    COUNT(*) as seat_class_count
FROM safari_connect.bookings_staging 
GROUP BY seat_class; -- counting seats 

-- BUS, business, BUSINESS CLASS to be standardized to Business
-- eco, economy, economy class to be standardized to Economy
-- Use CASE - WHEN in UPDATE query to standardize the the seat_classes, 

UPDATE safari_connect.bookings_staging
SET seat_class = CASE
    WHEN UPPER(TRIM(seat_class)) IN ('ECONOMY','ECO','ECONOMY CLASS') THEN 'Economy'    -- standardizing to Economy
    WHEN UPPER(TRIM(seat_class)) IN ('BUSINESS','BUS','BUSINESS CLASS') THEN 'Business' -- standardizing to Business
    ELSE seat_class     -- text already in the standard form is left as is.
END;


-- ===============================================================================================================================

-- 5. payment_method variants

-- Select statement to view and count each unique case for the payment_method
SELECT 
    DISTINCT payment_method, 
    count(*) as payment_method_count
FROM safari_connect.bookings_staging bs 
group by bs.payment_method; 

-- case to be made into proper case for card, cash
-- mpesa, MPESA  standardized to M-Pesa


--  CASE - WHEN in the UPDATE query to standardize the payment_methods 
UPDATE safari_connect.bookings_staging
SET payment_method = CASE
    WHEN UPPER(TRIM(payment_method)) IN ('MPESA','M-PESA','M PESA') THEN 'M-Pesa'
    WHEN UPPER(TRIM(payment_method)) = 'CASH'                       THEN 'Cash'
    WHEN UPPER(TRIM(payment_method)) = 'CARD'                       THEN 'Card'
    ELSE payment_method
END;


-- ===============================================================================================================================

-- 6. booking_status variants

-- select statement to count the number of each the booking_status cases
SELECT 
    DISTINCT booking_status, 
    count(*) as booking_status_case_count
FROM safari_connect.bookings_staging bs 
group by booking_status;

/* 
 * Standeridize case to proper case
 * Remove leading whitespace
 */

UPDATE safari_connect.bookings_staging
SET booking_status = CASE
    WHEN UPPER(TRIM(booking_status)) = 'COMPLETED'  THEN 'Completed'
    WHEN UPPER(TRIM(booking_status)) = 'CANCELLED'  THEN 'Cancelled'
    WHEN UPPER(TRIM(booking_status)) = 'NO SHOW'     THEN 'No Show'
    ELSE booking_status
END;


-- ===============================================================================================================================

-- 7. Date format problems
SELECT 
    booking_id, 
    departure_date 
FROM safari_connect.bookings_staging
WHERE departure_date NOT SIMILAR TO '[0-9]{4}-[0-9]{2}-[0-9]{2}';

-- standerdize to yyyy-mm-dd
-- some dates in dd/mm/yyyy
-- some dates in mm-dd-yy, mm-dd-yyyy

-- Fix DD/MM/YYYY
-- selecting dd/mm/yyyy formats
SELECT 
    booking_id, 
    departure_date 
FROM safari_connect.bookings_staging
where departure_date LIKE '%/%'; -- vuewing dates with a '/' as the separator

-- count all rows with dd/mm/yyyy format
SELECT count(*) as slash_format_dates
FROM safari_connect.bookings_staging
where departure_date LIKE '%/%'; -- 15 dates with '/' as separator

-- updating DD/MM/YYYY to yyyy-mm-dd
UPDATE safari_connect.bookings_staging
SET departure_date = TO_DATE(departure_date,'DD/MM/YYYY')::TEXT
WHERE departure_date LIKE '%/%';


-- Fix DD-MM-YY (length = 8)
-- selecting all rows with DD-MM-YY (length = 8) date format
SELECT 
    booking_id, 
    departure_date
FROM safari_connect.bookings_staging
WHERE departure_date LIKE '%-%' AND LENGTH(departure_date) = 8; -- viewing dates separated by - and only have 8 characters. 

-- count all rows with DD-MM-YY (length = 8)
SELECT count(*) as dash_separated_dates 
FROM safari_connect.bookings_staging
WHERE departure_date LIKE '%-%' AND LENGTH(departure_date) = 8; -- 14 dates counted

-- updating DD-MM-YY (length = 8)
UPDATE safari_connect.bookings_staging
SET departure_date = TO_DATE(departure_date,'DD-MM-YY')::TEXT
WHERE departure_date LIKE '%-%' AND LENGTH(departure_date) = 8; -- 14 rows updated

-- Fix MM-DD-YYYY (length=10, day part > 12 confirms it's MM-DD not DD-MM)

-- count rows with MM-DD-YYYY (length=10, day part > 12 confirms it's MM-DD not DD-MM)
SELECT count(*) as mm_dd_dates_count
FROM safari_connect.bookings_staging
WHERE departure_date LIKE '%-%'
  AND LENGTH(departure_date) = 10
  AND SPLIT_PART(departure_date,'-',2)::INTEGER > 12; -- 9 rows counted

UPDATE safari_connect.bookings_staging
SET departure_date = TO_DATE(departure_date,'MM-DD-YYYY')::TEXT
WHERE departure_date LIKE '%-%'
  AND LENGTH(departure_date) = 10
  AND SPLIT_PART(departure_date,'-',2)::INTEGER > 12; -- 9 rows updated


-- ===============================================================================================================================

-- 8. Phone format problems
SELECT 
    booking_id, 
    passenger_phone 
FROM safari_connect.bookings_staging bs
WHERE passenger_phone LIKE '+254%' OR passenger_phone LIKE '%-%';

-- some phone numbers in the format ****-***-***
-- some phone numbers in the format +254***** - standerdize leading "+254" to be 0

-- Remove dashes
UPDATE safari_connect.bookings_staging
SET passenger_phone = REGEXP_REPLACE(passenger_phone,'[^0-9]','','g') -- replacing all characters not in range 0-9 with a null
WHERE passenger_phone LIKE '%-%';   -- checking phone numbers with a dash anywhere in the number

-- Fix +254 prefix
UPDATE safari_connect.bookings_staging
SET passenger_phone = '0' || SUBSTRING(REGEXP_REPLACE(passenger_phone,'[^0-9]','','g'),4) -- substring checks first 4 values and replaces them with 0, all other values not in range 0-9 are replaced with null
WHERE passenger_phone LIKE '+254%'; -- where passenger phone starts with "+254"

-- Set empty to NULL
UPDATE safari_connect.bookings_staging SET passenger_phone = NULL
WHERE TRIM(passenger_phone) = ''; -- where no passenger phone provided, replace it with null


-- ===============================================================================================================================

-- 9. Fares stored as text
SELECT 
    booking_id, 
    total_fare, 
    fare_per_seat 
FROM safari_connect.bookings_staging bs
WHERE total_fare LIKE 'KES%' OR fare_per_seat LIKE 'KES%'; -- selecting total_fare or fare_per_seat with leading 'KES'

-- counting rows
SELECT 
    count(total_fare), 
    count(fare_per_seat) 
FROM safari_connect.bookings_staging bs
WHERE total_fare LIKE 'KES%' OR fare_per_seat LIKE 'KES%';

-- remove KES
UPDATE safari_connect.bookings_staging
SET total_fare = REGEXP_REPLACE(total_fare,'[^0-9.]','','g') -- replacing all characters not in range 0-9 with empty.
WHERE total_fare SIMILAR TO '%[^0-9.]%';

UPDATE safari_connect.bookings_staging
SET fare_per_seat = REGEXP_REPLACE(fare_per_seat,'[^0-9.]','','g') -- replacing all characters not in range 0-9 with empty.
WHERE fare_per_seat SIMILAR TO '%[^0-9.]%';


-- ===============================================================================================================================

-- 10. Invalid trip ratings

SELECT booking_id, trip_rating FROM safari_connect.bookings_staging bs 
WHERE trip_rating NOT IN ('1','2','3','4','5',''); -- selecting all instances where trip_rating does not match any value in fieldset.

-- values not in range of 1 to 5 to be standerdized to NULL ie. 0, 6 and 7.

-- count the values not in range of 0 to 5
SELECT count(*) as invalid_rating_count
FROM safari_connect.bookings_staging bs 
WHERE trip_rating NOT IN ('1','2','3','4','5',''); -- 13 rows/records counted

UPDATE safari_connect.bookings_staging
SET trip_rating = NULL
WHERE TRIM(trip_rating) NOT IN ('1','2','3','4','5',''); -- 13 rows updated


-- ===============================================================================================================================

-- 11. Duplicate booking_ids

SELECT 
	booking_id, 
	COUNT(*) as booking_id_count
FROM safari_connect.bookings_staging bs 
GROUP BY booking_id HAVING COUNT(*) > 1; -- booking id is unique thus if appears more than once indicates duplication

-- BK0005 appears twice in the table - remove the duplicate

select * from safari_connect.bookings_staging
where booking_id = 'BK0005'; -- selecting all rows with booking id "BK0005" to verify duplication

-- Remove exact duplicates (keep first ctid)
DELETE FROM safari_connect.bookings_staging
WHERE ctid NOT IN 
    (SELECT MIN(ctid) FROM safari_connect.bookings_staging GROUP BY booking_id);

-- ===============================================================================================================================

-- 12. Negative seats_booked
SELECT 
	booking_id, 
	seats_booked 
FROM safari_connect.bookings_staging bs
WHERE NULLIF(REGEXP_REPLACE(seats_booked,'[^0-9-]','','g'),'')::INTEGER < 1; -- 1 record found.

-- BK9002 has -1 seats booked standerdize to 0/null?

-- Delete rows with negative seats
DELETE FROM safari_connect.bookings_staging
WHERE NULLIF(REGEXP_REPLACE(seats_booked,'[^0-9-]','','g'),'')::INTEGER < 1;


-- ===============================================================================================================================

-- 13. Passenger City Cleaning
select passenger_city from safari_connect.bookings_staging;

--Convert to Proper Case
--Remove leading whitespaces
--Coalese empty city row to Unknown

select 
	passenger_city, 
	count(*) as passenger_city_case_count
from safari_connect.bookings_staging 
WHERE passenger_city != INITCAP(TRIM(passenger_city))
group by passenger_city; -- 23 passenger cities not in proper case

UPDATE safari_connect.bookings_staging
SET passenger_city = INITCAP(TRIM(passenger_city))
WHERE passenger_city != INITCAP(TRIM(passenger_city)); 

select count(*) as empty_passenger_city_count
from safari_connect.bookings_staging
WHERE passenger_city = '' OR passenger_city IS NULL; -- 13 passenger_city instances were empty

UPDATE safari_connect.bookings_staging SET passenger_city = 'Unknown'
WHERE TRIM(passenger_city) = '' OR passenger_city IS NULL;


-- ===============================================================================================================================

-- 14. Vehicle type casing 
select vehicle_type from safari_connect.bookings_staging bs 
WHERE bs.vehicle_type != INITCAP(TRIM(vehicle_type));

-- casing issues

select count(*) as vehicle_type_case_count from safari_connect.bookings_staging bs 
WHERE bs.vehicle_type != INITCAP(TRIM(vehicle_type)); -- 13 rows/records counted.

UPDATE safari_connect.bookings_staging
SET vehicle_type = INITCAP(TRIM(vehicle_type))
WHERE vehicle_type != INITCAP(TRIM(vehicle_type)); -- 13 records updated.



select * from  safari_connect.bookings_staging;

