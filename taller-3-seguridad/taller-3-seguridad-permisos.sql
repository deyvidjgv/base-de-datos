-- ==============================================================================
-- TALLER 3: SEGURIDAD, CONTROL DE ACCESO (DCL) Y PREVENCIÓN DE SQL INJECTION
-- Dominio: Sistema Bancario (BancoBD)
-- Motor: MySQL 8.0+ / MariaDB
-- ==============================================================================
-- Objetivos de Aprendizaje:
--   1. Realizar higiene y hardening inicial del servidor eliminando cuentas anónimas.
--   2. Implementar el Principio de Menor Privilegio (PoLP) creando usuarios por roles.
--   3. Otorgar permisos granulares a nivel de base de datos, tabla y columnas específicas (GRANT).
--   4. Auditar privilegios asignados con SHOW GRANTS y revocar permisos con REVOKE.
--   5. Prevenir ataques de SQL Injection mediante Sentencias Preparadas (PREPARE, EXECUTE, DEALLOCATE).
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- PASO 0: PREPARACIÓN DEL ENTORNO (Ejecutado como usuario ROOT o Administrador)
-- ------------------------------------------------------------------------------
CREATE DATABASE IF NOT EXISTS BancoBD;
USE BancoBD;

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS historial_transferencias;
DROP TABLE IF EXISTS cuentas;
SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE cuentas (
    id_cuenta INT PRIMARY KEY AUTO_INCREMENT,
    titular VARCHAR(100) NOT NULL,
    saldo DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    estado VARCHAR(20) DEFAULT 'Activa'
);

CREATE TABLE historial_transferencias (
    id_transferencia INT AUTO_INCREMENT PRIMARY KEY,
    cuenta_origen INT NOT NULL,
    cuenta_destino INT NOT NULL,
    monto DECIMAL(10, 2) NOT NULL,
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (cuenta_origen) REFERENCES cuentas(id_cuenta),
    FOREIGN KEY (cuenta_destino) REFERENCES cuentas(id_cuenta)
);

-- Insertar datos iniciales de prueba
INSERT INTO cuentas (titular, saldo, estado) VALUES
('Carlos Mendoza', 2500000.00, 'Activa'),
('Ana Gómez',       850000.00, 'Activa'),
('Roberto Silva',   120000.00, 'Bloqueada');

INSERT INTO historial_transferencias (cuenta_origen, cuenta_destino, monto) VALUES
(1, 2, 150000.00),
(2, 1,  50000.00);


-- ==============================================================================
-- PASO 1 Y 2: HIGIENE DE SEGURIDAD Y CREACIÓN DE USUARIOS POR ROLES
-- ==============================================================================

-- Higiene: Eliminar usuarios anónimos o inseguros por defecto
DROP USER IF EXISTS ''@'localhost';
DROP USER IF EXISTS ''@'%';

-- Limpieza preventiva de los usuarios de prueba si ya existían
DROP USER IF EXISTS 'admin_banco'@'localhost';
DROP USER IF EXISTS 'cajero_app'@'localhost';
DROP USER IF EXISTS 'auditor_consulta'@'%';
DROP USER IF EXISTS 'app_backend'@'localhost';

-- 1. Rol Administrador: Acceso local para administración del sistema
CREATE USER 'admin_banco'@'localhost' IDENTIFIED BY 'AdminBank2026!#';

-- 2. Rol Cajero: Acceso restringido a nivel de terminal/sucursal
CREATE USER 'cajero_app'@'localhost' IDENTIFIED BY 'CajeroPass2026!';

-- 3. Rol Auditor: Acceso de solo lectura desde cualquier host remoto
CREATE USER 'auditor_consulta'@'%' IDENTIFIED BY 'AuditorPass2026!';

-- 4. Rol Backend App: Aplicación web/API que interactúa con la BD
CREATE USER 'app_backend'@'localhost' IDENTIFIED BY 'AppBackend2026!Sec';

-- Verificación de usuarios creados en el catálogo de MySQL
SELECT user, host, plugin 
FROM mysql.user 
WHERE user IN ('admin_banco', 'cajero_app', 'auditor_consulta', 'app_backend');


-- ==============================================================================
-- PASO 3: ASIGNACIÓN GRANULAR DE PRIVILEGIOS (GRANT - Principio de Menor Privilegio)
-- ==============================================================================

-- A) Administrador: Control total sobre la base de datos bancaria con delegación (WITH GRANT OPTION)
GRANT ALL PRIVILEGES ON BancoBD.* TO 'admin_banco'@'localhost' WITH GRANT OPTION;

-- B) Backend App: Operaciones CRUD necesarias (Lectura, Inserción y Modificación)
GRANT SELECT, INSERT, UPDATE ON BancoBD.* TO 'app_backend'@'localhost';

-- C) Cajero: Restricción granular estricta A NIVEL DE COLUMNA:
-- Solo puede consultar: id_cuenta, titular y saldo (no ve el estado ni logs internos).
-- Solo puede modificar: saldo (no puede modificar titulares ni id_cuenta).
GRANT SELECT (id_cuenta, titular, saldo), UPDATE (saldo) ON BancoBD.cuentas TO 'cajero_app'@'localhost';

-- D) Auditor: Privilegios de solo lectura (SELECT) sobre todas las tablas de BancoBD
GRANT SELECT ON BancoBD.* TO 'auditor_consulta'@'%';

-- Aplicar los privilegios en la memoria del motor
FLUSH PRIVILEGES;

-- (EVIDENCIA 02: evidencia_02_asignacion_privilegios.png)
-- Consulta para confirmar que los privilegios fueron registrados:
SELECT user, host, db, Select_priv, Insert_priv, Update_priv 
FROM mysql.db 
WHERE db = 'BancoBD';


-- ==============================================================================
-- PASO 4: VERIFICACIÓN Y REVOCACIÓN DE PRIVILEGIOS (SHOW GRANTS & REVOKE)
-- ==============================================================================

-- 4.1 Inspección detallada de privilegios otorgados:
-- (EVIDENCIA 03: evidencia_03_verificacion_grants.png)
SHOW GRANTS FOR 'admin_banco'@'localhost';
SHOW GRANTS FOR 'cajero_app'@'localhost';
SHOW GRANTS FOR 'app_backend'@'localhost';
SHOW GRANTS FOR 'auditor_consulta'@'%';

-- 4.2 Revocación: Por políticas del banco, se retira el permiso de actualización directa al cajero
REVOKE UPDATE ON BancoBD.cuentas FROM 'cajero_app'@'localhost';
FLUSH PRIVILEGES;

-- 4.3 Verificación de la revocación aplicada:
-- (EVIDENCIA 04: evidencia_04_revocacion_privilegios.png)
SHOW GRANTS FOR 'cajero_app'@'localhost';


-- ==============================================================================
-- PASO 5: PREVENCIÓN DE SQL INJECTION CON SENTENCIAS PREPARADAS (PREPARE)
-- ==============================================================================
-- Demostración de protección: Los parámetros son enviados por canales separados
-- impidiendo que texto malicioso (como ' OR '1'='1) sea interpretado como código SQL.
-- ==============================================================================

-- 5.1 Definición de la plantilla parametrizada con marcadores '?'
PREPARE stmt_buscar_cuenta FROM 
'SELECT id_cuenta, titular, saldo, estado FROM cuentas WHERE id_cuenta = ? AND estado = ?';

-- 5.2 Definición de variables de sesión
SET @id_busqueda = 1;
SET @estado_busqueda = 'Activa';

-- 5.3 Ejecución segura con parámetros enlazados:
-- (EVIDENCIA 05: evidencia_05_sentencias_preparadas_sql_injection.png)
EXECUTE stmt_buscar_cuenta USING @id_busqueda, @estado_busqueda;

-- 5.4 Prueba de inmunidad: Incluso si un parámetro contiene sintaxis SQL maliciosa,
-- se evalúa como valor literal de texto y no rompe la consulta:
SET @id_busqueda = 2;
SET @estado_busqueda = 'Activa\' OR \'1\'=\'1';
EXECUTE stmt_buscar_cuenta USING @id_busqueda, @estado_busqueda;

-- 5.5 Liberar los recursos de memoria asignados a la sentencia
DEALLOCATE PREPARE stmt_buscar_cuenta;
