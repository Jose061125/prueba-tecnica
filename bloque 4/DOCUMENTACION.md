# DOCUMENTACION.md

# Síntesis y Documentación Estratégica

## 1. Introducción

Este documento registra las principales decisiones técnicas tomadas para el sistema de reservas de una clínica médica. Su objetivo es proporcionar contexto suficiente para que el equipo encargado del mantenimiento, nuevos desarrolladores y asistentes de inteligencia artificial puedan comprender la arquitectura, las reglas de negocio y los criterios técnicos utilizados.

El sistema permite a los pacientes agendar, reprogramar y cancelar citas médicas. Los doctores pueden consultar su agenda y registrar el estado de las citas, mientras que los administradores pueden gestionar doctores, especialidades y horarios.

Debido a que el sistema maneja información personal y relacionada con servicios de salud, las decisiones de arquitectura priorizan seguridad, integridad de los datos, trazabilidad y mantenibilidad.

---

# 2. ADR-001: Decisión de Stack Tecnológico

- **ID:** ADR-001
- **Título:** Selección del stack tecnológico
- **Estado:** Aceptado
- **Fecha:** 2026-08-27

## Contexto

El sistema debe ser desarrollado en un periodo aproximado de tres semanas y será utilizado por una clínica pequeña o mediana con aproximadamente 3 a 5 sucursales y alrededor de 50 doctores.

El sistema debe manejar:

- Pacientes.
- Doctores.
- Especialidades.
- Horarios.
- Citas.
- Reprogramaciones.
- Cancelaciones.
- Pagos.
- Recordatorios.
- Usuarios administrativos.

Además, la información manejada puede ser sensible, por lo que se requiere una solución que permita implementar controles de seguridad y mantener la integridad de los datos.

Se evaluaron tres alternativas:

1. Vue 3 + Firebase.
2. Next.js + PostgreSQL.
3. Python FastAPI + React + MySQL.

## Decisión

Se selecciona **Next.js + PostgreSQL**.

La aplicación utilizará Next.js como framework principal y PostgreSQL como sistema de gestión de base de datos relacional.

La solución se implementará inicialmente como un **monolito modular**, manteniendo separación lógica entre los principales dominios del sistema.

```text
Aplicación
│
├── Auth
├── Pacientes
├── Doctores
├── Especialidades
├── Horarios
├── Citas
├── Pagos
└── Notificaciones
        │
        ▼
    PostgreSQL
```

Los límites entre módulos deberán mantenerse claros para permitir que determinados componentes puedan ser extraídos posteriormente a servicios independientes si el crecimiento del sistema lo justifica.

## Consecuencias positivas

- Menor complejidad operacional.
- Menor cantidad de componentes que mantener.
- Desarrollo más rápido.
- Facilita el desarrollo dentro del plazo establecido.
- PostgreSQL permite manejar relaciones entre entidades de manera natural.
- Las transacciones facilitan mantener la consistencia de operaciones internas.
- Se pueden aplicar restricciones de integridad en la base de datos.
- Facilita el debugging.
- Reduce el costo inicial de infraestructura.

## Consecuencias negativas

- El backend representa inicialmente una unidad de despliegue.
- Algunos módulos no podrán escalar independientemente.
- Un error grave en la aplicación podría afectar diferentes módulos.
- Si el sistema crece significativamente, podrían ser necesarias futuras extracciones de módulos.

Estas consecuencias se consideran aceptables para el tamaño y alcance inicial del proyecto.

## Alternativas consideradas

### Alternativa 1: Vue 3 + Firebase

Se descartó como primera opción debido a que el dominio contiene relaciones fuertes entre pacientes, citas, doctores, horarios y pagos.

Firestore puede funcionar correctamente, pero el modelo documental puede resultar menos conveniente para las relaciones y consultas complejas que requiere el sistema.

Además, las reglas de seguridad de Firebase tendrían que diseñarse y auditarse cuidadosamente debido a la sensibilidad de los datos.

Esta alternativa seguiría siendo viable para un MVP donde la velocidad de desarrollo y el bajo mantenimiento de infraestructura fueran las prioridades principales.

### Alternativa 2: FastAPI + React + MySQL

Es una alternativa técnicamente válida y adecuada para sistemas empresariales.

Sin embargo, introduce una separación adicional entre frontend y backend y puede aumentar el trabajo de integración para un equipo pequeño con un plazo de tres semanas.

Se descartó para esta primera versión porque Next.js permite reducir parte de esa complejidad manteniendo una arquitectura organizada.

## Resultado esperado

El stack seleccionado permite priorizar velocidad de desarrollo, consistencia de datos, seguridad y facilidad de mantenimiento, manteniendo abierta la posibilidad de evolucionar hacia una arquitectura distribuida cuando exista una necesidad real.

---

# 3. ADR-002: Consistencia entre citas y pagos

- **ID:** ADR-002
- **Título:** Manejo de consistencia entre reservas y pagos
- **Estado:** Aceptado
- **Fecha:** 2026-08-27

## Contexto

El proceso de reserva puede involucrar una operación interna y un proveedor externo de pagos.

Un escenario posible es:

```text
Paciente
   │
   ▼
Crear cita
   │
   ▼
Intentar pago
   │
   ▼
Pago rechazado
```

Si la aplicación confirma inmediatamente la cita antes de conocer el resultado del pago, podría quedar una cita activa sin pago confirmado.

Además, Stripe es un sistema externo y no puede participar directamente en una transacción ACID de PostgreSQL.

Por lo tanto, es necesario establecer un mecanismo que permita representar estados intermedios y garantizar que el sistema pueda recuperarse correctamente ante errores.

## Decisión

Se utilizará un flujo basado en **estados de la reserva**, transacciones para operaciones internas, Stripe como proveedor de pagos y webhooks para confirmar el resultado del pago.

Los estados principales serán conceptualmente:

```text
PENDING_PAYMENT
      │
      ├──── Pago exitoso ────► CONFIRMED
      │
      └──── Pago fallido ────► CANCELLED
```

El flujo será:

```text
1. El paciente selecciona un horario.
2. El backend valida nuevamente la disponibilidad.
3. Se crea una reserva en estado PENDING_PAYMENT.
4. Se inicia el proceso de pago con Stripe.
5. Stripe procesa el pago.
6. Stripe notifica el resultado mediante webhook.
7. El backend valida el webhook.
8. Si el pago fue exitoso, la cita pasa a CONFIRMED.
9. Si el pago falla o expira, la reserva pasa a CANCELLED.
10. El horario vuelve a estar disponible cuando corresponda.
```

El backend no confiará únicamente en una respuesta enviada por el frontend para determinar si un pago fue exitoso.

También se implementará **idempotencia** para evitar que un mismo evento de pago sea procesado múltiples veces.

## Consecuencias positivas

- Reduce el riesgo de confirmar citas sin pago.
- Permite manejar estados intermedios.
- Stripe mantiene la responsabilidad de procesar el pago.
- Los webhooks permiten recibir confirmaciones desde el proveedor.
- La idempotencia evita duplicar operaciones.
- El sistema puede recuperarse de errores y reintentos.
- La solución es compatible con el monolito modular propuesto.

## Consecuencias negativas

- Aumenta la complejidad del flujo de reserva.
- Se deben manejar estados intermedios.
- Es necesario implementar correctamente los webhooks.
- Deben contemplarse eventos duplicados.
- Puede existir un pequeño periodo en el que una reserva permanezca pendiente.
- Se requiere un mecanismo para liberar reservas pendientes que hayan expirado.

## Alternativas consideradas

### Alternativa 1: Saga

El patrón Saga sería apropiado si el sistema estuviera construido como una arquitectura distribuida con varios microservicios.

Podría funcionar de la siguiente forma:

```text
Crear reserva
      ↓
Procesar pago
      ↓
Confirmar cita
      ↓
Si falla → acción compensatoria
```

Se descartó como solución principal porque la arquitectura recomendada es un monolito modular y no se justifica introducir la complejidad de una Saga para el tamaño actual del sistema.

Sin embargo, podría reconsiderarse si en el futuro el sistema evoluciona hacia microservicios.

### Alternativa 2: Transacciones distribuidas

Una transacción distribuida podría intentar coordinar diferentes sistemas dentro de una única operación.

Se descartó porque Stripe es un proveedor externo y no debe asumirse que participa en una transacción distribuida tradicional con nuestra base de datos.

Además, introduce complejidad operacional innecesaria.

### Alternativa 3: Confirmar la cita inmediatamente y corregir después

Otra alternativa sería crear la cita como confirmada y posteriormente modificarla si el pago falla.

Se descartó porque puede generar inconsistencias temporales y situaciones donde un horario aparece ocupado aunque el pago no se haya completado.

La opción de estados explícitos proporciona mayor claridad sobre la situación real de la reserva.

## Resultado esperado

La aplicación deberá mantener una separación clara entre:

- Reserva creada.
- Pago pendiente.
- Pago confirmado.
- Pago fallido.
- Cita confirmada.
- Cita cancelada.

Esto permite mantener trazabilidad y evitar asumir que una cita está confirmada simplemente porque fue creada.

---

# 4. AI_CONTEXT.md

## 4.1 Descripción del proyecto

El proyecto es un sistema de reservas para una clínica médica.

Los principales usuarios son:

### Pacientes

Pueden:

- Iniciar sesión.
- Consultar disponibilidad.
- Seleccionar especialidad.
- Seleccionar doctor.
- Seleccionar fecha y hora.
- Agendar citas.
- Reprogramar citas.
- Cancelar citas.
- Consultar sus propias citas.
- Recibir recordatorios.

### Doctores

Pueden:

- Consultar su agenda.
- Consultar las citas del día.
- Marcar citas como atendidas.
- Marcar citas como no asistidas.

### Administradores

Pueden:

- Gestionar doctores.
- Gestionar especialidades.
- Gestionar horarios.
- Gestionar usuarios.
- Consultar información administrativa autorizada.

---

# 5. Arquitectura del sistema

La arquitectura inicial utiliza un **monolito modular**.

```text
Vue / Frontend
      │
      │ HTTPS
      ▼
Next.js
      │
      ├── Auth
      ├── Pacientes
      ├── Doctores
      ├── Especialidades
      ├── Horarios
      ├── Citas
      ├── Pagos
      └── Notificaciones
      │
      ▼
PostgreSQL
```

Los pagos se gestionan mediante Stripe.

Las confirmaciones de pago deben recibirse mediante webhooks.

Los módulos internos deben evitar depender directamente de detalles de implementación de otros módulos.

---

# 6. Stack tecnológico

| Componente | Tecnología |
|---|---|
| Frontend | Next.js / React |
| Backend | Next.js |
| Base de datos | PostgreSQL |
| Pagos | Stripe |
| Notificaciones | Servicio externo de Email/SMS/Push |
| API | HTTP/REST |
| Control de versiones | Git |
| CI/CD | Pipeline automatizado |
| Testing | Tests unitarios + integración + E2E según criticidad |

Las versiones exactas de las dependencias deberán definirse en el archivo de dependencias del proyecto y no deberán ser inventadas por el agente de IA.

Antes de agregar una nueva dependencia, se debe comprobar si ya existe una solución dentro del proyecto.

---

# 7. Convenciones de código

## 7.1 Nombramiento

Utilizar nombres descriptivos.

Variables y funciones:

```text
camelCase
```

Ejemplos:

```javascript
getAvailableDoctors()
createAppointment()
cancelAppointment()
```

Componentes:

```text
PascalCase
```

Ejemplos:

```text
AppointmentForm
DoctorSchedule
AppointmentList
```

Constantes:

```text
UPPER_SNAKE_CASE
```

Ejemplo:

```text
MAX_APPOINTMENT_DURATION
```

---

# 8. Estructura conceptual de carpetas

```text
src/
│
├── app/
│
├── modules/
│   ├── auth/
│   ├── patients/
│   ├── doctors/
│   ├── specialties/
│   ├── schedules/
│   ├── appointments/
│   ├── payments/
│   └── notifications/
│
├── components/
│
├── lib/
│
├── infrastructure/
│
└── tests/
```

Cada módulo debe mantener separadas, cuando corresponda:

- Lógica de negocio.
- Acceso a datos.
- Validaciones.
- Controladores.
- Servicios.
- Tests.

La estructura puede ajustarse a las convenciones reales del repositorio, pero no debe mezclarse lógica crítica de negocio directamente dentro de componentes visuales.

---

# 9. Reglas de negocio críticas

## Citas

1. Un doctor no puede tener dos citas activas en el mismo horario.
2. Un paciente no debe tener reservas duplicadas para el mismo horario.
3. Los horarios deben corresponder a la disponibilidad configurada del doctor.
4. La disponibilidad debe validarse nuevamente en backend.
5. Las validaciones del frontend no son suficientes.
6. Una cita pendiente de pago no debe tratarse como confirmada.
7. Las citas canceladas deben liberar el horario cuando corresponda.
8. Las reprogramaciones deben volver a validar disponibilidad.
9. Las operaciones críticas deben manejar correctamente la concurrencia.

---

# 10. Reglas de seguridad

1. Nunca confiar en información proveniente directamente del frontend.
2. Toda operación debe validar autenticación.
3. Toda operación debe validar autorización.
4. Un paciente solamente puede acceder a sus propios recursos.
5. Un doctor solamente debe acceder a la información correspondiente a su agenda y permisos.
6. Los administradores deben tener permisos explícitos.
7. No almacenar secretos dentro del código.
8. Las credenciales deben utilizar variables de entorno o un sistema de gestión de secretos.
9. No registrar información médica sensible innecesariamente en logs.
10. Validar y sanitizar las entradas.
11. Utilizar consultas parametrizadas u ORM.
12. Los webhooks de Stripe deben validarse.
13. Los eventos de pago deben procesarse de manera idempotente.

---

# 11. Trampas comunes para agentes de IA

## 11.1 Confiar en el frontend

La IA puede generar código donde una validación solamente ocurre en el navegador.

Esto NO es suficiente.

Siempre debe existir validación en backend.

---

## 11.2 Conflictos de horarios

Un error común es comprobar:

```text
¿Está disponible?
       ↓
Sí
       ↓
Crear cita
```

sin considerar que otro usuario puede reservar el mismo horario entre ambas operaciones.

La disponibilidad debe validarse dentro de una operación segura que considere concurrencia.

---

## 11.3 Exposición de datos por ID

La IA puede generar endpoints como:

```text
GET /appointments/:id
```

y devolver la cita simplemente porque el ID existe.

Esto puede generar acceso horizontal no autorizado.

Siempre debe comprobarse que el usuario autenticado tenga permiso sobre el recurso.

---

## 11.4 Confiar en el frontend para pagos

Nunca asumir:

```text
paymentStatus = "success"
```

porque el frontend lo envió.

La confirmación del pago debe depender del backend y de la confirmación proporcionada por Stripe.

---

## 11.5 Webhooks duplicados

Un agente puede implementar un webhook que procese cada evento recibido sin verificar si ya fue procesado.

Esto puede provocar operaciones duplicadas.

Los eventos deben manejarse de forma idempotente.

---

## 11.6 Información sensible en logs

No generar logs con información médica o personal sensible sin una necesidad justificada.

Los logs deben contener la mínima información necesaria para diagnóstico y auditoría.

---

## 11.7 Sobreingeniería

La IA puede intentar introducir:

- Microservicios.
- Colas.
- Event sourcing.
- Kubernetes.
- Nuevas bases de datos.
- Librerías adicionales.

No se deben introducir tecnologías solamente porque sean populares.

Toda nueva tecnología debe responder a una necesidad concreta del sistema.

---

# 12. Reglas para generación de código con IA

Antes de generar código, el agente debe:

1. Analizar la arquitectura existente.
2. Revisar las convenciones del proyecto.
3. Identificar módulos relacionados.
4. Evitar duplicar funcionalidades existentes.
5. No agregar dependencias innecesarias.
6. No modificar reglas críticas sin autorización.
7. No introducir secretos.
8. Generar tests junto con funcionalidades críticas.
9. Explicar supuestos realizados.
10. Identificar riesgos y casos límite.

El agente no debe modificar arquitectura, autenticación, autorización, pagos o reglas críticas sin revisión del Tech Lead.

---

# 13. Proceso recomendado para cambios generados por IA

```text
Solicitud
   ↓
Agente IA analiza contexto
   ↓
Generación de código
   ↓
Tests
   ↓
Lint / análisis estático
   ↓
Revisión humana
   ↓
Revisión de seguridad
   ↓
Pull Request
   ↓
CI/CD
   ↓
Aprobación
   ↓
Deploy
```

El código generado por IA se considera una propuesta de implementación y no una fuente de verdad.

---

# 14. Reflexión final

El mayor riesgo de depender excesivamente de la inteligencia artificial para generar código en producción es asumir que un código que compila, pasa algunas pruebas o parece correcto es necesariamente seguro y adecuado para el negocio. Un modelo de IA puede generar soluciones funcionales pero incorrectas desde el punto de vista de seguridad, concurrencia, privacidad, rendimiento o reglas de negocio, especialmente cuando no conoce todo el contexto del sistema.

Como líder técnico implementaría mecanismos de defensa en varias capas: revisión humana obligatoria, análisis estático, pruebas unitarias e integración, pruebas de seguridad, revisión de dependencias, CI/CD con controles automáticos y aprobación manual para cambios críticos. Además, mantendría documentación como ADRs y un contexto específico para los agentes de IA, de manera que las decisiones arquitectónicas y reglas de negocio no dependan únicamente del conocimiento implícito de una persona o de una sesión de IA.

---

# 15. Resumen de decisiones

| Decisión | Elección |
|---|---|
| Arquitectura inicial | Monolito modular |
| Frontend / Framework | Next.js |
| Base de datos | PostgreSQL |
| Pagos | Stripe |
| Confirmación de pagos | Webhooks |
| Consistencia interna | Transacciones |
| Reservas pendientes | Estados explícitos |
| IA | Asistente de desarrollo |
| Código crítico | Revisión humana obligatoria |
| Testing | Unitario + integración + E2E según criticidad |
| Seguridad | Autenticación + autorización + mínimo privilegio |
| Evolución | Extraer servicios solo cuando exista una necesidad real |
