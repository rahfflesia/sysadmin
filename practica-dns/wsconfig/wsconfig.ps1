$ip = Read-Host "Ingresa la direccion ip"
$dominio = Read-Host "Ingresa el dominio a registar"
#$ip = (Get-NetIpAddress -InterfaceIndex 6 -AddressFamily IPv4).IPAddress
$zonefile = $dominio + ".dns"

function Es-IpValida{
    Param([Parameter(Mandatory)][string]$ip)
    forEach($byte in $ip.Split(".")){
        if($byte -gt 255){
            return $false
        }
    }
    return $true
}

function Es-DominioValido($dominio){
    return $dominio -match "^[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9](?:\.[a-zA-Z]{2,})+$"
}

if((Es-IpValida -ip $ip) -and (Es-DominioValido -dominio $dominio)){
    try{
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
    echo "Datos correctos"
}
else{
    echo "Has ingresado una ip o dominio con el formato incorrecto"
}

