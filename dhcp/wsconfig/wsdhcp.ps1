function Get-DhcpIp($Ip){ # Recibe una ip de tipo string con el siguiente formato -> x.x.x.x, en este caso utilizo ipBase
    $ipDhcp = ""
    $contador = 0
    forEach($byte in $ip.split(".")){
        if($contador -eq 3){
            $ipDhcp += "2"
        }
        else{
            $ipDhcp += $byte + "."
        }
        $contador++;
    }
    return $ipDhcp
}

function Get-MaskBits($Mascara){
    $prefix = 0
    forEach($byte in $mascara.split(".")){
        $binario = [Convert]::ToString($byte, 2)
        for($i = 0; $i -lt $binario.length; $i++){
            if($binario[$i] -eq "1"){
                $prefix++
            }
        }
    }
    return $prefix
}

# Instalo el servicio de DHCP
Install-WindowsFeature -Name DHCP
# Instalo las herramientas de gestión del servidor
Install-WindowsFeature -Name RSAT-DHCP

$nombreAmbito = Read-Host "Ingresa el nombre del ambito "
$ipInicial = Read-Host "Ingresa la ip inicial "
$ipFinal = Read-Host "Ingresa la ip final "
$mascara = Read-Host "Ingresa la mascara de subred "

# Agrego el ámbito
Add-DhcpServerv4Scope -Name $nombreAmbito -StartRange $ipInicial -EndRange $ipFinal -SubnetMask $mascara
# Id del ámbito
$ipBase = (Get-DhcpServerv4Scope).ScopeId.IPAddressToString
$ipDhcp = (Get-DhcpIp -Ip $ipBase)
# Lo activo
Set-DhcpServerv4Scope -ScopeId $ipBase -State Active
# Muestro el ámbito que creé recientemente
Get-DhcpServerv4Scope
# Ip del servidor dhcp dentro de la red interna, esta ip es la ip que se proporciona en la red interna y no la del adaptador puente
$bits = Get-MaskBits -Mascara $mascara
# Actualizo la ip
Remove-NetIPAddress -InterfaceAlias "Ethernet" -Confirm:$false
New-NetIpAddress -InterfaceAlias "Ethernet" -AddressFamily IPv4 -IpAddress $ipDhcp -PrefixLength $bits # Ocupo calcular el prefixLength dinamicamente
$gateway = (Get-NetIpAddress -InterfaceAlias "Ethernet" -AddressFamily IPv4).IPAddress

echo "Ip del ambito: $ipBase"
echo "Ip del servidor dhcp: $ipDhcp"
# Actualizo la ip del dhcp para que esté en la misma subred que la indicada en el ámbito
Set-DhcpServerv4OptionValue -ScopeId $ipBase -DnsServer 8.8.8.8 -Router $gateway # El router o puerta de enlace tiene que ser la ip del servidor dhcp en la red interna y no la puerta de enlace del adaptador puente
Get-DhcpServerv4Lease -ScopeId $ipBase

# Configuración NAT para que los clientes tengan acceso a internet
New-NetNat -Name "NAT Interna" -InternalIPInterfaceAddressPrefix "$ipBase/$bits" # El prefijo debe de ser el ScopeId del servidor o la ip con terminacion en cero x.x.0.0 por ejemplo
