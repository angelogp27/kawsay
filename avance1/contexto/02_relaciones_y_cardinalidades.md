# Relaciones y cardinalidades del modelo conceptual

## 1. Taxón — Taxón

**Relación:** `es padre de`

- Un taxón puede ser padre de cero o muchos taxones.
- Un taxón puede tener cero o un taxón padre.
- El taxón ubicado en la raíz de la jerarquía no posee padre.

**Cardinalidad:**

`TAXÓN (0..1) ←→ (0..N) TAXÓN`

Es una relación recursiva que permite representar la jerarquía taxonómica.

---

## 2. Taxón — Especie

**Relación:** `se especializa en`

- Un taxón puede corresponder o no a una especie.
- Toda especie corresponde exactamente a un taxón.
- Solo los taxones cuyo rango sea especie pueden participar en esta especialización.

**Cardinalidad:**

`TAXÓN (1) ←→ (0..1) ESPECIE`

---

## 3. Especie — Presencia esperada

**Relación:** `posee`

- Toda especie debe poseer una o más condiciones de presencia esperada.
- Cada condición de presencia esperada corresponde exactamente a una especie.

**Cardinalidad:**

`ESPECIE (1) ←→ (1..N) PRESENCIA_ESPERADA`

---

## 4. Departamento — Presencia esperada

**Relación:** `delimita`

- Un departamento puede estar asociado con cero o muchas condiciones de presencia esperada.
- Cada condición de presencia esperada corresponde a un único departamento.

**Cardinalidad:**

`DEPARTAMENTO (1) ←→ (0..N) PRESENCIA_ESPERADA`

De esta manera, la presencia esperada de una especie puede variar entre departamentos y períodos del año.

---

## 5. Observador — Investigador

**Relación:** `se especializa en`

- Un observador puede ser o no investigador.
- Todo investigador corresponde exactamente a un observador.

**Cardinalidad:**

`OBSERVADOR (1) ←→ (0..1) INVESTIGADOR`

---

## 6. Departamento — Investigador

**Relación:** `tiene asignado`

- Un departamento puede tener cero o muchos investigadores.
- Un investigador puede estar asignado, como máximo, a un departamento.

**Cardinalidad:**

`DEPARTAMENTO (0..1) ←→ (0..N) INVESTIGADOR`

La asignación territorial del investigador es opcional hasta que se le asigne una zona de responsabilidad.

---

## 7. Observador — Avistamiento

**Relación:** `registra`

- Un observador puede registrar cero o muchos avistamientos.
- Todo avistamiento debe ser registrado por exactamente un observador.

**Cardinalidad:**

`OBSERVADOR (1) ←→ (0..N) AVISTAMIENTO`

---

## 8. Taxón — Avistamiento

Existen **dos relaciones diferentes** entre estas entidades.

### Propuesta inicial

**Relación:** `es propuesto inicialmente en`

- Todo avistamiento debe poseer exactamente un taxón inicialmente propuesto.
- Un taxón puede ser propuesto inicialmente en cero o muchos avistamientos.

**Cardinalidad:**

`TAXÓN (1) ←→ (0..N) AVISTAMIENTO`

### Taxón validado

**Relación:** `es validado como`

- Un avistamiento puede no tener todavía un taxón validado.
- Cuando existe un resultado de validación, este corresponde exactamente a un taxón.
- Un taxón puede ser el taxón validado de cero o muchos avistamientos.

**Cardinalidad:**

`TAXÓN (0..1 por avistamiento) ←→ (0..N) AVISTAMIENTO`

La propuesta inicial y el taxón validado son relaciones independientes, ya que debe conservarse la propuesta original incluso cuando posteriormente sea corregida. El taxón validado puede resultar del consenso comunitario o de la revisión especializada.

---

## 9. Avistamiento — Evidencia

**Relación:** `se respalda con`

- Todo avistamiento debe poseer una o más evidencias.
- Cada evidencia pertenece exactamente a un avistamiento.

**Cardinalidad:**

`AVISTAMIENTO (1) ←→ (1..N) EVIDENCIA`

---

## 10. Observador — Identificación

**Relación:** `realiza`

- Un observador puede realizar cero o muchas identificaciones.
- Cada identificación es realizada por exactamente un observador.

**Cardinalidad:**

`OBSERVADOR (1) ←→ (0..N) IDENTIFICACIÓN`

---

## 11. Avistamiento — Identificación

**Relación:** `recibe`

- Un avistamiento puede recibir cero o muchas identificaciones.
- Cada identificación corresponde exactamente a un avistamiento.
- Un observador puede mantener como máximo una identificación por avistamiento; si cambia su propuesta, se actualiza dicha identificación.

**Cardinalidad:**

`AVISTAMIENTO (1) ←→ (0..N) IDENTIFICACIÓN`

El autor del avistamiento no puede realizar una identificación sobre su propio registro.

---

## 12. Taxón — Identificación

**Relación:** `es propuesto en`

- Cada identificación propone exactamente un taxón.
- Un taxón puede ser propuesto en cero o muchas identificaciones.

**Cardinalidad:**

`TAXÓN (1) ←→ (0..N) IDENTIFICACIÓN`

---

## 13. Departamento — Avistamiento

**Relación:** `ocurre en`

- Todo avistamiento debe encontrarse dentro de un departamento.
- Un departamento puede contener cero o muchos avistamientos.

**Cardinalidad:**

`DEPARTAMENTO (1) ←→ (0..N) AVISTAMIENTO`

La relación se determina a partir de la ubicación geográfica del avistamiento.

---

## 14. Campaña — Avistamiento

**Relación:** `agrupa`

- Una campaña puede agrupar cero o muchos avistamientos.
- Un avistamiento puede pertenecer, como máximo, a una campaña.
- Un avistamiento también puede realizarse fuera de cualquier campaña.

**Cardinalidad:**

`CAMPAÑA (0..1 por avistamiento) ←→ (0..N) AVISTAMIENTO`

---

## 15. Avistamiento — Alerta

**Relación:** `genera`

- Un avistamiento puede generar cero o muchas alertas.
- Cada alerta corresponde exactamente a un avistamiento.

**Cardinalidad:**

`AVISTAMIENTO (1) ←→ (0..N) ALERTA`

Un mismo avistamiento podría generar diferentes alertas; por ejemplo, una por especie amenazada y otra por encontrarse fuera de su distribución esperada.

---

## 16. Investigador — Alerta

**Relación:** `atiende`

- Un investigador puede atender cero o muchas alertas.
- Una alerta puede no tener investigador asignado mientras se encuentre pendiente de atención.
- La alerta queda disponible para los investigadores asignados al departamento correspondiente.
- Cuando uno de ellos asume la revisión, la alerta queda asociada a un único investigador responsable.

**Cardinalidad:**

`INVESTIGADOR (0..1 por alerta) ←→ (0..N) ALERTA`

---

## 17. Área protegida — Avistamiento

**Relación:** `contiene`

- Un área protegida puede contener cero o muchos avistamientos.
- Un avistamiento puede encontrarse dentro de cero o más áreas protegidas.

**Cardinalidad conceptual:**

`ÁREA_PROTEGIDA (0..N) ←→ (0..N) AVISTAMIENTO`

La relación se obtiene mediante cálculo espacial entre el punto del avistamiento y los polígonos de las áreas protegidas. Por ello, no implica necesariamente una relación almacenada mediante claves foráneas en el modelo lógico.

---

## 18. Celda de muestreo — Avistamiento

**Relación:** `contiene`

- Una celda de muestreo puede contener cero o muchos avistamientos.
- Un avistamiento pertenece espacialmente a una celda de la grilla cuando su ubicación se encuentra dentro de sus límites.

**Cardinalidad conceptual:**

`CELDA_MUESTREO (0..1 por avistamiento) ←→ (0..N) AVISTAMIENTO`

La relación se calcula espacialmente y no necesita almacenarse directamente.

---

## 19. Avistamiento — Avistamiento

**Relación:** `es candidato a duplicado de`

- Un avistamiento puede ser candidato a duplicado de cero o muchos otros avistamientos.
- Un avistamiento puede aparecer como candidato de cero o muchos avistamientos.
- Un avistamiento no puede relacionarse consigo mismo.
- La relación es simétrica.

**Cardinalidad:**

`AVISTAMIENTO (0..N) ←→ (0..N) AVISTAMIENTO`

La relación posee información propia, como la distancia espacial, diferencia temporal y estado de evaluación del posible duplicado.

---

## 20. Avistamiento — Auditoría de avistamiento

**Relación:** `registra cambios en`

- Un avistamiento puede poseer cero o muchos registros de auditoría.
- Cada registro de auditoría corresponde exactamente a un avistamiento.

**Cardinalidad:**

`AVISTAMIENTO (1) ←→ (0..N) AUDITORÍA_AVISTAMIENTO`

---

## 21. Observador — Auditoría de avistamiento

**Relación:** `es responsable de`

- Un observador puede ser responsable de cero o muchos cambios registrados.
- Un registro de auditoría puede estar asociado a cero o un observador responsable.
- Cuando el cambio es realizado automáticamente por el sistema, no existe un observador responsable.

**Cardinalidad:**

`OBSERVADOR (0..1 por auditoría) ←→ (0..N) AUDITORÍA_AVISTAMIENTO`
