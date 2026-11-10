-- ============================================================
-- PROYECTO BD2 - Ciencia ciudadana de biodiversidad
-- Oracle Database 26ai Free
-- Script de carga de datos de prueba
-- Compatible con creacion_modelo_bd2_oracle.sql
-- ============================================================

-- IMPORTANTE:
-- Ejecutar este script DESPUES del script de creacion del modelo.
-- Los IDs son explicitos para que el conjunto sea reproducible.
-- Geometrias en SRID 4326 (WGS84), orden X=longitud, Y=latitud.

-- ============================================================
-- 1. DEPARTAMENTO
-- Poligonos simplificados de prueba, no limites administrativos oficiales.
-- ============================================================
INSERT INTO departamento VALUES (1, 'Lima', MDSYS.SDO_GEOMETRY(2003,4326,NULL,MDSYS.SDO_ELEM_INFO_ARRAY(1,1003,1),MDSYS.SDO_ORDINATE_ARRAY(-77.20,-12.35,-76.70,-12.35,-76.70,-11.70,-77.20,-11.70,-77.20,-12.35)));
INSERT INTO departamento VALUES (2, 'Cusco', MDSYS.SDO_GEOMETRY(2003,4326,NULL,MDSYS.SDO_ELEM_INFO_ARRAY(1,1003,1),MDSYS.SDO_ORDINATE_ARRAY(-72.30,-14.20,-70.20,-14.20,-70.20,-12.80,-72.30,-12.80,-72.30,-14.20)));
INSERT INTO departamento VALUES (3, 'Loreto', MDSYS.SDO_GEOMETRY(2003,4326,NULL,MDSYS.SDO_ELEM_INFO_ARRAY(1,1003,1),MDSYS.SDO_ORDINATE_ARRAY(-77.00,-8.50,-69.90,-8.50,-69.90,-0.10,-77.00,-0.10,-77.00,-8.50)));
INSERT INTO departamento VALUES (4, 'Arequipa', MDSYS.SDO_GEOMETRY(2003,4326,NULL,MDSYS.SDO_ELEM_INFO_ARRAY(1,1003,1),MDSYS.SDO_ORDINATE_ARRAY(-75.20,-17.30,-70.80,-17.30,-70.80,-14.60,-75.20,-14.60,-75.20,-17.30)));
INSERT INTO departamento VALUES (5, 'Puno', MDSYS.SDO_GEOMETRY(2003,4326,NULL,MDSYS.SDO_ELEM_INFO_ARRAY(1,1003,1),MDSYS.SDO_ORDINATE_ARRAY(-71.20,-17.50,-68.80,-17.50,-68.80,-13.80,-71.20,-13.80,-71.20,-17.50)));

-- ============================================================
-- 2. TAXON
-- Jerarquias completas para especies usadas en el dataset.
-- ============================================================
-- Reino
INSERT INTO taxon VALUES (1, 'Animalia', 'reino', NULL);
-- Filos
INSERT INTO taxon VALUES (2, 'Chordata', 'filo', 1);
INSERT INTO taxon VALUES (3, 'Arthropoda', 'filo', 1);
-- Clases
INSERT INTO taxon VALUES (10, 'Aves', 'clase', 2);
INSERT INTO taxon VALUES (11, 'Mammalia', 'clase', 2);
INSERT INTO taxon VALUES (12, 'Insecta', 'clase', 3);
-- Ordenes
INSERT INTO taxon VALUES (20, 'Cathartiformes', 'orden', 10);
INSERT INTO taxon VALUES (21, 'Passeriformes', 'orden', 10);
INSERT INTO taxon VALUES (22, 'Carnivora', 'orden', 11);
INSERT INTO taxon VALUES (23, 'Artiodactyla', 'orden', 11);
INSERT INTO taxon VALUES (24, 'Lepidoptera', 'orden', 12);
-- Familias
INSERT INTO taxon VALUES (30, 'Cathartidae', 'familia', 20);
INSERT INTO taxon VALUES (31, 'Troglodytidae', 'familia', 21);
INSERT INTO taxon VALUES (32, 'Ursidae', 'familia', 22);
INSERT INTO taxon VALUES (33, 'Camelidae', 'familia', 23);
INSERT INTO taxon VALUES (34, 'Nymphalidae', 'familia', 24);
-- Generos
INSERT INTO taxon VALUES (40, 'Vultur', 'genero', 30);
INSERT INTO taxon VALUES (41, 'Troglodytes', 'genero', 31);
INSERT INTO taxon VALUES (42, 'Tremarctos', 'genero', 32);
INSERT INTO taxon VALUES (43, 'Vicugna', 'genero', 33);
INSERT INTO taxon VALUES (44, 'Danaus', 'genero', 34);
-- Especies
INSERT INTO taxon VALUES (100, 'Vultur gryphus', 'especie', 40);
INSERT INTO taxon VALUES (101, 'Troglodytes aedon', 'especie', 41);
INSERT INTO taxon VALUES (102, 'Tremarctos ornatus', 'especie', 42);
INSERT INTO taxon VALUES (103, 'Vicugna vicugna', 'especie', 43);
INSERT INTO taxon VALUES (104, 'Danaus plexippus', 'especie', 44);

-- ============================================================
-- 3. OBSERVADOR
-- ============================================================
INSERT INTO observador VALUES (1, 'piero_bio', DATE '2026-01-15', 125.50);
INSERT INTO observador VALUES (2, 'andrea_natura', DATE '2026-02-02', 98.00);
INSERT INTO observador VALUES (3, 'diego_aves', DATE '2026-02-18', 210.75);
INSERT INTO observador VALUES (4, 'esther_ecologia', DATE '2026-03-01', 180.00);
INSERT INTO observador VALUES (5, 'angelo_field', DATE '2026-03-14', 145.25);
INSERT INTO observador VALUES (6, 'lucia_wild', DATE '2026-04-05', 80.00);
INSERT INTO observador VALUES (7, 'marco_peru', DATE '2026-04-22', 64.50);
INSERT INTO observador VALUES (8, 'sofia_birding', DATE '2026-05-11', 155.00);
INSERT INTO observador VALUES (9, 'renzo_nature', DATE '2026-05-30', 45.00);
INSERT INTO observador VALUES (10, 'valeria_bio', DATE '2026-06-09', 132.00);

-- ============================================================
-- 4. CAMPANIA
-- ============================================================
INSERT INTO campania VALUES (1, 'Bioblitz Lima 2026', DATE '2026-06-01', DATE '2026-06-30');
INSERT INTO campania VALUES (2, 'Monitoreo Andes 2026', DATE '2026-07-01', DATE '2026-08-31');
INSERT INTO campania VALUES (3, 'Biodiversidad Amazonica 2026', DATE '2026-09-01', DATE '2026-10-31');

-- ============================================================
-- 5. ESPECIE
-- ============================================================
INSERT INTO especie VALUES (100, 'Condor andino', 'VU', 0, 0);
INSERT INTO especie VALUES (101, 'Cucarachero comun', 'LC', 0, 0);
INSERT INTO especie VALUES (102, 'Oso de anteojos', 'VU', 0, 0);
INSERT INTO especie VALUES (103, 'Vicuna', 'LC', 0, 0);
INSERT INTO especie VALUES (104, 'Mariposa monarca', 'LC', 0, 1);

-- ============================================================
-- 6. INVESTIGADOR
-- ============================================================
INSERT INTO investigador VALUES (3, 1); -- Lima
INSERT INTO investigador VALUES (4, 2); -- Cusco
INSERT INTO investigador VALUES (5, 3); -- Loreto

-- ============================================================
-- 7. PRESENCIA_ESPERADA
-- Cada especie posee al menos una condicion de presencia.
-- ============================================================
INSERT INTO presencia_esperada VALUES (1, 100, 2, 1, 12);
INSERT INTO presencia_esperada VALUES (2, 100, 4, 1, 12);
INSERT INTO presencia_esperada VALUES (3, 101, 1, 1, 12);
INSERT INTO presencia_esperada VALUES (4, 101, 2, 1, 12);
INSERT INTO presencia_esperada VALUES (5, 102, 2, 1, 12);
INSERT INTO presencia_esperada VALUES (6, 102, 3, 1, 12);
INSERT INTO presencia_esperada VALUES (7, 103, 4, 1, 12);
INSERT INTO presencia_esperada VALUES (8, 103, 5, 1, 12);
INSERT INTO presencia_esperada VALUES (9, 104, 1, 5, 9);

-- ============================================================
-- 8. AREA_PROTEGIDA
-- Poligonos simplificados para pruebas espaciales.
-- ============================================================
INSERT INTO area_protegida VALUES (1, 'Reserva de prueba Lima', 'reserva', MDSYS.SDO_GEOMETRY(2003,4326,NULL,MDSYS.SDO_ELEM_INFO_ARRAY(1,1003,1),MDSYS.SDO_ORDINATE_ARRAY(-77.10,-12.15,-76.95,-12.15,-76.95,-12.00,-77.10,-12.00,-77.10,-12.15)));
INSERT INTO area_protegida VALUES (2, 'Santuario de prueba Cusco', 'santuario', MDSYS.SDO_GEOMETRY(2003,4326,NULL,MDSYS.SDO_ELEM_INFO_ARRAY(1,1003,1),MDSYS.SDO_ORDINATE_ARRAY(-72.00,-13.70,-71.80,-13.70,-71.80,-13.45,-72.00,-13.45,-72.00,-13.70)));
INSERT INTO area_protegida VALUES (3, 'Reserva de prueba Loreto', 'reserva', MDSYS.SDO_GEOMETRY(2003,4326,NULL,MDSYS.SDO_ELEM_INFO_ARRAY(1,1003,1),MDSYS.SDO_ORDINATE_ARRAY(-73.40,-3.90,-73.10,-3.90,-73.10,-3.60,-73.40,-3.60,-73.40,-3.90)));

-- ============================================================
-- 9. CELDA_MUESTREO
-- ============================================================
INSERT INTO celda_muestreo VALUES (1, MDSYS.SDO_GEOMETRY(2003,4326,NULL,MDSYS.SDO_ELEM_INFO_ARRAY(1,1003,1),MDSYS.SDO_ORDINATE_ARRAY(-77.15,-12.20,-77.00,-12.20,-77.00,-12.05,-77.15,-12.05,-77.15,-12.20)));
INSERT INTO celda_muestreo VALUES (2, MDSYS.SDO_GEOMETRY(2003,4326,NULL,MDSYS.SDO_ELEM_INFO_ARRAY(1,1003,1),MDSYS.SDO_ORDINATE_ARRAY(-72.05,-13.70,-71.85,-13.70,-71.85,-13.50,-72.05,-13.50,-72.05,-13.70)));
INSERT INTO celda_muestreo VALUES (3, MDSYS.SDO_GEOMETRY(2003,4326,NULL,MDSYS.SDO_ELEM_INFO_ARRAY(1,1003,1),MDSYS.SDO_ORDINATE_ARRAY(-73.35,-3.85,-73.15,-3.85,-73.15,-3.65,-73.35,-3.65,-73.35,-3.85)));
INSERT INTO celda_muestreo VALUES (4, MDSYS.SDO_GEOMETRY(2003,4326,NULL,MDSYS.SDO_ELEM_INFO_ARRAY(1,1003,1),MDSYS.SDO_ORDINATE_ARRAY(-71.65,-16.50,-71.45,-16.50,-71.45,-16.30,-71.65,-16.30,-71.65,-16.50)));

-- ============================================================
-- 10. AVISTAMIENTO
-- Casos: pendientes, verificados, dudoso, rechazado,
-- validacion por consenso/investigador y candidatos duplicados.
-- Punto: SDO_POINT_TYPE(longitud, latitud, NULL)
-- ============================================================
INSERT INTO avistamiento VALUES (1,1,101,NULL,1,MDSYS.SDO_GEOMETRY(2001,4326,MDSYS.SDO_POINT_TYPE(-77.0428,-12.0464,NULL),NULL,NULL),TIMESTAMP '2026-06-10 08:15:00',2,'Observados en zona arbolada','pendiente',NULL);
INSERT INTO avistamiento VALUES (2,2,101,101,1,MDSYS.SDO_GEOMETRY(2001,4326,MDSYS.SDO_POINT_TYPE(-77.0430,-12.0462,NULL),NULL,NULL),TIMESTAMP '2026-06-10 08:32:00',2,'Registro cercano al avistamiento 1','verificado','consenso');
INSERT INTO avistamiento VALUES (3,6,100,100,2,MDSYS.SDO_GEOMETRY(2001,4326,MDSYS.SDO_POINT_TYPE(-71.9675,-13.5319,NULL),NULL,NULL),TIMESTAMP '2026-07-12 10:20:00',1,'Condor observado en vuelo','verificado','investigador');
INSERT INTO avistamiento VALUES (4,7,102,102,2,MDSYS.SDO_GEOMETRY(2001,4326,MDSYS.SDO_POINT_TYPE(-71.9500,-13.5500,NULL),NULL,NULL),TIMESTAMP '2026-07-15 06:45:00',1,'Individuo observado a distancia','verificado','investigador');
INSERT INTO avistamiento VALUES (5,8,103,NULL,2,MDSYS.SDO_GEOMETRY(2001,4326,MDSYS.SDO_POINT_TYPE(-71.5400,-16.4000,NULL),NULL,NULL),TIMESTAMP '2026-08-03 11:10:00',6,'Grupo de vicunas','pendiente',NULL);
INSERT INTO avistamiento VALUES (6,9,104,NULL,NULL,MDSYS.SDO_GEOMETRY(2001,4326,MDSYS.SDO_POINT_TYPE(-77.0300,-12.0800,NULL),NULL,NULL),TIMESTAMP '2026-10-02 14:05:00',1,'Mariposa fotografiada fuera del periodo esperado','dudoso',NULL);
INSERT INTO avistamiento VALUES (7,10,101,101,NULL,MDSYS.SDO_GEOMETRY(2001,4326,MDSYS.SDO_POINT_TYPE(-73.2500,-3.7500,NULL),NULL,NULL),TIMESTAMP '2026-09-05 07:30:00',3,'Ave comun observada durante viaje','verificado','consenso');
INSERT INTO avistamiento VALUES (8,1,102,NULL,NULL,MDSYS.SDO_GEOMETRY(2001,4326,MDSYS.SDO_POINT_TYPE(-77.0600,-12.1000,NULL),NULL,NULL),TIMESTAMP '2026-09-12 17:20:00',1,'Posible oso; ubicacion atipica','dudoso',NULL);
INSERT INTO avistamiento VALUES (9,2,103,103,NULL,MDSYS.SDO_GEOMETRY(2001,4326,MDSYS.SDO_POINT_TYPE(-71.5500,-16.4100,NULL),NULL,NULL),TIMESTAMP '2026-09-18 09:00:00',4,'Vicunas en campo abierto','verificado','investigador');
INSERT INTO avistamiento VALUES (10,6,100,NULL,NULL,MDSYS.SDO_GEOMETRY(2001,4326,MDSYS.SDO_POINT_TYPE(-73.2000,-3.7600,NULL),NULL,NULL),TIMESTAMP '2026-09-20 12:40:00',1,'Registro no concluyente de condor en selva','rechazado',NULL);
INSERT INTO avistamiento VALUES (11,7,101,NULL,NULL,MDSYS.SDO_GEOMETRY(2001,4326,MDSYS.SDO_POINT_TYPE(-77.0800,-12.1200,NULL),NULL,NULL),TIMESTAMP '2026-10-01 06:55:00',1,'Canto y fotografia','pendiente',NULL);
INSERT INTO avistamiento VALUES (12,8,100,100,NULL,MDSYS.SDO_GEOMETRY(2001,4326,MDSYS.SDO_POINT_TYPE(-71.9000,-13.6000,NULL),NULL,NULL),TIMESTAMP '2026-10-03 15:15:00',1,'Condor confirmado por especialista','verificado','investigador');
INSERT INTO avistamiento VALUES (13,9,104,104,NULL,MDSYS.SDO_GEOMETRY(2001,4326,MDSYS.SDO_POINT_TYPE(-77.0500,-12.0900,NULL),NULL,NULL),TIMESTAMP '2026-06-22 13:25:00',2,'Dos ejemplares en jardin','verificado','consenso');
INSERT INTO avistamiento VALUES (14,10,102,NULL,3,MDSYS.SDO_GEOMETRY(2001,4326,MDSYS.SDO_POINT_TYPE(-73.2700,-3.7800,NULL),NULL,NULL),TIMESTAMP '2026-09-25 05:50:00',1,'Huellas y observacion parcial','pendiente',NULL);
INSERT INTO avistamiento VALUES (15,1,101,NULL,NULL,MDSYS.SDO_GEOMETRY(2001,4326,MDSYS.SDO_POINT_TYPE(-77.0803,-12.1202,NULL),NULL,NULL),TIMESTAMP '2026-10-01 07:10:00',1,'Posible mismo individuo del registro cercano','pendiente',NULL);

-- ============================================================
-- 11. EVIDENCIA
-- Al menos una evidencia por cada avistamiento.
-- ============================================================
INSERT INTO evidencia VALUES (1,1,'foto','/evidencias/av01_foto01.jpg','HASH_AV01_F01',TIMESTAMP '2026-06-10 08:20:00');
INSERT INTO evidencia VALUES (2,2,'foto','/evidencias/av02_foto01.jpg','HASH_AV02_F01',TIMESTAMP '2026-06-10 08:35:00');
INSERT INTO evidencia VALUES (3,3,'foto','/evidencias/av03_foto01.jpg','HASH_AV03_F01',TIMESTAMP '2026-07-12 10:25:00');
INSERT INTO evidencia VALUES (4,4,'foto','/evidencias/av04_foto01.jpg','HASH_AV04_F01',TIMESTAMP '2026-07-15 06:50:00');
INSERT INTO evidencia VALUES (5,5,'foto','/evidencias/av05_foto01.jpg','HASH_AV05_F01',TIMESTAMP '2026-08-03 11:15:00');
INSERT INTO evidencia VALUES (6,6,'foto','/evidencias/av06_foto01.jpg','HASH_AV06_F01',TIMESTAMP '2026-10-02 14:10:00');
INSERT INTO evidencia VALUES (7,7,'audio','/evidencias/av07_audio01.mp3','HASH_AV07_A01',TIMESTAMP '2026-09-05 07:35:00');
INSERT INTO evidencia VALUES (8,8,'foto','/evidencias/av08_foto01.jpg','HASH_AV08_F01',TIMESTAMP '2026-09-12 17:25:00');
INSERT INTO evidencia VALUES (9,9,'foto','/evidencias/av09_foto01.jpg','HASH_AV09_F01',TIMESTAMP '2026-09-18 09:05:00');
INSERT INTO evidencia VALUES (10,10,'foto','/evidencias/av10_foto01.jpg','HASH_AV10_F01',TIMESTAMP '2026-09-20 12:45:00');
INSERT INTO evidencia VALUES (11,11,'audio','/evidencias/av11_audio01.mp3','HASH_AV11_A01',TIMESTAMP '2026-10-01 07:00:00');
INSERT INTO evidencia VALUES (12,12,'foto','/evidencias/av12_foto01.jpg','HASH_AV12_F01',TIMESTAMP '2026-10-03 15:20:00');
INSERT INTO evidencia VALUES (13,13,'foto','/evidencias/av13_foto01.jpg','HASH_AV13_F01',TIMESTAMP '2026-06-22 13:30:00');
INSERT INTO evidencia VALUES (14,14,'foto','/evidencias/av14_foto01.jpg','HASH_AV14_F01',TIMESTAMP '2026-09-25 05:55:00');
INSERT INTO evidencia VALUES (15,15,'foto','/evidencias/av15_foto01.jpg','HASH_AV15_F01',TIMESTAMP '2026-10-01 07:15:00');
INSERT INTO evidencia VALUES (16,3,'audio','/evidencias/av03_audio01.mp3','HASH_AV03_A01',TIMESTAMP '2026-07-12 10:26:00');

-- ============================================================
-- 12. IDENTIFICACION
-- Ningun autor identifica su propio avistamiento.
-- Se respeta UNIQUE(id_avistamiento,id_observador).
-- ============================================================
INSERT INTO identificacion VALUES (1,2,1,101,TIMESTAMP '2026-06-10 09:00:00');
INSERT INTO identificacion VALUES (2,2,8,101,TIMESTAMP '2026-06-10 09:10:00');
INSERT INTO identificacion VALUES (3,3,4,100,TIMESTAMP '2026-07-12 11:00:00');
INSERT INTO identificacion VALUES (4,4,5,102,TIMESTAMP '2026-07-15 08:00:00');
INSERT INTO identificacion VALUES (5,6,2,104,TIMESTAMP '2026-10-02 15:00:00');
INSERT INTO identificacion VALUES (6,7,1,101,TIMESTAMP '2026-09-05 08:10:00');
INSERT INTO identificacion VALUES (7,7,3,101,TIMESTAMP '2026-09-05 08:20:00');
INSERT INTO identificacion VALUES (8,8,4,102,TIMESTAMP '2026-09-12 18:00:00');
INSERT INTO identificacion VALUES (9,9,5,103,TIMESTAMP '2026-09-18 10:00:00');
INSERT INTO identificacion VALUES (10,11,2,101,TIMESTAMP '2026-10-01 08:00:00');
INSERT INTO identificacion VALUES (11,12,4,100,TIMESTAMP '2026-10-03 16:00:00');
INSERT INTO identificacion VALUES (12,13,2,104,TIMESTAMP '2026-06-22 14:00:00');
INSERT INTO identificacion VALUES (13,13,3,104,TIMESTAMP '2026-06-22 14:10:00');
INSERT INTO identificacion VALUES (14,14,5,102,TIMESTAMP '2026-09-25 07:00:00');
INSERT INTO identificacion VALUES (15,15,8,101,TIMESTAMP '2026-10-01 08:10:00');

-- ============================================================
-- 13. ALERTA
-- Casos demostrativos de los tres tipos permitidos.
-- ============================================================
INSERT INTO alerta VALUES (1,3,4,'especie_amenazada',TIMESTAMP '2026-07-12 10:30:00','resuelta');
INSERT INTO alerta VALUES (2,4,4,'especie_amenazada',TIMESTAMP '2026-07-15 06:55:00','resuelta');
INSERT INTO alerta VALUES (3,6,3,'fuera_temporada',TIMESTAMP '2026-10-02 14:15:00','asignada');
INSERT INTO alerta VALUES (4,8,3,'fuera_rango_geografico',TIMESTAMP '2026-09-12 17:30:00','asignada');
INSERT INTO alerta VALUES (5,8,NULL,'especie_amenazada',TIMESTAMP '2026-09-12 17:31:00','pendiente');
INSERT INTO alerta VALUES (6,10,5,'fuera_rango_geografico',TIMESTAMP '2026-09-20 12:50:00','descartada');
INSERT INTO alerta VALUES (7,10,NULL,'especie_amenazada',TIMESTAMP '2026-09-20 12:51:00','pendiente');
INSERT INTO alerta VALUES (8,12,4,'especie_amenazada',TIMESTAMP '2026-10-03 15:25:00','resuelta');
INSERT INTO alerta VALUES (9,14,5,'especie_amenazada',TIMESTAMP '2026-09-25 06:00:00','asignada');

-- ============================================================
-- 14. DUPLICADO_CANDIDATO
-- Parejas almacenadas en orden A < B.
-- ============================================================
INSERT INTO duplicado_candidato VALUES (1,2,31.00,17,'pendiente');
INSERT INTO duplicado_candidato VALUES (11,15,40.00,15,'pendiente');

-- ============================================================
-- 15. AUDITORIA_AVISTAMIENTO
-- Historial inicial y cambios de estado representativos.
-- ============================================================
INSERT INTO auditoria_avistamiento VALUES (1,1,1,NULL,'pendiente','observador',TIMESTAMP '2026-06-10 08:15:00');
INSERT INTO auditoria_avistamiento VALUES (2,2,2,NULL,'pendiente','observador',TIMESTAMP '2026-06-10 08:32:00');
INSERT INTO auditoria_avistamiento VALUES (3,2,NULL,'pendiente','verificado','sistema',TIMESTAMP '2026-06-10 10:00:00');
INSERT INTO auditoria_avistamiento VALUES (4,3,6,NULL,'pendiente','observador',TIMESTAMP '2026-07-12 10:20:00');
INSERT INTO auditoria_avistamiento VALUES (5,3,4,'pendiente','verificado','investigador',TIMESTAMP '2026-07-12 12:00:00');
INSERT INTO auditoria_avistamiento VALUES (6,4,7,NULL,'pendiente','observador',TIMESTAMP '2026-07-15 06:45:00');
INSERT INTO auditoria_avistamiento VALUES (7,4,4,'pendiente','verificado','investigador',TIMESTAMP '2026-07-15 09:00:00');
INSERT INTO auditoria_avistamiento VALUES (8,5,8,NULL,'pendiente','observador',TIMESTAMP '2026-08-03 11:10:00');
INSERT INTO auditoria_avistamiento VALUES (9,6,9,NULL,'pendiente','observador',TIMESTAMP '2026-10-02 14:05:00');
INSERT INTO auditoria_avistamiento VALUES (10,6,NULL,'pendiente','dudoso','sistema',TIMESTAMP '2026-10-02 14:16:00');
INSERT INTO auditoria_avistamiento VALUES (11,7,10,NULL,'pendiente','observador',TIMESTAMP '2026-09-05 07:30:00');
INSERT INTO auditoria_avistamiento VALUES (12,7,NULL,'pendiente','verificado','sistema',TIMESTAMP '2026-09-05 09:00:00');
INSERT INTO auditoria_avistamiento VALUES (13,8,1,NULL,'pendiente','observador',TIMESTAMP '2026-09-12 17:20:00');
INSERT INTO auditoria_avistamiento VALUES (14,8,NULL,'pendiente','dudoso','sistema',TIMESTAMP '2026-09-12 17:31:00');
INSERT INTO auditoria_avistamiento VALUES (15,9,2,NULL,'pendiente','observador',TIMESTAMP '2026-09-18 09:00:00');
INSERT INTO auditoria_avistamiento VALUES (16,9,5,'pendiente','verificado','investigador',TIMESTAMP '2026-09-18 11:00:00');
INSERT INTO auditoria_avistamiento VALUES (17,10,6,NULL,'pendiente','observador',TIMESTAMP '2026-09-20 12:40:00');
INSERT INTO auditoria_avistamiento VALUES (18,10,5,'pendiente','rechazado','investigador',TIMESTAMP '2026-09-20 14:00:00');
INSERT INTO auditoria_avistamiento VALUES (19,11,7,NULL,'pendiente','observador',TIMESTAMP '2026-10-01 06:55:00');
INSERT INTO auditoria_avistamiento VALUES (20,12,8,NULL,'pendiente','observador',TIMESTAMP '2026-10-03 15:15:00');
INSERT INTO auditoria_avistamiento VALUES (21,12,4,'pendiente','verificado','investigador',TIMESTAMP '2026-10-03 17:00:00');
INSERT INTO auditoria_avistamiento VALUES (22,13,9,NULL,'pendiente','observador',TIMESTAMP '2026-06-22 13:25:00');
INSERT INTO auditoria_avistamiento VALUES (23,13,NULL,'pendiente','verificado','sistema',TIMESTAMP '2026-06-22 15:00:00');
INSERT INTO auditoria_avistamiento VALUES (24,14,10,NULL,'pendiente','observador',TIMESTAMP '2026-09-25 05:50:00');
INSERT INTO auditoria_avistamiento VALUES (25,15,1,NULL,'pendiente','observador',TIMESTAMP '2026-10-01 07:10:00');

COMMIT;

-- ============================================================
-- CONSULTAS DE VERIFICACION DE CARGA
-- ============================================================
SELECT 'DEPARTAMENTO' AS tabla, COUNT(*) AS registros FROM departamento
UNION ALL SELECT 'TAXON', COUNT(*) FROM taxon
UNION ALL SELECT 'OBSERVADOR', COUNT(*) FROM observador
UNION ALL SELECT 'CAMPANIA', COUNT(*) FROM campania
UNION ALL SELECT 'ESPECIE', COUNT(*) FROM especie
UNION ALL SELECT 'INVESTIGADOR', COUNT(*) FROM investigador
UNION ALL SELECT 'PRESENCIA_ESPERADA', COUNT(*) FROM presencia_esperada
UNION ALL SELECT 'AREA_PROTEGIDA', COUNT(*) FROM area_protegida
UNION ALL SELECT 'CELDA_MUESTREO', COUNT(*) FROM celda_muestreo
UNION ALL SELECT 'AVISTAMIENTO', COUNT(*) FROM avistamiento
UNION ALL SELECT 'EVIDENCIA', COUNT(*) FROM evidencia
UNION ALL SELECT 'IDENTIFICACION', COUNT(*) FROM identificacion
UNION ALL SELECT 'ALERTA', COUNT(*) FROM alerta
UNION ALL SELECT 'DUPLICADO_CANDIDATO', COUNT(*) FROM duplicado_candidato
UNION ALL SELECT 'AUDITORIA_AVISTAMIENTO', COUNT(*) FROM auditoria_avistamiento
ORDER BY 1;

-- Resumen de avistamientos
SELECT a.id_avistamiento,
       o.alias AS autor,
       tp.nombre_cientifico AS taxon_propuesto,
       tv.nombre_cientifico AS taxon_validado,
       a.estado,
       a.metodo_validacion,
       a.fecha_hora_avistamiento
FROM avistamiento a
JOIN observador o ON o.id_observador = a.id_observador
JOIN taxon tp ON tp.id_taxon = a.id_taxon_propuesto
LEFT JOIN taxon tv ON tv.id_taxon = a.id_taxon_validado
ORDER BY a.id_avistamiento;

-- Alertas generadas
SELECT al.id_alerta, al.id_avistamiento, al.tipo, al.estado,
       o.alias AS investigador_responsable
FROM alerta al
LEFT JOIN investigador i ON i.id_observador = al.id_investigador
LEFT JOIN observador o ON o.id_observador = i.id_observador
ORDER BY al.id_alerta;

-- Candidatos a duplicado
SELECT * FROM duplicado_candidato ORDER BY id_avistamiento_a, id_avistamiento_b;

-- ============================================================
-- FIN DE CARGA
-- ============================================================
