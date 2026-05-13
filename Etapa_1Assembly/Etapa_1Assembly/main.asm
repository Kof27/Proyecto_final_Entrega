;
; Etapa_1Assembly.asm
;
; Botón Start en PD3 usando interrupción INT1
;

.include "m328PBdef.inc"

;***********************************************
.org 0x0000
    rjmp RESET               ; Vector de reset

.org 0x0004
    rjmp START            ; Vector de interrupción externa INT1

;***********************************************
RESET:

	ldi r16, 0xFF
    out DDRB, r16

	ldi r18, 0b00000010
	out DDRC, r18
	ldi r18, 0b00000010
	out PORTC, r18
    ;-------------------------------------------
    ; Configurar PD3 como entrada
    ; PD3 será el botón Start
    ;-------------------------------------------
    cbi DDRD, 3              ; PD3 como entrada

    ; Activar resistencia pull-up interna en PD3
    ; Sin presionar = 1
    ; Presionado = 0
    cbi PORTD, 3

    ;-------------------------------------------
    ; Configurar INT1 por flanco de caída
    ; ISC11 = 1
    ; ISC10 = 0
    ;
    ; Bits en EICRA:
    ; ISC11 ISC10 controlan INT1
    ; 1     0     = flanco de caída
    ;-------------------------------------------
    ldi r16, 0b00001100
    sts EICRA, r16

    ;-------------------------------------------
    ; Limpiar bandera de INT1
    ; INTF1 está en el bit 1 de EIFR
    ; Se limpia escribiendo un 1
    ;-------------------------------------------
    ldi r16, 0b00000010
    sts EIFR, r16

    ;-------------------------------------------
    ; Habilitar interrupción INT1
    ; INT1 está en el bit 1 de EIMSK
    ;-------------------------------------------
    ldi r16, 0b00000010
    out EIMSK, r16

    ;-------------------------------------------
    ; Habilitar interrupciones globales
    ;-------------------------------------------
    sei

;***********************************************
MAIN:
    ; El programa queda esperando hasta que se presione Start
    rjmp MAIN

;***********************************************
START:

    ; Apagar inicialmente PORTB
    ldi r16, 0x00
    out PORTB, r16
	ldi r18, 0x00
	out PORTC, r18

    reti