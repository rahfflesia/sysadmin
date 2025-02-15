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

function Es-IpValida {
    Param([Parameter(Mandatory)][string]$ip)
    return $ip -match "^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"
}

function Es-ConfiguracionValida($ipInicial, $ipFinal, $mascara, $dns, $gateway){
    return (Es-IpValida -ip $ipInicial) -and (Es-IpValida -ip $ipFinal) -and (Es-IpValida -ip $mascara) -and (Es-IpValida -ip $dns) -and (Es-IpValida -ip $gateway) 
}

$nombreAmbito = Read-Host "Ingresa el nombre del ambito "
$ipInicial = Read-Host "Ingresa la ip inicial "
$ipFinal = Read-Host "Ingresa la ip final "
$mascara = Read-Host "Ingresa la mascara de subred "
$dns = Read-Host "Ingresa el servidor DNS "
$gateway = Read-Host "Ingresa la puerta de enlace "

if(Es-ConfiguracionValida -ipInicial $ipInicial -ipFinal $ipFinal -mascara $mascara -dns $dns -gateway $gateway){
    try{
        # Instalo el servicio de DHCP
        Install-WindowsFeature -Name DHCP
        # Instalo las herramientas de gestión del servidor
        Install-WindowsFeature -Name RSAT-DHCP
        # Agrego el ámbito
        Add-DhcpServerv4Scope -Name $nombreAmbito -StartRange $ipInicial -EndRange $ipFinal -SubnetMask $mascara
        # Cálculo la ip base, es decir la ip con formato x.x.x.0, ejemplo -> ip: 192.168.1.100, ip base: 192.168.1.0
        $ipBase = (Get-DhcpServerv4Scope).ScopeId.IPAddressToString
        # Cálculo la ip estática del dhcp en mi caso asigno la segunda ip x.x.x.2
        $ipDhcp = (Get-DhcpIp -Ip $ipBase)
        # Lo activo
        Set-DhcpServerv4Scope -ScopeId $ipBase -State Active
        # Muestro el ámbito que creé recientemente
        Get-DhcpServerv4Scope
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
        # Configuración NAT para que los clientes tengan acceso a internet
        New-NetNat -Name $natNombre.toString() -InternalIPInterfaceAddressPrefix "$ipBase/$bits" # El prefijo debe de ser el ScopeId del servidor o la ip con terminacion en cero x.x.0.0 por ejemplo
    }
    catch{
        echo "Ha ocurrido un error"
    }
}
else {
    echo "Alguno de los parametros es invalido, verifique los datos ingresados"
}
