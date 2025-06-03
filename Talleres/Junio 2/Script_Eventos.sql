-- Crear esquemas
CREATE SCHEMA IF NOT EXISTS core;
CREATE SCHEMA IF NOT EXISTS participacion;
CREATE SCHEMA IF NOT EXISTS facturacion;

CREATE TABLE core.ubicaciones (
  ubicacion_id   SERIAL PRIMARY KEY,
  nombre         VARCHAR(100) NOT NULL,
  direccion      TEXT NOT NULL,
  ciudad         VARCHAR(50) NOT NULL,
  estado         VARCHAR(50),
  pais           VARCHAR(50) NOT NULL,
  capacidad      INT,
  descripcion    TEXT
);

CREATE TABLE core.organizadores (
  organizador_id     SERIAL PRIMARY KEY,
  nombre             VARCHAR(100) NOT NULL,
  correo_electronico VARCHAR(100) NOT NULL UNIQUE,
  telefono           VARCHAR(20),
  sitio_web          VARCHAR(150),
  descripcion        TEXT
);

CREATE TABLE core.eventos (
  evento_id        SERIAL PRIMARY KEY,
  titulo           VARCHAR(150) NOT NULL,
  descripcion      TEXT,
  fecha_inicio     TIMESTAMP NOT NULL,
  fecha_fin        TIMESTAMP,
  capacidad_maxima INT,
  estado           VARCHAR(20), 
  creado_en        TIMESTAMP DEFAULT NOW(),
  actualizado_en   TIMESTAMP DEFAULT NOW(),
  ubicacion_id     INT NOT NULL,
  FOREIGN KEY (ubicacion_id) REFERENCES core.ubicaciones(ubicacion_id)
);

CREATE TABLE core.evento_organizadores (
  evento_id       INT NOT NULL,
  organizador_id  INT NOT NULL,
  rol             VARCHAR(50) DEFAULT 'principal',
  PRIMARY KEY (evento_id, organizador_id),
  FOREIGN KEY (evento_id) REFERENCES core.eventos(evento_id),
  FOREIGN KEY (organizador_id) REFERENCES core.organizadores(organizador_id)
);

CREATE TABLE participacion.asistentes (
  asistente_id       SERIAL PRIMARY KEY,
  nombre             VARCHAR(100) NOT NULL,
  apellido           VARCHAR(100) NOT NULL,
  correo_electronico VARCHAR(100) NOT NULL UNIQUE,
  telefono           VARCHAR(20),
  fecha_registro     TIMESTAMP DEFAULT NOW()
);

CREATE TABLE participacion.inscripciones (
  inscripcion_id      SERIAL PRIMARY KEY,
  fecha_inscripcion   TIMESTAMP DEFAULT NOW(),
  estado_inscripcion  VARCHAR(20),
  evento_id           INT NOT NULL,
  asistente_id        INT NOT NULL,
  FOREIGN KEY (evento_id) REFERENCES core.eventos(evento_id),
  FOREIGN KEY (asistente_id) REFERENCES participacion.asistentes(asistente_id)
);

CREATE TABLE facturacion.pagos (
  pago_id        SERIAL PRIMARY KEY,
  monto          DECIMAL(10,2) NOT NULL,
  moneda         VARCHAR(3) DEFAULT 'USD',
  metodo_pago    VARCHAR(50),
  fecha_pago     TIMESTAMP DEFAULT NOW(),
  estado_pago    VARCHAR(20),
  inscripcion_id INT NOT NULL,
  FOREIGN KEY (inscripcion_id) REFERENCES participacion.inscripciones(inscripcion_id)
);

INSERT INTO core.ubicaciones (nombre, direccion, ciudad, estado, pais, capacidad, descripcion)
VALUES
  ('Centro de Convenciones A', 'Av. Principal 123', 'Ciudad X', 'Estado Y', 'País Z', 500, 'Ubicación para eventos grandes'),
  ('Auditorio B', 'Calle 456', 'Ciudad X', 'Estado Y', 'País Z', 200, 'Auditorio techado con sonido integrado');

 INSERT INTO core.organizadores (nombre, correo_electronico, telefono, sitio_web, descripcion)
VALUES
  ('Organizador Uno', 'uno@eventos.com', '1234567890', 'http://organizadoruno.com', 'Organizador con amplia experiencia'),
  ('Organizador Dos', 'dos@eventos.com', '0987654321', NULL, 'Organiza eventos pequeños y medianos');
 
 INSERT INTO core.eventos (titulo, descripcion, fecha_inicio, fecha_fin, capacidad_maxima, estado, ubicacion_id)
VALUES
  ('Conferencia Tech 2025', 'Evento sobre tecnología', '2025-09-10 09:00:00', '2025-09-12 18:00:00', 500, 'programado', 1),
  ('Feria de Emprendimiento', 'Feria para startups locales', '2025-10-01 10:00:00', '2025-10-02 17:00:00', 200, 'programado', 2);

 INSERT INTO core.evento_organizadores (evento_id, organizador_id, rol)
VALUES
  (1, 1, 'principal'),
  (2, 2, 'colaborador');
 
 INSERT INTO participacion.asistentes (nombre, apellido, correo_electronico, telefono)
VALUES
  ('Ana', 'Pérez', 'ana.perez@mail.com', '555123456'),
  ('Luis', 'Gómez', 'luis.gomez@mail.com', '555654321');
 
INSERT INTO participacion.inscripciones (evento_id, asistente_id, estado_inscripcion)
VALUES
  (1, 1, 'confirmada'),
  (1, 2, 'pendiente');

INSERT INTO facturacion.pagos (monto, moneda, metodo_pago, estado_pago, inscripcion_id)
VALUES
  (100.00, 'USD', 'tarjeta', 'completado', 1),
  (100.00, 'USD', 'paypal', 'pendiente', 2);




 
 

