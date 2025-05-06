# Programa que recorre una matriz 4x4 usando bucles
# Matriz A: posiciones 0-60 (16 palabras de 4 bytes)
# Matriz B: posiciones 64-124 (16 palabras)
# Matriz Resultado: posiciones 128-188 (16 palabras)

# Inicialización de registros
add r0, r0, r0      # r0 = 0 (dirección base)
add r14, r0, r0      # r14 = 0
add r15, r0, r0      # r15 = 0 (contador de bucle)
lw r11, 272(r0)     # Cargar constante 1
lw r12, 264(r0)     # Cargar constante 16
#r13 para fin de bucle
add r13,r11,r11		# r13 = 1 + 1 = 2
add r13,r13,r13		# r13 = 2 + 2 = 4


# Inicializar punteros
add r1, r0, r0      # r1 apunta al inicio de matriz A
lw r2, 256(r0)      # r2 = 64 (inicio de matriz B, cargar desde memoria)
lw r3, 288(r0)      # r3 = 128 (inicio de matriz Resultado, cargar desde memoria)
# Cargar registro useless para ocupar bien una via entera.

lw r16,304(r0)



# Bucle principal para recorrer la matriz
bucle_inicio:
    lw r4, 0(r1)        # Cargar elemento de A
    lw r5, 0(r2)        # Cargar elemento de B
    add r6, r4, r5      # Sumar elementos
	
	lw r4,4(r1)
    lw r5,4(r2)
    add r7, r4, r5
	
	lw r4,4(r1)
    lw r5,4(r2)
	add r8, r4, r5
	
	lw r4,4(r1)
    lw r5,4(r2)
	add r9, r4, r5
	
	sw r6,0(r3)
	sw r7,4(r3)
	sw r8,8(r3)
	sw r9,12(r3)
	
	add r1,r1,r12		# Avanzar punteros...
	add r2,r2,r12
	add r3,r3,r12
	
	add r15,r15,r11		# Avanzar contador
	
	beq r15,r13, FIN_BUCLE1
	beq r0,r0, INICIO_BUCLE1
	
	
fin_bucle1:

# Segunda fase: multiplicar cada elemento por 2
# Restablecemos contadores
add r15, r0, r0      # Reiniciar contador
lw r1, 288(r0)      # r1 = 128 (inicio de matriz Resultado)
lw r3, 292(r0)      # r3 = 192 (nueva ubicación para almacenar)

# Bucle de multiplicación por 2
bucle_mult:
    lw r4, 0(r1)        # Cargar elemento de Resultado
    add r5, r4, r4      # Multiplicar por 2 (sumando consigo mismo)
	lw r4,4(r1)
	add r6, r4, r4
	lw r4,8(r1)
	add r7, r4, r4
	lw r4,12(r1)
	add r8, r4, r4
    sw r5, 0(r1)        # Guardar resultado
	sw r6, 4(r1)
	sw r7, 8(r1)
	sw r8, 12(r1)	
	
	add r1,r1,r12		# Avanzar puntero
    add r15, r15, r11     # Incrementar contador
	
    beq r15, r13, fin_bucle2  # Si hemos terminado, salir
    beq r0,r0,BUCLE_MULT      # Volver al inicio del bucle
fin_bucle2:

# Invalidación de caché usando lw_inc
lw r2, 256(r0)      # r2 = 64 (inicio de matriz B)
lw_inc r4,0(r2)
lw_inc r4,16(r2)
lw_inc r4,32(r2)
lw_inc r4,48(r2)
# Esto de arriba debería invalidar los 4 bloques que siguen en la vía 1.


# Repetir primer bucle para ver diferencia de rendimiento
add r15, r0, r0     # Reiniciar contador
add r1, r0, r0      # r1 apunta al inicio de matriz A
lw r2, 256(r0)      # r2 = 64 (inicio de matriz B)
lw r3, 276(r0)      # r3 = 320 (otra ubicación para almacenar)

# Repetir bucle principal tras invalidación
bucle_repetir:
    lw r4, 0(r1)        # Cargar elemento de A
    lw r5, 0(r2)        # Cargar elemento de B -> Se debería ver que efectivamente tiene que hacer Fetch
    add r6, r4, r5      # Sumar elementos
	
	lw r4,4(r1)
    lw r5,4(r2)
    add r7, r4, r5
	
	lw r4,4(r1)
    lw r5,4(r2)
	add r8, r4, r5
	
	lw r4,4(r1)
    lw r5,4(r2)
	add r9, r4, r5
	
	sw r6,0(r3)
	sw r7,4(r3)
	sw r8,8(r3)
	sw r9,12(r3)
	
	add r1,r1,r12		# Avanzar punteros...
	add r2,r2,r12
	add r3,r3,r12
	
	add r15,r15,r11		# Avanzar contador
	
	beq r15,r13, FIN
	beq r0,r0, bucle_repetir
FIN: