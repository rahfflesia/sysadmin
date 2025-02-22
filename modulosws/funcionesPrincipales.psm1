# Funcion principal del script de dns
function Instalar-Dns($ip, $dominio, $zonefile){
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

