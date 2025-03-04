#!/bin/bash
sudo apt-get upgrade
sudo apt install vsftpd

while :
do
    echo "Menu"
    echo "1. Agregar usuario"
    echo "2. Cambiar usuario de grupo"
    echo "3. Salir"
    echo "Selecciona una opcion: "
    read opcion

    case "$opcion" in
        "1")
            echo "Ingresa el nombre del usuario: "
            read usuario
            echo "Ingresa el nombre del grupo (reprobados/recursadores): "
            read grupo
            sudo useradd $usuario
            sudo passwd $usuario
            sudo useradd -m -d /home/jj/ftp/usuarios/$usuario $usuario
            sudo chmod 750 /home/jj/ftp/usuarios/$usuario
            sudo mkdir /home/jj/ftp/usuarios/$usuario/$usuario
            sudo chmod 700 /home/jj/ftp/usuarios/$usuario/$usuario
            sudo mkdir /home/jj/ftp/usuarios/$usuario/General
            sudo chmod 700 /home/jj/ftp/usuarios/$usuario/General
            sudo mkdir /home/jj/ftp/usuarios/$usuario/$grupo
            sudo chmod 700 /home/jj/ftp/usuarios/$usuario/$grupo
        ;;
        "2")
            echo "Cambio de grupo"
        ;;
        "3")
            echo "Saliendo..."
            break
        ;;
        *)
            echo "Selecciona una opcion dentro del rango (1..3)"
        ;;
    esac
    echo ""
done