function esIpValida(){
	local regex="^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"
    if [[ $1 =~ $regex ]]; then
        return 0
    else
        return 1
    fi
}

# La función espera en el primer parámetro la ip y en el segundo la máscara de subred
function obtenerIpBase(){
    arrayIp=
    arrayMascara=
    IFS='.' read -r -a arrayIp <<< "$1" # Ip
    IFS='.' read -r -a arrayMascara <<< "$2" # Máscara
    direccion=""

    for ((i = 0; i < "${#arrayIp[@]}"; i++)); do
        byte="$((arrayIp[i] & arrayMascara[i]))"
        if [[ $i -eq 0 ]]; then
            direccion="$byte"
        else
            direccion="$direccion.$byte"
        fi
    done
    echo "${direccion}"
}

function obtenerBroadcast(){
    local arrayIp=
    IFS='.' read -r -a arrayIp <<< "$1"
    direccion=""
    
    for ((i = 0; i < "${#arrayIp[@]}"; i++)); do
        byte="${arrayIp[$i]}"
        if [[ $byte -eq "0" ]]; then
            direccion="$direccion.255"
        else
            if [[ $i -eq 0 ]]; then
                direccion="$byte"
            else 
                direccion="$direccion.$byte"
            fi
        fi
    done
    echo "${direccion}"
}

function esConfiguracionValida(){
    if esIpValida "$1" && esIpValida "$2" && esIpValida "$3" && esIpValida "$4" && esIpValida "$5" && esIpValida "$6"; then
        return 0
    else
        return 1
    fi
}

# Pido los parámetros
echo "Ingresa el nombre del grupo: "
read grupo
echo "Ingresa la ip inicial: "
read ipInicial
echo "Ingresa la ip final: "
read ipFinal
echo "Ingresa la mascara de subred: "
read mascara
echo "Ingresa el servidor dns: "
read dns
echo "Ingresa la puerta de enlace: "
read gateway
echo "Ingresa la ip que tendra el DHCP: "
read ipDhcp

if esConfiguracionValida "$ipInicial" "$ipFinal" "$mascara" "$dns" "$gateway" "$ipDhcp"; then
    # Instalo el servicio de dhcp
    sudo apt-get install isc-dhcp-server
    # Asigno la ip de la subred al servidor dhcp, en mi caso la interfaz enp0s8 contendrá la dirección ip del dhcp
    sudo ifconfig enp0s8 "${ipDhcp}" netmask "${mascara}"

    rutaArchivoConfiguracion="/etc/dhcp/dhcpd.conf"
    # Escritura de los parámetros de configuración en el archivo
    sudo printf "\n" >> $rutaArchivoConfiguracion
    sudo printf "group ${grupo} {\n" >> $rutaArchivoConfiguracion

    ipBase=$(obtenerIpBase $ipInicial $mascara)
    broadcast=$(obtenerBroadcast $ipBase)

    sudo printf "   subnet ${ipBase} netmask ${mascara} {\n" >> $rutaArchivoConfiguracion
    sudo printf "       range ${ipInicial} ${ipFinal};\n" >> $rutaArchivoConfiguracion
    sudo printf "       option domain-name-servers ${dns};\n" >> $rutaArchivoConfiguracion
    sudo printf '       option domain-name "local";\n' >> $rutaArchivoConfiguracion
    sudo printf "       option subnet-mask ${mascara};\n" >> $rutaArchivoConfiguracion
    sudo printf "       option routers ${ipDhcp};\n" >> $rutaArchivoConfiguracion
    sudo printf "       option broadcast-address ${broadcast};\n" >> $rutaArchivoConfiguracion
    sudo printf "       ping-check true;\n" >> $rutaArchivoConfiguracion
    sudo printf "   }\n" >> $rutaArchivoConfiguracion
    sudo printf "}\n" >> $rutaArchivoConfiguracion

    # Agrego la interfaz de red que va a actuar como dhcp
    sudo printf "INTERFACESv4=\"enp0s8\"\n" >> /etc/default/isc-dhcp-server

    # Reglas NAT para que los clientes tengan salida a internet
    sudo echo 1 > /proc/sys/net/ipv4/ip_forward
    sudo sysctl -p

    # La interfaz con salida a internet en mi caso es enp0s3
    sudo iptables -t nat -A POSTROUTING -o enp0s3 -j MASQUERADE
    sudo iptables -A FORWARD -i enp0s8 -o enp0s3 -j ACCEPT
    sudo iptables -A FORWARD -i enp0s3 -o enp0s8 -m state --state RELATED,ESTABLISHED -j ACCEPT

    sudo dhcpd -t -cf /etc/dhcp/dhcpd.conf
    sudo service isc-dhcp-server restart
    sudo service isc-dhcp-server status
else
    echo "Alguno de los parametros es invalido, verifica los datos ingresados"
fi