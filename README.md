# Proyecto Final - Arquitectura de Computadores

## Consola de videojuegos simple con ATmega328PB

Este proyecto consiste en programar y simular una consola de videojuegos simple utilizando el microcontrolador **ATmega328PB**. El juego será desarrollado en lenguaje ensamblador mediante **Microchip Studio** y simulado en **SimulIDE**.

El objetivo principal del juego es controlar un vehículo que se desplaza de izquierda a derecha en una matriz LED 8x8, mientras esquiva obstáculos que descienden desde la parte superior. Al mismo tiempo, dos displays de 7 segmentos muestran el tiempo transcurrido en segundos, contando desde `00` hasta `99`.

---

## Descripción del juego

Al presionar el botón **Start**, el sistema inicia el juego:

- Los displays de 7 segmentos muestran `00`.
- La matriz LED 8x8 muestra el vehículo en la posición inicial, ubicada en el centro.
- El contador de segundos comienza a avanzar.
- Los obstáculos empiezan a descender por la matriz LED.
- El jugador puede mover el vehículo hacia la izquierda o hacia la derecha mediante botones.
- Si un obstáculo choca con el vehículo, el juego se detiene.
- Al presionar nuevamente **Start**, el juego se reinicia.

---

## Microcontrolador utilizado

- **ATmega328PB**

---

## Software utilizado

- **Microchip Studio**  
  Para la programación en lenguaje ensamblador y generación de archivos `.asm` y `.hex`.

- **SimulIDE**  
  Para la simulación del circuito y funcionamiento del videojuego mediante el archivo `.sim1`.

---

## Funcionamiento general

El juego se organiza en cinco etapas de implementación. Cada etapa debe funcionar correctamente antes de continuar con la siguiente, ya que la evaluación depende del avance progresivo del proyecto.

---

# Etapas de implementación

## Primera etapa: Inicio del sistema

### Objetivo

Configurar el inicio del juego mediante el botón **Start**.

### Requisitos

- Los dos displays de 7 segmentos deben mostrar el valor `00` cuando se presione el botón **Start**.
- La matriz LED 8x8 debe mostrar el vehículo en el centro cuando se presione el botón **Start**.

### Valor

- Displays en `00`: **0.5**
- Vehículo en el centro: **0.5**

### Resultado esperado

Al presionar **Start**, el sistema debe reiniciar el contador y ubicar el vehículo en la posición inicial.

---

## Segunda etapa: Contador de segundos

### Objetivo

Implementar el conteo del tiempo usando los dos displays de 7 segmentos.

### Requisitos

- Los displays deben comenzar a contar los segundos de uno en uno al presionar el botón **Start**.
- El conteo debe iniciar en `00` y avanzar hasta `99`.
- Cuando el contador llegue a `99`, debe reiniciarse automáticamente a `00` y continuar contando.

### Valor

- Conteo de `00` a `99`: **0.5**
- Reciclado de `99` a `00`: **0.5**

### Resultado esperado

El contador debe mostrar el tiempo de juego en segundos y reiniciarse automáticamente después de llegar a `99`.

---

## Tercera etapa: Movimiento del vehículo

### Objetivo

Permitir el desplazamiento horizontal del vehículo en la matriz LED 8x8.

### Requisitos

- Al presionar el botón de la derecha, el vehículo debe desplazarse hacia la derecha.
- Al presionar el botón de la izquierda, el vehículo debe desplazarse hacia la izquierda.
- Si el vehículo llega al borde izquierdo, no debe seguir avanzando hacia la izquierda.
- Si el vehículo llega al borde derecho, no debe seguir avanzando hacia la derecha.
- El movimiento debe respetar estrictamente el patrón asignado por el docente a partir de esta etapa.

### Valor

- Movimiento correcto del vehículo: **1.0**

### Resultado esperado

El jugador puede controlar el vehículo lateralmente sin salirse de los límites de la matriz LED 8x8.

---

## Cuarta etapa: Obstáculos y colisiones

### Objetivo

Agregar obstáculos descendentes y detectar colisiones con el vehículo.

### Requisitos

- La matriz LED 8x8 debe mostrar obstáculos descendiendo desde la parte superior.
- Los obstáculos deben bajar a una velocidad jugable después de presionar **Start**.
- Si un obstáculo choca con el vehículo, el juego debe detenerse.
- Cuando el juego se detiene, también deben detenerse los displays de 7 segmentos.
- Al presionar nuevamente **Start**, el juego debe reiniciarse a la posición original, como en la primera etapa.

### Valor

- Obstáculos descendentes: **0.5**
- Detección de choque y pausa del juego: **0.5**
- Reinicio con botón Start: **0.5**

### Resultado esperado

El juego debe permitir esquivar obstáculos. Si ocurre una colisión, el sistema debe detenerse y esperar un nuevo inicio.

---

## Quinta etapa: Sonidos del juego

### Objetivo

Implementar sonidos diferentes para las acciones principales del juego.

### Requisitos

Cada sonido debe ser diferente y debe activarse en los siguientes casos:

- Cuando se presiona una tecla para mover el vehículo.
- Cuando los obstáculos son superados y llegan al borde inferior.
- Cuando un obstáculo choca con el vehículo.
- Cuando el juego inicia o se reinicia.

### Valor

- Implementación de sonidos: **0.5**

### Resultado esperado

El juego debe incluir retroalimentación sonora para mejorar la experiencia del usuario.

---

# Archivos requeridos

Para la entrega final se deben adjuntar los siguientes archivos:

```text
/Etapa_1/
├── etapa_1.asm
├── etapa_1.hex
├── etapa_1.sim1

/Etapa_2/
├── etapa_2.asm
├── etapa_2.hex
├── etapa_2.sim1

/Etapa_3/
├── etapa_3.asm
├── etapa_3.hex
├── etapa_3.sim1

/Etapa_4/
├── etapa_4.asm
├── etapa_4.hex
├── etapa_4.sim1

/Etapa_5/
├── etapa_5.asm
├── etapa_5.hex
├── etapa_5.sim1

/Diagrama_Flujo/
├── diagrama_flujo.png
