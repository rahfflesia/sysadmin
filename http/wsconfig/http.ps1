# Ambos scripts funcionales en caso de error puedo volver a este commit
$ProgressPreference = 'SilentlyContinue'

# Script de powershell funcional, quizás falta depurarlo un poco

function Es-PuertoValido([int]$puerto){
    $array = @(20 21 22 23 25 53 67 68 80 110 119 123 143 161 162 389 443)
    $arrayDesc = @()
    
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
                Install-WindowsFeature -Name Web-Server
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
                        if(-not(Es-Numerico -string $puerto) -or -not(Es-PuertoValido -puerto $puerto)){
                            echo "Ingresa un valor numerico entero o un puerto dentro del rango (1024-65535)"
                        }
                        else{
                            Stop-Process -Name caddy -ErrorAction SilentlyContinue
                            $versionSinV = quitarPrimerCaracter -string $versionLTSCaddy
                            echo $versionSinV
                            echo "Instalando version LTS $versionLTSCaddy"
                            Invoke-WebRequest -UseBasicParsing "https://github.com/caddyserver/caddy/releases/download/$versionLTSCaddy/caddy_${versionSinV}_windows_amd64.zip" -Outfile "C:\descargas\caddy-$versionLTSCaddy.zip"
                            Expand-Archive C:\descargas\caddy-$versionLTSCaddy.zip C:\descargas -Force
                            cd C:\descargas
                            New-Item c:\descargas\Caddyfile -type file -Force
                            Add-Content -Path "C:\descargas\Caddyfile" -Value ":$puerto"
                            Start-Process caddy.exe
                            Get-Process | Where-Object { $_.ProcessName -like "*caddy*" }
                            Select-String -Path "C:\descargas\Caddyfile" -Pattern ":$puerto"
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
                        if(-not(Es-Numerico -string $puerto) -or -not(Es-PuertoValido -puerto $puerto)){
                            echo "Ingresa un valor numerico entero o un puerto dentro del rango (1024-65535)"
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
                            Add-Content -Path "C:\descargas\Caddyfile" -Value ":$puerto"
                            Start-Process caddy.exe
                            Get-Process | Where-Object { $_.ProcessName -like "*caddy*" }
                            Select-String -Path "C:\descargas\Caddyfile" -Pattern ":$puerto"
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
                        if(-not(Es-Numerico -string $puerto) -or -not(Es-PuertoValido -puerto $puerto)){
                            echo "Ingresa un valor numerico entero o un puerto dentro del rango (1024-65535)"
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
                        if(-not(Es-Numerico -string $puerto) -or -not(Es-PuertoValido -puerto $puerto)){
                            echo "Ingresa un valor numerico entero o un puerto dentro del rango (1024-65535)"
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