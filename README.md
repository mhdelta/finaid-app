# finaid — marco para operar tus finanzas personales con un agente

**Estado: v0.9** — el diseño está probado en una instancia real (10 meses de datos, multi-moneda, con deuda); el marco generalizado aún no ha pasado un piloto con datos ajenos. Úsalo sabiendo eso.

## Qué es esto

Un kit de arranque para gestionar tus finanzas personales trabajando con un agente LLM (Claude Code u otro), de forma **auditable, continua entre sesiones y con separación clara de responsabilidades**: el agente analiza y propone; tú decides y ejecutas los movimientos de dinero.

No es una app ni un SaaS: es una estructura de carpetas, un documento de estado, y tres procesos escritos ("rituales") que el agente sigue. Todo vive en texto plano y CSV en tu máquina.

## El marco: 4 capas

El valor del sistema no está en el análisis financiero (eso lo hace cualquier LLM); está en la arquitectura que hace el trabajo **repetible y confiable**:

| Capa | Artefacto | Qué resuelve |
|---|---|---|
| **1. Principios** | `CLAUDE.md` (§ Principios) | Reglas que sobreviven a cualquier conversación: cálculos con código, nunca "de memoria"; el agente propone / el usuario ejecuta; la incertidumbre se marca, no se estima dos veces. |
| **2. Estado versionado** | `finanzas_base.md` | La fuente de verdad con changelog. La continuidad no vive en la conversación (el agente no tiene memoria fiable): vive en este documento, que cualquier sesión nueva carga y continúa. |
| **3. Datos con higiene** | `datos/transacciones_unificadas.csv` | Dataset maestro inmutable: backup antes de cada escritura, deduplicación, validación de saldos en cada ingesta, nunca reprocesar lo ya ingestado. |
| **4. Rituales** | `rituales/*.md` | Procesos escritos con salida definida. Lo que no está escrito se improvisa distinto cada vez; lo que está escrito se audita y se mejora. |

## Ciclo de vida: 4 fases

- **Fase 0 — Bootstrap** (`rituales/bootstrap.md`): inventario de cuentas, ingesta inicial de 3–6 meses de extractos, diagnóstico con código, y redacción de tu `finanzas_base.md` v1.0 a partir de la plantilla.
- **Fase 1 — Plan**: con el diagnóstico sobre la mesa, se define el plan (deuda, colchón, presupuesto objetivo) y las reglas de ejecución. Queda escrito en el documento base.
- **Fase 2 — Régimen**: ritual mensual (`rituales/revision_mensual.md`) — ingesta del mes, real vs. objetivo, desviaciones, decisión, nueva versión del documento.
- **Fase 3 — Evolución**: cuando los objetivos de la fase actual se cumplen (deuda muerta, colchón lleno), se redefine el documento (v2.0) y cambia el foco.

## Cómo empezar

1. Clona o copia este repo.
2. Abre tu agente en la raíz y dile: **"Arranca la Fase 0"** (o sigue `rituales/bootstrap.md` a mano).
3. Deja tus extractos en `extractos/entrada/` cuando el ritual te los pida. (En cristiano: los archivos que descargas de tu banco van a la carpeta `extractos`, subcarpeta `entrada` — nada más.)
4. Al terminar la Fase 0 tendrás tu `finanzas_base.md` v1.0 y el sistema queda en régimen mensual.

## El contrato del usuario

El sistema falla sin esto. Si no puedes comprometerte, no empieces:

1. **Exportas extractos una vez al mes** (la primera semana). Sin datos frescos no hay revisión.
2. **Ejecutas tú los movimientos** que se acuerden, y reportas lo que hiciste. El agente nunca asume que un pago se hizo.
3. **No le mientes al sistema.** Un dato incómodo omitido invalida el análisis en silencio.
4. **Lees la salida de cada revisión** y tomas la decisión del mes. El agente propone; la decisión es tuya.

## Privacidad

Tus datos financieros son tuyos. El `.gitignore` de este repo **excluye por defecto** todo lo personal (CSV, extractos, revisiones, tu `finanzas_base.md`): puedes versionar el marco sin arrastrar tus datos. Si tu fork es privado y quieres versionar también tus datos, edita el `.gitignore` a conciencia. Nunca publiques una instancia con datos.

## Estructura

```
finaid-app/
├── README.md                     ← este archivo
├── CLAUDE.md                     ← instrucciones para el agente
├── plantillas/
│   ├── finanzas_base.template.md ← esqueleto del documento de estado
│   └── bitacora.template.md      ← esqueleto de la bitácora de fricción
├── rituales/
│   ├── bootstrap.md              ← Fase 0
│   ├── ingesta.md                ← procesar extractos nuevos
│   └── revision_mensual.md       ← revisión mensual
├── datos/                        ← (se genera en Fase 0) CSV maestro, notas por banco, backups
├── extractos/
│   ├── entrada/                  ← aquí dejas los extractos nuevos
│   └── procesados/YYYY-MM/       ← ya ingestados; no reprocesar
├── revisiones/                   ← salida de cada revisión mensual
└── piloto/                       ← (se genera en Fase 0) bitácora de fricción — ver abajo
```

## Canal de retorno: la bitácora de fricción

Cada instancia mejora el marco. En el cierre de cada ritual, el agente registra en
`piloto/bitacora.md` todo lo que el marco no contempló: instrucciones ad-hoc que el usuario tuvo
que dar, pasos ambiguos, secciones de la plantilla que sobraron o faltaron, quirks de banco
generalizados. La bitácora se escribe **sin datos personales por diseño** (reglas en
`plantillas/bitacora.template.md`) — es el único archivo de la instancia pensado para compartirse,
y por eso no está en el `.gitignore`. Si usas el marco y quieres contribuir, ese archivo es lo
único que necesitamos de vuelta.

## Pendiente antes de v1.0

- [x] ~~Prueba con datos sintéticos~~ → hecho como **piloto con datos reales adaptados** (ago 2026): cuenta única del dataset Berka, cliente simulado por agente, bootstrap completo sin instrucciones ad-hoc. Hallazgos aplicados; informe en `docs/pilotos/2026-08-berka.md`. Queda abierto probar multi-banco/multi-formato en el siguiente piloto.
- [ ] Piloto real con una persona de perfil distinto al de origen (otra moneda, sin deuda, empleado en vez de autónomo).
- [ ] Endurecer la plantilla con lo que ambos pilotos descubran.
