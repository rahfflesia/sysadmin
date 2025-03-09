# Ya funciona la instalacion de apache, en cualquier inconveniente puedo volver a este commit
# $1 = URL, Retorna el html
# Nginx funcional
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

function esPuertoValido(){
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

function desinstalarNginx(){
    sudo /usr/local/nginx/sbin/nginx -s stop
    sudo rm -r /usr/local/nginx
}

versionRegex='[0-9]+\.[0-9]+\.[0-9]+'

while :
do
    echo "Elige el servicio a instalar"
    echo "1. Apache"
    echo "2. Tomcat"
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
                        echo "El puerto debe de estar dentro del rango 0-65535"
                    elif ! esValorEntero "$puerto"; then
                        echo "El puerto debe de ser un valor numerico entero"
                    else
                        instalarServicioHTTP "$ultimaVersionLTSApache" "https://dlcdn.apache.org/httpd/httpd-$ultimaVersionLTSApache.tar.gz" "httpd-$ultimaVersionLTSApache.tar.gz" "httpd-$ultimaVersionLTSApache" "apache"
                        # Verificar la instalación
                        /usr/local/apache2/bin/httpd -v
                        rutaArchivoConfiguracion="/usr/local/apache2/conf/httpd.conf"
                        # Remuevo el puerto en uso
                        sudo sed -i '/^Listen/d' $rutaArchivoConfiguracion
                        # Añado el puerto proporcionado por el usuario
                        sudo printf "Listen $puerto" >> $rutaArchivoConfiguracion
                        # Compruebo que realmente esté escuchando en ese puerto
                        sudo grep -i "Listen $puerto" $rutaArchivoConfiguracion
                    fi
                ;;
                "2")
                    echo "Instalando version de desarrollo"
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
        ;;
        "3")
            nginxDescargas="https://nginx.org/en/download.html"
            paginaNginx=$(hacerPeticion "$nginxDescargas")
            ultimaVersionNginxDev=$(encontrarValor "$versionRegex" "$paginaNginx")
            versiones=$(echo "$paginaNginx" | grep -oE "$versionRegex")
            nginxVersionLTS=$(obtenerVersionLTS 8 "$versiones")

            $rutaArchivoConfiguracion = "/usr/local/nginx/conf/nginx.conf"

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
                        echo "El puerto debe de estar dentro del rango 0-65535"
                    elif ! esValorEntero "$puerto"; then
                        echo "El puerto debe de ser un valor numerico entero"
                    else
                        instalarServicioHTTP "$nginxVersionLTS" "https://nginx.org/download/nginx-$nginxVersionLTS.tar.gz" "nginx-$nginxVersionLTS.tar.gz" "nginx-$nginxVersionLTS" "nginx"
                        /usr/local/nginx/sbin/nginx -v

                        sed -E "/listen[[:space:]]{7}[0-9]{1,5}/listen       $puerto/" $rutaArchivoConfiguracion
                        sudo grep -i "listen\s\s\s\s\s\s\s" $rutaArchivoConfiguracion
                    fi
                ;;
                "2")
                    echo "Ingresa el puerto en el que se instalará Nginx: "
                    read puerto

                    if ! esPuertoValido "$puerto"; then
                        echo "El puerto debe de estar dentro del rango 0-65535"
                    elif ! esValorEntero "$puerto"; then
                        echo "El puerto debe de ser un valor numerico entero"
                    else
                        instalarServicioHTTP "$ultimaVersionNginxDev" "https://nginx.org/download/nginx-$ultimaVersionNginxDev.tar.gz" "nginx-$ultimaVersionNginxDev.tar.gz" "nginx-$ultimaVersionNginxDev" "nginx"
                        /usr/local/nginx/sbin/nginx -v
                        sed -E "/listen[[:space:]]{7}[0-9]{1,5}/listen       $puerto/" $rutaArchivoConfiguracion
                        sudo grep -i "listen\s\s\s\s\s\s\s" $rutaArchivoConfiguracion

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