/*******************************************************************************
PROYECTO: Análisis de Engagement y Comportamiento de Usuario
HERRAMIENTAS: MySQL + Excel
AUTOR: Paula Fernández
OBJETIVO: Identificar las categorías de contenido con mayor rendimiento (Score)
          y analizar la salud de la comunidad.
*******************************************************************************/

-- 1. CONFIGURACIÓN E INTEGRIDAD INICIAL
CREATE DATABASE IF NOT EXISTS proyecto_social_media;
USE proyecto_social_media;

-- Verificación de carga total de registros por tabla
SELECT 'users' AS tabla, COUNT(*) AS total FROM users
UNION ALL
SELECT 'content', COUNT(*) FROM content
UNION ALL
SELECT 'reactions', COUNT(*) FROM reactions
UNION ALL
SELECT 'reaction_types', COUNT(*) FROM reaction_types;


-- 2. AUDITORÍA DE CALIDAD DE DATOS (DATA PROFILING)
-- Identificación de inconsistencias antes de la limpieza.

-- A. Detección de categorías con errores de formato (comillas y mayúsculas)
SELECT Category, COUNT(*) 
FROM content 
GROUP BY Category 
ORDER BY Category;

-- B. Búsqueda de registros huérfanos en la tabla de hechos (Reactions)
-- Verificamos User_ID y Content_ID para asegurar la trazabilidad
SELECT COUNT(*) FROM reactions WHERE User_ID = '' OR User_ID IS NULL;
SELECT COUNT(*) FROM reactions WHERE Content_ID = '' OR Content_ID IS NULL;

-- C. Inspección de sintaxis en intereses de usuario
SELECT Interests FROM user_profiles LIMIT 10;


-- 3. LIMPIEZA Y NORMALIZACIÓN DE DATOS (DATA CLEANING)
-- Aplicación de correcciones para garantizar la fiabilidad del análisis.

-- Desactivar modo seguro para permitir actualizaciones masivas
SET SQL_SAFE_UPDATES = 0;

-- A. Normalización de Categorías en la "tabla Content"
-- Eliminar comillas dobles y estandarizar a minúsculas
UPDATE content SET Category = REPLACE(Category, '"', '');
UPDATE content SET Category = LOWER(Category);

-- B. Limpieza de Sintaxis en "tabla User_Profiles" (Intereses)
UPDATE user_profiles 
SET Interests = REPLACE(REPLACE(REPLACE(Interests, '[', ''), ']', ''), "'", "");

-- C. Depuración de Registros Incompletos
-- Eliminamos los 3,019 registros sin User_ID detectados en la auditoría
DELETE FROM reactions WHERE User_ID = '' OR User_ID IS NULL;

-- Reactivar modo seguro por buena práctica
SET SQL_SAFE_UPDATES = 1;


-- 4. CONSULTAS DE ANÁLISIS ESTRATÉGICO (INSIGHTS)
-- Estas consultas generan los datos para el Dashboard de Excel.

-- CONSULTA A: Top de Categorías por Engagement Total (Query Maestra)
SELECT 
    c.Category, 
    SUM(rt.Score) AS Total_Score
FROM reactions r
JOIN content c ON r.Content_ID = c.Content_ID
JOIN reaction_types rt ON r.Type = rt.Type
GROUP BY c.Category
ORDER BY Total_Score DESC;

-- CONSULTA B: Análisis de Intereses Primarios de Usuarios
-- Limpiamos datos numéricos y extraemos solo el interés principal
SELECT 
    TRIM(SUBSTRING_INDEX(Interests, ',', 1)) AS Primary_Interest, 
    COUNT(*) AS Total_Users
FROM user_profiles
WHERE Interests NOT REGEXP '^[0-9]'
GROUP BY Primary_Interest
ORDER BY Total_Users DESC;

-- CONSULTA C: Engagement por Formato de Contenido (Video, Foto, etc.)
SELECT 
    c.Type AS Content_Type, 
    SUM(rt.Score) AS Total_Score
FROM reactions r
JOIN content c ON r.Content_ID = c.Content_ID
JOIN reaction_types rt ON r.Type = rt.Type
GROUP BY c.Type
ORDER BY Total_Score DESC;

-- CONSULTA D: Análisis de Sentimiento y Salud de la Comunidad
SELECT 
    rt.Sentiment, 
    COUNT(*) AS Total_Reactions, 
    SUM(rt.Score) AS Total_Score
FROM reactions r
JOIN reaction_types rt ON r.Type = rt.Type
GROUP BY rt.Sentiment
ORDER BY Total_Score DESC;
