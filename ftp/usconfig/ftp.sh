# Script 100% funcional
# Ambos scripts funcionan, cualquier caso puedo volver a este commit
# Script de bash con validaciones 100% funcional
#!/bin/bash
sudo apt-get upgrade
sudo apt install vsftpd

sudo groupadd reprobados --force
sudo groupadd recursadores --force

# Carpeta de usuarios anónimos
if mountpoint -q /home/jj/ftp/general; then
    sudo mount --bind /home/jj/ftp/general/ /home/jj/ftp/anon/general
fi

sudo chown :reprobados /home/jj/ftp/reprobados
sudo chown :recursadores /home/jj/ftp/recursadores
sudo chmod 775 /home/jj/ftp/reprobados
sudo chmod 775 /home/jj/ftp/recursadores

while :
do
    echo "Menu"
    echo "1. Agregar usuario"
    echo "2. Cambiar usuario de grupo"
    echo "3. Eliminar usuario"
    echo "4. Salir"
    echo "Selecciona una opcion: "
    read opcion

    case "$opcion" in
        "1")
            echo "Ingresa el nombre del usuario: "
            read usuario
            echo "Ingresa el nombre del grupo (reprobados/recursadores): "
            read grupo

            declare -l grupo
            grupo=$grupo
            echo "$grupo"

            declare -l usuario
            usuario=$usuario
            echo "$usuario"

            if [[ ("$grupo" != "reprobados" && "$grupo" != "recursadores") || -z "$grupo" || -z "$usuario" ]]; then
                echo "Has ingresado un grupo inválido o espacios en blanco"
            elif id "$usuario" &>/dev/null; then
                echo "El usuario ya existe"
            else
                sudo useradd -m -d "/home/jj/ftp/usuarios/$usuario" "$usuario"
                sudo passwd "$usuario"
                sudo usermod -G "$grupo" "$usuario"

                sudo mkdir -p "/home/jj/ftp/usuarios/$usuario/$usuario"
                sudo mkdir -p "/home/jj/ftp/users/$usuario"
                sudo mkdir -p "/home/jj/ftp/usuarios/$usuario/general"
                sudo mkdir -p "/home/jj/ftp/usuarios/$usuario/$grupo"

                sudo chown "$usuario" "/home/jj/ftp/usuarios/$usuario/$grupo"
                sudo chown "$usuario" "/home/jj/ftp/usuarios/$usuario/general"
                sudo chown "$usuario" "/home/jj/ftp/usuarios/$usuario/$usuario"

                sudo chmod 775 "/home/jj/ftp/usuarios/$usuario/$usuario"
                sudo chmod 775 "/home/jj/ftp/usuarios/$usuario/general"
                sudo chmod 775 "/home/jj/ftp/usuarios/$usuario/$grupo"
                sudo chmod -R 775 "/home/jj/ftp/usuarios/$usuario"

                # Enlaces
                sudo mount --bind "/home/jj/ftp/general" "/home/jj/ftp/usuarios/$usuario/general"
                sudo mount --bind "/home/jj/ftp/$grupo" "/home/jj/ftp/usuarios/$usuario/$grupo"
                sudo mount --bind "/home/jj/ftp/users/$usuario" "/home/jj/ftp/usuarios/$usuario/$usuario"

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

            if id "$usuario" &>/dev/null; then
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

                    if mountpoint -q "/home/jj/ftp/usuarios/$usuario/$grupoActual"; then
                        sudo umount "/home/jj/ftp/usuarios/$usuario/$grupoActual"
                    fi

                    if [[ -d "/home/jj/ftp/usuarios/$usuario/$grupoActual" ]]; then
                        sudo rm -r "/home/jj/ftp/usuarios/$usuario/$grupoActual"
                    fi


                    sudo mkdir -p "/home/jj/ftp/usuarios/$usuario/$grupo"
                    sudo chown "$usuario" "/home/jj/ftp/usuarios/$usuario/$grupo"
                    sudo chmod 775 "/home/jj/ftp/usuarios/$usuario/$grupo"
                    sudo mkdir -p "/home/jj/ftp/$grupo"

                    # Enlace
                    sudo mount --bind "/home/jj/ftp/$grupo" "/home/jj/ftp/usuarios/$usuario/$grupo"
                    echo "Se realizó el cambio de grupo"
            elif [[ ("$grupo" != "reprobados" && "$grupo" != "recursadores") || -z "$grupo" || -z "$usuario" ]]; then
                echo "Has ingresado un grupo inválido o campos vacios"
            else
                echo "El usuario no existe"
            fi
        ;;
        "3")
            echo "Ingresa el usuario a eliminar: "
            read usuario

            if id "$usuario" &>/dev/null; then
                sudo umount "/home/jj/ftp/usuarios/$usuario/$usuario"
                sudo umount "/home/jj/ftp/usuarios/$usuario/general"

                if [[ -d "/home/jj/ftp/users/$usuario/reprobados" ]]; then
                    sudo umount "/home/jj/ftp/usuarios/$usuario/reprobados"
                else
                    sudo umount "/home/jj/ftp/usuarios/$usuario/recursadores"
                fi
                
                sudo userdel $usuario -f

                sudo rm -r "/home/jj/ftp/usuarios/$usuario"
                sudo rm -r "/home/jj/ftp/users/$usuario"
                echo "Usuario eliminado"
            else
                echo "El usuario no existe"
            fi
        ;;

        "4")
            echo "Saliendo..."
            break
        ;;
        *)
            echo "Selecciona una opcion dentro del rango (1..4)"
        ;;
    esac
    echo ""
done