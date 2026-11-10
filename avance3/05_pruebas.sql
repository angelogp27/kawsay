-- ============================================================
-- PROYECTO BD2 - Ciencia ciudadana de biodiversidad
-- 05 - PRUEBAS DE REGLAS DE NEGOCIO (opcional, para la demostracion)
-- Cada caso intenta VIOLAR una regla; pasa si Oracle la rechaza
-- con el error esperado. Nada queda guardado (ROLLBACK).
-- ============================================================
SET SERVEROUTPUT ON SIZE UNLIMITED
SET SQLBLANKLINES ON

DECLARE
    v_ok  PLS_INTEGER := 0;
    v_mal PLS_INTEGER := 0;

    PROCEDURE probar(p_regla VARCHAR2, p_sql VARCHAR2, p_error NUMBER, p_actor VARCHAR2 DEFAULT NULL) IS
    BEGIN
        DBMS_SESSION.SET_IDENTIFIER(p_actor);
        SAVEPOINT antes;
        BEGIN
            EXECUTE IMMEDIATE p_sql;
            ROLLBACK TO antes;
            DBMS_OUTPUT.PUT_LINE('FALLA  ' || p_regla || '  (la operacion fue aceptada)');
            v_mal := v_mal + 1;
        EXCEPTION WHEN OTHERS THEN
            ROLLBACK TO antes;
            IF SQLCODE = p_error THEN
                DBMS_OUTPUT.PUT_LINE('OK     ' || p_regla || CHR(10) || '         -> '
                    || REGEXP_SUBSTR(SQLERRM, '^[^' || CHR(10) || ']*'));
                v_ok := v_ok + 1;
            ELSE
                DBMS_OUTPUT.PUT_LINE('FALLA  ' || p_regla || '  esperado ' || p_error || ', obtenido ' || SQLERRM);
                v_mal := v_mal + 1;
            END IF;
        END;
        DBMS_SESSION.SET_IDENTIFIER(NULL);
        pkg_bd2.g_sistema := FALSE;
        pkg_func.g_apelacion := FALSE;
    END;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== Reglas del modelo ===');
    probar('RN15 taxon sin ciclos / jerarquia',
           q'[UPDATE taxon SET id_taxon_padre = 100 WHERE id_taxon = 40]', -20001);
    probar('RN16 ESPECIE solo para rango especie',
           q'[INSERT INTO especie VALUES (40, 'Genero no valido', 'LC', 0, 0)]', -20002);
    probar('RN05 numero de individuos > 0',
           q'[UPDATE avistamiento SET numero_individuos = 0 WHERE id_avistamiento = 1]', -2290);
    probar('RN14 verificado exige taxon validado',
           q'[UPDATE avistamiento SET estado = 'verificado' WHERE id_avistamiento = 1]', -2290, '3');
    probar('RN24 avistamiento fuera del periodo de la campania',
           q'[UPDATE avistamiento SET id_campania = 3 WHERE id_avistamiento = 1]', -20010);
    probar('RN30 solo inscritos aportan a una campania',
           q'[UPDATE avistamiento SET id_campania = 4, id_salida = NULL WHERE id_avistamiento = 35]', -20013);
    probar('Salida de campo de otro observador',
           q'[UPDATE avistamiento SET id_salida = 1 WHERE id_avistamiento = 2]', -20011);
    probar('Conflicto de interes: validar lo propio',
           q'[UPDATE avistamiento SET estado = 'rechazado' WHERE id_avistamiento = 26]', -20014, '5');
    probar('RN12 el autor no identifica su avistamiento',
           q'[INSERT INTO identificacion VALUES (900, 1, 1, 101, TIMESTAMP '2026-06-11 10:00:00')]', -20020);
    probar('RN11 una identificacion por observador',
           q'[INSERT INTO identificacion VALUES (901, 2, 1, 101, TIMESTAMP '2026-06-11 10:00:00')]', -1);
    probar('Identificacion anterior al avistamiento',
           q'[INSERT INTO identificacion VALUES (902, 1, 5, 101, TIMESTAMP '2026-01-01 10:00:00')]', -20021);
    probar('RN22 investigador de otro departamento',
           q'[UPDATE alerta SET id_investigador = 3 WHERE id_alerta = 105]', -20030);
    probar('RN22 investigador sin territorio asignado',
           q'[UPDATE alerta SET id_investigador = 15 WHERE id_alerta = 105]', -20030);
    probar('Investigador revisa su propio avistamiento',
           q'[UPDATE alerta SET id_investigador = 5 WHERE id_alerta = 108]', -20031);
    probar('Alerta resuelta exige responsable',
           q'[UPDATE alerta SET estado = 'resuelta' WHERE id_alerta = 105]', -2290);
    probar('RN21 una alerta por tipo y avistamiento',
           q'[INSERT INTO alerta (id_alerta, id_avistamiento, tipo, fecha_generacion, estado)
              VALUES (999, 21, 'especie_amenazada', SYSTIMESTAMP, 'pendiente')]', -1);
    probar('RN27 duplicado: pareja en orden A<B',
           q'[INSERT INTO duplicado_candidato VALUES (2, 1, 31, 17, 'pendiente')]', -2290);
    probar('RN28 auditoria inmutable (UPDATE)',
           q'[UPDATE auditoria_avistamiento SET estado_nuevo = 'rechazado' WHERE id_auditoria = 1]', -20040);
    probar('RN28 auditoria inmutable (DELETE)',
           q'[DELETE FROM auditoria_avistamiento WHERE id_auditoria = 1]', -20040);
    probar('RN07 avistamiento sin evidencia',
           q'[BEGIN sp_registrar_avistamiento(999, 1, 101, -77.05, -12.05, SYSTIMESTAMP, 1, NULL,
                  999, 'foto', NULL, NULL); END;]', -20050);

    DBMS_OUTPUT.PUT_LINE('=== F1. Registro de investigadores ===');
    probar('Quien ya es investigador no postula',
        q'[INSERT INTO postulacion_investigador (id_postulacion, id_observador, id_departamento, institucion, especialidad, motivacion, fecha_postulacion)
           VALUES (900, 15, 2, 'X', 'X', 'X', SYSTIMESTAMP)]', -20101);
    probar('Antiguedad minima en la plataforma',
        q'[INSERT INTO postulacion_investigador (id_postulacion, id_observador, id_departamento, institucion, especialidad, motivacion, fecha_postulacion)
           VALUES (900, 16, 1, 'X', 'X', 'X', SYSTIMESTAMP)]', -20102);
    probar('Identificaciones acertadas minimas',
        q'[INSERT INTO postulacion_investigador (id_postulacion, id_observador, id_departamento, institucion, especialidad, motivacion, fecha_postulacion)
           VALUES (900, 14, 6, 'X', 'X', 'X', SYSTIMESTAMP)]', -20103);
    probar('Sin reportes procedentes recientes en contra',
        q'[BEGIN
             INSERT INTO reporte_avistamiento (id_reporte, id_avistamiento, id_reportante, motivo, fecha_reporte)
             VALUES (900, 9, 1, 'foto_ajena', SYSTIMESTAMP - INTERVAL '1' HOUR);
             INSERT INTO reporte_avistamiento (id_reporte, id_avistamiento, id_reportante, motivo, fecha_reporte)
             VALUES (901, 9, 10, 'foto_ajena', SYSTIMESTAMP - INTERVAL '1' HOUR);
             DBMS_SESSION.SET_IDENTIFIER('8');
             UPDATE reporte_avistamiento SET estado = 'procedente' WHERE id_avistamiento = 9;
             INSERT INTO postulacion_investigador (id_postulacion, id_observador, id_departamento, institucion, especialidad, motivacion, fecha_postulacion)
             VALUES (900, 2, 4, 'X', 'X', 'X', SYSTIMESTAMP);
           END;]', -20104);
    probar('Aprobar sin credenciales obligatorias',
        q'[BEGIN
             INSERT INTO postulacion_investigador (id_postulacion, id_observador, id_departamento, institucion, especialidad, motivacion, fecha_postulacion)
             VALUES (900, 2, 4, 'UNSA', 'Mastozoologia', 'X', SYSTIMESTAMP);
             UPDATE postulacion_investigador SET estado = 'en_revision', id_evaluador = 8 WHERE id_postulacion = 900;
             UPDATE postulacion_investigador SET estado = 'aprobada' WHERE id_postulacion = 900;
           END;]', -20107);
    probar('Aprobar sin acreditar investigacion (RENACYT/posgrado/SERFOR)',
        q'[BEGIN
             INSERT INTO credencial (id_credencial, id_observador, tipo, entidad_emisora, codigo_registro, fecha_emision, fecha_vencimiento)
             VALUES (900, 2, 'titulo_profesional', 'UNSA', 'T-900', DATE '2020-01-01', NULL);
             INSERT INTO credencial (id_credencial, id_observador, tipo, entidad_emisora, codigo_registro, fecha_emision, fecha_vencimiento)
             VALUES (901, 2, 'colegiatura', 'Colegio de Biologos del Peru', 'CBP-900', DATE '2020-01-01', DATE '2028-01-01');
             INSERT INTO credencial (id_credencial, id_observador, tipo, entidad_emisora, codigo_registro, fecha_emision, fecha_vencimiento)
             VALUES (902, 2, 'carta_institucional', 'UNSA', 'C-900', DATE '2026-01-01', NULL);
             INSERT INTO postulacion_investigador (id_postulacion, id_observador, id_departamento, institucion, especialidad, motivacion, fecha_postulacion)
             VALUES (900, 2, 4, 'UNSA', 'Mastozoologia', 'X', SYSTIMESTAMP);
             DBMS_SESSION.SET_IDENTIFIER('8');
             UPDATE postulacion_investigador SET estado = 'en_revision', id_evaluador = 8 WHERE id_postulacion = 900;
             UPDATE credencial SET estado_verificacion = 'verificada' WHERE id_credencial IN (900, 901, 902);
             UPDATE postulacion_investigador SET estado = 'aprobada' WHERE id_postulacion = 900;
           END;]', -20108);
    probar('Evaluador de otro departamento cuando hay uno local',
        q'[BEGIN
             INSERT INTO postulacion_investigador (id_postulacion, id_observador, id_departamento, institucion, especialidad, motivacion, fecha_postulacion)
             VALUES (900, 2, 1, 'UNMSM', 'Mastozoologia', 'X', SYSTIMESTAMP);
             UPDATE postulacion_investigador SET estado = 'en_revision', id_evaluador = 8 WHERE id_postulacion = 900;
           END;]', -20106);
    probar('Investigador suspendido (colegiatura vencida) no evalua',
        q'[BEGIN
             INSERT INTO postulacion_investigador (id_postulacion, id_observador, id_departamento, institucion, especialidad, motivacion, fecha_postulacion)
             VALUES (900, 2, 2, 'UNSAAC', 'Mastozoologia', 'X', SYSTIMESTAMP);
             UPDATE postulacion_investigador SET estado = 'en_revision', id_evaluador = 4 WHERE id_postulacion = 900;
           END;]', -20106);
    probar('Una sola postulacion activa por persona',
        q'[BEGIN
             INSERT INTO postulacion_investigador (id_postulacion, id_observador, id_departamento, institucion, especialidad, motivacion, fecha_postulacion)
             VALUES (900, 2, 4, 'X', 'X', 'X', SYSTIMESTAMP);
             INSERT INTO postulacion_investigador (id_postulacion, id_observador, id_departamento, institucion, especialidad, motivacion, fecha_postulacion)
             VALUES (901, 2, 1, 'X', 'X', 'X', SYSTIMESTAMP);
           END;]', -1);
    probar('Numero de colegiatura ya registrado por otra persona',
        q'[INSERT INTO credencial (id_credencial, id_observador, tipo, entidad_emisora, codigo_registro, fecha_emision, fecha_vencimiento)
           VALUES (900, 2, 'colegiatura', 'Colegio de Biologos del Peru', 'CBP-PRUEBA-14077', DATE '2020-01-01', DATE '2028-01-01')]', -1);
    probar('Nadie verifica sus propias credenciales',
        q'[UPDATE credencial SET estado_verificacion = 'observada', id_verificador = 11, fecha_verificacion = NULL
           WHERE id_credencial = 21]', -20109, '11');
    probar('Nivel RENACYT solo en credencial RENACYT',
        q'[INSERT INTO credencial (id_credencial, id_observador, tipo, entidad_emisora, codigo_registro, nivel_renacyt, fecha_emision)
           VALUES (900, 2, 'carta_institucional', 'UNSA', 'C-901', 3, DATE '2026-01-01')]', -2290);
    probar('Colegiatura exige fecha de vencimiento',
        q'[INSERT INTO credencial (id_credencial, id_observador, tipo, entidad_emisora, codigo_registro, fecha_emision)
           VALUES (900, 2, 'colegiatura', 'Colegio de Biologos del Peru', 'CBP-901', DATE '2026-01-01')]', -2290);
    probar('Investigador suspendido no asume alertas',
        q'[INSERT INTO alerta (id_alerta, id_avistamiento, id_investigador, tipo, fecha_generacion, estado)
           VALUES (900, 34, 4, 'fuera_temporada', SYSTIMESTAMP, 'asignada')]', -20110);

    DBMS_OUTPUT.PUT_LINE('=== F2. Reportes ===');
    probar('No se reporta un avistamiento propio',
        q'[INSERT INTO reporte_avistamiento (id_reporte, id_avistamiento, id_reportante, motivo, fecha_reporte)
           VALUES (900, 1, 1, 'foto_ajena', SYSTIMESTAMP)]', -20120);
    probar('Un reporte por persona y avistamiento',
        q'[INSERT INTO reporte_avistamiento (id_reporte, id_avistamiento, id_reportante, motivo, fecha_reporte)
           VALUES (900, 33, 6, 'foto_ajena', SYSTIMESTAMP)]', -1);
    probar('No se reporta algo ya rechazado',
        q'[INSERT INTO reporte_avistamiento (id_reporte, id_avistamiento, id_reportante, motivo, fecha_reporte)
           VALUES (900, 10, 2, 'foto_ajena', SYSTIMESTAMP)]', -20121);
    probar('Resuelve solo un investigador del departamento',
        q'[UPDATE reporte_avistamiento SET estado = 'improcedente' WHERE id_reporte = 5]', -20122, '3');
    probar('Un reporte resuelto no se reabre',
        q'[UPDATE reporte_avistamiento SET estado = 'procedente' WHERE id_reporte = 3]', -20123, '3');

    DBMS_OUTPUT.PUT_LINE('=== F3. Geoprivacidad ===');
    probar('Solo especies CR/EN requieren solicitud',
        q'[INSERT INTO solicitud_ubicacion (id_solicitud, id_solicitante, id_taxon, id_departamento, proposito, fecha_solicitud)
           VALUES (900, 2, 100, 2, 'X', SYSTIMESTAMP)]', -20140);
    probar('Nadie aprueba su propia solicitud',
        q'[BEGIN
             INSERT INTO solicitud_ubicacion (id_solicitud, id_solicitante, id_taxon, id_departamento, proposito, fecha_solicitud)
             VALUES (900, 5, 107, 3, 'Monitoreo', SYSTIMESTAMP);
             UPDATE solicitud_ubicacion SET estado = 'aprobada' WHERE id_solicitud = 900;
           END;]', -20142, '5');
    probar('Aprueba un investigador habilitado del departamento',
        q'[UPDATE solicitud_ubicacion SET estado = 'aprobada' WHERE id_solicitud = 4]', -20141, '3');
    probar('Una solicitud pendiente por persona, especie y departamento',
        q'[INSERT INTO solicitud_ubicacion (id_solicitud, id_solicitante, id_taxon, id_departamento, proposito, fecha_solicitud)
           VALUES (900, 9, 109, 5, 'Otra vez', SYSTIMESTAMP)]', -1);

    DBMS_OUTPUT.PUT_LINE('=== F4. Apelaciones ===');
    probar('Solo se apela un avistamiento rechazado',
        q'[INSERT INTO apelacion (id_apelacion, id_avistamiento, argumento, fecha_apelacion)
           VALUES (900, 25, 'X', SYSTIMESTAMP)]', -20130, '2');
    probar('Solo el autor apela',
        q'[INSERT INTO apelacion (id_apelacion, id_avistamiento, argumento, fecha_apelacion)
           VALUES (900, 10, 'X', SYSTIMESTAMP)]', -20131, '1');
    probar('Plazo de apelacion vencido',
        q'[INSERT INTO apelacion (id_apelacion, id_avistamiento, argumento, fecha_apelacion)
           VALUES (900, 10, 'X', SYSTIMESTAMP)]', -20132, '6');
    probar('Una sola apelacion por avistamiento',
        q'[INSERT INTO apelacion (id_apelacion, id_avistamiento, argumento, fecha_apelacion)
           VALUES (900, 29, 'Otra vez', SYSTIMESTAMP)]', -1, '12');
    probar('No la resuelve quien rechazo',
        q'[UPDATE apelacion SET estado = 'desestimada', resolucion = 'X' WHERE id_apelacion = 2]', -20134, '5');
    probar('El autor no resuelve su apelacion',
        q'[UPDATE apelacion SET estado = 'aceptada', resolucion = 'X' WHERE id_apelacion = 2]', -20135, '12');
    probar('Una apelacion resuelta es definitiva',
        q'[UPDATE apelacion SET estado = 'desestimada' WHERE id_apelacion = 1]', -20136, '8');

    DBMS_OUTPUT.PUT_LINE('------------------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('Pruebas superadas: ' || v_ok || '   Fallidas: ' || v_mal);
END;
/
