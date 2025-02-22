Import-Module C:\PowerShell\sysadmin\modulosws\funcionesIp.psm1
Import-Module C:\PowerShell\sysadmin\modulosws\funcionesPrincipales.psm1

$nombreAmbito = Read-Host "Ingresa el nombre del ambito "
$ipInicial = Read-Host "Ingresa la ip inicial "
$ipFinal = Read-Host "Ingresa la ip final "
$mascara = Read-Host "Ingresa la mascara de subred "
$dns = Read-Host "Ingresa el servidor DNS "
$gateway = Read-Host "Ingresa la puerta de enlace "
$ipDhcp = Read-Host "Ingresa la ip que tendra el servidor DHCP "

if(Es-ConfiguracionValida -ipInicial $ipInicial -ipFinal $ipFinal -mascara $mascara -dns $dns -gateway $gateway -ipDhcp $ipDhcp){
    try{
        Configurar-Dhcp $nombreAmbito $ipInicial $ipFinal $mascara $ipDhcp $dns $gateway
    }
    catch{
        echo $Error
    }
}
else {
    echo "Alguno de los parametros es invalido, verifique los datos ingresados"
}