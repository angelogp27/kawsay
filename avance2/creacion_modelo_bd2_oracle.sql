-- ============================================================
-- PROYECTO BD2 - Ciencia ciudadana de biodiversidad
-- Oracle Database 26ai Free
-- Script de creación del modelo relacional
-- Basado en el modelo lógico y restricciones proporcionadas
-- ============================================================

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
                'fuera_temporada'
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
        UNIQUE (id_avistamiento, tipo)
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

-- ============================================================
-- FIN DEL SCRIPT
-- ============================================================

-- NOTA:
-- Las siguientes reglas del modelo requieren lógica adicional
-- (triggers, procedimientos o lógica transaccional), por lo que
-- no se resuelven únicamente con CREATE TABLE:
--
-- * evitar ciclos en la jerarquía TAXON;
-- * validar que solo un TAXON con rango = 'especie' exista en ESPECIE;
-- * garantizar al menos una PRESENCIA_ESPERADA por ESPECIE;
-- * garantizar al menos una EVIDENCIA por AVISTAMIENTO;
-- * impedir que el autor identifique su propio AVISTAMIENTO;
-- * validar que el AVISTAMIENTO ocurra dentro del periodo de CAMPANIA;
-- * determinar espacialmente el DEPARTAMENTO del AVISTAMIENTO;
-- * validar la asignación territorial de ALERTA;
-- * generar alertas y duplicados automáticamente;
-- * mantener AUDITORIA_AVISTAMIENTO como estructura inmutable.
