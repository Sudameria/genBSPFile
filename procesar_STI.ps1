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
    $contenidoModificado = $contenido | ForEach-Object {
        if ($_ -match "FPCC") {
            "FPCASH"
        }
        else {
            $_
        }
    }
    Set-Content -Path $archivo -Value $contenidoModificado
}


#function Process-Amadeus-Files {
#    param (
#        [string]$archivo
#    )
#    $contenido = Get-Content -Path $archivo
#    $contenidoModificado = $contenido -replace "FPCC", "FPCASH"
#    Set-Content -Path $archivo -Value $contenidoModificado
#}



function Process-Sabre-Files {
    param (
        [string]$archivo
    )
    $contenido = Get-Content -Path $archivo
    $contenidoModificado = $contenido | ForEach-Object {
        $_ -replace "/CC\S+", "/CA"
    }
    Set-Content -Path $archivo -Value $contenidoModificado
}


#function Process-Sabre-Files {
#    param (
#        [string]$archivo
#    )
#    $contenido = Get-Content -Path $archivo
#    $contenidoModificado = $contenido -replace "/CC", "/CA"
#    Set-Content -Path $archivo -Value $contenidoModificado
#}

function Is-Amadeus {
    param (
        [string]$filePath
    )
    if (-not [string]::IsNullOrWhiteSpace($filePath) -and (Test-Path $filePath)) {
        try {
            $firstLine = Get-Content -Path $filePath -TotalCount 1
            if ($firstLine -match "^AIR-") {
                return $true
            }
        }
        catch {
            Write-Host "Error leyendo el archivo: $filePath. Detalles: $_"
        }
    }
    return $false
}

function Is-Sabre {
    param (
        [string]$filePath
    )
    if (-not [string]::IsNullOrWhiteSpace($filePath) -and (Test-Path $filePath)) {
        try {
            $firstLine = Get-Content -Path $filePath -TotalCount 1
            if ($firstLine -match "^AA") {
                return $true
            }
        }
        catch {
            Write-Host "Error leyendo el archivo: $filePath. Detalles: $_"
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
        # Verificar si el elemento es un archivo, no una carpeta
        if ($archivo.PSIsContainer) {
            Write-Host "Saltando carpeta: $($archivo.FullName)"
            continue
        }

        $filePath = $archivo.FullName 
        
        if (Is-Amadeus -filePath $filePath) {
            Process-Amadeus-Files -archivo $filePath
            Move-Item -Path $filePath -Destination $AmadeusFolder -Force
            Write-Host "Procesado y movido (Amadeus): $($archivo.Name)"
        }
        elseif (Is-Sabre -filePath $filePath) {
            Process-Sabre-Files -archivo $filePath
            Move-Item -Path $filePath -Destination $SabreFolder -Force
            Write-Host "Procesado y movido (Sabre): $($archivo.Name)"
        }
        else {
            Write-Host "No se pudo determinar si el archivo es de Amadeus o Sabre: $($archivo.Name)"
        }
    }
}

Write-Host "Procesando PNRs"

# Verifico carpetas
Verify-Folder $OriginFolder
Verify-Folder $AmadeusFolder
Verify-Folder $SabreFolder

# Acá empiezo a procesar
Process-Files -OriginFolder $OriginFolder -AmadeusFolder $AmadeusFolder -SabreFolder $SabreFolder

Write-Host "Proceso completado."
