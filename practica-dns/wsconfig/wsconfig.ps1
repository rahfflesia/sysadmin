$ip = Read-Host "Ingresa la direccion ip"
$dominio = Read-Host "Ingresa el dominio a registar"
#$ip = (Get-NetIpAddress -InterfaceIndex 6 -AddressFamily IPv4).IPAddress
$zonefile = $dominio + ".dns"

function Es-IpValida {
    Param([Parameter(Mandatory)][string]$ip)
    return $ip -match "^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"
}

function Es-DominioValido($dominio){
    return $dominio -match "^[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9](?:\.[a-zA-Z]{2,})+$"
}

if((Es-IpValida -ip $ip) -and (Es-DominioValido -dominio $dominio)){
    try{
        # Instalo servicio de DNS
        Install-WindowsFeature -Name DNS
        # Instalo RSAT de DNS
        Install-WindowsFeature -Name RSAT-DNS-Server
        Add-DnsServerPrimaryZone -Name $dominio -Zonefile $zonefile
        # Agrego -> www.dominio.com
        Add-DnsServerResourceRecordA -IPv4Address $ip -Name www -Zonename $dominio
        # Agrego -> dominio.com
        Add-DnsServerResourceRecordA -IPv4Address $ip -Name "@" -Zonename $dominio
        echo "El dominio ha sido registrado en el DNS"
    }
    catch{
        echo "Ha ocurrido un error, verifique los datos ingresados"
    }
}
else{
    echo "Has ingresado una ip o dominio con el formato incorrecto"
}

