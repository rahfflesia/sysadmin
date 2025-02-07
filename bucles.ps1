# Bucle for
# Solo se aumenta el valor de i, j se mantiene en cero durante todo el ciclo
# Funciona igual que el de cualquier lenguaje de programación convencional -> variable de control, condición para detenerlo; acción a repetir
for (($i = 0), ($j = 0); $i -lt 5; $i++)
{
    "$i:$i"
    "$j:$j"
}
# Mismo ciclo, se aumenta el valor de ambas variables
for (($i = 0), ($j = 0); $i -lt 5; $i++)
{
    "$i:$i"
    "$j:$j"
}