# ESTRATEGIA.md

# Dirección Técnica - Orquestación con Agentes de IA

## 1. Introducción

El objetivo de esta estrategia es definir cómo se organizaría el desarrollo de un sistema de reservas para una clínica médica en un periodo de tres semanas, utilizando agentes de inteligencia artificial especializados, un desarrollador junior y un Tech Lead.

Debido a que el sistema manejará información relacionada con pacientes, citas y profesionales de la salud, la estrategia prioriza la seguridad, integridad de los datos, disponibilidad y correcta implementación de las reglas de negocio.

La inteligencia artificial será utilizada como herramienta de aceleración del desarrollo, especialmente en tareas repetitivas, generación de código base, pruebas y documentación. Sin embargo, las decisiones relacionadas con arquitectura, seguridad, datos sensibles y reglas críticas serán revisadas y controladas directamente por el Tech Lead.

---

# 2. Parte A - Descomposición y estrategia

## 2.1 Módulos principales

El sistema se dividirá en los siguientes módulos:

1. Autenticación y autorización.
2. Gestión de pacientes.
3. Gestión de doctores y especialidades.
4. Gestión de horarios y disponibilidad.
5. Agendamiento de citas.
6. Reprogramación y cancelación.
7. Agenda del doctor.
8. Recordatorios automáticos.
9. Panel administrativo.
10. Auditoría, seguridad y monitoreo.
11. Testing.
12. Documentación.

---

## 2.2 Distribución de responsabilidades

| Módulo                       | Trabajo con IA                           | Trabajo manual / humano                      | Motivo                                                                   |
| ---------------------------- | ---------------------------------------- | -------------------------------------------- | ------------------------------------------------------------------------ |
| Autenticación y autorización | Generación de código base y tests        | Diseño, revisión y validación del Tech Lead  | Maneja acceso a información sensible.                                    |
| Pacientes                    | CRUD, DTOs, validaciones y tests         | Revisión de seguridad                        | Es información sensible.                                                 |
| Doctores y especialidades    | CRUD y componentes de interfaz           | Revisión de reglas de negocio                | Es funcionalidad relativamente estructurada.                             |
| Horarios                     | Código base y pruebas                    | Diseño de reglas y validación                | Los horarios afectan directamente la disponibilidad.                     |
| Agendamiento                 | Código base, componentes y tests         | Reglas de negocio, transacciones y revisión  | Es uno de los módulos críticos del sistema.                              |
| Reprogramación/cancelación   | Código base y pruebas                    | Definición de reglas y casos límite          | Puede afectar disponibilidad y trazabilidad.                             |
| Agenda del doctor            | Componentes y consultas base             | Validación de permisos                       | Un doctor solo debe acceder a información autorizada.                    |
| Recordatorios                | Código de integración y tests            | Arquitectura, configuración y seguridad      | Involucra servicios externos y tareas programadas.                       |
| Panel administrativo         | CRUD y componentes                       | Roles y permisos                             | Tiene privilegios elevados.                                              |
| Auditoría                    | Generación de estructuras base           | Definición de eventos y revisión             | Es importante para trazabilidad y seguridad.                             |
| Testing                      | Generación automática de tests           | Definición de escenarios críticos y revisión | La IA puede generar tests, pero el humano debe validar su cobertura.     |
| Documentación                | README, API docs y documentación técnica | Revisión y aprobación                        | La IA puede documentar incorrectamente comportamientos no implementados. |

---

# 3. Estrategia de utilización de cada agente

## 3.1 Agente de generación de código

El agente de generación de código se utilizará principalmente para:

* Componentes de frontend.
* Endpoints.
* DTOs y modelos.
* CRUD.
* Validaciones básicas.
* Código repetitivo.
* Integraciones previamente definidas.
* Refactorizaciones controladas.

No se le delegará de forma autónoma la definición de arquitectura ni decisiones relacionadas con seguridad crítica.

### Prompt principal

> Actúa como desarrollador senior dentro de un equipo que está construyendo un sistema de reservas para una clínica médica.
>
> Antes de generar código, analiza los requisitos funcionales y técnicos proporcionados.
>
> Respeta estrictamente la arquitectura, convenciones de código, estructura de carpetas y modelo de datos definidos por el Tech Lead.
>
> Genera código modular, mantenible y testeable.
>
> No incluyas secretos, credenciales ni información sensible en el código.
>
> Valida siempre los datos recibidos en el backend y no confíes en información proveniente directamente del frontend.
>
> Para operaciones críticas como agendamiento, cancelación y reprogramación, considera concurrencia, transacciones y validaciones del lado del servidor.
>
> Antes de finalizar, explica las decisiones realizadas, posibles riesgos y casos límite que deberían probarse.

### Riesgos

* Generación de código funcional pero inseguro.
* Suposiciones incorrectas sobre reglas del negocio.
* Uso de dependencias innecesarias.
* Validaciones únicamente en frontend.
* Manejo incorrecto de errores.
* Código que parece correcto pero presenta problemas de concurrencia.
* Exposición accidental de información sensible.

---

# 4. Agente de testing

El agente de testing será responsable de acelerar la creación de:

* Tests unitarios.
* Tests de integración.
* Casos límite.
* Tests de validaciones.
* Pruebas de endpoints.
* Pruebas de conflictos de horarios.

### Prompt principal

> Actúa como QA Engineer especializado en aplicaciones de salud.
>
> Analiza la funcionalidad proporcionada y genera pruebas unitarias y de integración.
>
> Incluye casos exitosos, casos inválidos, errores de autorización, datos incompletos, conflictos de horario, solicitudes duplicadas y condiciones de concurrencia.
>
> No asumas que el código funciona correctamente. Busca activamente casos que puedan provocar inconsistencias de datos o vulnerabilidades.
>
> Para cada prueba explica qué comportamiento está validando.

### Riesgos

La IA podría generar tests que únicamente comprueben el "happy path" y dejar sin cubrir escenarios críticos como:

* Dos usuarios reservando el mismo horario.
* Acceso de un paciente a otra cita.
* Reprogramaciones simultáneas.
* Usuarios sin permisos.
* Solicitudes duplicadas.

Por ello, el Tech Lead debe revisar la cobertura de las pruebas.

---

# 5. Agente de documentación

Este agente se utilizará para generar:

* README.
* Documentación de endpoints.
* Descripción de arquitectura.
* Guías de instalación.
* Documentación técnica.
* Ejemplos de consumo de API.

### Prompt principal

> Analiza exclusivamente el código y configuración proporcionados y genera documentación técnica basada en el comportamiento realmente implementado.
>
> No inventes endpoints, funcionalidades ni reglas de negocio que no estén presentes en el código.
>
> Documenta autenticación, parámetros, respuestas, errores y permisos cuando dicha información esté disponible.
>
> Señala explícitamente cualquier información que no pueda ser determinada a partir del código proporcionado.

### Riesgos

La IA podría documentar funcionalidades inexistentes o interpretar incorrectamente el comportamiento del sistema.

La documentación generada debe ser revisada antes de considerarse oficial.

---

# 6. Rol del desarrollador junior

El desarrollador junior participará en tareas con bajo riesgo y alcance claramente definido, siempre con supervisión.

Sus responsabilidades podrían incluir:

* Componentes de interfaz.
* Formularios.
* CRUD sencillos.
* Validaciones básicas.
* Corrección de bugs.
* Implementación de tests.
* Documentación.
* Integración de componentes previamente diseñados.

Las tareas críticas de seguridad, arquitectura y concurrencia no deberían asignarse sin revisión directa del Tech Lead.

---

# 7. Rol del Tech Lead

El Tech Lead será responsable de las decisiones que puedan afectar la seguridad, arquitectura y consistencia del sistema.

Responsabilidades principales:

* Definir arquitectura.
* Seleccionar tecnologías.
* Diseñar el modelo de datos.
* Definir reglas críticas del negocio.
* Diseñar autenticación y autorización.
* Definir estrategia de seguridad.
* Revisar código generado por IA.
* Revisar Pull Requests.
* Validar pruebas.
* Resolver conflictos técnicos.
* Revisar integraciones externas.
* Supervisar al desarrollador junior.
* Aprobar cambios antes de producción.

La IA será considerada un asistente de desarrollo y no una autoridad para tomar decisiones críticas.

---

# 8. Plan de trabajo de tres semanas

## Semana 1 - Arquitectura y funcionalidades principales

### Tech Lead

* Definir arquitectura.
* Diseñar modelo de datos.
* Definir autenticación y roles.
* Definir reglas de agendamiento.
* Configurar repositorio y CI/CD.
* Definir estándares de código.

### Agente de código

* Estructura inicial del proyecto.
* Modelos y DTOs.
* CRUD inicial.
* Componentes base.

### Desarrollador junior

* Formularios.
* Componentes de interfaz.
* CRUD de funcionalidades sencillas.

### Agente de testing

* Configuración del framework de pruebas.
* Tests iniciales.
* Casos de prueba de agendamiento.

### Agente de documentación

* README inicial.
* Documentación de arquitectura y endpoints.

---

## Semana 2 - Integración y funcionalidades críticas

### Tech Lead

* Implementar/revisar lógica crítica de agendamiento.
* Validar transacciones.
* Revisar permisos.
* Revisar seguridad.
* Supervisar integración.

### Agente de código

* Agenda del doctor.
* Reprogramación.
* Cancelación.
* Panel administrativo.
* Integración de recordatorios.

### Desarrollador junior

* Componentes de agenda.
* Interfaces administrativas.
* Correcciones de bugs.

### Agente de testing

* Tests de integración.
* Pruebas de conflictos de horario.
* Pruebas de autorización.
* Casos límite.

### Agente de documentación

* Actualización de documentación.
* Documentación de APIs.
* Guías de uso.

---

## Semana 3 - Seguridad, pruebas y entrega

### Tech Lead

* Auditoría técnica.
* Revisión de seguridad.
* Revisión de código.
* Pruebas de aceptación.
* Validación de arquitectura.
* Preparación del despliegue.

### Agente de código

* Correcciones.
* Refactorización.
* Mejoras de rendimiento.

### Desarrollador junior

* Corrección de errores identificados.
* Ajustes de interfaz.
* Soporte en pruebas.

### Agente de testing

* Regresión.
* Pruebas de seguridad.
* Pruebas de integración.
* Pruebas de escenarios críticos.

### Agente de documentación

* Documentación final.
* Guía de despliegue.
* Registro de decisiones técnicas.

---

# 9. Diagrama de decisión para asignación de tareas

```text
                    ┌──────────────────────┐
                    │   Nueva tarea        │
                    └──────────┬───────────┘
                               │
                               ▼
                  ┌─────────────────────────┐
                  │ ¿Afecta seguridad,      │
                  │ datos sensibles o       │
                  │ reglas críticas?        │
                  └───────────┬─────────────┘
                              │
                    ┌─────────┴─────────┐
                   SÍ                   NO
                    │                    │
                    ▼                    ▼
          ┌──────────────────┐   ┌─────────────────────┐
          │ Tech Lead diseña │   │ ¿Es repetitiva o    │
          │ y supervisa      │   │ fácilmente verificable? │
          └────────┬─────────┘   └──────────┬──────────┘
                   │                        │
                   │                ┌───────┴───────┐
                   │               SÍ              NO
                   │                │                │
                   │                ▼                ▼
                   │        ┌───────────────┐ ┌──────────────┐
                   │        │ Delegar a IA  │ │ Junior + IA  │
                   │        │ con tests     │ │ supervisados │
                   │        └───────┬───────┘ └───────┬──────┘
                   │                │                  │
                   └────────────────┴──────────────────┘
                                    │
                                    ▼
                         ┌─────────────────────┐
                         │ Code Review humano  │
                         │ + pruebas automáticas│
                         └──────────┬──────────┘
                                    │
                                    ▼
                           ┌─────────────────┐
                           │ ¿Cumple calidad │
                           │ y seguridad?    │
                           └───────┬─────────┘
                                   │
                           ┌───────┴───────┐
                          NO              SÍ
                           │                │
                           ▼                ▼
                    ┌────────────┐   ┌─────────────┐
                    │ Corregir y │   │ Aprobar PR  │
                    │ volver a   │   │ y desplegar │
                    │ revisar    │   └─────────────┘
                    └────────────┘
```

La regla principal es que **la criticidad determina el nivel de supervisión**, no simplemente la dificultad técnica de la tarea.

---

# 10. Parte B - Trade-offs y decisiones

## 10.1 Stack tecnológico seleccionado

### Opción elegida: B - Next.js + PostgreSQL

Seleccionaría **Next.js + PostgreSQL**.

La razón principal es que el sistema manejará información sensible y requiere consistencia en operaciones como agendamiento, reprogramación y cancelación.

PostgreSQL proporciona un modelo relacional adecuado para representar entidades como pacientes, doctores, especialidades, horarios y citas, además de ofrecer transacciones y restricciones que ayudan a mantener la integridad de los datos.

Next.js permite desarrollar la aplicación utilizando un ecosistema moderno y puede facilitar la construcción de frontend y backend dentro de una misma aplicación.

También considero que esta opción permite mantener una arquitectura relativamente sencilla para un equipo pequeño que debe entregar un MVP en tres semanas.

### Factores considerados

* Seguridad.
* Integridad de datos.
* Transacciones.
* Control de acceso.
* Tiempo de desarrollo.
* Mantenibilidad.
* Experiencia del equipo.
* Escalabilidad.
* Facilidad de testing.
* Complejidad operacional.
* Manejo de información sensible.

### ¿Por qué no elegiría las otras opciones?

#### Opción A: Vue 3 + Firebase

Firebase permitiría desarrollar rápidamente un MVP y reducir la infraestructura que debe administrarse.

Sin embargo, para este caso considero más importante tener un modelo relacional explícito y mayor control sobre las transacciones y restricciones de datos.

Además, al manejar información sensible, tendría que revisar cuidadosamente reglas de seguridad, autenticación, permisos y configuración de cada servicio.

#### Opción C: FastAPI + React + MySQL

Es una alternativa técnicamente válida y especialmente atractiva si el equipo tiene mayor experiencia con Python.

Sin embargo, introduce una separación adicional entre frontend y backend que puede aumentar el trabajo de integración en un proyecto con un plazo de únicamente tres semanas.

Por esta razón, elegiría Next.js + PostgreSQL para reducir la complejidad inicial sin sacrificar las capacidades necesarias para el sistema.

---

# 11. Preguntas que realizaría al PM antes de confirmar el stack

Antes de tomar la decisión definitiva realizaría las siguientes preguntas:

1. ¿Cuántos pacientes y doctores se esperan inicialmente?
2. ¿Cuál es el crecimiento esperado de usuarios durante el primer año?
3. ¿El sistema manejará únicamente citas o también historias clínicas?
4. ¿Qué tipo de datos personales y médicos se almacenarán?
5. ¿Existen requisitos regulatorios específicos para el tratamiento de datos?
6. ¿Qué canales se utilizarán para los recordatorios: email, SMS, WhatsApp o varios?
7. ¿El sistema debe integrarse con otros sistemas de la clínica?
8. ¿Se requiere disponibilidad 24/7?
9. ¿Existe infraestructura cloud definida?
10. ¿Se requiere auditoría completa de las acciones realizadas por usuarios y administradores?
11. ¿Qué roles y permisos deben existir?
12. ¿Cuál es el volumen esperado de citas por día?
13. ¿Existe un presupuesto mensual para infraestructura y servicios externos?
14. ¿Se necesita soporte multi-clínica o multi-sede?

Estas respuestas podrían modificar la decisión tecnológica inicial.

---

# 12. Recordatorios automáticos

## Decisión

Utilizaría un **servicio externo para el envío de mensajes**, combinado con un mecanismo de ejecución programada en la infraestructura de la aplicación.

Por ejemplo:

```text
             Base de datos
                  │
                  ▼
          Citas próximas
                  │
                  ▼
         Job programado
                  │
                  ▼
       Servicio de recordatorios
                  │
          ┌───────┴────────┐
          ▼                ▼
        Email              SMS
```

Para correo electrónico podría utilizarse un proveedor especializado como SendGrid. Para SMS podría utilizarse un servicio como Twilio, dependiendo de los requisitos del producto y disponibilidad regional.

### Costo

Los servicios externos normalmente tienen un costo asociado al volumen de mensajes, pero evitan desarrollar y mantener infraestructura propia para la entrega de SMS o correo.

### Escalabilidad

Los proveedores especializados están diseñados para manejar grandes volúmenes de mensajes, por lo que la aplicación no tendría que administrar directamente toda la infraestructura de entrega.

### Mantenibilidad

Separar la generación de recordatorios del envío de mensajes permite cambiar de proveedor con menor impacto en el resto del sistema.

### Seguridad

Las credenciales del proveedor deben almacenarse como secretos y nunca incluirse directamente en el código fuente.

Además, el sistema debería evitar incluir información médica innecesaria en los mensajes. Un recordatorio debería utilizar únicamente la información mínima necesaria.

---

# 13. Parte B - Seguridad

## Riesgo 1: Acceso horizontal no autorizado

Un paciente podría intentar acceder a la cita de otro paciente modificando un identificador en una URL o petición HTTP.

Ejemplo conceptual:

```text
GET /appointments/123
GET /appointments/124
GET /appointments/125
```

### Mitigación

* Autenticación obligatoria.
* Autorización en backend.
* Validación de propietario del recurso.
* Control de acceso basado en roles.
* No confiar en las validaciones realizadas únicamente en frontend.
* Registrar intentos de acceso no autorizado.

---

## Riesgo 2: Doble reserva por condiciones de concurrencia

Dos pacientes podrían intentar reservar simultáneamente el mismo horario.

Una validación únicamente en frontend no garantiza que esto no ocurra.

### Mitigación

* Validación en backend.
* Uso de transacciones.
* Restricciones adecuadas en la base de datos.
* Control de concurrencia.
* Pruebas automatizadas de reservas simultáneas.

El sistema debe garantizar que un horario no pueda ser asignado a dos citas activas simultáneamente.

---

## Riesgo 3: Exposición de información sensible

El sistema maneja información personal relacionada con citas médicas, por lo que una fuga de datos podría tener un impacto elevado.

### Mitigación

* HTTPS.
* Cifrado de información sensible cuando sea necesario.
* Gestión segura de secretos.
* Principio de mínimo privilegio.
* Control de acceso por roles.
* Logs sin información médica innecesaria.
* Auditoría de acciones administrativas.
* Protección de backups.
* Validación y sanitización de entradas.
* No almacenar credenciales en el repositorio.

---

# 14. Otros controles de seguridad recomendados

Además de los tres riesgos principales, consideraría:

* Protección contra SQL Injection mediante consultas parametrizadas/ORM.
* Protección contra XSS.
* Protección CSRF cuando corresponda a la arquitectura.
* Rate limiting.
* Políticas de contraseñas.
* MFA para usuarios administrativos.
* Gestión de sesiones.
* Expiración y revocación de tokens.
* Auditoría de acciones críticas.
* Monitoreo de errores y eventos de seguridad.
* Escaneo de dependencias.
* SAST y análisis de vulnerabilidades en CI/CD.

---

# 15. Parte C - Prompt Engineering Estratégico

## Prompt para el módulo de Agendamiento de Citas

> **Rol**
>
> Actúa como un desarrollador senior especializado en sistemas de reservas y aplicaciones que manejan información sensible.
>
> **Contexto**
>
> Estamos construyendo un sistema de reservas para una clínica médica. El sistema permite que los pacientes agenden, reprogramen y cancelen citas médicas. Los doctores pueden consultar su agenda y los administradores pueden gestionar doctores, especialidades y horarios.
>
> **Stack**
>
> Utiliza Next.js para la aplicación y PostgreSQL como base de datos. Respeta la arquitectura y convenciones existentes del proyecto.
>
> **Objetivo**
>
> Implementa el módulo de agendamiento de citas.
>
> **Flujo funcional**
>
> 1. El paciente debe seleccionar una especialidad.
> 2. Debe seleccionar un doctor disponible.
> 3. Debe seleccionar una fecha.
> 4. El sistema debe mostrar únicamente horarios disponibles.
> 5. El paciente selecciona un horario.
> 6. El sistema muestra un resumen de la cita.
> 7. El paciente confirma la reserva.
> 8. El backend valida nuevamente la disponibilidad.
> 9. Si el horario continúa disponible, se crea la cita.
> 10. Si el horario ya fue ocupado, se debe informar al paciente y solicitar que seleccione otro horario.
>
> **Reglas de negocio**
>
> * Un doctor no puede tener dos citas activas en el mismo horario.
> * Un paciente no debe poder crear reservas duplicadas para el mismo horario.
> * Solo deben mostrarse horarios correspondientes a la disponibilidad configurada del doctor.
> * No permitir reservas en fechas u horarios no disponibles.
> * Validar todas las reglas en el backend.
> * No confiar exclusivamente en las validaciones realizadas en el frontend.
>
> **Concurrencia**
>
> Considera que dos pacientes pueden intentar reservar el mismo horario simultáneamente.
>
> La implementación debe utilizar transacciones y mecanismos adecuados de PostgreSQL para garantizar la integridad de la reserva.
>
> **Seguridad**
>
> * Validar autenticación y autorización.
> * No permitir que un paciente cree una cita para otro usuario sin autorización.
> * Validar y sanitizar las entradas.
> * Utilizar consultas parametrizadas u ORM.
> * No incluir secretos en el código.
> * No exponer información sensible en mensajes de error.
> * Registrar eventos importantes sin almacenar innecesariamente datos médicos sensibles.
>
> **Frontend**
>
> Crear una interfaz clara para seleccionar:
>
> * Especialidad.
> * Doctor.
> * Fecha.
> * Horario.
> * Confirmación.
>
> Mostrar estados de carga, errores y confirmación de la reserva.
>
> Evitar que el usuario pueda enviar múltiples solicitudes mientras una reserva está siendo procesada.
>
> **Backend**
>
> Crear los endpoints necesarios para:
>
> * Consultar disponibilidad.
> * Crear una cita.
> * Validar conflictos.
>
> Las reglas de negocio críticas deben ejecutarse en el backend.
>
> **Testing**
>
> Genera pruebas para:
>
> * Reserva exitosa.
> * Doctor sin disponibilidad.
> * Horario ya ocupado.
> * Usuario no autenticado.
> * Usuario sin permisos.
> * Datos inválidos.
> * Reserva duplicada.
> * Dos solicitudes simultáneas para el mismo horario.
>
> **Entregables**
>
> 1. Código necesario para el módulo.
> 2. Tests unitarios y de integración.
> 3. Explicación breve de la arquitectura utilizada.
> 4. Identificación de posibles riesgos.
>
> Antes de finalizar, revisa el código buscando problemas de seguridad, concurrencia, validación y consistencia de datos. No asumas que las validaciones del frontend son suficientes.

---

# 16. Justificación de la estructura del prompt

El prompt fue dividido en secciones para reducir ambigüedades y permitir que el agente de IA trabaje dentro de límites técnicos definidos.

Primero se establece el rol del agente y el contexto del sistema. Después se especifica el stack tecnológico para evitar que la IA seleccione tecnologías diferentes a las definidas por el equipo.

Posteriormente se detallan el flujo funcional y las reglas de negocio, ya que el agendamiento de citas contiene reglas que no deberían quedar sujetas a interpretaciones de la IA.

También se incluye una sección específica para concurrencia porque la doble reserva es uno de los principales riesgos técnicos del módulo.

La seguridad se define explícitamente porque se trata de información relacionada con pacientes. Finalmente, se solicitan pruebas unitarias y de integración para que el código generado pueda ser validado y no se considere correcto únicamente porque compile.

La intención es que el agente genere código dentro de límites previamente establecidos, mientras que el Tech Lead conserva el control sobre las decisiones críticas.

---

# 17. Flujo de revisión del código generado por IA

Todo código generado por IA seguirá el siguiente proceso:

```text
IA genera código
       │
       ▼
Análisis estático / Linter
       │
       ▼
Tests automatizados
       │
       ▼
Revisión del desarrollador
       │
       ▼
Code Review del Tech Lead
       │
       ▼
Validación de seguridad
       │
       ▼
Pruebas de integración
       │
       ▼
Pull Request aprobado
       │
       ▼
Deploy
```

Ningún código generado directamente por IA debería llegar a producción sin pasar por este proceso.

---

# 18. Reflexión final

La inteligencia artificial puede reducir significativamente el tiempo de desarrollo al encargarse de tareas repetitivas, generar código base, crear pruebas y producir documentación. Sin embargo, en un sistema médico no considero adecuado delegar completamente en IA las decisiones relacionadas con seguridad, privacidad, arquitectura, integridad de datos y reglas críticas del negocio. Como Tech Lead utilizaría la IA como un multiplicador de productividad, estableciendo límites claros, revisiones humanas obligatorias, pruebas automatizadas y controles de seguridad dentro del pipeline CI/CD. De esta manera se obtiene velocidad de desarrollo sin perder el control técnico ni asumir que el código generado automáticamente es correcto por defecto.
