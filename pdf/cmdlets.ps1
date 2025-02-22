# Los cmdlets son los bloques fundamentales de ps
# Cada cmdlet realiza una función específica, normalmente su nombre describle la acción que realiza y sobre que recurso
Get-Command -Type Cmdlet | Sort-Object -Property Noun | Format-Table -GroupBy Noun
# Obtener la sintáxis de un nombre en concreto
Get-Command -Name Get-ChildItem -Args Cert: -Syntax
# Obtener el cmdlet de un alias
Get-Command -Name dir
# Obtener los cmdlets de un recurso
Get-Command -Noun WSManInstance