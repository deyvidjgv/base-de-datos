# Guía de Evidencias - Taller 4: Optimización de Consultas y Rendimiento (BancoDB)

Este taller ya se encuentra resuelto con su script y evidencias fotográficas correspondientes.

---

## Ubicación del Script y Evidencias
- Script principal: [`Script-13.sql`](file:///C:/Users/Diana%20Shiro%20Sora/Documents/base-de-datos-main/taller-optimizacion/Script-13.sql)

---

## Lista de Evidencias Disponibles

| # | Archivo de Imagen | Consulta / Bloque SQL | Estado |
|---|---|---|---|
| **00** | [`evidencia_00_poblacion_datos.png`](file:///C:/Users/Diana%20Shiro%20Sora/Documents/base-de-datos-main/taller-optimizacion/evidencia_00_poblacion_datos.png) | Conteo masivo de cuentas (1,000) y transferencias (10,000). | ✅ Completado |
| **01** | [`evidencia_01_demo_table_scan.png`](file:///C:/Users/Diana%20Shiro%20Sora/Documents/base-de-datos-main/taller-optimizacion/evidencia_01_demo_table_scan.png) | `EXPLAIN ANALYZE` demostrando Table Scan en transferencias. | ✅ Completado |
| **03** | [`evidencia_03_ejercicio1_ineficiente.png`](file:///C:/Users/Diana%20Shiro%20Sora/Documents/base-de-datos-main/taller-optimizacion/evidencia_03_ejercicio1_ineficiente.png) | `EXPLAIN ANALYZE` consulta no sargable con función `DATE(fecha)`. | ✅ Completado |
| **04** | [`evidencia_04_ejercicio1_sargable.png`](file:///C:/Users/Diana%20Shiro%20Sora/Documents/base-de-datos-main/taller-optimizacion/evidencia_04_ejercicio1_sargable.png) | `EXPLAIN ANALYZE` consulta sargable con rango de fechas e índice. | ✅ Completado |
| **05** | [`evidencia_05_ejercicio2_ineficiente.png`](file:///C:/Users/Diana%20Shiro%20Sora/Documents/base-de-datos-main/taller-optimizacion/evidencia_05_ejercicio2_ineficiente.png) | `EXPLAIN ANALYZE` Table Scan previo a índice cubriente. | ✅ Completado |
