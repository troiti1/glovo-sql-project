/* =========================================================
   01_schema.sql
   Proyecto SQL – Diseño del esquema de base de datos
   ========================================================= */

-- Primero creamos las tablas de dimensiones y hechos para un esquema estrella orientado al análisis de datos de restaurantes.

-- dim_restaurant: describe los restaurantes disponibles en la plataforma dentro de Marruecos.
-- dim_city: contiene las ciudades donde operan los restaurantes.
-- dim_category: clasifica los restaurantes por tipo de cocina o servicio.
-- dim_calendar: tabla de fechas para análisis temporal.


--dim_restaurant



CREATE TABLE IF NOT EXISTS dim_restaurant (
    restaurant_id SERIAL PRIMARY KEY,
    restaurant_name VARCHAR(150) NOT NULL,
    restaurant_url VARCHAR(255),
    CONSTRAINT uq_restaurant UNIQUE (restaurant_name, restaurant_url)
);

--dim_city

CREATE TABLE IF NOT EXISTS dim_city (
    city_id SERIAL PRIMARY KEY,
    city VARCHAR(100) NOT NULL UNIQUE
);


--dim_category

CREATE TABLE IF NOT EXISTS dim_category (
    category_id SERIAL PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL UNIQUE
);


--dim_calendar

CREATE TABLE IF NOT EXISTS dim_calendar (
    date_id SERIAL PRIMARY KEY,
    full_date DATE NOT NULL UNIQUE,
    day INT CHECK (day BETWEEN 1 AND 31),
    month INT CHECK (month BETWEEN 1 AND 12),
    year INT CHECK (year >= 2000)
);



-- A continuacion, la tabla de hechos central que conecta las dimensiones y almacena las métricas clave.
-- Granularidad: 1 fila = 1 restaurante en una ciudad, categoría y fecha.


CREATE TABLE IF NOT EXISTS fact_restaurant_ratings (
    fact_id SERIAL PRIMARY KEY,

    restaurant_id INT NOT NULL,
    city_id INT NOT NULL,
    category_id INT NOT NULL,
    date_id INT NOT NULL,

    rating_percent NUMERIC(3,2) CHECK (rating_percent BETWEEN 0 AND 1),
    rating_total INT CHECK (rating_total >= 0),

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_restaurant
        FOREIGN KEY (restaurant_id) REFERENCES dim_restaurant(restaurant_id),

    CONSTRAINT fk_city
        FOREIGN KEY (city_id) REFERENCES dim_city(city_id),

    CONSTRAINT fk_category
        FOREIGN KEY (category_id) REFERENCES dim_category(category_id),

    CONSTRAINT fk_date
        FOREIGN KEY (date_id) REFERENCES dim_calendar(date_id)
);


-- Ahora, añadimos algunos objetos adicionales para optimizar consultas y facilitar análisis comunes.
-- Creamos un índice y una vista agregada.


-- Indice para optimizar consultas frecuentes por ciudad.

CREATE INDEX IF NOT EXISTS idx_fact_city
ON fact_restaurant_ratings (city_id);


-- Vista resumen con métricas agregadas por ciudad y categoría para facilitar análisis de negocio y reporting.

CREATE OR REPLACE VIEW vw_city_category_ratings AS
SELECT
    c.city,
    cat.category_name,
    COUNT(f.fact_id) AS total_restaurants,
    ROUND(AVG(f.rating_percent), 2) AS avg_rating,
    SUM(f.rating_total) AS total_reviews
FROM fact_restaurant_ratings f
JOIN dim_city c ON f.city_id = c.city_id
JOIN dim_category cat ON f.category_id = cat.category_id
GROUP BY c.city, cat.category_name;


-- Función para calcular el rating medio de una ciudad específica. Por jemplo, fn_avg_rating_by_city('Marrakech').

CREATE OR REPLACE FUNCTION fn_avg_rating_by_city(p_city VARCHAR)
RETURNS NUMERIC AS $$
BEGIN
    RETURN (
        SELECT ROUND(AVG(f.rating_percent), 2)
        FROM fact_restaurant_ratings f
        JOIN dim_city c ON f.city_id = c.city_id
        WHERE c.city = p_city
    );
END;
$$ LANGUAGE plpgsql;
