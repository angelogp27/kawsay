-- ============================================================
-- PROYECTO BD2 - Ciencia ciudadana de biodiversidad
-- 03 - POBLADO DE DATOS
-- Ejecutar despues de 01_tablas.sql y 02_logica.sql.
-- ============================================================
-- PARTE A. Parametros del sistema
-- PARTE B. Carga historica base (con triggers desactivados: los
--          registros de auditoria y alertas historicos se cargan tal cual)
-- PARTE C. Credenciales de los investigadores existentes
-- PARTE D. Carga ampliada (la auditoria, alertas, duplicados,
--          consenso y reputacion los generan los triggers)
-- PARTE E. Funcionalidades: postulaciones, reportes, apelaciones
--          y solicitudes de ubicacion
--
-- DBMS_SESSION.SET_IDENTIFIER indica que observador esta operando
-- (equivale al usuario que inicio sesion en la aplicacion).
-- Los codigos SUNEDU / CBP / RENACYT / SERFOR son FICTICIOS.
-- ============================================================
SET SQLBLANKLINES ON


-- ############################################################
-- PARTE A. PARAMETROS DEL SISTEMA
-- ############################################################

INSERT INTO parametro_sistema VALUES ('UMBRAL_CONSENSO',            2,   'Identificaciones coincidentes necesarias para verificar por consenso (RN13)');
INSERT INTO parametro_sistema VALUES ('DUPLICADO_DISTANCIA_M',      100, 'Distancia maxima en metros entre candidatos a duplicado (RN26)');
INSERT INTO parametro_sistema VALUES ('DUPLICADO_MINUTOS',          30,  'Diferencia temporal maxima en minutos entre candidatos a duplicado (RN26)');
INSERT INTO parametro_sistema VALUES ('PUNTOS_VERIFICADO',          10,  'Reputacion que gana el autor cuando su avistamiento es verificado (RN04)');
INSERT INTO parametro_sistema VALUES ('PUNTOS_IDENTIFICACION_OK',   3,   'Reputacion que gana quien identifico correctamente un avistamiento verificado');

-- Saldo inicial: la reputacion cargada en la base queda explicada
-- como un evento, para que SUM(puntos) = observador.reputacion.
INSERT INTO evento_reputacion (id_evento, id_observador, id_avistamiento, motivo, puntos, fecha)
SELECT id_observador, id_observador, NULL, 'saldo_inicial', reputacion, CAST(fecha_registro AS TIMESTAMP)
FROM observador;
INSERT INTO parametro_sistema VALUES ('POSTULACION_MIN_IDENTIF_OK',  3,   'Identificaciones que coinciden con el taxon validado, minimo para postular');
INSERT INTO parametro_sistema VALUES ('POSTULACION_MIN_DIAS',        30,  'Dias minimos de antiguedad en la plataforma para postular');
INSERT INTO parametro_sistema VALUES ('POSTULACION_DIAS_SIN_REPORTE',180, 'Dias sin reportes procedentes en contra exigidos para postular');
INSERT INTO parametro_sistema VALUES ('REPORTES_UMBRAL',             2,   'Reportes pendientes que pasan un avistamiento a dudoso y generan alerta');
INSERT INTO parametro_sistema VALUES ('PUNTOS_PENALIZACION_REPORTE', 15,  'Reputacion que pierde el autor si un reporte en su contra es procedente');
INSERT INTO parametro_sistema VALUES ('PUNTOS_REPORTE_PROCEDENTE',   2,   'Reputacion que gana quien hizo un reporte procedente');
INSERT INTO parametro_sistema VALUES ('APELACION_PLAZO_DIAS',        30,  'Dias para apelar desde el rechazo');
INSERT INTO parametro_sistema VALUES ('UBICACION_VIGENCIA_DIAS',     90,  'Vigencia por defecto del acceso a ubicaciones exactas');
INSERT INTO parametro_sistema VALUES ('UBICACION_DIFUMINADO_GRADOS', 0.1, 'Tamano de la grilla (grados, ~11 km) para difuminar ubicaciones sensibles');
COMMIT;


-- ############################################################
-- PARTE B. CARGA HISTORICA BASE
-- ############################################################

-- Datos historicos: se insertan con sus estados, alertas y auditoria
-- ya definidos, por eso se desactivan los triggers que los generarian.
ALTER TABLE avistamiento   DISABLE ALL TRIGGERS;
ALTER TABLE identificacion DISABLE ALL TRIGGERS;
ALTER TABLE alerta         DISABLE ALL TRIGGERS;

-- ============================================================
-- 1. DEPARTAMENTO
-- Poligonos simplificados de prueba, no limites administrativos oficiales.
-- ============================================================
INSERT INTO departamento VALUES (1, 'Lima', MDSYS.SDO_GEOMETRY(2003,4326,NULL,MDSYS.SDO_ELEM_INFO_ARRAY(1,1003,1),MDSYS.SDO_ORDINATE_ARRAY(-77.20,-12.35,-76.70,-12.35,-76.70,-11.70,-77.20,-11.70,-77.20,-12.35)));
INSERT INTO departamento VALUES (2, 'Cusco', MDSYS.SDO_GEOMETRY(2003,4326,NULL,MDSYS.SDO_ELEM_INFO_ARRAY(1,1003,1),MDSYS.SDO_ORDINATE_ARRAY(-72.30,-14.20,-70.20,-14.20,-70.20,-12.80,-72.30,-12.80,-72.30,-14.20)));
INSERT INTO departamento VALUES (3, 'Loreto', MDSYS.SDO_GEOMETRY(2003,4326,NULL,MDSYS.SDO_ELEM_INFO_ARRAY(1,1003,1),MDSYS.SDO_ORDINATE_ARRAY(-77.00,-8.50,-69.90,-8.50,-69.90,-0.10,-77.00,-0.10,-77.00,-8.50)));
INSERT INTO departamento VALUES (4, 'Arequipa', MDSYS.SDO_GEOMETRY(2003,4326,NULL,MDSYS.SDO_ELEM_INFO_ARRAY(1,1003,1),MDSYS.SDO_ORDINATE_ARRAY(-75.20,-17.30,-70.80,-17.30,-70.80,-14.60,-75.20,-14.60,-75.20,-17.30)));
INSERT INTO departamento VALUES (5, 'Puno', MDSYS.SDO_GEOMETRY(2003,4326,NULL,MDSYS.SDO_ELEM_INFO_ARRAY(1,1003,1),MDSYS.SDO_ORDINATE_ARRAY(-70.19,-17.50,-68.80,-17.50,-68.80,-13.80,-70.19,-13.80,-70.19,-17.50)));

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
-- Lima
INSERT INTO investigador VALUES (3, 1);
-- Cusco
INSERT INTO investigador VALUES (4, 2);
-- Loreto
INSERT INTO investigador VALUES (5, 3);
-- Arequipa
INSERT INTO investigador VALUES (8, 4);

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
INSERT INTO avistamiento (id_avistamiento, id_observador, id_taxon_propuesto, id_taxon_validado, id_campania, ubicacion, fecha_hora_avistamiento, numero_individuos, notas, estado, metodo_validacion) VALUES (1,1,101,NULL,1,MDSYS.SDO_GEOMETRY(2001,4326,MDSYS.SDO_POINT_TYPE(-77.0428,-12.0464,NULL),NULL,NULL),TIMESTAMP '2026-06-10 08:15:00',2,'Observados en zona arbolada','pendiente',NULL);
INSERT INTO avistamiento (id_avistamiento, id_observador, id_taxon_propuesto, id_taxon_validado, id_campania, ubicacion, fecha_hora_avistamiento, numero_individuos, notas, estado, metodo_validacion) VALUES (2,2,101,101,1,MDSYS.SDO_GEOMETRY(2001,4326,MDSYS.SDO_POINT_TYPE(-77.0430,-12.0462,NULL),NULL,NULL),TIMESTAMP '2026-06-10 08:32:00',2,'Registro cercano al avistamiento 1','verificado','consenso');
INSERT INTO avistamiento (id_avistamiento, id_observador, id_taxon_propuesto, id_taxon_validado, id_campania, ubicacion, fecha_hora_avistamiento, numero_individuos, notas, estado, metodo_validacion) VALUES (3,6,100,100,2,MDSYS.SDO_GEOMETRY(2001,4326,MDSYS.SDO_POINT_TYPE(-71.9675,-13.5319,NULL),NULL,NULL),TIMESTAMP '2026-07-12 10:20:00',1,'Condor observado en vuelo','verificado','investigador');
INSERT INTO avistamiento (id_avistamiento, id_observador, id_taxon_propuesto, id_taxon_validado, id_campania, ubicacion, fecha_hora_avistamiento, numero_individuos, notas, estado, metodo_validacion) VALUES (4,7,102,102,2,MDSYS.SDO_GEOMETRY(2001,4326,MDSYS.SDO_POINT_TYPE(-71.9500,-13.5500,NULL),NULL,NULL),TIMESTAMP '2026-07-15 06:45:00',1,'Individuo observado a distancia','verificado','investigador');
INSERT INTO avistamiento (id_avistamiento, id_observador, id_taxon_propuesto, id_taxon_validado, id_campania, ubicacion, fecha_hora_avistamiento, numero_individuos, notas, estado, metodo_validacion) VALUES (5,8,103,NULL,2,MDSYS.SDO_GEOMETRY(2001,4326,MDSYS.SDO_POINT_TYPE(-71.5400,-16.4000,NULL),NULL,NULL),TIMESTAMP '2026-08-03 11:10:00',6,'Grupo de vicunas','pendiente',NULL);
INSERT INTO avistamiento (id_avistamiento, id_observador, id_taxon_propuesto, id_taxon_validado, id_campania, ubicacion, fecha_hora_avistamiento, numero_individuos, notas, estado, metodo_validacion) VALUES (6,9,104,NULL,NULL,MDSYS.SDO_GEOMETRY(2001,4326,MDSYS.SDO_POINT_TYPE(-77.0300,-12.0800,NULL),NULL,NULL),TIMESTAMP '2026-10-02 14:05:00',1,'Mariposa fotografiada fuera del periodo esperado','dudoso',NULL);
INSERT INTO avistamiento (id_avistamiento, id_observador, id_taxon_propuesto, id_taxon_validado, id_campania, ubicacion, fecha_hora_avistamiento, numero_individuos, notas, estado, metodo_validacion) VALUES (7,10,101,101,NULL,MDSYS.SDO_GEOMETRY(2001,4326,MDSYS.SDO_POINT_TYPE(-73.2500,-3.7500,NULL),NULL,NULL),TIMESTAMP '2026-09-05 07:30:00',3,'Ave comun observada durante viaje','verificado','consenso');
INSERT INTO avistamiento (id_avistamiento, id_observador, id_taxon_propuesto, id_taxon_validado, id_campania, ubicacion, fecha_hora_avistamiento, numero_individuos, notas, estado, metodo_validacion) VALUES (8,1,102,NULL,NULL,MDSYS.SDO_GEOMETRY(2001,4326,MDSYS.SDO_POINT_TYPE(-77.0600,-12.1000,NULL),NULL,NULL),TIMESTAMP '2026-09-12 17:20:00',1,'Posible oso; ubicacion atipica','dudoso',NULL);
INSERT INTO avistamiento (id_avistamiento, id_observador, id_taxon_propuesto, id_taxon_validado, id_campania, ubicacion, fecha_hora_avistamiento, numero_individuos, notas, estado, metodo_validacion) VALUES (9,2,103,103,NULL,MDSYS.SDO_GEOMETRY(2001,4326,MDSYS.SDO_POINT_TYPE(-71.5500,-16.4100,NULL),NULL,NULL),TIMESTAMP '2026-09-18 09:00:00',4,'Vicunas en campo abierto','verificado','investigador');
INSERT INTO avistamiento (id_avistamiento, id_observador, id_taxon_propuesto, id_taxon_validado, id_campania, ubicacion, fecha_hora_avistamiento, numero_individuos, notas, estado, metodo_validacion) VALUES (10,6,100,NULL,NULL,MDSYS.SDO_GEOMETRY(2001,4326,MDSYS.SDO_POINT_TYPE(-73.2000,-3.7600,NULL),NULL,NULL),TIMESTAMP '2026-09-20 12:40:00',1,'Registro no concluyente de condor en selva','rechazado',NULL);
INSERT INTO avistamiento (id_avistamiento, id_observador, id_taxon_propuesto, id_taxon_validado, id_campania, ubicacion, fecha_hora_avistamiento, numero_individuos, notas, estado, metodo_validacion) VALUES (11,7,101,NULL,NULL,MDSYS.SDO_GEOMETRY(2001,4326,MDSYS.SDO_POINT_TYPE(-77.0800,-12.1200,NULL),NULL,NULL),TIMESTAMP '2026-10-01 06:55:00',1,'Canto y fotografia','pendiente',NULL);
INSERT INTO avistamiento (id_avistamiento, id_observador, id_taxon_propuesto, id_taxon_validado, id_campania, ubicacion, fecha_hora_avistamiento, numero_individuos, notas, estado, metodo_validacion) VALUES (12,8,100,100,NULL,MDSYS.SDO_GEOMETRY(2001,4326,MDSYS.SDO_POINT_TYPE(-71.9000,-13.6000,NULL),NULL,NULL),TIMESTAMP '2026-10-03 15:15:00',1,'Condor confirmado por especialista','verificado','investigador');
INSERT INTO avistamiento (id_avistamiento, id_observador, id_taxon_propuesto, id_taxon_validado, id_campania, ubicacion, fecha_hora_avistamiento, numero_individuos, notas, estado, metodo_validacion) VALUES (13,9,104,104,NULL,MDSYS.SDO_GEOMETRY(2001,4326,MDSYS.SDO_POINT_TYPE(-77.0500,-12.0900,NULL),NULL,NULL),TIMESTAMP '2026-06-22 13:25:00',2,'Dos ejemplares en jardin','verificado','consenso');
INSERT INTO avistamiento (id_avistamiento, id_observador, id_taxon_propuesto, id_taxon_validado, id_campania, ubicacion, fecha_hora_avistamiento, numero_individuos, notas, estado, metodo_validacion) VALUES (14,10,102,NULL,3,MDSYS.SDO_GEOMETRY(2001,4326,MDSYS.SDO_POINT_TYPE(-73.2700,-3.7800,NULL),NULL,NULL),TIMESTAMP '2026-09-25 05:50:00',1,'Huellas y observacion parcial','pendiente',NULL);
INSERT INTO avistamiento (id_avistamiento, id_observador, id_taxon_propuesto, id_taxon_validado, id_campania, ubicacion, fecha_hora_avistamiento, numero_individuos, notas, estado, metodo_validacion) VALUES (15,1,101,NULL,NULL,MDSYS.SDO_GEOMETRY(2001,4326,MDSYS.SDO_POINT_TYPE(-77.0803,-12.1202,NULL),NULL,NULL),TIMESTAMP '2026-10-01 07:10:00',1,'Posible mismo individuo del registro cercano','pendiente',NULL);

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
INSERT INTO alerta (id_alerta, id_avistamiento, id_investigador, tipo, fecha_generacion, estado, fecha_resolucion) VALUES (1,3,4,'especie_amenazada',TIMESTAMP '2026-07-12 10:30:00','resuelta',TIMESTAMP '2026-07-12 12:30:00');
INSERT INTO alerta (id_alerta, id_avistamiento, id_investigador, tipo, fecha_generacion, estado, fecha_resolucion) VALUES (2,4,4,'especie_amenazada',TIMESTAMP '2026-07-15 06:55:00','resuelta',TIMESTAMP '2026-07-15 08:55:00');
INSERT INTO alerta (id_alerta, id_avistamiento, id_investigador, tipo, fecha_generacion, estado, fecha_resolucion) VALUES (3,6,3,'fuera_temporada',TIMESTAMP '2026-10-02 14:15:00','asignada',NULL);
INSERT INTO alerta (id_alerta, id_avistamiento, id_investigador, tipo, fecha_generacion, estado, fecha_resolucion) VALUES (4,8,3,'fuera_rango_geografico',TIMESTAMP '2026-09-12 17:30:00','asignada',NULL);
INSERT INTO alerta (id_alerta, id_avistamiento, id_investigador, tipo, fecha_generacion, estado, fecha_resolucion) VALUES (5,8,NULL,'especie_amenazada',TIMESTAMP '2026-09-12 17:31:00','pendiente',NULL);
INSERT INTO alerta (id_alerta, id_avistamiento, id_investigador, tipo, fecha_generacion, estado, fecha_resolucion) VALUES (6,10,5,'fuera_rango_geografico',TIMESTAMP '2026-09-20 12:50:00','descartada',TIMESTAMP '2026-09-20 14:50:00');
-- el avistamiento 10 fue rechazado: su alerta no puede seguir pendiente
INSERT INTO alerta (id_alerta, id_avistamiento, id_investigador, tipo, fecha_generacion, estado, fecha_resolucion) VALUES (7,10,5,'especie_amenazada',TIMESTAMP '2026-09-20 12:51:00','descartada',TIMESTAMP '2026-09-20 14:51:00');
INSERT INTO alerta (id_alerta, id_avistamiento, id_investigador, tipo, fecha_generacion, estado, fecha_resolucion) VALUES (8,12,4,'especie_amenazada',TIMESTAMP '2026-10-03 15:25:00','resuelta',TIMESTAMP '2026-10-03 17:25:00');
INSERT INTO alerta (id_alerta, id_avistamiento, id_investigador, tipo, fecha_generacion, estado, fecha_resolucion) VALUES (9,14,5,'especie_amenazada',TIMESTAMP '2026-09-25 06:00:00','asignada',NULL);
-- Troglodytes aedon en Loreto: fuera de su distribucion esperada (RN19)
INSERT INTO alerta (id_alerta, id_avistamiento, id_investigador, tipo, fecha_generacion, estado, fecha_resolucion) VALUES (10,7,5,'fuera_rango_geografico',TIMESTAMP '2026-09-05 07:31:00','resuelta',TIMESTAMP '2026-09-05 09:31:00');

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
INSERT INTO auditoria_avistamiento VALUES (16,9,8,'pendiente','verificado','investigador',TIMESTAMP '2026-09-18 11:00:00');
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

ALTER TABLE avistamiento   ENABLE ALL TRIGGERS;
ALTER TABLE identificacion ENABLE ALL TRIGGERS;
ALTER TABLE alerta         ENABLE ALL TRIGGERS;

-- Saldo inicial: la reputacion cargada en la base queda explicada
-- como un evento, para que SUM(puntos) = observador.reputacion.
INSERT INTO evento_reputacion (id_evento, id_observador, id_avistamiento, motivo, puntos, fecha)
SELECT id_observador, id_observador, NULL, 'saldo_inicial', reputacion, CAST(fecha_registro AS TIMESTAMP)
FROM observador;
COMMIT;


-- ############################################################
-- PARTE C. CREDENCIALES DE LOS INVESTIGADORES EXISTENTES
-- ############################################################

-- ============================================================
-- F1. Credenciales de los investigadores existentes
-- (se verifican entre ellos; nadie verifica las propias)
-- ============================================================
INSERT INTO credencial VALUES (1,  3,  'titulo_profesional',  'UNMSM - Facultad de Ciencias Biologicas', 'SUNEDU-T-PRUEBA-0001', NULL, DATE '2015-03-10', NULL,              'verificada', 4, TIMESTAMP '2026-01-15 10:00:00');
INSERT INTO credencial VALUES (2,  3,  'grado_maestria',      'UNMSM - Posgrado en Zoologia',            'SUNEDU-M-PRUEBA-0002', NULL, DATE '2019-08-20', NULL,              'verificada', 4, TIMESTAMP '2026-01-15 10:05:00');
-- colegiatura POR VENCER
INSERT INTO credencial VALUES (3,  3,  'colegiatura',         'Colegio de Biologos del Peru',            'CBP-PRUEBA-08812',     NULL, DATE '2015-06-01', DATE '2026-11-30', 'verificada', 4, TIMESTAMP '2026-01-15 10:10:00');
INSERT INTO credencial VALUES (4,  3,  'carta_institucional', 'Museo de Historia Natural - UNMSM',       'MHN-PRUEBA-2026-031',  NULL, DATE '2026-01-10', NULL,              'verificada', 4, TIMESTAMP '2026-01-15 10:15:00');

INSERT INTO credencial VALUES (5,  4,  'titulo_profesional',  'UNSAAC - Biologia',                       'SUNEDU-T-PRUEBA-0005', NULL, DATE '2012-11-05', NULL,              'verificada', 3, TIMESTAMP '2026-01-16 09:00:00');
-- colegiatura VENCIDA: esther queda suspendida
INSERT INTO credencial VALUES (6,  4,  'colegiatura',         'Colegio de Biologos del Peru',            'CBP-PRUEBA-10234',     NULL, DATE '2013-02-01', DATE '2026-10-31', 'verificada', 3, TIMESTAMP '2026-01-16 09:05:00');
INSERT INTO credencial VALUES (7,  4,  'renacyt',             'CONCYTEC',                                'RENACYT-PRUEBA-P0045', 5,    DATE '2024-03-01', DATE '2028-03-01', 'verificada', 3, TIMESTAMP '2026-01-16 09:10:00');
INSERT INTO credencial VALUES (8,  4,  'carta_institucional', 'UNSAAC - Herbario Vargas',                'UNSAAC-PRUEBA-2026-07',NULL, DATE '2026-01-05', NULL,              'verificada', 3, TIMESTAMP '2026-01-16 09:15:00');

INSERT INTO credencial VALUES (9,  5,  'titulo_profesional',  'UNAP - Ciencias Biologicas',              'SUNEDU-T-PRUEBA-0009', NULL, DATE '2016-04-18', NULL,              'verificada', 8, TIMESTAMP '2026-01-20 11:00:00');
INSERT INTO credencial VALUES (10, 5,  'colegiatura',         'Colegio de Biologos del Peru',            'CBP-PRUEBA-11870',     NULL, DATE '2016-07-01', DATE '2027-06-30', 'verificada', 8, TIMESTAMP '2026-01-20 11:05:00');
INSERT INTO credencial VALUES (11, 5,  'autorizacion_serfor', 'SERFOR',                                  'AUT-SERFOR-PRUEBA-0457',NULL,DATE '2026-02-01', DATE '2027-01-31', 'verificada', 8, TIMESTAMP '2026-02-05 11:10:00');
INSERT INTO credencial VALUES (12, 5,  'carta_institucional', 'Instituto de Investigaciones de la Amazonia Peruana', 'IIAP-PRUEBA-2026-12', NULL, DATE '2026-01-08', NULL, 'verificada', 8, TIMESTAMP '2026-01-20 11:15:00');

INSERT INTO credencial VALUES (13, 8,  'titulo_profesional',  'UNSA - Biologia',                         'SUNEDU-T-PRUEBA-0013', NULL, DATE '2010-12-01', NULL,              'verificada', 5, TIMESTAMP '2026-01-21 08:00:00');
INSERT INTO credencial VALUES (14, 8,  'grado_doctor',        'UNSA - Doctorado en Ciencias',            'SUNEDU-D-PRUEBA-0014', NULL, DATE '2020-06-15', NULL,              'verificada', 5, TIMESTAMP '2026-01-21 08:05:00');
INSERT INTO credencial VALUES (15, 8,  'colegiatura',         'Colegio de Biologos del Peru',            'CBP-PRUEBA-12503',     NULL, DATE '2011-03-01', DATE '2027-12-31', 'verificada', 5, TIMESTAMP '2026-01-21 08:10:00');
INSERT INTO credencial VALUES (16, 8,  'carta_institucional', 'UNSA - Museo de Historia Natural',        'UNSA-PRUEBA-2026-03',  NULL, DATE '2026-01-12', NULL,              'verificada', 5, TIMESTAMP '2026-01-21 08:15:00');

COMMIT;


-- ############################################################
-- PARTE D. CARGA AMPLIADA
-- ############################################################

-- Estos casos ocurrieron antes de que se exigiera colegiatura vigente
-- para asumir alertas (la de esther_ecologia vencio el 2026-10-31).
ALTER TRIGGER trg_alerta_credencial DISABLE;

-- ------------------------------------------------------------
-- 1. Territorio: Junin + nuevas celdas y areas protegidas
-- ------------------------------------------------------------
INSERT INTO departamento (id_departamento, nombre, poligono) VALUES (6, 'Junin',
  MDSYS.SDO_GEOMETRY(2003,4326,NULL,MDSYS.SDO_ELEM_INFO_ARRAY(1,1003,1),
  MDSYS.SDO_ORDINATE_ARRAY(-76.50,-12.60,-74.00,-12.60,-74.00,-10.60,-76.50,-10.60,-76.50,-12.60)));

INSERT INTO celda_muestreo (id_celda, poligono) VALUES (5, MDSYS.SDO_GEOMETRY(2003,4326,NULL,MDSYS.SDO_ELEM_INFO_ARRAY(1,1003,1),
  -- Puno, Titicaca
  MDSYS.SDO_ORDINATE_ARRAY(-70.10,-15.90,-69.90,-15.90,-69.90,-15.70,-70.10,-15.70,-70.10,-15.90)));
INSERT INTO celda_muestreo (id_celda, poligono) VALUES (6, MDSYS.SDO_GEOMETRY(2003,4326,NULL,MDSYS.SDO_ELEM_INFO_ARRAY(1,1003,1),
  -- Junin, lago
  MDSYS.SDO_ORDINATE_ARRAY(-76.20,-11.10,-76.00,-11.10,-76.00,-10.90,-76.20,-10.90,-76.20,-11.10)));
INSERT INTO celda_muestreo (id_celda, poligono) VALUES (7, MDSYS.SDO_GEOMETRY(2003,4326,NULL,MDSYS.SDO_ELEM_INFO_ARRAY(1,1003,1),
  -- Lima este (nunca muestreada)
  MDSYS.SDO_ORDINATE_ARRAY(-76.95,-12.10,-76.80,-12.10,-76.80,-11.95,-76.95,-11.95,-76.95,-12.10)));

INSERT INTO area_protegida (id_area, nombre, categoria, poligono) VALUES (4, 'Reserva Titicaca (prueba)', 'reserva',
  MDSYS.SDO_GEOMETRY(2003,4326,NULL,MDSYS.SDO_ELEM_INFO_ARRAY(1,1003,1),
  MDSYS.SDO_ORDINATE_ARRAY(-70.05,-15.85,-69.85,-15.85,-69.85,-15.65,-70.05,-15.65,-70.05,-15.85)));
INSERT INTO area_protegida (id_area, nombre, categoria, poligono) VALUES (5, 'Reserva Junin (prueba)', 'reserva',
  MDSYS.SDO_GEOMETRY(2003,4326,NULL,MDSYS.SDO_ELEM_INFO_ARRAY(1,1003,1),
  MDSYS.SDO_ORDINATE_ARRAY(-76.25,-11.15,-75.95,-11.15,-75.95,-10.85,-76.25,-10.85,-76.25,-11.15)));
INSERT INTO area_protegida (id_area, nombre, categoria, poligono) VALUES (6, 'Santuario Lagunas de Mejia (prueba)', 'santuario',
  MDSYS.SDO_GEOMETRY(2003,4326,NULL,MDSYS.SDO_ELEM_INFO_ARRAY(1,1003,1),
  -- sin registros aun
  MDSYS.SDO_ORDINATE_ARRAY(-71.90,-17.20,-71.80,-17.20,-71.80,-17.10,-71.90,-17.10,-71.90,-17.20)));

-- ------------------------------------------------------------
-- 2. Taxonomia: especies endemicas, en peligro y un segundo reino
-- ------------------------------------------------------------
INSERT INTO taxon (id_taxon, nombre_cientifico, rango, id_taxon_padre) VALUES (4,  'Plantae',            'reino',   NULL);
INSERT INTO taxon (id_taxon, nombre_cientifico, rango, id_taxon_padre) VALUES (5,  'Tracheophyta',       'filo',    4);
INSERT INTO taxon (id_taxon, nombre_cientifico, rango, id_taxon_padre) VALUES (13, 'Liliopsida',         'clase',   5);
INSERT INTO taxon (id_taxon, nombre_cientifico, rango, id_taxon_padre) VALUES (25, 'Podicipediformes',   'orden',   10);
INSERT INTO taxon (id_taxon, nombre_cientifico, rango, id_taxon_padre) VALUES (26, 'Primates',           'orden',   11);
INSERT INTO taxon (id_taxon, nombre_cientifico, rango, id_taxon_padre) VALUES (27, 'Phoenicopteriformes','orden',   10);
INSERT INTO taxon (id_taxon, nombre_cientifico, rango, id_taxon_padre) VALUES (28, 'Poales',             'orden',   13);
INSERT INTO taxon (id_taxon, nombre_cientifico, rango, id_taxon_padre) VALUES (35, 'Podicipedidae',      'familia', 25);
INSERT INTO taxon (id_taxon, nombre_cientifico, rango, id_taxon_padre) VALUES (36, 'Cotingidae',         'familia', 21);
INSERT INTO taxon (id_taxon, nombre_cientifico, rango, id_taxon_padre) VALUES (37, 'Atelidae',           'familia', 26);
INSERT INTO taxon (id_taxon, nombre_cientifico, rango, id_taxon_padre) VALUES (38, 'Phoenicopteridae',   'familia', 27);
INSERT INTO taxon (id_taxon, nombre_cientifico, rango, id_taxon_padre) VALUES (39, 'Bromeliaceae',       'familia', 28);
INSERT INTO taxon (id_taxon, nombre_cientifico, rango, id_taxon_padre) VALUES (45, 'Podiceps',           'genero',  35);
INSERT INTO taxon (id_taxon, nombre_cientifico, rango, id_taxon_padre) VALUES (46, 'Rupicola',           'genero',  36);
INSERT INTO taxon (id_taxon, nombre_cientifico, rango, id_taxon_padre) VALUES (47, 'Lagothrix',          'genero',  37);
INSERT INTO taxon (id_taxon, nombre_cientifico, rango, id_taxon_padre) VALUES (48, 'Phoenicopterus',     'genero',  38);
INSERT INTO taxon (id_taxon, nombre_cientifico, rango, id_taxon_padre) VALUES (49, 'Puya',               'genero',  39);
INSERT INTO taxon (id_taxon, nombre_cientifico, rango, id_taxon_padre) VALUES (50, 'Coragyps',           'genero',  30);
INSERT INTO taxon (id_taxon, nombre_cientifico, rango, id_taxon_padre) VALUES (105,'Podiceps taczanowskii',    'especie', 45);
INSERT INTO taxon (id_taxon, nombre_cientifico, rango, id_taxon_padre) VALUES (106,'Rupicola peruvianus',      'especie', 46);
INSERT INTO taxon (id_taxon, nombre_cientifico, rango, id_taxon_padre) VALUES (107,'Lagothrix flavicauda',     'especie', 47);
INSERT INTO taxon (id_taxon, nombre_cientifico, rango, id_taxon_padre) VALUES (108,'Phoenicopterus chilensis', 'especie', 48);
INSERT INTO taxon (id_taxon, nombre_cientifico, rango, id_taxon_padre) VALUES (109,'Puya raimondii',           'especie', 49);
INSERT INTO taxon (id_taxon, nombre_cientifico, rango, id_taxon_padre) VALUES (110,'Coragyps atratus',         'especie', 50);

INSERT INTO especie (id_taxon, nombre_comun, estado_conservacion, es_endemica, es_migratoria) VALUES (105, 'Zambullidor de Junin',          'CR', 1, 0);
INSERT INTO especie (id_taxon, nombre_comun, estado_conservacion, es_endemica, es_migratoria) VALUES (106, 'Gallito de las rocas',          'LC', 0, 0);
INSERT INTO especie (id_taxon, nombre_comun, estado_conservacion, es_endemica, es_migratoria) VALUES (107, 'Mono choro de cola amarilla',   'CR', 1, 0);
INSERT INTO especie (id_taxon, nombre_comun, estado_conservacion, es_endemica, es_migratoria) VALUES (108, 'Flamenco chileno',              'NT', 0, 1);
INSERT INTO especie (id_taxon, nombre_comun, estado_conservacion, es_endemica, es_migratoria) VALUES (109, 'Puya de Raimondi',              'EN', 1, 0);
INSERT INTO especie (id_taxon, nombre_comun, estado_conservacion, es_endemica, es_migratoria) VALUES (110, 'Gallinazo de cabeza negra',     'LC', 0, 0);

INSERT INTO presencia_esperada (id_presencia, id_taxon, id_departamento, mes_inicio, mes_fin) VALUES (10, 105, 6, 1, 12);
INSERT INTO presencia_esperada (id_presencia, id_taxon, id_departamento, mes_inicio, mes_fin) VALUES (11, 106, 2, 1, 12);
INSERT INTO presencia_esperada (id_presencia, id_taxon, id_departamento, mes_inicio, mes_fin) VALUES (12, 107, 3, 1, 12);
-- cruza el cambio de anio
INSERT INTO presencia_esperada (id_presencia, id_taxon, id_departamento, mes_inicio, mes_fin) VALUES (13, 108, 5, 11, 3);
INSERT INTO presencia_esperada (id_presencia, id_taxon, id_departamento, mes_inicio, mes_fin) VALUES (14, 108, 4, 4, 10);
INSERT INTO presencia_esperada (id_presencia, id_taxon, id_departamento, mes_inicio, mes_fin) VALUES (15, 109, 5, 1, 12);
INSERT INTO presencia_esperada (id_presencia, id_taxon, id_departamento, mes_inicio, mes_fin) VALUES (16, 110, 1, 1, 12);
INSERT INTO presencia_esperada (id_presencia, id_taxon, id_departamento, mes_inicio, mes_fin) VALUES (17, 110, 2, 1, 12);
INSERT INTO presencia_esperada (id_presencia, id_taxon, id_departamento, mes_inicio, mes_fin) VALUES (18, 110, 3, 1, 12);
INSERT INTO presencia_esperada (id_presencia, id_taxon, id_departamento, mes_inicio, mes_fin) VALUES (19, 110, 4, 1, 12);

-- ------------------------------------------------------------
-- 3. Personas
-- ------------------------------------------------------------
INSERT INTO observador (id_observador, alias, fecha_registro, reputacion) VALUES (11, 'camila_andes', DATE '2026-07-01', 0);
INSERT INTO observador (id_observador, alias, fecha_registro, reputacion) VALUES (12, 'jorge_selva',  DATE '2026-07-10', 0);
-- solo identifica, nunca registra
INSERT INTO observador (id_observador, alias, fecha_registro, reputacion) VALUES (13, 'nadia_flora',  DATE '2026-07-15', 0);
INSERT INTO observador (id_observador, alias, fecha_registro, reputacion) VALUES (14, 'tomas_junin',  DATE '2026-08-01', 0);
INSERT INTO observador (id_observador, alias, fecha_registro, reputacion) VALUES (15, 'rosa_cusco',   DATE '2026-08-05', 0);
-- recien registrado, sin actividad
INSERT INTO observador (id_observador, alias, fecha_registro, reputacion) VALUES (16, 'luis_nuevo',   DATE '2026-11-01', 0);
INSERT INTO evento_reputacion (id_evento, id_observador, id_avistamiento, motivo, puntos, fecha)
SELECT id_observador, id_observador, NULL, 'saldo_inicial', 0, CAST(fecha_registro AS TIMESTAMP)
FROM observador WHERE id_observador BETWEEN 11 AND 16;

-- aun sin territorio asignado
INSERT INTO investigador (id_observador, id_departamento) VALUES (15, NULL);

-- ------------------------------------------------------------
-- 4. Campanias y participacion
-- ------------------------------------------------------------
INSERT INTO campania (id_campania, nombre, fecha_inicio, fecha_fin) VALUES (4, 'Censo de flamencos Titicaca 2026', DATE '2026-10-15', DATE '2026-11-30');
INSERT INTO campania (id_campania, nombre, fecha_inicio, fecha_fin) VALUES (5, 'Bioblitz Cusco 2026',              DATE '2026-12-01', DATE '2026-12-15');

INSERT INTO participacion_campania (id_campania, id_observador, rol, fecha_inscripcion) VALUES (1, 1,  'coordinador', DATE '2026-05-20');
INSERT INTO participacion_campania (id_campania, id_observador, rol, fecha_inscripcion) VALUES (1, 2,  'voluntario',  DATE '2026-05-25');
INSERT INTO participacion_campania (id_campania, id_observador, rol, fecha_inscripcion) VALUES (1, 9,  'voluntario',  DATE '2026-06-01');
INSERT INTO participacion_campania (id_campania, id_observador, rol, fecha_inscripcion) VALUES (2, 6,  'coordinador', DATE '2026-06-15');
INSERT INTO participacion_campania (id_campania, id_observador, rol, fecha_inscripcion) VALUES (2, 7,  'voluntario',  DATE '2026-06-20');
INSERT INTO participacion_campania (id_campania, id_observador, rol, fecha_inscripcion) VALUES (2, 8,  'voluntario',  DATE '2026-06-22');
INSERT INTO participacion_campania (id_campania, id_observador, rol, fecha_inscripcion) VALUES (3, 5,  'coordinador', DATE '2026-08-15');
INSERT INTO participacion_campania (id_campania, id_observador, rol, fecha_inscripcion) VALUES (3, 10, 'voluntario',  DATE '2026-08-20');
INSERT INTO participacion_campania (id_campania, id_observador, rol, fecha_inscripcion) VALUES (3, 12, 'voluntario',  DATE '2026-08-21');
INSERT INTO participacion_campania (id_campania, id_observador, rol, fecha_inscripcion) VALUES (4, 11, 'coordinador', DATE '2026-10-01');
INSERT INTO participacion_campania (id_campania, id_observador, rol, fecha_inscripcion) VALUES (4, 3,  'voluntario',  DATE '2026-10-05');
-- inscrita, sin avistamientos
INSERT INTO participacion_campania (id_campania, id_observador, rol, fecha_inscripcion) VALUES (4, 13, 'voluntario',  DATE '2026-10-06');
INSERT INTO participacion_campania (id_campania, id_observador, rol, fecha_inscripcion) VALUES (5, 15, 'coordinador', DATE '2026-11-01');
INSERT INTO participacion_campania (id_campania, id_observador, rol, fecha_inscripcion) VALUES (5, 4,  'voluntario',  DATE '2026-11-03');

-- ------------------------------------------------------------
-- 5. Salidas de campo (esfuerzo de muestreo)
-- ------------------------------------------------------------
INSERT INTO salida_campo VALUES (1, 1,  1, 1,    TIMESTAMP '2026-06-10 07:30:00', TIMESTAMP '2026-06-10 09:30:00', 2.5);
INSERT INTO salida_campo VALUES (2, 2,  1, 1,    TIMESTAMP '2026-06-10 08:00:00', TIMESTAMP '2026-06-10 09:00:00', 1.2);
INSERT INTO salida_campo VALUES (3, 6,  2, 2,    TIMESTAMP '2026-07-12 09:00:00', TIMESTAMP '2026-07-12 12:00:00', 4.0);
INSERT INTO salida_campo VALUES (4, 11, 5, 4,    TIMESTAMP '2026-10-20 06:30:00', TIMESTAMP '2026-10-20 09:00:00', 3.0);
INSERT INTO salida_campo VALUES (5, 3,  5, 4,    TIMESTAMP '2026-10-20 07:00:00', TIMESTAMP '2026-10-20 08:30:00', 1.5);
INSERT INTO salida_campo VALUES (6, 11, 5, 4,    TIMESTAMP '2026-11-02 06:00:00', TIMESTAMP '2026-11-02 08:00:00', 2.2);
INSERT INTO salida_campo VALUES (7, 12, 3, 3,    TIMESTAMP '2026-09-28 08:00:00', TIMESTAMP '2026-09-28 12:00:00', 5.5);
INSERT INTO salida_campo VALUES (8, 14, 6, NULL, TIMESTAMP '2026-08-22 08:00:00', TIMESTAMP '2026-08-22 11:00:00', 3.1);
-- salida sin hallazgos
INSERT INTO salida_campo VALUES (9, 4,  2, NULL, TIMESTAMP '2026-11-05 06:00:00', TIMESTAMP '2026-11-05 10:00:00', 6.0);

-- Vincular avistamientos historicos a su salida
UPDATE avistamiento SET id_salida = 1 WHERE id_avistamiento = 1;
UPDATE avistamiento SET id_salida = 2 WHERE id_avistamiento = 2;
UPDATE avistamiento SET id_salida = 3 WHERE id_avistamiento = 3;

-- ------------------------------------------------------------
-- 6. Seguimiento de especies
-- ------------------------------------------------------------
INSERT INTO seguimiento_especie VALUES (1,  100, DATE '2026-02-01');
INSERT INTO seguimiento_especie VALUES (1,  102, DATE '2026-02-01');
INSERT INTO seguimiento_especie VALUES (2,  100, DATE '2026-03-10');
INSERT INTO seguimiento_especie VALUES (3,  108, DATE '2026-09-30');
INSERT INTO seguimiento_especie VALUES (3,  105, DATE '2026-09-30');
INSERT INTO seguimiento_especie VALUES (6,  103, DATE '2026-05-01');
INSERT INTO seguimiento_especie VALUES (11, 108, DATE '2026-07-02');
-- especie que nadie ha avistado
INSERT INTO seguimiento_especie VALUES (13, 109, DATE '2026-07-16');
INSERT INTO seguimiento_especie VALUES (14, 105, DATE '2026-08-02');
COMMIT;

-- ------------------------------------------------------------
-- 7. Nuevos avistamientos (via procedimiento: avistamiento + evidencia)
--    Los triggers generan auditoria, alertas y duplicados.
-- ------------------------------------------------------------
EXEC DBMS_SESSION.SET_IDENTIFIER('11');
EXEC sp_registrar_avistamiento(16, 11, 108, -69.9500, -15.7500, TIMESTAMP '2026-10-20 07:10:00', 35, 'Bandada en la orilla', 17, 'foto', '/evidencias/av16_foto01.jpg', 'HASH_AV16_F01', 4, 4);
EXEC sp_registrar_avistamiento(18, 11, 108, -69.9700, -15.7800, TIMESTAMP '2026-11-02 06:50:00', 52, 'Conteo matutino', 19, 'foto', '/evidencias/av18_foto01.jpg', 'HASH_AV18_F01', 4, 6);
EXEC sp_registrar_avistamiento(30, 11, 108, -71.6000, -16.4500, TIMESTAMP '2026-11-05 08:00:00', 20, 'Grupo en bofedal', 31, 'foto', '/evidencias/av30_foto01.jpg', 'HASH_AV30_F01');

EXEC DBMS_SESSION.SET_IDENTIFIER('3');
EXEC sp_registrar_avistamiento(17, 3, 108, -69.9502, -15.7501, TIMESTAMP '2026-10-20 07:25:00', 30, 'Misma bandada vista desde el muelle', 18, 'foto', '/evidencias/av17_foto01.jpg', 'HASH_AV17_F01', 4, 5);

EXEC DBMS_SESSION.SET_IDENTIFIER('15');
EXEC sp_registrar_avistamiento(19, 15, 106, -71.9500, -13.5200, TIMESTAMP '2026-08-14 08:00:00', 3, 'Machos en lek', 20, 'foto', '/evidencias/av19_foto01.jpg', 'HASH_AV19_F01');

EXEC DBMS_SESSION.SET_IDENTIFIER('12');
EXEC sp_registrar_avistamiento(20, 12, 107, -73.3000, -3.7000, TIMESTAMP '2026-09-28 10:15:00', 4, 'Tropa en el dosel', 21, 'foto', '/evidencias/av20_foto01.jpg', 'HASH_AV20_F01', 3, 7);
EXEC sp_registrar_avistamiento(29, 12, 104, -73.2200, -3.8000, TIMESTAMP '2026-10-12 14:00:00', 1, 'Mariposa naranja similar a monarca', 30, 'foto', '/evidencias/av29_foto01.jpg', 'HASH_AV29_F01');

EXEC DBMS_SESSION.SET_IDENTIFIER('14');
EXEC sp_registrar_avistamiento(21, 14, 105, -76.1000, -11.0000, TIMESTAMP '2026-08-22 09:00:00', 6, 'Parejas en totoral', 22, 'audio', '/evidencias/av21_audio01.mp3', 'HASH_AV21_A01', NULL, 8);
-- Propone solo el GENERO: la comunidad precisara la especie
EXEC sp_registrar_avistamiento(22, 14, 48, -76.0500, -11.0200, TIMESTAMP '2026-08-22 10:30:00', 12, 'Flamencos lejanos, no distingo especie', 23, 'foto', '/evidencias/av22_foto01.jpg', 'HASH_AV22_F01', NULL, 8);

EXEC DBMS_SESSION.SET_IDENTIFIER('7');
-- Propone condor, pero la comunidad corregira a gallinazo
EXEC sp_registrar_avistamiento(23, 7, 100, -71.9800, -13.5000, TIMESTAMP '2026-08-10 16:00:00', 1, 'Ave negra grande planeando', 24, 'foto', '/evidencias/av23_foto01.jpg', 'HASH_AV23_F01', 2);
EXEC sp_registrar_avistamiento(34, 7, 106, -71.8500, -13.6000, TIMESTAMP '2026-08-14 08:10:00', 1, 'Macho solitario', 35, 'foto', '/evidencias/av34_foto01.jpg', 'HASH_AV34_F01');

EXEC DBMS_SESSION.SET_IDENTIFIER('10');
EXEC sp_registrar_avistamiento(24, 10, 110, -77.0500, -12.0700, TIMESTAMP '2026-09-30 12:00:00', 8, 'Sobre el mercado', 25, 'foto', '/evidencias/av24_foto01.jpg', 'HASH_AV24_F01');
EXEC sp_registrar_avistamiento(35, 10, 108, -69.9701, -15.7802, TIMESTAMP '2026-11-02 07:05:00', 48, 'Conteo desde la orilla', 36, 'foto', '/evidencias/av35_foto01.jpg', 'HASH_AV35_F01');

EXEC DBMS_SESSION.SET_IDENTIFIER('2');
EXEC sp_registrar_avistamiento(25, 2, 102, -71.9200, -13.5800, TIMESTAMP '2026-07-28 06:20:00', 2, 'Madre con cria', 26, 'foto', '/evidencias/av25_foto01.jpg', 'HASH_AV25_F01');

EXEC DBMS_SESSION.SET_IDENTIFIER('5');
EXEC sp_registrar_avistamiento(26, 5, 107, -73.3200, -3.7200, TIMESTAMP '2026-09-28 10:40:00', 3, 'Segunda tropa', 27, 'audio', '/evidencias/av26_audio01.mp3', 'HASH_AV26_A01', 3);

EXEC DBMS_SESSION.SET_IDENTIFIER('6');
EXEC sp_registrar_avistamiento(27, 6, 103, -69.5000, -16.2000, TIMESTAMP '2026-10-05 11:00:00', 15, 'Tropilla en puna', 28, 'foto', '/evidencias/av27_foto01.jpg', 'HASH_AV27_F01');

EXEC DBMS_SESSION.SET_IDENTIFIER('8');
EXEC sp_registrar_avistamiento(28, 8, 103, -71.5000, -16.3500, TIMESTAMP '2026-10-10 09:30:00', 9, 'Cerca a la carretera', 29, 'foto', '/evidencias/av28_foto01.jpg', 'HASH_AV28_F01');

EXEC DBMS_SESSION.SET_IDENTIFIER('9');
EXEC sp_registrar_avistamiento(31, 9, 101, -77.0400, -12.0500, TIMESTAMP '2026-07-02 07:30:00', 1, 'Canto en parque', 32, 'audio', '/evidencias/av31_audio01.mp3', 'HASH_AV31_A01');

EXEC DBMS_SESSION.SET_IDENTIFIER('4');
EXEC sp_registrar_avistamiento(33, 4, 100, -72.0000, -15.6000, TIMESTAMP '2026-09-14 10:00:00', 2, 'Pareja en el canon', 34, 'foto', '/evidencias/av33_foto01.jpg', 'HASH_AV33_F01');

-- Evidencias adicionales (una reutiliza un archivo ya usado: mismo hash)
INSERT INTO evidencia VALUES (37, 20, 'audio', '/evidencias/av20_audio01.mp3', 'HASH_AV20_A01', TIMESTAMP '2026-09-28 10:20:00');
INSERT INTO evidencia VALUES (38, 25, 'foto',  '/evidencias/av25_foto02.jpg',  'HASH_AV25_F02', TIMESTAMP '2026-07-28 06:30:00');
INSERT INTO evidencia VALUES (39, 26, 'foto',  '/evidencias/av26_foto01.jpg',  'HASH_AV20_F01', TIMESTAMP '2026-09-28 10:45:00');
COMMIT;

-- ------------------------------------------------------------
-- 8. Identificaciones de la comunidad (disparan el consenso)
-- ------------------------------------------------------------
EXEC DBMS_SESSION.SET_IDENTIFIER(NULL);
INSERT INTO identificacion VALUES (16, 16, 3,  108, TIMESTAMP '2026-10-20 12:00:00');
-- 2 coinciden -> verificado
INSERT INTO identificacion VALUES (17, 16, 13, 108, TIMESTAMP '2026-10-20 13:00:00');
-- solo 1 -> sigue pendiente
INSERT INTO identificacion VALUES (18, 18, 13, 108, TIMESTAMP '2026-11-02 10:00:00');
INSERT INTO identificacion VALUES (19, 20, 5,  107, TIMESTAMP '2026-09-28 15:00:00');
INSERT INTO identificacion VALUES (20, 21, 3,  105, TIMESTAMP '2026-08-23 09:00:00');
INSERT INTO identificacion VALUES (21, 22, 13, 108, TIMESTAMP '2026-08-22 18:00:00');
-- genero -> especie por consenso
INSERT INTO identificacion VALUES (22, 22, 3,  108, TIMESTAMP '2026-08-23 08:00:00');
INSERT INTO identificacion VALUES (23, 23, 4,  110, TIMESTAMP '2026-08-10 18:00:00');
-- corrige condor -> gallinazo
INSERT INTO identificacion VALUES (24, 23, 15, 110, TIMESTAMP '2026-08-11 07:00:00');
INSERT INTO identificacion VALUES (25, 24, 1,  110, TIMESTAMP '2026-09-30 13:00:00');
INSERT INTO identificacion VALUES (26, 24, 2,  110, TIMESTAMP '2026-09-30 14:00:00');
INSERT INTO identificacion VALUES (27, 27, 11, 103, TIMESTAMP '2026-10-05 15:00:00');
-- desacuerdo: solo llega a genero
INSERT INTO identificacion VALUES (28, 27, 13, 43,  TIMESTAMP '2026-10-05 16:00:00');
INSERT INTO identificacion VALUES (29, 29, 5,  104, TIMESTAMP '2026-10-12 16:00:00');
INSERT INTO identificacion VALUES (30, 31, 2,  101, TIMESTAMP '2026-07-02 09:00:00');
INSERT INTO identificacion VALUES (31, 19, 4,  106, TIMESTAMP '2026-08-14 12:00:00');
INSERT INTO identificacion VALUES (32, 19, 7,  106, TIMESTAMP '2026-08-14 13:00:00');
COMMIT;

-- ------------------------------------------------------------
-- 9. Trabajo de los investigadores (asumir alertas y validar)
-- ------------------------------------------------------------
-- Cusco (investigador 4)
EXEC DBMS_SESSION.SET_IDENTIFIER('4');
UPDATE alerta SET id_investigador = 4 WHERE id_avistamiento = 25 AND tipo = 'especie_amenazada';
UPDATE avistamiento SET id_taxon_validado = 102, metodo_validacion = 'investigador', estado = 'verificado'
WHERE id_avistamiento = 25;
UPDATE alerta SET estado = 'resuelta' WHERE id_avistamiento = 25 AND tipo = 'especie_amenazada';
-- El "condor" era un gallinazo: la alerta de especie amenazada se descarta
UPDATE alerta SET id_investigador = 4, estado = 'descartada' WHERE id_avistamiento = 23 AND tipo = 'especie_amenazada';
-- Sin alertas abiertas, el investigador confirma el taxon que fijo la comunidad
UPDATE avistamiento SET estado = 'verificado', metodo_validacion = 'investigador'
WHERE id_avistamiento = 23;

-- Loreto (investigador 5)
EXEC DBMS_SESSION.SET_IDENTIFIER('5');
-- (el avistamiento 26 es del propio investigador 5: su alerta queda pendiente)
UPDATE alerta SET id_investigador = 5 WHERE id_avistamiento IN (20, 29);
UPDATE avistamiento SET id_taxon_validado = 107, metodo_validacion = 'investigador', estado = 'verificado'
WHERE id_avistamiento = 20;
UPDATE alerta SET estado = 'resuelta' WHERE id_avistamiento = 20;
UPDATE avistamiento SET estado = 'dudoso' WHERE id_avistamiento = 29;

-- Arequipa (investigador 8)
EXEC DBMS_SESSION.SET_IDENTIFIER('8');
UPDATE alerta SET id_investigador = 8 WHERE id_avistamiento IN (30, 33);
UPDATE avistamiento SET id_taxon_validado = 100, metodo_validacion = 'investigador', estado = 'verificado'
WHERE id_avistamiento = 33;
UPDATE alerta SET estado = 'resuelta' WHERE id_avistamiento = 33;

EXEC DBMS_SESSION.SET_IDENTIFIER(NULL);
COMMIT;

ALTER TRIGGER trg_alerta_credencial ENABLE;


-- ############################################################
-- PARTE E. FUNCIONALIDADES
-- ############################################################

-- Credenciales de rosa_cusco (investigadora registrada en la carga ampliada)
INSERT INTO credencial VALUES (17, 15, 'titulo_profesional',  'UNSAAC - Biologia',                       'SUNEDU-T-PRUEBA-0017', NULL, DATE '2018-09-10', NULL,              'verificada', 8, TIMESTAMP '2026-08-06 10:00:00');
INSERT INTO credencial VALUES (18, 15, 'colegiatura',         'Colegio de Biologos del Peru',            'CBP-PRUEBA-13001',     NULL, DATE '2019-01-15', DATE '2027-03-31', 'verificada', 8, TIMESTAMP '2026-08-06 10:05:00');
INSERT INTO credencial VALUES (19, 15, 'carta_institucional', 'ONG Conservacion Andina (ficticia)',      'CA-PRUEBA-2026-01',    NULL, DATE '2026-08-01', NULL,              'verificada', 8, TIMESTAMP '2026-08-06 10:10:00');
COMMIT;

-- ============================================================
-- Actividad previa que da experiencia a las postulantes
-- (identificaciones que terminan coincidiendo con el consenso)
-- ============================================================
INSERT INTO identificacion VALUES (33, 35, 11, 108, TIMESTAMP '2026-11-02 09:00:00');
-- 2 votos: consenso -> av. 35 verificado
INSERT INTO identificacion VALUES (34, 35, 13, 108, TIMESTAMP '2026-11-02 09:30:00');
INSERT INTO identificacion VALUES (35, 28, 11, 103, TIMESTAMP '2026-10-10 12:00:00');
-- 2 votos: consenso -> av. 28 verificado
INSERT INTO identificacion VALUES (36, 28, 2,  103, TIMESTAMP '2026-10-10 13:00:00');
-- 2 votos con la de andrea: consenso -> av. 31 verificado
INSERT INTO identificacion VALUES (37, 31, 11, 101, TIMESTAMP '2026-07-03 08:00:00');
COMMIT;

-- ============================================================
-- F1. Postulacion APROBADA: camila_andes -> Puno
-- Puno no tiene investigador: evalua uno de otro departamento.
-- ============================================================
INSERT INTO credencial (id_credencial, id_observador, tipo, entidad_emisora, codigo_registro, nivel_renacyt, fecha_emision, fecha_vencimiento)
VALUES (20, 11, 'grado_bachiller',     'Universidad Nacional del Altiplano', 'SUNEDU-B-PRUEBA-0020', NULL, DATE '2019-12-20', NULL);
INSERT INTO credencial (id_credencial, id_observador, tipo, entidad_emisora, codigo_registro, nivel_renacyt, fecha_emision, fecha_vencimiento)
VALUES (21, 11, 'colegiatura',         'Colegio de Biologos del Peru',       'CBP-PRUEBA-14077',     NULL, DATE '2021-02-01', DATE '2027-11-30');
INSERT INTO credencial (id_credencial, id_observador, tipo, entidad_emisora, codigo_registro, nivel_renacyt, fecha_emision, fecha_vencimiento)
VALUES (22, 11, 'carta_institucional', 'UNA Puno - Lab. de Ecologia Acuatica','UNAP-PRUEBA-2026-88',  NULL, DATE '2026-10-28', NULL);
INSERT INTO credencial (id_credencial, id_observador, tipo, entidad_emisora, codigo_registro, nivel_renacyt, fecha_emision, fecha_vencimiento)
VALUES (23, 11, 'renacyt',             'CONCYTEC',                           'RENACYT-PRUEBA-P0921', 7,    DATE '2025-06-30', DATE '2028-06-30');

INSERT INTO postulacion_investigador (id_postulacion, id_observador, id_departamento, institucion, especialidad, motivacion, fecha_postulacion)
VALUES (1, 11, 5, 'Universidad Nacional del Altiplano', 'Ornitologia acuatica',
        'Coordino el censo de flamencos del Titicaca y Puno no tiene investigador que revise alertas.',
        TIMESTAMP '2026-11-03 09:00:00');

EXEC DBMS_SESSION.SET_IDENTIFIER('8');
UPDATE postulacion_investigador SET estado = 'en_revision', id_evaluador = 8 WHERE id_postulacion = 1;
UPDATE credencial SET estado_verificacion = 'verificada' WHERE id_observador = 11;
UPDATE postulacion_investigador
SET estado = 'aprobada', observacion = 'Cumple requisitos documentarios y de experiencia'
WHERE id_postulacion = 1;
COMMIT;

-- La nueva investigadora ya trabaja: asume una alerta de Puno
-- (la del av. 16 no puede: es suya).
EXEC DBMS_SESSION.SET_IDENTIFIER('11');
UPDATE alerta SET id_investigador = 11 WHERE id_avistamiento = 17 AND tipo = 'fuera_temporada';
COMMIT;

-- ============================================================
-- F1. Postulacion RECHAZADA: nadia_flora -> Junin (sin colegiatura)
-- ============================================================
INSERT INTO credencial (id_credencial, id_observador, tipo, entidad_emisora, codigo_registro, nivel_renacyt, fecha_emision, fecha_vencimiento)
VALUES (24, 13, 'grado_bachiller',     'Universidad Nacional del Centro del Peru', 'SUNEDU-B-PRUEBA-0024', NULL, DATE '2024-07-15', NULL);
INSERT INTO credencial (id_credencial, id_observador, tipo, entidad_emisora, codigo_registro, nivel_renacyt, fecha_emision, fecha_vencimiento)
VALUES (25, 13, 'carta_institucional', 'UNCP - Grupo de Botanica',                 'UNCP-PRUEBA-2026-14',  NULL, DATE '2026-11-01', NULL);

INSERT INTO postulacion_investigador (id_postulacion, id_observador, id_departamento, institucion, especialidad, motivacion, fecha_postulacion)
VALUES (2, 13, 6, 'Universidad Nacional del Centro del Peru', 'Botanica altoandina',
        'Junin no cuenta con investigador y conozco la zona del lago.',
        TIMESTAMP '2026-11-04 15:00:00');

EXEC DBMS_SESSION.SET_IDENTIFIER('11');
UPDATE postulacion_investigador SET estado = 'en_revision', id_evaluador = 11 WHERE id_postulacion = 2;
UPDATE credencial SET estado_verificacion = 'verificada' WHERE id_credencial = 24;
UPDATE credencial SET estado_verificacion = 'observada'  WHERE id_credencial = 25;
UPDATE postulacion_investigador
SET estado = 'rechazada', observacion = 'Falta colegiatura habilitada del CBP; carta institucional sin firma'
WHERE id_postulacion = 2;
COMMIT;

-- ============================================================
-- F2. Reportes
-- Caso A (av. 8): dos reportes -> alerta -> PROCEDENTE -> rechazo
-- ============================================================
EXEC DBMS_SESSION.SET_IDENTIFIER(NULL);
INSERT INTO reporte_avistamiento (id_reporte, id_avistamiento, id_reportante, motivo, detalle, fecha_reporte)
VALUES (1, 8, 2, 'ubicacion_falsa', 'El oso de anteojos no habita la costa de Lima', TIMESTAMP '2026-11-05 10:00:00');
INSERT INTO reporte_avistamiento (id_reporte, id_avistamiento, id_reportante, motivo, detalle, fecha_reporte)
VALUES (2, 8, 10, 'ubicacion_falsa', 'La foto parece tomada en un zoologico', TIMESTAMP '2026-11-05 11:00:00');
COMMIT;

EXEC DBMS_SESSION.SET_IDENTIFIER('3');
UPDATE reporte_avistamiento SET estado = 'procedente' WHERE id_avistamiento = 8;
COMMIT;

-- Caso B (av. 24): dos reportes -> av. pasa a dudoso -> IMPROCEDENTES
-- -> vuelve a verificado (sin volver a pagar reputacion)
EXEC DBMS_SESSION.SET_IDENTIFIER(NULL);
INSERT INTO reporte_avistamiento (id_reporte, id_avistamiento, id_reportante, motivo, detalle, fecha_reporte)
VALUES (3, 24, 7, 'especie_cautiva', 'Podria ser un ave de un criadero', TIMESTAMP '2026-11-06 08:00:00');
INSERT INTO reporte_avistamiento (id_reporte, id_avistamiento, id_reportante, motivo, detalle, fecha_reporte)
VALUES (4, 24, 9, 'especie_cautiva', NULL, TIMESTAMP '2026-11-06 09:00:00');
COMMIT;

EXEC DBMS_SESSION.SET_IDENTIFIER('3');
UPDATE reporte_avistamiento SET estado = 'improcedente' WHERE id_avistamiento = 24;
COMMIT;

-- Caso C: un reporte suelto que no alcanza el umbral (queda pendiente)
EXEC DBMS_SESSION.SET_IDENTIFIER(NULL);
INSERT INTO reporte_avistamiento (id_reporte, id_avistamiento, id_reportante, motivo, detalle, fecha_reporte)
VALUES (5, 33, 6, 'fecha_incorrecta', 'En los metadatos de la foto figura otro anio', TIMESTAMP '2026-11-07 17:00:00');
COMMIT;

-- ============================================================
-- F4. Apelaciones
-- Caso A: piero apela el rechazo del av. 8 con nueva evidencia.
-- Lima solo tiene a diego (quien rechazo): resuelve otro investigador.
-- ============================================================
INSERT INTO evidencia VALUES (40, 8, 'foto', '/evidencias/av08_foto02.jpg', 'HASH_AV08_F02', TIMESTAMP '2026-11-09 18:00:00');

EXEC DBMS_SESSION.SET_IDENTIFIER('1');
INSERT INTO apelacion (id_apelacion, id_avistamiento, argumento, fecha_apelacion)
VALUES (1, 8, 'Adjunto una segunda foto con el GPS del celular; fue en las lomas de Lima, donde hay registros historicos.', SYSTIMESTAMP);
COMMIT;

EXEC DBMS_SESSION.SET_IDENTIFIER('8');
UPDATE apelacion
SET estado = 'aceptada', resolucion = 'La nueva evidencia justifica una revision especializada; se anula el rechazo'
WHERE id_apelacion = 1;
COMMIT;

-- Caso B: angelo rechaza el av. 29 y jorge apela (queda pendiente)
EXEC DBMS_SESSION.SET_IDENTIFIER('5');
UPDATE avistamiento SET estado = 'rechazado' WHERE id_avistamiento = 29;
UPDATE alerta SET estado = 'resuelta' WHERE id_avistamiento = 29;
COMMIT;

EXEC DBMS_SESSION.SET_IDENTIFIER('12');
INSERT INTO apelacion (id_apelacion, id_avistamiento, argumento, fecha_apelacion)
VALUES (2, 29, 'Era una Danaus erippus, especie hermana que si vive en la Amazonia; pido reconsiderar el taxon.', SYSTIMESTAMP);
COMMIT;

-- ============================================================
-- F3. Solicitudes de ubicacion exacta
-- ============================================================
EXEC DBMS_SESSION.SET_IDENTIFIER(NULL);
INSERT INTO solicitud_ubicacion (id_solicitud, id_solicitante, id_taxon, id_departamento, proposito, fecha_solicitud)
VALUES (1, 13, 107, 3, 'Tesis de pregrado: uso de habitat del mono choro de cola amarilla', TIMESTAMP '2026-11-06 10:00:00');
INSERT INTO solicitud_ubicacion (id_solicitud, id_solicitante, id_taxon, id_departamento, proposito, fecha_solicitud)
VALUES (2, 12, 105, 6, 'Quiero ir a fotografiarlo', TIMESTAMP '2026-11-07 12:00:00');
INSERT INTO solicitud_ubicacion (id_solicitud, id_solicitante, id_taxon, id_departamento, proposito, fecha_solicitud)
VALUES (3, 1, 107, 3, 'Monitoreo de primates para una ONG', TIMESTAMP '2026-06-01 09:00:00');
INSERT INTO solicitud_ubicacion (id_solicitud, id_solicitante, id_taxon, id_departamento, proposito, fecha_solicitud)
VALUES (4, 9, 109, 5, 'Inventario de puyas para el SERNANP', TIMESTAMP '2026-11-08 08:00:00');

-- Loreto: aprueba angelo (vigencia por defecto 90 dias)
EXEC DBMS_SESSION.SET_IDENTIFIER('5');
UPDATE solicitud_ubicacion SET estado = 'aprobada' WHERE id_solicitud = 1;
-- Aprobada en junio, ya VENCIDA
UPDATE solicitud_ubicacion
SET estado = 'aprobada', fecha_resolucion = TIMESTAMP '2026-06-03 10:00:00', vigente_hasta = DATE '2026-09-01'
WHERE id_solicitud = 3;

-- Junin no tiene investigador: resuelve uno de otro departamento
EXEC DBMS_SESSION.SET_IDENTIFIER('11');
UPDATE solicitud_ubicacion SET estado = 'denegada' WHERE id_solicitud = 2;

EXEC DBMS_SESSION.SET_IDENTIFIER(NULL);
COMMIT;

-- ============================================================
-- Verificacion de la carga
-- ============================================================
SELECT table_name AS tabla, num_rows AS filas FROM (
    SELECT table_name,
           TO_NUMBER(EXTRACTVALUE(XMLTYPE(DBMS_XMLGEN.GETXML('SELECT COUNT(*) c FROM ' || table_name)), '/ROWSET/ROW/C')) AS num_rows
    FROM user_tables
    WHERE table_name NOT LIKE 'MDRT%' AND table_name NOT LIKE 'MDXT%')
ORDER BY table_name;
