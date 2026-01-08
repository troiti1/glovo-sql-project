/* =========================================================
    03_eda.sql
    Proyecto SQL – Análisis exploratorio de datos (EDA)
   ========================================= */

/* =========================================================*/



-- En primer lugar, realizamos consultas básicas para entender la distribución de los datos en las tablas de dimensiones y hechos.
-- A partir de esta query podemos sacar un top 5 ciudades con mejor rating para ver donde se come mejor en Marruecos.

SELECT

    c.city,
    COUNT(f.fact_id) AS total_restaurants,
    ROUND(AVG(f.rating_percent), 2) AS avg_rating,
    SUM(f.rating_total) AS total_reviews
FROM fact_restaurant_ratings f
JOIN dim_city c ON f.city_id = c.city_id
GROUP BY c.city
ORDER BY avg_rating DESC LIMIT 5;



-- Detectaremos categorias con ratings bajos o sin rating para identificar oportunidades de mejoras:

SELECT
    cat.category_name,
    COUNT(f.fact_id) AS total_restaurants,
    ROUND(AVG(f.rating_percent), 2) AS avg_rating
FROM dim_category cat
LEFT JOIN fact_restaurant_ratings f
    ON cat.category_id = f.category_id
GROUP BY cat.category_name
ORDER BY total_restaurants DESC;

-- Como se puede observar los locales de sandwiches tienen un rating medio bajo, lo que puede indicar una oportunidad de mejora en este sector.
-- Por otro lado, se puede observar que las categorias mas minoritarias como la cocina local tienen ratings mucho más elevados.


-- Creamos una lógica condicional para clasificar los restaurantes según su rating_percent en Excelente, Bueno, Mejorable o Sin rating:

SELECT
    r.restaurant_name,
    c.city,
    f.rating_percent,
    CASE
        WHEN f.rating_percent >= 0.90 THEN 'Excelente'
        WHEN f.rating_percent >= 0.75 THEN 'Bueno'
        WHEN f.rating_percent IS NULL THEN 'Sin rating'
        ELSE 'Mejorable'
    END AS rating_category
FROM fact_restaurant_ratings f
JOIN dim_restaurant r ON f.restaurant_id = r.restaurant_id
JOIN dim_city c ON f.city_id = c.city_id
ORDER BY f.rating_percent DESC NULLS LAST;


-- Seleccionamos los 10 restaurantes con mejor rating_percent que superan la media global para ver los mejores locales

SELECT
    r.restaurant_name,
    f.rating_percent
FROM fact_restaurant_ratings f
JOIN dim_restaurant r ON f.restaurant_id = r.restaurant_id
WHERE f.rating_percent >
    (SELECT AVG(rating_percent) FROM fact_restaurant_ratings)
ORDER BY f.rating_percent DESC LIMIT 10;


-- Seleccionamos las 10 ciudades ordenadas por su rating medio para identificar las mejores ciudades para comer

WITH city_ratings AS (
    SELECT
        c.city,
        ROUND(AVG(f.rating_percent), 2) AS avg_rating
    FROM fact_restaurant_ratings f
    JOIN dim_city c ON f.city_id = c.city_id
    GROUP BY c.city
)
SELECT *
FROM city_ratings
ORDER BY avg_rating DESC LIMIT 10;


-- Identificamos las ciudades con un rating medio superior a la media global para ver las ciudades con mejor calidad gastronómica

WITH city_avg AS (
    SELECT
        c.city,
        AVG(f.rating_percent) AS avg_rating
    FROM fact_restaurant_ratings f
    JOIN dim_city c ON f.city_id = c.city_id
    GROUP BY c.city
),
global_avg AS (
    SELECT AVG(avg_rating) AS global_rating
    FROM city_avg
)
SELECT
    ca.city,
    ROUND(ca.avg_rating, 2) AS city_avg_rating
FROM city_avg ca, global_avg ga
WHERE ca.avg_rating > ga.global_rating
ORDER BY city_avg_rating DESC;



-- Seleccionamos exactamente los 3 restaurante con mayor numero de ratings por cada ciudad para identificar los locales más populares
WITH restaurant_scores AS (
    SELECT
        c.city,
        r.restaurant_name,
        MAX(f.rating_total) AS max_rating_total
    FROM fact_restaurant_ratings f
    JOIN dim_restaurant r ON f.restaurant_id = r.restaurant_id
    JOIN dim_city c ON f.city_id = c.city_id
    GROUP BY c.city, r.restaurant_name
),
ranked_restaurants AS (
    SELECT
        city,
        restaurant_name,
        max_rating_total,
        ROW_NUMBER() OVER (
            PARTITION BY city
            ORDER BY max_rating_total DESC
        ) AS row_num
    FROM restaurant_scores
)
SELECT *
FROM ranked_restaurants
WHERE row_num <= 3
ORDER BY city, row_num;



--- Consultamos la vista agregada creada en el esquema para obtener métricas resumidas por ciudad y categoría.
-- En este caso, ordenamos por la media de rating para identificar las combinaciones más destacadas.

SELECT *
FROM vw_city_category_ratings
ORDER BY avg_rating DESC;


-- Con el uso de la fuinción creada en el esquema, obtenemos el rating medio de una ciudad específica.

SELECT fn_avg_rating_by_city('Agadir') AS avg_rating_agadir;


-- Vista resumen final con métricas agregadas por ciudad y categoría, ordenada por el total de reviews.
-- Esta vista nos permite ordenar por ciudad y categoría para identificar las áreas con mayor actividad.

SELECT
    c.city,
    cat.category_name,
    COUNT(f.fact_id) AS total_restaurants,
    ROUND(AVG(f.rating_percent), 2) AS avg_rating,
    SUM(f.rating_total) AS total_reviews
FROM fact_restaurant_ratings f
JOIN dim_city c ON f.city_id = c.city_id
JOIN dim_category cat ON f.category_id = cat.category_id
GROUP BY c.city, cat.category_name
ORDER BY total_reviews DESC;



-- Análisis adicional: Identificamos las 5 ciudades con mayor número de reviews totales para enfocar el análisis en los mercados más activos.

CREATE TABLE top_5_cities_by_reviews AS
SELECT
    c.city,
    SUM(f.rating_total) AS total_reviews
FROM fact_restaurant_ratings f
JOIN dim_city c ON f.city_id = c.city_id
GROUP BY c.city
ORDER BY total_reviews DESC
LIMIT 5;

SELECT * FROM top_5_cities_by_reviews;

-- Ahora, utilizamos esta tabla para filtrar la vista agregada y centrarnos en estas ciudades principales.

SELECT
    c.city,
    cat.category_name,
    COUNT(f.fact_id) AS total_restaurants,
    ROUND(AVG(f.rating_percent), 2) AS avg_rating,
    SUM(f.rating_total) AS total_reviews
FROM fact_restaurant_ratings f
JOIN dim_city c ON f.city_id = c.city_id
JOIN dim_category cat ON f.category_id = cat.category_id
JOIN top_5_cities_by_reviews t
    ON c.city = t.city
GROUP BY c.city, cat.category_name
ORDER BY total_reviews DESC, avg_rating DESC;


-- Conclusiones: 
    --En el caso de abrir un negocio de comida a domicilio en Marruecos:
        -- Observamos que los mejores ratings se encunetran en ciudades como Laayoune, Agadir y Tamesna.
        -- Los mejores ratings de comida se lo llevan las categorias de Cocina Local y tradicional, sin embargo hay un menor numero de restaurantes en estas categorias para comida a domicilio.
        -- Las categorias de Sandwiches y Comida Rapida tienen ratings medios más bajos, lo que puede indicar una oportunidad de mejora en estos sectores.