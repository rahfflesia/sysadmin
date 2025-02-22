# Las funciones en PowerShell funcionan igual que en cualquier otro lenguaje de programación
# Pueden recibir parámetros y un ámbito, cada vez que esta sea llamada el cuerpo de la función sera ejecutado
# La única peculiaridad es la nomenclatura que debe de seguir una función en PS
# La estructura sería la siguiente VerboAprobado -> (-) -> Prefijo -> NombreSingular
# Para consultar la lista de verbos aprobados en ps utilizamos el comando Get-Verb
function Get-Fecha { # Wrapper de Get-Date
    Get-Date
}

# Podemos consultar las funciones cargadas en memoria utilizando el siguiente comando
# Get-ChildItem -Path Function:\*-*
Get-ChildItem -Path Function:\Get-*

# Es importante hacer uso de parámetros al crear funciones ya que, es eso lo que las vuelve tan potentes
# Deberíamos de evitar valores estáticos siempre que sea posible
# En esta ocasión usamos parametros posicionales
# A los parametros también podemos agregarle valores por defecto y opcionales
function Get-Resta {
    Param([int]$num1, [int]$num2)
    $resta = $num1 - $num2
    echo "Resultado: $resta"
}

# Por ejemplo si no quisieramos especificar los valores por posicion podríamos hacerlo así
# -num1 <valor> -num2 <valor>
# Parámetros mandatorios especificados en la función
function Get-Resta2{
    Param([Parameter(Mandatory)][int]$num1, [int]$num2)
    $resta = $num1 - $num2
    echo "Resultado $resta"
}

# Para convertir una funcion normal o común en una avanzada realizamos lo siguiente
# Al explorar las propiedades de la funcion con .Parameters.Keys nos aparecerán los parámetros de la función
function Get-RestaAvanzada {
    [CmdletBinding()]
    Param([int]$num1, [int]$num2)
    $resta = $num1 - $num2
    Write-Verbose -Message "Funcion que resta dos numeros, no ingrese valores no numericos"
    echo "Resultado $resta"
}

# Si queremos proporcionar información adicional al usuario final de la función utilizamos Write-Verbose

Get-Resta 10 5
Get-Resta2 -num2 10
(Get-Command -Name Get-RestaAvanzada).Parameters.Keys
Get-RestaAvanzada 100 10 -Verbose