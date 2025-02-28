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
                $grupo = Read-Host "Ingresa el grupo al que pertenecera el usuario"
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
