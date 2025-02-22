function Backup-Registry {
    Param(
        [Parameter(Mandatory = $true)]
        [string]$rutaBackup
    )
    
    # Ruta del archivo destino si no existe
    if (!(Test-Path -Path $rutaBackup)) {
        New-Item -ItemType Directory -Path $rutaBackup | Out-Null
    }
    
     # Escribir en el archivo de log
    $logDirectory = "$env:APPDATA\RegistryBackup"
    $logFile = Join-Path $logDirectory "backup-registry_log.txt"
    
    if (!(Test-Path -Path $logDirectory)) {
        New-Item -ItemType Directory -Path $logDirectory | Out-Null
    }
    
    # Agregar entrada al log
    $logEntry = "$(Get-Date) - $env:USERNAME - Backup - $rutaBackup"
    Add-Content -Path $logFile -Value $logEntry

    # Eliminar respaldos antiguos en caso de que se requiera
    $backupCount = 10
    $backups = Get-ChildItem $rutaBackup -Filter *.reg | Sort-Object LastWriteTime -Descending
    if ($backups.Count -gt $backupCount){
        $backupsToDelete = $backups[$backupCount..($backups.Count - 1)]
        $backupsToDelete | Remove-Item -Force
    }

    # Nombre del archivo de backup
    $nombreArchivo = "Backup-Registry_" + (Get-Date -Format "yyyy-MM-dd_HH-mm-ss") + ".reg"
    $rutaArchivo = Join-Path -Path $rutaBackup -ChildPath $nombreArchivo

    try {
        Write-Host "Realizando backup del registro del sistema en $rutaArchivo..."
        reg export HKLM $rutaArchivo
        Write-Host "El backup del registro del sistema se ha realizado con éxito."
    }
    catch {
        Write-Host "Se ha producido un error al realizar el backup del registro del sistema: $_"
    }
}

# Programar tarea para ejecutar el script diariamente a las 02:00 AM
# Configuracion de la tarea a las 2 am
$Time = New-ScheduledTaskTrigger -At 02:00 -Daily
# Acción a realizar
$PS = New-ScheduledTaskAction -Execute "Powershell.exe" -Argument "-File 'C:\ruta\al\script\Backup-Registry.ps1'"
# Crear la tarea programada
Register-ScheduledTask -TaskName "BackupRegistro" -Trigger $Time -Action $PS -User $env:USERNAME -RunLevel Highest -Force
