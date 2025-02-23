#!/bin/bash
source /home/jj/sysadmin/modulosus/funcionesIp.sh
source /home/jj/sysadmin/modulosus/funcionesDominio.sh
source /home/jj/sysadmin/modulosus/funcionesPrincipales.sh

echo "Ingresa la dirección ip: "
read ip
echo "Ingresa el dominio: "
read dominio

mainDns "$ip" "$dominio"