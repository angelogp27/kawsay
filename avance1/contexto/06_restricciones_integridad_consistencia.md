# Restricciones de integridad y consistencia

## 1. TAXON

### Restricciones de entidad

- `id_taxon` debe ser único y no nulo.
- `nombre_cientifico` debe ser obligatorio.
- `rango` debe ser obligatorio.
- `id_taxon_padre` puede ser nulo únicamente cuando el taxón corresponda a una raíz de la jerarquía.

### Restricciones de dominio

`rango` debe pertenecer al conjunto permitido:

- reino
- filo
- clase
- orden
- familia
- género
- especie

### Restricciones de consistencia

- Un taxón no puede ser padre de sí mismo.
- Un taxón hijo debe pertenecer a un nivel jerárquico inferior al de su padre.
- No deben generarse ciclos dentro de la jerarquía taxonómica.

La prevención de ciclos no puede resolverse únicamente mediante una restricción `CHECK`; deberá controlarse mediante lógica adicional.

---

## 2. ESPECIE

### Restricciones de entidad

- `id_taxon` debe ser único y obligatorio.
- Debe existir previamente el taxón correspondiente.

### Restricciones de consistencia

Solo puede existir una fila en `ESPECIE` cuando el taxón asociado tenga:

`rango = especie`

`estado_conservacion` debe restringirse a los estados utilizados por el proyecto, por ejemplo:

- LC
- NT
- VU
- EN
- CR

`es_endemica` y `es_migratoria` deben contener únicamente valores booleanos.

---

## 3. PRESENCIA_ESPERADA

### Restricciones de entidad

Son obligatorios:

- `id_presencia`
- `id_taxon`
- `id_departamento`
- `mes_inicio`
- `mes_fin`

### Restricciones referenciales

- `id_taxon` debe corresponder a una fila existente en `ESPECIE`.
- `id_departamento` debe corresponder a un departamento existente.

### Restricciones de dominio

Debe cumplirse:

`1 <= mes_inicio <= 12`

`1 <= mes_fin <= 12`

Se permiten intervalos que atraviesen el cambio de año.

Por ejemplo:

`noviembre → febrero`

puede representarse como:

`mes_inicio = 11`

`mes_fin = 2`

### Restricción de duplicidad

No debe registrarse dos veces la misma condición exacta de presencia para una especie y departamento.

Puede considerarse:

`UNIQUE (id_taxon, id_departamento, mes_inicio, mes_fin)`

---

## 4. OBSERVADOR

### Restricciones de entidad

Son obligatorios:

- `id_observador`
- `alias`
- `fecha_registro`
- `reputacion`

### Restricciones de dominio

`reputacion` no debe ser negativa.

Debe cumplirse:

`reputacion >= 0`

El alias debería ser único si se utiliza como identificador visible dentro de la plataforma.

En ese caso:

`UNIQUE (alias)`

---

## 5. INVESTIGADOR

### Restricciones de entidad

`id_observador` debe ser obligatorio y único.

### Restricciones referenciales

`id_observador` debe existir previamente en `OBSERVADOR`.

`id_departamento` puede ser nulo mientras el investigador todavía no tenga una asignación territorial.

Si existe, debe corresponder a un departamento válido.

### Restricción de especialización

Toda fila de `INVESTIGADOR` representa necesariamente a un observador existente.

Un mismo observador no puede generar más de una fila de investigador.

---

## 6. AVISTAMIENTO

### Restricciones obligatorias

Deben ser no nulos:

- `id_avistamiento`
- `id_observador`
- `id_taxon_propuesto`
- `ubicacion`
- `fecha_hora_avistamiento`
- `numero_individuos`
- `estado`

Pueden ser nulos:

- `id_taxon_validado`
- `id_campania`
- `notas`
- `metodo_validacion`

### Restricciones de dominio

Debe cumplirse:

`numero_individuos > 0`

El estado debe pertenecer al conjunto:

- pendiente
- verificado
- dudoso
- rechazado

### Restricciones temporales

La fecha del avistamiento no debería ser posterior al momento de registro del dato.

Si el proyecto almacena además una fecha de creación del registro, podría verificarse:

`fecha_hora_avistamiento <= fecha_hora_registro`

### Restricción geográfica

El departamento correspondiente al avistamiento debe determinarse espacialmente a partir de `ubicacion` y del polígono de `DEPARTAMENTO`.

No se almacena `id_departamento` como FK en `AVISTAMIENTO`.

### Restricción de validación

Si:

`estado = verificado`

entonces debe existir:

`id_taxon_validado IS NOT NULL`

Cuando `id_taxon_validado` no sea nulo, `metodo_validacion` también debe tener valor.

`metodo_validacion` debe pertenecer a:

- consenso
- investigador

---

## 7. EVIDENCIA

### Restricciones obligatorias

Deben ser no nulos:

- `id_evidencia`
- `id_avistamiento`
- `tipo`
- `ubicacion_recurso`
- `hash_archivo`
- `fecha_carga`

### Restricciones de dominio

`tipo` debe pertenecer a los formatos admitidos por el sistema, inicialmente:

- foto
- audio

### Restricción de integridad

Todo avistamiento debe tener al menos una evidencia.

Esta condición no puede garantizarse únicamente mediante una FK desde `EVIDENCIA`.

Debe controlarse mediante el flujo de inserción del avistamiento o mediante lógica adicional.

### Restricción sobre archivos

Si un mismo archivo físico no debe utilizarse como evidencia múltiples veces:

`UNIQUE (hash_archivo)`

Si se desea permitir reutilización legítima, esta restricción no debe aplicarse de forma global y el hash se utilizaría solamente para detección.

---

## 8. IDENTIFICACION

### Restricciones obligatorias

Deben ser no nulos:

- `id_identificacion`
- `id_avistamiento`
- `id_observador`
- `id_taxon_propuesto`
- `fecha`

### Restricción de unicidad

Debe cumplirse:

`UNIQUE (id_avistamiento, id_observador)`

De esta forma, un observador solo puede mantener una identificación sobre un determinado avistamiento. Si modifica su propuesta, se actualiza esa identificación.

### Restricción del autor

El identificador del observador que realiza la identificación debe ser diferente del autor del avistamiento.

Conceptualmente:

`identificacion.id_observador <> avistamiento.id_observador`

Esta regla depende de otra tabla y no puede implementarse mediante un `CHECK` convencional.

Requiere trigger o lógica transaccional.

---

## 9. DEPARTAMENTO

### Restricciones obligatorias

Deben ser no nulos:

- `id_departamento`
- `nombre`
- `poligono`

### Restricción de unicidad

`nombre` debe ser único.

`UNIQUE (nombre)`

### Restricción geográfica

El polígono debe representar una geometría territorial válida.

La validación específica corresponderá posteriormente al modelo físico.

---

## 10. AREA_PROTEGIDA

### Restricciones obligatorias

Deben ser no nulos:

- `id_area`
- `nombre`
- `categoria`
- `poligono`

### Restricciones de dominio

`categoria` debería pertenecer al catálogo de categorías que utilice el proyecto.

### Restricción geográfica

El polígono debe ser válido y utilizable en las operaciones espaciales previstas.

---

## 11. CELDA_MUESTREO

### Restricciones obligatorias

Deben ser no nulos:

- `id_celda`
- `poligono`

### Restricciones espaciales

Las celdas que formen parte de una misma grilla no deberían superponerse.

Cada punto perteneciente al territorio cubierto por la grilla debería encontrarse, como máximo, dentro de una celda.

Estas condiciones se controlarán durante la generación de la grilla o mediante validaciones espaciales.

---

## 12. CAMPANIA

### Restricciones obligatorias

Deben ser no nulos:

- `id_campania`
- `nombre`
- `fecha_inicio`
- `fecha_fin`

### Restricción temporal

Debe cumplirse:

`fecha_inicio <= fecha_fin`

### Restricción de consistencia

Si un avistamiento pertenece a una campaña, su fecha debería encontrarse dentro del período de dicha campaña.

Debe cumplirse conceptualmente:

`campania.fecha_inicio <= avistamiento.fecha_hora_avistamiento <= campania.fecha_fin`

Como esta regla involucra dos tablas, requerirá validación adicional.

---

## 13. ALERTA

### Restricciones obligatorias

Deben ser no nulos:

- `id_alerta`
- `id_avistamiento`
- `tipo`
- `fecha_generacion`
- `estado`

`id_investigador` puede ser nulo.

### Restricciones de dominio

`tipo` debe pertenecer como mínimo a:

- especie_amenazada
- fuera_rango_geografico
- fuera_temporada

El estado de la alerta puede pertenecer, por ejemplo, a:

- pendiente
- asignada
- resuelta
- descartada

### Restricción de asignación territorial

La alerta puede generarse sin investigador responsable y queda disponible para los investigadores del departamento correspondiente al avistamiento. Cuando uno de ellos asuma la revisión, dicho investigador debe pertenecer a ese departamento.

Esta regla requiere validación entre varias relaciones y un cálculo espacial del departamento del avistamiento.

### Restricción de duplicidad

Para evitar que el mismo evento genere reiteradamente la misma alerta:

`UNIQUE (id_avistamiento, tipo)`

siempre que el negocio establezca que solo puede existir una alerta activa de cada tipo por avistamiento.

---

## 14. DUPLICADO_CANDIDATO

### Restricciones obligatorias

Deben ser no nulos:

- `id_avistamiento_a`
- `id_avistamiento_b`
- `distancia_metros`
- `diferencia_minutos`
- `estado`

### Restricción de identidad

Debe cumplirse:

`id_avistamiento_a <> id_avistamiento_b`

### Restricción de orden

Para representar cada pareja una sola vez:

`id_avistamiento_a < id_avistamiento_b`

De esta forma no pueden coexistir:

`(A, B)`

y:

`(B, A)`

### Restricciones de dominio

Debe cumplirse:

`distancia_metros >= 0`

`diferencia_minutos >= 0`

El estado puede pertenecer a:

- pendiente
- confirmado
- descartado

### Restricción de detección

Cuando el registro sea producido automáticamente bajo las reglas iniciales del proyecto, debe satisfacer:

- mismo taxón;
- observadores diferentes;
- distancia menor a 100 metros;
- diferencia temporal menor a 30 minutos.

---

## 15. AUDITORIA_AVISTAMIENTO

### Restricciones obligatorias

Deben ser no nulos:

- `id_auditoria`
- `id_avistamiento`
- `estado_nuevo`
- `tipo_actor`
- `fecha_hora`

`estado_anterior` puede ser nulo únicamente cuando se registra el estado inicial del avistamiento.

`id_observador_responsable` puede ser nulo cuando la modificación sea automática.

### Restricciones de dominio

`tipo_actor` debe pertenecer a:

- observador
- investigador
- sistema

### Restricción entre atributos

Si:

`tipo_actor = sistema`

entonces:

`id_observador_responsable IS NULL`

Si:

`tipo_actor = observador`

o:

`tipo_actor = investigador`

entonces:

`id_observador_responsable IS NOT NULL`

### Restricción de inmutabilidad

Los registros de auditoría no deben modificarse ni eliminarse después de ser creados.

Las únicas operaciones permitidas sobre esta tabla deben ser inserciones.

# Clasificación de las restricciones

## Implementables mediante claves y restricciones declarativas

Pueden resolverse directamente mediante:

- `PRIMARY KEY`
- `FOREIGN KEY`
- `NOT NULL`
- `UNIQUE`
- `CHECK`

Ejemplos:

- número de individuos mayor que cero;
- meses entre 1 y 12;
- fechas de campaña válidas;
- estados pertenecientes a conjuntos definidos;
- evitar que un duplicado apunte al mismo avistamiento;
- impedir identificaciones duplicadas del mismo observador.

## Requieren lógica adicional

Necesitan triggers, procedimientos o lógica transaccional:

1. Evitar ciclos en la jerarquía taxonómica.
2. Garantizar que únicamente un taxón de rango especie aparezca en `ESPECIE`.
3. Garantizar que toda especie posea al menos una presencia esperada.
4. Garantizar que todo avistamiento posea al menos una evidencia.
5. Impedir que el autor identifique su propio avistamiento.
6. Calcular y actualizar el consenso comunitario.
7. Establecer `id_taxon_validado` y `metodo_validacion` cuando corresponda.
8. Determinar espacialmente el departamento de un avistamiento.
9. Comprobar presencia geográfica y temporal esperada.
10. Generar alertas automáticamente.
11. Permitir que una alerta sea asumida únicamente por investigadores de la zona correspondiente.
12. Validar que un avistamiento asociado a una campaña ocurra durante el período de la campaña.
13. Registrar automáticamente todos los cambios de estado en auditoría.
14. Mantener la auditoría como estructura inmutable.
15. Detectar automáticamente candidatos a duplicado.

# Resultado

Con estas restricciones, el modelo lógico queda protegido en tres niveles:

1. **Integridad de entidad:** cada registro puede identificarse de manera única.
2. **Integridad referencial:** las relaciones entre las tablas siempre apuntan a registros existentes.
3. **Integridad semántica:** los datos almacenados respetan las reglas propias del sistema de ciencia ciudadana.

Las restricciones que involucran únicamente atributos de una fila podrán implementarse declarativamente. Las reglas que requieren consultar otras relaciones, ejecutar cálculos espaciales o analizar el estado del sistema deberán implementarse mediante triggers, procedimientos almacenados o lógica transaccional.
