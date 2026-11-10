# Validación de normalización

El modelo lógico se revisa respecto de la Primera, Segunda y Tercera Forma Normal para verificar que no existan grupos repetitivos, dependencias parciales ni dependencias transitivas indebidas.

## 1. TAXON

Atributos principales:

- `id_taxon`
- `nombre_cientifico`
- `rango`
- `id_taxon_padre`

### Primera Forma Normal — 1FN

Cumple 1FN porque todos sus atributos almacenan valores atómicos y no existen grupos repetitivos.

### Segunda Forma Normal — 2FN

Cumple 2FN porque posee una clave primaria simple, `id_taxon`. Por tanto, no pueden existir dependencias parciales respecto de una clave compuesta.

### Tercera Forma Normal — 3FN

Cumple 3FN porque los atributos no clave dependen directamente de `id_taxon`.

La relación jerárquica se representa mediante `id_taxon_padre`, que referencia a otro taxón y no introduce una dependencia transitiva dentro de la misma fila.

**Resultado:** `TAXON` se encuentra en 3FN.

---

## 2. ESPECIE

Atributos principales:

- `id_taxon`
- `nombre_comun`
- `estado_conservacion`
- `es_endemica`
- `es_migratoria`

### 1FN

Todos los atributos son atómicos.

### 2FN

La clave primaria es simple, `id_taxon`, por lo que no existen dependencias parciales.

### 3FN

Los atributos propios de la especie dependen directamente del taxón especializado.

La separación respecto de `TAXON` evita almacenar información específica de especies en taxones de otros rangos.

**Resultado:** `ESPECIE` se encuentra en 3FN.

---

## 3. PRESENCIA_ESPERADA

Atributos principales:

- `id_presencia`
- `id_taxon`
- `id_departamento`
- `mes_inicio`
- `mes_fin`

### 1FN

Todos los atributos contienen valores atómicos.

### 2FN

La clave primaria es simple, `id_presencia`.

### 3FN

Los atributos geográficos y temporales describen directamente una condición de presencia esperada.

No se almacenan datos propios de la especie ni del departamento, evitando dependencias transitivas.

**Resultado:** `PRESENCIA_ESPERADA` se encuentra en 3FN.

---

## 4. OBSERVADOR

Atributos principales:

- `id_observador`
- `alias`
- `fecha_registro`
- `reputacion`

### 1FN

Todos los valores son atómicos.

### 2FN

La clave primaria es simple.

### 3FN

`alias`, `fecha_registro` y `reputacion` dependen directamente del observador.

La información exclusiva de investigadores fue separada en `INVESTIGADOR`, evitando atributos condicionales o dependencias innecesarias.

**Resultado:** `OBSERVADOR` se encuentra en 3FN.

---

## 5. INVESTIGADOR

Atributos principales:

- `id_observador`
- `id_departamento`

### 1FN

Los atributos son atómicos.

### 2FN

La clave primaria es simple.

### 3FN

El departamento asignado depende directamente del investigador.

La relación implementa la especialización entre `OBSERVADOR` e `INVESTIGADOR`.

**Resultado:** `INVESTIGADOR` se encuentra en 3FN.

---

## 6. AVISTAMIENTO

Atributos principales:

- `id_avistamiento`
- `id_observador`
- `id_taxon_propuesto`
- `id_taxon_validado`
- `id_campania`
- `ubicacion`
- `fecha_hora_avistamiento`
- `numero_individuos`
- `notas`
- `estado`
- `metodo_validacion`

### 1FN

Todos los atributos son atómicos y no existen listas dentro de una misma columna.

### 2FN

La clave primaria es simple, `id_avistamiento`.

### 3FN

Los atributos describen directamente al avistamiento.

El departamento no se almacena en `AVISTAMIENTO`, ya que se determina espacialmente a partir de `ubicacion`. De este modo se evita introducir una redundancia derivable dentro de la relación.

`id_taxon_propuesto` conserva la propuesta original, mientras que `id_taxon_validado` representa el resultado final del proceso de validación. `metodo_validacion` indica si dicho resultado se obtuvo por consenso comunitario o por revisión especializada.

**Resultado:** `AVISTAMIENTO` se encuentra en 3FN.

---

## 7. EVIDENCIA

Atributos principales:

- `id_evidencia`
- `id_avistamiento`
- `tipo`
- `ubicacion_recurso`
- `hash_archivo`
- `fecha_carga`

### 1FN

Todos los atributos son atómicos.

### 2FN

La clave primaria es simple.

### 3FN

Todos los atributos describen directamente una evidencia.

No se almacenan datos propios del avistamiento dentro de la tabla.

**Resultado:** `EVIDENCIA` se encuentra en 3FN.

---

## 8. IDENTIFICACION

Atributos principales:

- `id_identificacion`
- `id_avistamiento`
- `id_observador`
- `id_taxon_propuesto`
- `fecha`

### 1FN

Todos los atributos son atómicos.

### 2FN

La PK es simple, por lo que no existen dependencias parciales.

### 3FN

El taxón propuesto y la fecha describen directamente la identificación.

Debe mantenerse la restricción:

`UNIQUE (id_avistamiento, id_observador)`

para garantizar una sola identificación por observador y avistamiento.

**Resultado:** `IDENTIFICACION` se encuentra en 3FN.

---

## 9. DEPARTAMENTO

Atributos principales:

- `id_departamento`
- `nombre`
- `poligono`

### 1FN

Todos los atributos son atómicos desde la perspectiva del modelo relacional.

### 2FN

La clave primaria es simple.

### 3FN

`nombre` y `poligono` dependen únicamente de `id_departamento`.

**Resultado:** `DEPARTAMENTO` se encuentra en 3FN.

---

## 10. AREA_PROTEGIDA

Atributos principales:

- `id_area`
- `nombre`
- `categoria`
- `poligono`

### 1FN

Cumple 1FN.

### 2FN

La PK es simple.

### 3FN

Los atributos describen directamente al área protegida.

**Resultado:** `AREA_PROTEGIDA` se encuentra en 3FN.

---

## 11. CELDA_MUESTREO

Atributos principales:

- `id_celda`
- `poligono`

### 1FN

Cumple 1FN.

### 2FN

La clave primaria es simple.

### 3FN

El polígono depende exclusivamente de la celda.

**Resultado:** `CELDA_MUESTREO` se encuentra en 3FN.

---

## 12. CAMPANIA

Atributos principales:

- `id_campania`
- `nombre`
- `fecha_inicio`
- `fecha_fin`

### 1FN

Todos los atributos son atómicos.

### 2FN

La PK es simple.

### 3FN

Los atributos describen directamente una campaña.

**Resultado:** `CAMPANIA` se encuentra en 3FN.

---

## 13. ALERTA

Atributos principales:

- `id_alerta`
- `id_avistamiento`
- `id_investigador`
- `tipo`
- `fecha_generacion`
- `estado`
- `metodo_validacion`

### 1FN

Todos los atributos son atómicos.

### 2FN

La clave primaria es simple.

### 3FN

Cada atributo describe directamente una alerta.

No se almacena el departamento del investigador ni información del avistamiento que pueda obtenerse mediante relaciones.

**Resultado:** `ALERTA` se encuentra en 3FN.

---

## 14. DUPLICADO_CANDIDATO

Atributos principales:

- `id_avistamiento_a`
- `id_avistamiento_b`
- `distancia_metros`
- `diferencia_minutos`
- `estado`

La clave primaria es compuesta:

`(id_avistamiento_a, id_avistamiento_b)`

### 1FN

Todos los atributos son atómicos.

### 2FN

`distancia_metros`, `diferencia_minutos` y `estado` dependen del par completo de avistamientos y no de uno de ellos individualmente.

Por tanto, no existen dependencias parciales.

### 3FN

Los atributos no clave dependen directamente del par de avistamientos.

No existen dependencias entre atributos no clave.

**Resultado:** `DUPLICADO_CANDIDATO` se encuentra en 3FN.

---

## 15. AUDITORIA_AVISTAMIENTO

Atributos principales:

- `id_auditoria`
- `id_avistamiento`
- `id_observador_responsable`
- `estado_anterior`
- `estado_nuevo`
- `tipo_actor`
- `fecha_hora`

### 1FN

Todos los atributos son atómicos.

### 2FN

La clave primaria es simple.

### 3FN

Los datos almacenados describen directamente un evento de cambio de estado.

`id_observador_responsable` puede ser nulo cuando el cambio sea realizado automáticamente por el sistema.

**Resultado:** `AUDITORIA_AVISTAMIENTO` se encuentra en 3FN.

# Resultado general

El modelo se encuentra correctamente normalizado hasta **Tercera Forma Normal**.

Las principales decisiones que deben documentarse son:

1. `ESPECIE` se separa de `TAXON` para evitar atributos que solo aplican a taxones de rango especie.
2. `INVESTIGADOR` se separa de `OBSERVADOR` para representar correctamente la especialización.
3. `PRESENCIA_ESPERADA` evita almacenar múltiples zonas o períodos dentro de una misma fila de especie.
4. `IDENTIFICACION` resuelve la participación de múltiples observadores sobre múltiples avistamientos.
5. `DUPLICADO_CANDIDATO` resuelve una relación muchos a muchos autorreferenciada y almacena atributos propios de dicha relación.
6. `AVISTAMIENTO` no almacena `id_departamento`; el departamento se determina espacialmente a partir de `ubicacion`, evitando una redundancia derivable.
7. La propuesta inicial se mantiene separada del taxón validado porque representan hechos distintos del proceso de observación y validación.

Por tanto, el modelo lógico puede considerarse normalizado hasta **3FN**.
