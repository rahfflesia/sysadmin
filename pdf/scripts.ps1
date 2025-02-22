# Un script en powershell no es más que un archivo con extensión ps1 que ejecuta un conjunto de comandos
# La función principal de los scripts es el de automatizar tareas rutinarias
# Estos pueden variar en complejidad, pueden ser desde muy simples hasta excesivamente complejos según la función de este y la tarea que se quiera automatizar
# PS es un lenguaje de scripting interpretado
# PowerShell es un lenguaje interpretado, lo que significa que no se compila previamente a código de máquina.
# El intérprete de PowerShell evalúa los comandos en tiempo de ejecución.

# Por defecto los scripts de PS no devuelven ningún estado de salida
# Si queremos regresar algo en la sálida pordemos utilizar <exit> que por defecto retorna cero
# Los distintos valores de salida que puede devolver PS varían segun el SO

# Ayuda en PS
# 1. Comment-Based: Escribe la ayuda en los comentarios de la función.
# 2. XML-Based: Usa XML para soporte multilingüe y ayuda avanzada.

# Terminología básica en control de excepciones:
# 1. Excepción: Evento que ocurre cuando un error no se puede resolver normalmente.
# 2. Throw y Catch: Throw lanza una excepción; Catch captura y maneja la excepción.
# 3. Pila de llamadas: Lista de funciones llamadas, usada para capturar excepciones.
# 4. Errores de terminación y no terminación: 
#    - Terminación: Detiene el script si no se captura.
#    - No terminación: Write-Error solo agrega un error, no detiene la ejecución.

# Bloque try / catch
try {
    echo "Intenta alguna accion"
}
catch {
    echo "Algo lanzo algun error intentando realizar la accion"
    echo $_
}

# Ejemplo de bloque try / finally
# $comando = [System.Data.SqlClient.SqlCommand]::New(queryString, connection)
try {
    echo "Abro conexion"
    echo "Ejecuto la consulta"
}
finally {
    echo "Independientemente del estado cierro la conexion"
}

# Para mostrar información sobre el error podemos usar $PSItem o $_
# Cuenta con distintos métodos que podemos utilizar según sea conveniente
$PSItem.ToString() # Versión limpia del mensaje
$PSItem.InvocationInfo # Información sobre la función o script que inició la excepción
$PSItem.ScriptStackTrace # Muestra el orden de las llamadas de la función que le llevaron al código donde se generó la excepción
$PSItem.Exception # Muestra la excepción real que se inició

$PSItem.Exception.Message # 
$PSItem.Exception.InnerException # Muestra la excepción interna si se generó una
$PSItem.Exception.StackTrace # Seguimiendo de la pila de llamadas

# En powershell se pueden encadenar catch
try
{
    Start-Something -Path $path -ErrorAction Stop
}
catch [System.IO.DirectoryNotFoundException],[System.IO.FileNotFoundException]
{
    Write-Output "El directorio o fichero no ha sido encontrado: [$path]"
}
catch [System.IO.IOException]
{
    Write-Output "Error de IO con el archivo: [$path]"
}
catch
{
    Write-Output "Se ha producido un error inesperado: $_"
}

# También hay excepciones de un tipo en específico, por así decirlo
throw "No se puede encontrar la ruta: [$path]"
throw [System.IO.FileNotFoundException] "No se puede encontrar la ruta: [$path]"
throw [System.IO.FileNotFoundException]::new()
throw [System.IO.FileNotFoundException]::new("No se puede encontrar la ruta: [$path]")
throw (New-Object -TypeName System.IO.FileNotFoundException)
throw (New-Object -TypeName System.IO.FileNotFoundException -ArgumentList "No se puede encontrar la ruta: [$path]")

# De igual manera, podemos utilizar trap, trap nos permite ejecutar su código cuando se produce una excepción
# Y después seguir con el flujo de manera normal
trap {
    Write-Output $PSItem.ToString()
    continue
}
throw [System.Exception]::new("primero")
throw [System.Exception]::new("segundo")
throw [System.Exception]::new("tercero")
