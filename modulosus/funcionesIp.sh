#!/bin/bash
function esIpValida(){
	local regex="^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"
    if [[ $1 =~ $regex ]]; then
        return 0
    else
        return 1
    fi
}

# La función espera en el primer parámetro la ip y en el segundo la máscara de subred
function obtenerIpBase(){
    arrayIp=
    arrayMascara=
    IFS='.' read -r -a arrayIp <<< "$1" # Ip
    IFS='.' read -r -a arrayMascara <<< "$2" # Máscara
    direccion=""

    for ((i = 0; i < "${#arrayIp[@]}"; i++)); do
        byte="$((arrayIp[i] & arrayMascara[i]))"
        if [[ $i -eq 0 ]]; then
            direccion="$byte"
        else
            direccion="$direccion.$byte"
        fi
    done
    echo "${direccion}"
}
# Espera en el primer parámetro la dirección de red
function obtenerBroadcast(){
    local arrayIp=
    IFS='.' read -r -a arrayIp <<< "$1"
    direccion=""
    
    for ((i = 0; i < "${#arrayIp[@]}"; i++)); do
        byte="${arrayIp[$i]}"
        if [[ $byte -eq "0" ]]; then
            direccion="$direccion.255"
        else
            if [[ $i -eq 0 ]]; then
                direccion="$byte"
            else 
                direccion="$direccion.$byte"
            fi
        fi
    done
    echo "${direccion}"
}

function esConfiguracionValida(){
    if esIpValida "$1" && esIpValida "$2" && esIpValida "$3" && esIpValida "$4" && esIpValida "$5" && esIpValida "$6"; then
        return 0
    else
        return 1
    fi
}