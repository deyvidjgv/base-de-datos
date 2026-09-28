-- ==============================================================================
-- TALLER 2: FUNCIONES DEFINIDAS POR EL USUARIO (UDF) EN MYSQL
-- Dominio: Sistema Bancario ("BancoDB")
-- Motor: MySQL 8.0+ / MariaDB
-- ==============================================================================
-- Objetivos de Aprendizaje:
--   1. Crear funciones escalares con tipos de datos de retorno definidos.
--   2. Implementar características de ejecución: DETERMINISTIC y READS SQL DATA.
--   3. Manejar lógica condicional (IF-ELSEIF-ELSE) y control de flujo iterativo (WHILE).
--   4. Consultar datos de tablas dentro de funciones para alimentar reglas de negocio.
--   5. Invocar funciones dentro de expresiones DML (SELECT, WHERE, proyecciones masivas).
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- PARTE 0: PREPARACIÓN DEL ENTORNO Y TABLAS DE SOPORTE
-- ------------------------------------------------------------------------------
CREATE DATABASE IF NOT EXISTS BancoDB;
USE BancoDB;

-- Configurar modo seguro para permitir funciones en MySQL si binary logging está activo
SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS auditoria_operaciones;
DROP TABLE IF EXISTS historial_transferencias;
DROP TABLE IF EXISTS auditoria_saldos;
DROP TABLE IF EXISTS metricas_diarias;
DROP TABLE IF EXISTS Transacciones;
DROP TABLE IF EXISTS Cuentas;
DROP TABLE IF EXISTS cuentas;
SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE Cuentas (
    cuenta_id INT PRIMARY KEY AUTO_INCREMENT,
    titular VARCHAR(100) NOT NULL,
    tipo_cuenta VARCHAR(20) NOT NULL DEFAULT 'Ahorros',
    saldo DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    estado VARCHAR(20) NOT NULL DEFAULT 'Activa'
);

CREATE TABLE Transacciones (
    id_transaccion INT PRIMARY KEY AUTO_INCREMENT,
    cuenta_id INT NOT NULL,
    tipo_transaccion VARCHAR(20) NOT NULL, -- 'Deposito', 'Retiro', 'Transferencia'
    monto DECIMAL(12,2) NOT NULL,
    fecha DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (cuenta_id) REFERENCES Cuentas(cuenta_id)
);

-- Insertar cuentas para evaluar los distintos escenarios del taller:
INSERT INTO Cuentas (cuenta_id, titular, tipo_cuenta, saldo, estado) VALUES
(1, 'Carlos Mendoza',  'Ahorros',   3500000.00, 'Activa'),    -- Escenario Aprobado
(2, 'Ana Gómez',       'Corriente', 1200000.00, 'Activa'),    -- Escenario Requiere Aval
(3, 'Roberto Silva',   'Ahorros',    300000.00, 'Activa'),    -- Escenario Rechazado (saldo bajo)
(4, 'Laura Restrepo',  'Corriente', 4000000.00, 'Activa');    -- Escenario con retiros altos

-- Insertar transacciones de prueba con fechas en rangos específicos:
INSERT INTO Transacciones (cuenta_id, tipo_transaccion, monto, fecha) VALUES
-- Transacciones de Carlos (cuenta 1):
(1, 'Deposito', 2000000.00, '2026-01-10 10:00:00'),
(1, 'Retiro',    400000.00, '2026-01-15 14:30:00'),
(1, 'Retiro',    350000.00, '2026-01-20 09:15:00'),
(1, 'Retiro',    250000.00, '2026-02-05 16:00:00'),
-- Transacciones de Ana (cuenta 2):
(2, 'Deposito', 1500000.00, '2026-01-12 11:00:00'),
(2, 'Retiro',    300000.00, '2026-01-18 12:45:00'),
-- Transacciones de Laura (cuenta 4 - retiros altos para pruebas de score):
(4, 'Retiro',   5000000.00, '2026-01-25 10:00:00'),
(4, 'Retiro',   4500000.00, '2026-02-01 15:30:00');

-- Verificación de tablas preparadas
-- (EVIDENCIA 01: evidencia_01_preparacion_datos.png)
SELECT * FROM Cuentas;
SELECT * FROM Transacciones;


-- ==============================================================================
-- EJERCICIO 1: CÁLCULO DEL GRAVAMEN A LOS MOVIMIENTOS FINANCIEROS (4x1000 - GMF)
-- ==============================================================================
-- Característica técnica: DETERMINISTIC
-- Justificación: Para el mismo monto de entrada y condición de exención, el resultado 
-- matemático es idéntico y no realiza lectura de tablas en disco.
-- ==============================================================================

DROP FUNCTION IF EXISTS CalcularImpuestoGMF;

DELIMITER //

CREATE FUNCTION CalcularImpuestoGMF(
    p_monto DECIMAL(12,2),
    p_es_exenta BOOLEAN
)
RETURNS DECIMAL(12,2)
DETERMINISTIC
BEGIN
    DECLARE v_impuesto DECIMAL(12,2);
    
    -- Si la cuenta está marcada como exenta de 4x1000, el impuesto es cero
    IF p_es_exenta THEN
        SET v_impuesto = 0.00;
    ELSE
        -- 4 por mil equivale a multiplicar por 0.004
        SET v_impuesto = ROUND(p_monto * 0.004, 2);
    END IF;
    
    RETURN v_impuesto;
END //

DELIMITER ;

-- PRUEBAS EJERCICIO 1:
-- (EVIDENCIA 02: evidencia_02_funcion_gmf.png)
SELECT 
    1000000.00 AS Monto_Evaluado,
    CalcularImpuestoGMF(1000000.00, FALSE) AS Impuesto_No_Exenta,
    CalcularImpuestoGMF(1000000.00, TRUE)  AS Impuesto_Exenta;

SELECT 
    5500000.00 AS Monto_Evaluado,
    CalcularImpuestoGMF(5500000.00, FALSE) AS Impuesto_Calculado;


-- ==============================================================================
-- EJERCICIO 2: TOTAL HISTÓRICO DE RETIROS EN UN RANGO DE FECHAS
-- ==============================================================================
-- Característica técnica: READS SQL DATA
-- Justificación: La función ejecuta una consulta DML (SELECT SUM(...)) sobre la
-- tabla Transacciones para acumular los débitos ocurridos en el intervalo.
-- ==============================================================================

DROP FUNCTION IF EXISTS ObtenerTotalRetirosPeriodo;

DELIMITER //

CREATE FUNCTION ObtenerTotalRetirosPeriodo(
    p_cuenta_id INT,
    p_fecha_inicio DATE,
    p_fecha_fin DATE
)
RETURNS DECIMAL(12,2)
READS SQL DATA
BEGIN
    DECLARE v_total_retiros DECIMAL(12,2);
    
    -- Sumar exclusivamente transacciones de tipo 'Retiro' dentro de la ventana de fechas
    SELECT IFNULL(SUM(monto), 0.00)
    INTO v_total_retiros
    FROM Transacciones
    WHERE cuenta_id = p_cuenta_id
      AND tipo_transaccion = 'Retiro'
      AND DATE(fecha) BETWEEN p_fecha_inicio AND p_fecha_fin;
      
    RETURN v_total_retiros;
END //

DELIMITER ;

-- PRUEBAS EJERCICIO 2:
-- (EVIDENCIA 03: evidencia_03_total_retiros_periodo.png)
-- Consulta para Carlos (cuenta 1) en enero 2026:
SELECT 
    c.cuenta_id,
    c.titular,
    '2026-01-01' AS Fecha_Inicio,
    '2026-01-31' AS Fecha_Fin,
    ObtenerTotalRetirosPeriodo(c.cuenta_id, '2026-01-01', '2026-01-31') AS Total_Retirado_Enero
FROM Cuentas c
WHERE c.cuenta_id = 1;

-- Comparación de retiros entre todas las cuentas en enero:
SELECT 
    c.cuenta_id,
    c.titular,
    ObtenerTotalRetirosPeriodo(c.cuenta_id, '2026-01-01', '2026-01-31') AS Retiros_Enero
FROM Cuentas c;


-- ==============================================================================
-- EJERCICIO 3: PROYECCIÓN DE RENDIMIENTO FINANCIERO (CDT CON CICLO WHILE)
-- ==============================================================================
-- Característica técnica: DETERMINISTIC
-- Justificación: Implementa el cálculo de interés compuesto año a año usando una 
-- estructura de control iterativa pura (bucle WHILE), sin consultar datos en tablas.
-- Fórmula iterativa: Capital = Capital * (1 + Tasa / 100)
-- ==============================================================================

DROP FUNCTION IF EXISTS ProyectarRendimientoCDT;

DELIMITER //

CREATE FUNCTION ProyectarRendimientoCDT(
    p_capital DECIMAL(12,2),
    p_tasa_anual DECIMAL(5,2),
    p_anios INT
)
RETURNS DECIMAL(12,2)
DETERMINISTIC
BEGIN
    DECLARE v_capital_acumulado DECIMAL(12,2);
    DECLARE v_contador INT DEFAULT 1;
    
    -- Inicializar con el capital base depositado
    SET v_capital_acumulado = p_capital;
    
    -- Iterar por cada año aplicando la tasa anual compuesta
    WHILE v_contador <= p_anios DO
        SET v_capital_acumulado = v_capital_acumulado * (1 + (p_tasa_anual / 100.0));
        SET v_contador = v_contador + 1;
    END WHILE;
    
    RETURN ROUND(v_capital_acumulado, 2);
END //

DELIMITER ;

-- PRUEBAS EJERCICIO 3:
-- (EVIDENCIA 04: evidencia_04_rendimiento_cdt.png)
-- Simulación de CDT de $10,000,000 al 10.50% E.A. a 1, 2, 3 y 5 años:
SELECT 
    10000000.00 AS Capital_Inicial,
    10.50 AS Tasa_Anual_Pct,
    ProyectarRendimientoCDT(10000000.00, 10.50, 1) AS Proyeccion_1_Anio,
    ProyectarRendimientoCDT(10000000.00, 10.50, 2) AS Proyeccion_2_Anios,
    ProyectarRendimientoCDT(10000000.00, 10.50, 3) AS Proyeccion_3_Anios,
    ProyectarRendimientoCDT(10000000.00, 10.50, 5) AS Proyeccion_5_Anios;


-- ==============================================================================
-- EJERCICIO 4: EVALUACIÓN DE SCORE CREDITICIO (RETO INTEGRADOR)
-- ==============================================================================
-- Característica técnica: READS SQL DATA
-- Reglas de Negocio del Sistema Bancario:
--   - 'Cuenta Inexistente' : Si el ID suministrado no existe en la tabla Cuentas.
--   - 'Aprobado'           : Saldo >= $2,000,000 Y total histórico de retiros <= (Saldo * 2).
--   - 'Requiere Aval'      : Saldo entre $500,000 y $1,999,999.
--   - 'Rechazado'          : Saldo < $500,000 O retiros superan el doble del saldo.
-- ==============================================================================

DROP FUNCTION IF EXISTS EvaluarElegibilidadCredito;

DELIMITER //

CREATE FUNCTION EvaluarElegibilidadCredito(
    p_cuenta_id INT
)
RETURNS VARCHAR(30)
READS SQL DATA
BEGIN
    DECLARE v_saldo DECIMAL(12,2);
    DECLARE v_total_retiros DECIMAL(12,2);
    DECLARE v_resultado VARCHAR(30);
    
    -- Consultar saldo actual de la cuenta
    SELECT saldo INTO v_saldo
    FROM Cuentas
    WHERE cuenta_id = p_cuenta_id;
    
    -- Si la cuenta no existe en el sistema bancario
    IF v_saldo IS NULL THEN
        RETURN 'Cuenta Inexistente';
    END IF;
    
    -- Consultar la sumatoria histórica de retiros
    SELECT IFNULL(SUM(monto), 0.00)
    INTO v_total_retiros
    FROM Transacciones
    WHERE cuenta_id = p_cuenta_id 
      AND tipo_transaccion = 'Retiro';
      
    -- Aplicación rigurosa de las reglas de crédito
    IF v_saldo >= 2000000.00 AND v_total_retiros <= (v_saldo * 2) THEN
        SET v_resultado = 'Aprobado';
    ELSEIF v_saldo >= 500000.00 AND v_saldo < 2000000.00 THEN
        SET v_resultado = 'Requiere Aval';
    ELSE
        SET v_resultado = 'Rechazado';
    END IF;
    
    RETURN v_resultado;
END //

DELIMITER ;

-- PRUEBAS EJERCICIO 4:
-- (EVIDENCIA 05: evidencia_05_elegibilidad_credito.png)
-- Consulta DML integrada evaluando a todos los clientes del banco:
SELECT 
    c.cuenta_id,
    c.titular,
    c.saldo,
    IFNULL((SELECT SUM(monto) FROM Transacciones t WHERE t.cuenta_id = c.cuenta_id AND t.tipo_transaccion = 'Retiro'), 0.00) AS Total_Retiros_Historicos,
    EvaluarElegibilidadCredito(c.cuenta_id) AS Estado_Credito
FROM Cuentas c;

-- Prueba de robustez con cuenta no existente:
SELECT EvaluarElegibilidadCredito(999) AS Prueba_Cuenta_Inexistente;
