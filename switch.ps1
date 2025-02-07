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