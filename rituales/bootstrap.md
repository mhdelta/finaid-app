# Ritual: bootstrap (Fase 0)

Objetivo: pasar de cero a un sistema en régimen — CSV maestro validado, diagnóstico hecho con código, y `finanzas_base.md` v1.0 redactado y validado por el usuario. Suele tomar 1–3 sesiones; no comprimirlo en una si los datos son complejos.

## 0. Contrato
Antes de empezar, confirmar con el usuario el contrato del README (exporta extractos mensualmente, ejecuta él los movimientos, no omite datos incómodos, lee y decide). Si no se compromete, no seguir.

## 1. Entrevista de inventario
Preguntar y anotar (esto alimenta §1–§3 del documento base):
- **Cuentas y productos**: todas las cuentas bancarias, tarjetas, billeteras y plataformas intermedias (nómina, Deel, PayPal, exchanges), con moneda y para qué se usa cada una. Decidir cuáles entran al CSV (perímetro) y cuáles quedan fuera y por qué.
- **Ingresos**: monto, canal, periodicidad, y qué tan confiable es cada fuente. Separar el **ingreso recurrente confiable** (base del plan) de los extras.
- **Deudas**: producto, saldo aproximado, tasa, historia (moras, refinanciaciones). Marcar todo lo no confirmado como "a verificar con extractos".
- **Compromisos fijos** ineludibles y **fiscalidad** (retenciones, trimestrales, autónomo/empleado).
- **Monedas** en las que se gana y se gasta.

## 2. Reunir extractos
Pedir al usuario **3–6 meses** de extractos de cada cuenta del perímetro, en `extractos/entrada/`. Preferir formatos de datos (CSV/XLS) sobre PDF cuando el banco los ofrezca. Menos de 3 meses → el diagnóstico de gasto no es representativo; decirlo y seguir con lo que haya, marcándolo.

## 3. Ingesta inicial
Seguir `rituales/ingesta.md`. En esta primera pasada, además:
- Crear `datos/notas_bancos.md` y documentar cada quirk de formato descubierto (decimales, fechas, categorías embebidas, secciones del extracto, duplicados PDF/XLS). Este archivo es un activo: todas las ingestas futuras lo consultan.
- Crear `datos/resumen_ingesta.md`: período cubierto por cada extracto, resultado de la validación de saldos, criterios de normalización aplicados, huecos conocidos.
- La validación de saldos es innegociable también aquí: una cuenta que no cuadra no entra al CSV hasta resolverse.

## 4. Diagnóstico (con código sobre el CSV)
- **Ingreso real** del período vs. lo declarado en la entrevista. Ojo al perímetro: abonos desde plataformas intermedias pueden ser el mismo ingreso moviéndose, no ingreso extra.
- **Gasto por categoría**: clasificar por keywords sobre `concepto` (reglas por banco → `notas_bancos.md`), promediando solo meses completos y representativos. Excluir transferencias internas. El efectivo retirado sin rastro es una categoría.
- **Deudas**: saldo real, costo mensual (interés + comisiones), y el mecanismo que las alimenta (¿qué gasto cae en la tarjeta y por qué?).
- **Flujo estructural**: ¿el período fue superavitario por sí mismo o lo sostuvo algo no repetible (venta de un activo, extra)? Decirlo sin suavizarlo.
- Presentar el diagnóstico al usuario y **dejarle corregir**: él sabe cosas que el CSV no (esa corrección se documenta, p. ej. el perímetro de ingresos).

## 5. Redactar `finanzas_base.md` v1.0
Copiar `plantillas/finanzas_base.template.md` a la raíz como `finanzas_base.md` y rellenarlo sección por sección **con el usuario validando cada una**. Las secciones que no apliquen se marcan "No aplica", no se borran.

## 6. Plan y reglas de ejecución
Con el diagnóstico validado, proponer el plan (§6): prioridad entre deuda y colchón, pago/ahorro mensual calculado solo con el ingreso recurrente, proyección mes a mes, reglas de ejecución (orden de pagos, provisiones, saldo mínimo, contingencia). El usuario decide; lo decidido queda escrito.

## 7. Cierre
- Verificar: extractos movidos a `procesados/`, backup del CSV hecho, `finanzas_base.md` v1.0 con changelog.
- Acordar la fecha de la primera revisión mensual (primera semana del mes siguiente).
- Sembrar el backlog (§8) con todo lo que quedó "a verificar".
