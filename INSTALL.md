# Instalación en Windows

Guía para dejar un PC con Windows listo para operar el marco finaid. Pensada para una sesión
guiada en remoto: quien instala tiene el repo; la persona que va a usarlo solo tiene su PC.

El instalador (`instalar.ps1`) hace todo el trabajo y **verifica lo que hizo**. Si termina sin
avisos, la máquina está lista.

## Qué deja instalado

| Pieza | Para qué |
|---|---|
| **Claude Code** | El agente que ejecuta los rituales. |
| **Python + pandas** | Los cálculos del marco se hacen con código sobre el CSV, nunca "de memoria" (principio nº1). Sin Python el marco no funciona. |
| **openpyxl, xlrd, pdfplumber** | Leer extractos en `.xlsx`, `.xls` y PDF. |
| **Git for Windows** | Le da a Claude Code una shell Bash. Opcional, pero recomendado por Anthropic. |
| **El marco** | En `C:\Users\<usuario>\finaid`, con las carpetas de trabajo creadas. |
| **`.claude/settings.json`** | Fuerza UTF-8 en todo lo que escriba Python. En Windows esto no es opcional: la consola por defecto no es UTF-8 y los acentos acaban en mojibake. |

## Requisitos previos

- **Windows 10 build 17763 (1809) o superior**, 4 GB de RAM. El instalador lo comprueba y para si no se cumple.
- **Cuenta de Claude con plan Pro, Max, Team o Enterprise.** El plan gratuito no incluye Claude Code.
- **Un token de GitHub** para descargar el marco (el repo es privado). Ver abajo.
- Conexión a internet. No hace falta ser administrador del equipo.

## Antes de la sesión: crear el token

En GitHub → *Settings* → *Developer settings* → *Personal access tokens* → **Fine-grained tokens**:

- **Repository access**: solo `mhdelta/finaid-app`.
- **Permissions** → *Repository permissions* → **Contents: Read-only**. Nada más.
- **Expiration**: lo más corto que cubra la sesión (7 días).

Es un token de **solo lectura de un único repo**: aunque se filtre, no permite escribir nada.
Aun así, revócalo al terminar el piloto.

## La instalación

En el PC de destino, abrir una terminal (**da igual PowerShell o CMD**) y pegar esta línea,
sustituyendo el token:

```
powershell -NoProfile -ExecutionPolicy Bypass -Command "[Environment]::SetEnvironmentVariable('FINAID_TOKEN','github_pat_TU_TOKEN_AQUI','Process'); iex (irm 'https://api.github.com/repos/mhdelta/finaid-app/contents/instalar.ps1?ref=develop' -Headers @{Authorization=('Bearer '+[Environment]::GetEnvironmentVariable('FINAID_TOKEN')); Accept='application/vnd.github.raw'})"
```

> **Por qué es tan feo**: no contiene ni un `$` ni un `%`, y por eso el mismo texto funciona
> literalmente igual pegado en CMD y en PowerShell. Un comando que empiece por `irm` **sólo
> funciona en PowerShell**: en CMD responde *"'irm' no se reconoce como un comando interno o
> externo"*. Y `-ExecutionPolicy Bypass` está ahí porque la política por defecto de Windows es
> `Restricted`. Las dos cosas están verificadas en las dos shells.

Tarda entre 3 y 10 minutos, casi todo descargando Python y Claude Code.

> **El token nunca aparece en una URL ni queda escrito en disco**: viaja en una cabecera HTTP y
> muere con la ventana de PowerShell. El marco se descarga como ZIP y la instancia queda **sin
> `remote` de git**, así que es imposible empujar por accidente los datos de nadie al repo.

### Si el one-liner falla: instalación en dos pasos

Más robusta y permite leer el script antes de ejecutarlo:

```powershell
$env:FINAID_TOKEN='github_pat_TU_TOKEN_AQUI'
irm "https://api.github.com/repos/mhdelta/finaid-app/contents/instalar.ps1?ref=develop" -Headers @{Authorization="Bearer $env:FINAID_TOKEN"; Accept='application/vnd.github.raw'} -OutFile "$env:TEMP\instalar.ps1"
Unblock-File "$env:TEMP\instalar.ps1"
powershell -ExecutionPolicy Bypass -File "$env:TEMP\instalar.ps1"
```

## Qué se ve al terminar

```
[6/6] Verificando que la cadena completa funciona
  OK    estructura del marco completa
  OK    calculo sobre CSV UTF-8: pandas 3.0.2 | 3 filas | saldo 1483.00 EUR
  OK    Claude Code 2.1.222 (Claude Code)

=== Instalacion terminada ===
```

Esa línea de `calculo sobre CSV UTF-8` es la importante: prueba de punta a punta que Python
escribe un CSV con acentos, que pandas lo relee y que las cuentas cuadran. Es exactamente lo que
harán los rituales.

## Primer arranque

```powershell
cd "$env:USERPROFILE\finaid"
claude
```

1. La primera vez, Claude Code abre el navegador para iniciar sesión.
2. Ya dentro, escribir: **`Arranca la Fase 0`**.
3. El agente lee `CLAUDE.md`, ve que no hay `finanzas_base.md` y sigue `rituales/bootstrap.md`.

Los extractos del banco van en `C:\Users\<usuario>\finaid\extractos\entrada`.

> Durante la Fase 0 el agente pedirá permiso cada vez que ejecute código. La primera vez que
> pregunte por un comando de Python, elegir **"no volver a preguntar"**: si no, son decenas de
> confirmaciones a lo largo del bootstrap.

## Guion de la sesión guiada

1. Abrir PowerShell. **Comprobar que el prompt empieza por `PS`** — si no, es CMD y `irm` no existe.
2. Pegar las dos líneas de instalación. Esperar.
3. Leer los avisos amarillos, si los hay.
4. `cd "$env:USERPROFILE\finaid"` y `claude`. Iniciar sesión.
5. `Arranca la Fase 0` y dejar que el agente lleve la entrevista.
6. Al terminar: revocar el token en GitHub.

## Si algo falla

| Síntoma | Causa y solución |
|---|---|
| `'irm' no se reconoce como un comando interno o externo` | Estás en CMD y pegaste la variante corta de PowerShell. Usar el comando universal de arriba. |
| `no se puede cargar el archivo ... ejecución de scripts está deshabilitada` | Política `Restricted` (la de fábrica). El comando universal ya lleva `-ExecutionPolicy Bypass`. |
| `GitHub rechaza el token (401)` | Mal copiado o caducado. Regenerarlo. |
| `no tiene ninguna rama llamada 'main' (422)` | La rama del marco es `develop`. |
| `No se encuentra el repositorio (404)` | Nombre mal escrito, o el token no incluye ese repo en su lista de acceso. |
| `Python was not found` | Los alias de la Microsoft Store interceptan `python`. Configuración → Aplicaciones → *Alias de ejecución de aplicaciones* → desactivar `python.exe` y `python3.exe`. Relanzar. |
| Instala Python pero luego no lo encuentra | El PATH de esa ventana es viejo. Cerrar PowerShell, abrirlo de nuevo, relanzar el instalador (es re-ejecutable). |
| `claude` no se reconoce tras instalar | Igual: ventana nueva de PowerShell. El binario queda en `%USERPROFILE%\.local\bin`. |
| Acentos rotos (`Nómina`) | Algo escribió el archivo fuera de UTF-8. El agente debe escribir siempre desde Python con `encoding='utf-8'`, nunca con `Out-File` ni `Set-Content` de PowerShell. |
| El antivirus bloquea el instalador | Ejecutar la variante en dos pasos, que descarga el archivo y permite inspeccionarlo antes. |
| No se puede ejecutar scripts (`ExecutionPolicy`) | El one-liner no toca disco y no le afecta. Para la variante en dos pasos, usar `powershell -ExecutionPolicy Bypass -File ...` como está arriba. |

## Actualizar el marco de una instancia en uso

El instalador es **re-ejecutable sin riesgo**. Si detecta `finanzas_base.md` o el CSV maestro,
pasa a modo actualización: refresca `rituales/`, `plantillas/`, `CLAUDE.md`, `README.md` y los
ajustes, y **no toca** `finanzas_base.md`, `datos/`, `extractos/`, `revisiones/` ni `piloto/`.

```
OK    Instancia existente detectada: modo ACTUALIZAR (no se toca ningun dato personal)
OK    marco actualizado (rituales, plantillas y CLAUDE.md); datos personales intactos
```

La versión instalada queda registrada en `.marco-version` (repositorio, rama, commit y fecha):
es lo que hay que mirar para saber contra qué versión del marco corrió un piloto.

## Notas de Windows que importan

- **OneDrive**: la instalación va a `C:\Users\<usuario>\finaid`, fuera de las carpetas que OneDrive
  sincroniza. Si se mueve a Documentos o Escritorio, los extractos y el CSV se suben a la nube de
  Microsoft. El instalador avisa si detecta un destino dentro de OneDrive.
- **Rutas con acentos**: si el nombre de usuario de Windows lleva tildes o ñ, el instalador lo avisa.
  Si algo se rompe, instalar en `C:\finaid` con `$env:FINAID_DIR='C:\finaid'`.
- **La consola no es UTF-8** (suele ser CP850 en Windows en español). Por eso `.claude/settings.json`
  fija `PYTHONUTF8=1`.

## Variables de entorno del instalador

| Variable | Efecto |
|---|---|
| `FINAID_TOKEN` | Token de GitHub. Obligatorio salvo con `FINAID_SRC`. |
| `FINAID_REPO` | `owner/repo` del marco. Por defecto `mhdelta/finaid-app`. |
| `FINAID_BRANCH` | Rama a descargar. Por defecto `develop`. |
| `FINAID_DIR` | Carpeta destino. Por defecto `%USERPROFILE%\finaid`. |
| `FINAID_SRC` | Instala desde una carpeta local en vez de GitHub (ensayos). |
| `FINAID_SKIP` | Lista separada por comas de pasos a saltar: `git,python,claude,marco,verificacion`. |

## Desinstalar

```powershell
Remove-Item "$env:USERPROFILE\finaid" -Recurse -Force        # el marco y los datos
Remove-Item "$env:USERPROFILE\.local\bin\claude.exe" -Force  # Claude Code
Remove-Item "$env:USERPROFILE\.local\share\claude" -Recurse -Force
Remove-Item "$env:USERPROFILE\.claude" -Recurse -Force       # sesiones y ajustes de Claude
```

Python y Git se quitan desde Configuración → Aplicaciones.
