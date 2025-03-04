# Script funcional, faltan validaciones
#!/bin/bash
sudo apt-get upgrade
sudo apt install vsftpd

sudo groupadd reprobados --force
sudo groupadd recursadores --force

# Carpeta de usuarios anónimos
sudo mount --bind /home/jj/ftp/general/ /home/jj/ftp/anon/general

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

            declare -l grupo
            grupo=$grupo;
            echo "$grupo"

            declare -l usuario
            usuario=$usuario
            echo "$usuario"

            if [[ ("$grupo" != "reprobados" && "$grupo" != "recursadores") || -z "$grupo" || -z "$usuario" ]]; then
                echo "Has ingresado un grupo inválido, espacios en blanco o el usuario ya existe"
            elif id "$usuario" &>/dev/null; then
                echo "El usuario ya existe"
            else
                sudo useradd -m -d "/home/jj/ftp/usuarios/$usuario" "$usuario"
                sudo passwd "$usuario"

                sudo usermod -G "$grupo" "$usuario"

                sudo mkdir -p "/home/jj/ftp/usuarios/$usuario/$usuario"
                sudo chmod 755 "/home/jj/ftp/usuarios/$usuario"

                sudo mkdir -p "/home/jj/ftp/users/$usuario"
                sudo chmod 755 "/home/jj/ftp/usuarios/$usuario/$usuario"
                
                sudo mkdir -p "/home/jj/ftp/usuarios/$usuario/general"
                sudo chmod 755 "/home/jj/ftp/usuarios/$usuario/general"

                sudo mkdir -p "/home/jj/ftp/usuarios/$usuario/$grupo"
                sudo chmod 775 "/home/jj/ftp/usuarios/$usuario/$grupo"

                sudo chown "$usuario" "/home/jj/ftp/usuarios/$usuario/$grupo"
                sudo chown "$usuario" "/home/jj/ftp/usuarios/$usuario/general"
                sudo chown "$usuario" "/home/jj/ftp/usuarios/$usuario/$usuario"

                # Enlaces
                sudo mount --bind "/home/jj/ftp/usuarios/$usuario/general" "/home/jj/ftp/general"
                sudo mount --bind "/home/jj/ftp/usuarios/$usuario/$grupo" "/home/jj/ftp/$grupo"
                sudo mount --bind "/home/jj/ftp/usuarios/$usuario/$usuario" "/home/jj/ftp/users/$usuario"

                echo "Registro realizado correctamente"
            fi


        ;;
        "2")
            grupoActual=""
            echo "Nombre de usuario: "
            read usuario
            echo "Nuevo grupo de usuario: "
            read grupo

            declare -l grupo
            grupo=$grupo;
            echo "$grupo"

            declare -l usuario
            usuario=$usuario
            echo "$usuario"

            if [[ ("$grupo" != "reprobados" && "$grupo" != "recursadores") || -z "$grupo" || -z "$usuario" || ! id "$usuario" &>/dev/null ]]; then
                echo "Has ingresado un grupo inválido, campos vacíos o el usuario no existe"
            else
                if [[ "$grupo" == "reprobados" ]]; then
                    grupoActual="recursadores"
                else
                    grupoActual="reprobados"
                fi

                echo "Grupos actuales de $usuario:"
                groups "$usuario"

                sudo usermod -G "$grupo" "$usuario"

                echo "Grupos actuales de $usuario después del cambio:"
                groups "$usuario"

                if mountpoint -q "/home/jj/ftp/$grupoActual"; then
                    sudo umount "/home/jj/ftp/$grupoActual"
                fi

                if [[ -d "/home/jj/ftp/usuarios/$usuario/$grupoActual" ]]; then
                    sudo rm -r "/home/jj/ftp/usuarios/$usuario/$grupoActual"
                fi

                sudo mkdir -p "/home/jj/ftp/usuarios/$usuario/$grupo"
                sudo chmod 755 "/home/jj/ftp/usuarios/$usuario/$grupo"
                sudo chown "$usuario" "/home/jj/ftp/usuarios/$usuario/$grupo"

                sudo mkdir -p "/home/jj/ftp/$grupo"

                # Enlace
                sudo mount --bind "/home/jj/ftp/usuarios/$usuario/$grupo" "/home/jj/ftp/$grupo"

                echo "Se realizó el cambio de grupo"
            fi


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