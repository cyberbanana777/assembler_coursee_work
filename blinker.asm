; Определяем микроконтроллер
.include "m328Pdef.inc"

; Настройка настроек
.def temp = r16
.def counter1 = r17
.def counter2 = r18
.def counter3 = r19

; Pinout
.edu red_led = 0    ; First analog pin 
.edu green_led = 1  ; Second analog pin
.edu yellow_led = 2 ; Third analog pin

; setup input|output mode
.edu ANALOG_PINS_CONFIG = 0b00000111
.edu DIGIT_PINS_CONFIG = 0b00000000

; setup pin state voltage
.edu PIN_STATE_OUTPUT 0b00000000 
; setup pin mode (None|Input_pull_up)
.edu PIN_MODE_INPUT 0b00001100

; Начало программы (точка входа)
.cseg
.org 0x0000 ; Указываем, что код начинается с начала памяти программ

    ; Настройка стека (очень важно для работы подпрограмм!)
    ldi temp, low(RAMEND) ; Младший байт конца RAM
    out SPL, temp         ; в указатель стека SPL
    ldi temp, high(RAMEND); Старший байт конца RAM
    out SPH, temp         ; в указатель стека SPH

    out DDRC, ANALOG_PINS_CONFIG  ; setup analog pins
    out PORTC, PIN_STATE_OUTPUT   ; set voltage in output pins

    out DDRD, DIGIT_PINS_CONFIG   ; setup digital (0-7) pins
    out PORTD, PIN_MODE_INPUT     ; enable input_pull_up for input pins


; Главный бесконечный цикл
main_loop:
   sbi PORTB, 5           ; Включаем светодиод
   rcall delay_1s         ; Вызываем задержку 1 секунда

   cbi PORTB, 5           ; Выключаем светодиод
   rcall delay_1s         ; Вызываем задержку 1 секунда
   rjmp main_loop         ; Бесконечный цикл


; Подпрограмма задержки ~1 секунда при 16 МГц
delay_1s:
    ldi  counter1, 130    ; 1 такт
    ldi  counter2, 222    ; 1 такт
    ldi  counter3, 224    ; 1 такт
delay_loop:
    dec  counter3         ; 1 такт
    brne delay_loop       ; 2 такта (1 при последней итерации)
    dec  counter2         ; 1 такт
    brne delay_loop       ; 2 такта (1 при последней итерации)
    dec  counter1         ; 1 такт
    brne delay_loop       ; 2 такта (1 при последней итерации)
    ret                   ; 4 такта
