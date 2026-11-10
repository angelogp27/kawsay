-- ============================================================
-- PROYECTO BD2 - Ciencia ciudadana de biodiversidad
-- 04 - CONSULTAS
-- Ejecutar despues de 01, 02 y 03.
-- ============================================================
-- PARTE A. JOINs y agrupaciones
--   INNER JOIN ........ C01 - C03
--   LEFT JOIN ......... C04 - C07
--   RIGHT JOIN ........ C08 - C09
--   FULL OUTER JOIN ... C10 - C11
--   CROSS JOIN ........ C12
--   GROUP BY .......... C13 - C19  (HAVING, ROLLUP, CASE, subconsultas)
--   Avanzadas ......... C20 - C22  (ventana, jerarquica, LAG)
-- PARTE B. Funcionalidades
--   Registro de investigadores ... Q01 - Q04
--   Reportes ..................... Q05 - Q06
--   Apelaciones .................. Q07 - Q08
--   Geoprivacidad ................ Q09 - Q11
-- ============================================================


-- ############################################################
-- PARTE A. JOINS Y AGRUPACIONES
-- ############################################################

-- ============================================================
-- C01 | INNER JOIN (5 tablas + JOIN espacial)
-- Avistamientos verificados con autor, especie validada y el
-- departamento donde ocurrieron. El departamento NO es una FK:
-- se obtiene cruzando el punto con el poligono (RN09).
-- ============================================================
SELECT a.id_avistamiento,
       o.alias                 AS autor,
       t.nombre_cientifico     AS especie_validada,
       e.nombre_comun,
       d.nombre                AS departamento,
       a.metodo_validacion,
       TO_CHAR(a.fecha_hora_avistamiento, 'YYYY-MM-DD') AS fecha
FROM avistamiento a
INNER JOIN observador   o ON o.id_observador = a.id_observador
INNER JOIN taxon        t ON t.id_taxon      = a.id_taxon_validado
INNER JOIN especie      e ON e.id_taxon      = t.id_taxon
INNER JOIN departamento d ON SDO_ANYINTERACT(d.poligono, a.ubicacion) = 'TRUE'
WHERE a.estado = 'verificado'
ORDER BY d.nombre, a.fecha_hora_avistamiento;


-- ============================================================
-- C02 | INNER JOIN de la misma tabla dos veces (TAXON)
-- Correcciones de la comunidad: el taxon propuesto por el autor
-- es distinto del validado. Demuestra por que RN06 obliga a
-- conservar la propuesta original.
-- ============================================================
SELECT a.id_avistamiento,
       o.alias                AS autor,
       tp.nombre_cientifico   AS propuso,
       tp.rango               AS rango_propuesto,
       tv.nombre_cientifico   AS se_valido_como,
       a.metodo_validacion
FROM avistamiento a
INNER JOIN observador o  ON o.id_observador = a.id_observador
INNER JOIN taxon      tp ON tp.id_taxon     = a.id_taxon_propuesto
INNER JOIN taxon      tv ON tv.id_taxon     = a.id_taxon_validado
WHERE a.id_taxon_propuesto <> a.id_taxon_validado;


-- ============================================================
-- C03 | SELF JOIN (AVISTAMIENTO con AVISTAMIENTO)
-- Candidatos a duplicado con los dos observadores involucrados.
-- La tabla DUPLICADO_CANDIDATO se llena sola (trigger, RN25-26).
-- ============================================================
SELECT d.id_avistamiento_a,
       oa.alias               AS observador_a,
       d.id_avistamiento_b,
       ob.alias               AS observador_b,
       t.nombre_cientifico    AS especie,
       d.distancia_metros,
       d.diferencia_minutos,
       d.estado
FROM duplicado_candidato d
INNER JOIN avistamiento a  ON a.id_avistamiento  = d.id_avistamiento_a
INNER JOIN avistamiento b  ON b.id_avistamiento  = d.id_avistamiento_b
INNER JOIN observador   oa ON oa.id_observador   = a.id_observador
INNER JOIN observador   ob ON ob.id_observador   = b.id_observador
INNER JOIN taxon        t  ON t.id_taxon         = a.id_taxon_propuesto
ORDER BY d.id_avistamiento_a;


-- ============================================================
-- C04 | LEFT JOIN
-- Actividad de TODOS los observadores, incluso los que nunca
-- registraron ni identificaron nada (aparecen con 0).
-- Se agrega antes de unir para no multiplicar filas.
-- ============================================================
SELECT o.alias,
       CASE WHEN i.id_observador IS NOT NULL THEN 'investigador' ELSE 'observador' END AS rol,
       NVL(av.registrados, 0)       AS avistamientos,
       NVL(av.verificados, 0)       AS verificados,
       NVL(idf.identificaciones, 0) AS identificaciones,
       o.reputacion
FROM observador o
LEFT JOIN investigador i ON i.id_observador = o.id_observador
LEFT JOIN (SELECT id_observador,
                  COUNT(*) AS registrados,
                  SUM(CASE WHEN estado = 'verificado' THEN 1 ELSE 0 END) AS verificados
           FROM avistamiento
           GROUP BY id_observador) av ON av.id_observador = o.id_observador
LEFT JOIN (SELECT id_observador, COUNT(*) AS identificaciones
           FROM identificacion
           GROUP BY id_observador) idf ON idf.id_observador = o.id_observador
ORDER BY avistamientos DESC, identificaciones DESC;


-- ============================================================
-- C05 | LEFT JOIN como anti-join  ("especies buscadas")
-- Condiciones de PRESENCIA_ESPERADA que todavia no tienen ningun
-- avistamiento valido en ese departamento. Orienta a los
-- voluntarios sobre que buscar y donde.
-- ============================================================
SELECT e.nombre_comun,
       e.estado_conservacion,
       d.nombre        AS departamento,
       pe.mes_inicio,
       pe.mes_fin
FROM presencia_esperada pe
INNER JOIN especie      e ON e.id_taxon        = pe.id_taxon
INNER JOIN departamento d ON d.id_departamento = pe.id_departamento
LEFT JOIN avistamiento  a
       ON NVL(a.id_taxon_validado, a.id_taxon_propuesto) = pe.id_taxon
      AND a.estado <> 'rechazado'
      AND SDO_GEOM.RELATE(d.poligono, 'ANYINTERACT', a.ubicacion, 0.005) = 'TRUE'
WHERE a.id_avistamiento IS NULL
ORDER BY e.estado_conservacion DESC, e.nombre_comun;


-- ============================================================
-- C06 | LEFT JOIN (departamento -> investigador)
-- Cobertura territorial: departamentos sin investigador y cuantas
-- alertas abiertas se acumulan alli sin nadie que las atienda (RN22).
-- ============================================================
-- (No se puede hacer GROUP BY sobre una columna SDO_GEOMETRY:
--  por eso los investigadores se agregan antes en una subconsulta.)
SELECT d.nombre                          AS departamento,
       NVL(inv.cantidad, 0)              AS investigadores,
       NVL(inv.nombres, '-- ninguno --') AS investigador,
       (SELECT COUNT(*)
        FROM alerta al
        JOIN avistamiento a ON a.id_avistamiento = al.id_avistamiento
        WHERE al.estado IN ('pendiente', 'asignada')
          AND SDO_GEOM.RELATE(d.poligono, 'ANYINTERACT', a.ubicacion, 0.005) = 'TRUE') AS alertas_abiertas
FROM departamento d
LEFT JOIN (SELECT i.id_departamento,
                  COUNT(*) AS cantidad,
                  LISTAGG(o.alias, ', ') WITHIN GROUP (ORDER BY o.alias) AS nombres
           FROM investigador i
           JOIN observador o ON o.id_observador = i.id_observador
           GROUP BY i.id_departamento) inv
       ON inv.id_departamento = d.id_departamento
ORDER BY investigadores, alertas_abiertas DESC;


-- ============================================================
-- C07 | LEFT JOIN con condicion compuesta
-- Inscritos en una campania que todavia no aportaron avistamientos.
-- ============================================================
SELECT c.nombre        AS campania,
       o.alias         AS inscrito,
       pc.rol,
       c.fecha_inicio,
       c.fecha_fin
FROM participacion_campania pc
INNER JOIN campania   c ON c.id_campania   = pc.id_campania
INNER JOIN observador o ON o.id_observador = pc.id_observador
LEFT JOIN avistamiento a
       ON a.id_campania   = pc.id_campania
      AND a.id_observador = pc.id_observador
WHERE a.id_avistamiento IS NULL
ORDER BY c.fecha_inicio, o.alias;


-- ============================================================
-- C08 | RIGHT JOIN
-- Esfuerzo de muestreo por celda: TODAS las celdas de la grilla
-- (tabla de la derecha), incluidas las que nunca se muestrearon.
-- ============================================================
SELECT c.id_celda,
       COUNT(s.id_salida)                                         AS salidas,
       NVL(ROUND(SUM((CAST(s.fecha_hora_fin AS DATE)
                    - CAST(s.fecha_hora_inicio AS DATE)) * 24), 1), 0) AS horas,
       NVL(SUM(s.distancia_km), 0)                                AS km_recorridos,
       CASE WHEN COUNT(s.id_salida) = 0 THEN 'SIN MUESTREO' END   AS observacion
FROM salida_campo s
RIGHT JOIN celda_muestreo c ON c.id_celda = s.id_celda
GROUP BY c.id_celda
ORDER BY horas DESC, c.id_celda;


-- ============================================================
-- C09 | RIGHT JOIN espacial
-- Biodiversidad por area protegida: riqueza de especies,
-- especies amenazadas e individuos. Las areas sin registros
-- tambien aparecen (RN23).
-- ============================================================
SELECT ap.nombre                                   AS area_protegida,
       ap.categoria,
       COUNT(a.id_avistamiento)                    AS avistamientos,
       COUNT(DISTINCT e.id_taxon)                  AS especies,
       COUNT(DISTINCT CASE WHEN e.estado_conservacion IN ('VU', 'EN', 'CR')
                           THEN e.id_taxon END)    AS especies_amenazadas,
       NVL(SUM(a.numero_individuos), 0)            AS individuos
FROM avistamiento a
LEFT JOIN especie e ON e.id_taxon = NVL(a.id_taxon_validado, a.id_taxon_propuesto)
RIGHT JOIN area_protegida ap
       ON SDO_GEOM.RELATE(ap.poligono, 'ANYINTERACT', a.ubicacion, 0.005) = 'TRUE'
      AND a.estado <> 'rechazado'
GROUP BY ap.id_area, ap.nombre, ap.categoria
ORDER BY especies DESC, avistamientos DESC;


-- ============================================================
-- C10 | FULL OUTER JOIN
-- Interes vs. realidad: especies que la comunidad sigue frente a
-- especies que realmente se avistan. Muestra a la vez:
--   - seguidas pero nunca vistas  (columna avistamientos = 0)
--   - vistas pero que nadie sigue (columna seguidores   = 0)
-- ============================================================
SELECT NVL(s.id_taxon, v.id_taxon)                         AS id_taxon,
       (SELECT nombre_comun FROM especie
        WHERE id_taxon = NVL(s.id_taxon, v.id_taxon))      AS especie,
       NVL(s.seguidores, 0)                                AS seguidores,
       NVL(v.avistamientos, 0)                             AS avistamientos,
       CASE WHEN s.id_taxon IS NULL THEN 'nadie la sigue'
            WHEN v.id_taxon IS NULL THEN 'nunca avistada'
       END                                                 AS diagnostico
FROM (SELECT id_taxon, COUNT(*) AS seguidores
      FROM seguimiento_especie GROUP BY id_taxon) s
FULL OUTER JOIN
     (SELECT a.id_taxon_validado AS id_taxon, COUNT(*) AS avistamientos
      FROM avistamiento a
      WHERE a.estado = 'verificado'
      GROUP BY a.id_taxon_validado) v
  ON v.id_taxon = s.id_taxon
ORDER BY diagnostico NULLS FIRST, seguidores DESC;


-- ============================================================
-- C11 | FULL OUTER JOIN (investigador <-> alerta)
-- Carga de trabajo: alertas sin responsable e investigadores
-- sin alertas, en una sola consulta.
-- ============================================================
SELECT o.alias            AS investigador,
       d.nombre           AS territorio,
       al.id_alerta,
       al.tipo,
       al.estado
FROM investigador i
INNER JOIN observador o ON o.id_observador = i.id_observador
LEFT JOIN departamento d ON d.id_departamento = i.id_departamento
FULL OUTER JOIN alerta al
       ON al.id_investigador = i.id_observador
      AND al.estado IN ('pendiente', 'asignada')
WHERE al.id_alerta IS NULL
   OR al.estado IN ('pendiente', 'asignada')
ORDER BY o.alias NULLS FIRST, al.id_alerta;


-- ============================================================
-- C12 | CROSS JOIN + LEFT JOIN
-- Matriz especie x departamento: TODAS las combinaciones posibles
-- (producto cartesiano) y cuantos avistamientos tiene cada una.
-- Detecta huecos de informacion y registros fuera de rango.
-- ============================================================
SELECT e.nombre_comun,
       d.nombre AS departamento,
       CASE WHEN pe.id_taxon IS NOT NULL THEN 'si' ELSE 'no' END AS esperada,
       (SELECT COUNT(*) FROM avistamiento a
        WHERE NVL(a.id_taxon_validado, a.id_taxon_propuesto) = e.id_taxon
          AND SDO_GEOM.RELATE(d.poligono, 'ANYINTERACT', a.ubicacion, 0.005) = 'TRUE') AS avistamientos
FROM especie e
CROSS JOIN departamento d
LEFT JOIN (SELECT DISTINCT id_taxon, id_departamento FROM presencia_esperada) pe
       ON pe.id_taxon = e.id_taxon AND pe.id_departamento = d.id_departamento
ORDER BY e.nombre_comun, d.nombre;


-- ============================================================
-- C13 | GROUP BY ROLLUP
-- Avistamientos por departamento y estado con subtotales por
-- departamento y total general.
-- ============================================================
SELECT CASE WHEN GROUPING(d.nombre) = 1 THEN '== TOTAL GENERAL =='
            ELSE d.nombre END                           AS departamento,
       CASE WHEN GROUPING(a.estado) = 1 AND GROUPING(d.nombre) = 0
            THEN '-- subtotal --' ELSE a.estado END     AS estado,
       COUNT(*)                                         AS avistamientos,
       SUM(a.numero_individuos)                         AS individuos
FROM avistamiento a
INNER JOIN departamento d ON SDO_ANYINTERACT(d.poligono, a.ubicacion) = 'TRUE'
GROUP BY ROLLUP (d.nombre, a.estado)
ORDER BY GROUPING(d.nombre), d.nombre, GROUPING(a.estado), a.estado;


-- ============================================================
-- C14 | GROUP BY + HAVING + funcion de ventana
-- Ranking de observadores con al menos 2 avistamientos:
-- riqueza de especies y porcentaje de verificacion.
-- ============================================================
SELECT RANK() OVER (ORDER BY COUNT(DISTINCT a.id_taxon_validado) DESC,
                             COUNT(*) DESC)                       AS puesto,
       o.alias,
       COUNT(*)                                                    AS avistamientos,
       COUNT(DISTINCT a.id_taxon_validado)                         AS especies_confirmadas,
       ROUND(100 * SUM(CASE WHEN a.estado = 'verificado' THEN 1 ELSE 0 END) / COUNT(*), 1)
                                                                   AS pct_verificados,
       SUM(a.numero_individuos)                                    AS individuos
FROM avistamiento a
INNER JOIN observador o ON o.id_observador = a.id_observador
GROUP BY o.id_observador, o.alias
HAVING COUNT(*) >= 2
ORDER BY puesto;


-- ============================================================
-- C15 | GROUP BY con agregacion condicional
-- Fiabilidad por especie propuesta: de las veces que alguien
-- dijo "es X", cuantas se confirmaron, cuantas se corrigieron y
-- cuantas siguen abiertas.
-- ============================================================
SELECT t.nombre_cientifico AS taxon_propuesto,
       COUNT(*) AS veces_propuesto,
       SUM(CASE WHEN a.id_taxon_validado = a.id_taxon_propuesto THEN 1 ELSE 0 END)  AS confirmado,
       SUM(CASE WHEN a.id_taxon_validado <> a.id_taxon_propuesto THEN 1 ELSE 0 END) AS corregido,
       SUM(CASE WHEN a.estado = 'rechazado' THEN 1 ELSE 0 END)                       AS rechazado,
       SUM(CASE WHEN a.estado IN ('pendiente', 'dudoso') THEN 1 ELSE 0 END)          AS abierto
FROM avistamiento a
INNER JOIN taxon t ON t.id_taxon = a.id_taxon_propuesto
GROUP BY t.nombre_cientifico
ORDER BY corregido DESC, veces_propuesto DESC;


-- ============================================================
-- C16 | GROUP BY + subconsulta escalar + CROSS JOIN con parametro
-- Panel de consenso: avistamientos abiertos y el apoyo que tiene
-- cada taxon sugerido por la comunidad frente al umbral
-- configurable (RN13). Si ya hay consenso pero el registro es
-- anomalo, queda esperando al investigador (RN19).
-- ============================================================
SELECT i.id_avistamiento,
       a.estado,
       t.nombre_cientifico   AS taxon_sugerido,
       COUNT(*)              AS votos,
       p.valor               AS umbral,
       CASE WHEN COUNT(*) >= p.valor
            THEN 'consenso: espera investigador'
            ELSE 'faltan ' || (p.valor - COUNT(*)) || ' voto(s)' END AS situacion,
       (SELECT COUNT(*) FROM alerta al
        WHERE al.id_avistamiento = i.id_avistamiento
          AND al.estado IN ('pendiente', 'asignada')) AS alertas_abiertas
FROM identificacion i
INNER JOIN avistamiento      a ON a.id_avistamiento = i.id_avistamiento
INNER JOIN taxon             t ON t.id_taxon        = i.id_taxon_propuesto
CROSS JOIN parametro_sistema p
WHERE p.clave = 'UMBRAL_CONSENSO'
  AND a.estado IN ('pendiente', 'dudoso')
GROUP BY i.id_avistamiento, a.estado, t.nombre_cientifico, p.valor
ORDER BY votos DESC, i.id_avistamiento;


-- ============================================================
-- C17 | GROUP BY con aritmetica de fechas
-- Tablero de investigadores: alertas atendidas, abiertas y
-- tiempo promedio de resolucion en horas.
-- ============================================================
SELECT o.alias                         AS investigador,
       NVL(d.nombre, '(sin territorio)') AS territorio,
       COUNT(al.id_alerta)             AS alertas_totales,
       SUM(CASE WHEN al.estado IN ('resuelta', 'descartada') THEN 1 ELSE 0 END) AS cerradas,
       SUM(CASE WHEN al.estado = 'asignada' THEN 1 ELSE 0 END)                 AS en_curso,
       ROUND(AVG(CAST(al.fecha_resolucion AS DATE)
               - CAST(al.fecha_generacion AS DATE)) * 24, 2)                   AS horas_promedio
FROM investigador i
INNER JOIN observador   o  ON o.id_observador   = i.id_observador
LEFT JOIN  departamento d  ON d.id_departamento = i.id_departamento
LEFT JOIN  alerta       al ON al.id_investigador = i.id_observador
GROUP BY o.alias, d.nombre
ORDER BY alertas_totales DESC;


-- ============================================================
-- C18 | GROUP BY sobre esfuerzo de muestreo
-- Tasa de encuentro (avistamientos e individuos por hora de campo)
-- por celda. Es la metrica que usa eBird para comparar zonas
-- con distinto esfuerzo.
-- Dos niveles de GROUP BY: primero por salida (para no sumar las
-- horas de una salida tantas veces como avistamientos tenga) y
-- luego por celda.
-- ============================================================
SELECT ps.id_celda,
       COUNT(*)                                        AS salidas,
       ROUND(SUM(ps.horas), 1)                         AS horas,
       SUM(ps.avistamientos)                           AS avistamientos,
       SUM(ps.individuos)                              AS individuos,
       ROUND(SUM(ps.avistamientos) / SUM(ps.horas), 2) AS avist_por_hora
FROM (SELECT s.id_salida,
             s.id_celda,
             (CAST(s.fecha_hora_fin AS DATE) - CAST(s.fecha_hora_inicio AS DATE)) * 24 AS horas,
             COUNT(a.id_avistamiento)          AS avistamientos,
             NVL(SUM(a.numero_individuos), 0)  AS individuos
      FROM salida_campo s
      LEFT JOIN avistamiento a ON a.id_salida = s.id_salida
      GROUP BY s.id_salida, s.id_celda, s.fecha_hora_inicio, s.fecha_hora_fin) ps
GROUP BY ps.id_celda
ORDER BY avist_por_hora DESC;


-- ============================================================
-- C19 | GROUP BY + HAVING (control de calidad)
-- Evidencia reutilizada: el mismo archivo (hash) aparece en
-- avistamientos distintos. Posible fraude o error de carga.
-- ============================================================
SELECT ev.hash_archivo,
       COUNT(DISTINCT ev.id_avistamiento)                    AS avistamientos,
       LISTAGG(ev.id_avistamiento || ' (' || o.alias || ')', ', ')
           WITHIN GROUP (ORDER BY ev.id_avistamiento)        AS usado_en
FROM evidencia ev
INNER JOIN avistamiento a ON a.id_avistamiento = ev.id_avistamiento
INNER JOIN observador   o ON o.id_observador   = a.id_observador
GROUP BY ev.hash_archivo
HAVING COUNT(DISTINCT ev.id_avistamiento) > 1;


-- ============================================================
-- C20 | Funcion de ventana (ROW_NUMBER)
-- Primer registro verificado de cada especie en cada departamento:
-- el "descubridor" local.
-- ============================================================
SELECT especie, departamento, descubridor, fecha
FROM (SELECT e.nombre_comun AS especie,
             d.nombre       AS departamento,
             o.alias        AS descubridor,
             TO_CHAR(a.fecha_hora_avistamiento, 'YYYY-MM-DD') AS fecha,
             ROW_NUMBER() OVER (PARTITION BY e.id_taxon, d.id_departamento
                                ORDER BY a.fecha_hora_avistamiento) AS rn
      FROM avistamiento a
      INNER JOIN especie      e ON e.id_taxon      = a.id_taxon_validado
      INNER JOIN observador   o ON o.id_observador = a.id_observador
      INNER JOIN departamento d ON SDO_ANYINTERACT(d.poligono, a.ubicacion) = 'TRUE'
      WHERE a.estado = 'verificado')
WHERE rn = 1
ORDER BY departamento, fecha;


-- ============================================================
-- C21 | Consulta jerarquica (CONNECT BY) + agregacion
-- Arbol taxonomico con el numero de avistamientos de cada rama
-- (un orden suma los de todas sus familias, generos y especies).
-- ============================================================
SELECT LPAD(' ', 2 * (LEVEL - 1)) || t.nombre_cientifico AS arbol,
       t.rango,
       (SELECT COUNT(*)
        FROM avistamiento a
        WHERE NVL(a.id_taxon_validado, a.id_taxon_propuesto) IN
              (SELECT id_taxon FROM taxon
               START WITH id_taxon = t.id_taxon
               CONNECT BY PRIOR id_taxon = id_taxon_padre)) AS avistamientos_rama
FROM taxon t
START WITH t.id_taxon_padre IS NULL
CONNECT BY PRIOR t.id_taxon = t.id_taxon_padre
ORDER SIBLINGS BY t.nombre_cientifico;


-- ============================================================
-- C22 | Trazabilidad completa (auditoria + LAG)
-- Historia de un avistamiento: cada cambio de estado, quien lo
-- hizo y cuanto tiempo paso desde el cambio anterior.
-- ============================================================
SELECT au.id_avistamiento,
       au.estado_anterior,
       au.estado_nuevo,
       au.tipo_actor,
       NVL(o.alias, 'SISTEMA')                                  AS responsable,
       TO_CHAR(au.fecha_hora, 'YYYY-MM-DD HH24:MI')             AS cuando,
       ROUND((CAST(au.fecha_hora AS DATE)
            - CAST(LAG(au.fecha_hora) OVER (PARTITION BY au.id_avistamiento
                                            ORDER BY au.fecha_hora, au.id_auditoria) AS DATE)) * 24, 1)
                                                                AS horas_desde_anterior
FROM auditoria_avistamiento au
LEFT JOIN observador o ON o.id_observador = au.id_observador_responsable
-- 3: validado por investigador | 6: marcado dudoso por el sistema | 10: rechazado
WHERE au.id_avistamiento IN (3, 6, 10)
ORDER BY au.id_avistamiento, au.fecha_hora, au.id_auditoria;


-- ############################################################
-- PARTE B. FUNCIONALIDADES
-- ############################################################

-- ============================================================
-- Q01 | LEFT JOIN + GROUP BY con agregacion condicional
-- Lista de requisitos de cada postulacion: que documento tiene
-- verificado (SI), cual falta (--) y cual esta observado (OBS).
-- ============================================================
SELECT p.id_postulacion,
       o.alias                                AS postulante,
       d.nombre                               AS departamento,
       p.estado,
       MAX(CASE WHEN c.tipo IN ('grado_bachiller', 'titulo_profesional', 'grado_maestria', 'grado_doctor')
                 AND c.estado_verificacion = 'verificada' THEN 'SI' END)            AS grado,
       MAX(CASE WHEN c.tipo = 'colegiatura' AND c.estado_verificacion = 'verificada'
                 AND c.fecha_vencimiento >= TRUNC(SYSDATE) THEN 'SI' END)           AS colegiatura,
       MAX(CASE WHEN c.tipo = 'carta_institucional'
                THEN DECODE(c.estado_verificacion, 'verificada', 'SI', 'observada', 'OBS', 'PEND') END) AS carta,
       MAX(CASE WHEN c.estado_verificacion = 'verificada'
                 AND (c.tipo IN ('grado_maestria', 'grado_doctor')
                      OR (c.tipo IN ('renacyt', 'autorizacion_serfor') AND c.fecha_vencimiento >= TRUNC(SYSDATE)))
                THEN 'SI' END)                                                       AS acredita_investigacion,
       ev.alias                               AS evaluador
FROM postulacion_investigador p
INNER JOIN observador   o  ON o.id_observador   = p.id_observador
INNER JOIN departamento d  ON d.id_departamento = p.id_departamento
LEFT JOIN  credencial   c  ON c.id_observador   = p.id_observador
LEFT JOIN  observador   ev ON ev.id_observador  = p.id_evaluador
GROUP BY p.id_postulacion, o.alias, d.nombre, p.estado, ev.alias
ORDER BY p.id_postulacion;


-- ============================================================
-- Q02 | Anti-join + GROUP BY + HAVING
-- Candidatos: observadores que ya cumplen la experiencia minima
-- dentro de la plataforma pero nunca han postulado.
-- ============================================================
SELECT o.alias,
       o.fecha_registro,
       TRUNC(SYSDATE) - o.fecha_registro          AS dias_en_plataforma,
       COUNT(*)                                   AS identificaciones_acertadas,
       o.reputacion
FROM observador o
INNER JOIN identificacion i ON i.id_observador   = o.id_observador
INNER JOIN avistamiento   a ON a.id_avistamiento = i.id_avistamiento
                           AND a.id_taxon_validado = i.id_taxon_propuesto
LEFT JOIN investigador inv ON inv.id_observador = o.id_observador
LEFT JOIN postulacion_investigador p ON p.id_observador = o.id_observador
WHERE inv.id_observador IS NULL
  AND p.id_postulacion IS NULL
  AND TRUNC(SYSDATE) - o.fecha_registro >= (SELECT valor FROM parametro_sistema WHERE clave = 'POSTULACION_MIN_DIAS')
GROUP BY o.id_observador, o.alias, o.fecha_registro, o.reputacion
HAVING COUNT(*) >= (SELECT valor FROM parametro_sistema WHERE clave = 'POSTULACION_MIN_IDENTIF_OK')
ORDER BY identificaciones_acertadas DESC;


-- ============================================================
-- Q03 | INNER JOIN + CASE (semaforo de vencimientos)
-- Credenciales con vencimiento de los investigadores: vencidas
-- (suspende al investigador si es la colegiatura) o por vencer.
-- ============================================================
SELECT o.alias                        AS investigador,
       NVL(d.nombre, '(sin territorio)') AS territorio,
       c.tipo,
       c.codigo_registro,
       c.fecha_vencimiento,
       c.fecha_vencimiento - TRUNC(SYSDATE) AS dias_restantes,
       CASE WHEN c.fecha_vencimiento < TRUNC(SYSDATE)       THEN 'VENCIDA'
            WHEN c.fecha_vencimiento < TRUNC(SYSDATE) + 60  THEN 'POR VENCER'
            ELSE 'vigente' END        AS situacion
FROM credencial c
INNER JOIN investigador i ON i.id_observador = c.id_observador
INNER JOIN observador   o ON o.id_observador = i.id_observador
LEFT JOIN  departamento d ON d.id_departamento = i.id_departamento
WHERE c.fecha_vencimiento IS NOT NULL
ORDER BY c.fecha_vencimiento;


-- ============================================================
-- Q04 | LEFT JOIN de dos agregados sobre DEPARTAMENTO
-- Cobertura territorial real: investigadores asignados frente a
-- los HABILITADOS (colegiatura vigente) y postulaciones en curso.
-- ============================================================
SELECT d.nombre                       AS departamento,
       NVL(inv.asignados, 0)          AS investigadores,
       NVL(inv.habilitados, 0)        AS habilitados,
       NVL(pos.en_curso, 0)           AS postulaciones_en_curso,
       CASE WHEN NVL(inv.habilitados, 0) = 0 THEN 'SIN COBERTURA' END AS alerta
FROM departamento d
LEFT JOIN (SELECT id_departamento,
                  COUNT(*) AS asignados,
                  SUM(pkg_func.credencial_vigente(id_observador)) AS habilitados
           FROM investigador
           GROUP BY id_departamento) inv ON inv.id_departamento = d.id_departamento
LEFT JOIN (SELECT id_departamento, COUNT(*) AS en_curso
           FROM postulacion_investigador
           WHERE estado IN ('pendiente', 'en_revision')
           GROUP BY id_departamento) pos ON pos.id_departamento = d.id_departamento
ORDER BY habilitados, d.nombre;


-- ============================================================
-- Q05 | GROUP BY ROLLUP
-- Reportes por motivo y resultado, con subtotales.
-- ============================================================
-- (Los alias no deben llamarse igual que las columnas: en el ORDER BY
--  Oracle tomaria el alias y GROUPING() fallaria con ORA-00934.)
SELECT CASE WHEN GROUPING(r.motivo) = 1 THEN '== TOTAL ==' ELSE r.motivo END AS motivo_reporte,
       CASE WHEN GROUPING(r.estado) = 1 AND GROUPING(r.motivo) = 0 THEN '-- subtotal --'
            ELSE r.estado END                                                AS resultado,
       COUNT(*)                                                              AS reportes
FROM reporte_avistamiento r
GROUP BY ROLLUP (r.motivo, r.estado)
ORDER BY GROUPING(r.motivo), r.motivo, GROUPING(r.estado), r.estado;


-- ============================================================
-- Q06 | INNER JOIN + LEFT JOIN + GROUP BY
-- Bandeja de moderacion: avistamientos reportados, cuantos
-- reportes tienen, su estado y quien deberia atenderlos.
-- ============================================================
SELECT a.id_avistamiento,
       autor.alias                                   AS autor,
       d.nombre                                      AS departamento,
       a.estado                                      AS estado_avistamiento,
       COUNT(r.id_reporte)                           AS reportes,
       SUM(CASE WHEN r.estado = 'pendiente' THEN 1 ELSE 0 END) AS pendientes,
       LISTAGG(DISTINCT r.motivo, ', ') WITHIN GROUP (ORDER BY r.motivo) AS motivos,
       (SELECT LISTAGG(o.alias, ', ') WITHIN GROUP (ORDER BY o.alias)
        FROM investigador i JOIN observador o ON o.id_observador = i.id_observador
        WHERE i.id_departamento = d.id_departamento
          AND pkg_func.credencial_vigente(i.id_observador) = 1
          AND i.id_observador <> a.id_observador)    AS puede_atender
FROM reporte_avistamiento r
INNER JOIN avistamiento a     ON a.id_avistamiento = r.id_avistamiento
INNER JOIN observador   autor ON autor.id_observador = a.id_observador
LEFT JOIN  departamento d     ON SDO_ANYINTERACT(d.poligono, a.ubicacion) = 'TRUE'
GROUP BY a.id_avistamiento, autor.alias, d.nombre, d.id_departamento, a.estado, a.id_observador
ORDER BY pendientes DESC, a.id_avistamiento;


-- ============================================================
-- Q07 | UNION ALL de cuatro tablas (expediente cronologico)
-- Historia completa del avistamiento 8: cambios de estado,
-- reportes, apelacion y efectos en la reputacion.
-- ============================================================
SELECT TO_CHAR(fecha, 'YYYY-MM-DD HH24:MI') AS cuando, evento, detalle, actor
FROM (
    SELECT au.fecha_hora AS fecha, 'estado' AS evento,
           NVL(au.estado_anterior, '(nuevo)') || ' -> ' || au.estado_nuevo AS detalle,
           NVL(o.alias, 'SISTEMA') AS actor
    FROM auditoria_avistamiento au
    LEFT JOIN observador o ON o.id_observador = au.id_observador_responsable
    WHERE au.id_avistamiento = 8
    UNION ALL
    SELECT r.fecha_reporte, 'reporte', r.motivo || ' (' || r.estado || ')', o.alias
    FROM reporte_avistamiento r JOIN observador o ON o.id_observador = r.id_reportante
    WHERE r.id_avistamiento = 8
    UNION ALL
    SELECT ap.fecha_apelacion, 'apelacion', SUBSTR(ap.argumento, 1, 50) || '...', o.alias
    FROM apelacion ap JOIN avistamiento a ON a.id_avistamiento = ap.id_avistamiento
    JOIN observador o ON o.id_observador = a.id_observador
    WHERE ap.id_avistamiento = 8
    UNION ALL
    SELECT ap.fecha_resolucion, 'resolucion apelacion', ap.estado || ': ' || SUBSTR(ap.resolucion, 1, 40), o.alias
    FROM apelacion ap JOIN observador o ON o.id_observador = ap.id_investigador
    WHERE ap.id_avistamiento = 8
    UNION ALL
    SELECT e.fecha, 'reputacion', e.motivo || ' ' || TO_CHAR(e.puntos, 'S990'), o.alias
    FROM evento_reputacion e JOIN observador o ON o.id_observador = e.id_observador
    WHERE e.id_avistamiento = 8
)
ORDER BY fecha, evento;


-- ============================================================
-- Q08 | CROSS JOIN + funcion en SQL
-- Apelaciones pendientes: dias que llevan, quien rechazo y QUE
-- investigadores pueden resolverlas (todos los cruces posibles
-- filtrados por la regla de negocio).
-- ============================================================
SELECT ap.id_apelacion,
       ap.id_avistamiento,
       autor.alias                                        AS autor,
       rech.alias                                         AS rechazado_por,
       ROUND(CAST(SYSTIMESTAMP AS DATE) - CAST(ap.fecha_apelacion AS DATE), 1) AS dias_en_espera,
       LISTAGG(cand.alias, ', ') WITHIN GROUP (ORDER BY cand.alias) AS pueden_resolver
FROM apelacion ap
INNER JOIN avistamiento a     ON a.id_avistamiento = ap.id_avistamiento
INNER JOIN observador   autor ON autor.id_observador = a.id_observador
LEFT JOIN (SELECT id_avistamiento, id_observador_responsable,
                  ROW_NUMBER() OVER (PARTITION BY id_avistamiento ORDER BY fecha_hora DESC, id_auditoria DESC) rn
           FROM auditoria_avistamiento WHERE estado_nuevo = 'rechazado') ult
       ON ult.id_avistamiento = a.id_avistamiento AND ult.rn = 1
LEFT JOIN observador rech ON rech.id_observador = ult.id_observador_responsable
CROSS JOIN investigador i
INNER JOIN observador cand ON cand.id_observador = i.id_observador
WHERE ap.estado = 'pendiente'
  AND i.id_observador NOT IN (a.id_observador, NVL(ult.id_observador_responsable, -1))
  AND pkg_func.puede_revisar(i.id_observador, pkg_bd2.departamento_de(a.ubicacion), 1,
                             ult.id_observador_responsable) = 1
GROUP BY ap.id_apelacion, ap.id_avistamiento, autor.alias, rech.alias, ap.fecha_apelacion;


-- ============================================================
-- Q09 | INNER JOIN + CASE sobre fechas
-- Solicitudes de ubicacion: estado y si el acceso sigue vigente.
-- ============================================================
SELECT s.id_solicitud,
       sol.alias               AS solicitante,
       e.nombre_comun          AS especie,
       e.estado_conservacion   AS uicn,
       d.nombre                AS departamento,
       s.estado,
       apr.alias               AS resuelto_por,
       s.vigente_hasta,
       CASE WHEN s.estado <> 'aprobada'              THEN NULL
            WHEN s.vigente_hasta >= TRUNC(SYSDATE)   THEN 'VIGENTE'
            ELSE 'VENCIDA' END AS acceso
FROM solicitud_ubicacion s
INNER JOIN observador   sol ON sol.id_observador   = s.id_solicitante
INNER JOIN especie      e   ON e.id_taxon          = s.id_taxon
INNER JOIN departamento d   ON d.id_departamento   = s.id_departamento
LEFT JOIN  observador   apr ON apr.id_observador   = s.id_aprobador
ORDER BY s.fecha_solicitud;


-- ============================================================
-- Q10 | FULL OUTER JOIN
-- Especies sensibles (CR/EN) por departamento: donde hay registros
-- frente a donde hay interes de investigacion (solicitudes).
-- ============================================================
SELECT e.nombre_comun,
       d.nombre                           AS departamento,
       NVL(reg.avistamientos, 0)          AS avistamientos,
       NVL(sol.solicitudes, 0)            AS solicitudes,
       CASE WHEN reg.id_taxon IS NULL THEN 'interes sin registros'
            WHEN sol.id_taxon IS NULL THEN 'registros sin solicitudes' END AS diagnostico
FROM (SELECT NVL(a.id_taxon_validado, a.id_taxon_propuesto) AS id_taxon,
             pkg_bd2.departamento_de(a.ubicacion)           AS id_departamento,
             COUNT(*)                                       AS avistamientos
      FROM avistamiento a
      JOIN especie es ON es.id_taxon = NVL(a.id_taxon_validado, a.id_taxon_propuesto)
      WHERE es.estado_conservacion IN ('CR', 'EN')
      GROUP BY NVL(a.id_taxon_validado, a.id_taxon_propuesto), pkg_bd2.departamento_de(a.ubicacion)) reg
FULL OUTER JOIN
     (SELECT id_taxon, id_departamento, COUNT(*) AS solicitudes
      FROM solicitud_ubicacion GROUP BY id_taxon, id_departamento) sol
  ON sol.id_taxon = reg.id_taxon AND sol.id_departamento = reg.id_departamento
JOIN especie      e ON e.id_taxon        = NVL(reg.id_taxon, sol.id_taxon)
JOIN departamento d ON d.id_departamento = NVL(reg.id_departamento, sol.id_departamento)
ORDER BY e.nombre_comun, d.nombre;


-- ============================================================
-- Q11 | La VISTA segun quien la consulta
-- Mismos avistamientos de especies CR/EN vistos por 4 usuarios:
--   nadie (publico) -> difuminada
--   nadia_flora     -> exacta en Loreto (solicitud aprobada)
--   piero_bio       -> difuminada (su solicitud vencio)
--   angelo_field    -> exacta en Loreto (investigador)
-- ============================================================
EXEC DBMS_SESSION.SET_IDENTIFIER(NULL);
SELECT '(publico)' AS visor, id_avistamiento, taxon, departamento, longitud, latitud, precision_ubicacion, motivo_acceso
FROM v_avistamiento_publico WHERE estado_conservacion IN ('CR', 'EN') ORDER BY id_avistamiento;

EXEC DBMS_SESSION.SET_IDENTIFIER('13');
SELECT 'nadia_flora' AS visor, id_avistamiento, taxon, departamento, longitud, latitud, precision_ubicacion, motivo_acceso
FROM v_avistamiento_publico WHERE estado_conservacion IN ('CR', 'EN') ORDER BY id_avistamiento;

EXEC DBMS_SESSION.SET_IDENTIFIER('1');
SELECT 'piero_bio' AS visor, id_avistamiento, taxon, departamento, longitud, latitud, precision_ubicacion, motivo_acceso
FROM v_avistamiento_publico WHERE estado_conservacion IN ('CR', 'EN') ORDER BY id_avistamiento;

EXEC DBMS_SESSION.SET_IDENTIFIER('5');
SELECT 'angelo_field' AS visor, id_avistamiento, taxon, departamento, longitud, latitud, precision_ubicacion, motivo_acceso
FROM v_avistamiento_publico WHERE estado_conservacion IN ('CR', 'EN') ORDER BY id_avistamiento;

EXEC DBMS_SESSION.SET_IDENTIFIER(NULL);
