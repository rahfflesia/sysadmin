$ADSI = [ADSI]"WinNT://$env:ComputerName"

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

if(-not(Check-WindowsFeature "Web-FTP-Server") -and -not(Check-WindowsFeature "Web-Server")){
    Install-WindowsFeature Web-FTP-Server -IncludeAllSubFeature
    Install-WindowsFeature Web-Server -IncludeAllSubFeature -IncludeManagementTools
}

Import-Module WebAdministration

function Crear-SitioFtp([string]$nombreSitio, [int]$puerto = 21, [string]$ruta){
    New-WebFtpSite -Name $nombreSitio -Port $puerto -PhysicalPath $ruta -Force
    return $nombreSitio
}

function Crear-Grupo([string]$nombreGrupo, [string]$descripcion){
    if(-not(Get-LocalGroup -Name $nombreGrupo)){
        $grupoUsuarios = $ADSI.Create("Group", "$nombreGrupo")
        $grupoUsuarios.SetInfo()
        $grupoUsuarios.Description = $descripcion
        $grupoUsuarios.SetInfo()
    }
}

function Crear-UsuarioFtp([string]$usuario, [string]$contrasena){
    $usuarioFtp = $ADSI.Create("User", "$usuario")
    $usuarioFtp.SetInfo()
    $usuarioFtp.SetPassword("$contrasena")
    $usuarioFtp.SetInfo()
}

function Agregar-UsuarioAGrupoFTP([string]$usuario, [string]$nombreGrupo){
    $cuentaUsuario = New-Object System.Security.Principal.NTAccount("$usuario")
    $SID = $cuentaUsuario.Translate([System.Security.Principal.SecurityIdentifier])
    $grupo = [ADSI]"WinNT://$env:ComputerName/$nombreGrupo,Group"
    $user = [ADSI]"WinNT://$SID"
    $grupo.Add($user.Path)
}

function Habilitar-Autenticacion([string]$nombreSitio, [string]$nombreGrupo){
    $rutaSitioFtp = "IIS:\Sites\$nombreSitio"
    $basicAuth = "ftpServer.security.authentication.basicAuthentication.enabled"
    Set-ItemProperty -Path $rutaSitioFtp -Name $basicAuth -Value $True

    $Param = @{
        Filter = "/system.ftpServer/security/authorization"
        Value = @{
            accessType = "Allow"
            roles = "$nombreGrupo"
            permissions = 3
        }
        PSPath = "IIS:\"
        Location = $nombreSitio
    }
    Add-WebConfiguration @param
}

function Permitir-SSL([string]$rutaSitioFtp){
    $SSLPolicy = @(
        "ftpServer.security.ssl.controlChannelPolicy",
        "ftpServer.security.ssl.dataChannelPolicy"
    )
    Set-ItemProperty -Path $rutaSitioFtp -Name $SSLPolicy[0] -Value $false
    Set-ItemProperty -Path $rutaSitioFtp -Name $SSLPolicy[1] -Value $false
}

function Establecer-PermisosNtfs([string]$rutaSitio, [string]$nombreGrupo, [string]$nombreSitio){
    $cuentaUsuario = New-Object System.Security.Principal.NTAccount("$nombreGrupo")
    $reglaDeAcceso = [System.Security.AccessControl.FileSystemAccessRule]::new($cuentaUsuario,
        "ReadAndExecute",
        "ContainerInherit,ObjectInherit",
        "None",
        "Allow"
    )
    $ACL = Get-Acl -Path $rutaSitio
    $ACL.SetAccessRule($reglaDeAcceso)
    $ACL | Set-Acl -Path $rutaSitio
    Restart-WebItem "IIS:\Sites\$nombreSitio" -Verbose
}

# Variables globales de configuracion
$nombreSitio = "Servidor FTP"
$rutaFisicaFTP = "C:\Users\Administrador\Servidor-FTP\Publica"
$rutaSitioIIS = "IIS:\Sites\$nombreSitio"
Crear-SitioFtp -nombreSitio $nombreSitio -ruta $rutaFisicaFTP
Crear-Grupo -nombreGrupo "reprobados" -descripcion "Grupo FTP de reprobados"
Crear-Grupo -nombreGrupo "recursadores" -descripcion "Grupo FTP de recursadores"

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
                $usuario = Read-Host "Ingresa el nombre de usuario"
                $password = Read-Host "Ingresa la contrasena" -AsSecureString
                $grupo = Read-Host "Ingresa el grupo al que pertenecera el usuario (reprobados/recursadores)"
                try{
                    Crear-UsuarioFtp -usuario $usuario -contrasena $password
                    Agregar-UsuarioAGrupoFTP -usuario $usuario -nombreGrupo $grupo
                    Habilitar-Autenticacion -nombreSitio $nombreSitio -nombreGrupo $grupo
                    Permitir-SSL -rutaSitioFtp $rutaSitioIIS
                    Establecer-PermisosNtfs -rutaSitio $rutaFisicaFTP -nombreGrupo $grupo -nombreSitio $nombreSitio
                    echo "Configuracion establecida correctamente"
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
