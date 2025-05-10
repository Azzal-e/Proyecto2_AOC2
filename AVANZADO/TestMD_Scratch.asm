#Primero cargamos la dirección de MD_Scratch
lw r0,0(r0) 	# Read sobre MD_Scratch

lw r1,12(r0)	# Read sobre MD_Scratch
sw r1,16(r0)	# Write sobre MD_Scratch
lw r1,16(r0)	# Read sobre MD_Scratch

lw_inc r1,20(r0)#lw_inc sobre MD_Scratch (lw)

#Vuelta a MD

lw r2,4(r31)	# Read miss sobre Set "00" via 0
sw r1,4(r31)	# Write hit sobre Set "00" via 0

sw r1,16(r31)	# Write miss sobre Set "01" via 0
sw r1,80(r31)	# Write miss sobre Set "01" via 1
lw r3,144(r31)	# Read miss sobre Set "01" via 0
lw r4,208(r31)	# Read miss sobre Set "01" via 1

sw r1,144(r31)	# Write hit sobre Set "01" via 0
sw r3,144(r31)	# Write hit sobre Set "01" via 0
sw r4,144(r31)	# Write hit sobre Set "01" via 0

lw_inc r5,16(r31) # lw_inc miss que no invalida.
lw r3,144(r31)	# Read hit sobre Set "01" via 0


#I/O Registers ^^

sw r4,28672(r31)	# Intento de Write sobre Input Register
lw r4,28672(r31)	# Intento de Read sobre Input Register

sw r3,28676(r31) 	# Intento de Write sobre Output Register
lw r4,28676(r31)	# Intento de Read sobre Output Register

sw r2,28680(r31)	# Intento de Write sobre ACK Register
lw r4,28680(r31)	# Intento de Read sobre ACK Register