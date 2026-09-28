-- ==============================================================================
-- TALLER: OPTIMIZACIÓN DE CONSULTAS Y RENDIMIENTO EN MYSQL (BancoDB)
-- ==============================================================================

CREATE DATABASE IF NOT EXISTS BancoDB;
USE BancoDB;

-- ------------------------------------------------------------------------------
-- PARTE 0: ESTRUCTURA DE TABLAS Y POBLAMIENTO DE DATOS MASIVOS
-- ------------------------------------------------------------------------------

DROP TABLE IF EXISTS historial_transferencias;
DROP TABLE IF EXISTS cuentas;

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
    monto DECIMAL(12, 2) NOT NULL,
    estado_transferencia VARCHAR(20) NOT NULL DEFAULT 'Exitosa',
    fecha DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (cuenta_origen) REFERENCES cuentas(id_cuenta),
    FOREIGN KEY (cuenta_destino) REFERENCES cuentas(id_cuenta)
);

DELIMITER //
CREATE PROCEDURE CargarDatosPrueba()
BEGIN
    DECLARE i INT DEFAULT 1;
    
    WHILE i <= 1000 DO
        INSERT INTO cuentas (titular, tipo_cuenta, saldo, estado, fecha_apertura)
        VALUES (
            CONCAT('Cliente_', i),
            IF(i % 2 = 0, 'Ahorros', 'Corriente'),
            ROUND(RAND() * 10000000, 2),
            IF(i % 10 = 0, 'Bloqueada', 'Activa'),
            DATE_SUB(NOW(), INTERVAL FLOOR(RAND() * 365) DAY)
        );
        SET i = i + 1;
    END WHILE;

    SET i = 1;
    WHILE i <= 10000 DO
        INSERT INTO historial_transferencias (cuenta_origen, cuenta_destino, monto, estado_transferencia, fecha)
        VALUES (
            FLOOR(1 + RAND() * 999),
            FLOOR(1 + RAND() * 999),
            ROUND(1000 + RAND() * 500000, 2),
            IF(i % 15 = 0, 'Fallida', 'Exitosa'),
            DATE_SUB(NOW(), INTERVAL FLOOR(RAND() * 180) DAY)
        );
        SET i = i + 1;
    END WHILE;
END //
DELIMITER ;

CALL CargarDatosPrueba();
DROP PROCEDURE IF EXISTS CargarDatosPrueba;

-- Verificación de carga (EVIDENCIA 00: evidencia_00_poblacion_datos.png)
SELECT COUNT(*) AS total_cuentas FROM cuentas;
SELECT COUNT(*) AS total_transferencias FROM historial_transferencias;


-- ==============================================================================
-- PARTE 1: DEMOSTRACIÓN GUIADA EN CLASE
-- ==============================================================================

-- 1.1 Ineficiente: Búsqueda sin índice secundario (EVIDENCIA 01: evidencia_01_demo_table_scan.png)
EXPLAIN ANALYZE
SELECT id_transferencia, cuenta_origen, monto, fecha
FROM historial_transferencias
WHERE estado_transferencia = 'Exitosa'
  AND fecha >= '2026-01-01 00:00:00';

-- 1.2 Creación de índice compuesto
CREATE INDEX idx_transf_estado_fecha ON historial_transferencias(estado_transferencia, fecha);

-- 1.3 Optimizado: Re-evaluación con índice compuesto (EVIDENCIA 02: evidencia_02_demo_con_indice.png)
EXPLAIN ANALYZE
SELECT id_transferencia, cuenta_origen, monto, fecha
FROM historial_transferencias
WHERE estado_transferencia = 'Exitosa'
  AND fecha >= '2026-01-01 00:00:00';


-- ==============================================================================
-- PARTE 2: EJERCICIOS PRÁCTICOS
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- EJERCICIO 1: Diagnóstico de "Non-Sargable Query" (Uso de Funciones en WHERE)
-- ------------------------------------------------------------------------------

-- 1.1 Ineficiente: DATE() sobre columna fecha (EVIDENCIA 03: evidencia_03_ejercicio1_ineficiente.png)
EXPLAIN ANALYZE
SELECT * 
FROM historial_transferencias 
WHERE DATE(fecha) = '2026-02-15';

-- 1.2 Índice directo para la columna fecha
CREATE INDEX idx_transf_fecha ON historial_transferencias(fecha);

-- 1.3 Optimizado: Rango sargable sin funciones (EVIDENCIA 04: evidencia_04_ejercicio1_sargable.png)
EXPLAIN ANALYZE
SELECT * 
FROM historial_transferencias 
WHERE fecha >= '2026-02-15 00:00:00' 
  AND fecha <  '2026-02-16 00:00:00';


-- ------------------------------------------------------------------------------
-- EJERCICIO 2: Optimización mediante Índices Cubrientes (Covering Index)
-- ------------------------------------------------------------------------------

-- 2.1 Ineficiente: Table scan en cuentas (EVIDENCIA 05: evidencia_05_ejercicio2_ineficiente.png)
EXPLAIN ANALYZE
SELECT titular, saldo, tipo_cuenta
FROM cuentas
WHERE estado = 'Activa';

-- 2.2 Creación de Covering Index (Filtro en WHERE + Columnas proyectadas en SELECT)
CREATE INDEX idx_cuentas_estado_cubriente ON cuentas(estado, titular, saldo, tipo_cuenta);

-- 2.3 Optimizado: Consulta resuelta enteramente por índice (EVIDENCIA 06: evidencia_06_ejercicio2_covering_index.png)
EXPLAIN ANALYZE
SELECT titular, saldo, tipo_cuenta
FROM cuentas
WHERE estado = 'Activa';


-- ------------------------------------------------------------------------------
-- EJERCICIO 3: Optimización de Filtros Combinados y JOINs
-- ------------------------------------------------------------------------------

-- 3.1 Ineficiente: JOIN con Table scan en transferencias (EVIDENCIA 07: evidencia_07_ejercicio3_ineficiente.png)
EXPLAIN ANALYZE
SELECT c.id_cuenta, c.titular, ht.id_transferencia, ht.monto, ht.fecha
FROM cuentas c
JOIN historial_transferencias ht ON c.id_cuenta = ht.cuenta_origen
WHERE c.estado = 'Activa'
  AND ht.monto > 300000.00;

-- 3.2 Índices para acelerar el filtrado y el cruce del JOIN
CREATE INDEX idx_cuentas_estado ON cuentas(estado);
CREATE INDEX idx_transf_origen_monto ON historial_transferencias(cuenta_origen, monto);

-- 3.3 Optimizado: Cruce indexado por origen y rango de monto (EVIDENCIA 08: evidencia_08_ejercicio3_optimizado.png)
EXPLAIN ANALYZE
SELECT c.id_cuenta, c.titular, ht.id_transferencia, ht.monto, ht.fecha
FROM cuentas c
JOIN historial_transferencias ht ON c.id_cuenta = ht.cuenta_origen
WHERE c.estado = 'Activa'
  AND ht.monto > 300000.00;

