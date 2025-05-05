#Cargamos en el set 10, vía 0 el primer bloque.
#Luego guardaremos el valor 0 en la primera palabra del bloque de MD y MC.
#Teniendo un Write Hit. 
lw r1,96(r0)
sw r2,96(r0)

#Provocamos un Write miss en el set 10.
#Como no está cargado, traerá el bloque y escribirá en la primera palabra un 0.
#Luego tendremos un Read Hit.
sw r2,160(r0)
lw r3,160(r0)

#Cargamos en el set 11, vía 0 un bloque para luego hacer read hits, a las palabras 01 y 10 de dicho bloque.
lw r4,112(r0)
lw r5,116(r0)
lw r6,120(r0)