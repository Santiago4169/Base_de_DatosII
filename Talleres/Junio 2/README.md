<h1 style="text-align: center;">
Disparadores en SQL (Triggers)
</h1>

## ¿Qué son los disparadores y para qué se utilizan?

Los **disparadores (triggers)** en SQL son bloques de código que se ejecutan automáticamente en respuesta a ciertos eventos que ocurren sobre una tabla o vista. Estos eventos pueden ser:

- `INSERT`: cuando se agrega un nuevo registro.
- `UPDATE`: cuando se modifica un registro existente.
- `DELETE`: cuando se elimina un registro.


### Usos comunes de los disparadores:

- Registro de cambios (auditoría).
- Validación de datos antes de cambios.
- Mantenimiento de integridad referencial.
- Automatización de tareas administrativas.
- Sincronización entre tablas.

---
## Ventajas y Desventajas

### Ventajas:

- Automatización de procesos sin intervención manual.
- Mejora la integridad y consistencia de los datos.
- Útil para auditorías y seguimiento de cambios.
- Reduce duplicación de lógica en las aplicaciones cliente.

### Desventajas:

- Puede dificultar el mantenimiento si se abusa de ellos.
- El comportamiento no siempre es evidente para los desarrolladores.
- Puede afectar el rendimiento si se usan en operaciones frecuentes.
- No son portables entre diferentes motores de base de datos (sintaxis varía).

----


## Sintaxis de un disparador

### Sintaxis general (MySQL)

```sql
CREATE TRIGGER nombre_del_trigger
{BEFORE | AFTER} {INSERT | UPDATE | DELETE}
ON nombre_de_la_tabla
FOR EACH ROW
BEGIN
   -- Instrucciones SQL que se ejecutan
END;
```
### Explicación:

- **CREATE TRIGGER:** Crea un nuevo trigger.

- **{BEFORE | AFTER}:** Indica si el código se ejecuta antes o después del evento.

- **{INSERT | UPDATE | DELETE}:** Tipo de evento que activa el trigger.

- **ON nombre_de_la_tabla:** Tabla asociada al trigger.

- **FOR EACH ROW:** El trigger se ejecuta por cada fila afectada.

- **BEGIN ... END:** Bloque de instrucciones SQL.

---

## Ejemplos de uso

### Ejemplo 1: Auditoría de actualizaciones:

```sql
CREATE TRIGGER trigger_auditoria_update
AFTER UPDATE ON empleados
FOR EACH ROW
BEGIN
   INSERT INTO auditoria_empleados (id_empleado, usuario, fecha_cambio)
   VALUES (OLD.id, CURRENT_USER(), NOW());
END;
```
Este trigger se ejecuta después de una actualización en la tabla ```empleados``` y registra el cambio en ```auditoria_empleados```.

### Ejemplo 2: Validación antes de insertar

```sql
CREATE TRIGGER validar_salario
BEFORE INSERT ON empleados
FOR EACH ROW
BEGIN
   IF NEW.salario < 0 THEN
      SIGNAL SQLSTATE '45000' 
      SET MESSAGE_TEXT = 'El salario no puede ser negativo';
   END IF;
END;
```
Este trigger evita que se inserte un empleado con salario negativo usando ```SIGNAL```, que lanza un error personalizado.

### Ejemplo 3: Eliminar en cascada registros relacionados

```sql
CREATE TRIGGER borrar_detalles_orden
BEFORE DELETE ON ordenes
FOR EACH ROW
BEGIN
   DELETE FROM detalles_orden
   WHERE id_orden = OLD.id;
END;
```
Este trigger elimina automáticamente los detalles de la orden antes de eliminar la orden principal.

---

## Buenas prácticas

- Evitar lógica compleja dentro de los triggers.

- Documentar cada trigger claramente.

- Usar nombres descriptivos para saber qué hace el trigger.

- Probar exhaustivamente para evitar errores lógicos o efectos colaterales.

---

## ¿Y en otros motores de base de datos?

### PostgreSQL:

La sintaxis es diferente; requiere una función aparte que luego se asocia al trigger.

```sql
CREATE FUNCTION registrar_auditoria() RETURNS trigger AS $$
BEGIN
   INSERT INTO auditoria (tabla, accion, fecha) 
   VALUES ('empleados', TG_OP, NOW());
   RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_postgresql
AFTER UPDATE ON empleados
FOR EACH ROW
EXECUTE FUNCTION registrar_auditoria();
```
### SQL Server:

Utiliza una sintaxis más integrada con ````AFTER```` o ````INSTEAD OF````, y no requiere ````FOR EACH ROW```` (los triggers se disparan por lote).

````sql
CREATE TRIGGER trg_insert_empleados
ON empleados
AFTER INSERT
AS
BEGIN
   INSERT INTO log_empleados (id, fecha)
   SELECT id, GETDATE() FROM inserted;
END;
````
---

## Utilización de los disparadores en mi base de Datos

### Caso 1: Actualizar automáticamente la fecha de modificación del evento

#### Problema:

Cuando se actualiza cualquier información de un evento (por ejemplo, su capacidad, título, etc.), no se actualiza automáticamente el campo ````actualizado_en````, lo cual impide rastrear cuándo fue la última modificación.`

#### Solución: 

Crear un trigger ````BEFORE UPDATE```` que actualice el campo ````actualizado_en```` con la fecha y hora actuales.

````sql
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
````

### Caso 2: Verificar que la capacidad de la ubicación no sea superada al inscribir asistentes

#### Problema:

No existe una validación que impida inscribir más asistentes que la capacidad máxima del evento y su ubicación. Esto puede causar sobreventa de entradas.

#### Solución:

Crear un trigger ````BEFORE INSERT```` en ````participacion.inscripciones```` que verifique si la cantidad de inscripciones confirmadas excede la capacidad del evento.

````sql 
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
````

### Caso 3: Cambiar automáticamente el estado del pago si la inscripción se cancela

#### Problema:

Si una inscripción es cancelada manualmente, el estado del pago asociado no se actualiza, lo que puede dejar registros inconsistentes (como pagos completados para eventos cancelados).

#### Solución:

Crear un trigger ````AFTER UPDATE```` que, si el estado de la inscripción cambia a "cancelada", actualice el estado del pago relacionado a "cancelado".

````sql
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
````

## Conclusión

Los disparadores son una poderosa herramienta en SQL para automatizar tareas, garantizar la integridad de los datos y mantener reglas de negocio dentro de la base de datos. Usados con precaución y claridad, pueden simplificar la administración de datos y mejorar la seguridad y consistencia de los sistemas.