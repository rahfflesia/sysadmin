function Check-WindowsFeature {
    [CmdletBinding()]
    param(
        [Parameter(Position=0,Mandatory=$true)] [string]$FeatureName 
    )  
    if((Get-WindowsOptionalFeature -FeatureName $FeatureName -Online).State -eq "Enabled") {
        return $true
    }else{
        return $false
    }
}

if(-not(Check-WindowsFeature "Web-Server")){
    Install-WindowsFeature Web-Server -IncludeManagementTools
}

if(-not(Check-WindowsFeature "Web-Ftp-Server")){
    Install-WindowsFeature Web-Ftp-Server -IncludeAllSubFeature
}

if(-not(Check-WindowsFeature "Web-Basic-Auth")){
    Install-WindowsFeature Web-Basic-Auth
}

Import-Module WebAdministration

$ADSI = [ADSI]"WinNT://$env:ComputerName"

function Crear-Ruta([String]$ruta){
    if(!(Test-Path $ruta)){
        mkdir $ruta
    }
}

function Crear-SitioFTP([String]$nombreSitio, [Int]$puerto = 21, [String]$rutaFisica){
    New-WebFtpSite -Name $nombreSitio -Port $puerto -PhysicalPath $rutaFisica -Force
    return $nombreSitio
}

function Crear-Grupo([String]$nombreGrupo, [String]$descripcion){
    # Creación del grupo
    $FTPUserGroupName = $nombreGrupo
    $FTPUserGroup = $ADSI.Create("Group", "$FTPUserGroupName")
    $FTPUserGroup.SetInfo()
    $FTPUserGroup.Description = $descripcion
    $FTPUserGroup.SetInfo()
    return $nombreGrupo
}

function Crear-Usuario([String]$nombreUsuario, [String]$contrasena){
    # Creación del usuario
    $FTPUserName = $nombreUsuario
    $FTPPassword = $contrasena
    $CreateUserFTPUser = $ADSI.Create("User", "$FTPUserName")
    $CreateUserFTPUser.SetInfo()
    $CreateUserFTPUser.SetPassword("$FTPPassword")
    $CreateUserFTPUser.SetInfo()
}

function Agregar-UsuarioAGrupo([String]$nombreUsuario, [String]$nombreGrupo){
    # Unión de los usuarios al grupo FTP
    $UserAccount = New-Object System.Security.Principal.NTAccount("$nombreUsuario")
    $SID = $UserAccount.Translate([System.Security.Principal.SecurityIdentifier])
    $Group = [ADSI]"WinNT://$env:ComputerName/$nombreGrupo,Group"
    $User = [ADSI]"WinNT://$SID"
    $Group.Add($User.Path)
}

function Habilitar-Autenticacion(){
    Set-ItemProperty "IIS:\Sites\FTP" -Name ftpServer.Security.authentication.basicAuthentication.enabled -Value $true
}

function Agregar-Permisos([String]$nombreGrupo, [Int]$numero = 3, [String]$nombreSitio){
    Add-WebConfiguration "/system.ftpServer/security/authorization" -value @{accessType="Allow";roles="$nombreGrupo";permissions=$numero} -PSPath IIS:\ -location $nombreSitio
}

function Habilitar-SSL(){
    Set-ItemProperty "IIS:\Sites\FTP" -Name ftpServer.security.ssl.controlChannelPolicy -Value 0
    Set-ItemProperty "IIS:\Sites\FTP" -Name ftpServer.security.ssl.dataChannelPolicy -Value 0
}

function Reiniciar-Sitio(){
    Restart-WebItem "IIS:\Sites\FTP"
}

# Primera versión funcional del script, si ocurre cualquier error puedo volver a este commit
$rutaRaiz = "C:\FTP"
$rutaFisica = "C:\FTP\"

Crear-Ruta $rutaRaiz
$nombreSitio = Crear-SitioFTP "FTP" 21 $rutaFisica
Habilitar-SSL

if(!(Get-LocalGroup -Name "reprobados")){
   $nombre = Crear-Grupo -nombreGrupo "reprobados" -descripcion "Grupo FTP de reprobados"
   Agregar-Permisos -nombreGrupo $nombre -numero 3 -nombreSitio $nombreSitio
}

if(!(Get-LocalGroup -Name "recursadores")){
    $nombre = Crear-Grupo -nombreGrupo "recursadores" -descripcion "Grupo FTP de recursadores"
    Agregar-Permisos -nombreGrupo $nombre -numero 3 -nombreSitio $nombreSitio
}

# Habilitar autenticacion básica
Habilitar-Autenticacion

while($true){
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
                try{
                    $usuario = Read-Host "Ingresa el nombre de usuario"
                    $password = Read-Host "Ingresa la contrasena" -AsSecureString
                    $grupo = Read-Host "Ingresa el grupo al que pertenecera el usuario"
                    Crear-Usuario -nombreUsuario $usuario -contrasena $password
                    Agregar-UsuarioAGrupo -nombreUsuario $usuario -nombreGrupo $grupo
                    Reiniciar-Sitio
                }
                catch{
                    echo $Error[0]
                }
            }
            2 {
                $usuarioACambiar = Read-Host "Ingresa el usuario a cambiar de grupo"
                $grupo = Read-Host "Ingresa el nuevo grupo del usuario"
            }
            default {"Ingresa un numero dentro del rango (1..3)"}
        }
    }
    echo `n
}