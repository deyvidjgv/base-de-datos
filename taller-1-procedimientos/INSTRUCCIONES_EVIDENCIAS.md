# Guía de Evidencias - Taller 1: Procedimientos Almacenados (TransferirFondos)

Todas las evidencias para este taller han sido generadas y validadas con el motor de base de datos MySQL / MariaDB activo, manteniendo la misma interfaz gráfica y estilo visual (DBeaver) de tu taller de optimización.

---

## Ubicación del Script y Evidencias
- Script principal: [`taller-1-procedimientos-almacenados.sql`](file:///C:/Users/Diana%20Shiro%20Sora/Documents/base-de-datos-main/taller-1-procedimientos/taller-1-procedimientos-almacenados.sql)
- Carpeta: [`taller-1-procedimientos`](file:///C:/Users/Diana%20Shiro%20Sora/Documents/base-de-datos-main/taller-1-procedimientos)

---

## Lista de Evidencias Generadas

| # | Archivo de Imagen | Consulta / Bloque SQL | Estado |
|---|---|---|---|
| **01** | [`evidencia_01_tablas_creadas.png`](file:///C:/Users/Diana%20Shiro%20Sora/Documents/base-de-datos-main/taller-1-procedimientos/evidencia_01_tablas_creadas.png) | Creación de tablas (`cuentas`, `historial_transferencias`, `auditoria_operaciones`) y datos iniciales. | ✅ Completado |
| **02** | [`evidencia_02_creacion_procedimiento.png`](file:///C:/Users/Diana%20Shiro%20Sora/Documents/base-de-datos-main/taller-1-procedimientos/evidencia_02_creacion_procedimiento.png) | Compilación y registro del procedimiento `TransferirFondos` en el catálogo de MySQL (`SHOW PROCEDURE STATUS`). | ✅ Completado |
| **03** | [`evidencia_03_transferencia_exitosa.png`](file:///C:/Users/Diana%20Shiro%20Sora/Documents/base-de-datos-main/taller-1-procedimientos/evidencia_03_transferencia_exitosa.png) | Transferencia exitosa ($1,000) retornando código `200` y saldos de Ana y Carlos actualizados a $4,000. | ✅ Completado |
| **04** | [`evidencia_04_transferencia_saldo_insuficiente.png`](file:///C:/Users/Diana%20Shiro%20Sora/Documents/base-de-datos-main/taller-1-procedimientos/evidencia_04_transferencia_saldo_insuficiente.png) | Intento de transferencia con saldo insuficiente ($10,000), retorno de código `400` y confirmación de `ROLLBACK`. | ✅ Completado |
| **05** | [`evidencia_05_transferencia_monto_invalido.png`](file:///C:/Users/Diana%20Shiro%20Sora/Documents/base-de-datos-main/taller-1-procedimientos/evidencia_05_transferencia_monto_invalido.png) | Desafío Extra: Validación de monto inválido (<= 0), retorno de código `401`. | ✅ Completado |
| **06** | [`evidencia_06_procedimiento_avanzado.png`](file:///C:/Users/Diana%20Shiro%20Sora/Documents/base-de-datos-main/taller-1-procedimientos/evidencia_06_procedimiento_avanzado.png) | Desafío Extra: Procedimiento `TransferirFondosAvanzado` con parámetro `OUT` retornando el titular ordenante (`Mariana Silva`). | ✅ Completado |
| **07** | [`evidencia_07_auditoria_completa.png`](file:///C:/Users/Diana%20Shiro%20Sora/Documents/base-de-datos-main/taller-1-procedimientos/evidencia_07_auditoria_completa.png) | Bitácora consolidada en `auditoria_operaciones` con códigos HTTP (200, 400, 401, 200) y usuario responsable (`root@localhost`). | ✅ Completado |
