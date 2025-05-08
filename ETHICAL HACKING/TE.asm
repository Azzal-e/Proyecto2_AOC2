beq r1,r1,3
beq r1,r1,15
beq r1,r1,17
beq r1,r1,22
lw r2,4(r0)
lw r3, 8(r0)
sw r3, 4(r2)
lw r3, 12(r0)
sw r3, 8(r2)
lw_inc r4, 65(r0)
lw r5, 0(r3)
sw r5, 12(r0)
lw r6, 512(r0)
lw r6, 508(r0)
sw r6, 32(r0)
sw r6, 0(r3)
beq r0, r0, 65535
lw r1, 0(r0)
sw r1, 28680(r0)
rte
lw r1, 4(r2)
sw r1, 28676(r0)
lw r1, 8(r2)
lw r1, 0(r1)
sw r1, 48(r0)
rte
lw r1, 16(r0)
sw r1, 28676(r0)
beq r0, r0, 65532
