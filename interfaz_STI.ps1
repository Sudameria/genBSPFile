#########################################################################
#                                                                       #
#                        Script STI -> Sudameria                        #
#                                                                       #
#########################################################################
$carpetaAmadeus = "C:\Server Folder\Company Data\Amadeus Interface -AIR\"
$carpetaSabre = "C:\Server Folder\Company Data\Sabre Interface\"
$carpetaCopiados = "C:\SudameriaInterface\Copiados"
$carpetaProcesados = "C:\SudameriaInterface\Procesados"

$ftpUrl = "ftp://190.210.238.29"
$ftpUsuario = "SudameriaFTP"
$ftpClave = "SudaT001"

#$ftpUrl = "ftp://185.245.180.36"
#$ftpUsuario = "pnr@sudameria.com"
#$ftpClave = "ysszhi9Wp2E="

$identificadorSudameria = "0010009214"


function Verify-Folder {
    param (
        [string]$carpeta
    )
    if (-not (Test-Path $carpeta)) {
        New-Item -Path $carpeta -ItemType Directory | Out-Null
        Write-Host "No existe $carpeta se crea"
    }
}

function Upload-File-FTP {
    param (
        [string]$archivoLocal,
        [string]$ftpUrl,
        [string]$ftpUsuario,
        [string]$ftpClave
    )

    $ftpFullUrl = "$ftpUrl/$(Split-Path $archivoLocal -Leaf)"
    Write-Host "Moviendo archivo $archivoLocal a $ftpFullUrl"

    $webclient = New-Object System.Net.WebClient
    $webclient.Credentials = New-Object System.Net.NetworkCredential($ftpUsuario, $ftpClave)
    
    try {
        $webclient.UploadFile($ftpFullUrl, $archivoLocal)
        Write-Host "Completado $archivoLocal"
        return $true
    }
    catch {
        Write-Host "Error al transferir $archivoLocal $_"
        return $false
    }
}

function Process-Files {
    param (
        [string]$carpetaOrigen,
        [string]$identificador,
        [string]$carpetaCopiados,
        [string]$carpetaProcesados
    )

    Verify-Folder $carpetaCopiados
    Verify-Folder $carpetaProcesados

    $archivos = Get-ChildItem -Path $carpetaOrigen | Where-Object {
        Select-String -Path $_.FullName -Pattern $identificador
    }

    foreach ($archivo in $archivos) {
        $rutaArchivoDestino = Join-Path $carpetaCopiados $archivo.Name
        $rutaArchivoProcesados = Join-Path $carpetaProcesados $archivo.Name
        if (-not (Test-Path $rutaArchivoProcesados)) {
            Copy-Item -Path $archivo.FullName -Destination $rutaArchivoDestino
            #Write-Host "Archivo $($archivo.FullName) copiado a $rutaArchivoDestino"
        }
    }

    $archivosCopiados = Get-ChildItem -Path $carpetaCopiados
    foreach ($archivoCopiado in $archivosCopiados) {
        $rutaArchivoProcesados = Join-Path $carpetaProcesados $archivoCopiado.Name

        if (-not (Test-Path $rutaArchivoProcesados)) {
            if (Upload-File-FTP -archivoLocal $archivoCopiado.FullName -ftpUrl $ftpUrl -ftpUsuario $ftpUsuario -ftpClave $ftpClave) {
                Move-Item -Path $archivoCopiado.FullName -Destination $rutaArchivoProcesados
                #Write-Host "Archivo $($archivoCopiado.FullName) movido a $rutaArchivoProcesados"
            }
        }
    }
}

Verify-Folder $carpetaCopiados
Verify-Folder $carpetaProcesados

Write-Host "Procesando archivos de Amadeus..."
Process-Files -carpetaOrigen $carpetaAmadeus -identificador $identificadorSudameria -carpetaCopiados $carpetaCopiados -carpetaProcesados $carpetaProcesados

Write-Host "Procesando archivos de Sabre..."
Process-Files -carpetaOrigen $carpetaSabre -identificador $identificadorSudameria -carpetaCopiados $carpetaCopiados -carpetaProcesados $carpetaProcesados

Write-Host "Proceso completado."
