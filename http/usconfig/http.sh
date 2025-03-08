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

            # Mostrar pagina para depuracion
            echo "$paginaApache"

            echo "Instalador de Apache"
            echo "1. Ultima version LTS $ultimaVersionApache"
            echo "Selecciona una opcion: "
            read opcApache

            case "$opcApache" in
                "1")
                    echo "Ultima version -> $ultimaVersionApache"
                    echo "Instalando version $ultimaVersionApache de Apache"
                    linkDescargaApache="https://dlcdn.apache.org/httpd/httpd-$ultimaVersionApache.tar.gz"
                    curl "$linkDescargaApache" -o apache.tar.gz
                    # Descomprimir archivo
                    tar -xvzf apache.tar.gz
                    # Entrar a la carpeta
                    cd httpd-$ultimaVersionApache
                    # Compilar
                    ./configure --prefix=/usr/local/apache2
                    # Instalación
                    make
                    sudo make install
                    # Verificar la instalación
                    /usr/local/apache2/bin/httpd -v
                ;;
                *)
                    echo "Selecciona una opcion valida"
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
            echo "Selecciona una opcion dentro del rango (1..3)"
        ;;
    esac
    echo ""
done