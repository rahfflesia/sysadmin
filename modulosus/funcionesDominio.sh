function esDominioValido() {
    local regex="^[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9](\.[a-zA-Z]{2,})+$"
    if [[ $1 =~ $regex ]]; then
        return 0
    else
        return 1 
    fi
}