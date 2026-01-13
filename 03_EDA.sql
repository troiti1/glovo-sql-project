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
    ROUND(AVG(f.rating_percent), 2) AS avg_rating, -- Media del rating de todos los restaurantes en la ciudad
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

-- Como se puede observar los locales de sandwiches tienen un rating medio bajo, lo que puede indicar una oportunidad de mejora en este sector a pesar de la gran cantidad de locales que hay.
-- Si ordenamos por avg_rating, podemos observar que las categorias con mejor rating son la de Glace (Postres y helados) y Cocina local, pero con un numero relativamente bajo de restaurantes.
-- Por otro lado, se puede observar que las categorias mas minoritarias como la cocina local tienen ratings mucho más elevados.


-- Creamos una lógica condicional para clasificar los restaurantes según su rating_percent en Excelente, Bueno, Mejorable o Sin rating:

SELECT
    r.restaurant_name,
    c.city,
    f.rating_percent,
    CASE
        WHEN f.rating_percent >= 0.90 THEN 'Excelente'
        WHEN f.rating_percent >= 0.75 THEN 'Bueno'
       -- WHEN f.rating_percent IS NULL THEN 'Sin rating'
        ELSE 'Mejorable'
    END AS rating_category
FROM fact_restaurant_ratings f
JOIN dim_restaurant r ON f.restaurant_id = r.restaurant_id -- Cruzamos para mostrar el nombre de los restaurantes
JOIN dim_city c ON f.city_id = c.city_id -- Cruzamos para mostrar el nombre de las ciudades
ORDER BY f.rating_percent ;--DESC NULLS LAST;  -- Ordena por rating de mayor a menor, y los que no tienen rating se ponen al final.


-- Seleccionamos los 10 restaurantes con mejor rating_percent que superan la media global para ver los mejores locales

SELECT
    r.restaurant_name,
    f.rating_percent
FROM fact_restaurant_ratings f
JOIN dim_restaurant r ON f.restaurant_id = r.restaurant_id
WHERE f.rating_percent >
    (SELECT AVG(rating_percent) FROM fact_restaurant_ratings)
ORDER BY f.rating_percent DESC LIMIT 10;


-- Seleccionamos las 10 ciudades ordenadas por su rating medio para identificar las mejores ciudades para comer de Marruecos

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

/*
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

*/

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
), -- Creamos una tabla temporal con el numero de reviews por restaurante y ciudad
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
) -- Creamos otra tabla temporal para ordenar los restaurantes por numero de reviews dentro de cada ciudad de mayor a menor
SELECT *
FROM ranked_restaurants
WHERE row_num <= 3
ORDER BY city, row_num; -- Seleccionamos los 3 primeros restaurantes por ciudad



--- Consultamos la vista agregada creada en el esquema para obtener métricas resumidas por ciudad y categoría.
-- En este caso, ordenamos por la media de rating para identificar las combinaciones más destacadas.

SELECT *
FROM vw_city_category_ratings
ORDER BY avg_rating DESC;


-- Con el uso de la fuinción creada en el esquema, obtenemos el rating medio de una ciudad específica.

SELECT fn_avg_rating_by_city('Marrakech') AS avg_rating_agadir;


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
-- Dentro de las 5 ciudades donde más se vende, qué tipos de comida funcionan mejor en volumen y en calidad.
-- Si quiero abrir restaurantes de delivery en Marruecos, dentro de las ciudades más potentes, qué tipo de comida debería priorizar para ganar más dinero.

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

-- Añadimos una métrica adicional: número medio de reviews por restaurante en estas ciudades principales. Dado que puede ser interesante por si queremos montar un negocio de comida a domicilio en estas ciudades.
SELECT 
    c.city,
    cat.category_name,
    COUNT(f.fact_id) AS total_restaurants,
    ROUND(AVG(f.rating_percent), 2) AS avg_rating,
    SUM(f.rating_total) AS total_reviews,
    ROUND(
        SUM(f.rating_total)::NUMERIC / COUNT(f.fact_id),
        2
    ) AS reviews_per_restaurant
FROM fact_restaurant_ratings f
JOIN dim_city c ON f.city_id = c.city_id
JOIN dim_category cat ON f.category_id = cat.category_id
JOIN top_5_cities_by_reviews t
    ON c.city = t.city
GROUP BY c.city, cat.category_name
ORDER BY total_reviews DESC, avg_rating DESC;



-- Comentarios:
    
        -- Observamos que los mejores ratings se encunetran en ciudades como Laayoune, Agadir y Tamesna.
        -- Los mejores ratings de comida se lo llevan las categorias de Cocina Local y tradicional, sin embargo hay un menor numero de restaurantes en estas categorias para comida a domicilio.
        -- Las categorias de Sandwiches y Comida Rapida tienen ratings medios más bajos, lo que puede indicar una oportunidad de mejora en estos sectores.
        -- Observamos que en Casablanca y Tanger tenemos un buen rating medio para la categoria Sandwiches, con un gran numero de ventas, lo que puede indicar una buena oportunidad de negocio en estas ciudades para esta categoria.
        -- Otra opcion de negocio puede ser abrir un restaurante de comida asiatica en Cablanca, dado que



-----------------------------------------------------------------------------------------------

/*CONCLUSIONES DEL ANÁLISIS

1. Ciudades con mayor potencial:

Las ciudades con mejores ratings y actividad son Laâyoune, Agadir y Tamesna, ideales para abrir negocios de comida a domicilio enfocados en calidad.

Ciudades como Casablanca y Tánger muestran un alto volumen de ventas y un rating medio aceptable, lo que las hace atractivas para categorías más populares.

2. Categorías con mejor rating y menor competencia:

Cocina local y tradicional presentan los ratings más altos, aunque hay pocos restaurantes en estas categorías. Esto indica una oportunidad para ofrecer comida de calidad en un nicho poco saturado.

Postres y helados (Glace) también tienen un alto rating, pero con un número reducido de locales, lo que puede ser un nicho rentable.

3. Categorías con oportunidad de mejora:

Sandwiches y comida rápida muestran ratings medios más bajos, lo que indica que mejorar la calidad de estas categorías puede generar ventaja competitiva, especialmente en ciudades donde ya hay demanda.

En Casablanca y Tánger, los sandwiches tienen buen rating y gran volumen de ventas, lo que representa una oportunidad clara de negocio para estas ciudades.

4. Oportunidades de nicho y diferenciación:

Abrir un restaurante de comida asiática en Casablanca podría ser interesante, dado que hay demanda y se pueden diferenciar de los locales existentes.

Las categorías minoritarias con buen rating, como cocina local, permiten posicionarse como un restaurante de alta calidad con menos competencia directa.

RESUMEN:

Para alta calidad y diferenciación, apostar por cocina local o postres en ciudades con menos restaurantes pero con clientes exigentes (Laâyoune, Agadir, Tamesna).

Para volumen y ventas rápidas, considerar sandwiches y comida rápida en ciudades grandes con buena demanda (Casablanca, Tánger).

Nichos como comida asiática en Casablanca combinan potencial de ventas con diferenciación frente a la competencia.


*/

