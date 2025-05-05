add r0,r0,r0

#Set: "10" -> VIA 0: 96,100,104,108 ; VIA 1: 32,36,40,44

lw r1,96(r0)
lw r1,100(r0)

lw r2,32(r0)
lw r2,40(r0)

#Set: "01" -> VIA 0: 16,20,24,28 ; VIA 1: 80,84,88,92

sw r1,16(r0)
lw r3,20(r0)
sw r3,16(r0)

sw r2,80(r0)
lw r2,80(r0)
lw r4,84(r0)

#Vuelvo a Set "10" para tests "SENCILLOS"

lw r1,108(r0)
lw r2,36(r0)

#Tests de conflicto Set "10" + LW_INC recien expulsado -> VIA 0: 160,164,168,172 ; VIA 1: 224,228,232,236

lw r5,160(r0)
lw_inc r8,96(r0)
lw r6,224(r0)

#Tests de lw_inc invalidan: Set "10" -> VIA 0: 160,164,168,172 y VIA 1: 224,228,232,236

lw_inc r6,224(r0)
lw_inc r5,164(r0)
lw_inc r4,64(r0) # Este no invalida, no hay nada en Set "00"

#Invalidados. Set "01" -> VIA 0: 144,148,152,156 ; VIA 1: 208,212,216,220

lw r6,228(r0)
sw r6,144(r0)
sw r7,208(r0)

#Varios seguidos.

sw r1,160(r0)
sw r1,224(r0)
sw r2,148(r0)
sw r2,216(r0)

#Read hit seguidos

lw r1,144(r0)
lw r1,148(r0)
lw r1,152(r0)
lw r1,156(r0)

#Set: "00" -> VIA 0: 0,4,8,12 ; VIA 1: 64,68,72,76

lw r1,0(r0)
lw r2,64(r0)
lw_inc r1,128(r0)
lw r1,0(r0)
lw r1,128(r0)
lw r1,0(r0)
sw r1,68(r0)

sw r1,144(r0) #Set "01" VIA 0