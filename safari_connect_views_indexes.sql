-- =====================================================================================================
-- creating views based on the queries used to answer business questions.
set search_path to safari_connect;


-- View 1: Route performance - using 1A query
CREATE OR REPLACE VIEW v_route_performance as
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


-- =====================================================================================================


-- View 2: Driver performance using query 2A
CREATE OR REPLACE VIEW v_driver_performance as
	select driver_name,
			count(*) as total_trips,
			sum(seats_booked) as total_seats_carried,
			sum(total_fare) as total_revenue,
			round(avg(trip_rating), 2) as avg_trip_rating,
			avg(driver_rating) as driver_rating
	from safari_connect.v_clean_trips vct
	group by vct.driver_name
	order by total_revenue desc;


-- =====================================================================================================

-- View 3: Monthly revenue trend usong 3A query
CREATE OR REPLACE VIEW v_monthly_revenue as
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
	    revenue - LAG(revenue) OVER (ORDER BY month)      		  AS change, -- difference btwn current month and prev month
	    ROUND((revenue - LAG(revenue) OVER (ORDER BY month))
	        / NULLIF(LAG(revenue) OVER (ORDER BY month),0) * 100, 1)  AS change_pct
	FROM monthly ORDER BY month;


-- =====================================================================================================

-- View 4: Cancellation analysis usong query 5B
CREATE OR REPLACE VIEW v_cancellation_analysis AS
	SELECT
	    route_code,
	    route_from || ' → ' || route_to                               AS route,
	    COUNT(*)                                                      AS total_trips,
	    SUM(CASE WHEN booking_status = 'Completed' THEN 1 ELSE 0 END) AS completed_trips,
	    SUM(CASE WHEN booking_status = 'Cancelled' THEN 1 ELSE 0 END) AS cancelled_trips,
	    SUM(CASE WHEN booking_status = 'No Show'  THEN 1 ELSE 0 END)  AS no_show,
	    ROUND(SUM(CASE WHEN booking_status IN ('Cancelled','No Show')
	             THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS cancel_rate_pct
	FROM safari_connect.bookings
	GROUP BY route_code, route_from, route_to
	ORDER BY cancel_rate_pct DESC;


-- =====================================================================================================

-- View 5: Passenger city insights
CREATE OR REPLACE VIEW v_passenger_insights as
	SELECT 
	    passenger_city,
	    COUNT(*) AS total_bookings,        	-- How many bookings per city
	    SUM(seats_booked) AS total_seats,	-- adds all seats booked by passagers/city
	    SUM(total_fare) AS total_revenue,	-- adds full fare paid across all bookings
	    round(AVG(fare_per_seat),2) AS avg_fare		-- avg price per seat @city	
	FROM safari_connect.v_clean_trips vct 
	GROUP BY passenger_city
	HAVING COUNT(*) >= 3					-- to filter cities with 3 bookings and above (aggregation)
	ORDER BY total_bookings DESC;	


-- =====================================================================================================

-- creating indexes

CREATE INDEX idx_bookings_depdate     ON bookings (departure_date);
CREATE INDEX idx_bookings_route       ON bookings (route_code);
CREATE INDEX idx_bookings_driver      ON bookings (driver_name);
CREATE INDEX idx_bookings_status      ON bookings (booking_status);
CREATE INDEX idx_bookings_payment     ON bookings (payment_method);
CREATE INDEX idx_bookings_vehicle     ON bookings (vehicle_type);
CREATE INDEX idx_bookings_passcity    ON bookings (passenger_city);

SELECT tablename, indexname FROM pg_indexes
WHERE schemaname = 'safari_connect';

-- =====================================================================================================