# instalar.ps1 - Instalador del marco finaid para Windows 10/11.
#
# Deja el PC listo para operar finanzas con un agente: Claude Code, Python con pandas,
# el marco descargado y una verificacion que prueba que la cadena entera funciona.
#
# Uso (PowerShell, sin administrador):
#   $env:FINAID_TOKEN='<PAT de solo lectura>'; $env:FINAID_REPO='<owner>/finaid-app'
#   irm "https://api.github.com/repos/$env:FINAID_REPO/contents/instalar.ps1?ref=develop" `
#       -Headers @{Authorization="Bearer $env:FINAID_TOKEN"; Accept='application/vnd.github.raw'} | iex
#
# Variables de entorno reconocidas:
#   FINAID_TOKEN    PAT de GitHub, solo lectura, para descargar el marco. Obligatorio
#                   salvo que se use FINAID_SRC.
#   FINAID_REPO     'owner/repo' del marco. Por defecto el valor de $RepoPorDefecto.
#   FINAID_BRANCH   rama a descargar. Por defecto 'develop'.
#   FINAID_DIR      carpeta destino. Por defecto "$env:USERPROFILE\finaid".
#   FINAID_SRC      carpeta local con el marco; salta la descarga (para ensayos).
#   FINAID_SKIP     lista separada por comas: git,python,claude,marco,verificacion.

$ErrorActionPreference = 'Stop'
$ProgressPreference    = 'SilentlyContinue'
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}
try { [Console]::OutputEncoding = New-Object Text.UTF8Encoding $false } catch {}

$RepoPorDefecto = 'mhdelta/finaid-app'

$Repo    = if ($env:FINAID_REPO)   { $env:FINAID_REPO }   else { $RepoPorDefecto }
$Rama    = if ($env:FINAID_BRANCH) { $env:FINAID_BRANCH } else { 'develop' }
$Destino = if ($env:FINAID_DIR)    { $env:FINAID_DIR }    else { Join-Path $env:USERPROFILE 'finaid' }
$Saltar  = @()
if ($env:FINAID_SKIP) { $Saltar = $env:FINAID_SKIP.Split(',') | ForEach-Object { $_.Trim().ToLower() } }

$script:Avisos = @()
$script:ClaudeRecienInstalado = $false

function Paso  ($n, $t) { Write-Host ""; Write-Host "[$n/6] $t" -ForegroundColor Cyan }
function Ok    ($t)     { Write-Host "  OK    $t" -ForegroundColor Green }
function Info  ($t)     { Write-Host "  ..    $t" -ForegroundColor DarkGray }
function Aviso ($t)     { Write-Host "  AVISO $t" -ForegroundColor Yellow; $script:Avisos += $t }
function Morir ($t)     { Write-Host ""; Write-Host "  ERROR $t" -ForegroundColor Red; Write-Host ""; exit 1 }

function Saltado ($nombre) { return ($Saltar -contains $nombre) }
function Hay ($cmd) { return [bool](Get-Command $cmd -ErrorAction SilentlyContinue) }

# PowerShell 5.1 convierte en error terminante cualquier cosa que un .exe escriba por
# stderr cuando ErrorActionPreference es 'Stop' (pip avisa del PATH, winget es ruidoso).
# Todo comando externo pasa por aqui: se juzga por el codigo de salida, no por el ruido.
function Ejecutar-Nativo ($exe, $argumentos) {
    $previo = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $salida = & $exe @argumentos 2>&1 | Out-String
        $codigo = $LASTEXITCODE
    } catch {
        $salida = $_.Exception.Message
        $codigo = 1
    } finally {
        $ErrorActionPreference = $previo
    }
    return [pscustomobject]@{ Codigo = $codigo; Salida = $salida.Trim() }
}

function Refrescar-Path {
    $m = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $u = [Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path = (@($m, $u) | Where-Object { $_ }) -join ';'
}

function Escribir-Utf8 ($ruta, $texto) {
    $dir = Split-Path -Parent $ruta
    if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    [IO.File]::WriteAllText($ruta, $texto, (New-Object Text.UTF8Encoding $false))
}

function Winget-Instalar ($id, $nombre, $urlManual) {
    if (-not (Hay 'winget')) {
        Aviso "$nombre no esta instalado y winget no existe en este equipo. Instalalo a mano: $urlManual"
        return $false
    }
    Info "instalando $nombre con winget (puede tardar un par de minutos)..."
    $r = Ejecutar-Nativo 'winget' @('install', '--id', $id, '--exact', '--source', 'winget', '--silent',
                                    '--accept-package-agreements', '--accept-source-agreements')
    Refrescar-Path
    if ($r.Codigo -ne 0) {
        Aviso "winget devolvio el codigo $($r.Codigo) al instalar $nombre. Si el paso siguiente falla, instalalo a mano: $urlManual"
    }
    return $true
}

Write-Host ""
Write-Host "=== Instalador del marco finaid ===" -ForegroundColor White
Write-Host "    destino: $Destino"

# ---------------------------------------------------------------- 1. Preflight
Paso 1 "Comprobando el equipo"

if ($PSVersionTable.PSVersion.Major -lt 5) {
    Morir "Se necesita PowerShell 5.1 o superior. Este equipo tiene $($PSVersionTable.PSVersion)."
}
Ok "PowerShell $($PSVersionTable.PSVersion)"

$os = Get-CimInstance Win32_OperatingSystem
$build = [int]($os.BuildNumber)
if ($build -lt 17763) { Morir "Claude Code necesita Windows 10 1809 (build 17763) o superior. Este equipo: build $build." }
Ok "$($os.Caption) (build $build)"

$ramGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)
if ($ramGB -lt 4) { Aviso "El equipo tiene $ramGB GB de RAM; el minimo recomendado son 4 GB." } else { Ok "$ramGB GB de RAM" }

if ($Destino -match '[^\x20-\x7E]') {
    Aviso "La ruta de destino tiene acentos o caracteres no ASCII ($Destino). Algunas herramientas fallan ahi; si algo se rompe, prueba con C:\finaid."
}
if ($Destino -like "*OneDrive*") {
    Aviso "El destino esta dentro de OneDrive: los extractos y el CSV se sincronizarian a la nube de Microsoft. Recomendado: $env:USERPROFILE\finaid"
}

# El token es el fallo mas probable de toda la instalacion. Se comprueba AQUI, antes de
# gastar diez minutos instalando Python y Claude Code para morir al final descargando.
# Si no hay token, se intenta igual sin cabecera de autorizacion: con el repo publico
# la instalacion funciona sin token ninguno.
function Cabeceras-GitHub ($accept) {
    $h = @{ Accept = $accept; 'User-Agent' = 'finaid-instalador' }
    if ($env:FINAID_TOKEN) { $h['Authorization'] = "Bearer $env:FINAID_TOKEN" }
    return $h
}

function Comprobar-Acceso {
    $hdr = Cabeceras-GitHub 'application/vnd.github+json'
    try {
        Invoke-WebRequest -Uri "https://api.github.com/repos/$Repo/commits/$Rama" -Headers $hdr -UseBasicParsing -Method Head | Out-Null
        return
    } catch {
        $codigo = $null
        try { $codigo = [int]$_.Exception.Response.StatusCode } catch {}
        switch ($codigo) {
            401 { Morir "GitHub rechaza el token (401). Esta mal copiado o ha caducado. Genera uno nuevo y vuelve a lanzar el instalador." }
            403 { Morir "GitHub deniega el acceso (403). El token no tiene permiso 'Contents: Read' sobre $Repo." }
            404 {
                if (-not $env:FINAID_TOKEN) { Morir "No se encuentra $Repo (404) y no se ha dado ningun token. Si el repositorio es privado, hace falta token." }
                Morir "No se encuentra el repositorio $Repo (404). Puede ser que el nombre este mal escrito o que el token no incluya ese repositorio en su lista de acceso."
            }
            422 { Morir "El repositorio $Repo existe, pero no tiene ninguna rama llamada '$Rama' (422). La rama por defecto del marco es 'develop'." }
            default {
                if ($null -eq $codigo) { Morir "No hay conexion con GitHub. Revisa la conexion a internet y reintenta.`n$($_.Exception.Message)" }
                else { Morir "GitHub respondio $codigo al comprobar el acceso a $Repo ($Rama)." }
            }
        }
    }
}

if (-not $env:FINAID_SRC -and -not (Saltado 'marco')) {
    Comprobar-Acceso
    if ($env:FINAID_TOKEN) { Ok "acceso a $Repo ($Rama) confirmado" }
    else { Ok "acceso a $Repo ($Rama) confirmado (repositorio publico, sin token)" }
}

# Modo: instalacion nueva o actualizacion del marco sobre una instancia viva.
$instanciaViva = (Test-Path (Join-Path $Destino 'finanzas_base.md')) -or
                 (Test-Path (Join-Path $Destino 'datos\transacciones_unificadas.csv'))
if ($instanciaViva) {
    $Modo = 'actualizar'
    Ok "Instancia existente detectada: modo ACTUALIZAR (no se toca ningun dato personal)"
} else {
    $Modo = 'nuevo'
    if ((Test-Path $Destino) -and (Get-ChildItem $Destino -Force | Measure-Object).Count -gt 0) {
        Aviso "La carpeta $Destino ya existe y no esta vacia; los archivos del marco se sobreescriben."
    }
    Ok "Instalacion nueva"
}

# ------------------------------------------------------------ 2. Git for Windows
Paso 2 "Git for Windows (da a Claude Code una shell Bash)"

if (Saltado 'git') { Info "saltado" }
elseif (Hay 'git') { Ok "ya instalado: $((git --version) -replace 'git version ','')" }
else {
    if (Winget-Instalar 'Git.Git' 'Git for Windows' 'https://git-scm.com/downloads/win') {
        if (Hay 'git') { Ok "instalado: $((git --version) -replace 'git version ','')" }
        else { Aviso "Git se instalo pero aun no esta en el PATH de esta ventana. Cierra PowerShell y abrelo de nuevo." }
    }
}

# ------------------------------------------------------------------- 3. Python
Paso 3 "Python y las librerias de calculo"

$script:PyExe = $null
$script:PyPre = @()

function Buscar-Python {
    foreach ($cand in @(@('py', @('-3')), @('python', @()), @('python3', @()))) {
        $exe = $cand[0]; $pre = $cand[1]
        if (-not (Hay $exe)) { continue }
        $r = Ejecutar-Nativo $exe (@($pre) + @('-c', "import sys; print('%d.%d' % sys.version_info[:2])"))
        # La version del Store deja un stub que no ejecuta nada: el regex lo descarta.
        if ($r.Codigo -eq 0 -and $r.Salida -match '^3\.(\d+)$' -and [int]$Matches[1] -ge 9) {
            $script:PyExe = $exe; $script:PyPre = $pre
            return "3.$($Matches[1])"
        }
    }
    return $null
}

if (Saltado 'python') { Info "saltado" }
else {
    $ver = Buscar-Python
    if (-not $ver) {
        Winget-Instalar 'Python.Python.3.13' 'Python 3.13' 'https://www.python.org/downloads/windows/' | Out-Null
        $ver = Buscar-Python
    }
    if (-not $ver) {
        Morir "No se encontro Python despues de instalarlo. Cierra PowerShell, abrelo de nuevo y vuelve a lanzar el instalador. Si persiste: Configuracion > Aplicaciones > Alias de ejecucion de aplicaciones, y desactiva los alias 'python.exe' y 'python3.exe' de la Microsoft Store."
    }
    Ok "Python $ver ($script:PyExe)"

    Info "instalando pandas y lectores de extractos (pip)..."
    Ejecutar-Nativo $script:PyExe (@($script:PyPre) + @('-m', 'pip', 'install', '--quiet',
        '--disable-pip-version-check', '--upgrade', 'pip')) | Out-Null
    $r = Ejecutar-Nativo $script:PyExe (@($script:PyPre) + @('-m', 'pip', 'install', '--quiet',
        '--disable-pip-version-check', 'pandas', 'openpyxl', 'xlrd', 'pdfplumber'))
    if ($r.Codigo -ne 0) { Morir "Fallo la instalacion de las librerias de Python (codigo $($r.Codigo)):`n$($r.Salida)" }
    Ok "pandas, openpyxl, xlrd, pdfplumber"
}

# -------------------------------------------------------------- 4. Claude Code
Paso 4 "Claude Code"

if (Saltado 'claude') { Info "saltado" }
elseif (Hay 'claude') { Ok "ya instalado: $((Ejecutar-Nativo 'claude' @('--version')).Salida)" }
else {
    Info "descargando el instalador oficial de Anthropic..."
    $previo = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        & ([scriptblock]::Create((Invoke-RestMethod -Uri 'https://claude.ai/install.ps1'))) 2>&1 | Out-Null
    } catch {
        $ErrorActionPreference = $previo
        Morir "No se pudo instalar Claude Code automaticamente. Instalalo a mano en una ventana nueva de PowerShell con:  irm https://claude.ai/install.ps1 | iex"
    }
    $ErrorActionPreference = $previo
    Refrescar-Path
    if (-not (Hay 'claude')) {
        $local = Join-Path $env:USERPROFILE '.local\bin'
        if (Test-Path (Join-Path $local 'claude.exe')) { $env:Path = "$local;$env:Path" }
    }
    $script:ClaudeRecienInstalado = $true
    if (Hay 'claude') { Ok "instalado: $((Ejecutar-Nativo 'claude' @('--version')).Salida)" }
    else { Morir "Claude Code se instalo pero no aparece en el PATH. Cierra PowerShell, abrelo de nuevo y vuelve a lanzar el instalador." }
}

# ------------------------------------------------------------------ 5. El marco
Paso 5 "Descargando el marco"

function Obtener-Marco ($staging) {
    New-Item -ItemType Directory -Path $staging -Force | Out-Null

    if ($env:FINAID_SRC) {
        if (-not (Test-Path $env:FINAID_SRC)) { Morir "FINAID_SRC apunta a una carpeta que no existe: $env:FINAID_SRC" }
        Info "copiando desde $env:FINAID_SRC (modo local)"
        Copy-Item -Path (Join-Path $env:FINAID_SRC '*') -Destination $staging -Recurse -Force -Exclude '.git'
        if (Test-Path (Join-Path $staging '.git')) { Remove-Item (Join-Path $staging '.git') -Recurse -Force }
        return 'local'
    }

    if (-not $env:FINAID_TOKEN) {
        Morir "Falta el token de descarga. Antes de lanzar el instalador:  `$env:FINAID_TOKEN='<PAT de solo lectura>'"
    }
    $zip = Join-Path $env:TEMP "finaid-marco-$(Get-Random).zip"
    $url = "https://api.github.com/repos/$Repo/zipball/$Rama"
    $hdr = Cabeceras-GitHub 'application/vnd.github+json'

    Info "descargando $Repo ($Rama)..."
    try {
        Invoke-WebRequest -Uri $url -Headers $hdr -OutFile $zip -UseBasicParsing
    } catch {
        # Algunas versiones de PowerShell tropiezan al reenviar la cabecera al redirigir
        # a codeload: resolvemos el redirect a mano y descargamos la URL firmada sin cabecera.
        try {
            $r = Invoke-WebRequest -Uri $url -Headers $hdr -UseBasicParsing -MaximumRedirection 0 -ErrorAction SilentlyContinue
            $loc = $r.Headers.Location
        } catch { $loc = $_.Exception.Response.Headers.Location }
        if (-not $loc) {
            Morir "No se pudo descargar el marco desde $Repo. Revisa que el token sea valido, que no haya caducado y que tenga acceso de lectura a ese repositorio."
        }
        Invoke-WebRequest -Uri $loc -OutFile $zip -UseBasicParsing
    }

    $tmp = Join-Path $env:TEMP "finaid-zip-$(Get-Random)"
    Expand-Archive -Path $zip -DestinationPath $tmp -Force
    # GitHub empaqueta todo dentro de una carpeta owner-repo-sha: la aplanamos.
    $raiz = Get-ChildItem $tmp -Directory | Select-Object -First 1
    if (-not $raiz) { Morir "El archivo descargado no tiene el contenido esperado." }
    Copy-Item -Path (Join-Path $raiz.FullName '*') -Destination $staging -Recurse -Force
    $sha = ($raiz.Name -split '-')[-1]
    Remove-Item $zip, $tmp -Recurse -Force -ErrorAction SilentlyContinue
    return $sha
}

# Lo unico que se refresca al actualizar. Todo lo demas de la instancia es intocable.
$ArchivosDelMarco = @('CLAUDE.md', 'README.md', 'INSTALL.md', 'instalar.ps1', '.gitignore')
$CarpetasDelMarco = @('rituales', 'plantillas', 'docs', '.claude')

if (Saltado 'marco') { Info "saltado"; $version = 'saltado' }
else {
    $staging = Join-Path $env:TEMP "finaid-staging-$(Get-Random)"
    $version = Obtener-Marco $staging

    if (-not (Test-Path $Destino)) { New-Item -ItemType Directory -Path $Destino -Force | Out-Null }

    if ($Modo -eq 'nuevo') {
        Copy-Item -Path (Join-Path $staging '*') -Destination $Destino -Recurse -Force
        Ok "marco instalado en $Destino"
    } else {
        foreach ($f in $ArchivosDelMarco) {
            $o = Join-Path $staging $f
            if (Test-Path $o) { Copy-Item $o (Join-Path $Destino $f) -Force }
        }
        foreach ($c in $CarpetasDelMarco) {
            $o = Join-Path $staging $c
            if (Test-Path $o) { Copy-Item $o $Destino -Recurse -Force }
        }
        Ok "marco actualizado (rituales, plantillas y CLAUDE.md); datos personales intactos"
    }
    Remove-Item $staging -Recurse -Force -ErrorAction SilentlyContinue

    # Las carpetas de trabajo tienen que existir aunque el empaquetado se coma los .gitkeep.
    foreach ($c in @('datos\backup', 'extractos\entrada', 'extractos\procesados', 'revisiones')) {
        $p = Join-Path $Destino $c
        if (-not (Test-Path $p)) { New-Item -ItemType Directory -Path $p -Force | Out-Null }
    }

    $sello = @(
        "repositorio: $Repo",
        "rama: $Rama",
        "version: $version",
        "instalado: $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
    ) -join "`r`n"
    Escribir-Utf8 (Join-Path $Destino '.marco-version') $sello
}

# Ajustes de proyecto: UTF-8 en todo lo que escriba Python y la ruta de Git Bash.
$ajustes = [ordered]@{ env = [ordered]@{ PYTHONUTF8 = '1'; PYTHONIOENCODING = 'utf-8' } }
$bash = Join-Path $env:ProgramFiles 'Git\bin\bash.exe'
if (Test-Path $bash) { $ajustes.env['CLAUDE_CODE_GIT_BASH_PATH'] = $bash }
Escribir-Utf8 (Join-Path $Destino '.claude\settings.json') (($ajustes | ConvertTo-Json -Depth 5))
Ok "ajustes del proyecto escritos (.claude\settings.json)"

# ------------------------------------------------------------ 6. Verificacion
Paso 6 "Verificando que la cadena completa funciona"

if (Saltado 'verificacion') { Info "saltado" }
else {
    foreach ($f in @('CLAUDE.md', 'rituales\bootstrap.md', 'rituales\ingesta.md', 'rituales\revision_mensual.md',
                     'plantillas\finanzas_base.template.md', 'plantillas\bitacora.template.md',
                     'extractos\entrada', 'datos\backup')) {
        if (-not (Test-Path (Join-Path $Destino $f))) { Morir "Falta '$f' en $Destino. La descarga del marco quedo incompleta." }
    }
    Ok "estructura del marco completa"

    if ($script:PyExe) {
        # Prueba real de la cadena que usan los rituales: escribir CSV UTF-8 con acentos,
        # releerlo con pandas y que las cuentas cuadren. Es el principio numero 1 del marco.
        $prueba = Join-Path $env:TEMP "finaid-verificacion-$(Get-Random).py"
        $codigo = @'
import sys, os, tempfile
import pandas as pd
ruta = os.path.join(tempfile.gettempdir(), "finaid_check.csv")
filas = "fecha,cuenta,concepto,importe,moneda,tipo\n" \
        "2026-07-01,Nomina,Ingreso nomina,1500.00,EUR,ingreso\n" \
        "2026-07-03,Nomina,Compra farmacia,-12.35,EUR,gasto\n" \
        "2026-07-05,Nomina,Peaje autopista A-6,-4.65,EUR,gasto\n"
with open(ruta, "w", encoding="utf-8") as f:
    f.write(filas)
df = pd.read_csv(ruta, encoding="utf-8-sig")
os.remove(ruta)
saldo = round(df["importe"].sum(), 2)
assert saldo == 1483.00, "suma inesperada: %s" % saldo
assert "farmacia" in df.loc[1, "concepto"], "lectura de texto incorrecta"
assert "Peaje autopista" in df.loc[2, "concepto"], "acentos o codificacion mal"
print("pandas %s | 3 filas | saldo %.2f EUR" % (pd.__version__, saldo))
'@
        Escribir-Utf8 $prueba $codigo
        $r = Ejecutar-Nativo $script:PyExe (@($script:PyPre) + @($prueba))
        Remove-Item $prueba -Force -ErrorAction SilentlyContinue
        if ($r.Codigo -ne 0) { Morir "La prueba de calculo con pandas fallo:`n$($r.Salida)" }
        Ok "calculo sobre CSV UTF-8: $($r.Salida)"
    }

    if (Hay 'claude') { Ok "Claude Code $((Ejecutar-Nativo 'claude' @('--version')).Salida)" }
}

# ------------------------------------------------------------------- Resultado
Write-Host ""
Write-Host "=== Instalacion terminada ===" -ForegroundColor Green
Write-Host ""
if ($script:Avisos.Count -gt 0) {
    Write-Host "Avisos que conviene mirar:" -ForegroundColor Yellow
    foreach ($a in $script:Avisos) { Write-Host "  - $a" -ForegroundColor Yellow }
    Write-Host ""
}
if ($script:ClaudeRecienInstalado) {
    # El PATH de una ventana ya abierta no cambia: 'claude' no se reconocera en esta.
    Write-Host "IMPORTANTE: cierra ESTA ventana y abre una nueva antes de seguir." -ForegroundColor Yellow
    Write-Host "Claude Code acaba de instalarse y esta ventana todavia usa el PATH viejo:" -ForegroundColor Yellow
    Write-Host "si escribes 'claude' aqui, dira que no se reconoce el termino." -ForegroundColor Yellow
    Write-Host ""
}
Write-Host "Siguiente paso - en una ventana NUEVA, copia y pega estas dos lineas:" -ForegroundColor White
Write-Host ""
Write-Host "    cd `"$Destino`"" -ForegroundColor Cyan
Write-Host "    claude" -ForegroundColor Cyan
Write-Host ""
Write-Host "La primera vez, Claude abre el navegador para iniciar sesion (hace falta plan Pro o Max)."
Write-Host "Cuando estes dentro, escribe:  Arranca la Fase 0"
Write-Host ""
Write-Host "Los extractos del banco van en:  $Destino\extractos\entrada"
Write-Host ""
