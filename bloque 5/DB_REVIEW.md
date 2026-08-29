# DB_REVIEW

## Prueba técnica - Corrección de código generado por IA

**Bloque:** 5 - Desafío práctico
**Sección:** 1.6 - Revisión de bases de datos SQL y NoSQL
**Tecnologías:** MariaDB/MySQL y Firebase Firestore

---

# 1. Objetivo

El objetivo de esta revisión es analizar, corregir y justificar el modelo de datos generado inicialmente mediante Inteligencia Artificial.

La revisión contempla dos enfoques:

* Modelo relacional utilizando MariaDB/MySQL.
* Modelo NoSQL utilizando Firebase Firestore.

El análisis considera los siguientes aspectos:

* Integridad de los datos.
* Integridad referencial.
* Normalización.
* Reducción de redundancia.
* Rendimiento de consultas.
* Índices.
* Escalabilidad.
* Costos de operación.
* Patrones de acceso.
* Denormalización controlada.
* Consistencia entre operaciones relacionadas.

El objetivo no es únicamente obtener una estructura funcional, sino diseñar un modelo que pueda mantenerse y escalar de forma adecuada.

---

# 2. Esquema SQL corregido

## 2.1 Base de datos

```sql
CREATE DATABASE IF NOT EXISTS clinica_reservas;

USE clinica_reservas;
```

La base de datos se denomina `clinica_reservas` y contiene las entidades necesarias para gestionar pacientes, especialidades, doctores, horarios, citas y pagos.

---

## 2.2 Tabla `pacientes`

```sql
CREATE TABLE pacientes (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL,
    email VARCHAR(255) NOT NULL,
    telefono VARCHAR(20),
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    fecha_registro TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_pacientes_email UNIQUE (email)
);
```

### Justificación

La versión inicial generada por IA utilizaba:

```sql
id INT AUTO_INCREMENT PRIMARY KEY
```

Se reemplazó por:

```sql
id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY
```

`BIGINT` permite manejar un rango de identificadores considerablemente mayor que `INT`.

El atributo `UNSIGNED` evita valores negativos, los cuales no representan un caso válido para identificadores de entidades.

El campo `email` posee una restricción `UNIQUE`, evitando registrar dos pacientes con la misma dirección de correo.

El campo `activo` permite implementar una eliminación lógica. En lugar de eliminar físicamente un paciente que pueda tener historial de citas, se puede cambiar su estado a `FALSE`.

El campo `fecha_registro` permite conocer cuándo fue creado el registro.

---

## 2.3 Tabla `especialidades`

```sql
CREATE TABLE especialidades (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE,

    CONSTRAINT uq_especialidades_nombre UNIQUE (nombre)
);
```

### Justificación

Las especialidades se manejan como una entidad independiente para evitar almacenar repetidamente el nombre de una especialidad en cada doctor o cita.

La restricción:

```sql
UNIQUE (nombre)
```

evita duplicar especialidades con el mismo nombre.

El atributo `activo` permite deshabilitar una especialidad sin eliminarla físicamente, preservando las relaciones históricas.

---

## 2.4 Tabla `doctores`

```sql
CREATE TABLE doctores (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL,
    especialidad_id BIGINT UNSIGNED NOT NULL,
    email VARCHAR(255) NOT NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE,

    CONSTRAINT uq_doctores_email UNIQUE (email),

    CONSTRAINT fk_doctor_especialidad
        FOREIGN KEY (especialidad_id)
        REFERENCES especialidades(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);
```

### Justificación

La columna `especialidad_id` es una clave foránea que referencia:

```text
especialidades(id)
```

Esto garantiza la integridad referencial y evita asociar un doctor con una especialidad inexistente.

### `ON DELETE RESTRICT`

Impide eliminar una especialidad si existen doctores relacionados con ella.

Esto protege la integridad histórica de los datos.

### `ON UPDATE CASCADE`

Si el identificador de una especialidad cambia, el cambio se propaga automáticamente a las filas relacionadas de `doctores`.

Aunque en la práctica los identificadores autoincrementales normalmente no deberían modificarse, la regla mantiene la relación consistente ante un cambio explícito.

La restricción `UNIQUE` sobre el correo electrónico evita duplicar doctores con la misma dirección.

---

## 2.5 Tabla `horarios_doctores`

```sql
CREATE TABLE horarios_doctores (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    doctor_id BIGINT UNSIGNED NOT NULL,
    dia_semana TINYINT UNSIGNED NOT NULL,
    hora_inicio TIME NOT NULL,
    hora_fin TIME NOT NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE,

    CONSTRAINT fk_horario_doctor
        FOREIGN KEY (doctor_id)
        REFERENCES doctores(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT chk_dia_semana
        CHECK (dia_semana BETWEEN 1 AND 7),

    CONSTRAINT chk_horas_validas
        CHECK (hora_inicio < hora_fin),

    INDEX idx_horarios_doctor_dia
        (doctor_id, dia_semana, hora_inicio)
);
```

### Justificación

Esta tabla representa la disponibilidad habitual de los doctores.

La clave foránea `doctor_id` garantiza que cada horario esté asociado a un doctor existente.

La restricción:

```sql
CHECK (dia_semana BETWEEN 1 AND 7)
```

evita registrar valores inválidos para el día de la semana.

La restricción:

```sql
CHECK (hora_inicio < hora_fin)
```

garantiza que la hora de inicio sea anterior a la hora de finalización.

El índice:

```sql
INDEX idx_horarios_doctor_dia
    (doctor_id, dia_semana, hora_inicio)
```

está orientado a consultas que recuperan el horario de un doctor para un determinado día.

---

## 2.6 Tabla `citas`

```sql
CREATE TABLE citas (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    paciente_id BIGINT UNSIGNED NOT NULL,
    doctor_id BIGINT UNSIGNED NOT NULL,

    fecha_hora DATETIME NOT NULL,

    estado ENUM(
        'pendiente_pago',
        'confirmada',
        'atendida',
        'no_asistio',
        'cancelada'
    ) NOT NULL DEFAULT 'pendiente_pago',

    motivo VARCHAR(500),

    fecha_creacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    fecha_actualizacion TIMESTAMP NOT NULL
        DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_cita_paciente
        FOREIGN KEY (paciente_id)
        REFERENCES pacientes(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_cita_doctor
        FOREIGN KEY (doctor_id)
        REFERENCES doctores(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    INDEX idx_citas_doctor_fecha
        (doctor_id, fecha_hora),

    INDEX idx_citas_paciente_fecha
        (paciente_id, fecha_hora),

    INDEX idx_citas_estado_fecha
        (estado, fecha_hora)
);
```

### Justificación

La tabla `citas` representa la relación entre pacientes y doctores en un momento determinado.

Las columnas `paciente_id` y `doctor_id` son claves foráneas que garantizan que ambos registros existan.

La columna `estado` utiliza `ENUM` para limitar los estados válidos de una cita:

```text
pendiente_pago
confirmada
atendida
no_asistio
cancelada
```

Esto ayuda a mantener la integridad de los datos y evita almacenar estados arbitrarios.

Los campos `fecha_creacion` y `fecha_actualizacion` permiten mantener información de auditoría básica sobre la cita.

### Índices

Se definieron tres índices principales:

```text
idx_citas_doctor_fecha
```

Permite optimizar la consulta de citas de un doctor ordenadas por fecha.

```text
idx_citas_paciente_fecha
```

Permite optimizar la consulta del historial de citas de un paciente.

```text
idx_citas_estado_fecha
```

Facilita consultas relacionadas con estados de las citas y rangos de fechas.

### Corrección respecto al código generado

La definición de `citas` aparecía duplicada en el código revisado.

Esto se corrigió dejando una única definición de la tabla.

---

## 2.7 Tabla `pagos`

```sql
CREATE TABLE pagos (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    cita_id BIGINT UNSIGNED NOT NULL,

    monto DECIMAL(10,2) NOT NULL,

    metodo_pago ENUM(
        'tarjeta',
        'transferencia',
        'efectivo',
        'otro'
    ) NOT NULL,

    estado_pago ENUM(
        'pendiente',
        'aprobado',
        'rechazado',
        'reembolsado'
    ) NOT NULL DEFAULT 'pendiente',

    referencia_externa VARCHAR(255),

    fecha_pago TIMESTAMP NULL DEFAULT NULL,

    fecha_creacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_pago_cita
        UNIQUE (cita_id),

    CONSTRAINT uq_pago_referencia
        UNIQUE (referencia_externa),

    CONSTRAINT fk_pago_cita
        FOREIGN KEY (cita_id)
        REFERENCES citas(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT chk_monto_positivo
        CHECK (monto >= 0),

    INDEX idx_pagos_estado
        (estado_pago)
);
```

### Justificación

La tabla `pagos` se mantiene separada de `citas` porque el pago representa una entidad relacionada con el proceso de reserva.

La columna `cita_id` funciona como clave foránea hacia:

```text
citas(id)
```

La restricción:

```sql
UNIQUE (cita_id)
```

establece que cada cita puede tener como máximo un registro de pago bajo las reglas actuales del sistema.

La restricción:

```sql
UNIQUE (referencia_externa)
```

evita registrar dos pagos con la misma referencia proporcionada por un sistema externo de pagos.

El tipo:

```sql
DECIMAL(10,2)
```

es apropiado para valores monetarios porque permite representar cantidades con dos posiciones decimales evitando los problemas de precisión asociados a tipos de punto flotante.

La restricción:

```sql
CHECK (monto >= 0)
```

evita registrar montos negativos.

Los estados permitidos son:

```text
pendiente
aprobado
rechazado
reembolsado
```

Esto permite representar el ciclo básico del pago.

El índice sobre `estado_pago` facilita consultas administrativas relacionadas con pagos pendientes, aprobados, rechazados o reembolsados.

---

# 3. Relaciones principales del modelo SQL

El modelo presenta las siguientes relaciones:

```text
especialidades
      │
      │ 1:N
      ▼
  doctores
      │
      │ 1:N
      ▼
horarios_doctores


pacientes
      │
      │ 1:N
      ▼
    citas
      ▲
      │ 1:N
      │
  doctores


citas
  │
  │ 1:0..1
  ▼
pagos
```

La relación entre `citas` y `pagos` es uno a cero o uno debido a la restricción:

```sql
UNIQUE (cita_id)
```

Una cita puede no tener todavía un pago o puede tener un único registro de pago.

---

# 4. Consultas críticas adicionales

## 4.1 Agenda de un doctor por rango de fecha

```sql
SELECT
    c.id,
    c.fecha_hora,
    p.nombre AS paciente,
    c.estado,
    c.motivo
FROM citas c
INNER JOIN pacientes p
    ON c.paciente_id = p.id
WHERE c.doctor_id = ?
  AND c.fecha_hora >= ?
  AND c.fecha_hora < ?
ORDER BY c.fecha_hora ASC;
```

### Justificación

Esta consulta permite obtener las citas de un doctor dentro de un rango temporal.

Se utiliza un rango:

```text
fecha_hora >= inicio
fecha_hora < fin
```

en lugar de aplicar funciones directamente sobre la columna `fecha_hora`.

Esto permite aprovechar de mejor manera el índice:

```text
idx_citas_doctor_fecha
```

y presentar la agenda cronológicamente.

---

## 4.2 Historial de citas de un paciente

```sql
SELECT
    c.id,
    c.fecha_hora,
    d.nombre AS doctor,
    e.nombre AS especialidad,
    c.estado,
    c.motivo
FROM citas c
INNER JOIN doctores d
    ON c.doctor_id = d.id
INNER JOIN especialidades e
    ON d.especialidad_id = e.id
WHERE c.paciente_id = ?
ORDER BY c.fecha_hora DESC;
```

### Justificación

Permite recuperar el historial de citas de un paciente desde la más reciente hasta la más antigua.

La información del doctor y de la especialidad se obtiene mediante relaciones, evitando duplicar esos datos en la tabla `citas`.

La consulta aprovecha el índice:

```text
idx_citas_paciente_fecha
```

---

## 4.3 Pagos pendientes

```sql
SELECT
    p.id,
    p.cita_id,
    p.monto,
    p.metodo_pago,
    p.estado_pago,
    p.fecha_creacion
FROM pagos p
WHERE p.estado_pago = 'pendiente'
ORDER BY p.fecha_creacion ASC;
```

### Justificación

Esta consulta permite identificar pagos que aún no han sido aprobados o rechazados.

Es especialmente útil para procesos administrativos o para un servicio encargado de verificar el estado de los pagos.

El índice:

```text
idx_pagos_estado
```

permite optimizar el filtrado por estado.

---

# 5. Análisis de estructura NoSQL - Firestore

## 5.1 Estructura original generada por IA

La estructura inicial propuesta fue:

```text
appointments/{appointmentId}
```

con los siguientes campos:

```text
patientName: string
patientEmail: string
doctorName: string
specialty: string
dateTime: Date
status: string
notes: string
paymentMethod: string
paymentStatus: string
paymentAmount: number
```

También se proporcionó la siguiente consulta para obtener las citas del día:

```javascript
async function getTodaysAppointments() {
    const today = new Date();

    today.setHours(0, 0, 0, 0);

    const tomorrow = new Date(today);

    tomorrow.setDate(tomorrow.getDate() + 1);

    const snapshot = await db
        .collection('appointments')
        .where('dateTime', '>=', today)
        .where('dateTime', '<', tomorrow)
        .get();

    return snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
    }));
}
```

La consulta es funcional y utiliza correctamente un rango de fechas para recuperar las citas correspondientes a un día.

Sin embargo, la estructura general puede mejorarse considerando los diferentes patrones de acceso del sistema.

---

# 6. Patrones de acceso requeridos

El diseño de Firestore se realiza a partir de las operaciones que realizará la aplicación.

Los principales patrones identificados son:

1. Obtener las citas de un día.
2. Obtener la agenda de un doctor para una fecha determinada.
3. Obtener el historial de citas de un paciente.
4. Consultar la disponibilidad de un doctor.
5. Consultar citas según su estado.
6. Crear una cita.
7. Cancelar una cita.
8. Liberar el horario asociado a una cita.
9. Registrar una notificación para el paciente.
10. Consultar el estado del pago.
11. Gestionar el reembolso de un pago.

Firestore debe diseñarse teniendo en cuenta estos patrones de acceso y no intentando replicar exactamente el modelo normalizado utilizado en SQL.

---

# 7. Evaluación de la estructura original

## 7.1 Duplicación de información

La estructura inicial almacena:

```text
patientName
patientEmail
doctorName
specialty
```

directamente dentro de cada cita.

Por ejemplo, si un paciente tiene 50 citas, su nombre y correo podrían almacenarse 50 veces.

De igual manera, los datos del doctor pueden repetirse en numerosas citas.

La duplicación no es necesariamente incorrecta en Firestore.

En un modelo NoSQL, la denormalización controlada puede ser beneficiosa porque permite realizar lecturas más rápidas y evitar consultas adicionales.

Sin embargo, debe existir una estrategia para mantener los datos duplicados consistentes.

---

## 7.2 Falta de identificadores

La estructura inicial no contiene:

```text
patientId
doctorId
specialtyId
```

Estos identificadores son importantes para realizar consultas específicas y mantener referencias lógicas entre documentos.

Por esta razón, el rediseño incorpora estos identificadores.

---

## 7.3 Gestión de disponibilidad

La estructura inicial solamente contiene:

```text
dateTime
```

pero no representa explícitamente el horario o slot utilizado.

Esto dificulta:

* Reservar un horario.
* Liberar un horario.
* Bloquear un horario.
* Evitar doble reserva.

Por este motivo se propone una estructura independiente para los slots.

---

## 7.4 Falta de paginación

La consulta inicial recupera todos los documentos correspondientes al día.

Aunque puede funcionar para volúmenes pequeños, una aplicación de mayor escala debería limitar los resultados y utilizar paginación cuando corresponda.

Firestore permite utilizar:

```text
limit()
startAfter()
```

para implementar paginación basada en cursores.

---

## 7.5 Manejo del pago

La estructura original contiene:

```text
paymentMethod
paymentStatus
paymentAmount
```

Se propone agrupar esta información dentro de un objeto:

```text
payment
```

Esto mantiene relacionados los atributos pertenecientes al pago y facilita su lectura dentro del documento de la cita.

---

# 8. Escalabilidad y costos

Firestore cobra por operaciones como lecturas, escrituras y eliminaciones.

Por esta razón, el modelo debe evitar lecturas innecesarias.

No es recomendable recuperar grandes cantidades de documentos para después filtrarlos en la aplicación.

Es preferible utilizar directamente:

```text
where()
orderBy()
limit()
startAfter()
```

para reducir la cantidad de documentos procesados.

La denormalización controlada puede incluso disminuir costos cuando evita realizar lecturas adicionales.

Por ejemplo, almacenar:

```text
doctorName
patientName
specialtyName
```

en la cita puede evitar consultar los documentos de doctor, paciente y especialidad solamente para presentar información descriptiva.

La desventaja es que los datos duplicados deben actualizarse cuando cambie la información original.

Por lo tanto, se debe establecer claramente qué campos son fuente de verdad y cuáles son copias optimizadas para lectura.

---

# 9. Rediseño de datos para Firestore

La estructura propuesta es:

```text
patients/{patientId}

doctors/{doctorId}

appointments/{appointmentId}

doctorSchedules/{doctorId}/slots/{slotId}

notifications/{notificationId}
```

El modelo utiliza normalización selectiva y denormalización controlada.

---

# 10. Colección `patients`

```text
patients/{patientId}
```

Ejemplo:

```json
{
    "name": "Juan Pérez",
    "email": "juan@example.com",
    "phone": "3000000000",
    "active": true,
    "createdAt": "Timestamp"
}
```

### Justificación

La información principal del paciente se almacena en un documento independiente.

Las citas almacenan `patientId` como identificador lógico del paciente.

Se puede mantener adicionalmente `patientName` dentro de la cita como una copia orientada a lectura.

---

# 11. Colección `doctors`

```text
doctors/{doctorId}
```

Ejemplo:

```json
{
    "name": "Carlos Gómez",
    "specialtyId": "CARD",
    "specialtyName": "Cardiología",
    "email": "doctor@example.com",
    "active": true,
    "createdAt": "Timestamp"
}
```

### Justificación

Los datos principales del doctor se mantienen en un documento independiente.

`specialtyId` permite identificar la especialidad.

`specialtyName` puede mantenerse como dato desnormalizado para evitar lecturas adicionales cuando solamente se necesita presentar el nombre de la especialidad.

---

# 12. Colección `appointments`

```text
appointments/{appointmentId}
```

Ejemplo:

```json
{
    "patientId": "PAT001",
    "patientName": "Juan Pérez",

    "doctorId": "DOC001",
    "doctorName": "Carlos Gómez",

    "specialtyId": "CARD",
    "specialtyName": "Cardiología",

    "slotId": "2026-08-28_1000",

    "dateTime": "Timestamp",
    "dateKey": "2026-08-28",

    "status": "confirmed",

    "notes": "Consulta de control",

    "payment": {
        "method": "card",
        "status": "paid",
        "amount": 80000
    },

    "createdAt": "Timestamp",
    "updatedAt": "Timestamp"
}
```

### Justificación

La cita mantiene los identificadores:

```text
patientId
doctorId
specialtyId
```

para permitir consultas eficientes.

También mantiene determinados datos descriptivos:

```text
patientName
doctorName
specialtyName
```

como información desnormalizada.

Esta decisión evita realizar lecturas adicionales únicamente para presentar los nombres dentro de una agenda.

La información duplicada debe actualizarse mediante una estrategia definida si cambia el registro principal.

---

# 13. Representación del pago en Firestore

En SQL, `pagos` se mantiene como una tabla independiente.

En Firestore se propone representar el pago dentro de la cita:

```json
{
    "payment": {
        "method": "card",
        "status": "paid",
        "amount": 80000
    }
}
```

### Justificación

Esta decisión corresponde a una estrategia de denormalización controlada.

El pago está directamente relacionado con la cita y normalmente será consultado como parte del contexto de la reserva.

Además, el modelo SQL establece actualmente una relación uno a cero o uno entre `citas` y `pagos`, mediante:

```sql
UNIQUE (cita_id)
```

Por lo tanto, mantener el pago dentro del documento de la cita es coherente con la regla de negocio actual.

Si en el futuro el sistema requiere múltiples transacciones por una misma cita, como pagos parciales, reintentos o múltiples reembolsos, sería conveniente convertir los pagos en una subcolección:

```text
appointments/{appointmentId}/payments/{paymentId}
```

Esto permitiría evolucionar el modelo sin cambiar completamente la estructura de las citas.

---

# 14. Subcolección de horarios

```text
doctorSchedules/{doctorId}/slots/{slotId}
```

Ejemplo:

```json
{
    "date": "2026-08-28",
    "startTime": "10:00",
    "endTime": "10:30",
    "status": "booked",
    "appointmentId": "APT001"
}
```

Estados posibles:

```text
available
booked
blocked
```

### Justificación

El slot representa un recurso independiente de la cita.

Esto permite controlar explícitamente la disponibilidad.

Cuando una cita es creada, el slot pasa a:

```text
booked
```

Cuando una cita es cancelada:

```text
available
```

Esto facilita controlar la disponibilidad y reduce el riesgo de doble reserva.

---

# 15. Colección `notifications`

```text
notifications/{notificationId}
```

Ejemplo:

```json
{
    "patientId": "PAT001",
    "appointmentId": "APT001",
    "type": "appointment_cancelled",
    "message": "Su cita ha sido cancelada.",
    "read": false,
    "createdAt": "Timestamp"
}
```

### Justificación

Las notificaciones se mantienen separadas de las citas.

Esto permite registrar eventos relacionados con diferentes operaciones del sistema sin aumentar innecesariamente el documento de la cita.

También permite implementar posteriormente diferentes canales de notificación.

---

# 16. Operación compleja: cancelar una cita

La cancelación de una cita requiere coordinar diferentes acciones:

```text
Obtener cita
      ↓
Validar existencia
      ↓
Validar estado
      ↓
Obtener slot
      ↓
Cancelar cita
      ↓
Liberar slot
      ↓
Actualizar estado del pago
      ↓
Crear notificación
```

Se propone utilizar una transacción de Firestore para mantener la consistencia de los cambios realizados dentro de Firestore.

```javascript
async function cancelAppointment(appointmentId) {
    const appointmentRef = db
        .collection("appointments")
        .doc(appointmentId);

    await db.runTransaction(async (transaction) => {

        const appointmentSnapshot =
            await transaction.get(appointmentRef);

        if (!appointmentSnapshot.exists) {
            throw new Error("La cita no existe");
        }

        const appointment = appointmentSnapshot.data();

        if (appointment.status === "cancelled") {
            throw new Error("La cita ya está cancelada");
        }

        const slotRef = db
            .collection("doctorSchedules")
            .doc(appointment.doctorId)
            .collection("slots")
            .doc(appointment.slotId);

        const slotSnapshot =
            await transaction.get(slotRef);

        transaction.update(appointmentRef, {
            status: "cancelled",
            cancelledAt: new Date(),
            updatedAt: new Date()
        });

        if (slotSnapshot.exists) {
            transaction.update(slotRef, {
                status: "available",
                appointmentId: null
            });
        }

        if (appointment.payment?.status === "paid") {
            transaction.update(appointmentRef, {
                "payment.status": "refund_pending"
            });
        }

        const notificationRef = db
            .collection("notifications")
            .doc();

        transaction.set(notificationRef, {
            patientId: appointment.patientId,
            appointmentId: appointmentId,
            type: "appointment_cancelled",
            message: "Su cita ha sido cancelada.",
            read: false,
            createdAt: new Date()
        });
    });

    return {
        success: true,
        message: "Cita cancelada correctamente"
    };
}
```

---

# 17. Consideraciones sobre el reembolso

El reembolso no debe ejecutarse directamente dentro de la transacción de Firestore.

Cuando una cita pagada es cancelada, se cambia inicialmente el estado a:

```text
refund_pending
```

Posteriormente, un proceso backend puede comunicarse con el proveedor externo de pagos.

Esto evita ejecutar una operación externa no transaccional dentro de una transacción de Firestore.

El proceso de reembolso debería contemplar estados como:

```text
paid
refund_pending
refunded
refund_failed
```

También debe considerar:

* Reintentos.
* Fallos del proveedor externo.
* Registro de errores.
* Confirmación del reembolso.
* Idempotencia.

La idempotencia es especialmente importante para evitar que un mismo reembolso sea procesado dos veces.

---

# 18. Operación compleja: historial de citas de un paciente

El historial debe:

* Filtrar por `patientId`.
* Ordenar por fecha descendente.
* Limitar la cantidad de resultados.
* Permitir obtener una página siguiente.

```javascript
async function getPatientAppointments(
    patientId,
    pageSize = 10,
    lastDocument = null
) {
    let query = db
        .collection("appointments")
        .where("patientId", "==", patientId)
        .orderBy("dateTime", "desc")
        .limit(pageSize);

    if (lastDocument) {
        query = query.startAfter(lastDocument);
    }

    const snapshot = await query.get();

    const appointments = snapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data()
    }));

    const nextPageToken =
        snapshot.docs.length > 0
            ? snapshot.docs[snapshot.docs.length - 1]
            : null;

    return {
        appointments,
        nextPageToken
    };
}
```

---

# 19. Justificación de la paginación

La consulta utiliza:

```javascript
limit(pageSize)
```

para controlar el número máximo de documentos recuperados.

Posteriormente:

```javascript
startAfter(lastDocument)
```

permite continuar desde el último documento de la página anterior.

Esto evita descargar todo el historial del paciente cada vez que se solicita una página.

La estrategia resulta especialmente importante cuando un paciente posee un historial de muchas citas.

---

# 20. Índices de Firestore

Las consultas deben diseñarse considerando los índices requeridos.

Para el historial del paciente se debe considerar un índice compuesto equivalente a:

```text
Collection: appointments

patientId ASC
dateTime DESC
```

Este índice soporta el patrón:

```javascript
.where("patientId", "==", patientId)
.orderBy("dateTime", "desc")
```

También debe considerarse un índice para consultas relacionadas con:

```text
doctorId
dateTime
```

cuando se necesite obtener la agenda de un doctor ordenada cronológicamente.

Firestore puede solicitar automáticamente la creación de un índice cuando una consulta requiere uno que todavía no existe.

Los índices deben configurarse de acuerdo con las consultas reales utilizadas por la aplicación.

---

# 21. Prevención de doble reserva

Un problema importante en un sistema de citas es la posibilidad de que dos usuarios intenten reservar el mismo horario simultáneamente.

Para reducir este riesgo, el slot del doctor se considera un recurso independiente:

```text
doctorSchedules/{doctorId}/slots/{slotId}
```

La reserva debe verificar que el estado actual sea:

```text
available
```

y cambiarlo a:

```text
booked
```

dentro de una transacción.

El objetivo es que dos operaciones concurrentes no puedan considerar disponible el mismo slot.

El patrón conceptual sería:

```text
Leer slot
   ↓
¿Está disponible?
   ↓
Sí
   ↓
Reservar slot
   ↓
Crear cita
```

Si el slot ya fue reservado por otra operación, la transacción debe fallar o reintentarse y la aplicación debe informar que el horario ya no está disponible.

---

# 22. Comparación entre el modelo SQL y Firestore

| Aspecto        | SQL                       | Firestore                            |
| -------------- | ------------------------- | ------------------------------------ |
| Pacientes      | Tabla `pacientes`         | Colección `patients`                 |
| Doctores       | Tabla `doctores`          | Colección `doctors`                  |
| Especialidades | Tabla `especialidades`    | Campo/referencia lógica              |
| Horarios       | Tabla `horarios_doctores` | Subcolección `slots`                 |
| Citas          | Tabla `citas`             | Colección `appointments`             |
| Pagos          | Tabla `pagos`             | Objeto `payment` dentro de la cita   |
| Integridad     | FK y restricciones        | Reglas de seguridad + lógica backend |
| Consultas      | JOIN                      | Consultas orientadas a documentos    |
| Redundancia    | Se minimiza               | Se permite de forma controlada       |
| Paginación     | LIMIT/OFFSET o cursores   | limit/startAfter                     |
| Consistencia   | Transacciones SQL         | Transacciones/batches de Firestore   |

El modelo SQL prioriza la normalización e integridad referencial.

El modelo Firestore prioriza los patrones de acceso y la reducción de lecturas innecesarias mediante denormalización controlada.

Por lo tanto, ambos modelos representan el mismo dominio, pero utilizan estrategias diferentes debido a las características de cada motor.

---

# 23. Conclusiones

El análisis permitió identificar que la estructura inicial generada por IA era funcional para un escenario sencillo, pero requería modificaciones para soportar adecuadamente los patrones de acceso y crecimiento del sistema.

En el modelo SQL se priorizó la integridad referencial, la reducción de redundancia, el uso de restricciones y la creación de índices alineados con las consultas principales.

Se utilizaron claves `BIGINT UNSIGNED` para los identificadores, restricciones `UNIQUE` para evitar duplicidad, claves foráneas para mantener la integridad referencial y restricciones `CHECK` y `ENUM` para limitar valores inválidos.

En Firestore se adoptó un modelo orientado a los patrones de acceso, incorporando identificadores para pacientes, doctores y especialidades.

Se aplicó denormalización controlada mediante la duplicación selectiva de información descriptiva como nombres de pacientes, doctores y especialidades, con el objetivo de reducir lecturas adicionales.

También se incorporó una estructura independiente para los slots de los doctores, permitiendo gestionar la disponibilidad y reducir el riesgo de doble reserva.

Las operaciones complejas fueron diseñadas considerando consistencia y escalabilidad.

La cancelación de una cita actualiza su estado, libera el horario, genera una notificación y establece el estado `refund_pending` cuando corresponde.

El reembolso real se mantiene desacoplado de la transacción de Firestore debido a que normalmente depende de un proveedor externo.

Finalmente, el historial de citas utiliza paginación basada en cursores mediante `limit()` y `startAfter()`, evitando recuperar grandes cantidades de documentos innecesariamente.

El resultado es un diseño que busca equilibrar consistencia, rendimiento, escalabilidad, mantenibilidad y costos, aplicando las características propias de cada modelo de base de datos en lugar de utilizar el mismo patrón de diseño para SQL y NoSQL.
