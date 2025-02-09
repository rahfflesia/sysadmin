#!bin/bash
# Para que el script funcione bind9 debe estar instalado
# Primer intento
echo "Ingresa la dirección ip: "
read ip
echo "Ingresa el dominio: "
read dominio

dbFile="db.${dominio}";
zona="zone ${dominio} { type master; file \"/etc/bind/${dbFile}\"; };"
echo "${dbFile}"

sudo printf $zona >> /etc/bind/named.conf.local
sudo touch /etc/bind/"${dbFile}"
# Inserción del formato del archivo
sudo printf "TTL 604800" >> /etc/bind/"${dbFile}"
sudo printf "@ IN SOA ${dominio}. admin.${dominio}. ( 10 ; Serial 604800; Refresh 86400; Retry 2419200; Expire 604800 ) ; Negative Cache TTL;" >> /etc/bind/"${dbFile}"
sudo printf "@ IN NS ${dominio}." >> /etc/bind/"${dbFile}"
sudo printf "@ IN A ${ip}" >> /etc/bind/"${dbFile}"
sudo printf "www IN A ${ip}" >> /etc/bind/"${dbFile}"
sudo printf "\n"

sudo named-checkconf
sudo named-checkzone "${dominio}" "/etc/bind/${dbFile}"
sudo systemctl restart bind9
#########

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