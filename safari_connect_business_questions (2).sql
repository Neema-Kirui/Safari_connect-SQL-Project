-- ===============================================================================================================================
/* 1	Route Analysis 
 * 		Which routes earn the most? Which are most popular? Which is most efficient per seat sold?
		Specific route codes with KES figures. A clear top route and a clear underperformer.
*/

-- 1A - Revenue and bookings by route

-- Show: route_code, route_from, route_to, total_bookings, total_seats, total_revenue,
--		 avg_fare, avg_trip_rating.
--		 Order by total_revenue descending.


SELECT
    route_code,
    route_from || ' → ' || route_to      AS route,
    COUNT(*)                             AS total_bookings,
    SUM(seats_booked)                    AS total_seats,
    SUM(total_fare)                      AS total_revenue,
    ROUND(AVG(fare_per_seat), 2)    	 AS avg_fare,
    ROUND(AVG(trip_rating), 2)     		 AS avg_rating
FROM safari_connect.v_clean_trips
GROUP BY route_code, route_from, route_to
ORDER BY total_revenue DESC;

-- ===============================================================================================================================

/* 1B - Revenue per seat by route (efficiency metric)
		Which route earns the most per seat sold? 
		Show route, total_revenue, total_seats, and revenue_per_seat = total_revenue / total_seats.
*/

-- average fare per seat = total fare / total seats booked
select 
	route_code, 
	sum(seats_booked) as total_seats,
	sum(total_fare) as total_revenue,
	round(sum(total_fare) / sum(seats_booked), 2) as fare_per_seat
from safari_connect.v_clean_trips vct 
group by route_code
order by fare_per_seat desc;

-- route RT001 has the highest revenue per seat with avg fare of 1,258.54
-- route RT005 has the lowest revenue per seat with avg fare of 122.9.

-- ===============================================================================================================================

/* 1C - Route ranking with window function
		Rank all routes by total revenue using RANK(). 
		Also show each route's percentage of total company revenue.
*/

WITH route_rev AS (
    SELECT route_code, 
    	   route_from || ' → ' || route_to AS route,
           SUM(total_fare) AS revenue
    FROM safari_connect.v_clean_trips GROUP BY route_code, route_from, route_to
)
SELECT
    route, 
    revenue,
    RANK() OVER (ORDER BY revenue DESC)       		 AS revenue_rank,
    ROUND(revenue * 100.0 / SUM(revenue) OVER (), 1) AS pct_of_total
FROM route_rev 
ORDER BY revenue_rank;

-- nairobi to mombasa route has highest revenue of 51,600 which constitutes 23% of total revenue.
-- nairobi to machakos route has the lowest revenue of 6,900 which makes up 3.1% of total revenue.


-- ===============================================================================================================================

/* 1D - Vehicle type performance
		Compare Bus vs Matatu vs Minibus - total bookings, revenue, avg rating.
		 Which vehicle type is most profitable?
*/
	
select vehicle_type,
	   sum(seats_booked) as total_bookings,
	   sum(total_fare) as total_revenue,
	   round(avg(trip_rating), 2) as avg_rating
from safari_connect.v_clean_trips vct 
group by vct.vehicle_type;

-- bus have highest total bookings 180, matatu with 155 and minibus lowest with 105 booked seats
-- matatus have highest revenue at 85,135. bus have a revenue of 83,505 and minibus have a revenue of 55,330.
-- minibus have an avg rating of 3.1, matatus have an avg rating of 3.42 and bus have an avg ratung of 3.5
	   
-- ===============================================================================================================================


/* Question 2 - Driver Performance

	Business need: HR wants to know who to promote, who needs training, and whether driver rating affects passenger satisfaction.
*/

/* 2A - Driver summary
Show: driver_name, total_trips, total_seats_carried, total_revenue, avg_trip_rating, driver_rating. Order by total_revenue descending.
*/

select driver_name,
		count(*) as total_trips,
		sum(seats_booked) as total_seats_carried,
		sum(total_fare) as total_revenue,
		round(avg(trip_rating), 2) as avg_trip_rating,
		avg(driver_rating) as driver_rating
from safari_connect.v_clean_trips vct
group by vct.driver_name
order by total_revenue desc;

-- driver peter ngugi has the highest total trips made at 35 while Brian Kamau has the lowest trips made at 25 trips.
-- driver Isaac Korir has the highest total revenue at 32,505 while Peter Ngugi has the lowest total revenue at 23,880.
-- driver Hasan Abdi has the highest avg trip rating at 3.9 while Moses Kipchoge has the lowest avg trip rating at 3.12.


-- ===============================================================================================================================

/* 2B - Driver ranking - overall + by vehicle type
Using a CTE for driver totals, rank drivers overall by revenue AND within their vehicle type using PARTITION BY vehicle_type.
*/

WITH driver_totals AS (
    SELECT
        driver_name,
        vehicle_type,
        COUNT(*)           AS total_trips,
        SUM(total_fare)    AS total_revenue,
        ROUND(AVG(trip_rating),2) AS avg_passenger_rating
    FROM safari_connect.v_clean_trips
    GROUP BY driver_name, vehicle_type
)
SELECT
    driver_name, 
    vehicle_type, 
    total_trips, 
    total_revenue, 
    avg_passenger_rating,
    RANK() OVER (ORDER BY total_revenue DESC)                        AS overall_rank,
    RANK() OVER (PARTITION BY vehicle_type ORDER BY total_revenue DESC) AS vehicle_rank
FROM driver_totals
ORDER BY overall_rank;


-- driver Isaas Korir is the highest rated by total revenue of 32,505
-- Isaac korir and Kevin Omondi have the highest total trips i.e 31 trips with only one vehicle type
-- Samuel GItonga has trips with 2 vehicle types, thus his total trips = 33. 
-- driver Samuel Gitonga has 31 trips in a minibus with a total revenue of 27,755 and an avg passenger rating of 3.53
-- as well as 2 trips with a bus with a total revenue of 480, and an avg passenger rating of 4.5


-- ===============================================================================================================================

/* 2C - Does driver rating predict passenger satisfaction?
		Group drivers into high-rated (≥ 4.5) and standard (< 4.5).
 		Compare average passenger trip_rating for each group.
 		 Does a higher driver rating lead to happier passengers?
*/

-- checking avg driver rating and avg passenger rating for each driver
with driver_avg_rating as (
	select 	driver_name, 
			avg(driver_rating) as drv_rating,
			round(avg(trip_rating), 2) as passngr_rating
	from safari_connect.v_clean_trips vct 
	group by driver_name
), 
-- categorizing the driver ratings using a CASE WHEN CLAUSE to label drivers as either high rated or standard.
	category_driver as (
	select 	dar.driver_name,
			dar.drv_rating,
			case 
				when dar.drv_rating >= 4.5 then 'High-rated' -- driver with avg rating > or equal to 4.5 is labelled high rated
				else 'standard'		-- else labelled standard
			end
			as driver_category
	from driver_avg_rating dar
)
-- checking the avg driver rating and passenger rating for drivers in each driver category.
select cd.driver_category, 
		round(avg(dar.drv_rating), 2) as driver_rating, 
		round(avg(dar.passngr_rating), 2) as passenger_rating
from category_driver cd 
join driver_avg_rating dar
on cd.driver_name = dar.driver_name 
group by cd.driver_category ;

-- high rated drivers have a lower avg passenger rating of 3.34 with an avg driver rating of 4.63.
-- standard drivers have a higher avg passenger rating of 3.64 with an avg driver rating of 4.06.


-- ===============================================================================================================================

/* Question 3 - Revenue Trends

Business need: The Director wants to see if Safari Connect is growing and which months to focus on for expansion.
*/


/* 3A - Monthly revenue with month-over-month change (CTE + LAG) */

WITH monthly AS (
    SELECT
        TO_CHAR(departure_date, 'YYYY-MM') 	  AS month, -- extracting year and month
        COUNT(*)                              AS bookings, -- bookings in the month
        SUM(total_fare)                       AS revenue  -- total fare in that month
    FROM safari_connect.v_clean_trips
    GROUP BY TO_CHAR(departure_date, 'YYYY-MM')
)
SELECT
    month, bookings, revenue,
    LAG(revenue) OVER (ORDER BY month)                        AS prev_month,
    revenue - LAG(revenue) OVER (ORDER BY month)        AS change, -- difference btwn current month and prev month
    ROUND((revenue - LAG(revenue) OVER (ORDER BY month))
        / NULLIF(LAG(revenue) OVER (ORDER BY month),0) * 100, 1)  AS change_pct
FROM monthly ORDER BY month;


-- ===============================================================================================================================


/* 3B - Running total of revenue
Show each month with its revenue and a cumulative running total from January onwards.
*/

WITH monthly AS (
    SELECT
        TO_CHAR(departure_date, 'YYYY-MM') 	  AS month, -- extracting year and month
        SUM(total_fare)                       AS revenue  -- total fare in that month
    FROM safari_connect.v_clean_trips
    GROUP BY TO_CHAR(departure_date, 'YYYY-MM')
)
SELECT
    month, 
    revenue,
    LAG(revenue) OVER (ORDER BY month)     AS prev_month, --revenue in previous month
    SUM(revenue) OVER (ORDER BY month)     AS rolling_total_revenue -- sum btwn current month and all prev months.
FROM monthly ORDER BY month;



-- ===============================================================================================================================

/* 3C - Best and worst 3 months
Using a CTE for monthly revenue, show the top 3 months and the bottom 3 months by revenue. Use RANK().
*/

-- top 3 highest monthly revenues

WITH monthly AS (
    SELECT
        TO_CHAR(departure_date, 'YYYY-MM') 	  AS month, -- extracting year and month
        SUM(total_fare)                       AS revenue  -- total fare in that month
    FROM safari_connect.v_clean_trips
    GROUP BY TO_CHAR(departure_date, 'YYYY-MM')
)
SELECT
    month, 
    revenue,
    -- ranking revenue by highest revenue as first.
    rank() over (order by revenue desc) as monthy_revenue_rank 
FROM monthly
limit 3; -- show top 3 highest months by revenue


-- lowset 3 monthly revenue

WITH monthly AS (
    SELECT
        TO_CHAR(departure_date, 'YYYY-MM') 	  AS month, -- extracting year and month
        SUM(total_fare)                       AS revenue  -- total fare in that month
    FROM safari_connect.v_clean_trips
    GROUP BY TO_CHAR(departure_date, 'YYYY-MM')
)
SELECT
    month, 
    revenue,
    -- ranking revenue by lowest revenue first.
    rank() over (order by revenue) as monthy_revenue_rank 
FROM monthly
limit 3; -- show top 3 lowest months by revenue


-- ===============================================================================================================================

/* 3D - Revenue by route per month (pivot)
Show one row per month with separate columns for the top 3 routes (RT001, RT002, RT003) using CASE WHEN + SUM.
*/




SELECT * FROM safari_connect.v_clean_trips LIMIT 100;

