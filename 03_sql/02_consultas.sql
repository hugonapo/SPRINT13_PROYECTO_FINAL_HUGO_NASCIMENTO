-- ====================================================================
-- 02 · CONSULTAS DE ANÁLISIS · base de datos salud_mental_tech (MySQL 8)
-- Proyecto final · Hugo Nascimento · IT Academy
--
-- Antes de ejecutar estas consultas hay que ejecutar 01_crear_base_datos.sql.
--
-- Cómo he escrito las consultas:
-- - Las palabras reservadas van en MAYÚSCULAS y las tablas y columnas en minúsculas.
-- - Utilizo siempre los mismos alias: e = 'encuestas', pe = 'personas', r = 'respuestas',
--   p = 'preguntas', pa = 'paises', te = 'temas' y ta = 'tamanos_empresa'.
--
-- En la tabla 'respuestas' hay una fila por persona y pregunta. Para tener una columna
-- por pregunta utilizo MAX(CASE WHEN p.codigo = '...' THEN r.respuesta END) y agrupo por persona.
-- Los porcentajes los calculo sobre las personas que respondieron (los nulos no cuentan).
-- ====================================================================

USE salud_mental_tech;


-- ---------------------------------------------------------------------
-- BLOQUE 0 · CONOCER LOS DATOS
-- Primero miro cuántas personas hay, de dónde son y qué se pregunta, para saber con qué trabajo.
-- ---------------------------------------------------------------------

-- 0.1 Personas y respuestas por encuesta
SELECT e.anio,
       COUNT(DISTINCT pe.persona_id) AS personas,
       COUNT(r.respuesta_id) AS respuestas,
       COUNT(DISTINCT r.pregunta_id) AS preguntas
FROM encuestas e
JOIN personas pe ON pe.encuesta_id = e.encuesta_id
JOIN respuestas r ON r.persona_id = pe.persona_id
GROUP BY e.anio
ORDER BY e.anio;

-- 0.2 Género de las personas encuestadas, con el % sobre el total (función ventana)
SELECT pe.genero,
       COUNT(*) AS personas,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_personas
FROM personas pe
GROUP BY pe.genero
ORDER BY personas DESC;

-- 0.3 Diez países con más personas encuestadas
SELECT pa.pais_iso3,
       pa.pais,
       pa.region,
       COUNT(pe.persona_id) AS personas,
       ROUND(100.0 * COUNT(pe.persona_id) / SUM(COUNT(pe.persona_id)) OVER (), 1) AS pct_personas
FROM personas pe
JOIN paises pa ON pa.pais_iso3 = pe.pais_iso3
GROUP BY pa.pais_iso3, pa.pais, pa.region
ORDER BY personas DESC
LIMIT 10;

-- 0.4 Preguntas por tema y número de encuestas en las que aparece cada tema
SELECT te.tema,
       COUNT(DISTINCT p.pregunta_id) AS preguntas,
       COUNT(DISTINCT pe.encuesta_id) AS encuestas_con_el_tema
FROM temas te
JOIN preguntas p ON p.tema_id = te.tema_id
JOIN respuestas r ON r.pregunta_id = p.pregunta_id
JOIN personas pe ON pe.persona_id = r.persona_id
GROUP BY te.tema
ORDER BY preguntas DESC;


-- ---------------------------------------------------------------------
-- HIPÓTESIS 1 · "En tech, los problemas de salud mental son algo minoritario"
-- Miro cuánta gente tiene un trastorno y si le afecta en el trabajo.
-- ---------------------------------------------------------------------

-- 1.1 ¿Tienes actualmente un trastorno de salud mental? (encuestas 2016-2019)
SELECT r.respuesta AS trastorno_actual,
       COUNT(*) AS personas,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_personas
FROM respuestas r
JOIN preguntas p ON p.pregunta_id = r.pregunta_id
WHERE p.codigo = 'trastorno_actual'
  AND r.respuesta IS NOT NULL
GROUP BY r.respuesta
ORDER BY personas DESC;

-- 1.2 Diagnósticos más frecuentes (pregunta de respuesta múltiple, encuesta 2016)
SELECT r.respuesta AS diagnostico,
       COUNT(DISTINCT r.persona_id) AS personas
FROM respuestas r
JOIN preguntas p ON p.pregunta_id = r.pregunta_id
WHERE p.codigo = 'diagnostico'
  AND r.respuesta IS NOT NULL
GROUP BY r.respuesta
ORDER BY personas DESC, diagnostico
LIMIT 8;

-- 1.3 ¿Interfiere en el trabajo? Con tratamiento frente a sin tratamiento (quien tiene un trastorno)
SELECT p.codigo AS situacion,
       ROUND(100.0 * AVG(CASE WHEN r.respuesta = 'A menudo' THEN 1 ELSE 0 END), 1) AS pct_a_menudo,
       ROUND(100.0 * AVG(CASE WHEN r.respuesta = 'A veces' THEN 1 ELSE 0 END), 1) AS pct_a_veces,
       ROUND(100.0 * AVG(CASE WHEN r.respuesta = 'Rara vez' THEN 1 ELSE 0 END), 1) AS pct_rara_vez,
       ROUND(100.0 * AVG(CASE WHEN r.respuesta = 'Nunca' THEN 1 ELSE 0 END), 1) AS pct_nunca,
       COUNT(*) AS personas
FROM respuestas r
JOIN preguntas p ON p.pregunta_id = r.pregunta_id
WHERE (p.codigo = 'interfiere_con_tratamiento' OR p.codigo = 'interfiere_sin_tratamiento')
  AND r.respuesta <> 'No aplica'
GROUP BY p.codigo;


-- ---------------------------------------------------------------------
-- HIPÓTESIS 2 · "Las empresas tech cuidan la salud mental de su gente"
-- Miro qué nota le pone la gente al sector y qué hace de verdad su empresa.
-- ---------------------------------------------------------------------

-- 2.1 Nota que dan al sector tech en apoyo a la salud mental (1 = muy mal, 5 = muy bien, 2017-2019)
SELECT r.respuesta AS nota_apoyo_sector,
       COUNT(*) AS personas,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_personas
FROM respuestas r
JOIN preguntas p ON p.pregunta_id = r.pregunta_id
WHERE p.codigo = 'apoyo_sector_tech'
  AND r.respuesta IS NOT NULL
GROUP BY r.respuesta
ORDER BY r.respuesta;

-- 2.2 Nota media del sector tech por año
SELECT e.anio,
       ROUND(AVG(CAST(r.respuesta AS DECIMAL(4, 1))), 2) AS nota_media,
       COUNT(*) AS personas
FROM respuestas r
JOIN preguntas p ON p.pregunta_id = r.pregunta_id
JOIN personas pe ON pe.persona_id = r.persona_id
JOIN encuestas e ON e.encuesta_id = pe.encuesta_id
WHERE p.codigo = 'apoyo_sector_tech'
  AND r.respuesta IS NOT NULL
GROUP BY e.anio
ORDER BY e.anio;

-- 2.3 Lo que hace la empresa actual (empleados por cuenta ajena, 2016-2019)
SELECT p.codigo AS accion_empresa,
       ROUND(100.0 * AVG(CASE WHEN r.respuesta = 'Sí' THEN 1 ELSE 0 END), 1) AS pct_si,
       ROUND(100.0 * AVG(CASE WHEN r.respuesta = 'No' THEN 1 ELSE 0 END), 1) AS pct_no,
       ROUND(100.0 * AVG(CASE WHEN r.respuesta = 'No lo sé' THEN 1 ELSE 0 END), 1) AS pct_no_lo_sabe,
       COUNT(*) AS personas
FROM respuestas r
JOIN preguntas p ON p.pregunta_id = r.pregunta_id
JOIN personas pe ON pe.persona_id = r.persona_id
WHERE (p.codigo = 'empresa_hablo_formalmente' OR p.codigo = 'empresa_ofrece_recursos')
  AND r.respuesta IS NOT NULL
  AND pe.encuesta_id >= 2016
GROUP BY p.codigo;

-- 2.4 ¿Crees que se resentiría tu carrera si se supiera que tienes un problema de salud mental? (2016)
SELECT r.respuesta AS danaria_carrera,
       COUNT(*) AS personas,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_personas
FROM respuestas r
JOIN preguntas p ON p.pregunta_id = r.pregunta_id
WHERE p.codigo = 'danaria_carrera'
  AND r.respuesta IS NOT NULL
GROUP BY r.respuesta
ORDER BY personas DESC;


-- ---------------------------------------------------------------------
-- HIPÓTESIS 3 · "Hoy se habla de salud mental en el trabajo con normalidad"
-- Miro si la gente se atreve a hablar y si ha visto malas respuestas.
-- ---------------------------------------------------------------------

-- 3.1 ¿Lo contarías en una entrevista de trabajo? (las 5 encuestas)
SELECT r.respuesta AS lo_contaria_en_entrevista,
       COUNT(*) AS personas,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_personas
FROM respuestas r
JOIN preguntas p ON p.pregunta_id = r.pregunta_id
WHERE p.codigo = 'lo_contaria_en_entrevista'
  AND r.respuesta IS NOT NULL
GROUP BY r.respuesta
ORDER BY personas DESC;

-- 3.2 ¿Te sentirías cómodo hablándolo con tu supervisor o con tus compañeros? (2016-2019)
SELECT p.codigo AS con_quien,
       ROUND(100.0 * AVG(CASE WHEN r.respuesta = 'Sí' THEN 1 ELSE 0 END), 1) AS pct_si,
       ROUND(100.0 * AVG(CASE WHEN r.respuesta = 'Quizá' THEN 1 ELSE 0 END), 1) AS pct_quiza,
       ROUND(100.0 * AVG(CASE WHEN r.respuesta = 'No' THEN 1 ELSE 0 END), 1) AS pct_no,
       COUNT(*) AS personas
FROM respuestas r
JOIN preguntas p ON p.pregunta_id = r.pregunta_id
WHERE (p.codigo = 'comodo_hablar_supervisor' OR p.codigo = 'comodo_hablar_companeros')
  AND r.respuesta IS NOT NULL
GROUP BY p.codigo;

-- 3.3 ¿Has visto o vivido una mala respuesta a un problema de salud mental en el trabajo? (2016-2019)
SELECT r.respuesta AS vio_respuesta_negativa,
       COUNT(*) AS personas,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_personas
FROM respuestas r
JOIN preguntas p ON p.pregunta_id = r.pregunta_id
WHERE p.codigo = 'vio_respuesta_negativa'
  AND r.respuesta IS NOT NULL
GROUP BY r.respuesta
ORDER BY personas DESC;


-- ---------------------------------------------------------------------
-- HIPÓTESIS 4 · "La situación está mejorando con los años"
-- Utilizo tres preguntas que están en las 5 encuestas. Con una CTE calculo el % de cada año
-- y con LAG la diferencia con el año anterior.
-- ---------------------------------------------------------------------

-- 4.1 Evolución 2014-2019
WITH respuestas_persona AS (
    SELECT r.persona_id,
           MAX(CASE WHEN p.codigo = 'tratamiento_alguna_vez' THEN r.respuesta END) AS tratamiento,
           MAX(CASE WHEN p.codigo = 'prestaciones_salud_mental' THEN r.respuesta END) AS prestaciones,
           MAX(CASE WHEN p.codigo = 'anonimato_protegido' THEN r.respuesta END) AS anonimato,
           MAX(CASE WHEN p.codigo = 'lo_contaria_en_entrevista' THEN r.respuesta END) AS entrevista
    FROM respuestas r
    JOIN preguntas p ON p.pregunta_id = r.pregunta_id
    GROUP BY r.persona_id
),
indicadores_anio AS (
    SELECT pe.encuesta_id AS anio,
           ROUND(100.0 * AVG(CASE WHEN rp.tratamiento = 'Sí' THEN 1 ELSE 0 END), 1) AS pct_busco_tratamiento,
           ROUND(100.0 * AVG(CASE WHEN rp.prestaciones = 'Sí' THEN 1
                                WHEN rp.prestaciones IS NULL THEN NULL ELSE 0 END), 1) AS pct_empresa_con_prestaciones,
           ROUND(100.0 * AVG(CASE WHEN rp.anonimato = 'Sí' THEN 1
                                WHEN rp.anonimato IS NULL THEN NULL ELSE 0 END), 1) AS pct_anonimato_garantizado,
           ROUND(100.0 * AVG(CASE WHEN rp.entrevista = 'Sí' THEN 1 ELSE 0 END), 1) AS pct_lo_contaria_en_entrevista
    FROM respuestas_persona rp
    JOIN personas pe ON pe.persona_id = rp.persona_id
    GROUP BY pe.encuesta_id
)
SELECT ia.anio,
       ia.pct_busco_tratamiento,
       ROUND(ia.pct_busco_tratamiento - LAG(ia.pct_busco_tratamiento) OVER (ORDER BY ia.anio), 1) AS var_tratamiento,
       ia.pct_empresa_con_prestaciones,
       ROUND(ia.pct_empresa_con_prestaciones - LAG(ia.pct_empresa_con_prestaciones) OVER (ORDER BY ia.anio), 1) AS var_prestaciones,
       ia.pct_anonimato_garantizado,
       ia.pct_lo_contaria_en_entrevista
FROM indicadores_anio ia
ORDER BY ia.anio;


-- ---------------------------------------------------------------------
-- HIPÓTESIS 5 · "Da igual en qué empresa trabajes"
-- Miro si lo que hace la empresa cambia que la gente se atreva a hablar y a buscar ayuda.
-- ---------------------------------------------------------------------

-- 5.1 Comodidad para hablar con el supervisor según la importancia que la empresa da a la salud mental (0-10, 2017-2019)
WITH respuestas_persona AS (
    SELECT r.persona_id,
           MAX(CASE WHEN p.codigo = 'importancia_empresa_salud_mental' THEN r.respuesta END) AS importancia,
           MAX(CASE WHEN p.codigo = 'comodo_hablar_supervisor' THEN r.respuesta END) AS supervisor
    FROM respuestas r
    JOIN preguntas p ON p.pregunta_id = r.pregunta_id
    GROUP BY r.persona_id
)
SELECT CASE WHEN CAST(rp.importancia AS DECIMAL(4, 1)) <= 3 THEN '1) Baja (0-3)'
            WHEN CAST(rp.importancia AS DECIMAL(4, 1)) <= 6 THEN '2) Media (4-6)'
            ELSE '3) Alta (7-10)' END AS importancia_empresa,
       COUNT(*) AS personas,
       ROUND(100.0 * AVG(CASE WHEN rp.supervisor = 'Sí' THEN 1 ELSE 0 END), 1) AS pct_hablaria_con_supervisor
FROM respuestas_persona rp
WHERE rp.importancia IS NOT NULL
  AND rp.supervisor IS NOT NULL
GROUP BY importancia_empresa
ORDER BY importancia_empresa;

-- 5.2 Haber buscado tratamiento según si la empresa ofrece prestaciones de salud mental (las 5 encuestas)
WITH respuestas_persona AS (
    SELECT r.persona_id,
           MAX(CASE WHEN p.codigo = 'prestaciones_salud_mental' THEN r.respuesta END) AS prestaciones,
           MAX(CASE WHEN p.codigo = 'tratamiento_alguna_vez' THEN r.respuesta END) AS tratamiento
    FROM respuestas r
    JOIN preguntas p ON p.pregunta_id = r.pregunta_id
    GROUP BY r.persona_id
)
SELECT rp.prestaciones,
       COUNT(*) AS personas,
       ROUND(100.0 * AVG(CASE WHEN rp.tratamiento = 'Sí' THEN 1 ELSE 0 END), 1) AS pct_busco_tratamiento
FROM respuestas_persona rp
WHERE rp.prestaciones IS NOT NULL
GROUP BY rp.prestaciones
ORDER BY pct_busco_tratamiento DESC;

-- 5.3 Comodidad para hablar con el supervisor y prestaciones según el tamaño de la empresa (2016-2019)
WITH respuestas_persona AS (
    SELECT r.persona_id,
           MAX(CASE WHEN p.codigo = 'comodo_hablar_supervisor' THEN r.respuesta END) AS supervisor,
           MAX(CASE WHEN p.codigo = 'prestaciones_salud_mental' THEN r.respuesta END) AS prestaciones
    FROM respuestas r
    JOIN preguntas p ON p.pregunta_id = r.pregunta_id
    GROUP BY r.persona_id
)
SELECT ta.tamano_id,
       ta.tramo_empleados,
       COUNT(*) AS personas,
       ROUND(100.0 * AVG(CASE WHEN rp.supervisor = 'Sí' THEN 1 ELSE 0 END), 1) AS pct_hablaria_con_supervisor,
       ROUND(100.0 * AVG(CASE WHEN rp.prestaciones = 'Sí' THEN 1 ELSE 0 END), 1) AS pct_con_prestaciones
FROM respuestas_persona rp
JOIN personas pe ON pe.persona_id = rp.persona_id
JOIN tamanos_empresa ta ON ta.tamano_id = pe.tamano_id
WHERE rp.supervisor IS NOT NULL
GROUP BY ta.tamano_id, ta.tramo_empleados
ORDER BY ta.tamano_id;

-- 5.4 Comodidad para hablar con el supervisor: empresa tecnológica frente a no tecnológica (2016-2019)
WITH respuestas_persona AS (
    SELECT r.persona_id,
           MAX(CASE WHEN p.codigo = 'comodo_hablar_supervisor' THEN r.respuesta END) AS supervisor
    FROM respuestas r
    JOIN preguntas p ON p.pregunta_id = r.pregunta_id
    GROUP BY r.persona_id
)
SELECT CASE pe.empresa_tech WHEN 1 THEN 'Empresa tecnológica' ELSE 'Empresa no tecnológica' END AS tipo_empresa,
       COUNT(*) AS personas,
       ROUND(100.0 * AVG(CASE WHEN rp.supervisor = 'Sí' THEN 1 ELSE 0 END), 1) AS pct_hablaria_con_supervisor
FROM respuestas_persona rp
JOIN personas pe ON pe.persona_id = rp.persona_id
WHERE rp.supervisor IS NOT NULL
  AND pe.empresa_tech IS NOT NULL
GROUP BY pe.empresa_tech;


-- ---------------------------------------------------------------------
-- BLOQUE 6 · CONEXIÓN CON LOS MODELOS DE MACHINE LEARNING
-- He añadido estas dos consultas después de hacer los modelos de los notebooks 03 y 04.
-- Son dos de los factores que más pesan en la regresión logística y en el Random Forest,
-- y así se puede ver el mismo resultado directamente en SQL.
-- Utilizo los mismos datos que en los modelos: encuestas 2017-2019 y solo empleados por cuenta ajena.
-- ---------------------------------------------------------------------

-- 6.1 Trastorno actual según los antecedentes familiares (2017-2019, empleados)
WITH respuestas_persona AS (
    SELECT r.persona_id,
           MAX(CASE WHEN p.codigo = 'historial_familiar' THEN r.respuesta END) AS antecedentes,
           MAX(CASE WHEN p.codigo = 'trastorno_actual' THEN r.respuesta END) AS trastorno
    FROM respuestas r
    JOIN preguntas p ON p.pregunta_id = r.pregunta_id
    GROUP BY r.persona_id
)
SELECT rp.antecedentes AS antecedentes_familiares,
       COUNT(*) AS personas,
       ROUND(100.0 * AVG(CASE WHEN rp.trastorno = 'Sí' THEN 1 ELSE 0 END), 1) AS pct_trastorno_si,
       ROUND(100.0 * AVG(CASE WHEN rp.trastorno IN ('Posiblemente', 'Quizá') THEN 1 ELSE 0 END), 1) AS pct_trastorno_quiza,
       ROUND(100.0 * AVG(CASE WHEN rp.trastorno = 'No' THEN 1 ELSE 0 END), 1) AS pct_trastorno_no
FROM respuestas_persona rp
JOIN personas pe ON pe.persona_id = rp.persona_id
JOIN encuestas e ON e.encuesta_id = pe.encuesta_id
WHERE e.anio BETWEEN 2017 AND 2019
  AND pe.autonomo = 0
  AND rp.antecedentes IS NOT NULL
  AND rp.trastorno IS NOT NULL
GROUP BY rp.antecedentes
ORDER BY pct_trastorno_si DESC;

-- 6.2 Hablaría con su supervisor según lo fácil que sea pedir una baja por salud mental (2017-2019, empleados)
WITH respuestas_persona AS (
    SELECT r.persona_id,
           MAX(CASE WHEN p.codigo = 'facilidad_baja_medica' THEN r.respuesta END) AS facilidad_baja,
           MAX(CASE WHEN p.codigo = 'comodo_hablar_supervisor' THEN r.respuesta END) AS supervisor
    FROM respuestas r
    JOIN preguntas p ON p.pregunta_id = r.pregunta_id
    GROUP BY r.persona_id
)
SELECT CASE WHEN rp.facilidad_baja IN ('Muy fácil', 'Algo fácil') THEN '1) Fácil'
            WHEN rp.facilidad_baja = 'Ni fácil ni difícil' THEN '2) Ni fácil ni difícil'
            WHEN rp.facilidad_baja IN ('Algo difícil', 'Muy difícil', 'Difícil') THEN '3) Difícil'
            ELSE '4) No lo sé' END AS facilidad_pedir_baja,
       COUNT(*) AS personas,
       ROUND(100.0 * AVG(CASE WHEN rp.supervisor = 'Sí' THEN 1 ELSE 0 END), 1) AS pct_hablaria_con_supervisor
FROM respuestas_persona rp
JOIN personas pe ON pe.persona_id = rp.persona_id
JOIN encuestas e ON e.encuesta_id = pe.encuesta_id
WHERE e.anio BETWEEN 2017 AND 2019
  AND pe.autonomo = 0
  AND rp.facilidad_baja IS NOT NULL
  AND rp.supervisor IS NOT NULL
GROUP BY facilidad_pedir_baja
ORDER BY facilidad_pedir_baja;
