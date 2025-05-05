;; TEST DE COMPROBACIÓN DE ERRORES. COMPRENDE TRES TIPOS DE ERRORES.
;; 1. Acceso desalineado a palabra
;; 2. Dirección de bloque o palabra no reconocida por ningún dispositivo (devsel = 0)
;; 3. Error por intento de lectura de un registro interno
;; Además, se verá como el sistema pasa a estado normal después de leer de un registro interno.

Reset: beq  R1, R1, INI ;@0x0 (Salta a INI en 0x10) 
IRQ: beq  R1, R1, RTI ;@0x4 (Salta a IRQ en 0x14)
DAbort: beq R1, R1, RT_Abort;@0x8 (Salta a DAbort en 0x18)
UNDEF: beq R1, R1, RT_Undef;@0xC (Salta a UNDEF en 0x1C)

;; CONTENIDO MD: 1, 0x10000000, 0x00000AB0, 0x01000000, 0x0BAD0C0D;
;; CONTENIDO MD : ULTIMA PALABNRA CON UN 0x4
INI: 
    LW R2, 4(r0) ;@Ox10 (Cargar el valor del inicio de memoria scratch 0x10000000)
                 ; READ MISS ->  VIA 0 SET 0
    LW, R3, 8(R0) ;@0x14 (Cargar el valor de error abort de la dirección 0x0004)
                  ; READ HIT -> VIA 0 SET  0
    SW R3, 4(R2) ;@0x18 (Almacenar el valor de R2 en la dirección 0x01000004)
                 ; WRITE IN MDSCRATCH
    LW R3, 12(R0) ; @0x1C (Cargar el valor de dirección de ADDR_ERROR_Register de la dirección 0x0008)
                  ; READ HIT -> VIA 0 SET 0
    SW R3, 8(R2) ;@0x18 (Almacenar el valor de ADDR_Error_Register en la dirección 0x01000008)
                 ; WRITE IN MDSCRATCH
    
    ;;  Probar acceso desalineado a palabra

    LW_INC R4,65(R0); @0x20 (Cargar el valor de R3 en la dirección 0x00000001)
                    ; ERROR DESALINEADO -> "SET 0", PERO NO HAY REEMPLAZO
    LW R5, 0(R3) ;@0x24 (Volvemos a leer el valor del registro de error, pero ya estaba en modo normal)
                 ; READ HIT DE INTERNAL REGISTER
    SW R5, 12(R0); @0x28 (donde estaba el valor de registro de error se guarda dirección de valor invalido)
                 ; WRITE HIT -> VIA 0 SET 0 (porque instrucción anterior era errónea)
    
    ;; Probar Dirección de bloque o palabra no reconocida por ningún dispositivo (devsel = 0)
    LW R6, 512(R0); @0x2C (Intentar cargar el valor de una dirección no mapeable 0x00000200)
                    ; READ ERROR -> DISPOSITIVO NO RECONOCIDO
    LW r6, 508(R0); @0x30 (Cargar el valor de la dirección de error de la dirección 0x000001FC)
                  ; READ MISS -> VIA 1 SET 3  
    SW r6, 32(R0) ; @0x34 (Almacenar el valor de R6 en la dirección 0x00000020)
                 ; WRITE MISS -> VIA 0 SET 2 
    
    ;; Probar escritura de registro interno
    SW r6, 0(R3); @0x38 (Intentar escribir en el registro de error el valor 4)
                 ; WRITE ERROR -> INTENTO DE ESCRITURA DE REGISTRO INTERNO

    beq R0, R0, 65535 ;@0x3C BUCLE INFINITO

RTI: 
    LW R1, 0(R0) ;@0x40 (Cargar en R1 el valor 1)
                 ; READ HIT
    SW R1, 28680(R0) ;@0x44 (Almacenar el valor de R1 en la dirección 0x7008)
    RTE ;@0x48 (Retornar de la interrupción)

DAbort: 
    LW R1, 4(R2) ;@0x4C (Cargar en R1 el valor de error abort de registro de error de memoria scratch 0x10000004)
    SW R1, 28676(R0) ;@0x50 (Almacenar el valor de R1 en la dirección 0x7004)
                      ; LECTURA DE IO -> NO INTERVIENE MEMORIA CACHE
    LW R1,  8(R2) ; @54LEER DE MEMORIA SCRATCH EL VALOR DE LA DIRECCIÓN DE ERROR INTERNO 0x10000008
    LW r1, 0(R1) ;@58 (leer del registro ADDR_Error_Register el valor de la dirección problemática)
                         ; PASA A ESTADO NO ERROR
                         ; LECTURA DE REGISTRO INTERNO
    SW R1, 48(R0) ;@0x5C (Almacenar el valor de R1 en la dirección 0x0030)
                 ; 1er ERROR: WRITE MISS -> VIA 0 SET 3
                 ; 2o y 3er ERROR: WRITE HIT -> VIA 0 SET 3 
    RTE;@0X60 Volver a Ini
    

RT_Undef: LW R1, 16(R0) ;0x64 (cargar  0x0BAD0C0D)
                        ; READ MISS la 1 vez (read hit las siguientes) -> via 0 set 1
       SW R1, 28676(R0) ;@0x68 (Almacenar el valor de R1 en la dirección 0x7004)
       beq R0, R0, 65532 ;@Ox6C (#inm = -3)