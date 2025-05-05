add r0, r0, r0
add r14, r0, r0
add r15, r0, r0
lw r10, 252(r0)
lw r11, 268(r0)
lw r12, 264(r0)
add r13, r11, r11
add r13, r13, r13
add r1, r0, r0
lw r2, 256(r0)
lw r3, 260(r0)
lw r4, 0(r1)
lw r5, 0(r2)
add r6, r4, r5
lw r4, 4(r1)
lw r5, 4(r2)
add r7, r4, r5
lw r4, 4(r1)
lw r5, 4(r2)
add r8, r4, r5
lw r4, 4(r1)
lw r5, 4(r2)
add r9, r4, r5
sw r6, 0(r3)
sw r7, 4(r3)
sw r8, 8(r3)
sw r9, 12(r3)
add r1, r1, r12
add r2, r2, r12
add r3, r3, r12
add r15, r15, r11
beq r15, r13, 1
beq r0, r0, -22
add r15, r0, r0
lw r1, 260(r0)
lw r3, 272(r0)
lw r4, 0(r1)
add r5, r4, r4
lw r4, 4(r1)
add r6, r4, r4
lw r4, 8(r1)
add r7, r4, r4
lw r4, 12(r1)
add r8, r4, r4
sw r5, 0(r1)
sw r6, 4(r1)
sw r7, 8(r1)
sw r8, 12(r1)
add r1, r1, r12
add r15, r15, r11
beq r15, r13, 1
beq r0, r0,-16
lw r2, 256(r0)
lw_inc r4, 0(r2)
lw_inc r4, 16(r2)
lw_inc r4, 32(r2)
lw_inc r4, 48(r2)
add r15, r0, r0
add r1, r0, r0
lw r2, 256(r0)
lw r3, 276(r0)
lw r4, 0(r1)
lw r5, 0(r2)
add r6, r4, r5
lw r4, 4(r1)
lw r5, 4(r2)
add r7, r4, r5
lw r4, 4(r1)
lw r5, 4(r2)
add r8, r4, r5
lw r4, 4(r1)
lw r5, 4(r2)
add r9, r4, r5
sw r6, 0(r3)
sw r7, 4(r3)
sw r8, 8(r3)
sw r9, 12(r3)
add r1, r1, r12
add r2, r2, r12
add r3, r3, r12
add r15, r15, r11
beq r15, r13, 1
beq r0, r0,-22