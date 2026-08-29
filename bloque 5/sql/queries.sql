USE clinica_reservas;

SELECT
    c.id,
    c.fecha_hora,
    p.nombre AS paciente,
    c.estado,
    c.motivo
FROM citas c
INNER JOIN pacientes p
    ON c.paciente_id = p.id
WHERE c.doctor_id = 1
  AND c.fecha_hora >= '2026-08-28 00:00:00'
  AND c.fecha_hora < '2026-08-29 00:00:00'
ORDER BY c.fecha_hora ASC;

"#¿Qué citas tiene el doctor Carlos el 28 de agosto?#" 


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
WHERE c.paciente_id = 1
ORDER BY c.fecha_hora DESC
LIMIT 10 OFFSET 0;

"#¿Cuál es el historial de citas del paciente 1?#"


SELECT
    c.id AS cita_id,
    p.nombre AS paciente,
    p.email,
    d.nombre AS doctor,
    c.fecha_hora,
    pg.monto,
    pg.estado_pago
FROM citas c
INNER JOIN pacientes p
    ON c.paciente_id = p.id
INNER JOIN doctores d
    ON c.doctor_id = d.id
LEFT JOIN pagos pg
    ON c.id = pg.cita_id
WHERE c.estado = 'pendiente_pago'
ORDER BY c.fecha_hora ASC;

"#Hay una reserva pendiente de pago.#" 

"ANALISIS: primero analicé el esquema generado por IA y detecté problemas de normalización, 
ausencia de restricciones, falta de índices y riesgos de integridad referencial. Después normalicé 
entidades como especialidades y horarios, agregué restricciones NOT NULL, UNIQUE y CHECK, definí claves 
foráneas e índices según los patrones de consulta. Finalmente implementé datos de prueba y validé
 que las restricciones y consultas funcionaran correctamente."