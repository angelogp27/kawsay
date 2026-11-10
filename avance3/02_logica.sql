-- ============================================================
-- PROYECTO BD2 - Ciencia ciudadana de biodiversidad
-- 02 - FUNCIONES, PROCEDIMIENTOS, TRIGGERS Y VISTAS
-- Ejecutar despues de 01_tablas.sql y ANTES de 03_datos.sql:
-- la carga de datos usa sp_registrar_avistamiento y depende de los
-- triggers para generar auditoria, alertas, duplicados, consenso
-- y reputacion.
-- ============================================================
-- PARTE A. Reglas del modelo     (paquete pkg_bd2, 9 triggers, 1 procedimiento)
-- PARTE B. Funcionalidades       (paquete pkg_func, 8 triggers, 1 vista)
-- ============================================================
SET SQLBLANKLINES ON


-- ############################################################
-- PARTE A. REGLAS DEL MODELO
-- ############################################################

-- ------------------------------------------------------------
-- Paquete de apoyo
-- ------------------------------------------------------------
CREATE OR REPLACE PACKAGE pkg_bd2 AS
    -- TRUE mientras el propio sistema cambia un estado (consenso).
    g_sistema BOOLEAN := FALSE;

    FUNCTION departamento_de(p_ubicacion MDSYS.SDO_GEOMETRY) RETURN NUMBER;
    FUNCTION param(p_clave VARCHAR2) RETURN NUMBER;
    -- Observador que esta operando (DBMS_SESSION.SET_IDENTIFIER).
    FUNCTION actor_actual RETURN NUMBER;
    FUNCTION mes_en_rango(p_mes NUMBER, p_ini NUMBER, p_fin NUMBER) RETURN NUMBER;
END pkg_bd2;
/

CREATE OR REPLACE PACKAGE BODY pkg_bd2 AS
    FUNCTION departamento_de(p_ubicacion MDSYS.SDO_GEOMETRY) RETURN NUMBER IS
        v_id departamento.id_departamento%TYPE;
    BEGIN
        SELECT d.id_departamento INTO v_id
        FROM departamento d
        WHERE SDO_ANYINTERACT(d.poligono, p_ubicacion) = 'TRUE'
        FETCH FIRST 1 ROW ONLY;
        RETURN v_id;
    EXCEPTION WHEN NO_DATA_FOUND THEN RETURN NULL;
    END;

    FUNCTION param(p_clave VARCHAR2) RETURN NUMBER IS
        v NUMBER;
    BEGIN
        SELECT valor INTO v FROM parametro_sistema WHERE clave = p_clave;
        RETURN v;
    END;

    FUNCTION actor_actual RETURN NUMBER IS
    BEGIN
        RETURN TO_NUMBER(SYS_CONTEXT('USERENV', 'CLIENT_IDENTIFIER') DEFAULT NULL ON CONVERSION ERROR);
    END;

    -- 1 si el mes esta dentro del intervalo; soporta cruces de anio (11 -> 2).
    FUNCTION mes_en_rango(p_mes NUMBER, p_ini NUMBER, p_fin NUMBER) RETURN NUMBER IS
    BEGIN
        IF p_ini <= p_fin THEN
            RETURN CASE WHEN p_mes BETWEEN p_ini AND p_fin THEN 1 ELSE 0 END;
        END IF;
        RETURN CASE WHEN p_mes >= p_ini OR p_mes <= p_fin THEN 1 ELSE 0 END;
    END;
END pkg_bd2;
/

-- ------------------------------------------------------------
-- TAXON: el hijo debe tener un rango inferior al del padre.
-- Como el rango baja estrictamente en cada nivel, esta regla
-- hace IMPOSIBLE formar ciclos (resuelve RN15 sin recorrer el arbol).
-- Es COMPUESTO: un trigger de fila no puede leer su propia tabla en
-- un UPDATE (ORA-04091 mutating table); se valida al final de la sentencia.
-- ------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_taxon_jerarquia
FOR INSERT OR UPDATE OF id_taxon_padre, rango ON taxon
COMPOUND TRIGGER
    -- tipo de esquema para poder usarlo con TABLE() dentro de SQL
    g_ids SYS.ODCINUMBERLIST := SYS.ODCINUMBERLIST();

    AFTER EACH ROW IS
    BEGIN
        g_ids.EXTEND;
        g_ids(g_ids.LAST) := :NEW.id_taxon;
    END AFTER EACH ROW;

    AFTER STATEMENT IS
    BEGIN
        FOR r IN (
            SELECT h.nombre_cientifico hijo, h.rango rango_hijo, p.rango rango_padre
            FROM taxon h
            JOIN taxon p ON p.id_taxon = h.id_taxon_padre
            WHERE (h.id_taxon IN (SELECT COLUMN_VALUE FROM TABLE(g_ids))
                OR p.id_taxon IN (SELECT COLUMN_VALUE FROM TABLE(g_ids)))
              AND INSTR('reino,filo,clase,orden,familia,genero,especie', h.rango)
               <= INSTR('reino,filo,clase,orden,familia,genero,especie', p.rango)
            FETCH FIRST 1 ROW ONLY
        ) LOOP
            g_ids.DELETE;
            RAISE_APPLICATION_ERROR(-20001, 'El taxon ' || r.hijo || ' (' || r.rango_hijo ||
                ') no puede depender de un taxon de rango ' || r.rango_padre);
        END LOOP;
        g_ids.DELETE;
    END AFTER STATEMENT;
END trg_taxon_jerarquia;
/

-- ------------------------------------------------------------
-- ESPECIE: solo taxones de rango 'especie'.
-- ------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_especie_rango
BEFORE INSERT OR UPDATE OF id_taxon ON especie
FOR EACH ROW
DECLARE
    v_rango taxon.rango%TYPE;
BEGIN
    BEGIN
        SELECT rango INTO v_rango FROM taxon WHERE id_taxon = :NEW.id_taxon;
    EXCEPTION WHEN NO_DATA_FOUND THEN
        RETURN;   -- lo rechazara FK_ESPECIE_TAXON
    END;
    IF v_rango <> 'especie' THEN
        RAISE_APPLICATION_ERROR(-20002, 'Solo un taxon de rango especie puede registrarse en ESPECIE');
    END IF;
END;
/

-- ------------------------------------------------------------
-- AVISTAMIENTO (antes): campania y salida coherentes (RN24).
-- ------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_avistamiento_validar
BEFORE INSERT OR UPDATE OF id_campania, id_salida, fecha_hora_avistamiento, estado ON avistamiento
FOR EACH ROW
DECLARE
    v_ini DATE; v_fin DATE; v_obs NUMBER;
    v_s_ini TIMESTAMP; v_s_fin TIMESTAMP;
BEGIN
    -- Conflicto de interes: nadie valida su propio avistamiento.
    IF UPDATING AND NOT pkg_bd2.g_sistema
       AND pkg_bd2.actor_actual = :NEW.id_observador
       AND :NEW.estado <> :OLD.estado THEN
        RAISE_APPLICATION_ERROR(-20014, 'Un observador no puede cambiar el estado de su propio avistamiento');
    END IF;

    IF :NEW.id_campania IS NOT NULL THEN
        SELECT fecha_inicio, fecha_fin INTO v_ini, v_fin
        FROM campania WHERE id_campania = :NEW.id_campania;
        IF :NEW.fecha_hora_avistamiento < v_ini OR :NEW.fecha_hora_avistamiento >= v_fin + 1 THEN
            RAISE_APPLICATION_ERROR(-20010, 'El avistamiento ocurre fuera del periodo de la campania');
        END IF;
        -- RN30: solo los inscritos pueden aportar a una campania.
        SELECT COUNT(*) INTO v_obs FROM participacion_campania
        WHERE id_campania = :NEW.id_campania AND id_observador = :NEW.id_observador;
        IF v_obs = 0 THEN
            RAISE_APPLICATION_ERROR(-20013, 'El observador no esta inscrito en la campania');
        END IF;
    END IF;

    IF :NEW.id_salida IS NOT NULL THEN
        SELECT id_observador, fecha_hora_inicio, fecha_hora_fin INTO v_obs, v_s_ini, v_s_fin
        FROM salida_campo WHERE id_salida = :NEW.id_salida;
        IF v_obs <> :NEW.id_observador THEN
            RAISE_APPLICATION_ERROR(-20011, 'La salida de campo pertenece a otro observador');
        END IF;
        IF :NEW.fecha_hora_avistamiento NOT BETWEEN v_s_ini AND v_s_fin THEN
            RAISE_APPLICATION_ERROR(-20012, 'El avistamiento ocurre fuera del horario de la salida de campo');
        END IF;
    END IF;
END;
/

-- ------------------------------------------------------------
-- AVISTAMIENTO (despues): trigger compuesto.
--   * auditoria automatica de estados (RN28, RN29)
--   * alertas automaticas (RN19, RN20)
--   * reputacion al verificar (RN04)
--   * deteccion de duplicados (RN25, RN26) -> en AFTER STATEMENT
--     porque necesita leer AVISTAMIENTO (evita ORA-04091 mutating table)
-- ------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_avistamiento_eventos
FOR INSERT OR UPDATE OF estado, id_taxon_validado ON avistamiento
COMPOUND TRIGGER

    TYPE t_ids IS TABLE OF NUMBER;
    g_nuevos t_ids := t_ids();

    AFTER EACH ROW IS
        v_actor     NUMBER := pkg_bd2.actor_actual;
        v_tipo      VARCHAR2(20);
        v_resp      NUMBER;
        v_taxon     NUMBER := NVL(:NEW.id_taxon_validado, :NEW.id_taxon_propuesto);
        v_estado_c  especie.estado_conservacion%TYPE;
        v_depto     NUMBER;
        v_en_depto  NUMBER;
        v_en_mes    NUMBER;
        v_puntos    NUMBER;
        v_es_especie NUMBER;
        v_anterior  avistamiento.estado%TYPE;
        v_ya_pagado NUMBER;

        PROCEDURE crear_alerta(p_tipo VARCHAR2) IS
        BEGIN
            INSERT INTO alerta (id_alerta, id_avistamiento, id_investigador, tipo, fecha_generacion, estado)
            SELECT seq_alerta.NEXTVAL, :NEW.id_avistamiento, NULL, p_tipo, SYSTIMESTAMP, 'pendiente'
            FROM dual
            WHERE NOT EXISTS (SELECT 1 FROM alerta
                              WHERE id_avistamiento = :NEW.id_avistamiento AND tipo = p_tipo);
        END;
    BEGIN
        -- 1. Auditoria -------------------------------------------------
        IF INSERTING THEN
            v_tipo := 'observador'; v_resp := :NEW.id_observador;
        ELSIF pkg_bd2.g_sistema OR v_actor IS NULL THEN
            v_tipo := 'sistema';    v_resp := NULL;
        ELSE
            SELECT CASE WHEN COUNT(*) > 0 THEN 'investigador' ELSE 'observador' END
            INTO v_tipo FROM investigador WHERE id_observador = v_actor;
            v_resp := v_actor;
        END IF;

        IF INSERTING OR :OLD.estado <> :NEW.estado THEN
            v_anterior := CASE WHEN INSERTING THEN NULL ELSE :OLD.estado END;
            INSERT INTO auditoria_avistamiento (id_auditoria, id_avistamiento, id_observador_responsable,
                                                estado_anterior, estado_nuevo, tipo_actor, fecha_hora)
            VALUES (seq_auditoria.NEXTVAL, :NEW.id_avistamiento, v_resp,
                    v_anterior, :NEW.estado, v_tipo, SYSTIMESTAMP);
        END IF;

        -- 2. Alertas: al registrar y cada vez que cambia el taxon validado
        --    (p.ej. se propuso un genero y el consenso fijo una especie).
        IF INSERTING
           OR (:NEW.id_taxon_validado IS NOT NULL
               AND (:OLD.id_taxon_validado IS NULL OR :OLD.id_taxon_validado <> :NEW.id_taxon_validado)) THEN
            BEGIN
                SELECT estado_conservacion, 1 INTO v_estado_c, v_es_especie
                FROM especie WHERE id_taxon = v_taxon;
            EXCEPTION WHEN NO_DATA_FOUND THEN
                v_estado_c := NULL; v_es_especie := 0;   -- se propuso un genero/familia
            END;

            IF v_estado_c IN ('VU', 'EN', 'CR') THEN
                crear_alerta('especie_amenazada');
            END IF;

            v_depto := pkg_bd2.departamento_de(:NEW.ubicacion);
            IF v_es_especie = 1 THEN
                SELECT COUNT(*),
                       NVL(SUM(pkg_bd2.mes_en_rango(EXTRACT(MONTH FROM :NEW.fecha_hora_avistamiento),
                                                    mes_inicio, mes_fin)), 0)
                INTO v_en_depto, v_en_mes
                FROM presencia_esperada
                WHERE id_taxon = v_taxon AND id_departamento = v_depto;

                IF v_en_depto = 0 THEN
                    crear_alerta('fuera_rango_geografico');
                ELSIF v_en_mes = 0 THEN
                    crear_alerta('fuera_temporada');
                END IF;
            END IF;

            IF INSERTING THEN
                g_nuevos.EXTEND;
                g_nuevos(g_nuevos.LAST) := :NEW.id_avistamiento;
            END IF;
        END IF;

        -- 3. Reputacion al pasar a verificado --------------------------
        --    Autor: puntos completos si acerto la especie, la mitad si
        --    acerto el genero (propuso el padre del taxon validado).
        --    Solo la PRIMERA vez que se verifica (si vuelve a verificado tras
        --    un reporte improcedente o una apelacion, no se paga de nuevo).
        IF UPDATING AND :NEW.estado = 'verificado' AND :OLD.estado <> 'verificado' THEN
          SELECT COUNT(*) INTO v_ya_pagado FROM evento_reputacion
          WHERE id_avistamiento = :NEW.id_avistamiento
            AND motivo IN ('avistamiento_verificado', 'identificacion_acertada');
          IF v_ya_pagado = 0 THEN
            SELECT CASE
                     WHEN :NEW.id_taxon_validado = :NEW.id_taxon_propuesto THEN 1
                     WHEN MAX(id_taxon_padre) = :NEW.id_taxon_propuesto THEN 0.5
                     ELSE 0 END * pkg_bd2.param('PUNTOS_VERIFICADO')
            INTO v_puntos
            FROM taxon WHERE id_taxon = :NEW.id_taxon_validado;

            IF v_puntos > 0 THEN
                INSERT INTO evento_reputacion VALUES (seq_evento_rep.NEXTVAL, :NEW.id_observador,
                    :NEW.id_avistamiento, 'avistamiento_verificado', v_puntos, SYSTIMESTAMP);
                UPDATE observador SET reputacion = reputacion + v_puntos
                WHERE id_observador = :NEW.id_observador;
            END IF;

            v_puntos := pkg_bd2.param('PUNTOS_IDENTIFICACION_OK');
            FOR r IN (SELECT id_observador FROM identificacion
                      WHERE id_avistamiento = :NEW.id_avistamiento
                        AND id_taxon_propuesto = :NEW.id_taxon_validado) LOOP
                INSERT INTO evento_reputacion VALUES (seq_evento_rep.NEXTVAL, r.id_observador,
                    :NEW.id_avistamiento, 'identificacion_acertada', v_puntos, SYSTIMESTAMP);
                UPDATE observador SET reputacion = reputacion + v_puntos
                WHERE id_observador = r.id_observador;
            END LOOP;
          END IF;
        END IF;
    END AFTER EACH ROW;

    AFTER STATEMENT IS
        v_dist NUMBER := pkg_bd2.param('DUPLICADO_DISTANCIA_M');
        v_min  NUMBER := pkg_bd2.param('DUPLICADO_MINUTOS');
    BEGIN
        FOR i IN 1 .. g_nuevos.COUNT LOOP
            INSERT INTO duplicado_candidato (id_avistamiento_a, id_avistamiento_b,
                                             distancia_metros, diferencia_minutos, estado)
            SELECT LEAST(n.id_avistamiento, o.id_avistamiento),
                   GREATEST(n.id_avistamiento, o.id_avistamiento),
                   ROUND(SDO_GEOM.SDO_DISTANCE(n.ubicacion, o.ubicacion, 0.005, 'unit=M'), 2),
                   ROUND(ABS(CAST(n.fecha_hora_avistamiento AS DATE)
                           - CAST(o.fecha_hora_avistamiento AS DATE)) * 1440),
                   'pendiente'
            FROM avistamiento n
            JOIN avistamiento o
              ON o.id_avistamiento    <> n.id_avistamiento
             AND o.id_taxon_propuesto  = n.id_taxon_propuesto
             AND o.id_observador      <> n.id_observador
            WHERE n.id_avistamiento = g_nuevos(i)
              AND SDO_WITHIN_DISTANCE(o.ubicacion, n.ubicacion,
                                      'distance=' || v_dist || ' unit=M') = 'TRUE'
              AND ABS(CAST(n.fecha_hora_avistamiento AS DATE)
                    - CAST(o.fecha_hora_avistamiento AS DATE)) * 1440 < v_min
              AND NOT EXISTS (SELECT 1 FROM duplicado_candidato d
                              WHERE d.id_avistamiento_a = LEAST(n.id_avistamiento, o.id_avistamiento)
                                AND d.id_avistamiento_b = GREATEST(n.id_avistamiento, o.id_avistamiento));
        END LOOP;
        g_nuevos.DELETE;
    END AFTER STATEMENT;
END trg_avistamiento_eventos;
/

-- ------------------------------------------------------------
-- IDENTIFICACION: el autor no puede identificar lo suyo (RN12)
-- ni identificar algo antes de que exista.
-- ------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_identificacion_validar
BEFORE INSERT OR UPDATE ON identificacion
FOR EACH ROW
DECLARE
    v_autor NUMBER; v_fecha TIMESTAMP;
BEGIN
    SELECT id_observador, fecha_hora_avistamiento INTO v_autor, v_fecha
    FROM avistamiento WHERE id_avistamiento = :NEW.id_avistamiento;
    IF v_autor = :NEW.id_observador THEN
        RAISE_APPLICATION_ERROR(-20020, 'El autor no puede identificar su propio avistamiento');
    END IF;
    IF :NEW.fecha < v_fecha THEN
        RAISE_APPLICATION_ERROR(-20021, 'La identificacion no puede ser anterior al avistamiento');
    END IF;
END;
/

-- ------------------------------------------------------------
-- IDENTIFICACION: consenso automatico (RN13, RN14).
-- Compuesto porque debe contar filas de la misma tabla.
-- ------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_identificacion_consenso
FOR INSERT OR UPDATE OF id_taxon_propuesto ON identificacion
COMPOUND TRIGGER
    TYPE t_ids IS TABLE OF NUMBER;
    g_avist t_ids := t_ids();

    AFTER EACH ROW IS
    BEGIN
        g_avist.EXTEND;
        g_avist(g_avist.LAST) := :NEW.id_avistamiento;
    END AFTER EACH ROW;

    AFTER STATEMENT IS
        v_umbral   NUMBER := pkg_bd2.param('UMBRAL_CONSENSO');
        v_taxon    NUMBER;
        v_abiertas NUMBER;
    BEGIN
        FOR i IN 1 .. g_avist.COUNT LOOP
            BEGIN
                SELECT i2.id_taxon_propuesto INTO v_taxon
                FROM identificacion i2
                JOIN avistamiento a ON a.id_avistamiento = i2.id_avistamiento
                WHERE i2.id_avistamiento = g_avist(i)
                  AND a.estado IN ('pendiente', 'dudoso')
                GROUP BY i2.id_taxon_propuesto
                HAVING COUNT(*) >= v_umbral
                ORDER BY COUNT(*) DESC
                FETCH FIRST 1 ROW ONLY;

                pkg_bd2.g_sistema := TRUE;
                -- Paso 1: fijar el taxon (esto re-evalua las alertas con la especie consensuada)
                UPDATE avistamiento
                SET id_taxon_validado = v_taxon, metodo_validacion = 'consenso'
                WHERE id_avistamiento = g_avist(i);

                -- Paso 2: RN19 -> si hay alertas abiertas, el consenso NO basta:
                --         queda 'dudoso' a la espera de un investigador.
                SELECT COUNT(*) INTO v_abiertas FROM alerta
                WHERE id_avistamiento = g_avist(i) AND estado IN ('pendiente', 'asignada');

                UPDATE avistamiento
                SET estado = CASE WHEN v_abiertas > 0 THEN 'dudoso' ELSE 'verificado' END
                WHERE id_avistamiento = g_avist(i);
                pkg_bd2.g_sistema := FALSE;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN NULL;     -- aun no hay consenso
                WHEN OTHERS THEN pkg_bd2.g_sistema := FALSE; RAISE;
            END;
        END LOOP;
        g_avist.DELETE;
    END AFTER STATEMENT;
END trg_identificacion_consenso;
/

-- ------------------------------------------------------------
-- ALERTA: solo puede asumirla un investigador del departamento
-- donde ocurrio el avistamiento (RN22).
-- ------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_alerta_territorio
BEFORE INSERT OR UPDATE OF id_investigador, estado ON alerta
FOR EACH ROW
DECLARE
    v_depto_avist NUMBER; v_depto_inv NUMBER; v_ubic MDSYS.SDO_GEOMETRY; v_autor NUMBER;
BEGIN
    IF :NEW.id_investigador IS NOT NULL THEN
        SELECT ubicacion, id_observador INTO v_ubic, v_autor
        FROM avistamiento WHERE id_avistamiento = :NEW.id_avistamiento;
        IF v_autor = :NEW.id_investigador THEN
            RAISE_APPLICATION_ERROR(-20031, 'Un investigador no puede revisar su propio avistamiento');
        END IF;
        v_depto_avist := pkg_bd2.departamento_de(v_ubic);
        SELECT id_departamento INTO v_depto_inv FROM investigador WHERE id_observador = :NEW.id_investigador;
        IF v_depto_inv IS NULL OR v_depto_inv <> v_depto_avist THEN
            RAISE_APPLICATION_ERROR(-20030, 'El investigador no esta asignado al departamento del avistamiento');
        END IF;
        IF :NEW.estado = 'pendiente' THEN
            :NEW.estado := 'asignada';
        END IF;
    END IF;
    IF :NEW.estado IN ('resuelta', 'descartada') AND :NEW.fecha_resolucion IS NULL THEN
        :NEW.fecha_resolucion := SYSTIMESTAMP;
    END IF;
END;
/

-- ------------------------------------------------------------
-- AUDITORIA: inmutable (RN28).
-- ------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_auditoria_inmutable
BEFORE UPDATE OR DELETE ON auditoria_avistamiento
BEGIN
    RAISE_APPLICATION_ERROR(-20040, 'AUDITORIA_AVISTAMIENTO es inmutable: solo se permiten inserciones');
END;
/

-- ------------------------------------------------------------
-- PROCEDIMIENTO: registrar avistamiento + evidencia en una sola
-- transaccion. Asi se garantiza RN07 (al menos una evidencia).
-- ------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_registrar_avistamiento (
    p_id_avistamiento  IN NUMBER,
    p_id_observador    IN NUMBER,
    p_id_taxon         IN NUMBER,
    p_lon              IN NUMBER,
    p_lat              IN NUMBER,
    p_fecha_hora       IN TIMESTAMP,
    p_individuos       IN NUMBER,
    p_notas            IN VARCHAR2,
    p_id_evidencia     IN NUMBER,
    p_tipo_evidencia   IN VARCHAR2,
    p_recurso          IN VARCHAR2,
    p_hash             IN VARCHAR2,
    p_id_campania      IN NUMBER DEFAULT NULL,
    p_id_salida        IN NUMBER DEFAULT NULL
) AS
BEGIN
    IF p_recurso IS NULL OR p_hash IS NULL THEN
        RAISE_APPLICATION_ERROR(-20050, 'Todo avistamiento requiere al menos una evidencia (RN07)');
    END IF;

    INSERT INTO avistamiento (id_avistamiento, id_observador, id_taxon_propuesto, id_taxon_validado,
                              id_campania, id_salida, ubicacion, fecha_hora_avistamiento,
                              numero_individuos, notas, estado, metodo_validacion)
    VALUES (p_id_avistamiento, p_id_observador, p_id_taxon, NULL, p_id_campania, p_id_salida,
            MDSYS.SDO_GEOMETRY(2001, 4326, MDSYS.SDO_POINT_TYPE(p_lon, p_lat, NULL), NULL, NULL),
            p_fecha_hora, p_individuos, p_notas, 'pendiente', NULL);

    INSERT INTO evidencia (id_evidencia, id_avistamiento, tipo, ubicacion_recurso, hash_archivo, fecha_carga)
    VALUES (p_id_evidencia, p_id_avistamiento, p_tipo_evidencia, p_recurso, p_hash, p_fecha_hora);
END;
/


-- ############################################################
-- PARTE B. FUNCIONALIDADES
-- ############################################################

-- ------------------------------------------------------------
-- Paquete de apoyo
-- ------------------------------------------------------------
CREATE OR REPLACE PACKAGE pkg_func AS
    -- TRUE mientras una apelacion aceptada revierte reportes.
    g_apelacion BOOLEAN := FALSE;

    -- 1 si el investigador tiene colegiatura verificada y vigente.
    FUNCTION credencial_vigente(p_inv NUMBER) RETURN NUMBER;

    -- 1 si p_inv puede revisar asuntos del departamento p_depto.
    --   Siempre: investigador con credencial vigente.
    --   Regla: debe ser del departamento. Con p_respaldo = 1, si el
    --   departamento no tiene OTRO investigador habilitado (distinto
    --   de p_excluir), puede hacerlo uno con territorio de otro lugar.
    FUNCTION puede_revisar(p_inv NUMBER, p_depto NUMBER,
                           p_respaldo NUMBER DEFAULT 0, p_excluir NUMBER DEFAULT NULL) RETURN NUMBER;

    -- Ultimo rechazo de un avistamiento segun la auditoria.
    PROCEDURE ultimo_rechazo(p_avist NUMBER, o_responsable OUT NUMBER,
                             o_fecha OUT TIMESTAMP, o_estado_previo OUT VARCHAR2);

    PROCEDURE ajustar_reputacion(p_obs NUMBER, p_avist NUMBER, p_motivo VARCHAR2, p_puntos NUMBER);
END pkg_func;
/

CREATE OR REPLACE PACKAGE BODY pkg_func AS
    FUNCTION credencial_vigente(p_inv NUMBER) RETURN NUMBER IS
        v NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v FROM credencial
        WHERE id_observador = p_inv AND tipo = 'colegiatura'
          AND estado_verificacion = 'verificada' AND fecha_vencimiento >= TRUNC(SYSDATE);
        RETURN CASE WHEN v > 0 THEN 1 ELSE 0 END;
    END;

    FUNCTION puede_revisar(p_inv NUMBER, p_depto NUMBER,
                           p_respaldo NUMBER DEFAULT 0, p_excluir NUMBER DEFAULT NULL) RETURN NUMBER IS
        v_depto_inv NUMBER; v_locales NUMBER;
    BEGIN
        SELECT id_departamento INTO v_depto_inv FROM investigador WHERE id_observador = p_inv;
        IF credencial_vigente(p_inv) = 0 OR v_depto_inv IS NULL THEN
            RETURN 0;
        END IF;
        IF v_depto_inv = p_depto THEN
            RETURN 1;
        END IF;
        IF p_respaldo = 1 THEN
            SELECT COUNT(*) INTO v_locales FROM investigador i
            WHERE i.id_departamento = p_depto
              AND i.id_observador <> NVL(p_excluir, -1)
              AND credencial_vigente(i.id_observador) = 1;
            RETURN CASE WHEN v_locales = 0 THEN 1 ELSE 0 END;
        END IF;
        RETURN 0;
    EXCEPTION WHEN NO_DATA_FOUND THEN RETURN 0;
    END;

    PROCEDURE ultimo_rechazo(p_avist NUMBER, o_responsable OUT NUMBER,
                             o_fecha OUT TIMESTAMP, o_estado_previo OUT VARCHAR2) IS
    BEGIN
        SELECT id_observador_responsable, fecha_hora, estado_anterior
        INTO o_responsable, o_fecha, o_estado_previo
        FROM auditoria_avistamiento
        WHERE id_avistamiento = p_avist AND estado_nuevo = 'rechazado'
        ORDER BY fecha_hora DESC, id_auditoria DESC
        FETCH FIRST 1 ROW ONLY;
    EXCEPTION WHEN NO_DATA_FOUND THEN
        o_responsable := NULL; o_fecha := NULL; o_estado_previo := NULL;
    END;

    PROCEDURE ajustar_reputacion(p_obs NUMBER, p_avist NUMBER, p_motivo VARCHAR2, p_puntos NUMBER) IS
    BEGIN
        IF p_puntos = 0 THEN RETURN; END IF;
        INSERT INTO evento_reputacion (id_evento, id_observador, id_avistamiento, motivo, puntos, fecha)
        VALUES (seq_evento_rep.NEXTVAL, p_obs, p_avist, p_motivo, p_puntos, SYSTIMESTAMP);
        UPDATE observador SET reputacion = reputacion + p_puntos WHERE id_observador = p_obs;
    END;
END pkg_func;
/

-- ============================================================
-- Investigador suspendido: sin colegiatura vigente no puede
-- asumir alertas (se ejecuta despues de la regla territorial).
-- ============================================================
CREATE OR REPLACE TRIGGER trg_alerta_credencial
BEFORE INSERT OR UPDATE OF id_investigador ON alerta
FOR EACH ROW
FOLLOWS trg_alerta_territorio
WHEN (NEW.id_investigador IS NOT NULL)
BEGIN
    IF (INSERTING OR NVL(:OLD.id_investigador, -1) <> :NEW.id_investigador)
       AND pkg_func.credencial_vigente(:NEW.id_investigador) = 0 THEN
        RAISE_APPLICATION_ERROR(-20110, 'El investigador no tiene colegiatura verificada y vigente');
    END IF;
END;
/

-- ============================================================
-- F1. CREDENCIAL: verificacion
-- ============================================================
CREATE OR REPLACE TRIGGER trg_credencial_verificar
BEFORE INSERT OR UPDATE OF estado_verificacion, id_verificador ON credencial
FOR EACH ROW
DECLARE
    v NUMBER;
BEGIN
    IF :NEW.estado_verificacion <> 'pendiente' THEN
        :NEW.id_verificador := NVL(:NEW.id_verificador, pkg_bd2.actor_actual);
        :NEW.fecha_verificacion := NVL(:NEW.fecha_verificacion, SYSTIMESTAMP);
        IF :NEW.id_verificador = :NEW.id_observador THEN
            RAISE_APPLICATION_ERROR(-20109, 'Nadie puede verificar sus propias credenciales');
        END IF;
        SELECT COUNT(*) INTO v FROM investigador WHERE id_observador = :NEW.id_verificador;
        IF v = 0 THEN
            RAISE_APPLICATION_ERROR(-20109, 'Solo un investigador puede verificar credenciales');
        END IF;
    END IF;
END;
/

-- ============================================================
-- F1. POSTULACION: elegibilidad, evaluacion y requisitos
-- ============================================================
CREATE OR REPLACE TRIGGER trg_postulacion_validar
BEFORE INSERT OR UPDATE OF estado, id_evaluador ON postulacion_investigador
FOR EACH ROW
DECLARE
    v NUMBER; v_fecha DATE; v_faltan VARCHAR2(200);
BEGIN
    IF INSERTING THEN
        SELECT COUNT(*) INTO v FROM investigador WHERE id_observador = :NEW.id_observador;
        IF v > 0 THEN
            RAISE_APPLICATION_ERROR(-20101, 'El observador ya es investigador');
        END IF;

        SELECT fecha_registro INTO v_fecha FROM observador WHERE id_observador = :NEW.id_observador;
        IF CAST(:NEW.fecha_postulacion AS DATE) - v_fecha < pkg_bd2.param('POSTULACION_MIN_DIAS') THEN
            RAISE_APPLICATION_ERROR(-20102, 'Antiguedad insuficiente: se requieren '
                || pkg_bd2.param('POSTULACION_MIN_DIAS') || ' dias en la plataforma');
        END IF;

        -- Identificaciones que coinciden con el taxon finalmente validado
        SELECT COUNT(*) INTO v
        FROM identificacion i JOIN avistamiento a ON a.id_avistamiento = i.id_avistamiento
        WHERE i.id_observador = :NEW.id_observador
          AND i.id_taxon_propuesto = a.id_taxon_validado;
        IF v < pkg_bd2.param('POSTULACION_MIN_IDENTIF_OK') THEN
            RAISE_APPLICATION_ERROR(-20103, 'Experiencia insuficiente: ' || v || ' de '
                || pkg_bd2.param('POSTULACION_MIN_IDENTIF_OK') || ' identificaciones acertadas');
        END IF;

        SELECT COUNT(*) INTO v
        FROM reporte_avistamiento r JOIN avistamiento a ON a.id_avistamiento = r.id_avistamiento
        WHERE a.id_observador = :NEW.id_observador AND r.estado = 'procedente'
          AND r.fecha_resolucion >= :NEW.fecha_postulacion - NUMTODSINTERVAL(pkg_bd2.param('POSTULACION_DIAS_SIN_REPORTE'), 'DAY');
        IF v > 0 THEN
            RAISE_APPLICATION_ERROR(-20104, 'Tiene reportes procedentes en su contra en el periodo reciente');
        END IF;
        RETURN;
    END IF;

    -- Evaluacion
    IF :NEW.estado <> 'pendiente' THEN
        IF :NEW.id_evaluador = :NEW.id_observador THEN
            RAISE_APPLICATION_ERROR(-20105, 'Nadie evalua su propia postulacion');
        END IF;
        IF pkg_func.puede_revisar(:NEW.id_evaluador, :NEW.id_departamento, 1) = 0 THEN
            RAISE_APPLICATION_ERROR(-20106, 'El evaluador no esta habilitado para ese departamento');
        END IF;
    END IF;

    IF :NEW.estado IN ('aprobada', 'rechazada') THEN
        :NEW.fecha_resolucion := NVL(:NEW.fecha_resolucion, SYSTIMESTAMP);
    END IF;

    IF :NEW.estado = 'aprobada' THEN
        -- A. Obligatorios: grado/titulo, colegiatura vigente, carta institucional
        -- NVL: sin ninguna credencial, SUM() devuelve NULL (y NULL = 0 no es verdadero)
        SELECT RTRIM(
                 CASE WHEN NVL(SUM(CASE WHEN tipo IN ('grado_bachiller','titulo_profesional','grado_maestria','grado_doctor')
                                    THEN 1 ELSE 0 END), 0) = 0 THEN 'grado o titulo, ' END ||
                 CASE WHEN NVL(SUM(CASE WHEN tipo = 'colegiatura' AND fecha_vencimiento >= TRUNC(SYSDATE)
                                    THEN 1 ELSE 0 END), 0) = 0 THEN 'colegiatura vigente, ' END ||
                 CASE WHEN NVL(SUM(CASE WHEN tipo = 'carta_institucional' THEN 1 ELSE 0 END), 0) = 0
                      THEN 'carta institucional, ' END, ', ')
        INTO v_faltan
        FROM credencial
        WHERE id_observador = :NEW.id_observador AND estado_verificacion = 'verificada';
        IF v_faltan IS NOT NULL THEN
            RAISE_APPLICATION_ERROR(-20107, 'Faltan credenciales verificadas: ' || v_faltan);
        END IF;

        -- B. Acreditar investigacion: RENACYT, posgrado o autorizacion SERFOR
        SELECT COUNT(*) INTO v FROM credencial
        WHERE id_observador = :NEW.id_observador AND estado_verificacion = 'verificada'
          AND (tipo IN ('grado_maestria', 'grado_doctor')
               OR (tipo IN ('renacyt', 'autorizacion_serfor') AND fecha_vencimiento >= TRUNC(SYSDATE)));
        IF v = 0 THEN
            RAISE_APPLICATION_ERROR(-20108, 'Debe acreditar investigacion: RENACYT, maestria/doctorado o autorizacion SERFOR vigente');
        END IF;
    END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_postulacion_aprobada
AFTER UPDATE OF estado ON postulacion_investigador
FOR EACH ROW
WHEN (NEW.estado = 'aprobada' AND OLD.estado <> 'aprobada')
BEGIN
    INSERT INTO investigador (id_observador, id_departamento)
    VALUES (:NEW.id_observador, :NEW.id_departamento);
END;
/

-- ============================================================
-- F2. REPORTE: validaciones por fila
-- ============================================================
CREATE OR REPLACE TRIGGER trg_reporte_validar
BEFORE INSERT OR UPDATE OF estado ON reporte_avistamiento
FOR EACH ROW
DECLARE
    v_autor NUMBER; v_estado VARCHAR2(20); v_ubic MDSYS.SDO_GEOMETRY;
BEGIN
    SELECT id_observador, estado, ubicacion INTO v_autor, v_estado, v_ubic
    FROM avistamiento WHERE id_avistamiento = :NEW.id_avistamiento;

    IF INSERTING THEN
        IF v_autor = :NEW.id_reportante THEN
            RAISE_APPLICATION_ERROR(-20120, 'No se puede reportar un avistamiento propio');
        END IF;
        IF v_estado = 'rechazado' THEN
            RAISE_APPLICATION_ERROR(-20121, 'El avistamiento ya esta rechazado');
        END IF;
        RETURN;
    END IF;

    IF :OLD.estado = 'pendiente' AND :NEW.estado <> 'pendiente' THEN
        IF :NEW.id_investigador IS NULL THEN
            :NEW.id_investigador := pkg_bd2.actor_actual;
        END IF;
        IF :NEW.id_investigador IN (v_autor, :NEW.id_reportante)
           OR pkg_func.puede_revisar(:NEW.id_investigador, pkg_bd2.departamento_de(v_ubic)) = 0 THEN
            RAISE_APPLICATION_ERROR(-20122, 'Solo un investigador habilitado del departamento, ajeno al caso, resuelve reportes');
        END IF;
        :NEW.fecha_resolucion := NVL(:NEW.fecha_resolucion, SYSTIMESTAMP);
    ELSIF :OLD.estado <> :NEW.estado AND NOT (pkg_func.g_apelacion AND :NEW.estado = 'improcedente') THEN
        RAISE_APPLICATION_ERROR(-20123, 'Un reporte resuelto solo puede revertirse mediante una apelacion aceptada');
    END IF;
END;
/

-- ============================================================
-- F2. REPORTE: efectos (compuesto: cuenta filas de la misma tabla)
--   * umbral de reportes  -> avistamiento 'dudoso' + alerta
--   * reporte procedente  -> avistamiento 'rechazado', penaliza al
--                            autor, premia al reportante
--   * todos improcedentes -> se restaura el estado previo
-- ============================================================
CREATE OR REPLACE TRIGGER trg_reporte_efectos
FOR INSERT OR UPDATE OF estado ON reporte_avistamiento
COMPOUND TRIGGER
    g_avist  SYS.ODCINUMBERLIST := SYS.ODCINUMBERLIST();
    g_premio SYS.ODCINUMBERLIST := SYS.ODCINUMBERLIST();   -- reportes que se volvieron procedentes

    AFTER EACH ROW IS
    BEGIN
        -- (RETURN no esta permitido en triggers compuestos: se usa IF)
        IF NOT pkg_func.g_apelacion THEN
            IF INSERTING OR :OLD.estado = 'pendiente' THEN
                g_avist.EXTEND; g_avist(g_avist.LAST) := :NEW.id_avistamiento;
            END IF;
            IF UPDATING AND :OLD.estado = 'pendiente' AND :NEW.estado = 'procedente' THEN
                g_premio.EXTEND; g_premio(g_premio.LAST) := :NEW.id_reporte;
            END IF;
        END IF;
    END AFTER EACH ROW;

    AFTER STATEMENT IS
        v_estado     VARCHAR2(20);
        v_autor      NUMBER;
        v_pend       NUMBER;
        v_proc       NUMBER;
        v_primer     TIMESTAMP;
        v_previo     VARCHAR2(20);
        v_inv        NUMBER;
        v_ya         NUMBER;
        v_rep        NUMBER;
    BEGIN
        FOR i IN 1 .. g_avist.COUNT LOOP
            SELECT estado, id_observador INTO v_estado, v_autor
            FROM avistamiento WHERE id_avistamiento = g_avist(i);

            SELECT SUM(CASE WHEN estado = 'pendiente'  THEN 1 ELSE 0 END),
                   SUM(CASE WHEN estado = 'procedente' THEN 1 ELSE 0 END),
                   MIN(fecha_reporte),
                   MAX(CASE WHEN estado <> 'pendiente' THEN id_investigador END)
            INTO v_pend, v_proc, v_primer, v_inv
            FROM reporte_avistamiento WHERE id_avistamiento = g_avist(i);

            IF v_proc > 0 AND v_estado <> 'rechazado' THEN
                -- Procedente: rechazo (lo registra la auditoria como accion del investigador)
                UPDATE avistamiento SET estado = 'rechazado' WHERE id_avistamiento = g_avist(i);

                SELECT COUNT(*) INTO v_ya FROM evento_reputacion
                WHERE id_avistamiento = g_avist(i) AND motivo = 'penalizacion_reporte';
                IF v_ya = 0 THEN
                    SELECT LEAST(pkg_bd2.param('PUNTOS_PENALIZACION_REPORTE'), reputacion) INTO v_rep
                    FROM observador WHERE id_observador = v_autor;
                    pkg_func.ajustar_reputacion(v_autor, g_avist(i), 'penalizacion_reporte', -v_rep);
                END IF;

                UPDATE alerta SET id_investigador = v_inv, estado = 'resuelta'
                WHERE id_avistamiento = g_avist(i) AND tipo = 'reporte_comunidad'
                  AND estado IN ('pendiente', 'asignada');

            ELSIF v_pend = 0 AND v_proc = 0 THEN
                -- Todos improcedentes: cerrar alerta y restaurar el estado anterior
                -- SOLO si fueron los reportes los que lo pasaron a 'dudoso'.
                UPDATE alerta SET id_investigador = v_inv, estado = 'descartada'
                WHERE id_avistamiento = g_avist(i) AND tipo = 'reporte_comunidad'
                  AND estado IN ('pendiente', 'asignada');
                BEGIN
                    SELECT estado_anterior INTO v_previo FROM auditoria_avistamiento
                    WHERE id_avistamiento = g_avist(i) AND estado_nuevo = 'dudoso'
                      AND tipo_actor = 'sistema' AND fecha_hora >= v_primer
                    ORDER BY fecha_hora DESC, id_auditoria DESC FETCH FIRST 1 ROW ONLY;
                    IF v_estado = 'dudoso' THEN
                        pkg_bd2.g_sistema := TRUE;
                        UPDATE avistamiento SET estado = v_previo WHERE id_avistamiento = g_avist(i);
                        pkg_bd2.g_sistema := FALSE;
                    END IF;
                EXCEPTION WHEN NO_DATA_FOUND THEN NULL;
                END;

            ELSIF v_pend >= pkg_bd2.param('REPORTES_UMBRAL') THEN
                -- Umbral alcanzado: a revision
                IF v_estado IN ('pendiente', 'verificado') THEN
                    pkg_bd2.g_sistema := TRUE;
                    UPDATE avistamiento SET estado = 'dudoso' WHERE id_avistamiento = g_avist(i);
                    pkg_bd2.g_sistema := FALSE;
                END IF;
                INSERT INTO alerta (id_alerta, id_avistamiento, id_investigador, tipo, fecha_generacion, estado)
                SELECT seq_alerta.NEXTVAL, g_avist(i), NULL, 'reporte_comunidad', SYSTIMESTAMP, 'pendiente'
                FROM dual
                WHERE NOT EXISTS (SELECT 1 FROM alerta
                                  WHERE id_avistamiento = g_avist(i) AND tipo = 'reporte_comunidad');
            END IF;
        END LOOP;

        FOR r IN (SELECT id_reportante, id_avistamiento FROM reporte_avistamiento
                  WHERE id_reporte IN (SELECT COLUMN_VALUE FROM TABLE(g_premio))) LOOP
            pkg_func.ajustar_reputacion(r.id_reportante, r.id_avistamiento, 'reporte_procedente',
                                        pkg_bd2.param('PUNTOS_REPORTE_PROCEDENTE'));
        END LOOP;

        g_avist.DELETE; g_premio.DELETE;
    EXCEPTION WHEN OTHERS THEN
        pkg_bd2.g_sistema := FALSE; g_avist.DELETE; g_premio.DELETE; RAISE;
    END AFTER STATEMENT;
END trg_reporte_efectos;
/

-- ============================================================
-- F3. SOLICITUD DE UBICACION
-- ============================================================
CREATE OR REPLACE TRIGGER trg_solicitud_validar
BEFORE INSERT OR UPDATE OF estado, id_aprobador ON solicitud_ubicacion
FOR EACH ROW
DECLARE
    v_uicn especie.estado_conservacion%TYPE;
BEGIN
    IF INSERTING THEN
        SELECT estado_conservacion INTO v_uicn FROM especie WHERE id_taxon = :NEW.id_taxon;
        IF NVL(v_uicn, 'LC') NOT IN ('CR', 'EN') THEN
            RAISE_APPLICATION_ERROR(-20140, 'Solo se solicita ubicacion exacta de especies CR o EN; las demas son publicas');
        END IF;
    END IF;

    IF :NEW.estado <> 'pendiente' AND (INSERTING OR :OLD.estado = 'pendiente') THEN
        :NEW.id_aprobador := NVL(:NEW.id_aprobador, pkg_bd2.actor_actual);
        IF :NEW.id_aprobador = :NEW.id_solicitante THEN
            RAISE_APPLICATION_ERROR(-20142, 'Nadie aprueba su propia solicitud');
        END IF;
        IF pkg_func.puede_revisar(:NEW.id_aprobador, :NEW.id_departamento, 1) = 0 THEN
            RAISE_APPLICATION_ERROR(-20141, 'El aprobador no esta habilitado para ese departamento');
        END IF;
        :NEW.fecha_resolucion := NVL(:NEW.fecha_resolucion, SYSTIMESTAMP);
        IF :NEW.estado = 'aprobada' AND :NEW.vigente_hasta IS NULL THEN
            :NEW.vigente_hasta := TRUNC(CAST(:NEW.fecha_resolucion AS DATE)) + pkg_bd2.param('UBICACION_VIGENCIA_DIAS');
        END IF;
    END IF;
END;
/

-- ============================================================
-- F4. APELACION: presentacion y resolucion
-- ============================================================
CREATE OR REPLACE TRIGGER trg_apelacion_validar
BEFORE INSERT OR UPDATE OF estado, id_investigador ON apelacion
FOR EACH ROW
DECLARE
    v_autor NUMBER; v_estado VARCHAR2(20); v_ubic MDSYS.SDO_GEOMETRY;
    v_rechazo_por NUMBER; v_rechazo_fecha TIMESTAMP; v_previo VARCHAR2(20);
BEGIN
    SELECT id_observador, estado, ubicacion INTO v_autor, v_estado, v_ubic
    FROM avistamiento WHERE id_avistamiento = :NEW.id_avistamiento;
    pkg_func.ultimo_rechazo(:NEW.id_avistamiento, v_rechazo_por, v_rechazo_fecha, v_previo);

    IF INSERTING THEN
        IF v_estado <> 'rechazado' THEN
            RAISE_APPLICATION_ERROR(-20130, 'Solo se apela un avistamiento rechazado');
        END IF;
        IF NVL(pkg_bd2.actor_actual, -1) <> v_autor THEN
            RAISE_APPLICATION_ERROR(-20131, 'Solo el autor puede apelar su avistamiento');
        END IF;
        IF :NEW.fecha_apelacion > v_rechazo_fecha + NUMTODSINTERVAL(pkg_bd2.param('APELACION_PLAZO_DIAS'), 'DAY') THEN
            RAISE_APPLICATION_ERROR(-20132, 'Vencio el plazo de ' || pkg_bd2.param('APELACION_PLAZO_DIAS')
                || ' dias para apelar (rechazo: ' || TO_CHAR(v_rechazo_fecha, 'YYYY-MM-DD') || ')');
        END IF;
        RETURN;
    END IF;

    IF :NEW.estado <> 'pendiente' AND :OLD.estado = 'pendiente' THEN
        :NEW.id_investigador := NVL(:NEW.id_investigador, pkg_bd2.actor_actual);
        IF :NEW.id_investigador = v_autor THEN
            RAISE_APPLICATION_ERROR(-20135, 'El autor no puede resolver su propia apelacion');
        END IF;
        IF :NEW.id_investigador = v_rechazo_por THEN
            RAISE_APPLICATION_ERROR(-20134, 'La apelacion la resuelve un investigador distinto del que rechazo');
        END IF;
        IF pkg_func.puede_revisar(:NEW.id_investigador, pkg_bd2.departamento_de(v_ubic), 1, v_rechazo_por) = 0 THEN
            RAISE_APPLICATION_ERROR(-20133, 'El investigador no esta habilitado para resolver esta apelacion');
        END IF;
        :NEW.fecha_resolucion := NVL(:NEW.fecha_resolucion, SYSTIMESTAMP);
    ELSIF :OLD.estado <> 'pendiente' AND :NEW.estado <> :OLD.estado THEN
        RAISE_APPLICATION_ERROR(-20136, 'Una apelacion resuelta es definitiva');
    END IF;
END;
/

-- Apelacion aceptada: se revierte todo lo que provoco el rechazo.
CREATE OR REPLACE TRIGGER trg_apelacion_aceptada
AFTER UPDATE OF estado ON apelacion
FOR EACH ROW
WHEN (NEW.estado = 'aceptada' AND OLD.estado = 'pendiente')
DECLARE
    v_por NUMBER; v_fecha TIMESTAMP; v_previo VARCHAR2(20);
BEGIN
    pkg_func.ultimo_rechazo(:NEW.id_avistamiento, v_por, v_fecha, v_previo);
    pkg_func.g_apelacion := TRUE;

    -- 1. Los reportes que lo tumbaron pasan a improcedentes
    UPDATE reporte_avistamiento SET estado = 'improcedente'
    WHERE id_avistamiento = :NEW.id_avistamiento AND estado = 'procedente';

    -- 2. Se revierten penalizaciones y premios ligados a ese rechazo
    FOR e IN (SELECT id_observador, puntos FROM evento_reputacion
              WHERE id_avistamiento = :NEW.id_avistamiento
                AND motivo IN ('penalizacion_reporte', 'reporte_procedente')) LOOP
        pkg_func.ajustar_reputacion(e.id_observador, :NEW.id_avistamiento, 'reversion_apelacion', -e.puntos);
    END LOOP;

    -- 3. El avistamiento vuelve al estado que tenia antes del rechazo
    UPDATE avistamiento SET estado = NVL(v_previo, 'pendiente')
    WHERE id_avistamiento = :NEW.id_avistamiento;

    pkg_func.g_apelacion := FALSE;
EXCEPTION WHEN OTHERS THEN
    pkg_func.g_apelacion := FALSE; RAISE;
END;
/

-- ============================================================
-- F3. VISTA PUBLICA CON GEOPRIVACIDAD
-- Para especies CR/EN la ubicacion se difumina al centro de una
-- celda de ~11 km, salvo para: el autor, los investigadores del
-- departamento y quien tenga una solicitud aprobada y vigente.
-- El usuario actual se toma de DBMS_SESSION.SET_IDENTIFIER.
-- ============================================================
CREATE OR REPLACE VIEW v_avistamiento_publico AS
WITH base AS (
    SELECT a.id_avistamiento, a.id_observador, a.estado, a.fecha_hora_avistamiento,
           a.numero_individuos,
           NVL(a.id_taxon_validado, a.id_taxon_propuesto) AS id_taxon,
           a.ubicacion.SDO_POINT.X AS lon,
           a.ubicacion.SDO_POINT.Y AS lat,
           pkg_bd2.departamento_de(a.ubicacion) AS id_departamento,
           pkg_bd2.actor_actual AS visor,
           (SELECT valor FROM parametro_sistema WHERE clave = 'UBICACION_DIFUMINADO_GRADOS') AS g
    FROM avistamiento a
), acceso AS (
    SELECT b.*,
           e.estado_conservacion,
           CASE
             WHEN NVL(e.estado_conservacion, 'LC') NOT IN ('CR', 'EN') THEN 'publica'
             WHEN b.visor = b.id_observador THEN 'autor'
             WHEN EXISTS (SELECT 1 FROM investigador i
                          WHERE i.id_observador = b.visor
                            AND i.id_departamento = b.id_departamento) THEN 'investigador'
             WHEN EXISTS (SELECT 1 FROM solicitud_ubicacion s
                          WHERE s.id_solicitante = b.visor AND s.id_taxon = b.id_taxon
                            AND s.id_departamento = b.id_departamento
                            AND s.estado = 'aprobada' AND s.vigente_hasta >= TRUNC(SYSDATE)) THEN 'solicitud'
           END AS motivo_acceso
    FROM base b
    LEFT JOIN especie e ON e.id_taxon = b.id_taxon
)
SELECT x.id_avistamiento,
       o.alias                  AS autor,
       t.nombre_cientifico      AS taxon,
       x.estado_conservacion,
       d.nombre                 AS departamento,
       x.estado,
       x.fecha_hora_avistamiento,
       x.numero_individuos,
       CASE WHEN x.motivo_acceso IS NOT NULL THEN x.lon
            ELSE ROUND(FLOOR(x.lon / x.g) * x.g + x.g / 2, 4) END AS longitud,
       CASE WHEN x.motivo_acceso IS NOT NULL THEN x.lat
            ELSE ROUND(FLOOR(x.lat / x.g) * x.g + x.g / 2, 4) END AS latitud,
       CASE WHEN x.motivo_acceso IS NULL THEN 'difuminada' ELSE 'exacta' END AS precision_ubicacion,
       x.motivo_acceso
FROM acceso x
JOIN observador o ON o.id_observador = x.id_observador
JOIN taxon      t ON t.id_taxon      = x.id_taxon
LEFT JOIN departamento d ON d.id_departamento = x.id_departamento;

-- Verificacion: todos los objetos deben quedar VALID
SELECT object_type, object_name, status
FROM user_objects
WHERE object_type IN ('PACKAGE', 'PACKAGE BODY', 'PROCEDURE', 'FUNCTION', 'TRIGGER', 'VIEW')
ORDER BY object_type, object_name;
