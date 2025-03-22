# Ambos scripts funcionales en caso de error puedo volver a este commit
# Nginx funcional, falta lighttpd, cualquier cosa puedo volver a este commit
# $1 = URL, Retorna el html
ftpUrl="ftp://localhost"

echo "Desde donde quieres realizar la instalacion de los servicios? (web/ftp)"
read opcInstall

function hacerPeticion(){
    local url=$1
    local html=$(curl -s "$url")
    echo "${html}"
}

# $1 = Expresión regular, $2 = String a comparar, $3 = 
function encontrarValor(){
    local regex=$1
    local string=$2
    if [[ $string =~ $regex ]]; then
        echo "${BASH_REMATCH[0]}"
    else
        echo "No se encontro el patron"
    fi
}

function esPuertoValido() {
    local array=(20 21 22 23 25 53 67 68 80 110 119 123 143 161 162 389 443)
    declare -A arrayDesc

    arrayDesc[20]="FTP"
    arrayDesc[21]="FTP"
    arrayDesc[22]="SSH"
    arrayDesc[23]="Telnet"
    arrayDesc[25]="SMTP"
    arrayDesc[53]="DNS"
    arrayDesc[67]="DHCP"
    arrayDesc[68]="DHCP"
    arrayDesc[80]="HTTP"
    arrayDesc[110]="POP3"
    arrayDesc[119]="NNTP"
    arrayDesc[123]="NTP"
    arrayDesc[143]="IMAP"
    arrayDesc[161]="SNMP"
    arrayDesc[162]="SNMP"
    arrayDesc[389]="LDAP"
    arrayDesc[443]="HTTPS"

    local puerto=$1
    for numero in "${array[@]}"; do
        if [[ "$numero" -eq "$puerto" ]]; then
            echo "No se puede utilizar ese puerto porque está reservado para el servicio ${arrayDesc[$numero]}"
            return 1
        fi
    done
    return 0
}

function esRangoValido(){
    local puerto=$1
    if [[ "$puerto" -lt 0 || "$puerto" -gt 65535 ]]; then
        return 1
    else
        return 0
    fi
}


function esValorEntero(){
    local valor=$1
    if [[ "$valor" =~ ^[0-9]+$ ]]; then
        return 0
    else
        return 1
    fi
}

function puertoEnUso(){
    local puerto=$1
    if sudo nc -z -w 1 localhost "$puerto"; then
        return 0
    else
        return 1
    fi
}

# $1 = Indice de la version LTS, # $2 = String que contiene las versiones
function obtenerVersionLTS(){
    local indice=$1
    local string=$2
    IFS=$'\n' read -r -d '' -a versionesArray <<< "$string"
    echo "${versionesArray[$indice]}"
}

# $1 = Última versión a mostrar, $2 = Link de descarga, $3 = Nombre que se le pondrá al archivo descargado, $4 = Nombre del archivo una vez descomprimido
# $ 5 = Nombre del servicio a instalar (apache, nginx)
function instalarServicioHTTP(){
    local versionAMostrar=$1
    local linkDescarga=$2
    local nombreArchivo=$3
    local nombreArchivoDescomprimido=$4
    local nombreServicio=$5

    echo "Ultima version -> $versionAMostrar"
    echo "Instalando version $versionAMostrar de $nombreServicio"
    echo "Por favor espere..."
    curl -s -O "$linkDescarga"
    # Descomprimir archivo
    sudo tar -xvzf $nombreArchivo > /dev/null 2>&1
    # Entrar a la carpeta
    cd "$nombreArchivoDescomprimido"
    # Compilar
    ./configure --prefix=/usr/local/"$nombreServicio" > /dev/null 2>&1
    # Instalación
    make > /dev/null 2>&1
    sudo make install > /dev/null 2>&1
}

function instalarNginx(){
    local versionAMostrar=$1
    local linkDescarga=$2
    local nombreArchivo=$3
    local nombreArchivoDescomprimido=$4
    local nombreServicio=$5

    echo "Ultima version -> $versionAMostrar"
    echo "Instalando version $versionAMostrar de $nombreServicio"
    echo "Por favor espere..."
    curl -s -O "$linkDescarga"
    # Descomprimir archivo
    sudo tar -xvzf $nombreArchivo > /dev/null 2>&1
    # Entrar a la carpeta
    cd "$nombreArchivoDescomprimido"
    # Compilar
    ./configure --prefix=/usr/local/nginx --with-http_ssl_module > /dev/null 2>&1
    # Instalación
    make > /dev/null 2>&1
    sudo make install > /dev/null 2>&1
}


function habilitarSSLApache(){
    local puerto=$1
    rutaArchivoConfiguracion="/usr/local/apache/conf/httpd.conf"
    if sudo grep -qiE "LoadModule ssl_module modules\/mod_ssl.so" "$rutaArchivoConfiguracion"; then
        echo "El modulo de SSL ya se encuentra cargado, este paso sera omitido"
    else
        sudo printf "LoadModule ssl_module modules/mod_ssl.so\n" >> "$rutaArchivoConfiguracion"
    fi

    if sudo grep -q "<VirtualHost _default_:$puerto>" "$rutaArchivoConfiguracion"; then
        echo "La configuracion SSL ya se encuentra establecida, se omitira este paso"
    else
        sudo printf "<VirtualHost _default_:$puerto>\n" >> "$rutaArchivoConfiguracion"
        sudo printf "    DocumentRoot \"/usr/local/apache/htdocs\" \n" >> "$rutaArchivoConfiguracion"
        sudo printf "    ServerName ubuntu-server-jj\n" >> "$rutaArchivoConfiguracion"
        sudo printf "    SSLEngine on\n" >> "$rutaArchivoConfiguracion"
        sudo printf "    SSLCertificateFile /etc/ssl/certs/vsftpd.crt\n" >> "$rutaArchivoConfiguracion"
        sudo printf "    SSLCertificateKeyFile /etc/ssl/private/vsftpd.key\n" >> "$rutaArchivoConfiguracion"
        sudo printf "    <Directory \"/usr/local/apache/htdocs\">\n" >> "$rutaArchivoConfiguracion"
        sudo printf "       Options Indexes FollowSymLinks\n" >> "$rutaArchivoConfiguracion"
        sudo printf "       AllowOverride All\n" >> "$rutaArchivoConfiguracion"
        sudo printf "       Require all granted\n" >> "$rutaArchivoConfiguracion"
        sudo printf "    </Directory>\n" >> "$rutaArchivoConfiguracion"
        sudo printf "</VirtualHost>\n">> "$rutaArchivoConfiguracion"
    fi

    if sudo grep -qiE "Listen $puerto" "$rutaArchivoConfiguracion"; then
        echo "El puerto $puerto ya se encuentra configurado, se omitira este paso"
    else
        sudo printf "Listen $puerto\n" >> "$rutaArchivoConfiguracion"
    fi
    sudo /usr/local/apache/bin/apachectl restart
}

function habilitarSSLNginx(){
    local ruta=$1
    local puerto=$2

    > $ruta
    sudo bash -c "cat > $ruta" << EOF
worker_processes  1;

events {
    worker_connections  1024;
}

http {
    include       mime.types;
    default_type  application/octet-stream;

    sendfile        on;
    keepalive_timeout  65;

    server {
        listen 10017;
        server_name localhost;

        location / {
            root   html;
            index  index.html index.htm;
        }
    }

    server {
        listen $puerto ssl;
        server_name localhost;

        ssl_certificate /etc/ssl/certs/vsftpd.crt;
        ssl_certificate_key /etc/ssl/private/vsftpd.key;

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
EOF
}

function deshabilitarSSLNginx(){
    local ruta=$1
    local puerto=$2

    > $ruta
    sudo bash -c "cat > $ruta" << EOF
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
EOF
}

function habilitarSslLighttpd(){
    local ruta=$1
    local puerto=$2

    > $ruta
    sudo bash -c "cat > $ruta" << EOF
var.log_root = "var/log/lighttpd"
var.server_root = "/srv/www"
var.state_dir = "/run"
var.home_dir = "/var/lib/lighttpd"
var.conf_dir = "/etc/lighttpd"

var.vhosts_dir = server_root + "/vhosts"
var.cache_dir = "/var/cache/lighttpd"
var.socket_dir = home_dir + "/sockets"

include conf_dir + "/modules.conf"

server.port = 80

server.username = "lighttpd"
server.groupname = "lighttpd"

server.document-root = server_root + "/htdocs"

server.pid-file = state_dir + "lighttpd.pid"

server.errorlog = log_root + "/error.log"

include conf_dir + "/conf.d/access_log.conf"
include conf_dir + "/conf.d/debug.conf"

server.max-fds = 16384

index-file.names += (
    "index.xhtml", "index.html", "index.htm", "default.htm", "index.php"
)

url.access-deny = ( "~", ".inc" )

static-file.exclude-extensions = ( ".php", ".p1", ".fcgi", ".scgi" )

include conf_dir + "/conf.d/mime.conf"

include conf_dir + "/conf.d/dirlisting.conf"

\$SERVER["socket"] == ":$puerto" {
    ssl.engine = "enable"
    ssl.pemfile = "/etc/ssl/pem/certificate.pem"
}
EOF
}

function deshabilitarSslLighttpd(){
    local ruta=$1
    local puerto=$2

    > $ruta
    sudo bash -c "cat > $ruta" << EOF
var.log_root = "var/log/lighttpd"
var.server_root = "/srv/www"
var.state_dir = "/run"
var.home_dir = "/var/lib/lighttpd"
var.conf_dir = "/etc/lighttpd"

var.vhosts_dir = server_root + "/vhosts"
var.cache_dir = "/var/cache/lighttpd"
var.socket_dir = home_dir + "/sockets"

include conf_dir + "/modules.conf"

server.port = $puerto

server.username = "lighttpd"
server.groupname = "lighttpd"

server.document-root = server_root + "/htdocs"

server.pid-file = state_dir + "lighttpd.pid"

server.errorlog = log_root + "/error.log"

include conf_dir + "/conf.d/access_log.conf"
include conf_dir + "/conf.d/debug.conf"

server.max-fds = 16384

index-file.names += (
    "index.xhtml", "index.html", "index.htm", "default.htm", "index.php"
)

url.access-deny = ( "~", ".inc" )

static-file.exclude-extensions = ( ".php", ".p1", ".fcgi", ".scgi" )

include conf_dir + "/conf.d/mime.conf"

include conf_dir + "/conf.d/dirlisting.conf"
EOF
}

versionRegex='[0-9]+\.[0-9]+\.[0-9]+'

if [ "$opcInstall" = "ftp" ]; then
    while :
    do
        echo "Menu de instalacion FTP"
        echo "Servicios disponibles"
        curl $ftpUrl/ubuntu/
        echo "Selecciona una opcion (escribe salir para salir): "
        read opcion

        declare -l opcion
        opcSsl=$opcion

        case "$opcion" in
            "apache")
                curl $ftpUrl/ubuntu/apache/
                apacheDescargas="https://httpd.apache.org/download.cgi"
                paginaApache=$(hacerPeticion "$apacheDescargas")
                ultimaVersionLTSApache=$(encontrarValor "$versionRegex" "$paginaApache")

                echo "Instalador de Apache"
                echo "1. Ultima version LTS $ultimaVersionLTSApache"
                echo "2. Version de desarrollo"
                echo "3. Salir"
                echo "Selecciona una opcion: "
                read opcApache

                case "$opcApache" in
                    "1")
                        echo "Ingresa el puerto en el que se instalara Apache: "
                        read puerto

                        if ! esPuertoValido "$puerto"; then
                            echo "Error"
                        elif ! esValorEntero "$puerto"; then
                            echo "El puerto debe de ser un valor numerico entero"
                        elif ! esRangoValido "$puerto"; then
                            echo "Ingresa un numero dentro del rango (0-65535)"
                        elif puertoEnUso "$puerto"; then
                            echo "El puerto se encuentra en uso"
                        else
                            echo "Desea activar SSL? (si/no)"
                            read opcSsl

                            declare -l opcSsl
                            opcSsl=$opcSsl


                            curl "$ftpUrl/ubuntu/apache/httpd-$ultimaVersionLTSApache.tar.gz" -O
                            # Descomprimir archivo
                            sudo tar -xvzf httpd-$ultimaVersionLTSApache.tar.gz > /dev/null 2>&1
                            # Entrar a la carpeta
                            cd "httpd-$ultimaVersionLTSApache"
                            # Compilar
                            ./configure --prefix=/usr/local/apache > /dev/null 2>&1
                            # Instalación
                            make > /dev/null 2>&1

                            sudo make install > /dev/null 2>&1
                            # Verificar la instalación
                            /usr/local/apache/bin/httpd -v
                            rutaArchivoConfiguracion="/usr/local/apache/conf/httpd.conf"
                            # Remuevo el puerto en uso
                            sudo sed -i '/^Listen/d' $rutaArchivoConfiguracion
                            # Añado el puerto proporcionado por el usuario
                            sudo printf "Listen $puerto\n" >> $rutaArchivoConfiguracion
                            echo "Escuchando en el puerto $puerto"
                            # Compruebo que realmente esté escuchando en ese puerto
                            sudo grep -i "Listen $puerto" $rutaArchivoConfiguracion
                            sudo /usr/local/apache/bin/apachectl restart
                            ps aux | grep httpd

                            if [ "$opcSsl" = "si" ]; then
                                echo "Habilitando SSL..."
                                habilitarSSLApache "$puerto"
                            elif [ "$opcSsl" = "no" ]; then
                                echo "SSL no se habilitara"
                            else
                                echo "Selecciona una opcion valida (si/no)"
                            fi
                        fi
                    ;;
                    "2")
                        echo "Apache no cuenta con version de desarrollo"
                    ;;
                    "3")
                        echo "Saliendo del menu de apache..."
                    ;;
                    *)
                        echo "Selecciona una opcion valida (1..3)"
                    ;;
                esac
            ;;
            "lighttpd")
                curl $ftpUrl/ubuntu/lighttpd/
                lightDescargas="https://www.lighttpd.net/releases/"
                paginaLight=$(hacerPeticion "$lightDescargas")
                ultimaVersionDevLighttpd=$(encontrarValor "$versionRegex" "$paginaLight") 
                versiones=$(echo "$paginaLight" | grep -oE "$versionRegex")
                ultimaVersionLTSLighttpd=$(obtenerVersionLTS 2 "$versiones")

                echo "Instalador de Lighttpd"
                echo "1. Ultima version LTS $ultimaVersionLTSLighttpd"
                echo "2. Version de desarrollo $ultimaVersionDevLighttpd"
                echo "3. Salir"
                echo "Selecciona una opcion: "
                read opcLighttpd

                case "$opcLighttpd" in
                    "1")
                        echo "Ingresa el puerto en el que se instalara Lighttpd: "
                        read puerto

                        if ! esPuertoValido "$puerto"; then
                            echo "Error"
                        elif ! esValorEntero "$puerto"; then
                            echo "El puerto debe de ser un valor numerico entero"
                        elif ! esRangoValido "$puerto"; then
                            echo "Ingresa un numero dentro del rango (0-65535)"
                        elif puertoEnUso "$puerto"; then
                            echo "El puerto se encuentra en uso"
                        else
                            echo "Quieres habilitar SSL? (si/no):"
                            read opcSsl

                            declare -l opcSsl
                            opcSsl=$opcSsl

                            if [ "$opcSsl" = "si" ]; then
                                echo "Habilitando SSL..."
                                sudo pkill lighttpd
                                echo "Ultima version -> $ultimaVersionLTSLighttpd"
                                echo "Instalando version $ultimaVersionLTSLighttpd de Lighttpd"
                                echo "Por favor espere..."
                                curl "$ftpUrl/ubuntu/lighttpd/lighttpd-$ultimaVersionLTSLighttpd.tar.gz" -O
                                sudo tar -xvzf "lighttpd-$ultimaVersionLTSLighttpd.tar.gz" > /dev/null 2>&1
                                cd "lighttpd-$ultimaVersionLTSLighttpd"
                                sudo bash autogen.sh > /dev/null 2>&1
                                ./configure --prefix=/usr/local/lighttpd --with-openssl > /dev/null 2>&1
                                make -j$(nproc) > /dev/null 2>&1
                                sudo make install > /dev/null 2>&1
                                /usr/local/lighttpd/sbin/lighttpd -v
                                rutaArchivoConfiguracion=/etc/lighttpd/lighttpd.conf
                                habilitarSslLighttpd "$rutaArchivoConfiguracion" "$puerto"
                                sudo sed -i '/mod_Foo/d' /etc/lighttpd/modules.conf
                                sudo grep -i "server.port" "/etc/lighttpd/lighttpd.conf"
                                sudo /usr/local/lighttpd/sbin/lighttpd -f /etc/lighttpd/lighttpd.conf
                                ps aux | grep lighttpd
                            elif [ "$opcSsl" = "no" ]; then
                                echo "SSL no se habilitara"
                                sudo pkill lighttpd
                                echo "Ultima version -> $ultimaVersionLTSLighttpd"
                                echo "Instalando version $ultimaVersionLTSLighttpd de Lighttpd"
                                echo "Por favor espere..."
                                curl "$ftpUrl/ubuntu/lighttpd/lighttpd-$ultimaVersionLTSLighttpd.tar.gz" -O
                                sudo tar -xvzf "lighttpd-$ultimaVersionLTSLighttpd.tar.gz" > /dev/null 2>&1
                                cd "lighttpd-$ultimaVersionLTSLighttpd"
                                sudo bash autogen.sh > /dev/null 2>&1
                                ./configure --prefix=/usr/local/lighttpd --with-openssl > /dev/null 2>&1
                                make -j$(nproc) > /dev/null 2>&1
                                sudo make install > /dev/null 2>&1
                                /usr/local/lighttpd/sbin/lighttpd -v
                                rutaArchivoConfiguracion=/etc/lighttpd/lighttpd.conf
                                deshabilitarSslLighttpd "$rutaArchivoConfiguracion" "$puerto"
                                sudo sed -i '/mod_Foo/d' /etc/lighttpd/modules.conf
                                sudo grep -i "server.port" "/etc/lighttpd/lighttpd.conf"
                                sudo /usr/local/lighttpd/sbin/lighttpd -f /etc/lighttpd/lighttpd.conf
                                ps aux | grep lighttpd
                            else
                                echo "Selecciona una opcion valida (si/no)"
                            fi
                        fi
                    ;;
                    "2")
                        echo "Ingresa el puerto en el que se instalara Lighttpd: "
                        read puerto

                        if ! esPuertoValido "$puerto"; then
                            echo "Error"
                        elif ! esValorEntero "$puerto"; then
                            echo "El puerto debe de ser un valor numerico entero"
                        elif ! esRangoValido "$puerto"; then
                            echo "Ingresa un numero dentro del rango (0-65535)"
                        elif puertoEnUso "$puerto"; then
                            echo "El puerto se encuentra en uso"
                        else
                            echo "Quieres habilitar SSL? (si/no):"
                            read opcSsl

                            declare -l opcSsl
                            opcSsl=$opcSsl

                            if [ "$opcSsl" = "si" ]; then
                                echo "Habilitando SSL..."
                                sudo pkill lighttpd
                                echo "Ultima version -> $ultimaVersionDevLighttpd"
                                echo "Instalando version $ultimaVersionDevLighttpd de Lighttpd"
                                echo "Por favor espere..."
                                curl "$ftpUrl/ubuntu/lighttpd/lighttpd-$ultimaVersionDevLighttpd.tar.gz" -O
                                sudo tar -xvzf "lighttpd-$ultimaVersionDevLighttpd.tar.gz" > /dev/null 2>&1
                                cd "lighttpd-$ultimaVersionDevLighttpd"
                                sudo bash autogen.sh > /dev/null 2>&1
                                ./configure --prefix=/usr/local/lighttpd --with-openssl > /dev/null 2>&1
                                make -j$(nproc) > /dev/null 2>&1
                                sudo make install > /dev/null 2>&1
                                /usr/local/lighttpd/sbin/lighttpd -v
                                rutaArchivoConfiguracion=/etc/lighttpd/lighttpd.conf
                                habilitarSslLighttpd "$rutaArchivoConfiguracion" "$puerto"
                                sudo sed -i '/mod_Foo/d' /etc/lighttpd/modules.conf
                                sudo grep -i "server.port" "/etc/lighttpd/lighttpd.conf"
                                sudo /usr/local/lighttpd/sbin/lighttpd -f /etc/lighttpd/lighttpd.conf
                                ps aux | grep lighttpd
                            elif [ "$opcSsl" = "no" ]; then
                                echo "SSL no se habilitara"
                                sudo pkill lighttpd
                                echo "Ultima version -> $ultimaVersionDevLighttpd"
                                echo "Instalando version $ultimaVersionDevLighttpd de Lighttpd"
                                echo "Por favor espere..."
                                curl "$ftpUrl/ubuntu/lighttpd/lighttpd-$ultimaVersionDevLighttpd.tar.gz" -O
                                sudo tar -xvzf "lighttpd-$ultimaVersionDevLighttpd.tar.gz" > /dev/null 2>&1
                                cd "lighttpd-$ultimaVersionDevLighttpd"
                                sudo bash autogen.sh > /dev/null 2>&1
                                ./configure --prefix=/usr/local/lighttpd --with-openssl > /dev/null 2>&1
                                make -j$(nproc) > /dev/null 2>&1
                                sudo make install > /dev/null 2>&1
                                /usr/local/lighttpd/sbin/lighttpd -v
                                rutaArchivoConfiguracion=/etc/lighttpd/lighttpd.conf
                                deshabilitarSslLighttpd "$rutaArchivoConfiguracion" "$puerto"
                                sudo sed -i '/mod_Foo/d' /etc/lighttpd/modules.conf
                                sudo grep -i "server.port" "/etc/lighttpd/lighttpd.conf"
                                sudo /usr/local/lighttpd/sbin/lighttpd -f /etc/lighttpd/lighttpd.conf
                                ps aux | grep lighttpd
                            else
                                echo "Selecciona una opcion valida (si/no)"
                            fi
                        fi
                    ;;
                    "3")
                        echo "Saliendo del menu de lighttpd"
                    ;;
                esac
            ;;
            "nginx")
                curl $ftpUrl/ubuntu/nginx/
                nginxDescargas="https://nginx.org/en/download.html"
                paginaNginx=$(hacerPeticion "$nginxDescargas")
                ultimaVersionNginxDev=$(encontrarValor "$versionRegex" "$paginaNginx")
                versiones=$(echo "$paginaNginx" | grep -oE "$versionRegex")
                nginxVersionLTS=$(obtenerVersionLTS 8 "$versiones")

                rutaArchivoConfiguracion="/usr/local/nginx/conf/nginx.conf"

                echo "Instalador de Nginx"
                echo "1. Ultima version LTS $nginxVersionLTS"
                echo "2. Version de desarrollo $ultimaVersionNginxDev"
                echo "3. Salir"
                echo "Selecciona una opcion: "
                read opcNginx

                case "$opcNginx" in
                    "1")
                        echo "Ingresa el puerto en el que se instalará Nginx: "
                        read puerto

                        if ! esPuertoValido "$puerto"; then
                            echo "Error"
                        elif ! esValorEntero "$puerto"; then
                            echo "El puerto debe de ser un valor numerico entero"
                        elif ! esRangoValido "$puerto"; then
                            echo "Ingresa un numero dentro del rango (0-65535)"
                        elif puertoEnUso "$puerto"; then
                            echo "El puerto esta en uso"
                        else
                            echo "Quieres habilitar SSL? (si/no): "
                            read opcSsl

                            declare -l opcSsl
                            opcSsl=$opcSsl

                            if [ "$opcSsl" = "si" ]; then
                                echo "Habilitando SSL..."
                                curl "$ftpUrl/ubuntu/nginx/nginx-$nginxVersionLTS.tar.gz" -O
                                /usr/local/nginx/sbin/nginx -v
                                habilitarSSLNginx "$rutaArchivoConfiguracion" "$puerto"
                                sudo grep -i "listen\s\s\s\s\s\s\s" "$rutaArchivoConfiguracion"
                                sudo /usr/local/nginx/sbin/nginx
                                sudo /usr/local/nginx/sbin/nginx -s reload
                                ps aux | grep nginx
                            elif [ "$opcSsl" = "no" ]; then
                                echo "SSL no se habilitara"
                                curl "$ftpUrl/ubuntu/nginx/nginx-$nginxVersionLTS.tar.gz" -O
                                /usr/local/nginx/sbin/nginx -v
                                deshabilitarSSLNginx "$rutaArchivoConfiguracion" "$puerto"
                                sudo grep -i "listen\s\s\s\s\s\s\s" "$rutaArchivoConfiguracion"
                                sudo /usr/local/nginx/sbin/nginx
                                sudo /usr/local/nginx/sbin/nginx -s reload
                            else
                                echo "Selecciona una opcion valida (si/no)"
                            fi
                        fi
                    ;;
                    "2")
                        echo "Ingresa el puerto en el que se instalará Nginx: "
                        read puerto

                        if ! esPuertoValido "$puerto"; then
                            echo "Error"
                        elif ! esValorEntero "$puerto"; then
                            echo "El puerto debe de ser un valor numerico entero"
                        elif ! esRangoValido "$puerto"; then
                            echo "Ingresa un numero dentro del rango (0-65535)"
                        elif puertoEnUso "$puerto"; then
                            echo "El puerto esta en uso"
                        else
                            echo "Quieres habilitar SSL? (si/no): "
                            read opcSsl

                            declare -l opcSsl
                            opcSsl=$opcSsl

                            if [ "$opcSsl" = "si" ]; then
                                echo "Habilitando SSL..."
                                curl "$ftpUrl/ubuntu/nginx/nginx-$ultimaVersionNginxDev.tar.gz" -O
                                /usr/local/nginx/sbin/nginx -v
                                habilitarSSLNginx "$rutaArchivoConfiguracion" "$puerto"
                                sudo grep -i "listen\s\s\s\s\s\s\s" "$rutaArchivoConfiguracion"
                                sudo /usr/local/nginx/sbin/nginx
                                sudo /usr/local/nginx/sbin/nginx -s reload
                                ps aux | grep nginx
                            elif [ "$opcSsl" = "no" ]; then
                                echo "SSL no se habilitara"
                                curl "$ftpUrl/ubuntu/nginx/nginx-$ultimaVersionNginxDev.tar.gz" -O
                                /usr/local/nginx/sbin/nginx -v
                                deshabilitarSSLNginx "$rutaArchivoConfiguracion" "$puerto"
                                sudo grep -i "listen\s\s\s\s\s\s\s" "$rutaArchivoConfiguracion"
                                sudo /usr/local/nginx/sbin/nginx
                                sudo /usr/local/nginx/sbin/nginx -s reload
                            else
                                echo "Selecciona una opcion valida (si/no)"
                            fi
                        fi
                    ;;
                    "3")
                        echo "Saliendo del menu de nginx"
                    ;;
                esac
            ;;
            *)
                echo "Archivos disponibles para descarga"
                curl $ftpUrl/ubuntu/$opcion/
                if [ -d /home/jj/ftp/http/ubuntu/$opcion ]; then
                    echo "Ingresa el nombre del archivo a descargar, incluye tambien su extension: "
                    read archivo
                    if [ ! -f /home/jj/ftp/http/ubuntu/$opcion/$archivo ]; then
                        echo "El archivo no fue encontrado"
                    else
                        echo "Descargando archivo..."
                        curl $ftpUrl/ubuntu/$opcion/$archivo -O
                    fi
                else
                    echo "El directorio no existe"
                fi
            ;;
            "salir")
                echo "Saliendo..."
                break
            ;;
        esac

    done
elif [ "$opcInstall" = "web" ]; then
    while :
    do
        echo "Menu de instalacion web"
        echo "Elige el servicio a instalar"
        echo "1. Apache"
        echo "2. Lighttpd"
        echo "3. Nginx"
        echo "4. Salir"
        echo "Selecciona una opcion: "
        read opcion

        case "$opcion" in
            "1")
                apacheDescargas="https://httpd.apache.org/download.cgi"
                paginaApache=$(hacerPeticion "$apacheDescargas")
                ultimaVersionLTSApache=$(encontrarValor "$versionRegex" "$paginaApache")

                echo "Instalador de Apache"
                echo "1. Ultima version LTS $ultimaVersionLTSApache"
                echo "2. Version de desarrollo"
                echo "3. Salir"
                echo "Selecciona una opcion: "
                read opcApache

                case "$opcApache" in
                    "1")
                        echo "Ingresa el puerto en el que se instalara Apache: "
                        read puerto

                        if ! esPuertoValido "$puerto"; then
                            echo "Error"
                        elif ! esValorEntero "$puerto"; then
                            echo "El puerto debe de ser un valor numerico entero"
                        elif ! esRangoValido "$puerto"; then
                            echo "Ingresa un numero dentro del rango (0-65535)"
                        elif puertoEnUso "$puerto"; then
                            echo "El puerto se encuentra en uso"
                        else
                            echo "Deseas realizar la instalacion desde la web o desde ftp? (web/ftp): "
                            read opcDescarga

                            declare -l opcDescarga
                            opcDescarga=$opcDescarga

                            echo "Desea activar SSL? (si/no)"
                            read opcSsl

                            declare -l opcSsl
                            opcSsl=$opcSsl

                            instalarServicioHTTP "$ultimaVersionLTSApache" "https://dlcdn.apache.org/httpd/httpd-$ultimaVersionLTSApache.tar.gz" "httpd-$ultimaVersionLTSApache.tar.gz" "httpd-$ultimaVersionLTSApache" "apache"

                            # Verificar la instalación
                            /usr/local/apache/bin/httpd -v
                            rutaArchivoConfiguracion="/usr/local/apache/conf/httpd.conf"
                            # Remuevo el puerto en uso
                            sudo sed -i '/^Listen/d' $rutaArchivoConfiguracion
                            # Añado el puerto proporcionado por el usuario
                            sudo printf "Listen $puerto\n" >> $rutaArchivoConfiguracion
                            echo "Escuchando en el puerto $puerto"
                            # Compruebo que realmente esté escuchando en ese puerto
                            sudo grep -i "Listen $puerto" $rutaArchivoConfiguracion
                            sudo /usr/local/apache/bin/apachectl restart
                            ps aux | grep httpd

                            if [ "$opcSsl" = "si" ]; then
                                echo "Habilitando SSL..."
                                habilitarSSLApache "$puerto"
                            elif [ "$opcSsl" = "no" ]; then
                                echo "SSL no se habilitara"
                            else
                                echo "Selecciona una opcion valida (si/no)"
                            fi
                        fi
                    ;;
                    "2")
                        echo "Apache no cuenta con una version de desarrollo"
                    ;;
                    "3")
                        echo "Saliendo del menu de apache..."
                    ;;
                    *)
                        echo "Selecciona una opcion valida (1..3)"
                    ;;
                esac
            ;;
            "2")
                lightDescargas="https://www.lighttpd.net/releases/"
                paginaLight=$(hacerPeticion "$lightDescargas")
                ultimaVersionDevLighttpd=$(encontrarValor "$versionRegex" "$paginaLight") 
                versiones=$(echo "$paginaLight" | grep -oE "$versionRegex")
                ultimaVersionLTSLighttpd=$(obtenerVersionLTS 2 "$versiones")

                echo "Instalador de Lighttpd"
                echo "1. Ultima version LTS $ultimaVersionLTSLighttpd"
                echo "2. Version de desarrollo $ultimaVersionDevLighttpd"
                echo "3. Salir"
                echo "Selecciona una opcion: "
                read opcLighttpd

                rutaArchivoConfiguracion=""

                case "$opcLighttpd" in
                    "1")
                        echo "Ingresa el puerto en el que se instalara Lighttpd: "
                        read puerto

                        if ! esPuertoValido "$puerto"; then
                            echo "Error"
                        elif ! esValorEntero "$puerto"; then
                            echo "El puerto debe de ser un valor numerico entero"
                        elif ! esRangoValido "$puerto"; then
                            echo "Ingresa un numero dentro del rango (0-65535)"
                        elif puertoEnUso "$puerto"; then
                            echo "El puerto se encuentra en uso"
                        else
                            echo "Quieres habilitar SSL? (si/no):"
                            read opcSsl

                            declare -l opcSsl
                            opcSsl=$opcSsl

                            if [ "$opcSsl" = "si" ]; then
                                echo "Habilitando SSL..."
                                sudo pkill lighttpd
                                echo "Ultima version -> $ultimaVersionLTSLighttpd"
                                echo "Instalando version $ultimaVersionLTSLighttpd de Lighttpd"
                                echo "Por favor espere..."
                                curl -s -O "https://download.lighttpd.net/lighttpd/releases-1.4.x/lighttpd-$ultimaVersionLTSLighttpd.tar.gz"
                                sudo tar -xvzf "lighttpd-$ultimaVersionLTSLighttpd.tar.gz" > /dev/null 2>&1
                                cd "lighttpd-$ultimaVersionLTSLighttpd"
                                sudo bash autogen.sh > /dev/null 2>&1
                                ./configure --prefix=/usr/local/lighttpd --with-openssl > /dev/null 2>&1
                                make -j$(nproc) > /dev/null 2>&1
                                sudo make install > /dev/null 2>&1
                                /usr/local/lighttpd/sbin/lighttpd -v
                                rutaArchivoConfiguracion=/etc/lighttpd/lighttpd.conf
                                habilitarSslLighttpd "$rutaArchivoConfiguracion" "$puerto"
                                sudo sed -i '/mod_Foo/d' /etc/lighttpd/modules.conf
                                sudo grep -i "server.port" "/etc/lighttpd/lighttpd.conf"
                                sudo /usr/local/lighttpd/sbin/lighttpd -f /etc/lighttpd/lighttpd.conf
                                ps aux | grep lighttpd
                            elif [ "$opcSsl" = "no" ]; then
                                echo "SSL no se habilitara"
                                sudo pkill lighttpd
                                echo "Ultima version -> $ultimaVersionLTSLighttpd"
                                echo "Instalando version $ultimaVersionLTSLighttpd de Lighttpd"
                                echo "Por favor espere..."
                                curl -s -O "https://download.lighttpd.net/lighttpd/releases-1.4.x/lighttpd-$ultimaVersionLTSLighttpd.tar.gz"
                                sudo tar -xvzf "lighttpd-$ultimaVersionLTSLighttpd.tar.gz" > /dev/null 2>&1
                                cd "lighttpd-$ultimaVersionLTSLighttpd"
                                sudo bash autogen.sh > /dev/null 2>&1
                                ./configure --prefix=/usr/local/lighttpd --with-openssl > /dev/null 2>&1
                                make -j$(nproc) > /dev/null 2>&1
                                sudo make install > /dev/null 2>&1
                                /usr/local/lighttpd/sbin/lighttpd -v
                                rutaArchivoConfiguracion=/etc/lighttpd/lighttpd.conf
                                deshabilitarSslLighttpd "$rutaArchivoConfiguracion" "$puerto"
                                sudo sed -i '/mod_Foo/d' /etc/lighttpd/modules.conf
                                sudo grep -i "server.port" "/etc/lighttpd/lighttpd.conf"
                                sudo /usr/local/lighttpd/sbin/lighttpd -f /etc/lighttpd/lighttpd.conf
                                ps aux | grep lighttpd
                            else
                                echo "Selecciona una opcion valida (si/no)"
                            fi
                        fi
                    ;;
                    "2")
                        echo "Ingresa el puerto en el que se instalara Lighttpd: "
                        read puerto

                        if ! esPuertoValido "$puerto"; then
                            echo "Error"
                        elif ! esValorEntero "$puerto"; then
                            echo "El puerto debe de ser un valor numerico entero"
                        elif ! esRangoValido "$puerto"; then
                            echo "Ingresa un numero dentro del rango (0-65535)"
                        elif puertoEnUso "$puerto"; then
                            echo "El puerto esta en uso"
                        else
                            echo "Quieres habilitar SSL? (si/no):"
                            read opcSsl

                            declare -l opcSsl
                            opcSsl=$opcSsl

                            if [ "$opcSsl" = "si" ]; then
                                echo "Habilitando SSL..."
                                sudo pkill lighttpd
                                echo "Ultima version -> $ultimaVersionDevLighttpd"
                                echo "Instalando version $ultimaVersionDevLighttpd de Lighttpd"
                                echo "Por favor espere..."
                                curl -s -O "https://download.lighttpd.net/lighttpd/releases-1.4.x/lighttpd-$ultimaVersionDevLighttpd.tar.gz"
                                sudo tar -xvzf "lighttpd-$ultimaVersionDevLighttpd.tar.gz" > /dev/null 2>&1
                                cd "lighttpd-$ultimaVersionDevLighttpd"
                                sudo bash autogen.sh > /dev/null 2>&1
                                ./configure --prefix=/usr/local/lighttpd --with-openssl > /dev/null 2>&1
                                make -j$(nproc) > /dev/null 2>&1
                                sudo make install > /dev/null 2>&1
                                /usr/local/lighttpd/sbin/lighttpd -v
                                rutaArchivoConfiguracion=/etc/lighttpd/lighttpd.conf
                                habilitarSslLighttpd "$rutaArchivoConfiguracion" "$puerto"
                                sudo sed -i '/mod_Foo/d' /etc/lighttpd/modules.conf
                                sudo grep -i "server.port" "/etc/lighttpd/lighttpd.conf"
                                sudo /usr/local/lighttpd/sbin/lighttpd -f /etc/lighttpd/lighttpd.conf
                                ps aux | grep lighttpd
                            elif [ "$opcSsl" = "no" ]; then
                                echo "SSL no se habilitara"
                                sudo pkill lighttpd
                                echo "Ultima version -> $ultimaVersionDevLighttpd"
                                echo "Instalando version $ultimaVersionDevLighttpd de Lighttpd"
                                echo "Por favor espere..."
                                curl -s -O "https://download.lighttpd.net/lighttpd/releases-1.4.x/lighttpd-$ultimaVersionDevLighttpd.tar.gz"
                                sudo tar -xvzf "lighttpd-$ultimaVersionDevLighttpd.tar.gz" > /dev/null 2>&1
                                cd "lighttpd-$ultimaVersionDevLighttpd"
                                sudo bash autogen.sh > /dev/null 2>&1
                                ./configure --prefix=/usr/local/lighttpd --with-openssl > /dev/null 2>&1
                                make -j$(nproc) > /dev/null 2>&1
                                sudo make install > /dev/null 2>&1
                                /usr/local/lighttpd/sbin/lighttpd -v
                                rutaArchivoConfiguracion=/etc/lighttpd/lighttpd.conf
                                deshabilitarSslLighttpd "$rutaArchivoConfiguracion" "$puerto"
                                sudo sed -i '/mod_Foo/d' /etc/lighttpd/modules.conf
                                sudo grep -i "server.port" "/etc/lighttpd/lighttpd.conf"
                                sudo /usr/local/lighttpd/sbin/lighttpd -f /etc/lighttpd/lighttpd.conf
                                ps aux | grep lighttpd
                            else
                                echo "Selecciona una opcion valida (si/no)"
                            fi
                        fi
                    ;;
                    "3")
                        echo "Saliendo del menu de Lighttpd..."
                    ;;
                    *)
                        echo "Selecciona una opcion dentro del rango (1..3)"
                    ;;
                esac
            ;;
            "3")
                nginxDescargas="https://nginx.org/en/download.html"
                paginaNginx=$(hacerPeticion "$nginxDescargas")
                ultimaVersionNginxDev=$(encontrarValor "$versionRegex" "$paginaNginx")
                versiones=$(echo "$paginaNginx" | grep -oE "$versionRegex")
                nginxVersionLTS=$(obtenerVersionLTS 8 "$versiones")

                rutaArchivoConfiguracion="/usr/local/nginx/conf/nginx.conf"

                echo "Instalador de Nginx"
                echo "1. Ultima version LTS $nginxVersionLTS"
                echo "2. Version de desarrollo $ultimaVersionNginxDev"
                echo "3. Salir"
                echo "Selecciona una opcion: "
                read opcNginx

                case "$opcNginx" in
                    "1")
                        echo "Ingresa el puerto en el que se instalará Nginx: "
                        read puerto

                        if ! esPuertoValido "$puerto"; then
                            echo "Error"
                        elif ! esValorEntero "$puerto"; then
                            echo "El puerto debe de ser un valor numerico entero"
                        elif ! esRangoValido "$puerto"; then
                            echo "Ingresa un numero dentro del rango (0-65535)"
                        elif puertoEnUso "$puerto"; then
                            echo "El puerto esta en uso"
                        else
                            echo "Quieres habilitar SSL? (si/no): "
                            read opcSsl

                            declare -l opcSsl
                            opcSsl=$opcSsl

                            if [ "$opcSsl" = "si" ]; then
                                echo "Habilitando SSL..."
                                instalarNginx "$nginxVersionLTS" "https://nginx.org/download/nginx-$nginxVersionLTS.tar.gz" "nginx-$nginxVersionLTS.tar.gz" "nginx-$nginxVersionLTS" "nginx"
                                /usr/local/nginx/sbin/nginx -v
                                habilitarSSLNginx "$rutaArchivoConfiguracion" "$puerto"
                                sudo grep -i "listen\s\s\s\s\s\s\s" "$rutaArchivoConfiguracion"
                                sudo /usr/local/nginx/sbin/nginx
                                sudo /usr/local/nginx/sbin/nginx -s reload
                                ps aux | grep nginx
                            elif [ "$opcSsl" = "no" ]; then
                                echo "SSL no se habilitara"
                                instalarNginx "$nginxVersionLTS" "https://nginx.org/download/nginx-$nginxVersionLTS.tar.gz" "nginx-$nginxVersionLTS.tar.gz" "nginx-$nginxVersionLTS" "nginx"
                                /usr/local/nginx/sbin/nginx -v
                                deshabilitarSSLNginx "$rutaArchivoConfiguracion" "$puerto"
                                sudo grep -i "listen\s\s\s\s\s\s\s" "$rutaArchivoConfiguracion"
                                sudo /usr/local/nginx/sbin/nginx
                                sudo /usr/local/nginx/sbin/nginx -s reload
                            else
                                echo "Selecciona una opcion valida (si/no)"
                            fi
                        fi
                    ;;
                    "2")
                        echo "Ingresa el puerto en el que se instalará Nginx: "
                        read puerto

                        if ! esPuertoValido "$puerto"; then
                            echo "Error"
                        elif ! esValorEntero "$puerto"; then
                            echo "El puerto debe de ser un valor numerico entero"
                        elif ! esRangoValido "$puerto"; then
                            echo "Ingresa un numero dentro del rango (0-65535)"
                        elif puertoEnUso "$puerto"; then
                            echo "El puerto esta en uso"
                        else
                            echo "Quieres habilitar SSL? (si/no): "
                            read opcSsl

                            declare -l opcSsl
                            opcSsl=$opcSsl

                            if [ "$opcSsl" = "si" ]; then
                                echo "Habilitando SSL..."
                                instalarNginx "$ultimaVersionNginxDev" "https://nginx.org/download/nginx-$ultimaVersionNginxDev.tar.gz" "nginx-$ultimaVersionNginxDev.tar.gz" "nginx-$ultimaVersionNginxDev" "nginx"
                                /usr/local/nginx/sbin/nginx -v
                                habilitarSSLNginx "$rutaArchivoConfiguracion" "$puerto"
                                sudo grep -i "listen\s\s\s\s\s\s\s" "$rutaArchivoConfiguracion"
                                sudo /usr/local/nginx/sbin/nginx
                                sudo /usr/local/nginx/sbin/nginx -s reload
                                ps aux | grep nginx
                            elif [ "$opcSsl" = "no" ]; then
                                echo "SSL no se habilitara"
                                instalarNginx "$ultimaVersionNginxDev" "https://nginx.org/download/nginx-$ultimaVersionNginxDev.tar.gz" "nginx-$ultimaVersionNginxDev.tar.gz" "nginx-$ultimaVersionNginxDev" "nginx"
                                /usr/local/nginx/sbin/nginx -v
                                deshabilitarSSLNginx "$rutaArchivoConfiguracion" "$puerto"
                                sudo grep -i "listen\s\s\s\s\s\s\s" "$rutaArchivoConfiguracion"
                                sudo /usr/local/nginx/sbin/nginx
                                sudo /usr/local/nginx/sbin/nginx -s reload
                            else
                                echo "Selecciona una opcion valida (si/no)"
                            fi
                        fi
                    ;;
                    "3")
                        echo "Saliendo del menu de Nginx..."
                    ;;
                    *)
                        echo "Selecciona una opcion valida (1..3)"
                    ;;
                esac
            ;;
            "4")
                echo "Saliendo..."
                break
            ;;
            *)
                echo "Selecciona una opcion dentro del rango (1..4)"
            ;;
        esac
        echo ""
    done
else
    echo "Selecciona una opcion valida (web/ftp)"
fi