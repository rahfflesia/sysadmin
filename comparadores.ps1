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
# Por ejemplo, también hay algunas similitudes con sql, como el uso de like al validar comparaciones con strings