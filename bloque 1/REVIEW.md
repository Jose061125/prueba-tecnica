# REVIEW.md

## 1. Introducción

El presente documento contiene la revisión técnica de dos fragmentos de código generados mediante inteligencia artificial: un componente desarrollado en Vue 3 y una consulta SQL. El objetivo es identificar problemas relacionados con lógica, seguridad, rendimiento, mantenibilidad y experiencia de usuario, clasificarlos según su severidad y proponer soluciones concretas.

Además, se analiza por qué la inteligencia artificial pudo haber generado cada fragmento, se revisa el prompt utilizado para generar la consulta SQL y se propone una versión más precisa del mismo.

---

# 2. Revisión del componente Vue 3

## 2.1 Resumen

El componente permite consultar una lista de usuarios mediante una API, mostrar su nombre y correo electrónico y eliminar usuarios. A nivel básico, el código es funcional, pero presenta varios aspectos que deberían mejorarse antes de utilizarlo en un entorno productivo.

## 2.2 Tabla de hallazgos

| # | Problema                                                    | Severidad | Solución propuesta                                                                                                          |
| - | ----------------------------------------------------------- | --------- | --------------------------------------------------------------------------------------------------------------------------- |
| 1 | No existe manejo de errores en `deleteUser()`               | 🟡 Medio  | Implementar `try/catch` alrededor de la petición DELETE y mostrar un mensaje controlado al usuario.                         |
| 2 | La URL de la API está escrita directamente en el componente | 🟡 Medio  | Utilizar variables de entorno, por ejemplo `import.meta.env.VITE_API_URL`, para separar la configuración del código fuente. |
| 3 | El usuario puede eliminar un registro sin confirmación      | 🟡 Medio  | Solicitar confirmación antes de realizar una operación destructiva.                                                         |
| 4 | El botón de eliminación no tiene estado de carga            | 🟢 Bajo   | Mantener un estado de eliminación por usuario y deshabilitar el botón mientras la petición está en proceso.                 |
| 5 | Se muestra directamente `err.message` al usuario            | 🟢 Bajo   | Manejar los errores de Axios y mostrar mensajes amigables, evitando exponer información técnica innecesaria.                |
| 6 | No se valida la estructura de `response.data`               | 🟢 Bajo   | Validar que la respuesta recibida tenga la estructura esperada antes de asignarla a `users`.                                |

### Hallazgo 1: Manejo de errores en `deleteUser()`

**Severidad: 🟡 Medio**

El método `deleteUser()` realiza una petición HTTP mediante `axios.delete()`, pero no contiene un bloque `try/catch`.

Si la API responde con un error, por ejemplo un `404`, `401`, `403` o `500`, la excepción no es manejada por el componente. Esto puede producir una mala experiencia de usuario y dificultar el diagnóstico del problema.

### Solución

Agregar manejo de excepciones:

```javascript
const deleteUser = async (id) => {
  try {
    await axios.delete(`${API_URL}/users/${id}`)
    users.value = users.value.filter(user => user.id !== id)
  } catch (err) {
    error.value = 'No fue posible eliminar el usuario.'
  }
}
```

De esta forma, el usuario solo se elimina localmente cuando la API confirma correctamente la operación.

---

### Hallazgo 2: URL de API hardcodeada

**Severidad: 🟡 Medio**

La URL:

```javascript
https://api.example.com/users
```

está directamente dentro del componente.

Esto dificulta el mantenimiento y obliga a modificar el código cuando se cambia de entorno, por ejemplo entre desarrollo, pruebas y producción.

### Solución

Utilizar variables de entorno:

```javascript
const API_URL = import.meta.env.VITE_API_URL
```

Y posteriormente:

```javascript
axios.get(`${API_URL}/users`)
```

Esto permite configurar diferentes endpoints sin modificar el código fuente.

---

### Hallazgo 3: Eliminación sin confirmación

**Severidad: 🟡 Medio**

La acción de eliminar un usuario es destructiva y actualmente se ejecuta inmediatamente después de hacer clic en el botón.

Esto puede provocar eliminaciones accidentales.

### Solución

Agregar una confirmación antes de ejecutar la petición:

```javascript
const deleteUser = async (id) => {
  const confirmed = confirm('¿Está seguro de eliminar este usuario?')

  if (!confirmed) return

  // Ejecutar eliminación
}
```

En una aplicación real también podría utilizarse un modal personalizado para proporcionar una mejor experiencia de usuario.

---

### Hallazgo 4: Falta de estado de carga durante la eliminación

**Severidad: 🟢 Bajo**

El componente tiene un estado general `loading`, pero este únicamente se utiliza durante la carga inicial de usuarios.

Durante la eliminación no existe ningún indicador que informe al usuario de que la operación está en proceso.

Además, el usuario podría hacer clic varias veces sobre el botón y generar múltiples solicitudes.

### Solución

Implementar un estado específico para la eliminación, por ejemplo:

```javascript
const deletingId = ref(null)

const deleteUser = async (id) => {
  deletingId.value = id

  try {
    await axios.delete(`${API_URL}/users/${id}`)
    users.value = users.value.filter(user => user.id !== id)
  } finally {
    deletingId.value = null
  }
}
```

El botón podría deshabilitarse mientras `deletingId` corresponda al usuario seleccionado.

---

### Hallazgo 5: Exposición directa del mensaje de error

**Severidad: 🟢 Bajo**

El código utiliza:

```javascript
error.value = err.message
```

Mostrar directamente mensajes provenientes de excepciones no siempre es recomendable, ya que pueden contener información técnica que no es útil para el usuario final.

### Solución

Utilizar mensajes controlados:

```javascript
catch (err) {
  console.error(err)
  error.value = 'Ocurrió un error al realizar la operación.'
}
```

En un sistema real se puede diferenciar entre errores de autenticación, autorización, servidor o problemas de red.

---

### Hallazgo 6: Falta de validación de la respuesta

**Severidad: 🟢 Bajo**

El código asume que `response.data` siempre contiene un arreglo válido de usuarios:

```javascript
users.value = response.data
```

Si la API cambia su estructura o devuelve datos inesperados, el componente podría comportarse incorrectamente.

### Solución

Validar la respuesta antes de asignarla:

```javascript
if (Array.isArray(response.data)) {
  users.value = response.data
} else {
  throw new Error('Formato de respuesta inválido')
}
```

---

# 3. Análisis de por qué la IA generó el componente Vue

El componente parece haber sido generado a partir de un prompt general orientado a construir rápidamente una interfaz CRUD básica, posiblemente similar a:

> "Crea un componente Vue 3 que consulte una lista de usuarios desde una API, los muestre en pantalla y permita eliminarlos."

Este tipo de prompt explica que la IA haya priorizado la funcionalidad principal: obtener usuarios, mostrarlos y eliminarlos.

Sin embargo, el prompt no especifica requisitos de producción como manejo de errores para cada operación, configuración mediante variables de entorno, autenticación, autorización, accesibilidad, confirmación de acciones destructivas, prevención de solicitudes duplicadas o validación de respuestas.

Por esta razón, el resultado puede considerarse funcional como ejemplo inicial, pero requiere una revisión humana antes de incorporarlo a un sistema real.

---

# 4. Revisión de la consulta SQL

## 4.1 Consulta original

```sql
SELECT u.id, u.nombre, u.email, COUNT(t.id) as total_tareas
FROM usuarios u
LEFT JOIN tareas t ON u.id = t.usuario_id
WHERE t.estado = 'pendiente'
GROUP BY u.id, u.nombre, u.email
HAVING COUNT(t.id) > 0
ORDER BY total_tareas DESC;
```

## 4.2 Tabla de hallazgos

| # | Problema                                                                                                   | Severidad | Solución propuesta                                                                                |
| - | ---------------------------------------------------------------------------------------------------------- | --------- | ------------------------------------------------------------------------------------------------- |
| 1 | El `LEFT JOIN` pierde su comportamiento debido al `WHERE t.estado = 'pendiente'`                           | 🟡 Medio  | Mover el filtro de estado al `ON` si se deben incluir usuarios sin tareas pendientes.             |
| 2 | `HAVING COUNT(t.id) > 0` es redundante bajo la consulta actual                                             | 🟢 Bajo   | Eliminar el `HAVING` o utilizar `INNER JOIN` si solo se requieren usuarios con tareas pendientes. |
| 3 | El requerimiento "todos los usuarios con tareas pendientes" es ambiguo respecto a usuarios con cero tareas | 🟡 Medio  | Especificar en el requerimiento si los usuarios sin tareas deben aparecer con `0`.                |
| 4 | Puede existir un problema de rendimiento con grandes cantidades de tareas                                  | 🟢 Bajo   | Crear índices apropiados, especialmente sobre las columnas utilizadas en la relación y filtrado.  |

---

### Hallazgo 1: `LEFT JOIN` combinado con `WHERE`

**Severidad: 🟡 Medio**

La consulta utiliza:

```sql
LEFT JOIN tareas t ON u.id = t.usuario_id
WHERE t.estado = 'pendiente'
```

El objetivo de un `LEFT JOIN` es conservar los registros de la tabla izquierda aunque no tengan coincidencias en la tabla derecha.

Sin embargo, para usuarios sin tareas, `t.estado` sería `NULL`, por lo que la condición:

```sql
WHERE t.estado = 'pendiente'
```

descarta esos registros.

Por lo tanto, aunque se utilizó `LEFT JOIN`, el comportamiento termina siendo equivalente a utilizar un `INNER JOIN` para este caso.

### Solución

Si el objetivo es mostrar **todos los usuarios**, incluyendo aquellos que no tengan tareas pendientes, el filtro debe colocarse en el `ON`:

```sql
SELECT 
    u.id,
    u.nombre,
    u.email,
    COUNT(t.id) AS total_tareas
FROM usuarios u
LEFT JOIN tareas t 
    ON u.id = t.usuario_id
    AND t.estado = 'pendiente'
GROUP BY u.id, u.nombre, u.email
ORDER BY total_tareas DESC;
```

De esta manera, los usuarios sin tareas pendientes aparecerán con `total_tareas = 0`.

---

### Hallazgo 2: `HAVING COUNT(t.id) > 0` redundante

**Severidad: 🟢 Bajo**

En la consulta original se utiliza:

```sql
HAVING COUNT(t.id) > 0
```

Después de haber filtrado las tareas mediante:

```sql
WHERE t.estado = 'pendiente'
```

La condición del `HAVING` resulta redundante para el resultado buscado.

### Solución

Si se quieren mostrar únicamente usuarios con tareas pendientes, puede utilizarse directamente `INNER JOIN`:

```sql
SELECT 
    u.id,
    u.nombre,
    u.email,
    COUNT(t.id) AS total_tareas
FROM usuarios u
INNER JOIN tareas t 
    ON u.id = t.usuario_id
WHERE t.estado = 'pendiente'
GROUP BY u.id, u.nombre, u.email
ORDER BY total_tareas DESC;
```

Esta alternativa expresa mejor la intención de obtener únicamente usuarios que tengan al menos una tarea pendiente.

---

### Hallazgo 3: Ambigüedad en el requerimiento

**Severidad: 🟡 Medio**

El prompt indica:

> "muestre todos los usuarios con tareas pendientes"

Esta frase puede interpretarse de dos formas:

1. Mostrar únicamente usuarios que tengan al menos una tarea pendiente.
2. Mostrar todos los usuarios y contabilizar cuántas tareas pendientes tiene cada uno, incluyendo usuarios con cero.

La elección del `JOIN` depende directamente de esta interpretación.

### Solución

Especificar explícitamente el comportamiento esperado en el prompt.

Por ejemplo:

> "Incluye todos los usuarios, incluso aquellos que no tengan tareas pendientes, mostrando 0 en el contador."

O:

> "Muestra únicamente los usuarios que tengan al menos una tarea pendiente."

---

### Hallazgo 4: Posible problema de rendimiento

**Severidad: 🟢 Bajo**

En una base de datos con una cantidad considerable de usuarios y tareas, la consulta puede requerir revisar un número elevado de registros.

Las columnas utilizadas para relacionar y filtrar los registros deberían contar con índices adecuados.

### Solución

Dependiendo del motor de base de datos y del volumen de información, podría utilizarse un índice compuesto como:

```sql
CREATE INDEX idx_tareas_usuario_estado
ON tareas(usuario_id, estado);
```

La conveniencia exacta del índice debe comprobarse mediante el plan de ejecución y las características reales de la base de datos.

---

# 5. Análisis de por qué la IA generó la consulta SQL

La consulta fue generada a partir del siguiente prompt:

> "Genera una consulta SQL que muestre todos los usuarios con tareas pendientes, ordenados por cantidad de tareas pendientes de mayor a menor."

El resultado muestra una interpretación parcialmente correcta del requerimiento.

La IA identificó correctamente que era necesario relacionar las tablas `usuarios` y `tareas`, filtrar las tareas cuyo estado fuera `pendiente`, agrupar por usuario y ordenar por la cantidad de tareas.

Sin embargo, el prompt no especificaba qué debía ocurrir con los usuarios que no tienen tareas pendientes. La IA utilizó un `LEFT JOIN`, posiblemente intentando conservar todos los usuarios, pero posteriormente agregó el filtro `WHERE t.estado = 'pendiente'`, lo que cambia la semántica del `LEFT JOIN`.

Esto demuestra que una IA puede generar código sintácticamente válido y aparentemente lógico, pero no necesariamente interpretar correctamente todos los requisitos funcionales implícitos.

---

# 6. Prompt corregido

## 6.1 Prompt propuesto

> Genera una consulta SQL para obtener la cantidad de tareas pendientes asociadas a cada usuario.
>
> La base de datos contiene las tablas:
>
> * `usuarios(id, nombre, email)`
> * `tareas(id, usuario_id, estado)`
>
> La relación entre las tablas es `usuarios.id = tareas.usuario_id`.
>
> Una tarea pendiente se identifica cuando `tareas.estado = 'pendiente'`.
>
> El resultado debe:
>
> 1. Incluir todos los usuarios, incluso aquellos que no tengan tareas pendientes.
> 2. Mostrar las columnas `id`, `nombre`, `email` y `total_tareas`.
> 3. Mostrar `0` como `total_tareas` cuando un usuario no tenga tareas pendientes.
> 4. Ordenar los resultados de mayor a menor cantidad de tareas pendientes.
> 5. Utilizar correctamente `LEFT JOIN`, colocando el filtro de estado en la condición del `JOIN`.
> 6. Evitar condiciones redundantes.
>
> Proporciona únicamente la consulta SQL y una breve explicación de por qué la consulta conserva los usuarios que tienen cero tareas pendientes.

## 6.2 Justificación de los cambios

El prompt corregido proporciona información que el prompt original no especificaba.

Primero, define explícitamente la estructura de las tablas y la relación entre ellas. Esto reduce la posibilidad de que la IA tenga que asumir nombres de columnas o relaciones.

Segundo, define qué significa "todos los usuarios", indicando que deben incluirse aquellos que no tengan tareas pendientes. Esto permite determinar correctamente que se debe utilizar `LEFT JOIN`.

Tercero, especifica que los usuarios sin tareas pendientes deben mostrar un valor de `0`. De esta manera, se define claramente el resultado esperado.

Finalmente, se indica explícitamente dónde debe aplicarse el filtro `estado = 'pendiente'` y se solicita evitar condiciones redundantes. Esto orienta a la IA hacia una consulta con una semántica correcta y facilita posteriormente la revisión humana.

---

# 7. Consulta SQL esperada

Con base en el prompt corregido, una solución adecuada sería:

```sql
SELECT 
    u.id,
    u.nombre,
    u.email,
    COUNT(t.id) AS total_tareas
FROM usuarios u
LEFT JOIN tareas t
    ON u.id = t.usuario_id
    AND t.estado = 'pendiente'
GROUP BY u.id, u.nombre, u.email
ORDER BY total_tareas DESC;
```

Esta consulta mantiene a todos los usuarios debido al `LEFT JOIN`. El filtro de tareas pendientes se aplica dentro de la condición del `JOIN`, por lo que los usuarios sin tareas pendientes permanecen en el resultado y `COUNT(t.id)` devuelve `0` para ellos.

---

# 8. Reflexión: integración de IA en un flujo CI/CD

Integraría la revisión de código generado por IA como una etapa adicional dentro del flujo de CI/CD, pero sin reemplazar la revisión humana. El código generado por IA debería pasar primero por análisis estático, linters, pruebas automatizadas, análisis de seguridad y validaciones de calidad antes de crear un Pull Request. Posteriormente, un desarrollador debería revisar la lógica, los requisitos funcionales y posibles problemas que las herramientas automáticas no detecten. De esta manera, la IA puede utilizarse para aumentar la productividad del equipo, mientras que las pruebas automatizadas y la revisión humana garantizan que el código cumpla los requisitos técnicos, funcionales y de seguridad antes de llegar a producción.
