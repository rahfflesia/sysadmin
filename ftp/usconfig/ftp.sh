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
            echo "Uno"
        ;;
        "2")
            echo "Dos"
        ;;
        "3")
            echo "Saliendo..."
            break
        ;;
        *)
            echo "Selecciona una opcion dentro del rango (1..3)"
        ;;
    esac
done