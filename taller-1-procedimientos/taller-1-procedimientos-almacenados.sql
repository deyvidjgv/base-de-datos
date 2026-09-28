-- ==============================================================================
-- TALLER 1: TRANSFERENCIA BANCARIA SEGURA CON PROCEDIMIENTOS ALMACENADOS
-- Dominio: Sistema Bancario (BancoDB)
-- Motor: MySQL 8.0+ / MariaDB
-- ==============================================================================
-- Objetivos de Aprendizaje:
--   1. Crear procedimientos almacenados con parámetros IN y OUT.
--   2. Implementar transacciones con control de concurrencia pesimista (FOR UPDATE).
--   3. Utilizar COMMIT y ROLLBACK según el cumplimiento de reglas de negocio.
--   4. Implementar manejo de excepciones estructurado con DECLARE EXIT HANDLER FOR SQLEXCEPTION.
--   5. Controlar códigos de estado (200 OK, 400 Saldo Insuficiente, 401 Monto Inválido, 500 Error DB).
--   6. Registrar auditorías de operaciones y usuario responsable.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- PASO 1: CREAR Y SELECCIONAR LA BASE DE DATOS
-- ------------------------------------------------------------------------------
CREATE DATABASE IF NOT EXISTS BancoDB;
USE BancoDB;

-- ------------------------------------------------------------------------------
-- PASO 2: CREAR LAS TABLAS DEL SISTEMA BANCARIO
-- ------------------------------------------------------------------------------
DROP TABLE IF EXISTS auditoria_operaciones;
DROP TABLE IF EXISTS historial_transferencias;
DROP TABLE IF EXISTS cuentas;

-- Tabla: cuentas
CREATE TABLE cuentas (
    id_cuenta INT PRIMARY KEY,
    titular VARCHAR(100) NOT NULL,
    saldo DECIMAL(10,2) NOT NULL DEFAULT 0.00
);

-- Tabla: historial_transferencias
CREATE TABLE historial_transferencias (
    id_transferencia INT AUTO_INCREMENT PRIMARY KEY,
    cuenta_origen INT NOT NULL,
    cuenta_destino INT NOT NULL,
    monto DECIMAL(10,2) NOT NULL,
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (cuenta_origen) REFERENCES cuentas(id_cuenta),
    FOREIGN KEY (cuenta_destino) REFERENCES cuentas(id_cuenta)
);

-- Tabla adicional para el Desafío Extra: auditoria_operaciones
CREATE TABLE auditoria_operaciones (
    id_auditoria INT AUTO_INCREMENT PRIMARY KEY,
    id_transferencia INT NULL,
    cuenta_origen INT NOT NULL,
    cuenta_destino INT NOT NULL,
    monto DECIMAL(10,2) NOT NULL,
    codigo_resultado INT NOT NULL,
    mensaje_estado VARCHAR(150) NOT NULL,
    usuario_responsable VARCHAR(100) NOT NULL,
    fecha_operacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ------------------------------------------------------------------------------
-- PASO 3: INSERTAR DATOS DE PRUEBA INICIALES
-- ------------------------------------------------------------------------------
INSERT INTO cuentas (id_cuenta, titular, saldo) VALUES
(1, 'Ana López', 5000.00),
(2, 'Carlos Pérez', 3000.00),
(3, 'Mariana Silva', 1500.00);

-- Verificación de estructura y datos iniciales
-- (EVIDENCIA 01: evidencia_01_tablas_creadas.png)
SHOW TABLES;
SELECT * FROM cuentas;


-- ==============================================================================
-- PASO 4: CREACIÓN DEL PROCEDIMIENTO PRINCIPAL (TransferirFondos)
-- ==============================================================================
-- Parámetros:
--   IN  p_origen           INT          : ID de la cuenta que envía el dinero
--   IN  p_destino          INT          : ID de la cuenta que recibe el dinero
--   IN  p_monto            DECIMAL(10,2): Cantidad a transferir
--   OUT p_codigo_respuesta INT          : Código de estado resultante:
--                                          200: Transferencia Exitosa
--                                          400: Saldo Insuficiente
--                                          401: Monto Inválido (<= 0)
--                                          404: Cuenta Origen o Destino Inexistente
--                                          422: Origen y Destino idénticos
--                                          500: Excepción SQL / Error Interno
-- ==============================================================================

DELIMITER //

DROP PROCEDURE IF EXISTS TransferirFondos //

CREATE PROCEDURE TransferirFondos (
    IN  p_origen           INT,
    IN  p_destino          INT,
    IN  p_monto            DECIMAL(10,2),
    OUT p_codigo_respuesta INT
)
proc_label: BEGIN
    -- Declaración de variables locales
    DECLARE v_saldo_origen DECIMAL(10,2);
    DECLARE v_existe_origen INT DEFAULT 0;
    DECLARE v_existe_destino INT DEFAULT 0;
    DECLARE v_id_transf INT;

    -- Manejo estructurado de errores y excepciones SQL (Garantiza integridad)
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_codigo_respuesta = 500;
        
        -- Auditoría del error interno
        INSERT INTO auditoria_operaciones (cuenta_origen, cuenta_destino, monto, codigo_resultado, mensaje_estado, usuario_responsable)
        VALUES (p_origen, p_destino, p_monto, 500, 'Error crítico de base de datos (SQLEXCEPTION detectado - ROLLBACK forzado)', USER());
    END;

    -- --------------------------------------------------------------------------
    -- 1. VALIDACIÓN PREVENTIVA: Monto mayor que cero (Desafío Extra)
    -- --------------------------------------------------------------------------
    IF p_monto <= 0.00 THEN
        SET p_codigo_respuesta = 401;
        INSERT INTO auditoria_operaciones (cuenta_origen, cuenta_destino, monto, codigo_resultado, mensaje_estado, usuario_responsable)
        VALUES (p_origen, p_destino, p_monto, 401, 'Monto inválido (debe ser estrictamente mayor a 0)', USER());
        LEAVE proc_label;
    END IF;

    -- --------------------------------------------------------------------------
    -- 2. VALIDACIÓN: Las cuentas no pueden ser la misma
    -- --------------------------------------------------------------------------
    IF p_origen = p_destino THEN
        SET p_codigo_respuesta = 422;
        INSERT INTO auditoria_operaciones (cuenta_origen, cuenta_destino, monto, codigo_resultado, mensaje_estado, usuario_responsable)
        VALUES (p_origen, p_destino, p_monto, 422, 'Cuentas origen y destino no pueden ser iguales', USER());
        LEAVE proc_label;
    END IF;

    -- --------------------------------------------------------------------------
    -- 3. INICIO DE LA TRANSACCIÓN ACID
    -- --------------------------------------------------------------------------
    START TRANSACTION;

    -- Validar existencia y bloquear la fila de la cuenta de origen con FOR UPDATE
    SELECT saldo INTO v_saldo_origen
    FROM cuentas
    WHERE id_cuenta = p_origen
    FOR UPDATE;

    -- Validar existencia de la cuenta de destino
    SELECT COUNT(*) INTO v_existe_destino
    FROM cuentas
    WHERE id_cuenta = p_destino;

    -- Si alguna cuenta no existe en el sistema
    IF v_saldo_origen IS NULL OR v_existe_destino = 0 THEN
        ROLLBACK;
        SET p_codigo_respuesta = 404;
        INSERT INTO auditoria_operaciones (cuenta_origen, cuenta_destino, monto, codigo_resultado, mensaje_estado, usuario_responsable)
        VALUES (p_origen, p_destino, p_monto, 404, 'Cuenta de origen o destino no encontrada', USER());
        LEAVE proc_label;
    END IF;

    -- --------------------------------------------------------------------------
    -- 4. EVALUACIÓN DEL SALDO DISPONIBLE
    -- --------------------------------------------------------------------------
    IF v_saldo_origen >= p_monto THEN
        -- Saldo suficiente: Efectuar transferencia atómica
        -- A) Restar saldo en la cuenta de origen
        UPDATE cuentas 
        SET saldo = saldo - p_monto 
        WHERE id_cuenta = p_origen;

        -- B) Sumar saldo en la cuenta de destino
        UPDATE cuentas 
        SET saldo = saldo + p_monto 
        WHERE id_cuenta = p_destino;

        -- C) Registrar la transacción en el historial bancario
        INSERT INTO historial_transferencias (cuenta_origen, cuenta_destino, monto)
        VALUES (p_origen, p_destino, p_monto);
        
        SET v_id_transf = LAST_INSERT_ID();

        -- D) Confirmar cambios permanentemente
        COMMIT;

        -- E) Asignar código HTTP exitoso y auditar
        SET p_codigo_respuesta = 200;

        INSERT INTO auditoria_operaciones (id_transferencia, cuenta_origen, cuenta_destino, monto, codigo_resultado, mensaje_estado, usuario_responsable)
        VALUES (v_id_transf, p_origen, p_destino, p_monto, 200, 'Transferencia realizada con éxito (COMMIT ejecutado)', USER());

    ELSE
        -- Saldo insuficiente: Deshacer cualquier bloqueo y revertir
        ROLLBACK;
        SET p_codigo_respuesta = 400;

        INSERT INTO auditoria_operaciones (cuenta_origen, cuenta_destino, monto, codigo_resultado, mensaje_estado, usuario_responsable)
        VALUES (p_origen, p_destino, p_monto, 400, 'Saldo insuficiente en la cuenta de origen (ROLLBACK ejecutado)', USER());
    END IF;

END //

DELIMITER ;

-- Verificación de creación del procedimiento en el catálogo del sistema
-- (EVIDENCIA 02: evidencia_02_creacion_procedimiento.png)
SHOW PROCEDURE STATUS WHERE Db = 'BancoDB' AND Name = 'TransferirFondos';


-- ==============================================================================
-- DESAFÍO EXTRA ⭐: PROCEDIMIENTO EXTENDIDO CON PARÁMETRO OUT ADICIONAL
-- Procedimiento: TransferirFondosAvanzado
-- Parámetros adicionales requeridos por la guía:
--   OUT p_titular_origen VARCHAR(100) : Retorna el nombre del titular
--   Registro del usuario responsable (USER()) en auditoría
-- ==============================================================================

DELIMITER //

DROP PROCEDURE IF EXISTS TransferirFondosAvanzado //

CREATE PROCEDURE TransferirFondosAvanzado (
    IN  p_origen           INT,
    IN  p_destino          INT,
    IN  p_monto            DECIMAL(10,2),
    OUT p_codigo_respuesta INT,
    OUT p_titular_origen   VARCHAR(100)
)
proc_avanzado: BEGIN
    DECLARE v_saldo_origen DECIMAL(10,2);
    DECLARE v_existe_destino INT DEFAULT 0;
    DECLARE v_id_transf INT;

    -- Manejo de excepciones
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_codigo_respuesta = 500;
        SET p_titular_origen = 'DESCONOCIDO';
        INSERT INTO auditoria_operaciones (cuenta_origen, cuenta_destino, monto, codigo_resultado, mensaje_estado, usuario_responsable)
        VALUES (p_origen, p_destino, p_monto, 500, 'SQLEXCEPTION en procedimiento avanzado', USER());
    END;

    -- Obtener titular de origen
    SELECT titular INTO p_titular_origen FROM cuentas WHERE id_cuenta = p_origen;

    -- Validación de monto positivo (> 0)
    IF p_monto <= 0.00 THEN
        SET p_codigo_respuesta = 401;
        INSERT INTO auditoria_operaciones (cuenta_origen, cuenta_destino, monto, codigo_resultado, mensaje_estado, usuario_responsable)
        VALUES (p_origen, p_destino, p_monto, 401, 'Monto inválido reportado por procedimiento avanzado', USER());
        LEAVE proc_avanzado;
    END IF;

    START TRANSACTION;

    SELECT saldo, titular INTO v_saldo_origen, p_titular_origen
    FROM cuentas
    WHERE id_cuenta = p_origen
    FOR UPDATE;

    SELECT COUNT(*) INTO v_existe_destino FROM cuentas WHERE id_cuenta = p_destino;

    IF v_saldo_origen IS NULL OR v_existe_destino = 0 THEN
        ROLLBACK;
        SET p_codigo_respuesta = 404;
        LEAVE proc_avanzado;
    END IF;

    IF v_saldo_origen >= p_monto THEN
        UPDATE cuentas SET saldo = saldo - p_monto WHERE id_cuenta = p_origen;
        UPDATE cuentas SET saldo = saldo + p_monto WHERE id_cuenta = p_destino;

        INSERT INTO historial_transferencias (cuenta_origen, cuenta_destino, monto)
        VALUES (p_origen, p_destino, p_monto);
        SET v_id_transf = LAST_INSERT_ID();

        COMMIT;
        SET p_codigo_respuesta = 200;

        INSERT INTO auditoria_operaciones (id_transferencia, cuenta_origen, cuenta_destino, monto, codigo_resultado, mensaje_estado, usuario_responsable)
        VALUES (v_id_transf, p_origen, p_destino, p_monto, 200, CONCAT('Operación exitosa por: ', p_titular_origen), USER());
    ELSE
        ROLLBACK;
        SET p_codigo_respuesta = 400;
        INSERT INTO auditoria_operaciones (cuenta_origen, cuenta_destino, monto, codigo_resultado, mensaje_estado, usuario_responsable)
        VALUES (p_origen, p_destino, p_monto, 400, 'Fondos insuficientes reportados por avanzado', USER());
    END IF;

END //

DELIMITER ;


-- ==============================================================================
-- PASO 5: BATERÍA DE PRUEBAS Y GENERACIÓN DE EVIDENCIAS
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- CASO 1: TRANSFERENCIA EXITOSA (Código esperado: 200)
-- Ana (id: 1, saldo inicial: 5000) transfiere $1000 a Carlos (id: 2, saldo inicial: 3000)
-- Saldo final esperado: Ana = 4000, Carlos = 4000.
-- ------------------------------------------------------------------------------
-- (EVIDENCIA 03: evidencia_03_transferencia_exitosa.png)
CALL TransferirFondos(1, 2, 1000.00, @codigo);
SELECT @codigo AS codigo_respuesta;

-- Comprobación inmediata de actualización de saldos e historial:
SELECT * FROM cuentas WHERE id_cuenta IN (1, 2);
SELECT * FROM historial_transferencias;


-- ------------------------------------------------------------------------------
-- CASO 2: SALDO INSUFICIENTE (Código esperado: 400)
-- Ana intenta transferir $10,000 (solo dispone de $4,000). Debe hacer ROLLBACK.
-- Saldo esperado: Se mantienen inalterados ($4,000 y $4,000).
-- ------------------------------------------------------------------------------
-- (EVIDENCIA 04: evidencia_04_transferencia_saldo_insuficiente.png)
CALL TransferirFondos(1, 2, 10000.00, @codigo);
SELECT @codigo AS codigo_respuesta;

-- Comprobación: los saldos permanecen intactos
SELECT * FROM cuentas WHERE id_cuenta IN (1, 2);


-- ------------------------------------------------------------------------------
-- CASO 3: VALIDACIÓN DE MONTO INVÁLIDO - DESAFÍO EXTRA (Código esperado: 401)
-- Intento de transferir un monto negativo (-200) o en cero (0.00).
-- ------------------------------------------------------------------------------
-- (EVIDENCIA 05: evidencia_05_transferencia_monto_invalido.png)
CALL TransferirFondos(1, 2, -200.00, @codigo);
SELECT @codigo AS codigo_respuesta;


-- ------------------------------------------------------------------------------
-- CASO 4: PRUEBA DEL PROCEDIMIENTO AVANZADO CON PARÁMETRO OUT ADICIONAL
-- Mariana (id: 3, saldo: 1500) transfiere $500 a Carlos (id: 2).
-- ------------------------------------------------------------------------------
-- (EVIDENCIA 06: evidencia_06_procedimiento_avanzado.png)
CALL TransferirFondosAvanzado(3, 2, 500.00, @codigo, @titular);
SELECT @codigo AS codigo_respuesta, @titular AS titular_ordenante;


-- ------------------------------------------------------------------------------
-- CASO 5: REVISIÓN CONSOLIDADA DE LA AUDITORÍA DE OPERACIONES
-- Muestra el registro completo de intentos, usuarios responsables y códigos.
-- ------------------------------------------------------------------------------
-- (EVIDENCIA 07: evidencia_07_auditoria_completa.png)
SELECT 
    id_auditoria,
    id_transferencia,
    cuenta_origen,
    cuenta_destino,
    monto,
    codigo_resultado,
    mensaje_estado,
    usuario_responsable,
    fecha_operacion
FROM auditoria_operaciones;
