function Check-WindowsFeature {
    [CmdletBinding()]
    param(
        [Parameter(Position=0,Mandatory=$true)] [string]$FeatureName 
    )  
  if((Get-WindowsOptionalFeature -FeatureName $FeatureName -Online).State -eq "Enabled") {
        return $true
    } else {
        return $false
    }
}

if(-not(Check-WindowsFeature "Web-FTP-Server") -and -not(Check-WindowsFeature "Web-Server") -and -not(Check-WindowsFeature "Web-Basic-Auth")){
    Install-WindowsFeature Web-FTP-Server -IncludeAllSubFeature
    Install-WindowsFeature Web-Server -IncludeAllSubFeature -IncludeManagementTools
    Install-WindowsFeature Web-Basic-Auth
}

function crearGrupo([string]$nombreGrupo){
    if(-not(Get-LocalGroup -Name $nombreGrupo)){
        New-LocalGroup -Name $nombreGrupo -Description "Grupo FTP de $nombreGrupo"
    }
}

Import-Module WebAdministration

function Crear-SitioFtp([string]$nombreSitio, [int]$puerto = 21, [string]$ruta) {
    New-WebFtpSite -Name $nombreSitio -Port $puerto -PhysicalPath $ruta -Force
}

crearGrupo -nombreGrupo "reprobados"
crearGrupo -nombreGrupo "recursadores"

$rutaGeneral = "C:\FTP\General"
$rutaReprobados = "C:\FTP\Reprobados"
$rutaRecursadores = "C:\FTP\Recursadores"

if(!(Test-Path $rutaGeneral)){
    New-Item -ItemType Directory -Path $rutaGeneral
}

if(!(Test-Path $rutaReprobados)){
    New-Item -ItemType Directory -Path $rutaReprobados
}

if(!(Test-Path $rutaRecursadores)){
    New-Item -ItemType Directory -Path $rutaRecursadores
}

Crear-SitioFtp -nombreSitio "ServidorFTP" -ruta $rutaGeneral

$rutaSitioFtp = "IIS:\Sites\ServidorFTP"
Set-ItemProperty -Path $rutaSitioFtp -Name "ftpServer.security.authentication.anonymousAuthentication.enabled" -Value $true

function Establecer-Permisos([string]$ruta, [string]$grupo) {
    try {
        $grupoCompleto = "$env:ComputerName\$grupo"
        $acl = Get-Acl $ruta

        $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            $grupoCompleto,
            "Modify",            
            "ContainerInherit,ObjectInherit",
            "None",              
            "Allow"
        )

        $acl.AddAccessRule($accessRule)

        Set-Acl -Path $ruta -AclObject $acl

        Write-Host "Permisos establecidos correctamente para el grupo '$grupo' en la ruta '$ruta'."
    }
    catch {
        Write-Host "Ocurrió un error al establecer permisos: $_"
    }
}

Establecer-Permisos -ruta $rutaGeneral -grupo "Everyone"
Establecer-Permisos -ruta $rutaReprobados -grupo "reprobados"
Establecer-Permisos -ruta $rutaRecursadores -grupo "recursadores"

function Crear-UsuarioFtp([string]$usuario, [string]$contrasena, [string]$grupo) {
    $passwordSecure = ConvertTo-SecureString -String $contrasena -AsPlainText -Force
    New-LocalUser -Name $usuario -Password $passwordSecure -FullName $usuario -Description "Usuario FTP"
    Add-LocalGroupMember -Group $grupo -Member $usuario
}

Crear-UsuarioFtp -usuario "usuario1" -contrasena "#password222#" -grupo "reprobados"
Crear-UsuarioFtp -usuario "usuario2" -contrasena "#password222#" -grupo "recursadores"

Restart-WebItem "IIS:\Sites\ServidorFTP"

<#while($true){
    echo "Menu"
    echo "1. Agregar usuario"
    echo "2. Cambiar usuario de grupo"
    echo "3. Salir"

    try{
        $opcion = Read-Host "Selecciona una opcion"
        $intOpcion = [int]$opcion
    }
    catch{
        echo "Has ingresado un valor no entero"
    }

    if($intOpcion -eq 3){
        echo "Saliendo..."
        break
    }

    if($intOpcion -is [int]){
        switch($opcion){
            1 {
                $usuario = Read-Host "Ingresa el nombre de usuario"
                $password = Read-Host "Ingresa la contrasena" -AsSecureString
                $grupo = Read-Host "Ingresa el grupo al que pertenecera el usuario (reprobados/recursadores)"
            }
            2 {
                $usuarioACambiar = Read-Host "Ingresa el usuario a cambiar de grupo"
                $grupo = Read-Host "Ingresa el nuevo grupo del usuario"
            }
            default {"Ingresa un numero dentro del rango (1..3)"}
        }
    }
    echo `n
}#>
