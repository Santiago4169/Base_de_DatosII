

-- Trigger 1: Actualizar fecha de modificación del evento
CREATE OR REPLACE FUNCTION core.actualizar_fecha_evento()
RETURNS trigger AS $$
BEGIN
  NEW.actualizado_en := NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_actualiza_evento
BEFORE UPDATE ON core.eventos
FOR EACH ROW
EXECUTE FUNCTION core.actualizar_fecha_evento();

-- Trigger 2: Validar capacidad antes de inscribir
CREATE OR REPLACE FUNCTION participacion.validar_capacidad_evento()
RETURNS trigger AS $$
DECLARE
  inscripciones_actuales INT;
  capacidad_evento INT;
BEGIN
  SELECT COUNT(*) INTO inscripciones_actuales
  FROM participacion.inscripciones
  WHERE evento_id = NEW.evento_id AND estado_inscripcion = 'confirmada';

  SELECT capacidad_maxima INTO capacidad_evento
  FROM core.eventos
  WHERE evento_id = NEW.evento_id;

  IF inscripciones_actuales >= capacidad_evento THEN
    RAISE EXCEPTION 'No se puede inscribir: se alcanzó la capacidad máxima del evento.';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validar_capacidad
BEFORE INSERT ON participacion.inscripciones
FOR EACH ROW
EXECUTE FUNCTION participacion.validar_capacidad_evento();

-- Trigger 3: Cancelar pago si inscripción es cancelada
CREATE OR REPLACE FUNCTION facturacion.cancelar_pago_por_cancelacion()
RETURNS trigger AS $$
BEGIN
  IF NEW.estado_inscripcion = 'cancelada' AND OLD.estado_inscripcion != 'cancelada' THEN
    UPDATE facturacion.pagos
    SET estado_pago = 'cancelado'
    WHERE inscripcion_id = NEW.inscripcion_id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_cancelar_pago
AFTER UPDATE ON participacion.inscripciones
FOR EACH ROW
EXECUTE FUNCTION facturacion.cancelar_pago_por_cancelacion();


-- Validar trigger 1

SELECT actualizado_en FROM core.eventos WHERE evento_id = 1;

UPDATE core.eventos
SET descripcion = 'Actualizado por prueba'
WHERE evento_id = 1;

SELECT actualizado_en FROM core.eventos WHERE evento_id = 1;

-- Validar trigger 2

SELECT capacidad_maxima FROM core.eventos WHERE evento_id = 1;

--- Ver cuántos confirmados hay
SELECT COUNT(*) FROM participacion.inscripciones
WHERE evento_id = 1 AND estado_inscripcion = 'confirmada';

INSERT INTO participacion.inscripciones (evento_id, asistente_id, estado_inscripcion)
VALUES (1, 4, 'confirmada');

-- Validar trigger 3

SELECT estado_pago FROM facturacion.pagos WHERE inscripcion_id = 1;

UPDATE participacion.inscripciones
SET estado_inscripcion = 'cancelada'
WHERE inscripcion_id = 1;


SELECT estado_pago FROM facturacion.pagos WHERE inscripcion_id = 1;


/*UPDATE facturacion.pagos 
SET estado_pago = 'confirmado'
WHERE inscripcion_id = 1;*/

















