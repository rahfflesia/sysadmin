# En PowerShell no se trabaja únicamente con texto, también se trabaja con objetos ya que este está hecho en C#
# Como ya sabemos un objeto es una estructura de datos, tiene métodos y propiedades a las cuales podemos acceder
# Cmdlets básicos
# Get member nos proporciona información acerca de los miembros de un objeto
Get-Service -Name "LSM" | Get-Member
# Si quisieramos obtener solo información sobre las propiedades de un objeto
# Simplemente agregamos -MemberType
Get-Service -Name "LSM" | Get-Member -MemberType Property
# La columna definition nos da información valiosa
# El tipo de dato que devuelve la propiedad
# El nombre de esta
# Y si es un getter o un setter

# Select-Object lo utilizamos para mostrar el valor de las propiedades de un objeto
# Únicamente las que nos interesen, en este caso, nos interesa el nombre y la longitud
Get-Item .\cmdlets.ps1 | Select-Object Name, Length

# En veces en la salida se nos retornan demasiados datos
# Podemos utilizar First o Last para filtrar
Get-Service | Select-Object -First 5
Get-Service | Select-Object -Last 5

# Where-Object
# Podemos utilizar Where-Object para filtrar objetos que cumplan con la condición establecida
Get-Service | Where-Object {$_.Status -eq "Running"}

# Como mencioné los objetos tienen propiedades y métodos
# Una propiedad sería como una característica del objeto por así decirlo, usualmente almacenan un valor
# Un método es una acción que se puede realizar sobre un objeto
(Get-Item .\cmdlets.ps1).IsReadOnly
# Con esta propiedad podemos verificar si es de solo lectura

# Además de utilizar objetos predefinidos, en ps podemos crear nuestros propios objetos
# Podemos utilizar PSObject para poder expandirlo dinámicamente usando Add-Member
# En este caso creamos un objeto con dos propiedades y un método
# NoteProperty -> Propiedad
# ScriptMethod -> Método
$obj = New-Object PSObject
$obj | Add-Member -MemberType NoteProperty -Name Nombre -Value "Miguel"
$obj | Add-Member -MemberType NoteProperty -Name Edad -Value 23
$obj | Add-Member -MemberType ScriptMethod -Name Saludar -Value { Write-Host "Hola mundo" }

# Igualmente podemos crear un objeto a utilizando un tabla hash durante la creación del objeto
$obj2 = New-Object -TypeName PSObject -Property @{
    Nombre = "Miguel"
    Edad = 23
}
$obj2 | Add-Member -MemberType ScriptMethod -Name Saludar -Value { Write-Host "Adios mundo"}
$obj2 | Get-Member

# Otra manera en la que podemos crear un objeto es usando el acelerador PSCustomObject lo que nos ahorra escribir algunos parámetros
$obj3 = [PSCustomObject] @{
    Nombre = "Miguel"
    Edad = 23
}
