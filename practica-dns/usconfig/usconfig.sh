#!/bin/bash
# Para que el script funcione bind9 debe estar instalado
# Esta versión del script ya funciona, solo falta agregar validaciones

function esIpValida(){
	local regex="^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"
    if [[ $1 =~ $regex ]]; then
        return 0
    else
        return 1
    fi
}

function esDominioValido() {
    local regex="^[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9](\.[a-zA-Z]{2,})+$"
    if [[ $1 =~ $regex ]]; then
        return 0
    else
        return 1 
    fi
}

echo "Ingresa la dirección ip: "
read ip
echo "Ingresa el dominio: "
read dominio

if esIpValida "$ip" && esDominioValido "$dominio"; then
    dbFile="db.${dominio}"
    zona="zone \"${dominio}\" { type master; file \"/etc/bind/${dbFile}\"; };"

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
    sudo printf "@        IN        SOA        ${dominio}. admin.${dominio}. ( \n" >> /etc/bind/"${dbFile}"
    sudo printf "                              31          ; Serial\n" >> /etc/bind/"${dbFile}"
    sudo printf "                              604800      ; Refresh\n" >> /etc/bind/"${dbFile}"
    sudo printf "                              86400       ; Retry\n" >> /etc/bind/"${dbFile}"
    sudo printf "                              2419200     ; Expire\n" >> /etc/bind/"${dbFile}"
    sudo printf "                              604800 )    ; Negative Cache TTL\n" >> /etc/bind/"${dbFile}"
    sudo printf ";"
    sudo printf "@        IN        NS         ${dominio}.\n" >> /etc/bind/"${dbFile}"
    sudo printf "\n" >> /etc/bind/"${dbFile}"
    sudo printf "@        IN        A          ${ip}\n" >> /etc/bind/"${dbFile}"
    sudo printf "www      IN        A          ${ip}\n" >> /etc/bind/"${dbFile}"

    # Agregar una línea en blanco al final
    sudo printf "\n" >> /etc/bind/"${dbFile}"

    # Verificar la configuración
    sudo named-checkconf
    sudo named-checkzone "${dominio}" "/etc/bind/${dbFile}"

    # Reiniciar el servicio bind9
    sudo systemctl restart bind9
else
    echo "Dirección ip o dominio inválido"
fi
# Pasos en pocas palabras: 
# Entra a sudo nano /etc/bind/named.conf.local
# Ingresa el archivo del dominio local
# zone <dominio> {
#  type master;
#  file "/etc/bind/db + dominio";
#};
# copia la estructura de cualquier archivo de zona local disponible
# sudo cp /etc/bind/db.hola.com /etc/bind/db + <dominio>
# edita el contenido y ajustalo (muchos pasos para ponerlo en un simple comentario)
# verificar la configuracion con
# sudo named-checkconf
# sudo named-checkzone <dominio> <ruta del archivo db del dominio>
# sudo systemctl restart bind9