# Finanzas personales — Documento base

**Versión: v1.0 (FECHA)** · Actualizar tras cada revisión mensual.

Este documento es la fuente de verdad del proyecto financiero. Cualquier agente que trabaje en este proyecto debe leerlo completo antes de actuar. Los datos transaccionales viven en `datos/transacciones_unificadas.csv`.

> **Cómo usar esta plantilla**: copia este archivo a la raíz como `finanzas_base.md` y rellénalo durante la Fase 0 (`rituales/bootstrap.md`). Los bloques `> Guía:` explican qué va en cada sección — bórralos al rellenar. Las secciones que no apliquen (p. ej. §3 si no hay deuda) se dejan con una línea: "No aplica — (motivo)". No borres secciones: que no aplique hoy es información.

---

## 1. Contexto de la persona

> Guía: situación laboral y fiscal, país(es), **ingreso recurrente confiable** (monto, moneda, canal, periodicidad) — este número es la base del plan; los extras nunca lo son. Compromisos fijos ineludibles (familia, pensiones). Monedas en las que se gasta. Si el dinero pasa por plataformas intermedias (nómina, Deel, PayPal…), definir aquí el **perímetro de ingresos**: qué abonos del CSV son ingreso real y cuáles son movimientos del mismo dinero.

- Ingreso recurrente confiable: **[monto] [moneda]/mes** vía [canal].
- Compromisos fijos: …
- Fiscalidad: …
- Regla de tasas (si hay más de una moneda): todo cálculo usa el tipo de cambio del día, buscado en el momento del análisis. Tasas usadas en esta versión: …

## 2. Foto patrimonial (FECHA, tasas del día: …)

> Guía: tabla de saldos por cuenta (convertidos a la moneda principal con tasas del día), total líquido, deudas, patrimonio neto. Se actualiza en cada revisión con movimientos relevantes. Marcar "a verificar" lo no confirmado en app/extracto.

| Concepto | Valor |
|---|---|
| [Cuenta 1] | … |
| **Total líquido** | … |
| [Deuda 1] | … |
| **Patrimonio neto** | … |

## 3. Deudas — hechos clave

> Guía: por cada deuda: producto, saldo, tasa real (mensual y E.A.), comisiones, condiciones de prepago, historia (moras, refinanciaciones) y las **reglas propias** que salgan del diagnóstico (p. ej. "este producto no se usa mientras X"). Si no hay deuda: "No aplica" y pasar el foco al colchón (§5).

## 4. Presupuesto — real vs. objetivo ([moneda]/mes)

> Guía: tabla por categoría con dos columnas: **Real** (promedio medido en el CSV sobre meses completos y representativos) y **Objetivo** (vigente desde la versión actual). Notas por línea. Cuidados aprendidos: (a) para líneas fijas usar el importe del recibo, no la media del dataset — promediar sobre meses donde no se cobró subestima; (b) excluir transferencias internas; (c) el efectivo sin rastro es una categoría, no un residuo. Cerrar con: ingreso mensual esperado, margen resultante, y a qué se destina el margen.

| Categoría | Real | Objetivo | Nota |
|---|---:|---:|---|
| … | | | |
| **TOTAL** | | | |

Ingreso: … · Margen: … · Destino del margen: …

## 5. Riesgos y colchón

> Guía: los 2–3 riesgos reales del ingreso y del contexto (concentración de cliente, tipo de cambio, empleo, salud…), con su escenario concreto. Definir **modo supervivencia** (gasto mínimo mensual) y de ahí el **colchón mínimo intocable** de la fase actual y la **meta de colchón** de la siguiente. Si hay exposición a tipo de cambio: tabla de sensibilidad e indicador a vigilar en cada revisión, con umbral de acción.

- Modo supervivencia mensual: **… /mes**.
- Colchón mínimo intocable (fase actual): **…**
- Meta de colchón (siguiente fase): **…**

## 6. Plan y proyección (FECHA – FECHA)

> Guía: tabla mes a mes con acción, saldo proyectado (de deuda o de colchón) e hitos de caja (impuestos trimestrales, pagos grandes). Calculado **solo con el ingreso recurrente**, con las tasas anotadas en §1. Debajo, dos bloques que se mantienen vivos entre sesiones:
> - **Estado de ejecución**: qué está hecho, en tránsito y pendiente inmediato — es lo primero que lee una sesión nueva.
> - **Reglas de ejecución**: las reglas operativas numeradas que el plan necesita para no fallar (orden de pagos del mes, provisiones, saldos mínimos, contingencia si un mes el ingreso no llega).

| Mes | Acción | Proyección | Hitos de caja |
|---|---|---:|---|
| … | | | |

**ESTADO DE EJECUCIÓN (FECHA) — leer antes de continuar:**
- …

Reglas de ejecución:
1. …

## 7. Ritual mensual

Primera semana de cada mes: el usuario exporta los extractos → ingesta (`rituales/ingesta.md`) → revisión (`rituales/revision_mensual.md`) → salida en `revisiones/` y nueva versión de este documento.

## 8. Temas abiertos / backlog

> Guía: checklist vivo. Todo lo detectado que no se resuelve en el momento entra aquí con fecha objetivo si la tiene. Lo resuelto se tacha con fecha y resultado, no se borra.

- [ ] …

## 9. Principios del proyecto (para agentes y para el usuario)

> Guía: empezar con los 7 principios del `CLAUDE.md` del marco y añadir los propios que el diagnóstico revele. Los principios nacen de errores: cuando algo falle, preguntarse qué regla lo habría evitado y escribirla.

1. Los cálculos se hacen con código sobre el CSV, nunca "de memoria".
2. El agente propone; el usuario ejecuta los movimientos de dinero.
3. …

**Changelog**
- v1.0 (FECHA): documento inicial tras la ingesta y diagnóstico de la Fase 0 (período cubierto: …).
