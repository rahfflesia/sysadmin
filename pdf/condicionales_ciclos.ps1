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
# $PSVersionTable para checar la version
# Funciona solo en versiones >= 7.0, en mi caso tengo la 5.1
# ($numero -ge 2) ? (Write-Output "Numero mayor a dos") : (Write-Output "Numero menor a dos")

# if (Test-Path $path) {
#     Write-Output "La ruta existe"
# } else {
#     Write-Output "La ruta no existe"
# }

# Con operador ternario quedaría algo así
# (Test-Path $path) ? "La ruta existe" : "La ruta no existe"
# Cualquier patrón que coincida con el valor establecido en el switch case
# En este caso son puros enteros y se utiliza una 
switch(3){
    1 {"[$_] es uno"}
    2 {"[$_] es dos"}
    3 {"[$_] es tres"}
    4 {"[$_] es cuatro"}
}
# Funciona exactamente igual que el anterior pero puede repetir valores, ya que, no utiliza la sentencia break
switch(3){
    1 {"[$_] es uno"}
    2 {"[$_] es dos"}
    3 {"[$_] es tres"}
    4 {"[$_] es cuatro"}
    3 {"[$_] es tres }"}
}
# En este caso funciona exactamente igual que los dos anteriores solo en un rango más amplio
switch (1, 5)
{
    1 {"[$_] es uno."}
    2 {"[$_] es dos."}
    3 {"[$_] es tres."}
    4 {"[$_] es cuatro."}
    5 {"[$_] es cinco."}
}
# En este caso se utiliza un string, ya no hay repetición de coincidencias al utilizar la sentencia break, de igual manera
# Se utiliza una expresión regular que coincida con cualquier string que contenga este patrón se______ a partir de se puede haber cualquier caracter
switch ("seis")
{
   1 {"[$_] es uno." ; Break}
   2 {"[$_] es dos."; Break}
   3 {"[$_] es tres."; Break}
   4 {"[$_] es cuatro."; Break}
   5 {"[$_] es cinco."; Break}
    "se*" {"[$_] coincide con se*."}
    Default {
        "No hay coincidencias con [$_]"
    }
}

switch -wildcard ("seis")
{
   1 {"[$_] es uno." ; Break}
   2 {"[$_] es dos." ; Break}
   3 {"[$_] es tres." ; Break}
   4 {"[$_] es cuatro." ; Break}
   5 {"[$_] es cinco." ; Break}
    "se*" {"[$_] coincide con [se*]"}
   Default {
    "No hay coincidencias con [$_]"
    }
}

# En este caso, también se utilizan expresiones regulares que coincidan con patrones característicos de los email educativos
# o de una url, la comparación de la url se hace a través del protocolo de esta, puede ser http o https
$email = 'antonio.yanez@udc.es'
$email2 = 'antonio.yanez@usc.gal'
$url = 'https://www.dc.fi.udc.es/~afyanez/Docencia/2023'
switch -Regex ($url, $email, $email2)
{
    '\w+\.\w+@(udc|usc|edu)\.es|gal$' { "[$_] es una direccion de correo electronico academica" }
    '~ftp://.*$' { "[$_] es una direccion ftp" }
    '~(http[s]?)//.*$' { "[$_] es una direccion web, que utiliza [$($matches[1])]" }
}
# El valor de la derecha se convierte al tipo del de la izquierda
# 1 === 1 True
1 -eq "1.0"
# "1.0" === "1" False
"1.0" -eq 1
# Comparador and
1 -eq "1.0" -and 1 -gt 2 # Falso
"1.0" -eq 1 -and 1 -gt -1 # True
"1.0" -eq 2 -xor 2 -eq 3 # Falso
-not (1 -eq "1.0" -and 1 -gt 2) # Falso NOT -> True
# A diferencia de los lenguajes de programación comunes en los que se utilizan (&&, ||) u operadores directamente como >, <, >=, <=
# En powershell se utilizan de manera un poco distinta
# Por ejemplo, también hay algunas similitudes con sql, como el uso de like al hacer comparaciones con strings
# Bucle for
# Solo se aumenta el valor de i, j se mantiene en cero durante todo el ciclo
# Funciona igual que el de cualquier lenguaje de programación convencional -> variable de control, condición para detenerlo; acción a repetir
for (($i = 0), ($j = 0); $i -lt 5; $i++)
{
    "`$i:$i"
    "`$j:$j"
}
# Mismo ciclo, se aumenta el valor de ambas variables
for ($($i = 0; $j = 0); $i -lt 5; $($i++;$j++))
{
    "`$i:$i"
    "`$j:$j"
}

# ForEach
$numeros = 1..10
# El bucle funciona sobre colecciones e itera a través de los elementos de este
forEach($numero in $numeros){
    echo ($numero * $numero);
}

# While
# Mientras la condición sea verdadera se ejecutará el cuerpo del bucle
$num = 0
while ($num -ne 3)
{
    $num++;
    Write-Host $num
}
$num1 = 0
# La única diferencia es que ahora se incluye continue, si se cumple la condición dada se saltará dicha iteración
while ($num1 -ne 5)
{
    if ($num1 -eq 1) { $num1 = $num1 + 3 ; Continue }
    $num1++;
    Write-Host $num1
}

# Do while
# Es en pocas palabras lo mismo que un bucle for pero con la lógica invertida, este también se ejecuta al menos una vez
$valor = 5
$multiplication = 1
do
{
    $multiplication = $multiplication * $valor
    $valor--
}
while ($valor -gt 0)
echo $multiplication

# Los ciclos pueden usar continue y break, continue salta la iteración actual, break sale del ciclo inmediatamente