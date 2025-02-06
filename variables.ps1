$variable1 = "Hola"
$variable2 = "Que tal?"
$variable3 = 100
$(var iable4) = 200
New-Variable -Name variable5 -value 300
echo $variable1
echo $variable2
echo $variable3
echo $(var iable4)
echo ($variable1 + " " + $variable2)
echo ($variable3 + $(var iable4))
echo ($variable3 - $(var iable4))
echo ($variable1 + " " + $variable2)
echo $$
echo $^
echo $?