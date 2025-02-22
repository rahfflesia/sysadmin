Import-Module C:\PowerShell\sysadmin\modulosws\funcionesIp.psm1
Import-Module C:\PowerShell\sysadmin\modulosws\funcionesDominio.psm1
Import-Module C:\PowerShell\sysadmin\modulosws\funcionesPrincipales.psm1

$ip = Read-Host "Ingresa la direccion ip"
$dominio = Read-Host "Ingresa el dominio a registar"
$zonefile = $dominio + ".dns"

if((Es-IpValida -ip $ip) -and (Es-DominioValido -dominio $dominio)){
    try{
        Instalar-Dns -ip $ip -dominio $dominio -zonefile $zonefile
    }
    catch{
        echo "Ha ocurrido un error, verifique los datos ingresados"
    }
}
else{
    echo "Has ingresado una ip o dominio con el formato incorrecto"
}