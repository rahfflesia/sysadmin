# Función para realizar un backup del registro del sistema
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
    $logDirectory = "en:APPDATA\RegistryBackup"
    $logFile = Join-Path $logDirectory "backup-registry_log.txt"
    $logEntry = "$(Get-Date) - $env:USERNAME - Backup - $backupPath"

    if(!(Test-Path $logDirectory)){
        New-Item -ItemType Directory -Path $logDirectory | Out-Null
    }
    Add-Content -Path $logFile -Value $logEntry

    # Eliminar respaldos antiguos en caso de que se requiera
    $backupCount = 10
    $backups = Get-ChildItem $backupDirectory -Filter *.reg | Sort-Object LastWriteTime -Descending
    if ($backups.Count -gt $backupCount){
        $backupsToDelete = $backups[$backupCount..($backups.Count - 1)]
        $backupsToDelete | Remove-Item -Force
    }
    # Nombre único para el archivo de backup
    $nombreArchivo = "Backup-Registry_" + (Get-Date -Format "yyyy-MM-dd_HH-mm-ss") + ".reg"
    $rutaArchivo = Join-Path -Path $rutaBackup -ChildPath $nombreArchivo
    # Backup registro del sistema y guardarlo en el archivo destino

    # Configuración de la tarea
    $Time = New-ScheduledTaskTrigger -At 02:00 -Daily
    # Acción de la tarea
    $PS = New-ScheduledTaskAction -Execute "Powershell.exe" -Argument
    "-Command `"Import-Module BackupRegistry -Force; Backup-Registry -
    rutaBackup 'D:\tmp\Backups\Registro'`""
    # Crear la tarea programada
    Register-ScheduledTask -TaskName "Ejecutar Backup del Registro del
    Sistema" -Trigger $Time -Action $PS
    
    try {
        Write-Host "Realizando backup del registro del sistema en $rutaArchivo..."
        reg export HKLM $rutaArchivo
        Write-Host "El backup del registro del sistema se ha realizado con éxito."
    }
    catch {
        Write-Host "Se ha producido un error al realizar el backup del registro del sistema: $_"
    }
}