# Los condicionales funcionan exactamente que en cualquier lenguaje de programación actual
if ($condition) {
    Write-Output "Condition verdadera"
} else {
    Write-Output "Condition falsa"
}

$numero = 2
if ($numero -ge 3) {
    Write-Output "Numero mayor que tres"
} elseif ($numero -lt 2) {
    Write-Output "Numero menor que dos"
} else {
    Write-Output "Numero igual a dos"
}

# Operador ternario
# $PSTableVersion para checar la version
# Funciona solo en versiones >= 7.0, en mi caso tengo la 5.1
# ($numero -ge 2) ? (Write-Output "Numero mayor a dos") : (Write-Output "Numero menor a dos")

# if (Test-Path $path) {
#     Write-Output "La ruta existe"
# } else {
#     Write-Output "La ruta no existe"
# }

# Con operador ternario quedaría algo así
# (Test-Path $path) ? "La ruta existe" : "La ruta no existe"