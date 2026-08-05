# Ritual: ingesta de extractos nuevos

Procesa únicamente lo que esté en `extractos/entrada/`. Antes de empezar: leer `datos/notas_bancos.md` (quirks conocidos por banco) si existe.

## Pasos

### 1. INVENTARIO
Lista los archivos de `entrada/`; identifica banco/cuenta, moneda y período de cada uno. Reporta: meses faltantes dentro del rango, duplicados (mismo período en dos formatos), archivos ilegibles. **Verifica contra `procesados/` que ningún período ya esté ingestado** — si lo está, avisar y excluir (reprocesar = duplicar transacciones).

**Regla de duplicados entre formatos**: si un mismo período llega en formato de datos (XLS/CSV) y en PDF, el XLS/CSV es la fuente de las transacciones; el PDF solo para resúmenes de estado (paso 4). Prioridad general: XLS/CSV > PDF.

### 2. EXTRACCIÓN
Extrae todas las transacciones: fecha, concepto, importe, moneda, cuenta de origen.

Cuidados de formato (los específicos de cada banco viven en `notas_bancos.md` — consultarlo y **actualizarlo con cada quirk nuevo**):
- **Separadores decimales**: muchas monedas usan punto de miles y coma decimal (1.700.000,00 = un millón setecientos mil, NO 1,7). Ante montos sospechosamente pequeños para su moneda, revisar posible error de parsing.
- **Fechas**: identificar el formato de cada fuente (DD/MM vs MM/DD es el error silencioso clásico); normalizar a ISO `YYYY-MM-DD`. Si un archivo usa un formato inesperado, indicarlo en el resumen.
- **PDFs escaneados** (imagen): avisar antes de intentar OCR.
- **Clasificar `tipo`**: `gasto` | `ingreso` | `transferencia_interna` | `pago_deuda` | `comision`. Las transferencias entre cuentas propias del perímetro son `transferencia_interna` — detectarlas evita inflar gasto e ingreso.

### 3. VALIDACIÓN DE SALDOS (sanity check obligatorio)
Para cada extracto: saldo inicial + suma de movimientos = saldo final del extracto. Si no cuadra, reportar la diferencia y **NO integrar esa cuenta al CSV** hasta resolverlo. Este paso detecta errores de extracción; saltárselo corrompe el dataset en silencio.

### 4. ESTADO DE DEUDAS (si aplica)
De los extractos de tarjetas/créditos: saldo total, desglose de cuotas o capital pendiente, intereses del período, pago mínimo, comisiones. Actualizar `datos/estado_deudas.md`.

### 5. INTEGRACIÓN
- Backup: copiar `datos/transacciones_unificadas.csv` a `datos/backup/transacciones_unificadas_YYYYMMDD.csv`.
- Añadir las transacciones nuevas manteniendo el esquema existente (leer el header del CSV primero y respetarlo).
- Deduplicar contra lo existente (fecha + importe + concepto + cuenta).
- Reportar: nº de transacciones añadidas, rango de fechas, totales por cuenta y moneda.

### 6. CIERRE
- Mover los archivos procesados de `entrada/` a `procesados/YYYY-MM/`.
- Resumen final: qué entró, qué quedó pendiente, anomalías detectadas (candidatas al backlog del documento base).
