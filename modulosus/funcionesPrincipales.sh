#!/bin/bash
# Primer parámetro ip, segundo parámetro dominio
function mainDns(){
    if esIpValida "$1" && esDominioValido "$2"; then
        sudo apt install -y bind9*
        dbFile="db.${$2}"
        zona="zone \"${$2}\" { type master; file \"/etc/bind/${dbFile}\"; };"

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
        sudo printf "@        IN        SOA        ${$2}. admin.${$2}. ( \n" >> /etc/bind/"${dbFile}"
        sudo printf "                              31          ; Serial\n" >> /etc/bind/"${dbFile}"
        sudo printf "                              604800      ; Refresh\n" >> /etc/bind/"${dbFile}"
        sudo printf "                              86400       ; Retry\n" >> /etc/bind/"${dbFile}"
        sudo printf "                              2419200     ; Expire\n" >> /etc/bind/"${dbFile}"
        sudo printf "                              604800 )    ; Negative Cache TTL\n" >> /etc/bind/"${dbFile}"
        sudo printf ";"
        sudo printf "@        IN        NS         ${$2}.\n" >> /etc/bind/"${dbFile}"
        sudo printf "\n" >> /etc/bind/"${dbFile}"
        sudo printf "@        IN        A          ${$1}\n" >> /etc/bind/"${dbFile}"
        sudo printf "www      IN        A          ${$1}\n" >> /etc/bind/"${dbFile}"

        # Agregar una línea en blanco al final
        sudo printf "\n" >> /etc/bind/"${dbFile}"

        # Verificar la configuración
        sudo named-checkconf
        sudo named-checkzone "${$2}" "/etc/bind/${dbFile}"

        # Reiniciar el servicio bind9
        sudo systemctl restart bind9
    else
        echo "Dirección ip o dominio inválido"
    fi
}