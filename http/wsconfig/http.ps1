# Ambos scripts funcionales en caso de error puedo volver a este commit
$ProgressPreference = 'SilentlyContinue'

# Script de powershell funcional, quizás falta depurarlo un poco

function Es-PuertoValido([int]$puerto) {
    $puertosReservados = @{
        20 = "FTP"
        21 = "FTP"
        22 = "SSH"
        23 = "Telnet"
        25 = "SMTP"
        53 = "DNS"
        67 = "DHCP"
        68 = "DHCP"
        80 = "HTTP"
        110 = "POP3"
        119 = "NNTP"
        123 = "NTP"
        143 = "IMAP"
        161 = "SNMP"
        162 = "SNMP"
        389 = "LDAP"
        443 = "HTTPS"
    }

    if ($puertosReservados.ContainsKey($puerto)) {
        echo "No se puede utilizar ese puerto porque está reservado para el servicio $($puertosReservados[$puerto])"
        return $false
    }
    
    return $true
}

function Es-RangoValido([int]$puerto){
    if($puerto -lt 0 -or $puerto -gt 65535){
        return $false
    }
    else{
        return $true
    }
}

function Es-PuertoEnUso([int]$puerto){
    $enUso = Get-NetTCPConnection -LocalPort $puerto -ErrorAction SilentlyContinue
    if($enUso){return $true}
    return $false
}


function Es-Numerico([string]$string){
    return $string -match "^[0-9]+$"
}

function hacerPeticion([string]$url){
    return Invoke-WebRequest -UseBasicParsing -URI $url
}

function encontrarValor([string]$regex, [string]$pagina){
    $coincidencias = [regex]::Matches($pagina, $regex) | ForEach-Object { $_.Value }
    return $coincidencias
}

function quitarPrimerCaracter([string]$string){
    $stringSinPrimerCaracter = ""
    for($i = 1; $i -lt $string.length; $i++){
        $stringSinPrimerCaracter += $string[$i]
    }
    return $stringSinPrimerCaracter
}

$versionRegex = "[0-9]+.[0-9]+.[0-9]"

while($true){
    echo "Elige el servicio a instalar"
    echo "1. IIS"
    echo "2. Caddy"
    echo "3. Nginx"
    echo "4. Salir"
    $opc = Read-Host "Selecciona una opcion"

    if($opc -eq "4"){
        echo "Saliendo..."
        break
    }

    switch($opc){
        "1"{
            if(-not(Get-WindowsFeature -Name Web-Server).Installed){
                $puerto = Read-Host "Ingresa el puerto donde se realizara la instalacion"
                if(-not(Es-Numerico -string $puerto)){
                    echo "Ingresa un valor numerico entero"
                }
                elseif(-not(Es-RangoValido $puerto)){
                    echo "Ingresa un puerto dentro del rango (0-65535)"
                }
                elseif(Es-PuertoEnUso $puerto){
                    echo "El puerto se encuentra en uso"
                }
                elseif(-not(Es-PuertoValido $puerto)){
                    echo "Error el puerto no es valido"
                }
                else{
                    Install-WindowsFeature -Name Web-Server -IncludeManagementTools
                    $opc = Read-Host "Quieres habilitar SSL? (si/no)"
                    if($opc.ToLower() -eq "si"){
                        Import-Module WebAdministration
                        $thumbprint = "96D9BFD93676F3BC2E9F54D9138C4C92801EB6DD"
                        $cert = Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object { $_.Thumbprint -eq $thumbprint }
                        New-WebBinding -Name "Default Web Site" -IP "*" -Port $puerto -Protocol https
                        $cert | New-Item -path IIS:\SslBindings\0.0.0.0!$puerto
                        netsh advfirewall firewall add rule name="IIS" dir=in action=allow protocol=TCP localport=$puerto
                        echo "IIS Se ha instalado correctamente"
                    }
                    elseif($opc.ToLower() -eq "no"){
                        Set-WebBinding -Name "Default Web Site" -BindingInformation "*:80:" -PropertyName "bindingInformation" -Value ("*:" + $puerto + ":")
                        netsh advfirewall firewall add rule name="IIS" dir=in action=allow protocol=TCP localport=$puerto
                        iisreset
                        echo "IIS Se ha instalado correctamente"
                    }
                    else{
                        echo "Selecciona una opcion valida (si/no)"
                    }
                }
            }
            else{
                echo "IIS ya se encuentra instalado"
            }
        }
        "2"{
            $objetosCaddy = Invoke-RestMethod "https://api.github.com/repos/caddyserver/caddy/releases"
            $versionesCaddy = $objetosCaddy
            $versionDesarrolloCaddy = $versionesCaddy[0].tag_name
            $versionLTSCaddy = $versionesCaddy[6].tag_name


            echo "Instalador de Caddy"
            echo "1. Version LTS $versionLTSCaddy"
            echo "2. Version de desarrollo $versionDesarrolloCaddy"
            echo "3. Salir"
            $opcCaddy = Read-Host "Selecciona una version"
            switch($opcCaddy){
                "1"{
                    try{
                        $puerto = Read-Host "Ingresa el puerto donde se realizara la instalacion"
                        if(-not(Es-Numerico -string $puerto)){
                            echo "Ingresa un valor numerico entero"
                        }
                        elseif(-not(Es-RangoValido $puerto)){
                            echo "Ingresa un puerto dentro del rango (0-65535)"
                        }
                        elseif(Es-PuertoEnUso $puerto){
                            echo "El puerto se encuentra en uso"
                        }
                        elseif(-not(Es-PuertoValido $puerto)){
                            echo "Error"
                        }
                        else{
                            $opcCaddy = Read-Host "Quieres activar SSL? (si/no)"
                            Stop-Process -Name caddy -ErrorAction SilentlyContinue
                            $versionSinV = quitarPrimerCaracter -string $versionLTSCaddy
                            echo $versionSinV
                            echo "Instalando version LTS $versionLTSCaddy"
                            Invoke-WebRequest -UseBasicParsing "https://github.com/caddyserver/caddy/releases/download/$versionLTSCaddy/caddy_${versionSinV}_windows_amd64.zip" -Outfile "C:\descargas\caddy-$versionLTSCaddy.zip"
                            Expand-Archive C:\descargas\caddy-$versionLTSCaddy.zip C:\descargas -Force
                            cd C:\descargas
                            New-Item c:\descargas\Caddyfile -type file -Force
                            if($opcCaddy.ToLower() -eq "si"){
                                echo "Habilitando SSL..."
                                Clear-Content -Path "C:\descargas\Caddyfile"
                                Set-Content -Path "C:\descargas\Caddyfile" -Value @"
{
    auto__https disable_redirects
    debug
}

https://192.168.100.38:$puerto {
    root * "C:\MiSitio"
    file_server
    tls C:\Descargas\certificate.crt C:\Descargas\private_decrypted.key
}
"@
                            }
                            elseif($opcCaddy.ToLower() -eq "no"){
                                Clear-Content -Path "C:\descargas\Caddyfile"
                                echo "SSL no sera habilitado..."
                                Set-Content -Path "C:\descargas\Caddyfile" -Value @"
:$puerto {
    root * "C:\MiSitio"
    file_server
}
"@
                            }
                            else{
                                echo "Selecciona una opcion valida (si/no)"
                            }
                            Start-Process -NoNewWindow -FilePath "C:\descargas\caddy.exe" -ArgumentList "run --config C:\descargas\Caddyfile"
                            Get-Process | Where-Object { $_.ProcessName -like "*caddy*" }
                            Select-String -Path "C:\descargas\Caddyfile" -Pattern ":$puerto"
                            netsh advfirewall firewall add rule name="Caddy" dir=in action=allow protocol=TCP localport=$puerto
                            echo "Se instalo la version LTS $versionLTSCaddy de Caddy"
                        }
                    }
                    catch{
                        echo $Error[0].ToString()
                    }
                }
                "2"{
                    try{
                        $puerto = Read-Host "Ingresa el puerto donde se realizara la instalacion"
                        if(-not(Es-Numerico -string $puerto)){
                            echo "Ingresa un valor numerico entero"
                        }
                        elseif(-not(Es-RangoValido $puerto)){
                            echo "Ingresa un puerto dentro del rango (0-65535)"
                        }
                        elseif(Es-PuertoEnUso $puerto){
                            echo "El puerto se encuentra en uso"
                        }
                        elseif(-not(Es-PuertoValido $puerto)){
                            echo "Error"
                        }
                        else{
                            Stop-Process -Name caddy -ErrorAction SilentlyContinue
                            $versionSinV = quitarPrimerCaracter -string $versionDesarrolloCaddy
                            echo $versionSinV
                            echo "Instalando version LTS $versionDesarrolloCaddy"
                            Invoke-WebRequest -UseBasicParsing "https://github.com/caddyserver/caddy/releases/download/$versionDesarrolloCaddy/caddy_${versionSinV}_windows_amd64.zip" -Outfile "C:\descargas\caddy-$versionDesarrolloCaddy.zip"
                            Expand-Archive C:\descargas\caddy-$versionDesarrolloCaddy.zip C:\descargas -Force
                            cd C:\descargas
                            New-Item c:\descargas\Caddyfile -type file -Force
                            Set-Content -Path "C:\descargas\Caddyfile" -Value @"
                            :$puerto {
                                root * "C:\MiSitio"
                                file_server
                            }
"@
                            Start-Process -NoNewWindow -FilePath "C:\descargas\caddy.exe" -ArgumentList "run --config C:\descargas\Caddyfile"
                            Get-Process | Where-Object { $_.ProcessName -like "*caddy*" }
                            Select-String -Path "C:\descargas\Caddyfile" -Pattern ":$puerto"
                            netsh advfirewall firewall add rule name="Caddy" dir=in action=allow protocol=TCP localport=$puerto
                            echo "Se instalo la version de desarrollo $versionDesarrolloCaddy de Caddy"
                        }
                    }
                    catch{
                        echo $Error[0].ToString()
                    }
                }
                "3"{
                    echo "Saliendo del menu de caddy..."
                }
                default {"Selecciona una opcion dentro del rango (1..3)"}
            }
        }
        "3"{
            $nginxDescargas = "https://nginx.org/en/download.html"
            $paginaNginx = (hacerPeticion -url $nginxDescargas).Content
            $versiones = (encontrarValor -regex $versionRegex -pagina $paginaNginx)
            $versionLTSNginx = $versiones[6]
            $versionDevNginx = $versiones[0]

            echo "Instalador de Nginx"
            echo "1. Version LTS $versionLTSNginx"
            echo "2. Version de desarrollo $versionDevNginx"
            echo "3. Salir"
            $opcNginx = Read-Host "Selecciona una version"
            switch($opcNginx){
                "1"{
                    try {
                        $puerto = Read-Host "Ingresa el puerto donde se realizara la instalacion"
                        if(-not(Es-Numerico -string $puerto)){
                            echo "Ingresa un valor numerico entero"
                        }
                        elseif(-not(Es-RangoValido $puerto)){
                            echo "Ingresa un puerto dentro del rango (0-65535)"
                        }
                        elseif(Es-PuertoEnUso $puerto){
                            echo "El puerto se encuentra en uso"
                        }
                        elseif(-not(Es-PuertoValido $puerto)){
                            echo "Error"
                        }
                        else{
                            Stop-Process -Name nginx -ErrorAction SilentlyContinue
                            echo "Instalando version LTS $versionLTSNginx"
                            Invoke-WebRequest -UseBasicParsing "https://nginx.org/download/nginx-$versionLTSNginx.zip" -Outfile "C:\descargas\nginx-$versionLTSNginx.zip"
                            Expand-Archive C:\descargas\nginx-$versionLTSNginx.zip C:\descargas -Force
                            cd C:\descargas\nginx-$versionLTSNginx
                            Start-Process nginx.exe
                            Get-Process | Where-Object { $_.ProcessName -like "*nginx*" }
                            cd ..
                            (Get-Content C:\descargas\nginx-$versionLTSNginx\conf\nginx.conf) -replace "listen       [0-9]{1,5}", "listen       $puerto" | Set-Content C:\descargas\nginx-$versionLTSNginx\conf\nginx.conf
                            Select-String -Path "C:\descargas\nginx-$versionLTSNginx\conf\nginx.conf" -Pattern "listen       [0-9]{1,5}"
                            netsh advfirewall firewall add rule name="Nginx" dir=in action=allow protocol=TCP localport=$puerto
                            echo "Se instalo la version LTS $versionLTSNginx de Nginx"
                        }
                    }
                    catch {
                        Echo $Error[0].ToString()
                    }
                }
                "2"{
                    try {
                        $puerto = Read-Host "Ingresa el puerto donde se realizara la instalacion"
                        if(-not(Es-Numerico -string $puerto)){
                            echo "Ingresa un valor numerico entero"
                        }
                        elseif(-not(Es-RangoValido $puerto)){
                            echo "Ingresa un puerto dentro del rango (0-65535)"
                        }
                        elseif(Es-PuertoEnUso $puerto){
                            echo "El puerto se encuentra en uso"
                        }
                        elseif(-not(Es-PuertoValido $puerto)){
                            echo "Error"
                        }
                        else{
                            Stop-Process -Name nginx -ErrorAction SilentlyContinue
                            echo "Instalando version de desarrollo $versionDevNginx"
                            Invoke-WebRequest -UseBasicParsing "https://nginx.org/download/nginx-$versionDevNginx.zip" -Outfile "C:\descargas\nginx-$versionDevNginx.zip"
                            Expand-Archive C:\descargas\nginx-$versionDevNginx.zip C:\descargas -Force
                            cd C:\descargas\nginx-$versionDevNginx
                            Start-Process nginx.exe
                            Get-Process | Where-Object { $_.ProcessName -like "*nginx*" }
                            cd ..
                            (Get-Content C:\descargas\nginx-$versionDevNginx\conf\nginx.conf) -replace "listen       [0-9]{1,5}", "listen       $puerto" | Set-Content C:\descargas\nginx-$versionDevNginx\conf\nginx.conf
                            Select-String -Path "C:\descargas\nginx-$versionDevNginx\conf\nginx.conf" -Pattern "listen       [0-9]{1,5}"
                            netsh advfirewall firewall add rule name="Nginx" dir=in action=allow protocol=TCP localport=$puerto
                            echo "Se instalo la Version de desarrollo $versionDevNginx de Nginx"   
                        }
                    }
                    catch {
                        echo $Error[0].ToString()
                    }
                }
                "3"{
                    echo "Saliendo del menu de Nginx..."
                }
                default {"Selecciona una opcion dentro del rango (1..3)"}
            }
        }
        default {echo "Selecciona una opcion dentro del rango (1..4)"}
    }
    echo `n
}