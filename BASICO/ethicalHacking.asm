;; TEST PARA REALIZAR UN "HACKING ÉTICO" EN EL SISTEMA DE MEMORIA CACHE
;; Para ello, se van a saturar todos los conjuntos de ambas vías de la memoria cahce
;; Se escogeran 4 bloques por conjunto, los cuales se irán cargando sucesivamente. De este
;; modo, los pares de bloques se irán expulsando entre sí de la cache sin dar opción a 
;; que se de si quiera un hit.

;; Contenido de la MD inicial:
;; 1, 2, 3, 4

;; NOTA : Bloques por vía seleccionados arbitrariamente:
;; SET 0: 0x0000, 0x0040, 0x0080, 0x00C0
;; SET 1: 0x0010, 0x0050, 0x0090, 0x00D0
;; SET 2: 0x0020, 0x0060, 0x00A0, 0x00E0
;; SET 3: 0x0030, 0x0070, 0x00B0, 0x00F0

;; En cada vía i, el programa calcula 4* 16 * i+1 de una manera curiosa
;; Carga de atributos de la MD:
lw r0, 0(r0); @0x0000 (cargar el valor 1)
            ; READ MISS OBLIGATORIO -> VIA 0 SET 0 
lw r1, 4(r0); @0x0004 (cargar el valor 2)
             ; READ HIT -> VIA 0 SET 0 
lw r2, 8(r0); @0x0008 (cargar el valor 3)
             ; READ HIT -> VIA 0 SET 0 
lw r3, 12(r0); @0x000C (cargar el valor 4)
                 ; READ HIT -> VIA 0 SET 0 
add r4, r3, r3; @0x0010
add r4, r4, r4; @0x0014 (r4 = 4*4 = 16)

add r5, r0, r5 ; @0x0018 
add r6, r1, r6 ; @0x001C 
add r7, r2, r7 ; @0x0020 
add r8, r3, r8 ; @0x0024 
;; BUCLE PRINCIPAL

;; ------- SET 0 -------
INI: sw r0, 0(r9); @0x0028 (almacenar el valor 1 * k en la dirección 0x00000000)
                ; WRITE MISS CONFLICTO -> VIA 0 SET 0  (excepto en la primera iteración, que es hit)
sw r0, 64(r9); @0x002C (almacenar el valor 1 * k en la dirección 0x00000040)
                ; WRITE MISS CONFLICTO -> VIA 1 SET 0 (excepto en la primera iteración, que es obligatorio)

sw r0, 128(r9); @0x0030 (almacenar el valor 1 * k en la dirección 0x00000080)
                ; WRITE MISS CONFLICTO -> VIA 0 SET 0

sw r0, 192(r9); @0x0034 (almacenar el valor 1 * k en la dirección 0x000000C0)
                ; WRITE MISS CONFLICTO -> VIA 1 SET 0

;; ------- SET 1 -------
sw r1, 16(r9); @0x0038 (almacenar el valor 2 * k en la dirección 0x00000010)
                ; WRITE MISS CONFLICTO -> VIA 0 SET 1 (excepto en la primera iteración, que es obligatorio)
sw r1, 80(r9); @0x003C (almacenar el valor 2 * k en la dirección 0x00000050)
                ;  WRITE MISS CONFLICTO -> VIA 1 SET 1  (excepto en la primera iteración, que es obligatorio)
sw r1, 144(r9); @0x0040 (almacenar el valor 2 * k en la dirección 0x00000090)
                ;  WRITE MISS CONFLICTO -> VIA 0 SET 1 
sw r1, 208(r9); @0x0044 (almacenar el valor 2 * k en la dirección 0x000000D0)
                ;  WRITE MISS CONFLICTO -> VIA 1 SET 1 

;; ------- SET 2 -------
sw r2, 32(r9); @0x0048 (almacenar el valor 3 * k en la dirección 0x00000020)
                ; WRITE MISS CONFLICTO -> VIA 0 SET 2 (excepto en la primera iteración, que es obligatorio)

sw r2, 96(r9); @0x004C (almacenar el valor 3 * k en la dirección 0x00000060)
                ; WRITE MISS CONFLICTO -> VIA 1 SET 2  (excepto en la primera iteración, que es obligatorio)
sw r2, 160(r9); @0x0050 (almacenar el valor 3 * k en la dirección 0x000000A0)
                ; WRITE MISS CONFLICTO -> VIA 0 SET 2 
sw r2, 224(r9); @0x0054 (almacenar el valor 3 * k en la dirección 0x000000E0)
                ; WRITE MISS CONFLICTO -> VIA 1 SET 2 

;; ------- SET 3 -------

sw r3, 48(r9); @0x0058 (almacenar el valor 4 * k en la dirección 0x00000030)
                ; WRITE MISS CONFLICTO -> VIA 0 SET 3 (excepto en la primera iteración, que es obligatorio)
sw r3, 112(r9); @0x005C (almacenar el valor 4 * k en la dirección 0x00000070)
                ; WRITE MISS CONFLICTO -> VIA 1 SET 3 (excepto en la primera iteración, que es obligatorio)

sw r3, 176(r9); @0x0060 (almacenar el valor 4 * k en la dirección 0x000000B0)
                ; WRITE MISS CONFLICTO -> VIA 1 SET 3
sw r3, 240(r9); @0x0064 (almacenar el valor 4 * k en la dirección 0x000000F0)
                ; WRITE MISS CONFLICTO -> VIA 1 SET 3

;; --- CÁLCULO DE i * (k+1)
add r1, r1, r5; @0x0068 
add r2, r2, r6; @0x006C 
add r3, r3, r7; @0x0070
add r4, r4, r8; @0x0074

;; Decrementar contador de iteraciones
sub r4, r4, r5 ;; @0x0078 (restar 1 al contador de iteraciones)
beq r4, r9, FIN; @0x007C (si el valor de r4 es igual a 0,  salgo del bucle)
beq r0, r0, INI; @0x0080 (si no , vuelvo a iterar)

;; FINAL DEL PROGRAMA
FIN : lw r0, 0(r9); @0x0084 (cargar el valor 1*16)
                ;; READ MISS CONFLICTO -> VIA 0 SET 0 
lw r1, 64(r9); @0x0088 (cargar el valor 1*16)
                ;; READ MISS CONFLICTO -> VIA 1 SET 0
lw r2, 128(r9); @0x008C (cargar el valor 1*16)
                ;; READ MISS CONFLICTO -> VIA 0 SET 0
lw r3, 192(r9); @0x0090 (cargar el valor 1*16)
                ;; READ MISS CONFLICTO -> VIA 1 SET 0

add r0, r0, r1; @0x0094 
add r0, r0, r2; @0x0098
add r0, r0, r3; @0x009C

sw r0, 0(r9); @0X00A0 (almacenar el valor 1 * 16* 4 )

                    ;; WRITE MISS CONFLICTO -> VIA 0 SET 0

lw r0, 16(r9); @0x00A4 (cargar el valor 2*16)
                ;; READ MISS CONFLICTO -> VIA 0 SET 1
lw r1, 80(r9); @0x00A8 (cargar el valor 2*16)
                ;; READ MISS CONFLICTO -> VIA 1 SET 1
lw r2, 144(r9); @0x00AC cargar el valor 2*16)
                ;; READ MISS CONFLICTO -> VIA 0 SET 1
lw r3, 208(r9); @0x00B0 cargar el valor 2*16)
                ;; READ MISS CONFLICTO -> VIA 1 SET 1
add r0, r0, r1 ;@0x00B4
add r0, r0, r2 ;@0x00B8
add r0, r0, r3 ;@0x00BC

sw r0, 64(r9); @0x00C0 (almacenar el valor 2 * 16* 4 en la dirección 0x00000010)
                    ;; WRITE MISS CONFLICTO -> VIA 1 SET 0

lw r0, 32(r9); @0x00C4 (cargar el valor 3*16 de la dirección 0x00000040)
                ;; READ MISS CONFLICTO -> VIA 0 SET 2
lw r1, 96(r9); @0x00C8 (cargar el valor 3*16 de la dirección 0x00000080)
                ;; READ MISS CONFLICTO -> VIA 1 SET 2   
lw r2, 160(r9); @0x00CC (cargar el valor 3*16 de la dirección 0x000000C0)
                ;; READ MISS CONFLICTO -> VIA 0 SET 2
lw r3, 224(r9); @0x00D0 (cargar el valor 3*16 de la dirección 0x00000010)
                ;; READ MISS CONFLICTO -> VIA 1 SET 2

add r0, r0, r1; @0x00D4
add r0, r0, r2; @0x00D8
add r0, r0, r3; @0x00DC

sw r0, 128(r9); @0x00E0 (almacenar el valor 2 * 16 *4 en la dirección 0x000000020)
                    ;; WRITE MISS CONFLICTO -> VIA 0 SET 0

lw r0, 48(r9); @0x00E4 (cargar el valor 4 * 16)
                    ;; READ MISS CONFLICTO -> VIA 0 SET 3
lw r1, 112(r9); @0x00E8 (cargar el valor 4 * 16)
                    ;; READ MISS CONFLICTO -> VIA 1 SET 3
lw r2, 176(r9); @0x00EC (cargar el valor 4 * 16)
                    ;; READ MISS CONFLICTO -> VIA 0 SET 3
lw r3, 240(r9); @0x00F0 (cargar el valor 4 * 16)
                    ;; READ MISS CONFLICTO -> VIA 1 SET 3

add r0, r0, r1; @0x00F4
add r0, r0, r2; @0x00F8
add r0, r0, r3; @0x00FC

sw r0, 192(r9); @0x0100 (almacenar el valor 2 en la dirección 0x00000010)
                    ;; WRITE MISS CONFLICTO -> VIA 1 SET 0

beq r0, r0, 65535; @0x0104 (si no , vuelvo a iterar)
;; FIN DEL PROGRAMA

