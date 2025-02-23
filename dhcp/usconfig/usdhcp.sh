source /home/jj/sysadmin/modulosus/funcionesIp.sh
source /home/jj/sysadmin/modulosus/funcionesPrincipales.sh

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

mainDhcp "$ipInicial" "$ipFinal" "$mascara" "$dns" "$gateway" "$ipDhcp" "$grupo"