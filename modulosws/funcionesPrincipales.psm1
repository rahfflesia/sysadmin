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

function Configurar-Dhcp($nombreAmbito, $ipInicial, $ipFinal, $mascara, $ipDhcp, $dns, $gateway){
    # Instalo el servicio de DHCP
    Install-WindowsFeature -Name DHCP
    # Instalo las herramientas de gestión del servidor
    Install-WindowsFeature -Name RSAT-DHCP
    # El rango de direcciones ip que el dhcp puede repartir empieza desde rango inicial + 1 porque reservo la primera ip para el propio servidor dhcp
    # Entonces $ipInicial es en realidad la direccion ip del servidor e ipInicial2 es de donde empiezan los rangos de ip realmente empiezan desde la segunda
    Get-DhcpServerv4Scope | ForEach-Object { Remove-DhcpServerv4Scope -ScopeId $_.ScopeId -Confirm:$false -Force} # Borro scopes anteriores, en caso de que existan
    # Agrego el ámbito
    Add-DhcpServerv4Scope -Name $nombreAmbito -StartRange $ipInicial -EndRange $ipFinal -SubnetMask $mascara
    # Obtengo la ip base, es decir la ip con formato x.x.x.0, ejemplo -> ip: 192.168.1.100, ip base: 192.168.1.0
    $ipBase = (Get-DhcpServerv4Scope).ScopeId.IPAddressToString
    # Excluyo la ip que se asigne al dhcp
    Add-DhcpServerv4ExclusionRange -ScopeId $ipBase -StartRange $ipDhcp -EndRange $ipDhcp
    # Lo activo
    Set-DhcpServerv4Scope -ScopeId $ipBase -State Active
    # Muestro el ámbito que creé recientemente
    Get-DhcpServerv4Scope -ScopeId $ipBase
    # Calculo los bits utilizados en la máscara, 255.255.255.0 -> 11111111.11111111.11111111.00000000 -> 24 bits
    $bits = Get-MaskBits -Mascara $mascara
    # Actualizo la ip
    Remove-NetIPAddress -InterfaceAlias "Ethernet" -Confirm:$false
    New-NetIpAddress -InterfaceAlias "Ethernet" -AddressFamily IPv4 -IpAddress $ipDhcp -PrefixLength $bits # Ocupo calcular el prefixLength dinamicamente
    # Muestro en consola las direcciones que generé (caracter meramente informativo)
    echo "Ip del ambito: $ipBase"
    echo "Ip del servidor dhcp: $ipDhcp"
    # Actualizo la ip del dhcp para que esté en la misma subred que la indicada en el ámbito
    Set-DhcpServerv4OptionValue -ScopeId $ipBase -DnsServer $dns -Router $gateway # El router o puerta de enlace tiene que ser la ip del servidor dhcp en la red interna y no la puerta de enlace del adaptador puente
    Get-DhcpServerv4Lease -ScopeId $ipBase
    $natNombre = Get-Random
    # Remuevo reglas nat anteriores para evitar conflictos
    Remove-NetNat -Confirm:$false
    # Configuración NAT para que los clientes tengan acceso a internet
    New-NetNat -Name $natNombre.toString() -InternalIPInterfaceAddressPrefix "$ipBase/$bits" # El prefijo debe de ser el ScopeId del servidor o la ip con terminacion en cero x.x.0.0 por ejemplo
}
