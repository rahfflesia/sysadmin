# Ambos scripts funcionales en caso de error puedo volver a este commit
$ProgressPreference = 'SilentlyContinue'
# Script de windows server 100% funcional
# Cualquier cosa puedo volver a este commit
# Cuando cambie de red tengo que editar la ip que ingreso en el Caddyfile <- importante
$opcDescarga = Read-Host "Desde donde quieres realizar la instalacion de los servicios? (web/ftp)"

$servidorFtp = "ftp://localhost"

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

function listarDirectoriosFtp {
    param (
        [string]$servidorFtp
    )

    $usuario = "anonymous"
    $contrasena = ""

    $exito = $false

    $validacionOriginalCallback = [System.Net.ServicePointManager]::ServerCertificateValidationCallback

    foreach ($usarSsl in $false, $true) {
        try {
            $peticion = [System.Net.FtpWebRequest]::Create($servidorFtp)
            $peticion.Method = [System.Net.WebRequestMethods+Ftp]::ListDirectoryDetails
            $peticion.Credentials = New-Object System.Net.NetworkCredential($usuario, $contrasena)
            $peticion.EnableSsl = $usarSsl

            if ($usarSsl) {
                [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
            }

            $respuesta = $peticion.GetResponse()
            $respuestaStream = $respuesta.GetResponseStream()
            $lector = New-Object System.IO.StreamReader($respuestaStream)

            Write-Host "Conexion exitosa usando SSL = $usarSsl"

            while (-not $lector.EndOfStream) {
                $linea = $lector.ReadLine()
                Write-Output $linea
            }

            $lector.Close()
            $respuestaStream.Close()
            $respuesta.Close()

            $exito = $true
            break
        }
        catch {
            Write-Host "Fallo con SSL = $usarSsl, reintentando..."
        }
    }

    if (-not $exito) {
        Write-Host "No se pudo conectar al FTP con o sin SSL."
    }

    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = $validacionOriginalCallback
}

function Es-ArchivoExistente($rutaDirectorio, $archivoABuscar){
    forEach($file in Get-ChildItem -Path $rutaDirectorio){
        if($file.Name -eq $archivoABuscar){
            return $true
        }
    }
    return $false
}

$versionRegex = "[0-9]+.[0-9]+.[0-9]"

if($opcDescarga.ToLower() -eq "ftp"){
    while($true){
        listarDirectoriosFtp -servidorFtp $servidorFtp
        echo "Menu de instalacion FTP"
        echo "Elige el servicio a instalar"
        $opc = Read-Host "Selecciona una opcion (escribe salir para salir)"
        $opc = $opc.ToLower()

        if($opc -eq "4"){
            echo "Saliendo..."
            break
        }

        switch($opc){
            "caddy"{
                listarDirectoriosFtp -servidorFtp "$servidorFtp/Caddy"
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
                            else {
                                $opcCaddySsl = Read-Host "Quieres activar SSL? (si/no)"
                                Stop-Process -Name caddy -ErrorAction SilentlyContinue
                                $versionSinV = quitarPrimerCaracter -string $versionLTSCaddy
                                echo $versionSinV
                                echo "Instalando version LTS $versionLTSCaddy"
                                curl.exe "$servidorFtp/Caddy/caddy-$versionLTSCaddy.zip" --ftp-ssl -k -o "C:\descargas\caddy-$versionLTSCaddy.zip"
                                Expand-Archive C:\descargas\caddy-$versionLTSCaddy.zip C:\descargas -Force
                                cd C:\descargas
                                New-Item c:\descargas\Caddyfile -type file -Force

                                if($opcCaddySsl.ToLower() -eq "si"){
                                    echo "Habilitando SSL..."
                                    Clear-Content -Path "C:\descargas\Caddyfile"
                                    Set-Content -Path "C:\descargas\Caddyfile" -Value @"
{
    auto_https disable_redirects
    debug
}

https://192.168.100.38:$puerto {
    root * "C:\MiSitio"
    file_server
    tls C:\Descargas\certificate.crt C:\Descargas\private_decrypted.key
}
"@
                                    Start-Process -NoNewWindow -FilePath "C:\descargas\caddy.exe" -ArgumentList "run --config C:\descargas\Caddyfile"
                                    Get-Process | Where-Object { $_.ProcessName -like "*caddy*" }
                                    Select-String -Path "C:\descargas\Caddyfile" -Pattern ":$puerto"
                                    netsh advfirewall firewall add rule name="Caddy" dir=in action=allow protocol=TCP localport=$puerto
                                    echo "Se instalo la version LTS $versionLTSCaddy de Caddy"
                                }
                                elseif($opcCaddySsl.ToLower() -eq "no"){
                                    Clear-Content -Path "C:\descargas\Caddyfile"
                                    echo "SSL no sera habilitado..."
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
                                    echo "Se instalo la version LTS $versionLTSCaddy de Caddy"
                                }
                                else {
                                    echo "Selecciona una opcion valida (si/no)"
                                }
                            }
                        }
                        catch {
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
                                $opcSsl = Read-Host "Quieres activar SSL (si/no)"
                                if($opcSsl.ToLower() -eq "si"){
                                    echo "Habilitando SSL..." 
                                    Stop-Process -Name caddy -ErrorAction SilentlyContinue
                                    $versionSinV = quitarPrimerCaracter -string $versionDesarrolloCaddy
                                    echo $versionSinV
                                    echo "Instalando version LTS $versionDesarrolloCaddy"
                                    curl.exe "$servidorFtp/Caddy/caddy-$versionDesarrolloCaddy.zip" --ftp-ssl -k -o "C:\descargas\caddy-$versionDesarrolloCaddy.zip"
                                    Expand-Archive C:\descargas\caddy-$versionDesarrolloCaddy.zip C:\descargas -Force
                                    cd C:\descargas
                                    New-Item c:\descargas\Caddyfile -type file -Force
                                    Set-Content -Path "C:\descargas\Caddyfile" -Value @"
{
    auto_https disable_redirects
    debug
}

https://192.168.100.38:$puerto {
    root * "C:\MiSitio"
    file_server
    tls C:\Descargas\certificate.crt C:\Descargas\private_decrypted.key
}
"@
                                    Start-Process -NoNewWindow -FilePath "C:\descargas\caddy.exe" -ArgumentList "run --config C:\descargas\Caddyfile"
                                    Get-Process | Where-Object { $_.ProcessName -like "*caddy*" }
                                    Select-String -Path "C:\descargas\Caddyfile" -Pattern ":$puerto"
                                    netsh advfirewall firewall add rule name="Caddy" dir=in action=allow protocol=TCP localport=$puerto
                                    echo "Se instalo la version de desarrollo $versionDesarrolloCaddy de Caddy"
                                }
                            elseif($opcSsl.ToLower() -eq "no"){
                                    echo "SSl no se habilitara..." 
                                    Stop-Process -Name caddy -ErrorAction SilentlyContinue
                                    $versionSinV = quitarPrimerCaracter -string $versionDesarrolloCaddy
                                    echo $versionSinV
                                    echo "Instalando version LTS $versionDesarrolloCaddy"
                                    curl.exe "$servidorFtp/Caddy/caddy-$versionDesarrolloCaddy.zip" --ftp-ssl -k -o "C:\descargas\caddy-$versionDesarrolloCaddy.zip"
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
                                else{
                                    echo "Selecciona una opcion valida (si/no)" 
                                }
                            }
                        }
                        catch{
                            echo $Error[0].ToString()
                        }
                    }
                    "3"{
                        echo "Saliendo del menu de Caddy..."
                    }
                    default { echo "Selecciona una opcion valida" } 
                }
            }
            "nginx"{
                listarDirectoriosFtp -servidorFtp "$servidorFtp/Nginx"
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
                                $opcSsl = Read-Host "Quieres habilitar SSL (si/no)"
                                if($opcSsl.ToLower() -eq "si"){
                                    echo "Habilitando SSL..."
                                    Stop-Process -Name nginx -ErrorAction SilentlyContinue
                                    echo "Instalando version LTS $versionLTSNginx"
                                    curl.exe "$servidorFtp/Nginx/nginx-$versionLTSNginx.zip" --ftp-ssl -k -o "C:\descargas\nginx-$versionLTSNginx.zip"
                                    Expand-Archive C:\descargas\nginx-$versionLTSNginx.zip C:\descargas -Force
                                    cd C:\descargas\nginx-$versionLTSNginx
                                    Clear-Content -Path "C:\descargas\nginx-$versionLTSNginx\conf\nginx.conf"
                                    Start-Process nginx.exe
                                    Get-Process | Where-Object { $_.ProcessName -like "*nginx*" }
                                    cd ..
                                    $contenido = @"
worker_processes  1;

events {
    worker_connections  1024;
}

http {
    include       mime.types;
    default_type  application/octet-stream;

    sendfile        on;
    keepalive_timeout  65;

    # Configuración del servidor HTTP (redirige a HTTPS)
    server {
        listen 81;
        server_name localhost;

        location / {
            root   html;
            index  index.html index.htm;
        }
    }

    # Configuración del servidor HTTPS
    server {
        listen $puerto ssl;
        server_name localhost;

        ssl_certificate c:\descargas\certificate.crt;
        ssl_certificate_key c:\descargas\private.key;

        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers HIGH:!aNULL:!MD5;

        location / {
            root   html;
            index  index.html index.htm;
        }

        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }
    }
}
"@
                                    Set-Content -Path "C:\descargas\nginx-$versionLTSNginx\conf\nginx.conf" -Value $contenido
                                    netsh advfirewall firewall add rule name="Nginx" dir=in action=allow protocol=TCP localport=$puerto
                                    echo "Se instalo la version LTS $versionLTSNginx de Nginx"
                                }
                                elseif($opcSsl.ToLower() -eq "no"){
                                    echo "SSL no se habilitara"
                                    Stop-Process -Name nginx -ErrorAction SilentlyContinue
                                    echo "Instalando version LTS $versionLTSNginx"
                                    curl.exe "$servidorFtp/Nginx/nginx-$versionLTSNginx.zip" --ftp-ssl -k -o "C:\descargas\nginx-$versionLTSNginx.zip"
                                    Expand-Archive C:\descargas\nginx-$versionLTSNginx.zip C:\descargas -Force
                                    cd C:\descargas\nginx-$versionLTSNginx
                                    Clear-Content -Path "C:\descargas\nginx-$versionLTSNginx\conf\nginx.conf"
                                    Start-Process nginx.exe
                                    Get-Process | Where-Object { $_.ProcessName -like "*nginx*" }
                                    cd ..
                                    $contenido = @"
worker_processes  1;

events {
    worker_connections  1024;
}

http {
    include       mime.types;
    default_type  application/octet-stream;

    sendfile        on;
    keepalive_timeout  65;

    # Configuración del servidor HTTP (redirige a HTTPS)
    server {
        listen $puerto;
        server_name localhost;

        location / {
            root   html;
            index  index.html index.htm;
        }
    }
}
"@
                                    Set-Content -Path "C:\descargas\nginx-$versionLTSNginx\conf\nginx.conf" -Value $contenido
                                    netsh advfirewall firewall add rule name="Nginx" dir=in action=allow protocol=TCP localport=$puerto
                                    echo "Se instalo la version LTS $versionLTSNginx de Nginx"
                                }
                                else{
                                    echo "Selecciona una opcion valida (si/no)"
                                }
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
                                $opcSsl = Read-Host "Quieres activar SSL? (si/no)"
                                if($opcSsl.ToLower() -eq "si"){
                                    echo "Habilitando SSL..."
                                    Stop-Process -Name nginx -ErrorAction SilentlyContinue
                                    echo "Instalando version LTS $versionDevNginx"
                                    curl.exe "$servidorFtp/Nginx/nginx-$versionDevNginx.zip" --ftp-ssl -k -o "C:\descargas\nginx-$versionDevNginx.zip"
                                    Expand-Archive C:\descargas\nginx-$versionDevNginx.zip C:\descargas -Force
                                    cd C:\descargas\nginx-$versionDevNginx
                                    Clear-Content -Path "C:\descargas\nginx-$versionDevNginx\conf\nginx.conf"
                                    Start-Process nginx.exe
                                    Get-Process | Where-Object { $_.ProcessName -like "*nginx*" }
                                    cd ..
                                    $contenido = @"
worker_processes  1;

events {
    worker_connections  1024;
}

http {
    include       mime.types;
    default_type  application/octet-stream;

    sendfile        on;
    keepalive_timeout  65;

    # Configuración del servidor HTTP (redirige a HTTPS)
    server {
        listen 81;
        server_name localhost;

        location / {
            root   html;
            index  index.html index.htm;
        }
    }

    # Configuración del servidor HTTPS
    server {
        listen $puerto ssl;
        server_name localhost;

        ssl_certificate c:\descargas\certificate.crt;
        ssl_certificate_key c:\descargas\private.key;

        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers HIGH:!aNULL:!MD5;

        location / {
            root   html;
            index  index.html index.htm;
        }

        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }
    }
}
"@
                                    Set-Content -Path "C:\descargas\nginx-$versionDevNginx\conf\nginx.conf" -Value $contenido
                                    netsh advfirewall firewall add rule name="Nginx" dir=in action=allow protocol=TCP localport=$puerto
                                    echo "Se instalo la version LTS $versionDevNginx de Nginx"

                                }
                                elseif($opcSsl.ToLower() -eq "no"){
                                    echo "SSL no se habilitara"
                                    Stop-Process -Name nginx -ErrorAction SilentlyContinue
                                    echo "Instalando version LTS $versionDevNginx"
                                    curl.exe "$servidorFtp/Nginx/nginx-$versionDevNginx.zip" --ftp-ssl -k -o "C:\descargas\nginx-$versionDevNginx.zip"
                                    Expand-Archive C:\descargas\nginx-$versionDevNginx.zip C:\descargas -Force
                                    cd C:\descargas\nginx-$versionDevNginx
                                    Clear-Content -Path "C:\descargas\nginx-$versionDevNginx\conf\nginx.conf"
                                    Start-Process nginx.exe
                                    Get-Process | Where-Object { $_.ProcessName -like "*nginx*" }
                                    cd ..
                                    $contenido = @"
worker_processes  1;

events {
    worker_connections  1024;
}

http {
    include       mime.types;
    default_type  application/octet-stream;

    sendfile        on;
    keepalive_timeout  65;

    # Configuración del servidor HTTP (redirige a HTTPS)
    server {
        listen $puerto;
        server_name localhost;

        location / {
            root   html;
            index  index.html index.htm;
        }
    }
}
"@
                                    Set-Content -Path "C:\descargas\nginx-$versionDevNginx\conf\nginx.conf" -Value $contenido
                                    netsh advfirewall firewall add rule name="Nginx" dir=in action=allow protocol=TCP localport=$puerto
                                    echo "Se instalo la version LTS $versionDevNginx de Nginx"
                                }
                                else{
                                    echo "Selecciona una opcion valida (si/no)"
                                }
                            }
                        }
                        catch {
                            echo $Error[0].ToString()
                        }
                    }
                    "3"{
                        echo "Saliendo del menu de Nginx..."
                    }
                }
            }
            "salir"{
                echo "Saliendo..."
                break
            }
            default{
                if(Test-Path "C:\FTP\LocalUser\Public\$opc"){
                    echo "Archivos disponibles para descarga"
                    listarDirectoriosFtp -servidorFtp "$servidorFtp/$opc"
                    $archivoADescargar = Read-Host "Selecciona uno, al seleccionar incluye tanto el nombre como la extension en caso de necesitarse"
                    if(Es-ArchivoExistente -rutaDirectorio "C:\FTP\LocalUser\Public\$opc\$archivoADescargar" -archivoABuscar $archivoADescargar){
                        echo "Archivo encontrado, comenzando con la descarga..."
                        curl.exe "$servidorFtp/$opc/$archivoADescargar" --ftp-ssl -k -o "C:\descargas\$archivoADescargar"
                    }
                    else{
                        echo "El archivo no existe en el directorio, ingresa un archivo valido"
                    }
                }
                else{
                    echo "El directorio no existe"
                }
            }
        }
    }
}

elseif($opcDescarga.ToLower() -eq "web"){
    while($true){
    echo "Menu de instalacion Web"
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
    auto_https disable_redirects
    debug
}

https://192.168.100.38:$puerto {
    root * "C:\MiSitio"
    file_server
    tls C:\Descargas\certificate.crt C:\Descargas\private_decrypted.key
}
"@
                                # Se ocupa cambiar la ip para que coincida con la de la vm
                                Start-Process -NoNewWindow -FilePath "C:\descargas\caddy.exe" -ArgumentList "run --config C:\descargas\Caddyfile"
                                Get-Process | Where-Object { $_.ProcessName -like "*caddy*" }
                                Select-String -Path "C:\descargas\Caddyfile" -Pattern ":$puerto"
                                netsh advfirewall firewall add rule name="Caddy" dir=in action=allow protocol=TCP localport=$puerto
                                echo "Se instalo la version LTS $versionLTSCaddy de Caddy"
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
                                Start-Process -NoNewWindow -FilePath "C:\descargas\caddy.exe" -ArgumentList "run --config C:\descargas\Caddyfile"
                                Get-Process | Where-Object { $_.ProcessName -like "*caddy*" }
                                Select-String -Path "C:\descargas\Caddyfile" -Pattern ":$puerto"
                                netsh advfirewall firewall add rule name="Caddy" dir=in action=allow protocol=TCP localport=$puerto
                                echo "Se instalo la version LTS $versionLTSCaddy de Caddy"
                            }
                            else{
                                echo "Selecciona una opcion valida (si/no)"
                            }
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
                            $opcSsl = Read-Host "Quieres activar SSL (si/no)"
                            if($opcSsl.ToLower() -eq "si"){
                                echo "Habilitando SSL..." 
                                Stop-Process -Name caddy -ErrorAction SilentlyContinue
                                $versionSinV = quitarPrimerCaracter -string $versionDesarrolloCaddy
                                echo $versionSinV
                                echo "Instalando version LTS $versionDesarrolloCaddy"
                                Invoke-WebRequest -UseBasicParsing "https://github.com/caddyserver/caddy/releases/download/$versionDesarrolloCaddy/caddy_${versionSinV}_windows_amd64.zip" -Outfile "C:\descargas\caddy-$versionDesarrolloCaddy.zip"
                                Expand-Archive C:\descargas\caddy-$versionDesarrolloCaddy.zip C:\descargas -Force
                                cd C:\descargas
                                New-Item c:\descargas\Caddyfile -type file -Force
                                Set-Content -Path "C:\descargas\Caddyfile" -Value @"
{
    auto_https disable_redirects
    debug
}

https://192.168.100.38:$puerto {
    root * "C:\MiSitio"
    file_server
    tls C:\Descargas\certificate.crt C:\Descargas\private_decrypted.key
}
"@
                                Start-Process -NoNewWindow -FilePath "C:\descargas\caddy.exe" -ArgumentList "run --config C:\descargas\Caddyfile"
                                Get-Process | Where-Object { $_.ProcessName -like "*caddy*" }
                                Select-String -Path "C:\descargas\Caddyfile" -Pattern ":$puerto"
                                netsh advfirewall firewall add rule name="Caddy" dir=in action=allow protocol=TCP localport=$puerto
                                echo "Se instalo la version de desarrollo $versionDesarrolloCaddy de Caddy"
                            }
                            elseif($opcSsl.ToLower() -eq "no"){
                                echo "SSl no se habilitara..." 
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
                            else{
                                echo "Selecciona una opcion valida (si/no)" 
                            }
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
                            $opcSsl = Read-Host "Quieres habilitar SSL (si/no)"
                            if($opcSsl.ToLower() -eq "si"){
                                echo "Habilitando SSL..."
                                Stop-Process -Name nginx -ErrorAction SilentlyContinue
                                echo "Instalando version LTS $versionLTSNginx"
                                Invoke-WebRequest -UseBasicParsing "https://nginx.org/download/nginx-$versionLTSNginx.zip" -Outfile "C:\descargas\nginx-$versionLTSNginx.zip"
                                Expand-Archive C:\descargas\nginx-$versionLTSNginx.zip C:\descargas -Force
                                cd C:\descargas\nginx-$versionLTSNginx
                                Clear-Content -Path "C:\descargas\nginx-$versionLTSNginx\conf\nginx.conf"
                                Start-Process nginx.exe
                                Get-Process | Where-Object { $_.ProcessName -like "*nginx*" }
                                cd ..
                                $contenido = @"
worker_processes  1;

events {
    worker_connections  1024;
}

http {
    include       mime.types;
    default_type  application/octet-stream;

    sendfile        on;
    keepalive_timeout  65;

    # Configuración del servidor HTTP (redirige a HTTPS)
    server {
        listen 81;
        server_name localhost;

        location / {
            root   html;
            index  index.html index.htm;
        }
    }

    # Configuración del servidor HTTPS
    server {
        listen $puerto ssl;
        server_name localhost;

        ssl_certificate c:\descargas\certificate.crt;
        ssl_certificate_key c:\descargas\private.key;

        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers HIGH:!aNULL:!MD5;

        location / {
            root   html;
            index  index.html index.htm;
        }

        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }
    }
}
"@
                                Set-Content -Path "C:\descargas\nginx-$versionLTSNginx\conf\nginx.conf" -Value $contenido
                                netsh advfirewall firewall add rule name="Nginx" dir=in action=allow protocol=TCP localport=$puerto
                                echo "Se instalo la version LTS $versionLTSNginx de Nginx"
                            }
                            elseif($opcSsl.ToLower() -eq "no"){
                                echo "SSL no se habilitara"
                                Stop-Process -Name nginx -ErrorAction SilentlyContinue
                                echo "Instalando version LTS $versionLTSNginx"
                                Invoke-WebRequest -UseBasicParsing "https://nginx.org/download/nginx-$versionLTSNginx.zip" -Outfile "C:\descargas\nginx-$versionLTSNginx.zip"
                                Expand-Archive C:\descargas\nginx-$versionLTSNginx.zip C:\descargas -Force
                                cd C:\descargas\nginx-$versionLTSNginx
                                Clear-Content -Path "C:\descargas\nginx-$versionLTSNginx\conf\nginx.conf"
                                Start-Process nginx.exe
                                Get-Process | Where-Object { $_.ProcessName -like "*nginx*" }
                                cd ..
                                $contenido = @"
worker_processes  1;

events {
    worker_connections  1024;
}

http {
    include       mime.types;
    default_type  application/octet-stream;

    sendfile        on;
    keepalive_timeout  65;

    # Configuración del servidor HTTP (redirige a HTTPS)
    server {
        listen $puerto;
        server_name localhost;

        location / {
            root   html;
            index  index.html index.htm;
        }
    }
}
"@
                                Set-Content -Path "C:\descargas\nginx-$versionLTSNginx\conf\nginx.conf" -Value $contenido
                                netsh advfirewall firewall add rule name="Nginx" dir=in action=allow protocol=TCP localport=$puerto
                                echo "Se instalo la version LTS $versionLTSNginx de Nginx"
                            }
                            else{
                                echo "Selecciona una opcion valida (si/no)"
                            }
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
                            $opcSsl = Read-Host "Quieres activar SSL? (si/no)"
                            if($opcSsl.ToLower() -eq "si"){
                                echo "Habilitando SSL..."
                                Stop-Process -Name nginx -ErrorAction SilentlyContinue
                                echo "Instalando version LTS $versionDevNginx"
                                Invoke-WebRequest -UseBasicParsing "https://nginx.org/download/nginx-$versionDevNginx.zip" -Outfile "C:\descargas\nginx-$versionDevNginx.zip"
                                Expand-Archive C:\descargas\nginx-$versionDevNginx.zip C:\descargas -Force
                                cd C:\descargas\nginx-$versionDevNginx
                                Clear-Content -Path "C:\descargas\nginx-$versionDevNginx\conf\nginx.conf"
                                Start-Process nginx.exe
                                Get-Process | Where-Object { $_.ProcessName -like "*nginx*" }
                                cd ..
                                $contenido = @"
worker_processes  1;

events {
    worker_connections  1024;
}

http {
    include       mime.types;
    default_type  application/octet-stream;

    sendfile        on;
    keepalive_timeout  65;

    # Configuración del servidor HTTP (redirige a HTTPS)
    server {
        listen 81;
        server_name localhost;

        location / {
            root   html;
            index  index.html index.htm;
        }
    }

    # Configuración del servidor HTTPS
    server {
        listen $puerto ssl;
        server_name localhost;

        ssl_certificate c:\descargas\certificate.crt;
        ssl_certificate_key c:\descargas\private.key;

        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers HIGH:!aNULL:!MD5;

        location / {
            root   html;
            index  index.html index.htm;
        }

        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }
    }
}
"@
                                Set-Content -Path "C:\descargas\nginx-$versionDevNginx\conf\nginx.conf" -Value $contenido
                                netsh advfirewall firewall add rule name="Nginx" dir=in action=allow protocol=TCP localport=$puerto
                                echo "Se instalo la version LTS $versionDevNginx de Nginx"

                            }
                            elseif($opcSsl.ToLower() -eq "no"){
                                echo "SSL no se habilitara"
                                Stop-Process -Name nginx -ErrorAction SilentlyContinue
                                echo "Instalando version LTS $versionDevNginx"
                                Invoke-WebRequest -UseBasicParsing "https://nginx.org/download/nginx-$versionDevNginx.zip" -Outfile "C:\descargas\nginx-$versionDevNginx.zip"
                                Expand-Archive C:\descargas\nginx-$versionDevNginx.zip C:\descargas -Force
                                cd C:\descargas\nginx-$versionDevNginx
                                Clear-Content -Path "C:\descargas\nginx-$versionDevNginx\conf\nginx.conf"
                                Start-Process nginx.exe
                                Get-Process | Where-Object { $_.ProcessName -like "*nginx*" }
                                cd ..
                                $contenido = @"
worker_processes  1;

events {
    worker_connections  1024;
}

http {
    include       mime.types;
    default_type  application/octet-stream;

    sendfile        on;
    keepalive_timeout  65;

    # Configuración del servidor HTTP (redirige a HTTPS)
    server {
        listen $puerto;
        server_name localhost;

        location / {
            root   html;
            index  index.html index.htm;
        }
    }
}
"@
                                Set-Content -Path "C:\descargas\nginx-$versionDevNginx\conf\nginx.conf" -Value $contenido
                                netsh advfirewall firewall add rule name="Nginx" dir=in action=allow protocol=TCP localport=$puerto
                                echo "Se instalo la version LTS $versionDevNginx de Nginx"
                            }
                            else{
                                echo "Selecciona una opcion valida (si/no)"
                            }
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
}
else{
    echo "Selecciona una opcion valida (web/ftp)"
}