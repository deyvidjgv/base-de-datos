# Guía de Evidencias - Taller 5: Triggers y Eventos en MySQL

Todas las evidencias para este taller han sido generadas y validadas con el motor de base de datos MySQL / MariaDB activo, manteniendo la misma interfaz gráfica y estilo visual (DBeaver) de tu taller de optimización.

---

## Ubicación del Script y Evidencias
- Script principal: [`taller-5-triggers-eventos.sql`](file:///C:/Users/Diana%20Shiro%20Sora/Documents/base-de-datos-main/taller-5-triggers-eventos/taller-5-triggers-eventos.sql)
- Carpeta: [`taller-5-triggers-eventos`](file:///C:/Users/Diana%20Shiro%20Sora/Documents/base-de-datos-main/taller-5-triggers-eventos)

---

## Lista de Evidencias Generadas

| # | Archivo de Imagen | Consulta / Bloque SQL | Estado |
|---|---|---|---|
| **01** | [`evidencia_01_tablas_auditoria_y_event_scheduler.png`](file:///C:/Users/Diana%20Shiro%20Sora/Documents/base-de-datos-main/taller-5-triggers-eventos/evidencia_01_tablas_auditoria_y_event_scheduler.png) | Activación de `event_scheduler = ON`, creación de tablas base y tablas de auditoría/métricas. | ✅ Completado |
| **02** | [`evidencia_02_demo_trigger_auditoria_saldos.png`](file:///C:/Users/Diana%20Shiro%20Sora/Documents/base-de-datos-main/taller-5-triggers-eventos/evidencia_02_demo_trigger_auditoria_saldos.png) | Trigger demostración `trg_auditar_cambio_saldo` registrando automáticamente en `auditoria_saldos` tras un cambio de balance. | ✅ Completado |
| **03** | [`evidencia_03_demo_evento_metricas_diarias.png`](file:///C:/Users/Diana%20Shiro%20Sora/Documents/base-de-datos-main/taller-5-triggers-eventos/evidencia_03_demo_evento_metricas_diarias.png) | Evento demostración `evt_registrar_metricas_diarias` en el programador (`SHOW EVENTS`) y datos consolidados en `metricas_diarias`. | ✅ Completado |
| **04** | [`evidencia_04_reto_trigger_insercion_valida.png`](file:///C:/Users/Diana%20Shiro%20Sora/Documents/base-de-datos-main/taller-5-triggers-eventos/evidencia_04_reto_trigger_insercion_valida.png) | Reto Ejercicio 1: Inserción válida en `historial_transferencias` permitida por el trigger `trg_validar_transferencia`. | ✅ Completado |
| **05** | [`evidencia_05_reto_trigger_error_monto.png`](file:///C:/Users/Diana%20Shiro%20Sora/Documents/base-de-datos-main/taller-5-triggers-eventos/evidencia_05_reto_trigger_error_monto.png) | Reto Ejercicio 1: Intento de insertar monto <= 0 cancelado por el trigger con `SIGNAL SQLSTATE '45000'`. | ✅ Completado |
| **06** | [`evidencia_06_reto_trigger_error_mismas_cuentas.png`](file:///C:/Users/Diana%20Shiro%20Sora/Documents/base-de-datos-main/taller-5-triggers-eventos/evidencia_06_reto_trigger_error_mismas_cuentas.png) | Reto Ejercicio 1: Intento de transferir a la misma cuenta cancelado por el trigger con `SIGNAL SQLSTATE '45000'`. | ✅ Completado |
| **07** | [`evidencia_07_reto_evento_inactivar_cuentas.png`](file:///C:/Users/Diana%20Shiro%20Sora/Documents/base-de-datos-main/taller-5-triggers-eventos/evidencia_07_reto_evento_inactivar_cuentas.png) | Reto Ejercicio 2: Evento `evt_inactivar_cuentas_vacias` marcando como `'Inactiva'` las cuentas con saldo en cero. | ✅ Completado |
