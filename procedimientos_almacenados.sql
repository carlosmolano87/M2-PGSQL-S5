--1. Crear una nueva cuenta bancaria

CREATE OR REPLACE PROCEDURE crear_cuenta_bancaria(
    p_cliente_id INTEGER,
    p_numero_cuenta VARCHAR(20),
    p_tipo_cuenta VARCHAR(20),
    p_saldo NUMERIC(12,2),
    p_fecha_apertura DATE,
    p_estado VARCHAR(20)
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO cuentas_bancarias (cliente_id, numero_cuenta, tipo_cuenta, saldo, fecha_apertura, estado)
    VALUES (p_cliente_id, p_numero_cuenta, p_tipo_cuenta, p_saldo, p_fecha_apertura, p_estado);
END;
$$;


--2. Actualizar la información del cliente

CREATE OR REPLACE PROCEDURE actualizar_informacion_cliente(
    p_cliente_id INTEGER,
    p_direccion VARCHAR(100),
    p_telefono VARCHAR(20),
    p_correo_electronico VARCHAR(100)
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE clientes
    SET direccion = p_direccion, telefono = p_telefono, correo_electronico = p_correo_electronico
    WHERE cliente_id = p_cliente_id;
END;
$$;


--3. Eliminar una cuenta bancaria

CREATE OR REPLACE PROCEDURE eliminar_cuenta_bancaria(
    p_cuenta_id INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM transacciones WHERE cuenta_id = p_cuenta_id;
    DELETE FROM cuentas_bancarias WHERE cuenta_id = p_cuenta_id;
END;
$$;


--4. Transferir fondos entre cuentas

CREATE OR REPLACE PROCEDURE transferir_fondos(
    p_cuenta_origen INTEGER,
    p_cuenta_destino INTEGER,
    p_monto NUMERIC(12,2)
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE cuentas_bancarias
    SET saldo = saldo - p_monto
    WHERE cuenta_id = p_cuenta_origen;

    UPDATE cuentas_bancarias
    SET saldo = saldo + p_monto
    WHERE cuenta_id = p_cuenta_destino;

    INSERT INTO transacciones (cuenta_id, tipo_transaccion, monto, fecha_transaccion)
    VALUES (p_cuenta_origen, 'transferencia', p_monto, NOW());

    INSERT INTO transacciones (cuenta_id, tipo_transaccion, monto, fecha_transaccion)
    VALUES (p_cuenta_destino, 'transferencia', p_monto, NOW());
END;
$$;

--5. Agregar una nueva transacción

CREATE OR REPLACE PROCEDURE agregar_transaccion(
    p_cuenta_id INTEGER,
    p_tipo_transaccion VARCHAR(20),
    p_monto NUMERIC(12,2),
    p_descripcion TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_tipo_transaccion = 'deposito' THEN
        UPDATE cuentas_bancarias
        SET saldo = saldo + p_monto
        WHERE cuenta_id = p_cuenta_id;
    ELSIF p_tipo_transaccion = 'retiro' THEN
        UPDATE cuentas_bancarias
        SET saldo = saldo - p_monto
        WHERE cuenta_id = p_cuenta_id;
    END IF;

    INSERT INTO transacciones (cuenta_id, tipo_transaccion, monto, fecha_transaccion, descripcion)
    VALUES (p_cuenta_id, p_tipo_transaccion, p_monto, NOW(), p_descripcion);
END;
$$;


--6. Calcular el saldo total de todas las cuentas de un cliente

CREATE OR REPLACE FUNCTION calcular_saldo_total_cliente(
    p_cliente_id INTEGER
)
RETURNS NUMERIC(12,2)
LANGUAGE plpgsql
AS $$
DECLARE
    v_saldo_total NUMERIC(12,2);
BEGIN
    SELECT SUM(saldo)
    INTO v_saldo_total
    FROM cuentas_bancarias
    WHERE cliente_id = p_cliente_id;

    RETURN v_saldo_total;
END;
$$;


--7. Generar un reporte de transacciones para un rango de fechas

CREATE OR REPLACE FUNCTION reporte_transacciones(
    p_fecha_inicio DATE,
    p_fecha_fin DATE
)
RETURNS TABLE (
    transaccion_id INTEGER,
    cuenta_id INTEGER,
    tipo_transaccion VARCHAR(20),
    monto NUMERIC(12,2),
    fecha_transaccion TIMESTAMP,
    descripcion TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        transaccion_id, cuenta_id, tipo_transaccion, monto, fecha_transaccion, descripcion
    FROM 
        transacciones
    WHERE 
        fecha_transaccion BETWEEN p_fecha_inicio AND p_fecha_fin;
END;
$$;

