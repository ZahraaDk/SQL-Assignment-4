-- FIRST EXERCISE:
SELECT 
	se_customer.customer_id, 
	se_customer.first_name, 
	se_customer.last_name,
	AVG(EXTRACT( DAY from se_rental.return_date - se_rental.rental_date)) AS Avg_Rental_Duration, 
	SUM(se_payment.amount) AS total_revenue
FROM customer as se_customer
INNER JOIN rental as se_rental
	ON se_customer.customer_id = se_rental.customer_id
INNER JOIN payment as se_payment
	ON se_rental.rental_id = se_payment.rental_id
GROUP BY 
	se_customer.customer_id, 
	se_customer.first_name, 
	se_customer.last_name


-- SECOND EXERCISE : 
SELECT 
	se_customer.customer_id, 
	se_customer.first_name, 
	se_customer.last_name
FROM customer as se_customer
LEFT JOIN rental as se_rental
	ON se_rental.customer_id = se_customer.customer_id
LEFT JOIN payment as se_payment
	ON se_payment.customer_id = se_rental.customer_id
WHERE se_rental.customer_id is NULL and se_payment.customer_id is NOT NULL 

-- THIRD EXERCISE: 
SELECT 
	se_customer.customer_id, 
	COUNT(se_rental.rental_id) AS rental_freq, 
	AVG(se_film.rating) AS avg_rating 
FROM customer as se_customer
INNER JOIN rental as se_rental
	ON se_rental.customer_id = se_customer.customer_id
INNER JOIN inventory AS se_inventory
	ON se_inventory.inventory_id = se_rental.inventory_id
INNER JOIN film as se_film 
	ON se_film.film_id = se_inventory.film_id
GROUP BY
	se_customer.customer_id

-- FOURTH EXERCISE: 
 WITH CTE_COUNT_RENTED AS
(
	SELECT 
		se_city.city, 
		COUNT(se_rental.rental_id) AS total_rented_films
	FROM city as se_city
	INNER JOIN address as se_address
		 ON se_address.city_id = se_city.city_id
	INNER JOIN customer as se_customer
		ON se_customer.address_id = se_address.address_id
	INNER JOIN rental as se_rental
		ON se_rental.customer_id = se_customer.customer_id
	GROUP BY 
		se_city.city_id
) 
SELECT
	CTE_COUNT_RENTED.city,
	ROUND(AVG(total_rented_films), 2) AS avg_total_rentedfilms
FROM CTE_COUNT_RENTED
GROUP BY city

-- FIFTH EXERCISE: 
-- films rented more than average nb of times and not in inventory
-- get avg number of rentals / to get films more than count(rentals)>avg + its id in inventory is null
-- to do so i may use CTE to get count and then access it to get avg
-- tables to access: rentals : films : inventory
-- tables: rental -> inventory -> films or vice versa then put the conditions

WITH CTE_COUNTFILMS AS(
SELECT 
	se_film.film_id, 
	COUNT(se_rental.rental_id) as count_rentals
FROM film as se_film
INNER JOIN inventory as se_inventory
	ON se_inventory.film_id = se_film.film_id
INNER JOIN rental as se_rental
	ON se_rental.inventory_id = se_inventory.inventory_id
GROUP BY se_film.film_id)

SELECT 
	CTE_COUNTFILMS.film_id, 
	ROUND(AVG(count_rentals), 2) as avg_rentals
FROM CTE_COUNTFILMS 
WHERE count_rentals > (SELECT AVG(count_rentals) FROM CTE_COUNTFILMS)
AND CTE_COUNTFILMS.film_id not in (SELECT film_id from inventory)
GROUP BY CTE_COUNTFILMS.film_id

-- SIXTH EXERCISE:
-- Calculate the replacement cost of lost films for each store, considering the rental history.
-- replacement cost from film
-- lost films: not in inventory, weren't returned by the customer
-- get store id from inv/join with film to get its replacement cost/put condition inventory not in rental
-- tables: film, rental, inventory 

SELECT 
	se_inventory.store_id, 
	SUM(se_film.replacement_cost) AS total_repcost
FROM inventory as se_inventory
INNER JOIN film as se_film
	ON se_film.film_id = se_inventory.film_id
WHERE se_inventory.inventory_id not in (
	SELECT inventory_id from rental as se_rental
)
GROUP BY se_inventory.store_id
	
-- SEVENTH EXERCISE:
-- Create a report that shows the top 5 most rented films in each category 
-- along with their corresponding rental counts and revenue.
-- get 5 top rented films -- order by + limit 5 on rental id and join with film table to get film name
-- select count(rental_id) and get revenue(total payment amount)
-- tables: films, rental, payment. to go from films to rental, use inventory

SELECT 
	se_film.film_id, 
	se_film.title, 
	COUNT(se_rental.rental_id) as rental_count, 
	SUM(se_payment.amount) as revenue
FROM film as se_film 
INNER JOIN inventory as se_inventory
	ON se_inventory.film_id = se_film.film_id
INNER JOIN rental as se_rental
	ON se_rental.inventory_id = se_inventory.inventory_id
INNER JOIN payment as se_payment
	ON se_payment.rental_id = se_rental.rental_id
GROUP BY se_film.film_id, se_film.title
ORDER BY rental_count DESC
LIMIT 5 
	

-- EIGHTH EXERCISE: 
-- CURRENT*10 (EXTRACT MONTH AND YEAR FROM CURRENT *10 - EXTRACT MONTH AND YEAR FROM DATE COLUMN) < 3
-- ten most frequently rented films -> count(rental_id), order DESC and limit 10
-- tables: rental, films, to go from film to rental: inventory 

SELECT 
	se_film.film_id, 
	se_film.title, 
	COUNT(se_rental.rental_id) as total_rentals
FROM film as se_film
INNER JOIN inventory as se_inventory
	ON se_inventory.film_id = se_film.film_id
INNER JOIN rental as se_rental
	ON se_rental.inventory_id = se_inventory.inventory_id
WHERE EXTRACT(YEAR FROM CURRENT_DATE) * 12 + EXTRACT(MONTH FROM CURRENT_DATE) -
      (EXTRACT(YEAR FROM se_rental.rental_date) * 12 + EXTRACT(MONTH FROM se_rental.rental_date)) < 3
GROUP BY se_film.film_id
ORDER BY total_rentals DESC
LIMIT 10

-- Ninth exercise:
SELECT 
	se_inventory.store_id, 
	SUM(rental_rate * rental_duration) as rentals_revenue, 
	SUM(se_payment.amount) as payment_revenue
FROM inventory as se_inventory
INNER JOIN film as se_film 
	ON se_film.film_id = se_inventory.film_id
INNER JOIN rental as se_rental 
	ON se_rental.inventory_id = se_inventory.inventory_id
LEFT JOIN payment as se_payment
	ON se_payment.rental_id = se_rental.rental_id
GROUP BY se_inventory.store_id
HAVING SUM(rental_rate * rental_duration) > SUM(se_payment.amount)


-- Tenth Exercise:
--Determine the average rental duration and total revenue for each store, considering different payment methods.
-- select AVG(rental duration) and sum(amount) + store_id +payment_id as payment method
-- tables: film, payment, inventory
SELECT 
	se_inventory.store_id, 
	se_payment.payment_id as payment_method, 
	AVG(se_film.rental_duration), 
	SUM(se_payment.amount) as total_revenue
FROM payment as se_payment
INNER JOIN rental as se_rental
	ON se_rental.rental_id = se_payment.rental_id
INNER JOIN inventory as se_inventory
	ON se_inventory.inventory_id = se_rental.inventory_id
INNER JOIN film as se_film
	ON se_film.film_id = se_inventory.film_id
GROUP BY se_inventory.store_id, payment_method
