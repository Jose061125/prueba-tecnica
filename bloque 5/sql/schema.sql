CREATE DATABASE IF NOT EXISTS clinica_reservas;

USE clinica_reservas;

CREATE TABLE pacientes (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL,
    email VARCHAR(255) NOT NULL,
    telefono VARCHAR(20),
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    fecha_registro TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_pacientes_email UNIQUE (email)
);

"## la Ia habia generado ### id INT AUTO_INCREMENT PRIMARY KEY ###" y nosotros utilizamos
"## id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY###"  porque "bigint" permite un rango más amplio de valores y
 "UNSIGNED" asegura que el valor sea siempre positivo, lo cual es útil para identificadores únicos.

CREATE TABLE especialidades (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE,

    CONSTRAINT uq_especialidades_nombre UNIQUE (nombre)
);



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

"#aqui tenemos  tenemos foreign key Esto significa que especialidad_id tiene que existir en: especialidades(id)
para que se pueda insertar un doctor.
Esto asegura la integridad referencial entre las tablas."
"que hace el on delete restrict? Esto significa que no se puede eliminar una especialidad si hay doctores asociados a ella."
"el on update cascade significa que si se cambia el id de una especialidad, se actualizará automáticamente en la tabla doctores."


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

"enum es un tipo de dato que permite definir un conjunto de valores posibles para una columna.
En este caso, la columna estado de la tabla citas solo puede tener uno de los siguientes valores:
'pendiente_pago', 'confirmada', 'atendida', 'no_asistio', 'cancelada'. Esto ayuda a mantener la integridad de los datos
y evita errores al ingresar valores no válidos."