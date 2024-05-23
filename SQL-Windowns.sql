-- Challenge 1
use sakila;
-- This challenge consists of three exercises that will test your ability to use the SQL RANK() function. 
-- You will use it to rank films by their length, their length within the rating category, 
-- and by the actor or actress who has acted in the greatest number of films.

-- Rank films by their length and create an output table that includes the title, length, and rank columns only. 
-- Filter out any rows with null or zero values in the length column.
SELECT 
	title, 
    length, 
	RANK() OVER (ORDER BY length DESC) AS ranking
FROM film
WHERE length IS NOT NULL AND length > 0;
-- Rank films by length within the rating category and create an output table that includes the title, length, rating and rank columns only. 
-- Filter out any rows with null or zero values in the length column.
SELECT title, length, rating, 
       RANK() OVER (PARTITION BY rating ORDER BY length DESC) AS ranking
FROM film
WHERE length IS NOT NULL AND length > 0;
-- Produce a list that shows for each film in the Sakila database, the actor or actress who has acted in the greatest number of films, as well as the total number of films in which they have acted. 
-- Find the actor who has been in the most film out of the actors in the movie. each movie shows up one
-- Hint: Use temporary tables, CTEs, or Views when appropiate to simplify your queries.

WITH ActorFilmCount AS (
    SELECT 
        fa.film_id,
        fa.actor_id,
        COUNT(fa.film_id) OVER (PARTITION BY fa.actor_id) AS actor_film_count
    FROM 
        film_actor fa
),
ProlificActor AS(
SELECT 
        film_id,
        actor_id,
        actor_film_count,
        RANK() OVER (PARTITION BY film_id ORDER BY actor_film_count DESC) AS rank_num
    FROM 
        ActorFilmCount)
SELECT 
	f.film_id,
    f.title, 
    a.actor_id,
    CONCAT(a.first_name, ' ', a.last_name) AS most_prolific_name,
    p.actor_film_count
from ProlificActor p 
join film f on f.film_id=p.film_id
join actor a on p.actor_id = a.actor_id
where p.rank_num =1 
group by f.film_id
order by f.film_id;

-- Challenge 2
-- This challenge involves analyzing customer activity and retention in the Sakila database to gain insight into business performance. By analyzing customer behavior over time, businesses can identify trends and make data-driven decisions to improve customer retention and increase revenue.

SELECT 
    DATE_FORMAT('2005-05-31 00:46:31', '%Y-%m') AS rental_month;

-- The goal of this exercise is to perform a comprehensive analysis of customer activity and retention by conducting an analysis on the monthly percentage change in the number of active customers and the number of retained customers. Use the Sakila database and progressively build queries to achieve the desired outcome.
-- Step 1. Retrieve the number of monthly active customers, i.e., the number of unique customers who rented a movie in each month.
CREATE TEMPORARY TABLE IF NOT EXISTS eachmonth AS(select
	DATE_FORMAT(r.rental_date, '%Y-%m') as Year_monthh,
	count(distinct c.customer_id) as unique_customer
from customer c
join rental r on c.customer_id = r.customer_id
group by DATE_FORMAT(r.rental_date, '%Y-%m')
order by DATE_FORMAT(r.rental_date, '%Y-%m') DESC);
select * from eachmonth;
-- Step 2. Retrieve the number of active users in the previous month.
CREATE TEMPORARY TABLE IF NOT EXISTS last_eachmonth(SELECT 
    Year_monthh,
    unique_customer,
    LAG(unique_customer, 1) OVER (ORDER BY Year_monthh) AS previous_month_customers
FROM eachmonth
group by Year_monthh,unique_customer
order by Year_monthh asc);
select * from last_eachmonth;
-- Step 3. Calculate the percentage change in the number of active customers between the current and previous month.
select 
	Year_monthh,
    unique_customer,
    previous_month_customers,
    CONCAT(
        ROUND(
            ((unique_customer - previous_month_customers) / previous_month_customers) * 100, 2
        ), '%'
    ) AS percent_change
from last_eachmonth
group by Year_monthh
order by Year_monthh asc;
 -- Step 4 Calculate the number of retained customers every month, i.e., customers who rented movies in the current and previous months.
CREATE TEMPORARY TABLE IF NOT EXISTS retained_customers AS (
    SELECT 
        DATE_FORMAT(r1.rental_date, '%Y-%m') AS current_month,
        COUNT(DISTINCT r1.customer_id) AS retained_customers
    FROM rental r1
    JOIN rental r2 ON r1.customer_id = r2.customer_id
    WHERE 
        DATE_FORMAT(r1.rental_date, '%Y-%m') = DATE_FORMAT(r2.rental_date + INTERVAL 1 MONTH, '%Y-%m')
    GROUP BY 
        DATE_FORMAT(r1.rental_date, '%Y-%m')
);
-- Step 1: Create the eachmonth temporary table to store customer activity by month
DROP table IF EXISTS eachmonth_detailed;

CREATE TEMPORARY TABLE IF NOT EXISTS eachmonth_detailed AS (
    SELECT
        DATE_FORMAT(r.rental_date, '%Y-%m') AS Year_monthh,
        c.customer_id
    FROM 
        customer c
    JOIN 
        rental r ON c.customer_id = r.customer_id
    GROUP BY 
       c.customer_id, DATE_FORMAT(r.rental_date, '%Y-%m')
);

SELECT * FROM eachmonth_detailed;

-- Step 2: Calculate retained customers using window functions
CREATE TEMPORARY TABLE IF NOT EXISTS retained_customers2 AS (
    SELECT 
        current_month,
        COUNT(DISTINCT customer_id) AS unique_customer,
        previous_month,
        COUNT(DISTINCT CASE WHEN previous_month IS NOT NULL THEN customer_id END) AS retained_customers
    FROM (
        SELECT 
            customer_id,
            Year_monthh AS current_month,
            LAG(Year_monthh, 1) OVER (PARTITION BY customer_id ORDER BY Year_monthh) AS previous_month
        FROM 
            eachmonth_detailed
    ) AS customer_activity
    GROUP BY 
        current_month
);

SELECT * FROM retained_customers;

SELECT * FROM retained_customers2;
-- Hint: Use temporary tables, CTEs, or Views when appropiate to simplify your queries.