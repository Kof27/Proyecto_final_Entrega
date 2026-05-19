;
; Etapa_4Assembly.asm
;
; Botón Start en PD3 usando interrupción INT1
; Matriz 8x8 usando dos decodificadores 4:10
; Timer0: multiplexado de matriz
; Timer1: contador de segundos y descenso de obstáculos
;

.include "m328PBdef.inc"

;***********************************************
; Variables en memoria RAM
;***********************************************
.dseg
juego_activo:  .byte 1
pixel_actual:  .byte 1
unidades:      .byte 1
decenas:       .byte 1
pos_carro:     .byte 1
boton_lock:    .byte 1
obstaculo1_y:  .byte 1
obstaculo2_y:  .byte 1

;***********************************************
; Segmento de código
;***********************************************
.cseg

.org 0x0000
    rjmp RESET               ; Vector de reset

.org 0x0004
    rjmp START               ; Vector de interrupción externa INT1

.org 0x0016
    rjmp ISR_TIMER1_COMPA    ; Vector Timer/Counter1 Compare Match A

.org 0x001C
    rjmp ISR_TIMER0_COMPA    ; Vector Timer0 Compare Match A

.org 0x0040                  ; Evita solapamiento con vectores

;***********************************************
RESET:

    ;-------------------------------------------
    ; Inicializar Stack Pointer
    ; Necesario para rcall, ret e interrupciones
    ;-------------------------------------------
    ldi r16, HIGH(RAMEND)
    out SPH, r16

    ldi r16, LOW(RAMEND)
    out SPL, r16

    ;-------------------------------------------
    ; PORTB para displays BCDTo7S
    ; PB0-PB3 = decenas
    ; PB4-PB7 = unidades
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
    ;
    ; PC1 se mantiene en 1 hasta Start
    ;-------------------------------------------
    ldi r18, 0b01111110
    out DDRC, r18

    ;-------------------------------------------
    ; Configurar PORTD
    ;
    ; PD0 -> S2 filas
    ; PD1 -> S1 filas
    ; PD2 -> S0 filas
    ; PD3 -> Start / INT1
    ; PD4 -> botón derecha
    ;-------------------------------------------
    ldi r18, 0b00000111
    out DDRD, r18

    cbi DDRD, 3             ; PD3 como entrada
    cbi DDRD, 4             ; PD4 como entrada

    cbi PORTD, 3            ; Sin pull-up interna
    cbi PORTD, 4            ; Sin pull-up interna

    ;-------------------------------------------
    ; PE0 = botón izquierda
    ;-------------------------------------------
    cbi DDRE, 0             ; PE0 como entrada
    cbi PORTE, 0            ; Sin pull-up interna

    ;-------------------------------------------
    ; Apagar matriz inicialmente
    ; PC6 = 1 y PC1 = 1
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
    sts pixel_actual, r16
    sts unidades, r16
    sts decenas, r16

    ; Posición inicial del carro en el centro
    ldi r16, 3
    sts pos_carro, r16

    ; Botones desbloqueados
    ldi r16, 0
    sts boton_lock, r16

    ; Obstáculo 1 inicia arriba
    ldi r16, 0
    sts obstaculo1_y, r16

    ; Obstáculo 2 inicia más abajo para que no aparezcan juntos
    ldi r16, 4
    sts obstaculo2_y, r16

    ;-------------------------------------------
    ; Configurar INT1 por flanco de subida
    ; Sin pull-up:
    ; sin presionar = 0
    ; presionado    = 1
    ;-------------------------------------------
    ldi r16, 0b00001100
    sts EICRA, r16

    ; Limpiar bandera INT1
    ldi r16, 0b00000010
    sts EIFR, r16

    ; Habilitar INT1
    ldi r16, 0b00000010
    out EIMSK, r16

    ;-------------------------------------------
    ; Configurar Timer0 en modo CTC
    ; Timer0 refresca la matriz LED
    ;-------------------------------------------
    ldi r16, 0b00000010
    out TCCR0A, r16

    ldi r16, 250
    out OCR0A, r16

    ldi r16, 0b00000010
    sts TIMSK0, r16

    ; Prescaler 64
    ldi r16, 0b00000011
    out TCCR0B, r16

    ;-------------------------------------------
    ; Configurar Timer1 en modo CTC
    ; Timer1 cuenta segundos reales
    ;
    ; Para 16 MHz con prescaler 1024:
    ; 16.000.000 / 1024 = 15625 cuentas por segundo
    ; Como cuenta desde 0, usamos OCR1A = 15624
    ;-------------------------------------------
    ldi r16, HIGH(15624)
    sts OCR1AH, r16

    ldi r16, LOW(15624)
    sts OCR1AL, r16

    ; WGM12 = 1, CS12 = 1, CS10 = 1
    ; Modo CTC + prescaler 1024
    ldi r16, 0b00001101
    sts TCCR1B, r16

    ; OCIE1A = 1
    ldi r16, 0b00000010
    sts TIMSK1, r16

    ;-------------------------------------------
    ; Habilitar interrupciones globales
    ;-------------------------------------------
    sei

;***********************************************
MAIN:
    rjmp MAIN

;***********************************************
; START
; Se ejecuta cuando PD3 recibe flanco de subida
;***********************************************
START:

    ; PC1 pasa a 0 cuando inicia el juego
    cbi PORTC, 1

    ; Reiniciar Timer1
    ldi r16, 0x00
    sts TCNT1H, r16
    sts TCNT1L, r16

    ; Limpiar bandera de comparación de Timer1
    ldi r16, 0b00000010
    sts TIFR1, r16

    ; Activar juego
    ldi r16, 0x01
    sts juego_activo, r16

    ; Iniciar desde el primer pixel
    ldi r16, 0x00
    sts pixel_actual, r16

    ; Reiniciar contador a 00
    ldi r16, 0x00
    sts unidades, r16
    sts decenas, r16

    ; Vehículo al centro
    ldi r16, 3
    sts pos_carro, r16

    ; Desbloquear botones
    ldi r16, 0
    sts boton_lock, r16

    ; Reiniciar obstáculos
    ldi r16, 0
    sts obstaculo1_y, r16

    ldi r16, 4
    sts obstaculo2_y, r16

    ; Mostrar 00 en displays
    rcall MOSTRAR_DISPLAY

    reti

;***********************************************
; ISR_TIMER0_COMPA
; Refresca matriz y lee botones
;***********************************************
ISR_TIMER0_COMPA:

    ; Verificar si el juego está activo
    lds r16, juego_activo
    cpi r16, 0x01
    breq CONTINUAR_TIMER0

    rjmp APAGAR_MATRIZ

CONTINUAR_TIMER0:

    rcall LEER_BOTONES

    ; Leer cuál pixel toca mostrar
    lds r16, pixel_actual

    cpi r16, 0
    breq SALTAR_PIXEL_0

    cpi r16, 1
    breq SALTAR_PIXEL_1

    cpi r16, 2
    breq SALTAR_PIXEL_2

    cpi r16, 3
    breq SALTAR_OBS1_0

    cpi r16, 4
    breq SALTAR_OBS1_1

    cpi r16, 5
    breq SALTAR_OBS1_2

    cpi r16, 6
    breq SALTAR_OBS2_0

    cpi r16, 7
    breq SALTAR_OBS2_1

    cpi r16, 8
    breq SALTAR_OBS2_2

    cpi r16, 9
    breq SALTAR_OBS2_3

    rjmp REINICIAR_PIXEL

; Saltos intermedios para evitar Relative branch out of reach

SALTAR_PIXEL_0:
    rjmp MOSTRAR_PIXEL_0

SALTAR_PIXEL_1:
    rjmp MOSTRAR_PIXEL_1

SALTAR_PIXEL_2:
    rjmp MOSTRAR_PIXEL_2

SALTAR_OBS1_0:
    rjmp MOSTRAR_OBS1_0

SALTAR_OBS1_1:
    rjmp MOSTRAR_OBS1_1

SALTAR_OBS1_2:
    rjmp MOSTRAR_OBS1_2

SALTAR_OBS2_0:
    rjmp MOSTRAR_OBS2_0

SALTAR_OBS2_1:
    rjmp MOSTRAR_OBS2_1

SALTAR_OBS2_2:
    rjmp MOSTRAR_OBS2_2

SALTAR_OBS2_3:
    rjmp MOSTRAR_OBS2_3

;***********************************************
; ISR_TIMER1_COMPA
; Cada segundo actualiza contador y baja obstáculos
;***********************************************
ISR_TIMER1_COMPA:

    ; Verificar si el juego está activo
    lds r16, juego_activo
    cpi r16, 0x01
    breq CONTINUAR_TIMER1

    rjmp FIN_TIMER1

CONTINUAR_TIMER1:

    rcall ACTUALIZAR_CONTADOR
    rcall MOVER_OBSTACULOS

FIN_TIMER1:
    reti

;***********************************************
; Pixel 0 del vehículo
; Fila 6, columna pos_carro + 1
;***********************************************
MOSTRAR_PIXEL_0:

    lds r20, pos_carro
    inc r20

    ldi r21, 6
    rcall MOSTRAR_LED

    rjmp AVANZAR_PIXEL

;***********************************************
; Pixel 1 del vehículo
; Fila 7, columna pos_carro
;***********************************************
MOSTRAR_PIXEL_1:

    lds r20, pos_carro

    ldi r21, 7
    rcall MOSTRAR_LED

    rjmp AVANZAR_PIXEL

;***********************************************
; Pixel 2 del vehículo
; Fila 7, columna pos_carro + 2
;***********************************************
MOSTRAR_PIXEL_2:

    lds r20, pos_carro
    inc r20
    inc r20

    ldi r21, 7
    rcall MOSTRAR_LED

    rjmp AVANZAR_PIXEL

;***********************************************
; Obstáculo 1: barra horizontal de 3 píxeles
; Columnas 2, 3 y 4
; Fila = obstaculo1_y
;***********************************************
MOSTRAR_OBS1_0:

    ldi r20, 2
    lds r21, obstaculo1_y
    rcall MOSTRAR_LED

    rjmp AVANZAR_PIXEL

MOSTRAR_OBS1_1:

    ldi r20, 3
    lds r21, obstaculo1_y
    rcall MOSTRAR_LED

    rjmp AVANZAR_PIXEL

MOSTRAR_OBS1_2:

    ldi r20, 4
    lds r21, obstaculo1_y
    rcall MOSTRAR_LED

    rjmp AVANZAR_PIXEL

;***********************************************
; Obstáculo 2: barra horizontal de 4 píxeles
; Columnas 3, 4, 5 y 6
; Fila = obstaculo2_y
;***********************************************
MOSTRAR_OBS2_0:

    ldi r20, 3
    lds r21, obstaculo2_y
    rcall MOSTRAR_LED

    rjmp AVANZAR_PIXEL

MOSTRAR_OBS2_1:

    ldi r20, 4
    lds r21, obstaculo2_y
    rcall MOSTRAR_LED

    rjmp AVANZAR_PIXEL

MOSTRAR_OBS2_2:

    ldi r20, 5
    lds r21, obstaculo2_y
    rcall MOSTRAR_LED

    rjmp AVANZAR_PIXEL

MOSTRAR_OBS2_3:

    ldi r20, 6
    lds r21, obstaculo2_y
    rcall MOSTRAR_LED

    rjmp AVANZAR_PIXEL

;***********************************************
; Avanzar pixel del multiplexado
; Hay 10 píxeles:
; 3 vehículo + 3 obstáculo1 + 4 obstáculo2
;***********************************************
AVANZAR_PIXEL:

    lds r16, pixel_actual
    inc r16

    cpi r16, 10
    brlo GUARDAR_PIXEL

REINICIAR_PIXEL:
    ldi r16, 0

GUARDAR_PIXEL:
    sts pixel_actual, r16
    rjmp FIN_TIMER0

;***********************************************
APAGAR_MATRIZ:

    ; PC6 = 1 para fila 8 apagada
    ; PC1 = 1 mientras no se presiona Start
    ldi r18, 0b01000010
    out PORTC, r18

    ldi r18, 0b00000000
    out PORTD, r18

    rjmp FIN_TIMER0

;***********************************************
FIN_TIMER0:
    reti

;***********************************************
; ACTUALIZAR_CONTADOR
; 00, 01, 02 ... 99, 00
;***********************************************
ACTUALIZAR_CONTADOR:

    ; Aumentar unidades
    lds r16, unidades
    inc r16

    cpi r16, 10
    brlo GUARDAR_UNIDADES

    ; Si unidades llegó a 10, vuelve a 0
    ldi r16, 0x00
    sts unidades, r16

    ; Aumentar decenas
    lds r17, decenas
    inc r17

    cpi r17, 10
    brlo GUARDAR_DECENAS

    ; Si decenas llegó a 10, vuelve a 0
    ldi r17, 0x00

GUARDAR_DECENAS:
    sts decenas, r17
    rcall MOSTRAR_DISPLAY
    ret

GUARDAR_UNIDADES:
    sts unidades, r16
    rcall MOSTRAR_DISPLAY
    ret

;***********************************************
; MOSTRAR_DISPLAY
;
; PB0-PB3 = DECENAS
; PB4-PB7 = UNIDADES
;***********************************************
MOSTRAR_DISPLAY:

    ; Cargar unidades en r17
    lds r17, unidades

    ; Cargar decenas en r16
    lds r16, decenas

    ; Mover unidades a la parte alta del byte
    lsl r17
    lsl r17
    lsl r17
    lsl r17

    ; Unir unidades y decenas
    or r16, r17

    ; Enviar a los BcdTo7S
    out PORTB, r16

    ret

;***********************************************
; LEER_BOTONES
;
; PE0 = izquierda
; PD4 = derecha
;
; Sin pull-up:
; sin presionar = 0
; presionado    = 1
;***********************************************
LEER_BOTONES:

    ; Si los botones están bloqueados,
    ; verificar si ya se soltaron
    lds r16, boton_lock
    cpi r16, 1
    breq VERIFICAR_SOLTAR_BOTONES

    ; Revisar botón izquierda PE0
    sbic PINE, 0
    rjmp BOTON_IZQUIERDA_PRESIONADO

    ; Revisar botón derecha PD4
    sbic PIND, 4
    rjmp BOTON_DERECHA_PRESIONADO

    ret

BOTON_IZQUIERDA_PRESIONADO:

    rcall MOVER_IZQUIERDA

    ldi r16, 1
    sts boton_lock, r16

    ret

BOTON_DERECHA_PRESIONADO:

    rcall MOVER_DERECHA

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

    ; Si ambos están en 0, desbloquear botones
    ldi r16, 0
    sts boton_lock, r16

    ret

;***********************************************
; MOVER_IZQUIERDA
; Límite izquierdo: pos_carro = 0
;***********************************************
MOVER_IZQUIERDA:

    lds r16, pos_carro

    cpi r16, 0
    breq FIN_MOVER_IZQUIERDA

    dec r16
    sts pos_carro, r16

FIN_MOVER_IZQUIERDA:
    ret

;***********************************************
; MOVER_DERECHA
; Límite derecho: pos_carro = 5
;***********************************************
MOVER_DERECHA:

    lds r16, pos_carro

    cpi r16, 5
    breq FIN_MOVER_DERECHA

    inc r16
    sts pos_carro, r16

FIN_MOVER_DERECHA:
    ret

;***********************************************
; MOVER_OBSTACULOS
; Baja cada obstáculo una fila por segundo
;***********************************************
MOVER_OBSTACULOS:

    ;-------------------------------------------
    ; Obstáculo 1
    ;-------------------------------------------
    lds r16, obstaculo1_y
    inc r16

    cpi r16, 8
    brlo GUARDAR_OBSTACULO1

    ldi r16, 0

GUARDAR_OBSTACULO1:
    sts obstaculo1_y, r16

    ;-------------------------------------------
    ; Obstáculo 2
    ;-------------------------------------------
    lds r16, obstaculo2_y
    inc r16

    cpi r16, 8
    brlo GUARDAR_OBSTACULO2

    ldi r16, 0

GUARDAR_OBSTACULO2:
    sts obstaculo2_y, r16

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

    ldi r18, 0b00000000
    out PORTD, r18

    rcall SET_COLUMNA
    rcall SET_FILA

    ret

;***********************************************
; SET_COLUMNA
;
; Entrada:
; r20 = columna
;
; PC2 -> S3
; PC3 -> S2
; PC4 -> S1
; PC5 -> S0
;***********************************************
SET_COLUMNA:

    ; Limpiar PC2, PC3, PC4, PC5
    ; Mantener PC6 y PC1
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
; PC6 -> S3
; PD0 -> S2
; PD1 -> S1
; PD2 -> S0
;***********************************************
SET_FILA:

    ; bit 3 de fila -> PC6
    in r18, PORTC
    andi r18, 0b10111111

    sbrc r21, 3
    ori r18, 0b01000000

    out PORTC, r18

    ; bits 2,1,0 de fila -> PD0, PD1, PD2
    in r18, PORTD
    andi r18, 0b11111000

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