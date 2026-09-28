-- ==============================================================================
-- TALLER 5: TRIGGERS Y EVENTOS EN MYSQL (BancoDB)
-- Motor: MySQL 8.0+ / MariaDB
-- ==============================================================================
-- Objetivos de Aprendizaje:
--   1. Comprender la reactividad en tiempo real en la base de datos mediante TRIGGERS.
--   2. Distinguir entre eventos AFTER (auditoría/histórico) y BEFORE (validación/bloqueo).
--   3. Usar variables de transición OLD y NEW para comparar cambios de estado.
--   4. Lanzar errores controlados de negocio con SIGNAL SQLSTATE '45000'.
--   5. Programar tareas automáticas recurrentes mediante el Programador de EVENTOS (Event Scheduler).
-- ==============================================================================

CREATE DATABASE IF NOT EXISTS BancoDB;
USE BancoDB;

-- ------------------------------------------------------------------------------
-- PARTE 0: TABLAS BASE, AUDITORÍA Y MÉTRICAS (Estructura de Soporte)
-- ------------------------------------------------------------------------------

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS auditoria_operaciones;
DROP TABLE IF EXISTS auditoria_saldos;
DROP TABLE IF EXISTS metricas_diarias;
DROP TABLE IF EXISTS Transacciones;
DROP TABLE IF EXISTS Cuentas;
DROP TABLE IF EXISTS historial_transferencias;
DROP TABLE IF EXISTS cuentas;
SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE cuentas (
    id_cuenta INT PRIMARY KEY AUTO_INCREMENT,
    titular VARCHAR(100) NOT NULL,
    tipo_cuenta VARCHAR(20) NOT NULL DEFAULT 'Ahorros',
    saldo DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    estado VARCHAR(20) NOT NULL DEFAULT 'Activa',
    fecha_apertura DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE historial_transferencias (
    id_transferencia INT AUTO_INCREMENT PRIMARY KEY,
    cuenta_origen INT NOT NULL,
    cuenta_destino INT NOT NULL,
    monto DECIMAL(12,2) NOT NULL,
    estado_transferencia VARCHAR(20) NOT NULL DEFAULT 'Exitosa',
    fecha DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (cuenta_origen) REFERENCES cuentas(id_cuenta),
    FOREIGN KEY (cuenta_destino) REFERENCES cuentas(id_cuenta)
);

-- Tabla para auditar cambios de saldo en tiempo real (usada por el Trigger de auditoría)
CREATE TABLE auditoria_saldos (
    id_log INT AUTO_INCREMENT PRIMARY KEY,
    id_cuenta INT NOT NULL,
    saldo_anterior DECIMAL(12,2) NOT NULL,
    saldo_nuevo DECIMAL(12,2) NOT NULL,
    usuario VARCHAR(100) NOT NULL,
    fecha_modificacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_cuenta) REFERENCES cuentas(id_cuenta)
);

-- Tabla para guardar métricas consolidadas del sistema (usada por el Evento)
CREATE TABLE metricas_diarias (
    id_metrica INT AUTO_INCREMENT PRIMARY KEY,
    fecha_metrica DATE NOT NULL,
    total_cuentas INT NOT NULL,
    saldo_total_sistema DECIMAL(14,2) NOT NULL,
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Carga inicial de cuentas de prueba:
INSERT INTO cuentas (id_cuenta, titular, tipo_cuenta, saldo, estado) VALUES
(1, 'Carlos Mendoza',  'Ahorros',   2500000.00, 'Activa'),
(2, 'Ana Gómez',       'Corriente', 1800000.00, 'Activa'),
(3, 'Roberto Silva',   'Ahorros',         0.00, 'Activa'), -- Cuenta con saldo en cero para probar evento
(4, 'Mariana Restrepo', 'Ahorros',        0.00, 'Activa'); -- Cuenta con saldo en cero para probar evento

-- Habilitar el Programador de Eventos en el servidor MySQL
SET GLOBAL event_scheduler = ON;

-- Verificación de configuración inicial y tablas
-- (EVIDENCIA 01: evidencia_01_tablas_auditoria_y_event_scheduler.png)
SHOW VARIABLES LIKE 'event_scheduler';
SHOW TABLES;
SELECT * FROM cuentas;


-- ==============================================================================
-- PARTE 1: DEMOSTRACIÓN GUIADA EN CLASE
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1.1 TRIGGER DEMOSTRACIÓN: Auditoría Automática de Cambios de Saldo
-- Tipo: AFTER UPDATE sobre la tabla 'cuentas'
-- Concepto: Registra en auditoria_saldos únicamente cuando el saldo sufre un cambio.
-- ------------------------------------------------------------------------------

DELIMITER //

DROP TRIGGER IF EXISTS trg_auditar_cambio_saldo //

CREATE TRIGGER trg_auditar_cambio_saldo
AFTER UPDATE ON cuentas
FOR EACH ROW
BEGIN
    -- Detectar si hubo una modificación efectiva en la columna saldo
    IF OLD.saldo <> NEW.saldo THEN
        INSERT INTO auditoria_saldos (
            id_cuenta, 
            saldo_anterior, 
            saldo_nuevo, 
            usuario
        ) 
        VALUES (
            NEW.id_cuenta, 
            OLD.saldo, 
            NEW.saldo, 
            USER()
        );
    END IF;
END //

DELIMITER ;

-- PRUEBA DE DISPARO DEL TRIGGER DE AUDITORÍA:
-- (EVIDENCIA 02: evidencia_02_demo_trigger_auditoria_saldos.png)
-- Actualizar saldo de Carlos (cuenta 1):
UPDATE cuentas SET saldo = saldo + 500000.00 WHERE id_cuenta = 1;
-- Actualizar titular (NO debe disparar registro en auditoria_saldos pues el saldo no cambió):
UPDATE cuentas SET titular = 'Carlos Alberto Mendoza' WHERE id_cuenta = 1;

-- Comprobar que solo el cambio de saldo fue registrado:
SELECT * FROM auditoria_saldos;


-- ------------------------------------------------------------------------------
-- 1.2 EVENTO DEMOSTRACIÓN: Resumen Periódico de Métricas del Banco
-- Tipo: RECURRING (Se ejecuta automáticamente cada 1 día)
-- Concepto: Consolida saldo y cuentas activas de manera desatendida.
-- ------------------------------------------------------------------------------

DELIMITER //

DROP EVENT IF EXISTS evt_registrar_metricas_diarias //

CREATE EVENT evt_registrar_metricas_diarias
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP
ON COMPLETION PRESERVE
COMMENT 'Consolida el saldo total y cantidad de cuentas activas diariamente'
DO
BEGIN
    INSERT INTO metricas_diarias (fecha_metrica, total_cuentas, saldo_total_sistema)
    SELECT 
        CURDATE(),
        COUNT(id_cuenta),
        IFNULL(SUM(saldo), 0.00)
    FROM cuentas
    WHERE estado = 'Activa';
END //

DELIMITER ;

-- PRUEBA DEL EVENTO Y REGISTRO DE MÉTRICAS:
-- (EVIDENCIA 03: evidencia_03_demo_evento_metricas_diarias.png)
-- Verificación del evento activo en el programador:
SHOW EVENTS FROM BancoDB;

-- Invocación manual del bloque de métricas para evidenciar el poblamiento:
INSERT INTO metricas_diarias (fecha_metrica, total_cuentas, saldo_total_sistema)
SELECT CURDATE(), COUNT(id_cuenta), IFNULL(SUM(saldo), 0.00)
FROM cuentas WHERE estado = 'Activa';

SELECT * FROM metricas_diarias;


-- ==============================================================================
-- PARTE 2: RETO AUTÓNOMO RESUELTO (EJERCICIOS PRÁCTICOS)
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- EJERCICIO 1 (TRIGGER): Validación Preventiva de Transferencias
-- Momento: BEFORE INSERT ON historial_transferencias
-- Reglas de Negocio Implementadas:
--   1. El monto a transferir debe ser estrictamente mayor que cero (> 0).
--   2. La cuenta_origen y la cuenta_destino NO pueden ser idénticas.
-- Si alguna regla se incumple, se cancela la operación con SIGNAL SQLSTATE '45000'.
-- ------------------------------------------------------------------------------

DELIMITER //

DROP TRIGGER IF EXISTS trg_validar_transferencia //

CREATE TRIGGER trg_validar_transferencia
BEFORE INSERT ON historial_transferencias
FOR EACH ROW
BEGIN
    -- Regla 1: Monto estrictamente positivo
    IF NEW.monto <= 0.00 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error de Negocio: El monto de la transferencia debe ser estrictamente mayor a cero.';
    END IF;

    -- Regla 2: Cuentas origen y destino diferentes
    IF NEW.cuenta_origen = NEW.cuenta_destino THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error de Negocio: La cuenta de origen y destino no pueden ser iguales.';
    END IF;
END //

DELIMITER ;


-- PRUEBAS EJERCICIO 1 (TRIGGER VALIDACIÓN):

-- Caso A: Inserción Válida (Monto > 0 y cuentas distintas)
-- (EVIDENCIA 04: evidencia_04_reto_trigger_insercion_valida.png)
INSERT INTO historial_transferencias (cuenta_origen, cuenta_destino, monto, estado_transferencia)
VALUES (1, 2, 300000.00, 'Exitosa');

SELECT * FROM historial_transferencias;

-- Caso B: Inserción Inválida por Monto <= 0 (Debe ser bloqueada con SIGNAL 45000)
-- (EVIDENCIA 05: evidencia_05_reto_trigger_error_monto.png)
-- Ejecutar y capturar el mensaje de error arrojado:
-- INSERT INTO historial_transferencias (cuenta_origen, cuenta_destino, monto, estado_transferencia)
-- VALUES (1, 2, -100.00, 'Exitosa');

-- Caso C: Inserción Inválida por Cuentas Iguales (Debe ser bloqueada con SIGNAL 45000)
-- (EVIDENCIA 06: evidencia_06_reto_trigger_error_mismas_cuentas.png)
-- Ejecutar y capturar el mensaje de error arrojado:
-- INSERT INTO historial_transferencias (cuenta_origen, cuenta_destino, monto, estado_transferencia)
-- VALUES (1, 1, 50000.00, 'Exitosa');


-- ------------------------------------------------------------------------------
-- EJERCICIO 2 (EVENTO): Inactivación Automática de Cuentas en Cero
-- Programación: EVERY 1 DAY
-- Tarea: Cambiar estado a 'Inactiva' para todas las cuentas con saldo = 0.00
--        que actualmente se encuentren en estado 'Activa'.
-- ------------------------------------------------------------------------------

DELIMITER //

DROP EVENT IF EXISTS evt_inactivar_cuentas_vacias //

CREATE EVENT evt_inactivar_cuentas_vacias
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP
ON COMPLETION PRESERVE
COMMENT 'Inactiva automáticamente las cuentas activas cuyo saldo sea 0.00'
DO
BEGIN
    UPDATE cuentas
    SET estado = 'Inactiva'
    WHERE saldo = 0.00 
      AND estado = 'Activa';
END //

DELIMITER ;


-- PRUEBA EJERCICIO 2 (EVENTO DE INACTIVACIÓN):
-- (EVIDENCIA 07: evidencia_07_reto_evento_inactivar_cuentas.png)
-- Visualizar el evento programado:
SHOW EVENTS FROM BancoDB LIKE 'evt_inactivar_cuentas_vacias';

-- Ejecutar la acción del evento para verificar la actualización de estados:
UPDATE cuentas
SET estado = 'Inactiva'
WHERE saldo = 0.00 
  AND estado = 'Activa';

-- Comprobación: Las cuentas 3 y 4 ahora están marcadas como 'Inactiva':
SELECT id_cuenta, titular, saldo, estado FROM cuentas;
