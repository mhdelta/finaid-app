# Proyecto: Finanzas personales (marco finaid)

## Antes de hacer NADA
0. **Identifica qué repo es este.** El marco vive en dos formas: el **repo canónico**, donde se desarrolla el marco mismo (plantilla, rituales, documentación; el trabajo es *meta* — ver "Pendiente antes de v1.0" en el README) y las **instancias**, copias donde una persona opera sus finanzas reales. En el repo canónico nunca existirá `finanzas_base.md` y **nunca se arranca la Fase 0**: no hay finanzas que operar ahí.
1. Si existe `finanzas_base.md` en la raíz: es una instancia en régimen. **Léelo COMPLETO**. Es la fuente de verdad (contexto, deuda, presupuesto, plan, riesgos, principios). Ningún análisis ni cálculo se hace sin haberlo leído. Revisa su "Estado de ejecución" y su backlog — ahí está lo pendiente entre sesiones.
2. Si NO existe `finanzas_base.md` y el contexto no deja claro cuál de las dos formas es: **pregúntale al usuario** antes de asumir nada. Solo si confirma que es una instancia nueva, sigue `rituales/bootstrap.md`.

## Principios innegociables
1. **Los cálculos se hacen con código** sobre `datos/transacciones_unificadas.csv`, nunca "de memoria".
2. **El agente propone; el usuario ejecuta** los movimientos de dinero. Nunca asumas que un pago ya se hizo: pregunta o pide el extracto.
3. **Toda conversión de moneda usa el tipo de cambio del día** (búscalo en internet al momento; sin acceso a red, pídeselo al usuario). Nunca tasas congeladas. (Aplica solo si hay más de una moneda.)
4. **El plan se calcula solo con el ingreso recurrente confiable** definido en el documento base. Los ingresos extra aceleran el plan, nunca lo sostienen.
5. **Cada dato incierto se marca "a verificar con extractos"**, no se estima dos veces.
6. **Ninguna compra nueva se financia con interés.** Cualquier decisión de deuda nueva pasa primero por el documento base.
7. **Tras cada revisión mensual se actualiza `finanzas_base.md`**: nueva versión + entrada en el changelog.

## Reglas de las carpetas
- **Solo se procesa lo que está en `extractos/entrada/`.** Lo que está en `procesados/` ya vive en el CSV; volver a ingestarlo duplicaría transacciones.
- Tras una ingesta exitosa (validación de saldos incluida), mueve los archivos de `entrada/` a `procesados/YYYY-MM/` según el período que cubren.
- El CSV maestro nunca se sobreescribe a ciegas: copia `datos/backup/transacciones_unificadas_YYYYMMDD.csv` antes de añadir filas.
- `piloto/bitacora.md` es el canal de retorno hacia el marco: cualquier fricción con el marco — también fuera de un ritual — se registra ahí, **sin datos personales** (reglas en `plantillas/bitacora.template.md`).

## El dataset maestro
- `datos/transacciones_unificadas.csv`, esquema fijo: `fecha, cuenta, concepto, importe, moneda, tipo`.
  - `fecha`: ISO `YYYY-MM-DD`. `importe`: negativo = sale dinero, positivo = entra. `moneda`: código ISO (EUR, USD, COP…).
  - `tipo`: `gasto` | `ingreso` | `transferencia_interna` | `pago_deuda` | `comision`. Las transferencias entre cuentas propias son `transferencia_interna` y **se excluyen** de cualquier análisis de gasto/ingreso.
- Guardar con UTF-8 (tolerar BOM al leer); leer con pandas o equivalente, no con parsing manual. **Escribir siempre desde código con `encoding='utf-8'` explícito**; en Windows, nunca con `Out-File`/`Set-Content` de PowerShell (su codificación por defecto no es UTF-8 y corrompe los acentos en silencio).
- El CSV **no tiene columna de categoría**: la clasificación se hace por keywords sobre `concepto`, con las reglas por banco documentadas en `datos/notas_bancos.md`.

## Conocimiento por banco: `datos/notas_bancos.md`
Cada banco tiene quirks de formato (decimales, fechas, categorías embebidas, secciones del extracto, duplicados entre formatos). Ese conocimiento **se documenta en `datos/notas_bancos.md` la primera vez que se descubre** y se consulta en cada ingesta. Es la parte menos transferible del sistema: trátala como un activo que crece.

## Perímetro de ingresos (definirlo en Fase 0 y respetarlo)
Si el dinero pasa por plataformas intermedias (nómina, Deel, PayPal…) que no son cuentas del CSV, los abonos que llegan a cuentas rastreadas pueden ser retiros del mismo ingreso, no ingresos adicionales. El documento base define qué cuenta como ingreso; el CSV no se suma a ciegas.

El **efectivo** es el otro caso de perímetro: si una parte del flujo se cobra y gasta en mano sin tocar cuentas, los depósitos son un proxy del ingreso (no el ingreso) y los retiros una bolsa de gasto opaca. El documento base define cómo se mide esa parte y qué reglas la gobiernan; nunca se trata como si el banco viera todo.

## Tareas típicas
- **"Revisión mensual"** → sigue `rituales/revision_mensual.md`.
- **"Procesa los extractos"** → sigue `rituales/ingesta.md` sobre `extractos/entrada/`.
- **"Arranca la Fase 0"** → sigue `rituales/bootstrap.md`.
- **Preguntas de análisis** → código sobre el CSV + contexto del documento base.
