; Определяем микроконтроллер
.include "m328Pdef.inc"

; Настройка настроек
.def temp = r16
.def counter1 = r17
.def counter2 = r18
.def counter3 = r19

.def red_led_state = r20
.def green_led_state = r21
.def blue_led_state = r22
.def state = r23

; Начало программы
.cseg
.org 0x0000

    ; Настройка стека
    ldi temp, low(RAMEND)
    out SPL, temp
    ldi temp, high(RAMEND)
    out SPH, temp

    ; Настройка пинов D5 и D6 как выходов
    ldi temp, 0b01100000  ; D6 и D5 как выходы, остальные как входы
    out DDRD, temp

    ; Настройка пина D9 как выхода
    ldi temp, 0b00000010  ; D9 как выход
    out DDRB, temp

    ; Настройка ТАЙМЕРА0
    ldi temp, (1<<COM0A1)|(1<<COM0B1)|(1<<WGM01)|(1<<WGM00)
    out TCCR0A, temp
    ldi temp, (1<<CS01)|(1<<CS00)
    out TCCR0B, temp

    ; Настройка ТАЙМЕРА1
    ldi temp, (1<<COM1A1)|(1<<WGM10)
    sts TCCR1A, temp
    ldi temp, (1<<WGM12)|(1<<CS11)|(1<<CS10)
    sts TCCR1B, temp

    ; init state
    ldi state, 0

    ; Инициализация всех каналов
    ldi red_led_state, 0
    ldi green_led_state, 0
    ldi blue_led_state, 0
    rcall update_leds

    rcall delay_1s
    rcall delay_1s
 
    rjmp main_loop

; Главный бесконечный цикл
main_loop:
    sbi PORTB, 5           ; Включаем светодиод на D13
    ldi red_led_state, 0   ; Красный выключен
    ldi green_led_state, 255 ; Зеленый выключен
    ldi blue_led_state, 0  ; Синий выключен
    rcall update_leds
    rcall delay_1s

    cbi PORTB, 5           ; Выключаем светодиод на D13
    ldi red_led_state, 128   ; Красный на половину
    ldi green_led_state, 0   ; Зеленый выключен
    ldi blue_led_state, 200    ; Синий выключен
    rcall update_leds
    rcall delay_1s

    rjmp main_loop


; Обновление светодиодов
update_leds:
    out OCR0B, green_led_state  ; D5 = Зеленый
    out OCR0A, red_led_state    ; D6 = Красный
    sts OCR1AL, blue_led_state  ; D9 = Синий
    ret

; Подпрограмма задержки ~1 секунда
delay_1s:
    ldi counter1, 130
    ldi counter2, 222
    ldi counter3, 224
delay_loop:
    dec counter3
    brne delay_loop
    dec counter2
    brne delay_loop
    dec counter1
    brne delay_loop
    ret