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
    ; PORTB no se usa para la matriz en este ejemplo
    ; Lo dejamos apagado
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
    ; Configurar PORTD
    ;
    ; Filas:
    ; PD0 -> S2
    ; PD1 -> S1
    ; PD2 -> S0
    ;
    ; PD3 -> Start / INT1
    ;-------------------------------------------
    ldi r18, 0b00000111
    out DDRD, r18

    ; PD3 como entrada
    cbi DDRD, 3

    ; Sin pull-up interna.
    cbi PORTD, 3

    ;-------------------------------------------
    ; Apagar matriz inicialmente
    ;
    ; Mandamos fila 8 al decodificador.
    ; Como solo usas salidas 0 a 7, la salida 8 queda sin conexión.
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
    ; Si parpadea mucho, puedes bajar este valor.
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

    reti

;***********************************************
ISR_TIMER0_COMPA:

    ;-------------------------------------------
    ; Primero revisamos si ya se presionó Start
    ;-------------------------------------------
    lds r16, juego_activo
    cpi r16, 0x01
    brne APAGAR_MATRIZ

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
; Fila 6, columna 4
;***********************************************
MOSTRAR_PIXEL_0:

    ; Apagar momentáneamente la matriz
    ldi r18, 0b01000000
    out PORTC, r18

    ldi r18, 0b00000000
    out PORTD, r18

    ; Columna 4 = 0100
    ; PC2=S3, PC3=S2, PC4=S1, PC5=S0
    ;
    ; 0100 significa:
    ; S3=0, S2=1, S1=0, S0=0
    ; Entonces se activa PC3.
    ldi r18, 0b00001000
    out PORTC, r18

    ; Fila 6 = 0110
    ; PC6=S3, PD0=S2, PD1=S1, PD2=S0
    ;
    ; 0110 significa:
    ; S3=0, S2=1, S1=1, S0=0
    ; Entonces PD0=1, PD1=1, PD2=0.
    ldi r18, 0b00000011
    out PORTD, r18

    rjmp AVANZAR_PIXEL

;***********************************************
; Pixel 1:
; Fila 7, columna 3
;***********************************************
MOSTRAR_PIXEL_1:

    ; Apagar momentáneamente la matriz
    ldi r18, 0b01000000
    out PORTC, r18

    ldi r18, 0b00000000
    out PORTD, r18

    ; Columna 3 = 0011
    ; S3=0, S2=0, S1=1, S0=1
    ; PC4=1, PC5=1
    ldi r18, 0b00110000
    out PORTC, r18

    ; Fila 7 = 0111
    ; S3=0, S2=1, S1=1, S0=1
    ; PD0=1, PD1=1, PD2=1
    ldi r18, 0b00000111
    out PORTD, r18

    rjmp AVANZAR_PIXEL

;***********************************************
; Pixel 2:
; Fila 7, columna 5
;***********************************************
MOSTRAR_PIXEL_2:

    ; Apagar momentáneamente la matriz
    ldi r18, 0b01000000
    out PORTC, r18

    ldi r18, 0b00000000
    out PORTD, r18

    ; Columna 5 = 0101
    ; S3=0, S2=1, S1=0, S0=1
    ; PC3=1, PC5=1
    ldi r18, 0b00101000
    out PORTC, r18

    ; Fila 7 = 0111
    ; PD0=1, PD1=1, PD2=1
    ldi r18, 0b00000111
    out PORTD, r18

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

    ; Mandar fila 8 para que no se vea nada
    ldi r18, 0b01000010
    out PORTC, r18

    ldi r18, 0b00000000
    out PORTD, r18

;***********************************************
FIN_TIMER:
    reti