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