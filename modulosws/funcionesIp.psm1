function Es-IpValida {
    Param([Parameter(Mandatory)][string]$ip)
    return $ip -match "^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"
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

function Es-ConfiguracionValida($ipInicial, $ipFinal, $mascara, $dns, $gateway, $ipDhcp){
    return (Es-IpValida -ip $ipInicial) -and (Es-IpValida -ip $ipFinal) -and (Es-IpValida -ip $mascara) -and (Es-IpValida -ip $dns) -and (Es-IpValida -ip $gateway) -and (Es-IpValida -ip $ipDhcp)
}