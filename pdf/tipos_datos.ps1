# En powershell no es obligatorio declarar el tipo de la variable, al tener este inferencia de tipo
# En caso de querer declarar el tipo de la variable se realiza de la siguiente manera: 
[int]$variable1 = 100
[char]$variable2 = "X"
[double]$variable3 = 2.717
[string]$variable4 = "Hola"
# Variable de tipo fecha, en este caso le asigno un valor usando el comando Get-Date
$variable5 = Get-Date
[boolean]$variable6 = $false
# Array con números del 1 al 10, esta es la sintáxis para crear rangos en ps
$array = 1..10

# Impresión de las variables
Write-Output ("Variable entera: $variable1")
Write-Output ("Variable de tipo char: $variable2")
Write-Output ("Variable de tipo double: $variable3")
Write-Output ("Variable de tipo string: $variable4")
Write-Output ("Variable de tipo datetime: $variable5")
Write-Output ("Variable de tipo boolean: $variable6")
Write-Output ("Array: $array")