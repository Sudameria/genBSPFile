#########################################################################
#                                                                       #
#               Script para procesar archivos Amadeus/Sabre             #
#                                                                       #
#########################################################################

# Variables
$OriginFolder = "C:\SudameriaInterface\Procesados"
$AmadeusFolder = "C:\SudameriaInterface\Procesados\AmadeusProcessed\"
$SabreFolder = "C:\SudameriaInterface\Procesados\SabreProcessed\"

function Verify-Folder {
    param (
        [string]$carpeta
    )
    if (-not (Test-Path $carpeta)) {
        New-Item -Path $carpeta -ItemType Directory | Out-Null
        Write-Host "No existe $carpeta, se crea"
    }
}

function Process-Amadeus-Files {
    param (
        [string]$archivo
    )
    $contenido = Get-Content -Path $archivo
    $contenidoModificado = $contenido -replace "FPCC", "FPCASH"
    Set-Content -Path $archivo -Value $contenidoModificado
}

function Process-Sabre-Files {
    param (
        [string]$archivo
    )
    $contenido = Get-Content -Path $archivo
    $contenidoModificado = $contenido -replace "/CC", "/CA"
    Set-Content -Path $archivo -Value $contenidoModificado
}

function Is-Amadeus {
    param (
        [string]$filePath
    )

    # Validación para asegurarse de que filePath no esté vacío
    if (-not [string]::IsNullOrWhiteSpace($filePath) -and (Test-Path $filePath)) {
        # Leer la primera línea del archivo
        $firstLine = Get-Content -Path $filePath -TotalCount 1

        # Verificar si la primera línea comienza con "AIR-"
        if ($firstLine -match "^AIR-") {
            return $true
        }
    }
    return $false
}

function Is-Sabre {
    param (
        [string]$filePath
    )
    
    # Validación para asegurarse de que filePath no esté vacío
    if (-not [string]::IsNullOrWhiteSpace($filePath) -and (Test-Path $filePath)) {
        # Leer la primera línea del archivo
        $firstLine = Get-Content -Path $filePath -TotalCount 1

        # Verificar si la primera línea comienza con "AA"
        if ($firstLine -match "^AA") {
            return $true
        }
    }
    return $false
}

function Process-Files {
    param (
        [string]$OriginFolder,
        [string]$AmadeusFolder,
        [string]$SabreFolder
    )

    $archivos = Get-ChildItem -Path $OriginFolder

    foreach ($archivo in $archivos) {
        $filePath = $archivo.FullName  # Obtener la ruta completa del archivo
        
        if (Is-Amadeus -filePath $filePath) {
            Process-Amadeus-Files -archivo $filePath
            Move-Item -Path $filePath -Destination $AmadeusFolder
            Write-Host "Procesado y movido (Amadeus): $($archivo.Name)"
        }
        elseif (Is-Sabre -filePath $filePath) {
            Process-Sabre-Files -archivo $filePath
            Move-Item -Path $filePath -Destination $SabreFolder
            Write-Host "Procesado y movido (Sabre): $($archivo.Name)"
        }
        else {
            Write-Host "No se pudo determinar si el archivo es de Amadeus o Sabre: $($archivo.Name)"
        }
    }
}

Write-Host "Procesando PNRs"

# Verificar si las carpetas existen, si no crearlas
Verify-Folder $OriginFolder
Verify-Folder $AmadeusFolder
Verify-Folder $SabreFolder

# Procesar los archivos
Process-Files -OriginFolder $OriginFolder -AmadeusFolder $AmadeusFolder -SabreFolder $SabreFolder

Write-Host "Proceso completado."
