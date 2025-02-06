$dominio = Read-Host "Ingresa el dominio a registar: "
# Ip propia dinámica
$ip = (Get-NetIpAddress -InterfaceIndex 4 -AddressFamily IPv4).IPAddress
Add-DnsServerResourceRecordA -IPv4Address $ip -Name www -Host $dominio

