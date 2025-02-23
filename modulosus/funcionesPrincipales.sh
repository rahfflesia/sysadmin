#!/bin/bash
# Primer parámetro ip, segundo parámetro dominio
function mainDns(){
    if esIpValida "$1" && esDominioValido "$2"; then
        sudo apt install -y bind9*
        dbFile="db.${2}"
        zona="zone \"${2}\" { type master; file \"/etc/bind/${dbFile}\"; };"

        # Imprimir la zona para comprobar
        echo "${zona}"

        # Agregar la zona al archivo de configuración
        sudo printf "%s\n" "$zona" >> /etc/bind/named.conf.local

        # Crear el archivo de zona
        sudo touch /etc/bind/"${dbFile}"

        # Insertar la configuración en el archivo db
        sudo printf ";\n"
        sudo printf "; BIND data file for local loopback interface\n"
        sudo printf ";\n"
        sudo printf "\$TTL        604800\n" >> /etc/bind/"${dbFile}"
        sudo printf "@        IN        SOA        ${2}. admin.${2}. ( \n" >> /etc/bind/"${dbFile}"
        sudo printf "                              31          ; Serial\n" >> /etc/bind/"${dbFile}"
        sudo printf "                              604800      ; Refresh\n" >> /etc/bind/"${dbFile}"
        sudo printf "                              86400       ; Retry\n" >> /etc/bind/"${dbFile}"
        sudo printf "                              2419200     ; Expire\n" >> /etc/bind/"${dbFile}"
        sudo printf "                              604800 )    ; Negative Cache TTL\n" >> /etc/bind/"${dbFile}"
        sudo printf ";"
        sudo printf "@        IN        NS         ${2}.\n" >> /etc/bind/"${dbFile}"
        sudo printf "\n" >> /etc/bind/"${dbFile}"
        sudo printf "@        IN        A          ${1}\n" >> /etc/bind/"${dbFile}"
        sudo printf "www      IN        A          ${1}\n" >> /etc/bind/"${dbFile}"

        # Agregar una línea en blanco al final
        sudo printf "\n" >> /etc/bind/"${dbFile}"

        # Verificar la configuración
        sudo named-checkconf
        sudo named-checkzone "${2}" "/etc/bind/${dbFile}"

        # Reiniciar el servicio bind9
        sudo systemctl restart bind9
    else
        echo "Dirección ip o dominio inválido"
    fi
}
# $1 = Ip Inicial, $2 = Ip Final, $3 = máscara de subred, $4 = dns, $5 = gateway, puerta de enlace, $6 = Ip a asignar al dhcp, $7 = nombre del grupo
function mainDhcp(){
    if esConfiguracionValida "$1" "$2" "$3" "$4" "$5" "$6"; then
    # Instalo el servicio de dhcp
        sudo apt-get install isc-dhcp-server
        # Asigno la ip de la subred al servidor dhcp, en mi caso la interfaz enp0s8 contendrá la dirección ip del dhcp
        sudo ifconfig enp0s8 "${6}" netmask "${3}"

        rutaArchivoConfiguracion="/etc/dhcp/dhcpd.conf"
        # Escritura de los parámetros de configuración en el archivo
        sudo printf "\n" >> $rutaArchivoConfiguracion
        sudo printf "group ${7} {\n" >> $rutaArchivoConfiguracion

        ipBase=$(obtenerIpBase "$1" "$3")
        broadcast=$(obtenerBroadcast $ipBase)

        sudo printf "   subnet ${ipBase} netmask ${3} {\n" >> $rutaArchivoConfiguracion
        sudo printf "       range ${1} ${2};\n" >> $rutaArchivoConfiguracion
        sudo printf "       option domain-name-servers ${4};\n" >> $rutaArchivoConfiguracion
        sudo printf '       option domain-name "local";\n' >> $rutaArchivoConfiguracion
        sudo printf "       option subnet-mask ${3};\n" >> $rutaArchivoConfiguracion
        sudo printf "       option routers ${6};\n" >> $rutaArchivoConfiguracion
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
}