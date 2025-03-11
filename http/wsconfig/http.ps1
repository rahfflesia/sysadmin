$ProgressPreference = 'SilentlyContinue'

function Es-PuertoValido([int]$puerto){
    return $puerto -gt 1023 -and $puerto -lt 65536
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
            echo "Instalador de Caddy"
            echo "1. Version LTS "
            echo "2. Version de desarrollo "
            echo "3. Salir"
            $opcCaddy = Read-Host "Selecciona una version"
            switch($opcCaddy){
                "1"{
                    # Implementar
                }
                "2"{
                    echo "Caddy no cuenta con una version de desarrollo"
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
                        Stop-Process -Name nginx -ErrorAction SilentlyContinue
                        echo "Instalando version LTS $versionLTSNginx"
                        Invoke-WebRequest -UseBasicParsing "https://nginx.org/download/nginx-$versionLTSNginx.zip" -Outfile "C:\descargas\nginx-$versionLTSNginx.zip"
                        Expand-Archive C:\descargas\nginx-$versionLTSNginx.zip C:\descargas -Force | Out-Null
                        cd C:\descargas\nginx-$versionLTSNginx
                        Start-Process nginx.exe
                        Get-Process | Where-Object { $_.ProcessName -like "*nginx*" }
                        cd ..
                        (Get-Content C:\descargas\nginx-$versionLTSNginx\conf\nginx.conf) -replace "listen       [0-9]{1,5}", "listen       $puerto" | Set-Content C:\descargas\nginx-$versionLTSNginx\conf\nginx.conf
                        Select-String -Path "C:\descargas\nginx-$versionLTSNginx\conf\nginx.conf" -Pattern "listen       [0-9]{1,5}"
                        echo "Se instalo la version LTS $versionLTSNginx de Nginx"
                    }
                    catch {
                        Echo $Error[0].ToString()
                    }
                }
                "2"{
                    try {
                        Stop-Process -Name nginx -ErrorAction SilentlyContinue
                        $puerto = Read-Host "Ingresa el puerto donde se realizara la instalacion"
                        echo "Instalando version de desarrollo $versionDevNginx"
                        Invoke-WebRequest -UseBasicParsing "https://nginx.org/download/nginx-$versionDevNginx.zip" -Outfile "C:\descargas\nginx-$versionDevNginx.zip"
                        Expand-Archive C:\descargas\nginx-$versionDevNginx.zip C:\descargas -Force | Out-Null
                        cd C:\descargas\nginx-$versionDevNginx
                        Start-Process nginx.exe
                        Get-Process | Where-Object { $_.ProcessName -like "*nginx*" }
                        cd ..
                        (Get-Content C:\descargas\nginx-$versionDevNginx\conf\nginx.conf) -replace "listen       [0-9]{1,5}", "listen       $puerto" | Set-Content C:\descargas\nginx-$versionDevNginx\conf\nginx.conf
                        Select-String -Path "C:\descargas\nginx-$versionDevNginx\conf\nginx.conf" -Pattern "listen       [0-9]{1,5}"
                        echo "Se instalo la Version de desarrollo $versionDevNginx de Nginx"
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