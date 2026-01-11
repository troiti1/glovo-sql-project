/* =========================================================
   02_data.sql
   Proyecto SQL – Carga y limpieza de datos
   ========================================================= */





-- 	CARGA DE DATOS
-- 	Se ha creado una imagen de Postgres en Docker y una vez realizada la conexión se ha subido el archivo csv glovo_data para trabajar con los datos.
--	La tabla en si contiene entorno a unas 42609 rows, comprobaremos que se han agregado correctamente:
SELECT * FROM glovo_data LIMIT 10;

SELECT COUNT(*) FROM glovo_data;


-- Creamos una tabla nueva para trabajar con ella, mantenemos la anterior en caso de tener que volver a los datos de inicio para trabajar de forma mas comoda en adelante

CREATE TABLE restaurantes AS SELECT * FROM glovo_data;
SELECT * FROM restaurantes LIMIT 10;

-- Check de types de columnas
SELECT data_type FROM information_schema.columns
WHERE table_name = 'restaurantes';

-- Cambiamos el nombre de las columnas para que no tengan espacios y sea mejor tratarlas

ALTER TABLE restaurantes RENAME COLUMN "restaurant name" TO restaurant_name;
ALTER TABLE restaurantes RENAME COLUMN "restaurant url" TO restaurant_url;
ALTER TABLE restaurantes RENAME COLUMN "City" TO city;
ALTER TABLE restaurantes RENAME COLUMN "Category Name" TO category_name;
ALTER TABLE restaurantes RENAME COLUMN "Link" TO link;
ALTER TABLE restaurantes RENAME COLUMN "RATING" TO rating_percent;
ALTER TABLE restaurantes RENAME COLUMN "RATING TOTAL" TO rating_total;

SELECT * FROM restaurantes LIMIT 10;

----------------------------------------------------------------------------------------------------

-- LIMPIEZA Y TRATAMIENTO DE DATOS

-- A continuacion realizaremos un tratamiento de datos para comprobar que datos tenemos como NULL

SELECT
    COUNT(*) AS total_rows,
    COUNT(CASE WHEN restaurant_name IS NULL THEN 1 END) AS restaurant_name_nulls,
    COUNT(CASE WHEN restaurant_name = '' THEN 1 END) AS restaurant_name_empties,
    COUNT(CASE WHEN restaurant_url IS NULL THEN 1 END) AS restaurant_url_nulls,
    COUNT(CASE WHEN restaurant_url = '' THEN 1 END) AS restaurant_url_empties,
    COUNT(CASE WHEN city IS NULL THEN 1 END) AS city_nulls,
    COUNT(CASE WHEN city = '' THEN 1 END) AS city_empties,
    COUNT(CASE WHEN category_name IS NULL THEN 1 END) AS category_name_nulls,
    COUNT(CASE WHEN category_name = '' THEN 1 END) AS category_name_empties,
    COUNT(CASE WHEN link IS NULL THEN 1 END) AS link_nulls,
    COUNT(CASE WHEN link = '' THEN 1 END) AS link_empties,
    COUNT(CASE WHEN rating_percent IS NULL THEN 1 END) AS rating_percent_nulls,
    COUNT(CASE WHEN rating_percent = '' THEN 1 END) AS rating_percent_empties,
    COUNT(CASE WHEN rating_total IS NULL THEN 1 END) AS rating_total_nulls,
    COUNT(CASE WHEN rating_total = '' THEN 1 END) AS rating_total_empties
FROM restaurantes;

-- Observamos que solo tenemos datos no imputados: '' en rating_total_empties.
-- Sin embargo, rating_percent tambien alberga muchos datos de tipo diferente a NUM como pueden ser '--', '-', ... para ello comprobaremos todos aquellos que son diferente a numericos:


		--rating_percent:


-- en primer lugar quitaremos el %
UPDATE restaurantes
SET rating_percent = REPLACE(rating_percent, '%', '')
WHERE rating_percent IS NOT NULL;
-- Comprobamos numeros unicamente y quitamos el resto
UPDATE restaurantes
SET rating_percent = CASE
    WHEN rating_percent ~ '^[0-9]+$' THEN rating_percent  -- si es un número, lo dejamos
    ELSE NULL                                            -- si no, ponemos NULL
END;
-- Comprobamos
SELECT * FROM restaurantes LIMIT 30;
-- Cambiamos el tipo de la columna a numerico, como hemos quitado con anterioridad el porcentaje del rating_percent, dejaremos esta columna con un valor entre 0 y 1. Por ejemplo: 95% = 0.95
ALTER TABLE restaurantes
ALTER COLUMN rating_percent TYPE NUMERIC(3,2)
USING (CAST(rating_percent AS NUMERIC) / 100);
-- Comprobamos
SELECT * FROM restaurantes LIMIT 30;


		--rating_total:

--reemplazamos los valores no imputados '.' como NULL:

UPDATE restaurantes
SET rating_total = NULL
WHERE rating_total = '';
--Comprobamos
SELECT COUNT(CASE WHEN rating_total = '' THEN 1 END) AS rating_total_empties
FROM restaurantes;
--Quitamos los parentesis y los simbolos + de nuestros datos para poder convertirlo a integer

UPDATE restaurantes
SET rating_total = REPLACE(REPLACE(REPLACE(rating_total, '(', ''), ')', ''), '+', '')
WHERE rating_total IS NOT NULL;
--Comprobamos
SELECT * FROM restaurantes LIMIT 30;

-- Convertimos a integer
ALTER TABLE restaurantes
ALTER COLUMN rating_total TYPE INTEGER
USING CAST(rating_total AS INTEGER);

--Comprobamos
SELECT * FROM restaurantes LIMIT 30;



		-- resto de campos


-- Cambiamos los textos largos a VARCHAR con tamaño adecuado
ALTER TABLE restaurantes
ALTER COLUMN restaurant_name TYPE VARCHAR(150);
ALTER TABLE restaurantes
ALTER COLUMN restaurant_url TYPE VARCHAR(255);
ALTER TABLE restaurantes
ALTER COLUMN city TYPE VARCHAR(100);
ALTER TABLE restaurantes
ALTER COLUMN category_name TYPE VARCHAR(100);
ALTER TABLE restaurantes
ALTER COLUMN link TYPE VARCHAR(255);


--Comprobamos
SELECT * FROM restaurantes LIMIT 30;


-- La columna link vemos que no nos interesa por lo cual la dropearemos

ALTER TABLE restaurantes 
DROP COLUMN link;

-- Comprobamos datos nulos tras la limpieza
SELECT 
    COUNT(*) FILTER (WHERE restaurant_name IS NULL) AS null_restaurant_name,
    COUNT(*) FILTER (WHERE city IS NULL) AS null_city,
    COUNT(*) FILTER (WHERE category_name IS NULL) AS null_category_name,
    COUNT(*) FILTER (WHERE rating_percent IS NULL) AS null_rating_percent,
    COUNT(*) FILTER (WHERE rating_total IS NULL) AS null_rating_total
FROM restaurantes;

SELECT COUNT(*) AS total_filas
FROM restaurantes;


-- Eliminamos aquellas rows con nulls para trabajar con datos limpios en las dimensiones y hechos (2191 rows de 46209 rows)
DELETE FROM restaurantes
WHERE restaurant_name IS NULL
   OR city IS NULL
   OR category_name IS NULL
   OR rating_percent IS NULL
   OR rating_total IS NULL;

-- Comprobamos datos nulos tras la limpieza

SELECT COUNT(*) AS total_filas
FROM restaurantes;



-- CARGA DE DATOS LIMPIOS EN EL ESQUEMA DEFINIDO

BEGIN;
-- Tenemos ahora 44018 rows limpias para trabajar

-- ============================================================
-- DIMENSIONES
-- ============================================================

/*
------------------------------------------------------------
dim_city
Se insertan todas las ciudades únicas de la tabla staging 'restaurantes'.
------------------------------------------------------------
*/
INSERT INTO dim_city (city)
SELECT DISTINCT city
FROM restaurantes
WHERE city IS NOT NULL
ON CONFLICT (city) DO NOTHING;  -- para evitar duplicados en caso de que la ciudad ya exista

--Comprobamos los datos insertados
SELECT * FROM dim_city LIMIT 10;

/*
------------------------------------------------------------
dim_category
Se insertan todas las categorías únicas de la tabla staging.
------------------------------------------------------------
*/
INSERT INTO dim_category (category_name)
SELECT DISTINCT category_name
FROM restaurantes
WHERE category_name IS NOT NULL
ON CONFLICT (category_name) DO NOTHING;

--Comprobamos los datos insertados
SELECT * FROM dim_category LIMIT 10;
/*
------------------------------------------------------------
dim_restaurant
Se insertan todos los restaurantes únicos.
------------------------------------------------------------
*/
INSERT INTO dim_restaurant (restaurant_name, restaurant_url)
SELECT DISTINCT restaurant_name, restaurant_url
FROM restaurantes
WHERE restaurant_name IS NOT NULL
ON CONFLICT (restaurant_name, restaurant_url) DO NOTHING;

--Comprobamos los datos insertados
SELECT * FROM dim_restaurant LIMIT 10;

/*
------------------------------------------------------------
dim_calendar
Insertamos un registro por fecha de carga (snapshot)
En este proyecto usaremos CURRENT_DATE como fecha de snapshot
------------------------------------------------------------
*/
INSERT INTO dim_calendar (full_date, day, month, year)
VALUES (
    CURRENT_DATE,
    EXTRACT(DAY FROM CURRENT_DATE)::INT,
    EXTRACT(MONTH FROM CURRENT_DATE)::INT,
    EXTRACT(YEAR FROM CURRENT_DATE)::INT
)
ON CONFLICT (full_date) DO NOTHING;

--Comprobamos los datos insertados
SELECT * FROM dim_calendar LIMIT 10;

-- ============================================================
-- TABLA DE HECHOS
-- ============================================================

/*
------------------------------------------------------------
fact_restaurant_ratings
Se insertan métricas de rating utilizando JOINs con dimensiones.
Granularidad: 1 fila = 1 restaurante en ciudad + categoría + fecha
------------------------------------------------------------
*/
INSERT INTO fact_restaurant_ratings (restaurant_id, city_id, category_id, date_id, rating_percent, rating_total)
SELECT
    dr.restaurant_id,
    dc.city_id,
    dcat.category_id,
    dcal.date_id,
    r.rating_percent,
    r.rating_total
FROM restaurantes r
JOIN dim_restaurant dr
    ON r.restaurant_name = dr.restaurant_name
    AND r.restaurant_url = dr.restaurant_url
JOIN dim_city dc
    ON r.city = dc.city
JOIN dim_category dcat
    ON r.category_name = dcat.category_name
JOIN dim_calendar dcal
    ON dcal.full_date = CURRENT_DATE;



COMMIT;
--Comprobamos los datos insertados
SELECT * FROM fact_restaurant_ratings LIMIT 10;

-- ============================================================
-- CHECKS POST-INSERT
-- ============================================================
-- Número de registros cargados en dimensiones y fact
SELECT COUNT(*) AS dim_city_count FROM dim_city;
SELECT COUNT(*) AS dim_category_count FROM dim_category;
SELECT COUNT(*) AS dim_restaurant_count FROM dim_restaurant;
SELECT COUNT(*) AS dim_calendar_count FROM dim_calendar;
SELECT COUNT(*) AS fact_count FROM fact_restaurant_ratings;
