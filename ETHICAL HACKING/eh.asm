lw r0, 0(r0)
lw r1, 4(r0)
lw r2, 8(r0)
lw r3, 12(r0)
add r4, r3, r3
add r4, r4, r4
add r5, r0, r5 
add r6, r1, r6  
add r7, r2, r7 
add r8, r3, r8 
sw r0, 0(r9)
sw r0, 64(r9)
sw r0, 128(r9)
sw r0, 192(r9)
sw r1, 16(r9)
sw r1, 80(r9)
sw r1, 144(r9)
sw r1, 208(r9)
sw r2, 32(r9)
sw r2, 96(r9)
sw r2, 160(r9)
sw r2, 224(r9)
sw r3, 48(r9)
sw r3, 112(r9)
sw r3, 176(r9)
sw r3, 240(r9)
add r0, r0, r5 
add r1, r1, r6 
add r2, r2, r7
add r3, r3, r8
sub r4, r4, r5 
beq r4, r9, 1
beq r0, r0, 65513
lw r0, 0(r9)
lw r1, 64(r9)
lw r2, 128(r9)
lw r3, 192(r9)
add r0, r0, r1
add r0, r0, r2
add r0, r0, r3
sw r0, 0(r9)
lw r0, 16(r9)
lw r1, 80(r9)
lw r2, 144(r9)
lw r3, 208(r9)
add r0, r0, r1 
add r0, r0, r2 
add r0, r0, r3 
sw r0, 64(r9)
lw r0, 32(r9)
lw r1, 96(r9)
lw r2, 160(r9)
lw r3, 224(r9)
add r0, r0, r1
add r0, r0, r2
add r0, r0, r3
sw r0, 128(r9)
lw r0, 48(r9)
lw r1, 112(r9)
lw r2, 176(r9)
lw r3, 240(r9)
add r0, r0, r1
add r0, r0, r2
add r0, r0, r3
sw r0, 192(r9)
beq r0, r0, 65535