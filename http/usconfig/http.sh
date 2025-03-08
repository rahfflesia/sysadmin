# Ya funciona la instalacion de apache, en cualquier inconveniente puedo volver a este commit
# $1 = URL, Retorna el html
function hacerPeticion(){
    local url=$1
    local html=$(curl -s "$url")
    echo "${html}"
}

# $1 = Expresión regular, $2 = String a comparar
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
            ultimaVersionApache=$(encontrarValor "$versionRegex" "$paginaApache")

            echo "Instalador de Apache"
            echo "1. Ultima version LTS $ultimaVersionApache"
            echo "2. Version de desarrollo"
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
                        echo "Ultima version -> $ultimaVersionApache"
                        echo "Instalando version $ultimaVersionApache de Apache"
                        echo "Por favor espere..."
                        linkDescargaApache="https://dlcdn.apache.org/httpd/httpd-$ultimaVersionApache.tar.gz"
                        curl "$linkDescargaApache" -s -o apache.tar.gz
                        # Descomprimir archivo
                        tar -xvzf apache.tar.gz > /dev/null 2>&1
                        # Entrar a la carpeta
                        cd httpd-$ultimaVersionApache
                        # Compilar
                        ./configure --prefix=/usr/local/apache2 > /dev/null 2>&1
                        # Instalación
                        make > /dev/null 2>&1
                        sudo make install > /dev/null 2>&1
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
                *)
                    echo "Selecciona una opcion valida (1..2)"
                ;;
            esac
        ;;
        "2")
        ;;
        "3")
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