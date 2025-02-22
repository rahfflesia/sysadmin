# PowerShell nos proporciona distintos comandos para gestionar servicios
# El mas elemental es Get-Service
Get-Service
# Para filtrar por nombre
Get-Service -Name Spooler
# Para filtrar por palabras clave
Get-Service -DisplayName Hora*
# Para filtrar por algunas de sus propiedades
Get-Service | Where-Object {$_.Status -eq "Running"}
# Filtrado por la propiedad StartType
Get-Service | Where-Object {$_.StartType -eq "Automatic"} | Select-Object Name,StartType
# Get-Service también nos permite buscar que servicios dependen del servicio que indicamos
Get-Service -DependentServices Spooler
# También podemos filtrar por los servicios de los que depende el servicio que indicamos
Get-Service -RequiredServices Fax

# Stop Service
# Detén el servicio spooler, pide la confirmación del usuario y retorna el objeto del servicio iniciado
# No funciona en algunos servicios que están programados para reiniciarse automáticamente al ser detenidos
Stop-Service -Name Spooler -Confirm -PassThru

# Start Service
# Nos permite iniciar el servicio especificado
# Funciona de manera similar a stop service pero con el efecto inverso
Start-Service -Name Spooler -Confirm -PassThru

# Suspend service
# Nos permite detener un servicio de manera temporal, no definitivamente como stop-service
Suspend-Service -Name stisvc -Confirm -PassThru
# No todos los servicios pueden suspenderse
# Para verificar cuales pueden serlo usamos:
Get-Service | Where-Object CanPauseAndContinue -eq True

# Reiniciar servicio
Restart-Service -Name WSearch -Confirm -PassThru

# Set-Service
# Nos permite cambiar la configuración de un servicio
Set-Service -Name dcsvc -DisplayName "Servicio de virtualización de credenciales de seguridad distribuidas"

# Procesos
# Obtener los procesos en ejecución
Get-Process
# Podemos especificar un id del proceso o un procesname
Get-Process -Name Search*
Get-Process -Id 1

# Sirve para detener procesos, funciona igual que los cmdlets de servicios
Stop-Process -Name Acrobat | Stop-Process -Confirm -PassThru

# Nos permite iniciar un nuevo proceso
# Podemos pasar la ruta completa del proceso a iniciar con -FilePath
# PassThru retorna el objeto que se inició
Start-Process -FilePath "C:\Windows\System32\notepad.exe" -PassThru

# Sirve para esperar que un proceso en ejecución se detenga
Wait-Process -Name notepad

# Administración de usuarios y grupos
# Proporciona información detallada de los usuarios locales del equipo
Get-LocalUser

# Información detallada de los grupos locales del equipo
Get-LocalGroup

# Crear una cuenta de usuario local
New-LocalUser -Name "Dummy" -Description "Cuenta dummy" -NoPassword

# Remover usuarios
Remove-LocalUser -Name "Dummy"

# Crear nuevo grupo local
New-LocalGroup -Name "Grupo1" -Description "Grupo de prueba 1"

# Agregar miembro a grupo local
Add-LocalGroupMember -Group "Grupo1" -Member "Usuario2" -Verbose

# Retorna los usuarios del grupo especificado
Get-LocalGroupMember "Grupo1"

# Remueve usuario del grupo especificado
Remove-LocalGroupMember -Group "Grupo1" -Member "Usuario2"

# Remover el grupo especificado
Remove-LocalGroup -Group "Grupo1"


