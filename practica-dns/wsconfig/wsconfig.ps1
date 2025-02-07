$dominio = Read-Host "Ingresa el dominio a registar: "
# Ip propia dinámica
$ip = (Get-NetIpAddress -InterfaceIndex 6 -AddressFamily IPv4).IPAddress
$zonefile = $dominio + ".dns"
try {
    Add-DnsServerPrimaryZone -Name $dominio -Zonefile $zonefile
    Add-DnsServerResourceRecordA -IPv4Address $ip -Name www -Zonename $dominio
    echo "El dominio ha sido registrado en el DNS"
}
catch{
    echo "Ha ocurrido un error"
}

