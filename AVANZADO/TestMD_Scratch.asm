#Primero cargamos la dirección de MD_Scratch
lw r0,0(r0) 

lw r1,12(r0)
sw r1,16(r0)
lw r1,16(r0)

lw_inc r1,20(r0)

#Vuelta a MD

lw r2,4(r31)
sw r1,4(r31)

sw r1,16(r31)
sw r1,80(r31)
lw r3,144(r31)
lw r4,208(r31)

sw r1,144(r31)
sw r3,144(r31)
sw r4,144(r31)

lw_inc r5,16(r31)
lw r3,144(r31)


#I/O Registers ^^

sw r4,28672(r31)
lw r4,28672(r31)

sw r3,28676(r31)
lw r4,28676(r31)

sw r2,28680(r31)
lw r4,28680(r31)