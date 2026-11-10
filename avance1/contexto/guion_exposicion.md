# Guion de Exposición: Reglas de Negocio (Basado en Diapositiva)

Este guion está diseñado para acompañar la diapositiva "Reglas de negocio principales", e incluye la comparación solicitada con la plataforma eBird.

---

### 1. Introducción y la Inspiración en eBird (1 - 2 minutos)
*Objetivo: Romper el hielo, dar contexto y usar eBird para que el profesor entienda el sistema al instante.*

**Tú:** "Buenos días, profesor. Hoy le presentaré mi proyecto de Base de Datos 2, el cual es un **Sistema de Ciencia Ciudadana para la Biodiversidad**. 

Para que se haga una idea exacta de lo que hemos construido, el sistema tiene una filosofía muy similar a **eBird** (la plataforma del Laboratorio de Ornitología de Cornell). Al igual que en eBird, el objetivo es que cualquier persona con un teléfono o cámara pueda salir a la naturaleza y reportar lo que ve. Sin embargo, sabemos que un usuario común puede equivocarse al identificar un ave o un insecto. Por lo tanto, al igual que eBird, nuestra base de datos no es un simple formulario de registro, sino **un ecosistema complejo donde la información es validada por la comunidad y por expertos** antes de considerarse un dato científico oficial.

Basado en este concepto, definimos las reglas de negocio principales que sustentan nuestro modelo de datos, las cuales vemos en pantalla:"

### 2. Explicación de la Diapositiva: Reglas de Negocio (3 - 4 minutos)
*Objetivo: Leer o parafrasear cada viñeta de la diapositiva explicando cómo la base de datos lo resuelve.*

**Tú:** "[Señalando la primera columna de la diapositiva]

Empezando por los actores del sistema:
* **Todo usuario participa como observador:** Cualquier persona que se registra entra a la tabla `Observador`. Es la base de nuestro sistema.
* **Un observador puede además ser investigador:** Para esto usamos una relación de herencia o extensión en la base de datos. Tenemos una tabla `Investigador` que se vincula al observador, dándole roles de autoridad sobre ciertos `Departamentos` (regiones geográficas).

Sobre cómo se captura la información:
* **Todo avistamiento registra taxón propuesto, ubicación, fecha y número de individuos:** En nuestra tabla `Avistamiento`, aseguramos la calidad del dato con restricciones duras. El usuario siempre indica qué especie cree haber visto (taxón propuesto), cuántos vio (mayor a cero), cuándo y dónde (utilizando tipos de datos espaciales nativos para la ubicación).
* **Otros observadores pueden proponer identificaciones:** Para emular el aspecto de red social científica, tenemos la tabla `Identificacion`. Aquí aplicamos una regla de negocio clave: evitamos que el autor original cree una identificación para su propio avistamiento, forzando a que la discusión venga de terceros.

[Señalando la segunda columna de la diapositiva]

Sobre cómo procesamos y aseguramos esa información:
* **Validación por consenso o investigador:** Un avistamiento nace como 'pendiente'. Para que pase a estado 'verificado', las reglas de la base de datos exigen que se indique el método de validación (ya sea que la comunidad llegó a un acuerdo o que un experto lo validó) y obligatoriamente se debe registrar el `taxón_validado` final.
* **Alertas ante registros anómalos o especies amenazadas:** Aquí entra la automatización (triggers). Si alguien reporta una especie en un departamento o en un mes donde nuestra tabla de `Presencia_Esperada` dice que no debería estar, o si la tabla `Especie` indica que está en peligro de extinción, el sistema dispara automáticamente una `Alerta` para que los investigadores la revisen.
* **Detección de posibles duplicados:** Otro trigger fundamental. Si dos usuarios registran la misma especie, el mismo día, y las funciones espaciales determinan que están a pocos metros de distancia, la base de datos genera un registro de `Duplicado_Candidato`. Esto evita que inflemos falsamente las estadísticas de población de una especie.
* **Auditoría de cambios de estado:** Finalmente, como hablamos de datos científicos, la trazabilidad es vital. Toda vez que un avistamiento cambia de estado (ej. de pendiente a verificado o rechazado), una tabla de `Auditoria_Avistamiento` registra de forma inmutable quién hizo el cambio y cuándo, asegurando la transparencia del proceso."

### 3. Cierre (1 minuto)
*Objetivo: Concluir destacando el diseño.*

**Tú:** "En conclusión, profesor, al igual que las plataformas líderes mundiales como eBird, nuestro diseño de base de datos no es un almacén pasivo. Es un motor activo de reglas que filtra, audita y valida la información ciudadana para convertirla en conocimiento científico estructurado y confiable. 

¿Tiene alguna pregunta sobre cómo implementamos alguna de estas reglas a nivel de SQL?"

---

### 💡 Consejos para la transición eBird -> Diapositiva
*   **Haz énfasis en la "validación"**: La gran diferencia entre un proyecto escolar básico y uno avanzado es cómo tratas la basura ("garbage in, garbage out"). eBird es famoso justo por sus filtros de calidad. Cuando expliques las alertas y duplicados, recuérdale al profesor que esto es exactamente lo que hace eBird para mantener su base de datos limpia.
