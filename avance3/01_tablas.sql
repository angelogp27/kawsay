-- ============================================================
-- PROYECTO BD2 - Ciencia ciudadana de biodiversidad
-- 01 - CREACION DE TABLAS
-- Oracle Database 26ai
-- ============================================================
-- Orden de ejecucion: 01_tablas -> 02_logica -> 03_datos -> 04_consultas
--
-- PARTE A. Modelo base (15 tablas)
-- PARTE B. Ampliacion (5 tablas): parametros, campanias, esfuerzo
--          de muestreo, seguimiento de especies y reputacion
-- PARTE C. Funcionalidades (5 tablas): registro de investigadores,
--          reportes, geoprivacidad y apelaciones
-- PARTE D. Secuencias e indices (claves foraneas y espaciales)
-- ============================================================
SET SQLBLANKLINES ON


-- ############################################################
-- PARTE A. MODELO BASE
-- ############################################################

-- ============================================================
-- 1. DEPARTAMENTO
-- ============================================================
CREATE TABLE departamento (
    id_departamento NUMBER(10) NOT NULL,
    nombre           VARCHAR2(100) NOT NULL,
    poligono         MDSYS.SDO_GEOMETRY NOT NULL,

    CONSTRAINT pk_departamento PRIMARY KEY (id_departamento),
    CONSTRAINT uq_departamento_nombre UNIQUE (nombre)
);

-- ============================================================
-- 2. TAXON
-- ============================================================
CREATE TABLE taxon (
    id_taxon            NUMBER(10) NOT NULL,
    nombre_cientifico   VARCHAR2(200) NOT NULL,
    rango               VARCHAR2(20) NOT NULL,
    id_taxon_padre      NUMBER(10),

    CONSTRAINT pk_taxon PRIMARY KEY (id_taxon),

    CONSTRAINT fk_taxon_padre
        FOREIGN KEY (id_taxon_padre)
        REFERENCES taxon(id_taxon),

    CONSTRAINT ck_taxon_rango
        CHECK (rango IN (
            'reino',
            'filo',
            'clase',
            'orden',
            'familia',
            'genero',
            'especie'
        )),

    CONSTRAINT ck_taxon_no_autopadre
        CHECK (id_taxon_padre IS NULL OR id_taxon_padre <> id_taxon)
);

-- ============================================================
-- 3. OBSERVADOR
-- ============================================================
CREATE TABLE observador (
    id_observador   NUMBER(10) NOT NULL,
    alias           VARCHAR2(100) NOT NULL,
    fecha_registro  DATE NOT NULL,
    reputacion      NUMBER(10,2) DEFAULT 0 NOT NULL,

    CONSTRAINT pk_observador PRIMARY KEY (id_observador),
    CONSTRAINT uq_observador_alias UNIQUE (alias),
    CONSTRAINT ck_observador_reputacion CHECK (reputacion >= 0)
);

-- ============================================================
-- 4. CAMPANIA
-- ============================================================
CREATE TABLE campania (
    id_campania     NUMBER(10) NOT NULL,
    nombre          VARCHAR2(150) NOT NULL,
    fecha_inicio    DATE NOT NULL,
    fecha_fin       DATE NOT NULL,

    CONSTRAINT pk_campania PRIMARY KEY (id_campania),
    CONSTRAINT ck_campania_fechas CHECK (fecha_inicio <= fecha_fin)
);

-- ============================================================
-- 5. ESPECIE
-- ============================================================
CREATE TABLE especie (
    id_taxon              NUMBER(10) NOT NULL,
    nombre_comun          VARCHAR2(150),
    estado_conservacion   VARCHAR2(5),
    es_endemica           NUMBER(1),
    es_migratoria         NUMBER(1),

    CONSTRAINT pk_especie PRIMARY KEY (id_taxon),

    CONSTRAINT fk_especie_taxon
        FOREIGN KEY (id_taxon)
        REFERENCES taxon(id_taxon),

    CONSTRAINT ck_especie_conservacion
        CHECK (
            estado_conservacion IS NULL
            OR estado_conservacion IN ('LC', 'NT', 'VU', 'EN', 'CR')
        ),

    CONSTRAINT ck_especie_endemica
        CHECK (es_endemica IS NULL OR es_endemica IN (0,1)),

    CONSTRAINT ck_especie_migratoria
        CHECK (es_migratoria IS NULL OR es_migratoria IN (0,1))
);

-- ============================================================
-- 6. INVESTIGADOR
-- ============================================================
CREATE TABLE investigador (
    id_observador     NUMBER(10) NOT NULL,
    id_departamento   NUMBER(10),

    CONSTRAINT pk_investigador PRIMARY KEY (id_observador),

    CONSTRAINT fk_investigador_observador
        FOREIGN KEY (id_observador)
        REFERENCES observador(id_observador),

    CONSTRAINT fk_investigador_departamento
        FOREIGN KEY (id_departamento)
        REFERENCES departamento(id_departamento)
);

-- ============================================================
-- 7. PRESENCIA_ESPERADA
-- ============================================================
CREATE TABLE presencia_esperada (
    id_presencia       NUMBER(10) NOT NULL,
    id_taxon           NUMBER(10) NOT NULL,
    id_departamento    NUMBER(10) NOT NULL,
    mes_inicio         NUMBER(2) NOT NULL,
    mes_fin            NUMBER(2) NOT NULL,

    CONSTRAINT pk_presencia_esperada PRIMARY KEY (id_presencia),

    CONSTRAINT fk_presencia_especie
        FOREIGN KEY (id_taxon)
        REFERENCES especie(id_taxon),

    CONSTRAINT fk_presencia_departamento
        FOREIGN KEY (id_departamento)
        REFERENCES departamento(id_departamento),

    CONSTRAINT ck_presencia_mes_inicio CHECK (mes_inicio BETWEEN 1 AND 12),
    CONSTRAINT ck_presencia_mes_fin CHECK (mes_fin BETWEEN 1 AND 12),

    CONSTRAINT uq_presencia_condicion
        UNIQUE (id_taxon, id_departamento, mes_inicio, mes_fin)
);

-- ============================================================
-- 8. AVISTAMIENTO
-- ============================================================
CREATE TABLE avistamiento (
    id_avistamiento          NUMBER(10) NOT NULL,
    id_observador            NUMBER(10) NOT NULL,
    id_taxon_propuesto       NUMBER(10) NOT NULL,
    id_taxon_validado        NUMBER(10),
    id_campania              NUMBER(10),
    id_salida                NUMBER(10),
    ubicacion                MDSYS.SDO_GEOMETRY NOT NULL,
    fecha_hora_avistamiento  TIMESTAMP NOT NULL,
    numero_individuos        NUMBER(10) NOT NULL,
    notas                    VARCHAR2(1000),
    estado                   VARCHAR2(20) NOT NULL,
    metodo_validacion        VARCHAR2(20),

    CONSTRAINT pk_avistamiento PRIMARY KEY (id_avistamiento),

    CONSTRAINT fk_avistamiento_observador
        FOREIGN KEY (id_observador)
        REFERENCES observador(id_observador),

    CONSTRAINT fk_avistamiento_taxon_propuesto
        FOREIGN KEY (id_taxon_propuesto)
        REFERENCES taxon(id_taxon),

    CONSTRAINT fk_avistamiento_taxon_validado
        FOREIGN KEY (id_taxon_validado)
        REFERENCES taxon(id_taxon),

    CONSTRAINT fk_avistamiento_campania
        FOREIGN KEY (id_campania)
        REFERENCES campania(id_campania),

    CONSTRAINT ck_avistamiento_individuos
        CHECK (numero_individuos > 0),

    CONSTRAINT ck_avistamiento_estado
        CHECK (estado IN ('pendiente', 'verificado', 'dudoso', 'rechazado')),

    CONSTRAINT ck_avistamiento_metodo
        CHECK (
            metodo_validacion IS NULL
            OR metodo_validacion IN ('consenso', 'investigador')
        ),

    CONSTRAINT ck_avistamiento_verificado
        CHECK (
            estado <> 'verificado'
            OR id_taxon_validado IS NOT NULL
        ),

    CONSTRAINT ck_avistamiento_validacion
        CHECK (
            id_taxon_validado IS NULL
            OR metodo_validacion IS NOT NULL
        )
);

-- ============================================================
-- 9. EVIDENCIA
-- ============================================================
CREATE TABLE evidencia (
    id_evidencia        NUMBER(10) NOT NULL,
    id_avistamiento     NUMBER(10) NOT NULL,
    tipo                VARCHAR2(20) NOT NULL,
    ubicacion_recurso   VARCHAR2(500) NOT NULL,
    hash_archivo        VARCHAR2(128) NOT NULL,
    fecha_carga         TIMESTAMP NOT NULL,

    CONSTRAINT pk_evidencia PRIMARY KEY (id_evidencia),

    CONSTRAINT fk_evidencia_avistamiento
        FOREIGN KEY (id_avistamiento)
        REFERENCES avistamiento(id_avistamiento),

    CONSTRAINT ck_evidencia_tipo
        CHECK (tipo IN ('foto', 'audio'))
);

-- ============================================================
-- 10. IDENTIFICACION
-- ============================================================
CREATE TABLE identificacion (
    id_identificacion      NUMBER(10) NOT NULL,
    id_avistamiento        NUMBER(10) NOT NULL,
    id_observador          NUMBER(10) NOT NULL,
    id_taxon_propuesto     NUMBER(10) NOT NULL,
    fecha                  TIMESTAMP NOT NULL,

    CONSTRAINT pk_identificacion PRIMARY KEY (id_identificacion),

    CONSTRAINT fk_identificacion_avistamiento
        FOREIGN KEY (id_avistamiento)
        REFERENCES avistamiento(id_avistamiento),

    CONSTRAINT fk_identificacion_observador
        FOREIGN KEY (id_observador)
        REFERENCES observador(id_observador),

    CONSTRAINT fk_identificacion_taxon
        FOREIGN KEY (id_taxon_propuesto)
        REFERENCES taxon(id_taxon),

    CONSTRAINT uq_identificacion_observador
        UNIQUE (id_avistamiento, id_observador)
);

-- ============================================================
-- 11. ALERTA
-- ============================================================
CREATE TABLE alerta (
    id_alerta           NUMBER(10) NOT NULL,
    id_avistamiento     NUMBER(10) NOT NULL,
    id_investigador     NUMBER(10),
    tipo                VARCHAR2(40) NOT NULL,
    fecha_generacion    TIMESTAMP NOT NULL,
    estado              VARCHAR2(20) NOT NULL,
    fecha_resolucion    TIMESTAMP,

    CONSTRAINT pk_alerta PRIMARY KEY (id_alerta),

    CONSTRAINT fk_alerta_avistamiento
        FOREIGN KEY (id_avistamiento)
        REFERENCES avistamiento(id_avistamiento),

    CONSTRAINT fk_alerta_investigador
        FOREIGN KEY (id_investigador)
        REFERENCES investigador(id_observador),

    CONSTRAINT ck_alerta_tipo
        CHECK (
            tipo IN (
                'especie_amenazada',
                'fuera_rango_geografico',
                'fuera_temporada',
                'reporte_comunidad'
            )
        ),

    CONSTRAINT ck_alerta_estado
        CHECK (
            estado IN (
                'pendiente',
                'asignada',
                'resuelta',
                'descartada'
            )
        ),

    CONSTRAINT uq_alerta_tipo
        UNIQUE (id_avistamiento, tipo),

    CONSTRAINT ck_alerta_resolucion
        CHECK (
            (estado IN ('resuelta', 'descartada') AND fecha_resolucion IS NOT NULL
             AND fecha_resolucion >= fecha_generacion)
            OR (estado IN ('pendiente', 'asignada') AND fecha_resolucion IS NULL)
        ),

    CONSTRAINT ck_alerta_responsable
        CHECK (estado NOT IN ('asignada', 'resuelta') OR id_investigador IS NOT NULL)
);

-- ============================================================
-- 12. DUPLICADO_CANDIDATO
-- ============================================================
CREATE TABLE duplicado_candidato (
    id_avistamiento_a    NUMBER(10) NOT NULL,
    id_avistamiento_b    NUMBER(10) NOT NULL,
    distancia_metros     NUMBER(10,2) NOT NULL,
    diferencia_minutos   NUMBER(10) NOT NULL,
    estado               VARCHAR2(20) NOT NULL,

    CONSTRAINT pk_duplicado_candidato
        PRIMARY KEY (id_avistamiento_a, id_avistamiento_b),

    CONSTRAINT fk_duplicado_avistamiento_a
        FOREIGN KEY (id_avistamiento_a)
        REFERENCES avistamiento(id_avistamiento),

    CONSTRAINT fk_duplicado_avistamiento_b
        FOREIGN KEY (id_avistamiento_b)
        REFERENCES avistamiento(id_avistamiento),

    CONSTRAINT ck_duplicado_orden
        CHECK (id_avistamiento_a < id_avistamiento_b),

    CONSTRAINT ck_duplicado_distancia
        CHECK (distancia_metros >= 0),

    CONSTRAINT ck_duplicado_minutos
        CHECK (diferencia_minutos >= 0),

    CONSTRAINT ck_duplicado_estado
        CHECK (estado IN ('pendiente', 'confirmado', 'descartado'))
);

-- ============================================================
-- 13. AUDITORIA_AVISTAMIENTO
-- ============================================================
CREATE TABLE auditoria_avistamiento (
    id_auditoria                NUMBER(10) NOT NULL,
    id_avistamiento             NUMBER(10) NOT NULL,
    id_observador_responsable   NUMBER(10),
    estado_anterior             VARCHAR2(20),
    estado_nuevo                VARCHAR2(20) NOT NULL,
    tipo_actor                  VARCHAR2(20) NOT NULL,
    fecha_hora                  TIMESTAMP NOT NULL,

    CONSTRAINT pk_auditoria_avistamiento PRIMARY KEY (id_auditoria),

    CONSTRAINT fk_auditoria_avistamiento
        FOREIGN KEY (id_avistamiento)
        REFERENCES avistamiento(id_avistamiento),

    CONSTRAINT fk_auditoria_observador
        FOREIGN KEY (id_observador_responsable)
        REFERENCES observador(id_observador),

    CONSTRAINT ck_auditoria_estado_anterior
        CHECK (
            estado_anterior IS NULL
            OR estado_anterior IN ('pendiente', 'verificado', 'dudoso', 'rechazado')
        ),

    CONSTRAINT ck_auditoria_estado_nuevo
        CHECK (
            estado_nuevo IN ('pendiente', 'verificado', 'dudoso', 'rechazado')
        ),

    CONSTRAINT ck_auditoria_tipo_actor
        CHECK (tipo_actor IN ('observador', 'investigador', 'sistema')),

    CONSTRAINT ck_auditoria_actor
        CHECK (
            (tipo_actor = 'sistema' AND id_observador_responsable IS NULL)
            OR
            (tipo_actor IN ('observador', 'investigador')
             AND id_observador_responsable IS NOT NULL)
        )
);

-- ============================================================
-- 14. AREA_PROTEGIDA
-- ============================================================
CREATE TABLE area_protegida (
    id_area      NUMBER(10) NOT NULL,
    nombre       VARCHAR2(150) NOT NULL,
    categoria    VARCHAR2(100) NOT NULL,
    poligono     MDSYS.SDO_GEOMETRY NOT NULL,

    CONSTRAINT pk_area_protegida PRIMARY KEY (id_area)
);

-- ============================================================
-- 15. CELDA_MUESTREO
-- ============================================================
CREATE TABLE celda_muestreo (
    id_celda     NUMBER(10) NOT NULL,
    poligono     MDSYS.SDO_GEOMETRY NOT NULL,

    CONSTRAINT pk_celda_muestreo PRIMARY KEY (id_celda)
);


-- ############################################################
-- PARTE B. AMPLIACION
-- ############################################################

-- B1. PARAMETRO_SISTEMA: los umbrales de RN13 y RN26 dejan de estar
--     "quemados" en el codigo.
CREATE TABLE parametro_sistema (
    clave        VARCHAR2(40)  NOT NULL,
    valor        NUMBER(10,2)  NOT NULL,
    descripcion  VARCHAR2(200) NOT NULL,
    CONSTRAINT pk_parametro_sistema PRIMARY KEY (clave),
    CONSTRAINT ck_parametro_valor CHECK (valor >= 0)
);

-- B2. PARTICIPACION_CAMPANIA: N:M entre observador y campania.
CREATE TABLE participacion_campania (
    id_campania        NUMBER(10)   NOT NULL,
    id_observador      NUMBER(10)   NOT NULL,
    rol                VARCHAR2(20) NOT NULL,
    fecha_inscripcion  DATE         NOT NULL,
    CONSTRAINT pk_participacion_campania PRIMARY KEY (id_campania, id_observador),
    CONSTRAINT fk_participacion_campania FOREIGN KEY (id_campania) REFERENCES campania(id_campania),
    CONSTRAINT fk_participacion_observador FOREIGN KEY (id_observador) REFERENCES observador(id_observador),
    CONSTRAINT ck_participacion_rol CHECK (rol IN ('coordinador', 'voluntario'))
);

-- B3. SALIDA_CAMPO: esfuerzo de muestreo (equivalente a la "checklist"
--     de eBird). Da uso real a CELDA_MUESTREO.
CREATE TABLE salida_campo (
    id_salida          NUMBER(10)  NOT NULL,
    id_observador      NUMBER(10)  NOT NULL,
    id_celda           NUMBER(10),
    id_campania        NUMBER(10),
    fecha_hora_inicio  TIMESTAMP   NOT NULL,
    fecha_hora_fin     TIMESTAMP   NOT NULL,
    distancia_km       NUMBER(6,2) NOT NULL,
    CONSTRAINT pk_salida_campo PRIMARY KEY (id_salida),
    CONSTRAINT fk_salida_observador FOREIGN KEY (id_observador) REFERENCES observador(id_observador),
    CONSTRAINT fk_salida_celda FOREIGN KEY (id_celda) REFERENCES celda_muestreo(id_celda),
    CONSTRAINT fk_salida_campania FOREIGN KEY (id_campania) REFERENCES campania(id_campania),
    CONSTRAINT ck_salida_fechas CHECK (fecha_hora_fin > fecha_hora_inicio),
    CONSTRAINT ck_salida_distancia CHECK (distancia_km >= 0)
);

ALTER TABLE avistamiento ADD CONSTRAINT fk_avistamiento_salida
    FOREIGN KEY (id_salida) REFERENCES salida_campo(id_salida);

-- B4. SEGUIMIENTO_ESPECIE: el observador "sigue" especies de interes.
CREATE TABLE seguimiento_especie (
    id_observador  NUMBER(10) NOT NULL,
    id_taxon       NUMBER(10) NOT NULL,
    fecha_inicio   DATE       NOT NULL,
    CONSTRAINT pk_seguimiento_especie PRIMARY KEY (id_observador, id_taxon),
    CONSTRAINT fk_seguimiento_observador FOREIGN KEY (id_observador) REFERENCES observador(id_observador),
    CONSTRAINT fk_seguimiento_especie FOREIGN KEY (id_taxon) REFERENCES especie(id_taxon)
);

-- B5. EVENTO_REPUTACION: explica de donde sale OBSERVADOR.reputacion (RN04).
CREATE TABLE evento_reputacion (
    id_evento        NUMBER(10)   NOT NULL,
    id_observador    NUMBER(10)   NOT NULL,
    id_avistamiento  NUMBER(10),
    motivo           VARCHAR2(30) NOT NULL,
    puntos           NUMBER(6,2)  NOT NULL,
    fecha            TIMESTAMP    NOT NULL,
    CONSTRAINT pk_evento_reputacion PRIMARY KEY (id_evento),
    CONSTRAINT fk_evento_observador FOREIGN KEY (id_observador) REFERENCES observador(id_observador),
    CONSTRAINT fk_evento_avistamiento FOREIGN KEY (id_avistamiento) REFERENCES avistamiento(id_avistamiento),
    CONSTRAINT ck_evento_motivo CHECK (motivo IN ('saldo_inicial', 'avistamiento_verificado', 'identificacion_acertada',
        'penalizacion_reporte', 'reporte_procedente', 'reversion_apelacion'))
);


-- ############################################################
-- PARTE C. FUNCIONALIDADES
-- ############################################################

-- ============================================================
-- F1. REGISTRO DE INVESTIGADORES
-- Politica de la plataforma inspirada en los registros peruanos:
--   SUNEDU (grados y titulos), Colegio de Biologos del Peru
--   (colegiatura y habilitacion, Ley 28847), CONCYTEC (RENACYT,
--   7 niveles) y SERFOR/ARFFS (autorizacion de investigacion).
-- ============================================================

-- Documentos de una persona (no de una postulacion: si vuelve a
-- postular, sus credenciales siguen siendo las mismas).
CREATE TABLE credencial (
    id_credencial        NUMBER(10)    NOT NULL,
    id_observador        NUMBER(10)    NOT NULL,
    tipo                 VARCHAR2(30)  NOT NULL,
    entidad_emisora      VARCHAR2(150) NOT NULL,
    codigo_registro      VARCHAR2(50)  NOT NULL,
    nivel_renacyt        NUMBER(1),
    fecha_emision        DATE          NOT NULL,
    fecha_vencimiento    DATE,
    -- PENDIENTE: almacenamiento del documento (PDF/escaneo).
    -- Por definir si sera un enlace (p. ej. Google Drive) u otro medio.
    estado_verificacion  VARCHAR2(20)  DEFAULT 'pendiente' NOT NULL,
    id_verificador       NUMBER(10),
    fecha_verificacion   TIMESTAMP,

    CONSTRAINT pk_credencial PRIMARY KEY (id_credencial),
    CONSTRAINT fk_credencial_observador FOREIGN KEY (id_observador) REFERENCES observador(id_observador),
    CONSTRAINT fk_credencial_verificador FOREIGN KEY (id_verificador) REFERENCES investigador(id_observador),
    CONSTRAINT uq_credencial_codigo UNIQUE (tipo, entidad_emisora, codigo_registro),
    CONSTRAINT ck_credencial_tipo CHECK (tipo IN (
        'grado_bachiller', 'titulo_profesional', 'grado_maestria', 'grado_doctor',
        'colegiatura', 'renacyt', 'autorizacion_serfor', 'carta_institucional')),
    CONSTRAINT ck_credencial_renacyt CHECK (
        (tipo = 'renacyt' AND nivel_renacyt BETWEEN 1 AND 7)
        OR (tipo <> 'renacyt' AND nivel_renacyt IS NULL)),
    CONSTRAINT ck_credencial_vence CHECK (
        tipo NOT IN ('colegiatura', 'renacyt', 'autorizacion_serfor') OR fecha_vencimiento IS NOT NULL),
    CONSTRAINT ck_credencial_fechas CHECK (fecha_vencimiento IS NULL OR fecha_vencimiento > fecha_emision),
    CONSTRAINT ck_credencial_estado CHECK (estado_verificacion IN ('pendiente', 'verificada', 'observada')),
    CONSTRAINT ck_credencial_verificador CHECK (
        estado_verificacion = 'pendiente' OR (id_verificador IS NOT NULL AND fecha_verificacion IS NOT NULL))
);

CREATE TABLE postulacion_investigador (
    id_postulacion     NUMBER(10)     NOT NULL,
    id_observador      NUMBER(10)     NOT NULL,
    id_departamento    NUMBER(10)     NOT NULL,
    institucion        VARCHAR2(200)  NOT NULL,
    especialidad       VARCHAR2(100)  NOT NULL,
    motivacion         VARCHAR2(1000) NOT NULL,
    fecha_postulacion  TIMESTAMP      NOT NULL,
    estado             VARCHAR2(20)   DEFAULT 'pendiente' NOT NULL,
    id_evaluador       NUMBER(10),
    fecha_resolucion   TIMESTAMP,
    observacion        VARCHAR2(500),

    CONSTRAINT pk_postulacion PRIMARY KEY (id_postulacion),
    CONSTRAINT fk_postulacion_observador FOREIGN KEY (id_observador) REFERENCES observador(id_observador),
    CONSTRAINT fk_postulacion_departamento FOREIGN KEY (id_departamento) REFERENCES departamento(id_departamento),
    CONSTRAINT fk_postulacion_evaluador FOREIGN KEY (id_evaluador) REFERENCES investigador(id_observador),
    CONSTRAINT ck_postulacion_estado CHECK (estado IN ('pendiente', 'en_revision', 'aprobada', 'rechazada')),
    CONSTRAINT ck_postulacion_evaluador CHECK (estado = 'pendiente' OR id_evaluador IS NOT NULL),
    CONSTRAINT ck_postulacion_resolucion CHECK (
        (estado IN ('aprobada', 'rechazada') AND fecha_resolucion IS NOT NULL)
        OR (estado IN ('pendiente', 'en_revision') AND fecha_resolucion IS NULL))
);

-- Una sola postulacion activa por persona (indice unico basado en
-- funcion: las filas cerradas producen NULL y no se indexan).
CREATE UNIQUE INDEX ux_postulacion_activa ON postulacion_investigador (
    CASE WHEN estado IN ('pendiente', 'en_revision') THEN id_observador END);

-- ============================================================
-- F2. REPORTE DE AVISTAMIENTOS SOSPECHOSOS
-- ============================================================
CREATE TABLE reporte_avistamiento (
    id_reporte        NUMBER(10)    NOT NULL,
    id_avistamiento   NUMBER(10)    NOT NULL,
    id_reportante     NUMBER(10)    NOT NULL,
    motivo            VARCHAR2(30)  NOT NULL,
    detalle           VARCHAR2(500),
    fecha_reporte     TIMESTAMP     NOT NULL,
    estado            VARCHAR2(20)  DEFAULT 'pendiente' NOT NULL,
    id_investigador   NUMBER(10),
    fecha_resolucion  TIMESTAMP,

    CONSTRAINT pk_reporte PRIMARY KEY (id_reporte),
    CONSTRAINT fk_reporte_avistamiento FOREIGN KEY (id_avistamiento) REFERENCES avistamiento(id_avistamiento),
    CONSTRAINT fk_reporte_reportante FOREIGN KEY (id_reportante) REFERENCES observador(id_observador),
    CONSTRAINT fk_reporte_investigador FOREIGN KEY (id_investigador) REFERENCES investigador(id_observador),
    CONSTRAINT uq_reporte_persona UNIQUE (id_avistamiento, id_reportante),
    CONSTRAINT ck_reporte_motivo CHECK (motivo IN (
        'foto_ajena', 'ubicacion_falsa', 'especie_cautiva', 'fecha_incorrecta', 'contenido_inapropiado')),
    CONSTRAINT ck_reporte_estado CHECK (estado IN ('pendiente', 'procedente', 'improcedente')),
    CONSTRAINT ck_reporte_resolucion CHECK (
        (estado = 'pendiente' AND fecha_resolucion IS NULL)
        OR (estado <> 'pendiente' AND id_investigador IS NOT NULL AND fecha_resolucion IS NOT NULL))
);

-- ============================================================
-- F3. GEOPRIVACIDAD
-- ============================================================
CREATE TABLE solicitud_ubicacion (
    id_solicitud      NUMBER(10)    NOT NULL,
    id_solicitante    NUMBER(10)    NOT NULL,
    id_taxon          NUMBER(10)    NOT NULL,
    id_departamento   NUMBER(10)    NOT NULL,
    proposito         VARCHAR2(500) NOT NULL,
    fecha_solicitud   TIMESTAMP     NOT NULL,
    estado            VARCHAR2(20)  DEFAULT 'pendiente' NOT NULL,
    id_aprobador      NUMBER(10),
    fecha_resolucion  TIMESTAMP,
    vigente_hasta     DATE,

    CONSTRAINT pk_solicitud_ubicacion PRIMARY KEY (id_solicitud),
    CONSTRAINT fk_solicitud_solicitante FOREIGN KEY (id_solicitante) REFERENCES observador(id_observador),
    CONSTRAINT fk_solicitud_especie FOREIGN KEY (id_taxon) REFERENCES especie(id_taxon),
    CONSTRAINT fk_solicitud_departamento FOREIGN KEY (id_departamento) REFERENCES departamento(id_departamento),
    CONSTRAINT fk_solicitud_aprobador FOREIGN KEY (id_aprobador) REFERENCES investigador(id_observador),
    CONSTRAINT ck_solicitud_estado CHECK (estado IN ('pendiente', 'aprobada', 'denegada')),
    CONSTRAINT ck_solicitud_resolucion CHECK (
        (estado = 'pendiente' AND fecha_resolucion IS NULL AND vigente_hasta IS NULL)
        OR (estado = 'denegada' AND id_aprobador IS NOT NULL AND fecha_resolucion IS NOT NULL AND vigente_hasta IS NULL)
        OR (estado = 'aprobada' AND id_aprobador IS NOT NULL AND fecha_resolucion IS NOT NULL
            AND vigente_hasta > CAST(fecha_resolucion AS DATE)))
);

-- Una sola solicitud pendiente por persona, especie y departamento.
CREATE UNIQUE INDEX ux_solicitud_pendiente ON solicitud_ubicacion (
    CASE WHEN estado = 'pendiente' THEN id_solicitante END,
    CASE WHEN estado = 'pendiente' THEN id_taxon END,
    CASE WHEN estado = 'pendiente' THEN id_departamento END);

-- ============================================================
-- F4. APELACION
-- El autor no se almacena: se obtiene del avistamiento (evita una
-- dependencia transitiva). Las pruebas nuevas van en EVIDENCIA.
-- ============================================================
CREATE TABLE apelacion (
    id_apelacion      NUMBER(10)     NOT NULL,
    id_avistamiento   NUMBER(10)     NOT NULL,
    argumento         VARCHAR2(1000) NOT NULL,
    fecha_apelacion   TIMESTAMP      NOT NULL,
    estado            VARCHAR2(20)   DEFAULT 'pendiente' NOT NULL,
    id_investigador   NUMBER(10),
    fecha_resolucion  TIMESTAMP,
    resolucion        VARCHAR2(500),

    CONSTRAINT pk_apelacion PRIMARY KEY (id_apelacion),
    CONSTRAINT fk_apelacion_avistamiento FOREIGN KEY (id_avistamiento) REFERENCES avistamiento(id_avistamiento),
    CONSTRAINT fk_apelacion_investigador FOREIGN KEY (id_investigador) REFERENCES investigador(id_observador),
    CONSTRAINT uq_apelacion_avistamiento UNIQUE (id_avistamiento),
    CONSTRAINT ck_apelacion_estado CHECK (estado IN ('pendiente', 'aceptada', 'desestimada')),
    CONSTRAINT ck_apelacion_resolucion CHECK (
        (estado = 'pendiente' AND fecha_resolucion IS NULL)
        OR (estado <> 'pendiente' AND id_investigador IS NOT NULL
            AND fecha_resolucion IS NOT NULL AND resolucion IS NOT NULL))
);

-- ============================================================
-- Indices sobre las nuevas claves foraneas
-- ============================================================
CREATE INDEX ix_credencial_observador   ON credencial(id_observador, tipo);
CREATE INDEX ix_credencial_verificador  ON credencial(id_verificador);
CREATE INDEX ix_postulacion_observador  ON postulacion_investigador(id_observador);
CREATE INDEX ix_postulacion_depto       ON postulacion_investigador(id_departamento);
CREATE INDEX ix_postulacion_evaluador   ON postulacion_investigador(id_evaluador);
CREATE INDEX ix_reporte_reportante      ON reporte_avistamiento(id_reportante);
CREATE INDEX ix_reporte_investigador    ON reporte_avistamiento(id_investigador);
CREATE INDEX ix_solicitud_solicitante   ON solicitud_ubicacion(id_solicitante);
CREATE INDEX ix_solicitud_taxon_depto   ON solicitud_ubicacion(id_taxon, id_departamento);
CREATE INDEX ix_solicitud_aprobador     ON solicitud_ubicacion(id_aprobador);
CREATE INDEX ix_apelacion_investigador  ON apelacion(id_investigador);


-- ############################################################
-- PARTE D. SECUENCIAS E INDICES
-- ############################################################

-- ============================================================
-- C. SECUENCIAS (para filas que generan los triggers)
-- ============================================================
CREATE SEQUENCE seq_alerta     START WITH 100;
CREATE SEQUENCE seq_auditoria  START WITH 100;
CREATE SEQUENCE seq_evento_rep START WITH 100;

-- ============================================================
-- D. INDICES
-- Oracle NO crea indices automaticamente sobre claves foraneas.
-- Sin ellos, los JOIN y los DELETE del padre recorren toda la tabla.
-- ============================================================
CREATE INDEX ix_taxon_padre            ON taxon(id_taxon_padre);
CREATE INDEX ix_investigador_depto     ON investigador(id_departamento);
CREATE INDEX ix_presencia_depto        ON presencia_esperada(id_departamento);
CREATE INDEX ix_avist_observador       ON avistamiento(id_observador);
CREATE INDEX ix_avist_taxon_prop       ON avistamiento(id_taxon_propuesto);
CREATE INDEX ix_avist_taxon_val        ON avistamiento(id_taxon_validado);
CREATE INDEX ix_avist_campania         ON avistamiento(id_campania);
CREATE INDEX ix_avist_salida           ON avistamiento(id_salida);
CREATE INDEX ix_avist_estado_fecha     ON avistamiento(estado, fecha_hora_avistamiento);
CREATE INDEX ix_evidencia_avist        ON evidencia(id_avistamiento);
CREATE INDEX ix_evidencia_hash         ON evidencia(hash_archivo);
CREATE INDEX ix_identif_observador     ON identificacion(id_observador);
CREATE INDEX ix_identif_taxon          ON identificacion(id_taxon_propuesto);
CREATE INDEX ix_alerta_investigador    ON alerta(id_investigador);
CREATE INDEX ix_duplicado_b            ON duplicado_candidato(id_avistamiento_b);
CREATE INDEX ix_auditoria_avist        ON auditoria_avistamiento(id_avistamiento, fecha_hora);
CREATE INDEX ix_auditoria_responsable  ON auditoria_avistamiento(id_observador_responsable);
CREATE INDEX ix_participacion_obs      ON participacion_campania(id_observador);
CREATE INDEX ix_salida_observador      ON salida_campo(id_observador);
CREATE INDEX ix_salida_celda           ON salida_campo(id_celda);
CREATE INDEX ix_seguimiento_taxon      ON seguimiento_especie(id_taxon);
CREATE INDEX ix_evento_observador      ON evento_reputacion(id_observador);

-- Metadatos + indices espaciales (requeridos para un uso eficiente
-- de SDO_RELATE / SDO_WITHIN_DISTANCE / SDO_NN).
INSERT INTO user_sdo_geom_metadata (table_name, column_name, diminfo, srid)
SELECT t, c, MDSYS.SDO_DIM_ARRAY(
           MDSYS.SDO_DIM_ELEMENT('LONG', -180, 180, 0.005),
           MDSYS.SDO_DIM_ELEMENT('LAT',   -90,  90, 0.005)), 4326
FROM (SELECT 'AVISTAMIENTO' t, 'UBICACION' c FROM dual
      UNION ALL SELECT 'DEPARTAMENTO',   'POLIGONO' FROM dual
      UNION ALL SELECT 'AREA_PROTEGIDA', 'POLIGONO' FROM dual
      UNION ALL SELECT 'CELDA_MUESTREO', 'POLIGONO' FROM dual);
COMMIT;

CREATE INDEX sx_avistamiento_ubicacion ON avistamiento(ubicacion)     INDEXTYPE IS MDSYS.SPATIAL_INDEX_V2;
CREATE INDEX sx_departamento_poligono  ON departamento(poligono)      INDEXTYPE IS MDSYS.SPATIAL_INDEX_V2;
CREATE INDEX sx_area_poligono          ON area_protegida(poligono)    INDEXTYPE IS MDSYS.SPATIAL_INDEX_V2;
CREATE INDEX sx_celda_poligono         ON celda_muestreo(poligono)    INDEXTYPE IS MDSYS.SPATIAL_INDEX_V2;
