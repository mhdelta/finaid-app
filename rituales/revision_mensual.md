# Ritual: revisión mensual

Primera semana de cada mes. Prerequisito: la ingesta del mes anterior ya hecha (`rituales/ingesta.md`). Todos los pasos usan el documento base (`finanzas_base.md`) como referencia; los cálculos, código sobre el CSV.

## Pasos

1. **Tasas del día** (si hay más de una moneda): buscar en internet los cruces relevantes del día y anotarlos en la salida. Todos los cálculos del mes las usan.

2. **Deuda vs. plan (§6 del documento base)** (si aplica):
   - Pedir al usuario el saldo actual desde la app (o tomarlo del extracto).
   - Comparar contra la proyección. Desviación > 5% → investigar (¿pago no aplicado como se esperaba? ¿intereses distintos? ¿tasa de cambio?).
   - Confirmar con el usuario que el pago del mes se hizo según las reglas de ejecución. No asumirlo.

3. **Gasto real vs. objetivo (§4)**: con código sobre el CSV, gasto del mes por categoría contra la columna objetivo. Identificar las **3 desviaciones principales**.

4. **Provisiones** (si aplica: impuestos trimestrales, pagos anuales): verificar que la provisión del mes se apartó según las reglas de ejecución. Acumulado vs. lo que exige el próximo vencimiento.

5. **Indicadores de riesgo (§5)**: revisar los indicadores definidos en el documento base (p. ej. tipo de cambio) contra sus umbrales. Umbral superado de forma sostenida → proponer ajuste del plan, no del colchón.

6. **Colchón**: total líquido actual vs. mínimo intocable de la fase. Si bajó del mínimo, es la primera desviación a tratar.

7. **Backlog (§8)**: repasar pendientes; marcar resueltos (con fecha y resultado), añadir nuevos.

## Salida
- Crear `revisiones/YYYY-MM_revision.md` con: tasas usadas (si aplica), deuda real vs. plan, las 3 desviaciones principales, **la decisión/ajuste del mes**, backlog actualizado.
- Actualizar `finanzas_base.md`: nueva versión (v1.1, v1.2…), cambios anotados en el changelog, foto patrimonial (§2) con tasas del día si hubo movimientos relevantes.
- El usuario ejecuta los movimientos acordados; el agente no asume nada como hecho.
