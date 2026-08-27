# ARQUITECTURA.md

# Evaluación de Arquitectura y Calidad

## 1. Introducción

El objetivo de esta revisión es analizar críticamente la arquitectura propuesta para el sistema de reservas de una clínica médica, identificando problemas relacionados con acoplamiento, complejidad, seguridad, consistencia, escalabilidad, costos y mantenibilidad.

Aunque la arquitectura propuesta utiliza tecnologías modernas y una separación mediante microservicios, considero que la cantidad de componentes y servicios debe estar justificada por las necesidades reales del negocio. Para una clínica pequeña o mediana, con aproximadamente 3 a 5 sucursales y 50 doctores, una arquitectura excesivamente distribuida puede introducir complejidad operacional sin aportar beneficios proporcionales.

La evaluación se realiza teniendo en cuenta principalmente la criticidad de los datos médicos, la integridad de las citas y pagos, la facilidad de mantenimiento y la capacidad del equipo para operar la solución.

---

# 2. Arquitectura propuesta

La arquitectura entregada es:

```text
Frontend (Vue 3)
        │
        ▼
HTTP REST
        │
        ▼
API Gateway
(Node.js + Express)
        │
        ├───────────────┐
        │               │
        ▼               ▼
Microservicio Auth   Microservicio Citas
        │               │
        ▼               ▼
   Firestore          Firestore
      users         appointments
        │
        ├───────────────┐
        │               │
        ▼               ▼
Microservicio       Microservicio
Doctores            Pagos
        │               │
        ▼               ├──────► Stripe API
    Firestore           │
     doctors            ▼
                    Firestore
                     payments

                        │
                        ▼
                Firebase Cloud
                  Messaging
```

---

# 3. Análisis crítico

## 3.1 Microservicios excesivos para el tamaño del sistema

**Impacto: Alto**

La arquitectura separa autenticación, citas, doctores y pagos en microservicios independientes.

Para una clínica con aproximadamente 50 doctores y entre 3 y 5 sucursales, esta distribución puede representar una complejidad innecesaria.

Cada microservicio implica:

* Despliegue independiente.
* Configuración.
* Monitoreo.
* Logs.
* Manejo de errores.
* Comunicación entre servicios.
* Gestión de versiones.
* Seguridad entre servicios.
* Mayor complejidad de debugging.

### Alternativa

Utilizar inicialmente un **monolito modular** o un **modular monolith**.

Por ejemplo:

```text
Aplicación
│
├── Auth
├── Pacientes
├── Doctores
├── Especialidades
├── Citas
├── Pagos
└── Notificaciones
        │
        ▼
   PostgreSQL
```

Los módulos estarían separados lógicamente, pero podrían ejecutarse dentro de una misma aplicación.

Esta arquitectura permite evolucionar posteriormente hacia microservicios si algún módulo realmente requiere escalar de forma independiente.

---

# 3.2 Uso de Firestore como base de datos para todo el sistema

**Impacto: Alto**

Firestore puede ser muy útil para aplicaciones con datos orientados a documentos, pero el dominio de una clínica tiene múltiples relaciones:

* Paciente → citas.
* Doctor → especialidades.
* Doctor → horarios.
* Cita → paciente.
* Cita → doctor.
* Cita → pago.
* Sucursal → doctores.
* Especialidad → doctores.

Además, las operaciones de agenda requieren garantizar consistencia y evitar reservas simultáneas del mismo horario.

### Alternativa

Utilizar una base de datos relacional como **PostgreSQL**.

Un modelo simplificado podría ser:

```text
Paciente
   │
   └──────< Cita >────── Doctor
               │
               ├──── Especialidad
               ├──── Horario
               └──── Pago
```

PostgreSQL permitiría utilizar:

* Relaciones.
* Claves foráneas.
* Restricciones.
* Transacciones.
* Índices.
* Consultas complejas.
* Mecanismos de concurrencia.

---

# 3.3 Problemas de consistencia entre servicios

**Impacto: Alto**

Al utilizar diferentes microservicios con Firestore, una operación de negocio puede involucrar varios componentes.

Por ejemplo:

```text
Paciente
   │
   ▼
Citas
   │
   ▼
Pago
   │
   ▼
Stripe
```

Si una operación falla en medio del proceso, puede quedar información parcialmente registrada.

Ejemplo:

```text
Crear cita → OK
Crear pago → FALLA
```

La cita podría permanecer registrada aunque el pago no se haya realizado.

### Alternativa

Utilizar un patrón de consistencia distribuida como **Saga** cuando realmente existan servicios independientes.

¿Qué hace Saga?

Saga permite dividir la operación en pasos y definir qué hacer si alguno falla.

Por ejemplo:

Crear reserva
     ↓
PENDING_PAYMENT
     ↓
Intentar pago
     │
 ┌───┴────┐
 ↓        ↓
OK       FALLA
 ↓        ↓
CONFIRMAR  CANCELAR
CITA       CITA

Sin embargo, si se utiliza un monolito modular con PostgreSQL, muchas de estas operaciones podrían manejarse mediante transacciones de base de datos, reduciendo considerablemente la complejidad.

---

# 3.4 API Gateway innecesario para un sistema pequeño

**Impacto: Medio**

El API Gateway agrega una capa adicional entre el frontend y los servicios.

En un sistema con pocos servicios puede convertirse en un punto adicional de configuración y mantenimiento.

También aumenta la complejidad del diagnóstico de errores:

```text
Frontend
   ↓
Gateway
   ↓
Servicio
   ↓
Base de datos
```

En caso de error, es necesario determinar en qué capa ocurrió el problema.

### Alternativa

En un monolito modular se podría exponer directamente una API principal:

```text
Vue
 │
 ▼
Backend
 │
 ├── Auth
 ├── Citas
 ├── Doctores
 ├── Pagos
 └── Notificaciones
```

Si posteriormente se migra a microservicios, el API Gateway podría incorporarse cuando exista una necesidad real.

---

# 3.5 Seguridad y separación de responsabilidades

**Impacto: Alto**

La arquitectura indica que existe un microservicio Auth con JWT, pero no especifica:

* Roles.
* Permisos.
* Rotación de tokens.
* Expiración.
* Revocación.
* Gestión de refresh tokens.
* MFA.
* Protección de endpoints.
* Auditoría.

En un sistema médico no es suficiente con autenticar al usuario. También es necesario verificar qué recursos puede consultar o modificar.

### Alternativa

Implementar autenticación y autorización basada en roles y permisos.

Ejemplo:

```text
Paciente
 ├── Consultar sus citas
 ├── Crear citas
 ├── Reprogramar sus citas
 └── Cancelar sus citas

Doctor
 ├── Consultar su agenda
 └── Marcar citas como atendidas

Administrador
 ├── Gestionar doctores
 ├── Gestionar horarios
 ├── Gestionar especialidades
 └── Gestionar usuarios
```

La autorización debe validarse siempre en backend.

---

# 3.6 Acoplamiento con Firebase Cloud Messaging

**Impacto: Medio**

El uso de Firebase Cloud Messaging como mecanismo de recordatorios crea dependencia directa de un proveedor.

Además, las notificaciones push pueden no ser suficientes si el requisito del negocio requiere garantizar que el paciente reciba el recordatorio.

### Alternativa

Diseñar una capa de notificaciones desacoplada:

```text
Sistema
   │
   ▼
Notification Service
   │
   ├── Email
   ├── SMS
   └── Push
```

Esto permite cambiar de proveedor sin modificar la lógica principal del sistema.

---

# 3.7 Pagos y Stripe requieren un tratamiento especial

**Impacto: Alto**

La arquitectura propuesta conecta el microservicio de pagos directamente con Stripe y Firestore.

El principal riesgo es tratar el pago como una operación completamente controlada por el frontend.

Nunca se debería confiar únicamente en que el frontend indique que un pago fue exitoso.

### Alternativa

Utilizar Stripe como autoridad para confirmar el estado del pago y procesar eventos mediante webhooks.

Flujo:

```text
Paciente
   │
   ▼
Frontend
   │
   ▼
Backend
   │
   ▼
Stripe
   │
   ▼
Webhook
   │
   ▼
Backend
   │
   ▼
Actualizar estado del pago
```

El backend debe validar los eventos recibidos y evitar procesarlos más de una vez.

---

# 4. Estilo arquitectónico recomendado

## Decisión: Modular Monolith

Para una clínica pequeña/mediana con 3 a 5 sucursales y aproximadamente 50 doctores, inicialmente recomendaría un **monolito modular** en lugar de una arquitectura de microservicios.

### Razones

#### 1. Menor complejidad operacional

Existe un único backend que puede desplegarse, monitorearse y mantenerse de forma más sencilla.

#### 2. Menor costo

Se reduce la cantidad de infraestructura, servicios desplegados y componentes que necesitan monitoreo.

#### 3. Mayor facilidad para mantener consistencia

Las operaciones relacionadas con citas y pagos pueden manejarse mediante transacciones cuando corresponda.

#### 4. Equipo pequeño

Un equipo reducido puede mantener mejor un sistema modular que varios microservicios independientes.

#### 5. Escalabilidad suficiente

Para aproximadamente 50 doctores, un monolito correctamente diseñado puede soportar un volumen considerable de operaciones.

### Arquitectura propuesta

```text
                  ┌─────────────────┐
                  │   Vue 3         │
                  │   Frontend      │
                  └────────┬────────┘
                           │ HTTPS
                           ▼
                  ┌─────────────────┐
                  │ Backend         │
                  │ Modular         │
                  ├─────────────────┤
                  │ Auth            │
                  │ Pacientes       │
                  │ Doctores        │
                  │ Especialidades  │
                  │ Citas           │
                  │ Horarios        │
                  │ Pagos           │
                  │ Notificaciones  │
                  └────────┬────────┘
                           │
                 ┌─────────┴─────────┐
                 ▼                   ▼
          ┌─────────────┐      ┌─────────────┐
          │ PostgreSQL  │      │ Stripe      │
          └─────────────┘      └─────────────┘
                                      │
                                      ▼
                                  Webhooks
```

Los módulos deberían mantenerse desacoplados internamente mediante interfaces claras para facilitar una futura extracción a microservicios si el crecimiento del sistema lo justifica.

---

# 5. Consistencia de datos

El escenario plantea:

> Un paciente agenda una cita pero el pago falla, por lo que la cita queda registrada sin pago.

Existen diferentes alternativas para resolver este problema.

---

## 5.1 Patrón Saga

Una Saga divide una operación distribuida en varias transacciones locales y define acciones compensatorias.

Ejemplo:

```text
1. Crear reserva provisional
        ↓
2. Crear/intentar pago
        ↓
3. Confirmar cita
```

Si el pago falla:

```text
Pago falla
   ↓
Cancelar reserva provisional
   ↓
Liberar horario
```

### Ventajas

* Adecuado para arquitecturas distribuidas.
* No requiere una transacción distribuida tradicional.
* Permite utilizar transacciones locales.
* Facilita la integración entre servicios independientes.

### Desventajas

* Mayor complejidad.
* Requiere manejar estados intermedios.
* Las acciones compensatorias deben estar correctamente diseñadas.
* Puede ser difícil de depurar.

### Aplicación

Podrían existir estados:

```text
PENDING_PAYMENT
      │
      ├── Pago exitoso → CONFIRMED
      │
      └── Pago fallido → CANCELLED
```

---

# 5.2 Transacción de base de datos

Si la arquitectura utiliza una base de datos relacional y las operaciones pueden realizarse dentro del mismo límite transaccional, se puede utilizar una transacción.

Ejemplo conceptual:

```text
BEGIN TRANSACTION

Crear reserva
Crear registro de pago

Si todo es correcto:
    COMMIT

Si existe error:
    ROLLBACK
```

### Ventajas

* Más sencilla de implementar.
* Consistencia fuerte.
* Fácil de entender.
* Menor complejidad operacional.

### Desventajas

Una transacción de base de datos no puede garantizar por sí sola el éxito de una operación externa con Stripe.

Por ejemplo:

```text
PostgreSQL → OK
Stripe → FALLA
```

Por esta razón, cuando existe un proveedor externo de pagos, se necesita diseñar cuidadosamente el flujo y el estado de la reserva.

---

# 5.3 Decisión recomendada

Para esta clínica utilizaría una combinación de:

* Transacciones de PostgreSQL para operaciones internas.
* Estado `PENDING_PAYMENT` para reservas que dependen de un pago.
* Stripe como fuente de verdad del estado del pago.
* Webhooks de Stripe.
* Idempotencia para evitar procesar dos veces el mismo evento.
* Cancelación automática de reservas cuyo pago no se complete dentro de un tiempo determinado.

Esto ofrece un equilibrio entre consistencia y complejidad.

---

# 6. Estrategia de testing

La estrategia de testing debe priorizar los componentes con mayor impacto en seguridad, dinero e integridad de datos.

La prioridad sería:

```text
1. Pagos
2. Autenticación/autorización
3. Agendamiento
4. Backend/API
5. Integración
6. Frontend
7. UI visual
```

---

## 6.1 Pruebas para pagos

Los pagos son el módulo más crítico.

Priorizaría:

* Tests unitarios.
* Tests de integración.
* Tests de webhooks.
* Idempotencia.
* Pagos exitosos.
* Pagos rechazados.
* Pagos cancelados.
* Eventos duplicados.
* Eventos fuera de orden.
* Montos incorrectos.
* Intentos de manipulación del monto.
* Confirmación de pago desde backend.

Nunca utilizaría credenciales reales de Stripe para pruebas.

Utilizaría el entorno de pruebas/sandbox proporcionado por el proveedor.

---

# 6.2 Pruebas de autenticación

Debido a que el módulo fue desarrollado por un junior, requiere una revisión especialmente rigurosa.

Probaría:

* Login correcto.
* Contraseña incorrecta.
* Usuario inexistente.
* Token expirado.
* Token inválido.
* Acceso sin autenticación.
* Acceso con rol incorrecto.
* Manipulación de JWT.
* Acceso horizontal entre pacientes.
* Acceso administrativo no autorizado.
* Rate limiting.

---

# 6.3 Pruebas de agendamiento

Se deben probar especialmente los escenarios de concurrencia.

Casos:

* Horario disponible.
* Horario ocupado.
* Dos pacientes intentando reservar simultáneamente.
* Doctor sin disponibilidad.
* Fecha inválida.
* Horario fuera de jornada.
* Reprogramación.
* Cancelación.
* Reserva duplicada.
* Paciente intentando modificar una cita que no le pertenece.

---

# 6.4 Pruebas del frontend generado por IA

El frontend debería probarse principalmente mediante:

* Tests de componentes.
* Tests de integración.
* Validaciones de formularios.
* Manejo de errores.
* Estados de carga.
* Navegación.
* Permisos.
* Flujos principales.

No dedicaría inicialmente una cantidad excesiva de tiempo a pruebas visuales de cada elemento de la interfaz si no tienen impacto funcional.

---

# 6.5 Qué dejaría fuera inicialmente

Debido al plazo de tres semanas, dejaría para una etapa posterior:

* Pruebas visuales exhaustivas de cada componente.
* Pruebas de rendimiento de escenarios poco relevantes.
* Compatibilidad con navegadores muy antiguos.
* Automatización completa de todos los flujos administrativos.
* Pruebas de carga masivas si todavía no existe información real sobre el volumen esperado.

Esto no significa que nunca se realicen, sino que se priorizan después de cubrir las funcionalidades críticas.

---

# 6.6 Aprovisionamiento de datos de prueba

Utilizaría datos sintéticos y scripts automatizados de seed.

Ejemplo:

```text
Seed de pruebas
│
├── 20 pacientes
├── 10 doctores
├── 5 especialidades
├── 3 sucursales
├── Horarios disponibles
├── Citas confirmadas
├── Citas canceladas
├── Citas pendientes
└── Pagos en diferentes estados
```

Nunca utilizaría información real de pacientes en ambientes de desarrollo o testing.

Los datos deberían poder:

* Crearse automáticamente.
* Reiniciarse.
* Versionarse mediante scripts.
* Ser reproducibles en CI/CD.

---

# 7. Métricas de calidad en producción

## KPI 1: Tasa de errores de la API

### Qué mide

Porcentaje de solicitudes que terminan en errores HTTP o excepciones no controladas.

### Fórmula conceptual

```text
Tasa de errores =
Solicitudes fallidas / Solicitudes totales × 100
```

### Herramientas

* Sentry.
* Application Performance Monitoring.
* Logs centralizados.
* Métricas del proveedor cloud.

### Objetivo

Detectar rápidamente regresiones y problemas de disponibilidad.

---

# 7.2 KPI 2: Disponibilidad del sistema

### Qué mide

Porcentaje de tiempo durante el cual la API y servicios principales están disponibles.

### Medición

Utilizar monitoreo externo y health checks.

Ejemplo:

```text
GET /health
```

Herramientas posibles:

* Uptime monitoring.
* Prometheus.
* Grafana.
* Cloud Monitoring.

### Objetivo

Detectar interrupciones del servicio y medir confiabilidad.

---

# 7.3 KPI 3: Latencia de las operaciones críticas

### Qué mide

Tiempo que tarda el sistema en responder a operaciones importantes.

Especialmente:

* Consulta de disponibilidad.
* Creación de cita.
* Confirmación de pago.
* Consulta de agenda.

### Medición

Utilizar percentiles, principalmente:

* P50.
* P95.
* P99.

El P95 permite observar el comportamiento del 95 % de las solicitudes y detectar problemas que no son visibles utilizando únicamente el promedio.

### Herramientas

* Application Performance Monitoring.
* OpenTelemetry.
* Prometheus.
* Grafana.

---

# 8. Observabilidad recomendada

Para complementar los KPIs utilizaría:

```text
Aplicación
    │
    ├── Logs
    │
    ├── Métricas
    │
    └── Trazas
           │
           ▼
    Observabilidad
           │
      ┌────┴────┐
      ▼         ▼
   Alertas    Dashboards
```

Los logs deben evitar información médica innecesaria y datos sensibles.

---

# 9. Arquitectura final recomendada

Para el contexto planteado, propondría inicialmente:

```text
                    ┌──────────────────┐
                    │    Vue 3         │
                    │    Frontend      │
                    └────────┬─────────┘
                             │ HTTPS
                             ▼
                    ┌──────────────────┐
                    │ Backend          │
                    │ Modular Monolith │
                    ├──────────────────┤
                    │ Auth             │
                    │ Pacientes        │
                    │ Doctores         │
                    │ Especialidades   │
                    │ Horarios         │
                    │ Citas            │
                    │ Pagos            │
                    │ Notificaciones   │
                    └────────┬─────────┘
                             │
                  ┌──────────┴──────────┐
                  ▼                     ▼
           ┌──────────────┐      ┌──────────────┐
           │ PostgreSQL   │      │ Stripe       │
           └──────────────┘      └──────┬───────┘
                                        │
                                        ▼
                                   Webhooks
                                        │
                                        ▼
                                  Backend
                                        │
                                        ▼
                               Notification Service
                                        │
                              ┌─────────┴─────────┐
                              ▼                   ▼
                           Email                Push/SMS
```

Esta arquitectura permite comenzar con una solución relativamente sencilla y mantenible, pero manteniendo límites modulares claros que faciliten una futura evolución.

---

# 10. Evolución futura hacia microservicios

No descartaría los microservicios permanentemente.

Los consideraría cuando existan señales concretas como:

* Incremento significativo del tráfico.
* Necesidad de escalar módulos independientemente.
* Equipos diferentes trabajando sobre dominios independientes.
* Requisitos de disponibilidad diferentes.
* Procesamiento asíncrono de gran volumen.
* Necesidad de desplegar determinados componentes de forma independiente.

Una posible evolución sería:

```text
                 Backend Modular
                       │
              ┌────────┴────────┐
              │                 │
          Crecimiento       Mayor carga
              │                 │
              └────────┬────────┘
                       ▼
               Extraer módulos
                       │
        ┌──────────────┼──────────────┐
        ▼              ▼              ▼
      Pagos         Notificaciones   Citas
    Microservicio   Microservicio   Microservicio
```

La migración debería realizarse progresivamente y basada en necesidades reales, no simplemente por adoptar una arquitectura considerada "más moderna".

---

# 11. Conclusión

La arquitectura propuesta demuestra una separación clara de responsabilidades, pero considero que está sobredimensionada para una clínica pequeña o mediana con 3 a 5 sucursales y aproximadamente 50 doctores. El principal riesgo no es la falta de escalabilidad, sino introducir complejidad distribuida antes de que exista una necesidad real. Recomendaría comenzar con un monolito modular utilizando una base de datos relacional como PostgreSQL, manteniendo límites claros entre dominios y utilizando Stripe mediante un flujo basado en webhooks e idempotencia. Esta alternativa reduce costos y complejidad, facilita la consistencia de datos y permite que el sistema evolucione posteriormente hacia microservicios si el crecimiento del negocio realmente lo requiere.
