# Proyecto SQL – Diseño de Base de Datos Relacional y Análisis Exploratorio  
## Plataforma de Restaurantes (Caso Glovo – Marruecos)

---

## 1. Objetivo del proyecto

El objetivo de este proyecto es diseñar, implementar y analizar una base de datos relacional utilizando SQL, siguiendo un enfoque de **modelo estrella (Star Schema)** con una tabla de hechos y varias tablas de dimensiones.

A partir de un conjunto de datos real descargado de Kaggle, se realiza:
- Limpieza y transformación de datos
- Normalización del modelo
- Creación de claves primarias y foráneas
- Análisis exploratorio de datos (EDA) exclusivamente con SQL
- Extracción de insights relevantes para la toma de decisiones de negocio

El proyecto se ha desarrollado utilizando **PostgreSQL en Docker** y consultas ejecutadas desde **TablePlus** y **VSCode**.

---

## 2. Origen del dataset

El dataset utilizado en este proyecto ha sido descargado desde **Kaggle**, y contiene información de los restaurantes disponibles en la plataforma Glovo dentro de Marruecos.

🔗 **URL del dataset en Kaggle:**  
https://www.kaggle.com/datasets/elharitamine/glovo-restaurants-data

El fichero original (`glovo_data.csv`) cuenta con aproximadamente **46.209 registros**, donde cada fila representa un restaurante registrado en la plataforma.

---

## 3. Estructura original del CSV

La siguiente tabla representa la estructura original del fichero CSV, previa a cualquier proceso de limpieza o transformación:

| Columna | Descripción | Tipo de Dato sugerido | Rol en el Proyecto |
|------|-----------|----------------------|-------------------|
| restaurant name | El nombre comercial del establecimiento. | VARCHAR | Atributo de Dimensión |
| restaurant url | Enlace directo al perfil del restaurante. | TEXT | Atributo (posible candidato a borrar) |
| City | Ciudad donde opera el restaurante (ej. Agadir, Tétouan). | VARCHAR | Dimensión Geográfica |
| Category Name | Tipo de comida o sección (ej. Sandwichs, Tacos, Pizza). | VARCHAR | Dimensión Categoría |
| Link | Enlace a la categoría específica (el que se elimina durante la limpieza). | TEXT | - |
| RATING | Puntuación porcentual (ej. 94%, 75%). | VARCHAR / INT | Métrica de Calidad |
| RATING TOTAL | Número de reseñas entre paréntesis (ej. (500+), (90)). | VARCHAR | Métrica de Popularidad |

---

## 4. Modelo de datos y estructura del proyecto

El proyecto sigue una arquitectura de **Data Warehouse**, separando claramente:

- **Tablas de dimensiones** (información descriptiva)
- **Tabla de hechos** (métricas)
- **Vistas y funciones** para facilitar el análisis

### Estructura del repositorio

```
glovo/
│
├── data/
│   └── glovo_data.csv
│
├── sql/
│   ├── 01_schema.sql
│   ├── 02_data.sql
│   └── 03_eda.sql
│
├── ER_Glovo.png
└── README.md
```


## Modelo Entidad–Relación

El siguiente diagrama representa el modelo entidad–relación del proyecto, diseñado siguiendo un enfoque de **modelo estrella**, donde la tabla de hechos se relaciona con múltiples tablas de dimensiones.

![ER_Glovo](ER_Glovo.png)


---

## 5. Descripción de los ficheros SQL

### 01_schema.sql – Diseño del modelo

En este fichero se define la estructura completa de la base de datos.

**Tablas de dimensión:**
- **dim_restaurant**: información descriptiva del restaurante.
- **dim_city**: dimensión geográfica para análisis por ciudad.
- **dim_category**: clasificación de los restaurantes por tipo de comida.
- **dim_calendar**: dimensión temporal para análisis por fecha.

**Tabla de hechos:**
- **fact_restaurant_ratings**: tabla central que almacena las métricas de calidad y popularidad (`rating_percent` y `rating_total`) junto con las claves foráneas a las dimensiones.

Además, se incluyen:
- Una **vista (VIEW)** para simplificar consultas analíticas.
- Una **función SQL** para reutilizar lógica de análisis.

Todas las tablas incluyen claves primarias, claves foráneas, constraints y comentarios explicativos.

---

### 02_data.sql – Limpieza y carga de datos

En este fichero se realiza:
- Limpieza del CSV original
- Normalización de nombres de columnas
- Tratamiento de valores nulos y valores no válidos
- Conversión de tipos de datos
- Eliminación de columnas no relevantes
- Carga de datos en las tablas de dimensiones
- Inserción final en la tabla de hechos

Se utilizan transacciones (`BEGIN / COMMIT`) para garantizar la integridad de los datos durante la carga.

---

### 03_eda.sql – Análisis Exploratorio de Datos (EDA)

Este fichero constituye el núcleo analítico del proyecto.

Incluye:
- JOINs entre tablas de hechos y dimensiones
- Agregaciones (COUNT, AVG, SUM)
- CTEs encadenadas (`WITH`)
- Funciones ventana (`OVER (PARTITION BY ...)`)
- CASE y lógica condicional
- Subqueries
- Creación de métricas y KPIs

Cada bloque de consultas incluye comentarios explicativos sobre los insights obtenidos y su relevancia desde el punto de vista de negocio.

---

## 6. Limpieza y transformación de datos

Durante el proceso de preparación de datos se realizaron las siguientes transformaciones principales:

- Eliminación de la columna `Link`
- Conversión de `rating_percent` a valores numéricos entre **0 y 1**
- Conversión de `rating_total` a valores **INTEGER**
- Sustitución de valores no numéricos o vacíos por `NULL`
- Normalización de tipos de datos para facilitar el análisis

---

## 7. Alcance y limitaciones

**Incluido en el proyecto:**
- Modelado relacional completo
- Datos reales de establecimientos
- Análisis exploratorio orientado a negocio

**No incluido:**
- Información de pedidos reales
- Datos de clientes
- Información de precios o ingresos
- Series temporales reales de transacciones

Estas limitaciones se asumen conscientemente y se documentan como parte del diseño.

---

## 8. Tecnologías utilizadas

- Base de datos: **PostgreSQL**
- Contenerización: **Docker**
- IDE SQL: **TablePlus**
- Control de versiones: **GitHub**
- Diagramas: **draw.io**

---

## 9. Conclusión

Este proyecto demuestra la capacidad de diseñar un modelo relacional coherente, preparar datos reales para análisis y extraer insights relevantes utilizando exclusivamente SQL, siguiendo buenas prácticas de modelado y documentación propias de entornos profesionales de análisis de datos y Business Intelligence.


## 10. Documentación

- **Tabla de staging (restaurantes)**: tabla temporal donde se carga el CSV original antes de limpiar y transformar los datos.
  - restaurant_name: *nombre del restaurante tal como aparece en el CSV original.*
  - restaurant_url: *enlace al perfil del restaurante en Glovo.*
  - city: *ciudad donde opera el restaurante.*
  - category_name: *tipo de comida o categoría del restaurante.*
  - rating_percent: *puntuación porcentual del restaurante (ej. 94%).*
  - rating_total: *número total de reseñas o valor de popularidad.*

- **Dimensión dim_restaurant**: almacena información descriptiva de cada restaurante.
  - restaurant_id (PK): *identificador único de cada restaurante.*
  - restaurant_name: *nombre del restaurante.*
  - restaurant_url: *URL del perfil del restaurante.*

- **Dimensión dim_city**: información geográfica de las ciudades donde operan los restaurantes.
  - city_id (PK): *identificador único de cada ciudad.*
  - city_name: *nombre de la ciudad.*

- **Dimensión dim_category**: clasifica los restaurantes según el tipo de comida o categoría.
  - category_id (PK): *identificador único de cada categoría.*
  - category_name: *nombre de la categoría de comida.*

- **Dimensión dim_calendar**: dimensión temporal basada en la fecha de carga de los datos.
  - date_id (PK): *identificador único de la fecha.*
  - load_date: *fecha en que se cargaron los datos en la base de datos.*

- **Tabla de hechos fact_restaurant_ratings**: tabla central que almacena las métricas de los restaurantes y se relaciona con todas las dimensiones.
  - fact_id (PK): *identificador único de cada registro de hecho.*
  - restaurant_id (FK): *clave foránea que apunta a dim_restaurant.*
  - city_id (FK): *clave foránea que apunta a dim_city.*
  - category_id (FK): *clave foránea que apunta a dim_category.*
  - date_id (FK): *clave foránea que apunta a dim_calendar.*
  - rating_percent: *puntuación porcentual del restaurante.*
  - rating_total: *número total de reseñas.*

- **Vista vw_city_category_ratings**: vista que combina datos de dimensiones y tabla de hechos, facilitando análisis agregados.
  - city_name: *nombre de la ciudad.*
  - category_name: *nombre de la categoría de comida.*
  - avg_rating_percent: *promedio de rating porcentual por ciudad y categoría.*
  - total_reviews: *suma de todas las reseñas por ciudad y categoría.*

- **Función fn_avg_rating_by_city**: calcula el rating promedio por ciudad.
  - Parámetro: city_name *nombre de la ciudad a analizar.*
  - Retorna: *rating promedio de todos los restaurantes en esa ciudad.*
