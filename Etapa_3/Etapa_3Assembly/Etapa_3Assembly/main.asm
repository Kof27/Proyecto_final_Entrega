;
; Etapa_1Assembly.asm
;
; Botón Start en PD3 usando interrupción INT1
; Matriz 8x8 usando dos decodificadores 4:10
;

.include "m328PBdef.inc"

;***********************************************
; Variables en memoria RAM
;***********************************************
.dseg
juego_activo: .byte 1
pixel_actual: .byte 1
unidades: .byte 1
decenas: .byte 1
contador: .byte 1
pos_carro: .byte 1
boton_lock: .byte 1

;***********************************************
; Segmento de código
;***********************************************
.cseg

.org 0x0000
    rjmp RESET               ; Vector de reset

.org 0x0004
    rjmp START               ; Vector de interrupción externa INT1

.org 0x001C
    rjmp ISR_TIMER0_COMPA    ; Vector Timer0 Compare Match A

;***********************************************
RESET:

    ;-------------------------------------------
    ; Inicializar Stack Pointer
    ;-------------------------------------------
    ldi r16, HIGH(RAMEND)
    out SPH, r16

    ldi r16, LOW(RAMEND)
    out SPL, r16

    ;-------------------------------------------
    ; PORTB 
    ;-------------------------------------------
    ldi r16, 0xFF
    out DDRB, r16

    ldi r16, 0x00
    out PORTB, r16

    ;-------------------------------------------
    ; Configurar PORTC
    ;
    ; Columnas:
    ; PC2 -> S3
    ; PC3 -> S2
    ; PC4 -> S1
    ; PC5 -> S0
    ;
    ; Filas:
    ; PC6 -> S3 del decodificador de filas
    ;-------------------------------------------
    ldi r18, 0b01111110
    out DDRC, r18
    ;-------------------------------------------
	; PD3 = Start / INT1
	; PD4 = botón derecha
	; Ambos como entrada sin pull-up
	;-------------------------------------------
	cbi DDRD, 3        ; PD3 como entrada
	cbi DDRD, 4        ; PD4 como entrada

	cbi PORTD, 3       ; Pull-up interna en PD3
	cbi PORTD, 4       ; Pull-up interna en PD4

	;-------------------------------------------
	; PE0 = botón izquierda
	; Como entrada sin pull-up
	;-------------------------------------------
	cbi DDRE, 0        ; PE0 como entrada
	cbi PORTE, 0       ; Pull-up interna en PE0
    ;-------------------------------------------
    ; Apagar matriz inicialmente
    ;-------------------------------------------
    ldi r18, 0b01000010
    out PORTC, r18

    ldi r18, 0b00000000
    out PORTD, r18

    ;-------------------------------------------
    ; Variables iniciales
    ;-------------------------------------------
    ldi r16, 0x00
    sts juego_activo, r16

    ldi r16, 0x00
    sts pixel_actual, r16

	ldi r16, 0x00
	sts unidades, r16
	sts decenas, r16
	sts contador, r16

	; Posición inicial del carro en el centro
	ldi r16, 3
	sts pos_carro, r16

	; Botones desbloqueados
	ldi r16, 0
	sts boton_lock, r16

    ;-------------------------------------------
    ; Configurar INT1 por flanco de subida
    ;
    ; ISC11 = 1
    ; ISC10 = 1
    ;
    ; Esto significa que START se ejecuta cuando
    ; PD3 pasa de 0 a 1.
    ;-------------------------------------------
    ldi r16, 0b00001100
    sts EICRA, r16

    ;-------------------------------------------
    ; Limpiar bandera de INT1
    ;-------------------------------------------
    ldi r16, 0b00000010
    sts EIFR, r16

    ;-------------------------------------------
    ; Habilitar INT1
    ;-------------------------------------------
    ldi r16, 0b00000010
    out EIMSK, r16

    ;-------------------------------------------
    ; Configurar Timer0 en modo CTC
    ;-------------------------------------------
    ldi r16, 0b00000010
    out TCCR0A, r16

    ; Valor de comparación.
    ldi r16, 250
    out OCR0A, r16

    ; Habilitar interrupción Timer0 Compare Match A
    ldi r16, 0b00000010
    sts TIMSK0, r16

    ; Encender Timer0 con prescaler 64
    ldi r16, 0b00000011
    out TCCR0B, r16

    ;-------------------------------------------
    ; Habilitar interrupciones globales
    ;-------------------------------------------
    sei

;***********************************************
MAIN:
    rjmp MAIN

;***********************************************
START:

    ;mostrar numeros
    cbi PORTC, 1

    ; Activar el juego/matriz
    ldi r16, 0x01
    sts juego_activo, r16

    ; Iniciar desde el primer pixel
    ldi r16, 0x00
    sts pixel_actual, r16

    ; Reiniciar contador a 00
    ldi r16, 0x00
    sts unidades, r16
    sts decenas, r16
    sts contador, r16

    ; Vehículo al centro
    ldi r16, 3
    sts pos_carro, r16

    ; Desbloquear botones
    ldi r16, 0
    sts boton_lock, r16

    ; Mostrar info displays
    rcall MOSTRAR_DISPLAY

    reti

;***********************************************
ISR_TIMER0_COMPA:

    ;-------------------------------------------
    ; Primero revisamos si ya se presionó Start
    ;-------------------------------------------
    lds r16, juego_activo
    cpi r16, 0x01
    brne APAGAR_MATRIZ
	rcall LEER_BOTONES
	rcall ACTUALIZAR_CONTADOR

    ;-------------------------------------------
    ; Leer cuál pixel toca mostrar
    ;-------------------------------------------
    lds r16, pixel_actual

    cpi r16, 0
    breq MOSTRAR_PIXEL_0

    cpi r16, 1
    breq MOSTRAR_PIXEL_1

    cpi r16, 2
    breq MOSTRAR_PIXEL_2

    rjmp REINICIAR_PIXEL

;***********************************************
; Pixel 0:
; Fila 6, columna pos_carro + 1
;***********************************************
MOSTRAR_PIXEL_0:

    lds r20, pos_carro
    inc r20              ; columna = pos_carro + 1

    ldi r21, 6           ; fila 6
    rcall MOSTRAR_LED

    rjmp AVANZAR_PIXEL

;***********************************************
; Pixel 1:
; Fila 7, columna pos_carro
;***********************************************
MOSTRAR_PIXEL_1:

    lds r20, pos_carro   ; columna = pos_carro

    ldi r21, 7           ; fila 7
    rcall MOSTRAR_LED

    rjmp AVANZAR_PIXEL

;***********************************************
; Pixel 2:
; Fila 7, columna pos_carro + 2
;***********************************************
MOSTRAR_PIXEL_2:

    lds r20, pos_carro
    inc r20
    inc r20              ; columna = pos_carro + 2

    ldi r21, 7           ; fila 7
    rcall MOSTRAR_LED

    rjmp AVANZAR_PIXEL

;***********************************************
AVANZAR_PIXEL:

    ; pixel_actual = pixel_actual + 1
    lds r16, pixel_actual
    inc r16

    ; Si pixel_actual < 3, guardar normal
    cpi r16, 3
    brlo GUARDAR_PIXEL

REINICIAR_PIXEL:
    ; Si llegó a 3, volver a 0
    ldi r16, 0

GUARDAR_PIXEL:
    sts pixel_actual, r16
    rjmp FIN_TIMER

;***********************************************
APAGAR_MATRIZ:

    ; PC6 = 1 para fila 8 apagada
    ; PC1 = 1 mientras no se presiona Start
    ldi r18, 0b01000010
    out PORTC, r18

    ; Mantener pull-up de PD3 y PD4
    ldi r18, 0b00000000
    out PORTD, r18

    rjmp FIN_TIMER

;***********************************************
FIN_TIMER:
    reti
;***********************************************
; ACTUALIZAR_CONTADOR
;***********************************************
ACTUALIZAR_CONTADOR:

    ; contador_ticks++
    lds r16, contador
    inc r16
    sts contador, r16
    cpi r16, 250
    brlo FIN_ACTUALIZAR_CONTADOR

    ; Si llegó al valor definido, reinicia ticks
    ldi r16, 0x00
    sts contador, r16

    ; Aumentar unidades
    lds r16, unidades
    inc r16

    ; Si unidades < 10, guardar y mostrar
    cpi r16, 10
    brlo GUARDAR_UNIDADES

    ; Si unidades llegó a 10, vuelve a 0
    ldi r16, 0x00
    sts unidades, r16

    ; Aumentar decenas
    lds r17, decenas
    inc r17

    ; Si decenas < 10, guardar
    cpi r17, 10
    brlo GUARDAR_DECENAS

    ; Si decenas llegó a 10, significa que pasó de 99.
    ; Entonces vuelve a 00.
    ldi r17, 0x00

GUARDAR_DECENAS:
    sts decenas, r17
    rcall MOSTRAR_DISPLAY
    rjmp FIN_ACTUALIZAR_CONTADOR

GUARDAR_UNIDADES:
    sts unidades, r16
    rcall MOSTRAR_DISPLAY

FIN_ACTUALIZAR_CONTADOR:
    ret

;***********************************************
; MOSTRAR_DISPLAY
;
; Muestra decenas y unidades en PORTB.
;
; PB0-PB3 = DECENAS
; PB4-PB7 = UNIDADES
;***********************************************
MOSTRAR_DISPLAY:

    ; Cargar unidades en r17
    lds r17, unidades

    ; Cargar decenas en r16
    lds r16, decenas

    ; Mover decenas a la parte alta del byte
    lsl r17
    lsl r17
    lsl r17
    lsl r17

    ; Unir decenas y unidades
    or r16, r17

    ; Enviar a los BcdTo7S
    out PORTB, r16

    ret
;***********************************************
; LEER_BOTONES
;
; PE0 = botón izquierda
; PD4 = botón derecha
;
; Sin pull-up interna:
; Sin presionar = 0
; Presionado    = 1
;***********************************************
LEER_BOTONES:

    ; Si los botones están bloqueados,
    ; verificar si ya se soltaron
    lds r16, boton_lock
    cpi r16, 1
    breq VERIFICAR_SOLTAR_BOTONES

    ;-------------------------------------------
    ; Revisar botón izquierda en PE0
    ; sbic salta si el bit está en 0.
    ; Si PE0 está en 1, NO salta y ejecuta rjmp.
    ;-------------------------------------------
    sbic PINE, 0
    rjmp BOTON_IZQUIERDA_PRESIONADO

    ;-------------------------------------------
    ; Revisar botón derecha en PD4
    ; Si PD4 está en 1, está presionado.
    ;-------------------------------------------
    sbic PIND, 4
    rjmp BOTON_DERECHA_PRESIONADO

    ret

BOTON_IZQUIERDA_PRESIONADO:

    rcall MOVER_IZQUIERDA

    ; Bloquear hasta que se suelte el botón
    ldi r16, 1
    sts boton_lock, r16

    ret

BOTON_DERECHA_PRESIONADO:

    rcall MOVER_DERECHA

    ; Bloquear hasta que se suelte el botón
    ldi r16, 1
    sts boton_lock, r16

    ret

VERIFICAR_SOLTAR_BOTONES:

    ; Si PE0 sigue en 1, todavía está presionado
    sbic PINE, 0
    ret

    ; Si PD4 sigue en 1, todavía está presionado
    sbic PIND, 4
    ret

    ; Si ambos están en 0, ya se soltaron
    ldi r16, 0
    sts boton_lock, r16

    ret
;***********************************************
; MOVER_IZQUIERDA
;
; Límite izquierdo: pos_carro = 0
;***********************************************
MOVER_IZQUIERDA:

    lds r16, pos_carro

    ; Si ya está en 0, no se mueve más
    cpi r16, 0
    breq FIN_MOVER_IZQUIERDA

    dec r16
    sts pos_carro, r16

FIN_MOVER_IZQUIERDA:
    ret

;***********************************************
; MOVER_DERECHA
;
; Límite derecho: pos_carro = 5
; Porque el carro ocupa columnas:
; pos_carro, pos_carro+1, pos_carro+2
;***********************************************
MOVER_DERECHA:

    lds r16, pos_carro

    ; Si ya está en 5, no se mueve más
    cpi r16, 5
    breq FIN_MOVER_DERECHA

    inc r16
    sts pos_carro, r16

FIN_MOVER_DERECHA:
    ret

;***********************************************
; MOSTRAR_LED
;
; Entrada:
; r20 = columna 0 a 7
; r21 = fila 0 a 7
;***********************************************
MOSTRAR_LED:

    ; Apagar momentáneamente la matriz
    ; Columna 8 y fila 8 quedan sin conexión
    ldi r18, 0b01000100
    out PORTC, r18

    ; Apagar filas sin activar pull-up en PD3 y PD4
    ldi r18, 0b00000000
    out PORTD, r18

    ; Enviar columna
    rcall SET_COLUMNA

    ; Enviar fila
    rcall SET_FILA

    ret
;***********************************************
; SET_COLUMNA
;
; Entrada:
; r20 = columna
;
; Columnas:
; PC2 -> S3
; PC3 -> S2
; PC4 -> S1
; PC5 -> S0
;***********************************************
SET_COLUMNA:

    ; Limpiar PC2, PC3, PC4, PC5
    ; Mantener PC6 y PC1 como estén
    in r18, PORTC
    andi r18, 0b11000011

    ; bit 3 de r20 -> PC2
    sbrc r20, 3
    ori r18, 0b00000100

    ; bit 2 de r20 -> PC3
    sbrc r20, 2
    ori r18, 0b00001000

    ; bit 1 de r20 -> PC4
    sbrc r20, 1
    ori r18, 0b00010000

    ; bit 0 de r20 -> PC5
    sbrc r20, 0
    ori r18, 0b00100000

    out PORTC, r18

    ret

;***********************************************
; SET_FILA
;
; Entrada:
; r21 = fila
;
; Filas:
; PC6 -> S3
; PD0 -> S2
; PD1 -> S1
; PD2 -> S0
;***********************************************
SET_FILA:

    ;-------------------------------------------
    ; bit 3 de fila -> PC6
    ;-------------------------------------------
    in r18, PORTC
    andi r18, 0b10111111     ; limpiar PC6

    sbrc r21, 3
    ori r18, 0b01000000

    out PORTC, r18

    ;-------------------------------------------
    ; bits 2,1,0 de fila -> PD0,PD1,PD2
    ; PD3 y PD4 sin pull-up interna
    ;-------------------------------------------
    in r18, PORTD
    andi r18, 0b11111000     ; limpiar PD0, PD1, PD2

    ; bit 2 de r21 -> PD0
    sbrc r21, 2
    ori r18, 0b00000001

    ; bit 1 de r21 -> PD1
    sbrc r21, 1
    ori r18, 0b00000010

    ; bit 0 de r21 -> PD2
    sbrc r21, 0
    ori r18, 0b00000100

    out PORTD, r18

    ret