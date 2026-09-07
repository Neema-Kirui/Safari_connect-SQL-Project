# Safari Connect - Bus & Matatu Booking Platform

## Project Scenario

You have just been hired as a **Data Analyst** at Safari Connect - a fast-growing Nairobi-based bus and matatu booking platform. They operate a long-distance travel company where passengers book seats online, choose their route, and pay via M-Pesa, cash or card.

The company has been running since 2024 and storing all booking records in a shared Excel file. It is a complete mess. The Operations Director has handed you a CSV export and sent you this message:

### Message from the Operations Director


> "We are growing fast - hundreds of bookings a month and counting. But I have no idea which routes are making money, which drivers are performing well, or why our cancellation rate feels high.

> I need you to clean this data, load it into our database, analyse it, and present your findings to the board.

> I want to know: which routes are most profitable, which drivers I should promote, how revenue is trending month by month, where our passengers come from, how much revenue cancellations are costing us, and what our busiest travel times are.

> Make it look professional. . The CEO will be in the room."

---

## The Data - `safari_connect_dirty.csv`

You will receive a CSV file with **approximately 290 rows** of booking records exported from the company's Excel file.

### Columns in the CSV

| Column | Description | Expected Clean Format |
|---|---|---|
| `booking_id` | Unique booking reference | `BK0001`, `BK0002` ... |
| `passenger_name` | Full name of the passenger | Title Case - e.g. Alice Mwangi |
| `passenger_phone` | Passenger phone number | `07XXXXXXXX` (10 digits, no dashes or +254) |
| `passenger_gender` | Passenger gender | Male / Female only |
| `passenger_city` | Passenger home city | Title Case - e.g. Nairobi |
| `route_code` | Route identifier | RT001 to RT010 |
| `route_from` | Departure city | Title Case - e.g. Nairobi |
| `route_to` | Destination city | Title Case - e.g. Mombasa |
| `vehicle_plate` | Vehicle registration plate | e.g. KBZ 001A |
| `vehicle_type` | Type of vehicle | Bus / Matatu / Minibus |
| `driver_name` | Driver full name | Title Case |
| `driver_rating` | Driver's platform rating | Numeric e.g. 4.5 |
| `departure_date` | Date of travel | YYYY-MM-DD |
| `departure_time` | Scheduled departure time | HH:MM e.g. 06:00 |
| `seat_class` | Class of seat booked | Economy / Business |
| `seats_booked` | Number of seats on this booking | Positive integer |
| `fare_per_seat` | Fare per seat in KES | Numeric e.g. 1200 |
| `total_fare` | Total amount paid | Numeric e.g. 2400 |
| `payment_method` | How passenger paid | M-Pesa / Cash / Card |
| `booking_status` | Outcome of the booking | Completed / Cancelled / No Show |
| `trip_rating` | Passenger satisfaction rating | Integer 1-5 or blank if not completed |

---

## Dirty Data Problems to Find and Fix

These are the **categories of problems** in the CSV. Your job is to find every instance of each problem and fix it with SQL.

| # | Problem Type | Example | How to Fix |
|---:|---|---|---|
| 1 | UPPERCASE passenger names | `'ALICE MWANGI'` | `INITCAP(TRIM(name))` |
| 2 | lowercase passenger names | `'alice mwangi'` | `INITCAP(TRIM(name))` |
| 3 | Extra whitespace in names | `' Carol   Wanjiku '` | `TRIM()` |
| 4 | Phone with dashes | `'0712-345-678'` | `REGEXP_REPLACE(phone,'[^0-9]','','g')` |
| 5 | Phone with +254 prefix | `'+254712345678'` | Strip then prepend `'0'` |
| 6 | NULL / empty phone numbers | `(empty)` | `COALESCE` to `NULL` |
| 7 | Date format DD/MM/YYYY | `'15/09/2024'` | `TO_DATE(col,'DD/MM/YYYY')` |
| 8 | Date format MM-DD-YYYY | `'09-25-2024'` | `TO_DATE(col,'MM-DD-YYYY')` |
| 9 | Date format DD-MM-YY | `'20-09-24'` | `TO_DATE(col,'DD-MM-YY')` |
| 10 | UPPERCASE passenger city | `'NAIROBI'` | `INITCAP(TRIM(city))` |
| 11 | lowercase passenger city | `'kisumu'` | `INITCAP(TRIM(city))` |
| 12 | NULL / empty city | `(empty)` | `COALESCE` to `'Unknown'` |
| 13 | Gender inconsistency (7 variants) | `'male','MALE','M','F'` | `CASE WHEN` to standardise |
| 14 | Payment method casing | `'mpesa','CASH','card'` | `CASE WHEN` to standardise |
| 15 | Booking status casing | `'completed','CANCELLED'` | `CASE WHEN` to standardise |
| 16 | `total_fare` stored as text | `'KES 1200'` | `REGEXP_REPLACE` then `CAST` |
| 17 | `fare_per_seat` stored as text | `'KES 900'` | `REGEXP_REPLACE` then `CAST` |
| 18 | `seat_class` lowercase | `'economy','business'` | `INITCAP()` or `CASE WHEN` |
| 19 | `seat_class` abbreviations | `'ECO','BUS','economy class'` | `CASE WHEN` to map to standard |
| 20 | UPPERCASE driver names | `'KELVIN OMONDI'` | `INITCAP(TRIM(name))` |
| 21 | Invalid `trip_rating` (0 or 6) | `'0'` or `'6'` | Set to `NULL` |
| 22 | Negative `seats_booked` | `'-1'` | **DELETE** these rows |
| 23 | Exact duplicate `booking_id` | `BK0005` appears twice | **DELETE** with `ctid` |

---

## The 6 Business Questions You Must Answer

These are the questions the Operations Director is asking. Your analysis must answer all six.

> **The CEO's questions on Friday will come directly from these six areas - so know your results inside out.**

| # | Business Question | What the CEO Wants to See |
|---:|---|---|
| **1** | **Route Analysis** - Which routes earn the most? Which are most popular? Which is most efficient per seat sold? | Specific route codes with KES figures. A clear top route and a clear underperformer. |
| **2** | **Driver Performance** - Who are the best drivers? Does driver rating affect passenger satisfaction? | Named drivers with revenue and rating figures. A promotion recommendation with data behind it. |
| **3** | **Revenue Trends** - How is revenue changing month by month? What are our best and worst months? | Month-over-month change with % growth. A trend direction - growing or declining. |
| **4** | **Passenger Insights** - Where do passengers come from? What seat class do they prefer? Are they satisfied? | Top cities with numbers. Satisfaction breakdown. Gender and class split. |
| **5** | **Cancellations** - What is the cancellation rate per route? How much revenue did cancellations cost us? | A KES figure for lost revenue. The worst route for cancellations. A policy recommendation. |
| **6** | **Operational Patterns** - What are our busiest days and times? When should we add more vehicles? | Specific days and times with booking and revenue numbers. A clear peak period. |

---
