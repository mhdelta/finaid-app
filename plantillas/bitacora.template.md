# Bitácora de fricción — [nombre de la instancia]

Registro de dónde el marco se quedó corto en esta instancia. Es el canal de retorno hacia el repo
canónico: cada entrada es un candidato a mejorar `rituales/`, `plantillas/` o `CLAUDE.md` del marco.
El agente la actualiza en el **cierre de cada ritual**; no es opcional.

## Regla dura: sin datos personales

Este es el único archivo de la instancia diseñado para compartirse (por eso NO está en el
`.gitignore`). Se escribe con **patrones, nunca con datos**:

- ✅ "El banco mezcla separador decimal US y europeo en un mismo XLSX"
- ❌ "El saldo de la Visa era 8,8M COP"
- ✅ "El usuario tuvo que aclarar que los abonos de la plataforma de nómina no son ingreso extra"
- ❌ nombres de personas, montos, saldos, números de cuenta, nombres de comercios

Si una entrada necesita un dato para entenderse, se generaliza ("un monto seis órdenes de magnitud
mayor que el resto") o no se escribe.

## Qué se registra

| Tipo | Qué es | Señal típica |
|---|---|---|
| `instruccion-adhoc` | El usuario tuvo que darle al agente una instrucción que el ritual no contemplaba | "ah, pero primero tienes que…" |
| `hueco-ritual` | Un paso del ritual fue insuficiente, ambiguo o faltó | el agente improvisó o se atascó |
| `plantilla` | Una sección de `finanzas_base.template.md` sobró, faltó o no encajó con el perfil | secciones forzadas o vacías |
| `quirk-banco` | Formato o comportamiento de un banco no previsto por `ingesta.md` (la versión con detalle va a `notas_bancos.md`; aquí va el patrón generalizado) | parsing sospechoso, validación que no cuadra |
| `mejora` | Algo funcionó pero hay una forma claramente mejor | fricción repetida sin ser error |

## Entradas

Formato: una entrada por fricción, la más reciente arriba.

<!-- plantilla de entrada:
### YYYY-MM-DD · tipo · ritual (bootstrap / ingesta / revision_mensual)
**Qué pasó:** [1–3 frases, sin datos personales]
**Qué habría hecho falta:** [la instrucción, paso o sección que el marco debió tener]
-->
