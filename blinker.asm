; Определяем микроконтроллер
.include "m328Pdef.inc"

; Настройка настроек
.def temp = r16
.def counter1 = r17
.def counter2 = r18
.def counter3 = r19

.def red_led_state = r20    ; Яркость красного (0-255)
.def green_led_state = r21  ; =0
.def blue_led_state = r22   ; =0
.def encoder_prev = r23     ; Предыдущее состояние энкодера
.def zero = r0              ; Нулевой регистр

; Начало программы
.cseg
.org 0x0000
    rjmp reset              ; Вектор сброса
    rjmp INT0_Handler       ; Вектор INT0 (D2)
    rjmp INT1_Handler       ; Вектор INT1 (D3)
    ; ... остальные векторы ...

.org 0x100
reset:
    ; Настройка стека
    ldi temp, low(RAMEND)
    out SPL, temp
    ldi temp, high(RAMEND)
    out SPH, temp

    ; Инициализация нулевого регистра
    clr zero

    ; Настройка пинов энкодера как входов с подтяжкой
    cbi DDRD, PD2          ; D2 как вход (канал A энкодера)
    sbi PORTD, PD2         ; Подтяжка к питанию
    cbi DDRD, PD3          ; D3 как вход (канал B энкодера) 
    sbi PORTD, PD3         ; Подтяжка к питанию

    ; Настройка прерываний для энкодера
    ldi temp, (1<<ISC01)|(1<<ISC00)|(1<<ISC11)|(1<<ISC10) ; По любому изменению
    sts EICRA, temp
    ldi temp, (1<<INT0)|(1<<INT1) ; Разрешить INT0 и INT1
    out EIMSK, temp

    ; Настройка пинов D5 и D6 как выходов
    ldi temp, 0b01100000   ; D6 и D5 как выходы
    out DDRD, temp

    ; Настройка пина D9 как выхода
    ldi temp, 0b00000010   ; D9 как выход
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

    ; Инициализация переменных
    ldi red_led_state, 128   ; Начальная яркость красного = 50%
    ldi green_led_state, 0   ; Зеленый выключен
    ldi blue_led_state, 0    ; Синий выключен
    ldi encoder_prev, 0
    
    ; Прочитать начальное состояние энкодера
    in temp, PIND
    andi temp, (1<<PIND2)|(1<<PIND3)  ; Правильная маска!
    mov encoder_prev, temp

    ; Применить начальные значения
    rcall update_leds

    ; Разрешить глобальные прерывания
    sei

    rjmp main_loop

; Главный бесконечный цикл
main_loop:
    ; Мигаем светодиодом на D13 для индикации работы
    sbi PORTB, 5
    rcall delay_100ms
    cbi PORTB, 5
    rcall delay_100ms
    
    rjmp main_loop

; Обработчик прерывания INT0 (D2 - канал A)
INT0_Handler:
    push temp
    in temp, SREG
    push temp
    
    rcall handle_encoder  ; Обработать изменение энкодера
    
    pop temp
    out SREG, temp
    pop temp
    reti

; Обработчик прерывания INT1 (D3 - канал B)  
INT1_Handler:
    push temp
    in temp, SREG
    push temp
    
    rcall handle_encoder  ; Обработать изменение энкодера
    
    pop temp
    out SREG, temp
    pop temp
    reti

; Обработка изменения энкодера
; Обработка изменения энкодера (упрощенная версия)
handle_encoder:
    push temp
    push r1
    
    ; Прочитать текущее состояние энкодера
    in temp, PIND
    andi temp, (1<<PIND2)|(1<<PIND3)
    
    ; Сравнить с предыдущим состоянием
    cp temp, encoder_prev
    breq end_encoder_handler  ; Если не изменилось - выйти
    
    ; Проверить последовательность состояний для определения направления
    ; Энкодер: 00 → 10 → 11 → 01 → 00 (вперед)
    ;          00 → 01 → 11 → 10 → 00 (назад)
    
    cpi encoder_prev, 0b00000000
    breq check_from_00
    cpi encoder_prev, 0b00000100  ; PD2
    breq check_from_10
    cpi encoder_prev, 0b00001100  ; PD2+PD3
    breq check_from_11
    cpi encoder_prev, 0b00001000  ; PD3
    breq check_from_01
    
    rjmp end_encoder_handler

check_from_00:
    cpi temp, 0b00000100  ; 00 → 10 = вперед
    breq encoder_inc
    cpi temp, 0b00001000  ; 00 → 01 = назад
    breq encoder_dec
    rjmp end_encoder_handler

check_from_10:
    cpi temp, 0b00001100  ; 10 → 11 = вперед
    breq encoder_inc
    cpi temp, 0b00000000  ; 10 → 00 = назад
    breq encoder_dec
    rjmp end_encoder_handler

check_from_11:
    cpi temp, 0b00001000  ; 11 → 01 = вперед
    breq encoder_inc
    cpi temp, 0b00000100  ; 11 → 10 = назад
    breq encoder_dec
    rjmp end_encoder_handler

check_from_01:
    cpi temp, 0b00000000  ; 01 → 00 = впеard
    breq encoder_inc
    cpi temp, 0b00001100  ; 01 → 11 = назад
    breq encoder_dec
    rjmp end_encoder_handler

encoder_inc:
    inc red_led_state      ; Увеличить яркость красного
    sbi PORTB, 5          ; Мигнуть D13
    cbi PORTB, 5
    rjmp update_brightness

encoder_dec:
    dec red_led_state      ; Уменьшить яркость красного
    sbi PORTB, 5          ; Мигнуть D13
    cbi PORTB, 5

update_brightness:
    rcall update_leds      ; Немедленно обновить светодиоды

end_encoder_handler:
    mov encoder_prev, temp ; Сохранить текущее состояние
    pop r1
    pop temp
    ret
 

; Обновление светодиодов
update_leds:
    out OCR0B, green_led_state  ; D5 = Зеленый (всегда 0)
    out OCR0A, red_led_state    ; D6 = Красный (0-255)
    sts OCR1AL, blue_led_state  ; D9 = Синий (всегда 0)
    ret

; Подпрограмма задержки ~100ms
delay_100ms:
    push counter1
    push counter2
    push counter3
    
    ldi counter1, 13
    ldi counter2, 45
    ldi counter3, 215
delay_loop:
    dec counter3
    brne delay_loop
    dec counter2
    brne delay_loop
    dec counter1
    brne delay_loop
    
    pop counter3
    pop counter2
    pop counter1
    ret