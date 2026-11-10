-- ============================================================
-- PROYECTO BD2 - CIENCIA CIUDADANA DE BIODIVERSIDAD
-- CONSULTAS PARA EXPOSICION DEL AVANCE
-- Oracle Database 26ai
-- ============================================================

-- ============================================================
-- CONSULTA 1
-- Avistamientos con observador y especie propuesta
-- ============================================================
SELECT
    a.id_avistamiento,
    o.alias AS observador,
    t.nombre_cientifico AS especie_propuesta,
    a.fecha_hora_avistamiento,
    a.numero_individuos,
    a.estado
FROM avistamiento a
JOIN observador o
    ON a.id_observador = o.id_observador
JOIN taxon t
    ON a.id_taxon_propuesto = t.id_taxon
ORDER BY a.id_avistamiento;


-- ============================================================
-- CONSULTA 2
-- Avistamientos verificados y especie finalmente validada
-- ============================================================
SELECT
    a.id_avistamiento,
    o.alias AS observador,
    tp.nombre_cientifico AS especie_propuesta,
    tv.nombre_cientifico AS especie_validada,
    a.metodo_validacion
FROM avistamiento a
JOIN observador o
    ON a.id_observador = o.id_observador
JOIN taxon tp
    ON a.id_taxon_propuesto = tp.id_taxon
JOIN taxon tv
    ON a.id_taxon_validado = tv.id_taxon
WHERE a.estado = 'verificado'
ORDER BY a.id_avistamiento;


-- ============================================================
-- CONSULTA 3
-- Cantidad de avistamientos registrados por especie
-- ============================================================
SELECT
    t.nombre_cientifico AS especie,
    COUNT(*) AS total_avistamientos
FROM avistamiento a
JOIN taxon t
    ON a.id_taxon_propuesto = t.id_taxon
GROUP BY t.nombre_cientifico
ORDER BY total_avistamientos DESC;


-- ============================================================
-- CONSULTA 4
-- Alertas generadas y los investigadores asignados
-- LEFT JOIN permite mostrar alertas aun sin investigador asignado
-- ============================================================
SELECT
    al.id_alerta,
    al.id_avistamiento,
    t.nombre_cientifico AS especie,
    al.tipo AS tipo_alerta,
    al.estado AS estado_alerta,
    o.alias AS investigador
FROM alerta al
JOIN avistamiento a
    ON al.id_avistamiento = a.id_avistamiento
JOIN taxon t
    ON a.id_taxon_propuesto = t.id_taxon
LEFT JOIN investigador i
    ON al.id_investigador = i.id_observador
LEFT JOIN observador o
    ON i.id_observador = o.id_observador
ORDER BY al.id_alerta;


-- ============================================================
-- CONSULTA 5
-- Identificaciones realizadas por la comunidad
-- Se diferencia al autor del avistamiento del observador que identifica
-- ============================================================
SELECT
    i.id_avistamiento,
    autor.alias AS autor_avistamiento,
    identificador.alias AS identificado_por,
    t.nombre_cientifico AS taxon_identificado,
    i.fecha
FROM identificacion i
JOIN avistamiento a
    ON i.id_avistamiento = a.id_avistamiento
JOIN observador autor
    ON a.id_observador = autor.id_observador
JOIN observador identificador
    ON i.id_observador = identificador.id_observador
JOIN taxon t
    ON i.id_taxon_propuesto = t.id_taxon
ORDER BY i.id_avistamiento, i.fecha;


-- ============================================================
-- CONSULTA 6
-- Posibles avistamientos duplicados
-- Muestra la distancia y diferencia temporal entre ambos registros
-- ============================================================
SELECT
    d.id_avistamiento_a,
    d.id_avistamiento_b,
    t.nombre_cientifico AS especie,
    d.distancia_metros,
    d.diferencia_minutos,
    d.estado
FROM duplicado_candidato d
JOIN avistamiento a
    ON d.id_avistamiento_a = a.id_avistamiento
JOIN taxon t
    ON a.id_taxon_propuesto = t.id_taxon
ORDER BY d.id_avistamiento_a;

-- ============================================================
-- FIN DE CONSULTAS
-- ============================================================
