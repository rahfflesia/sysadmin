# Declaración de variables
$variable1 = "Hola"
$variable2 = "Que tal?"
$variable3 = 100
# No se recomienda utilizar espacios en el nombre de variables, en caso de requerirse tiene que estar entre paréntesis
$(var iable4) = 200
# Otra forma de declarar variables a través de comandos
New-Variable -Name variable5 -value 300
# Impresión de valores
echo $variable1
echo $variable2
echo $variable3
echo $(var iable4)
# Realización de operaciones de suma o concatenación de variables según su tipo de dato
echo ($variable1 + " " + $variable2)
echo ($variable3 + $(var iable4))
echo ($variable3 - $(var iable4))
echo ($variable1 + " " + $variable2)
# $$ último token recibido en la última línea de la sesión
echo $$
# $^ Primer token en la última línea recibida por la sesión
echo $^
# esta variable contiene el estado de la ejecución del último comando. 
# Si el resultado de la ejecución del último comando ha sido satisfactorio
# contendrá True y en otro caso contendrá False
echo $?