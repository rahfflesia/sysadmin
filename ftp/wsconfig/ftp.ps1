# Script 100% funcional
# Ambos scripts funcionan, cualquier caso puedo volver a este commit
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

function Crear-Ruta([String]$ruta){
    if(!(Test-Path $ruta)){
        mkdir $ruta
    }
}

function Crear-SitioFTP([String]$nombreSitio, [Int]$puerto = 21, [String]$rutaFisica){
    New-WebFtpSite -Name $nombreSitio -Port $puerto -PhysicalPath $rutaFisica -Force
    return $nombreSitio
}

function Get-ADSI(){
    return [ADSI]"WinNT://$env:ComputerName"
}

Function Validar-Contrasena {
    param (
        [string]$Contrasena
    )

    $longitudMinima = 8
    $regexMayuscula = "[A-Z]"
    $regexMinuscula = "[a-z]"
    $regexNumero = "[0-9]"
    $regexEspecial = "[!@#$%^&*()\-+=]"

    if ($Contrasena.Length -lt $longitudMinima) {
        return $false
    }

    if ($Contrasena -notmatch $regexMayuscula) {
        return $false
    }

    if ($Contrasena -notmatch $regexMinuscula) {
        return $false
    }

    if ($Contrasena -notmatch $regexNumero) {
        return $false
    }

    if ($Contrasena -notmatch $regexEspecial) {
        return $false
    }

    return $true
}

function Crear-Grupo([String]$nombreGrupo, [String]$descripcion){
    # Creación del grupo
    $FTPUserGroupName = $nombreGrupo
    $ADSI = Get-ADSI
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
    $ADSI = Get-ADSI
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

function Agregar-Permisos([String]$nombreGrupo, [Int]$numero = 3, [String]$carpetaSitio){
    Add-WebConfiguration "/system.ftpServer/security/authorization" -value @{accessType="Allow";roles="$nombreGrupo";permissions=$numero} -PSPath IIS:\ -location "FTP/$carpetaSitio"
}

function Deshabilitar-SSL(){
    Set-ItemProperty "IIS:\Sites\FTP" -Name ftpServer.security.ssl.controlChannelPolicy -Value 0
    Set-ItemProperty "IIS:\Sites\FTP" -Name ftpServer.security.ssl.dataChannelPolicy -Value 0
}

function Habilitar-SSL(){
    $numeroCert = "96D9BFD93676F3BC2E9F54D9138C4C92801EB6DD"
    Set-ItemProperty "IIS:\Sites\FTP" -Name ftpServer.security.ssl.controlChannelPolicy -Value "SslAllow"
    Set-ItemProperty "IIS:\Sites\FTP" -Name ftpServer.security.ssl.dataChannelPolicy -Value "SslAllow"
    Set-ItemProperty "IIS:\Sites\FTP" -Name ftpServer.security.ssl.serverCertHash -Value $numeroCert
    Set-ItemProperty "IIS:\Sites\FTP" -Name ftpServer.security.ssl.controlChannelPolicy -Value "SslRequire"
    Set-ItemProperty "IIS:\Sites\FTP" -Name ftpServer.security.ssl.dataChannelPolicy -Value "SslRequire"
}

function Reiniciar-Sitio(){
    Restart-WebItem "IIS:\Sites\FTP"
}

function Habilitar-AccesoAnonimo(){
    Set-ItemProperty "IIS:\Sites\FTP" -Name ftpServer.security.authentication.anonymousAuthentication.enabled -Value $true
}

# Primera versión funcional del script, si ocurre cualquier error puedo volver a este commit
$rutaRaiz = "C:\FTP"
$rutaFisica = "C:\FTP\"

Crear-Ruta $rutaRaiz
Crear-SitioFTP -nombreSitio "FTP" -puerto 21 -rutaFisica $rutaFisica

Set-ItemProperty "IIS:\Sites\FTP" -Name ftpServer.userIsolation.mode -Value 3

if(!(Get-LocalGroup -Name "reprobados")){
   Crear-Grupo -nombreGrupo "reprobados" -descripcion "Grupo FTP de reprobados"
}

if(!(Get-LocalGroup -Name "recursadores")){
    Crear-Grupo -nombreGrupo "recursadores" -descripcion "Grupo FTP de recursadores"
}

# Habilitar autenticacion básica
Habilitar-Autenticacion
Habilitar-AccesoAnonimo

Add-WebConfiguration "/system.ftpServer/security/authorization" -PSPath "IIS:\Sites\FTP" -Value @{accessType="Allow"; users="*"; permissions="Read, Write"}
icacls "C:\FTP\LocalUser\Public\General" /grant "IIS_IUSRS:(R)"

$opcSsl = Read-Host "Desea activar SSL?"

if($opcSsl.ToLower() -eq "si"){
    echo "Habilitando SSL..."
    Habilitar-SSL
    Reiniciar-Sitio
}
elseif($opcSsl.ToLower() -eq "no"){
    echo "SSL no se habilitara"
    Deshabilitar-SSL
    Reiniciar-Sitio
}
else{
    echo "Selecciona una opcion valida (si/no)"
}

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
                    $password = Read-Host "Ingresa la contrasena"
                    $grupo = Read-Host "Ingresa el grupo al que pertenecera el usuario (reprobados/recursadores)"
                    if (($grupo.ToLower() -ne "reprobados" -and $grupo.ToLower() -ne "recursadores") -or
                    ([String]::IsNullOrEmpty($usuario)) -or
                    ([String]::IsNullOrEmpty($grupo)) -or
                    ([String]::IsNullOrEmpty($password))) {
                    
                        echo "El grupo es invalido, el usuario ya existe o algunos de los campos son nulos o vacíos"
                    }
                    elseif((Get-LocalUser -Name $usuario -ErrorAction SilentlyContinue)){
                        echo "El usuario ya existe"
                    }
                    elseif ($usuario.length -gt 20){
                        echo "El nombre de usuario excede el maximo de caracteres permitido para un usuario"
                    }
                    else{
                        if(-not(Validar-Contrasena -Contrasena $password)){
                            echo "La contraseña no cumple con los lineamientos de seguridad, debe contener al menos una mayuscula, una minuscula, 8 caracteres, un caracter especial y un numero"
                        }
                        else{
                            Crear-Usuario -nombreUsuario $usuario -contrasena $password
                            Agregar-UsuarioAGrupo -nombreUsuario $usuario -nombreGrupo $grupo
                            mkdir "C:\FTP\LocalUser\$usuario"
                            mkdir "C:\FTP\Usuarios\$usuario"
                            icacls "C:\FTP\LocalUser\$usuario" /grant "$($usuario):(OI)(CI)F"
                            icacls "C:\FTP\$grupo" /grant "$($grupo):(OI)(CI)F"
                            icacls "C:\FTP\General" /grant "$($usuario):(OI)(CI)F"
                            icacls "C:\FTP\$grupo" /grant "$($usuario):(OI)(CI)F"
                            New-Item -ItemType Junction -Path "C:\FTP\LocalUser\$usuario\General" -Target "C:\FTP\General"
                            icacls "C:\FTP\LocalUser\$usuario\General" /grant "$($usuario):(OI)(CI)F"
                            New-Item -ItemType Junction -Path "C:\FTP\LocalUser\$usuario\$usuario" -Target "C:\FTP\Usuarios\$usuario"
                            icacls "C:\FTP\LocalUser\$usuario\$usuario" /grant "$($usuario):(OI)(CI)F"
                            New-Item -ItemType Junction -Path "C:\FTP\LocalUser\$usuario\$grupo" -Target "C:\FTP\$grupo"
                            icacls "C:\FTP\LocalUser\$usuario\$grupo" /grant "$($usuario):(OI)(CI)F"
                            Reiniciar-Sitio
                            echo "Usuario creado exitosamente"
                        }
                    }
                }
                catch{
                    echo $Error[0].ToString()
                }
            }
            2 {
                try{
                    $usuarioACambiar = Read-Host "Ingresa el usuario a cambiar de grupo"
                    try{
                        $mostrarGrupo = Get-LocalGroup | Where-Object { (Get-LocalGroupMember -Group $_.Name).Name -match "\\$usuarioACambiar$"} | Select-Object -ExpandProperty Name
                        echo "Grupo actual de $usuarioACambiar -> $mostrarGrupo"
                    }
                    catch{
                        $Error[0].ToString()
                    }
                    $grupo = Read-Host "Ingresa el nuevo grupo del usuario"
                    if (($grupo.ToLower() -ne "reprobados" -and $grupo.ToLower() -ne "recursadores") -or
                    [String]::IsNullOrEmpty($usuarioACambiar) -or
                    [String]::IsNullOrEmpty($grupo)) {
                        echo "El grupo es inválido, el usuario no existe o algunos de los campos son nulos o contienen espacios en blanco"
                    }
                    elseif(-not (Get-LocalUser -Name $usuarioACambiar -ErrorAction SilentlyContinue)){
                        echo "El usuario no existe"
                    }
                    elseif ($usuarioACambiar.length -gt 20){
                        echo "El nombre de usuario excede el maximo de caracteres permitido para un usuario"
                    }
                    else{
                        echo "Grupo actual del usuario $usuarioACambiar -> $mostrarGrupo"
                        $grupoActual = ""
                        if($grupo.ToLower() -eq "reprobados"){
                            $grupoActual = "recursadores"
                        }
                        else{
                            $grupoActual = "reprobados"
                        }
                        Remove-LocalGroupMember -Member $usuarioACambiar -Group $grupoActual
                        rm "C:\FTP\LocalUser\$usuarioACambiar\$grupoActual" -Recurse -Force
                        Agregar-UsuarioAGrupo -nombreUsuario $usuarioACambiar -nombreGrupo $grupo
                        New-Item -ItemType Junction -Path "C:\FTP\LocalUser\$usuario\$grupo" -Target "C:\FTP\$grupo"
                        icacls "C:\FTP\LocalUser\$usuario\$grupo" /grant "$($usuario):(OI)(CI)F"
                        icacls "C:\FTP\$grupo" /grant "$($usuario):(OI)(CI)F"
                    }
                }
                catch{
                    echo $Error[0].ToString()
                }
            }
            default {"Ingresa un numero dentro del rango (1..3)"}
        }
    }
    echo `n
}