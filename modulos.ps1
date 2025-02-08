# Un módulo es una unidad independiente en la que podemos organizar y/o abstraer código de powershell
# Por ejemplo, podríamos hacer un módulo que contenga una clase con métodos que usamos frecuentemente
# Por defecto, solo se importan los módulos almacenados en la ubicación especificada por PSModulePath
# Si queremos importar módulos de otra ubicación lo haremos mediante el cmdlet Import-Module
# Para consultar los módulos de PowerShell cargados en nuestra sesión usaremos Get-Module
Get-Module
# Lista con todos los módulos disponibles para ser cargados según nuestro path
Get-Module -ListAvailable

# Existen cuatro tipo de módulos
# Módulo de manifiesto: contiene información acerca del módulo
# Módulo de script: contiene cualquier código válido de ps
# Módulo binario: contiene archivos dll, es decir binarios
# Módulo dinámico: no está almacenado, se crea en tiempo de ejecución

# Remover módulo
# Remove-Module BitsTransfer

# Podemos usar Get-Command para buscar los comandos de un módulo
# También podemos usar Get-Help si es que contiene archivos de ayuda
Get-Command -Module BitsTransfer

# Es importante dar nombres únicos cuando utilicemos módulos, ya que, se pueden generar conflictos



