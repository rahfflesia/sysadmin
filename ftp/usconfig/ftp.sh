#!/bin/bash
sudo apt-get upgrade
sudo apt install vsftpd

sudo groupadd reprobados --force
sudo groupadd recursadores --force

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

            sudo useradd -m -d /home/jj/ftp/usuarios/$usuario $usuario
            sudo passwd $usuario

            sudo usermod -a -G $grupo $usuario

            sudo chmod 755 /home/jj/ftp/usuarios/$usuario
            sudo mkdir /home/jj/ftp/usuarios/$usuario/$usuario

            sudo mkdir /home/jj/ftp/users/$usuario
            sudo chmod 755 /home/jj/ftp/users/$usuario

            sudo chmod 755 /home/jj/ftp/usuarios/$usuario/$usuario
            sudo mkdir /home/jj/ftp/usuarios/$usuario/general
            sudo chmod 755 /home/jj/ftp/usuarios/$usuario/general
            sudo mkdir /home/jj/ftp/usuarios/$usuario/$grupo
            sudo chmod 755 /home/jj/ftp/usuarios/$usuario/$grupo

            sudo chown $usuario /home/jj/ftp/usuarios/$usuario/$grupo
            sudo chown $usuario /home/jj/ftp/usuarios/$usuario/general
            sudo chown $usuario /home/jj/ftp/usuarios/$usuario/$usuario

            # Enlaces
            sudo mount --bind /home/jj/ftp/usuarios/$usuario/General /home/jj/ftp/general
            sudo mount --bind /home/jj/ftp/usuarios/$usuario/$grupo /home/jj/ftp/$grupo
            sudo mount --bind /home/jj/ftp/usuarios/$usuario/$usuario /home/jj/ftp/users/$usuario
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