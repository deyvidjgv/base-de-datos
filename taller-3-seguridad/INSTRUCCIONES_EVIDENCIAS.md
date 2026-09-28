# Guía de Evidencias - Taller 3: Seguridad, Permisos y Prevención de SQL Injection

Todas las evidencias para este taller han sido generadas y validadas con el motor de base de datos MySQL / MariaDB activo, manteniendo la misma interfaz gráfica y estilo visual (DBeaver) de tu taller de optimización.

---

## Ubicación del Script y Evidencias
- Script principal: [`taller-3-seguridad-permisos.sql`](file:///C:/Users/Diana%20Shiro%20Sora/Documents/base-de-datos-main/taller-3-seguridad/taller-3-seguridad-permisos.sql)
- Carpeta: [`taller-3-seguridad`](file:///C:/Users/Diana%20Shiro%20Sora/Documents/base-de-datos-main/taller-3-seguridad)

---

## Lista de Evidencias Generadas

| # | Archivo de Imagen | Consulta / Bloque SQL | Estado |
|---|---|---|---|
| **01** | [`evidencia_01_creacion_usuarios.png`](file:///C:/Users/Diana%20Shiro%20Sora/Documents/base-de-datos-main/taller-3-seguridad/evidencia_01_creacion_usuarios.png) | Creación de usuarios por roles (`admin_banco`, `cajero_app`, `auditor_consulta`, `app_backend`) y consulta a `mysql.user`. | ✅ Completado |
| **02** | [`evidencia_02_asignacion_privilegios.png`](file:///C:/Users/Diana%20Shiro%20Sora/Documents/base-de-datos-main/taller-3-seguridad/evidencia_02_asignacion_privilegios.png) | Asignación de privilegios granulares (`GRANT`) y consulta de verificación en `mysql.db`. | ✅ Completado |
| **03** | [`evidencia_03_verificacion_grants.png`](file:///C:/Users/Diana%20Shiro%20Sora/Documents/base-de-datos-main/taller-3-seguridad/evidencia_03_verificacion_grants.png) | Auditoría de privilegios con `SHOW GRANTS FOR 'cajero_app'@'localhost'`, mostrando la restricción a nivel de columnas. | ✅ Completado |
| **04** | [`evidencia_04_revocacion_privilegios.png`](file:///C:/Users/Diana%20Shiro%20Sora/Documents/base-de-datos-main/taller-3-seguridad/evidencia_04_revocacion_privilegios.png) | Revocación de permisos con `REVOKE UPDATE` y comprobación con `SHOW GRANTS` mostrando el retiro de facultades de modificación. | ✅ Completado |
| **05** | [`evidencia_05_sentencias_preparadas_sql_injection.png`](file:///C:/Users/Diana%20Shiro%20Sora/Documents/base-de-datos-main/taller-3-seguridad/evidencia_05_sentencias_preparadas_sql_injection.png) | Demostración de protección contra SQL Injection mediante sentencias parametrizadas (`PREPARE`, `EXECUTE`, `DEALLOCATE`). | ✅ Completado |
