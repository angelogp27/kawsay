# Reglas de negocio

## Gestión de usuarios y observadores

**RN01 — Registro de usuarios.**
Toda persona que participe en la plataforma debe estar registrada como observador. Un observador puede registrar avistamientos y participar en la identificación de avistamientos realizados por otros usuarios.

**RN02 — Investigadores.**
Un observador puede desempeñar la función de investigador. Los investigadores son responsables de revisar los avistamientos anómalos correspondientes al territorio que tengan asignado.

**RN03 — Asignación territorial de investigadores.**
Cada investigador puede estar asignado, como máximo, a un departamento. Un departamento puede tener asignados varios investigadores.

**RN04 — Reputación.**
Todo observador posee una reputación acumulada que puede modificarse de acuerdo con la validación de sus aportes. La verificación de un avistamiento puede incrementar la reputación de su autor.

## Gestión de avistamientos

**RN05 — Registro de avistamientos.**
Todo avistamiento debe ser registrado por un único observador y debe indicar, como mínimo, el taxón inicialmente propuesto, la ubicación geográfica, la fecha y hora de observación y el número de individuos observados.

**RN06 — Propuesta taxonómica inicial.**
Todo avistamiento debe tener exactamente un taxón propuesto inicialmente por su autor. Esta propuesta debe conservarse aun cuando posteriormente el proceso de validación determine un taxón validado diferente.

**RN07 — Evidencias.**
Todo avistamiento debe estar respaldado por una o más evidencias multimedia, como fotografías o audios. Cada evidencia pertenece a un único avistamiento.

**RN08 — Estado del avistamiento.**
Todo avistamiento posee un estado que representa su situación dentro del proceso de validación. Los estados contemplados son: pendiente, verificado, dudoso y rechazado.

**RN09 — Ubicación territorial.**
Todo avistamiento ocurre en un único punto geográfico y debe poder determinarse el departamento dentro del cual se encuentra dicho punto.

## Identificación y consenso comunitario

**RN10 — Identificación comunitaria.**
Un observador puede proponer una identificación taxonómica para un avistamiento registrado por otro observador. Cada identificación corresponde a un único observador, un único avistamiento y un único taxón propuesto.

**RN11 — Una identificación por observador.**
Un observador puede mantener como máximo una identificación para un mismo avistamiento. Si modifica su propuesta, se actualiza dicha identificación.

**RN12 — Restricción del autor.**
El observador que registró un avistamiento no puede realizar una identificación comunitaria sobre ese mismo avistamiento, debido a que su propuesta ya se encuentra representada por el taxón inicialmente propuesto.

**RN13 — Consenso taxonómico.**
El consenso comunitario se determina a partir de las identificaciones realizadas por la comunidad cuando se alcanza el umbral de acuerdo establecido por el sistema.

**RN14 — Verificación.**
Un avistamiento puede pasar al estado verificado cuando obtiene un taxón validado. Este puede resultar del consenso comunitario o de la revisión especializada realizada por un investigador, debiendo quedar registrado el método de validación utilizado.

## Taxonomía y especies

**RN15 — Jerarquía taxonómica.**
Los taxones se organizan jerárquicamente. Un taxón puede depender de un taxón superior y puede contener múltiples taxones inferiores. La jerarquía debe permitir representar los rangos reino, filo, clase, orden, familia, género y especie.

**RN16 — Información específica de especies.**
Los taxones cuyo rango sea especie poseen información adicional propia de dicho nivel, incluyendo nombre común, estado de conservación, condición endémica y condición migratoria.

**RN17 — Distribución geográfica y temporal esperada.**
Toda especie debe tener definida su distribución geográfica esperada y el período del año en el que se espera su presencia. Una especie puede presentar diferentes condiciones de presencia según la zona geográfica y la temporada.

**RN18 — Múltiples condiciones de presencia.**
Una especie puede poseer múltiples condiciones de presencia esperada. Cada condición establece una zona geográfica y el período del año durante el cual la presencia de la especie se considera esperada en dicha zona.

## Alertas y revisión especializada

**RN19 — Detección de anomalías.**
El sistema debe detectar los avistamientos que se encuentren fuera de la distribución geográfica o del período temporal esperado para la especie identificada. Estos casos deben ser marcados para revisión especializada.

**RN20 — Especies amenazadas.**
Cuando un avistamiento corresponda a una especie considerada amenazada, el sistema debe generar una alerta para su tratamiento especializado.

**RN21 — Gestión de alertas.**
Un avistamiento puede generar cero o más alertas. Cada alerta corresponde a un único avistamiento y puede permanecer inicialmente sin investigador responsable.

**RN22 — Enrutamiento territorial de alertas.**
Las alertas que requieran revisión especializada deben quedar disponibles para los investigadores asignados al departamento en el que ocurrió el avistamiento. Cuando uno de ellos asume la revisión, queda registrado como responsable de la alerta.

## Contexto territorial y campañas

**RN23 — Áreas protegidas.**
La pertenencia de un avistamiento a un área protegida debe determinarse espacialmente a partir de la ubicación del avistamiento y del polígono correspondiente al área protegida. Esta pertenencia no constituye una asignación manual.

**RN24 — Campañas de observación.**
Un avistamiento puede realizarse de manera independiente o formar parte de una campaña de observación. Una campaña puede agrupar múltiples avistamientos y debe poseer un período definido de inicio y fin.

## Detección de duplicados

**RN25 — Detección de posibles duplicados.**
Dos avistamientos realizados por observadores diferentes pueden ser considerados candidatos a representar un mismo evento cuando corresponden al mismo taxón y cumplen los criterios de proximidad espacial y temporal establecidos por el sistema.

**RN26 — Criterios de proximidad.**
Para la detección automática de candidatos a duplicados se consideran, inicialmente, avistamientos del mismo taxón registrados a menos de 100 metros de distancia y con una diferencia temporal menor a 30 minutos.

**RN27 — Simetría de duplicados.**
Si un avistamiento A es candidato a duplicado de un avistamiento B, dicha relación representa el mismo caso que B respecto de A. Un avistamiento nunca puede ser candidato a duplicado de sí mismo.

## Auditoría

**RN28 — Auditoría de estados.**
Todo cambio de estado de un avistamiento debe quedar registrado de manera histórica e inmutable, indicando el estado anterior, el nuevo estado, la fecha y hora del cambio y el responsable cuando corresponda.

**RN29 — Cambios automáticos.**
Los cambios de estado realizados automáticamente por el sistema también deben quedar registrados en la auditoría, diferenciándolos de aquellos efectuados por un observador o investigador.
