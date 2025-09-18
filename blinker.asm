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
.def pos_reg = r23      ; Позиция энкодера

; Определение пинов
.equ PIN_A = 2    ; PD2
.equ PIN_B = 3    ; PD3

; Начало программы
.cseg
; Векторы прерываний
.org 0x0000
    jmp reset
.org INT0addr
    jmp ISR_INT0
.org INT1addr
    jmp ISR_INT1


.org 0x100
reset:
    ; Настройка стека
    ldi temp, low(RAMEND)
    out SPL, temp
    ldi temp, high(RAMEND)
    out SPH, temp

    ; Настройка пинов энкодера как входов с подтяжкой
    cbi DDRD, PIN_A          ; D2 как вход (канал A энкодера)
    cbi PORTD, PIN_A         ; Выключить подтяжку к питанию
    cbi DDRD, PIN_B          ; D3 как вход (канал B энкодера) 
    cbi PORTD, PIN_B         ; Выключить подтяжку к питанию

    ; Настройка прерываний для энкодера (по нисходящему фронту)
    ldi temp, (1<<ISC01)|(0<<ISC00)|(1<<ISC11)|(0<<ISC10)
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
    ldi red_led_state, 0   ; Начальная яркость красного = 50%
    ldi green_led_state, 255   ; Зеленый выключен
    ldi blue_led_state, 50    ; Синий выключен
    ldi pos_reg, 0       ; Начальная позиция энкодера
    
    ; Применить начальные значения
    rcall update_leds

    ; Разрешить глобальные прерывания
    sei

    rjmp main_loop


; Главный бесконечный цикл
main_loop:
    ; Обновляем яркость на основе позиции энкодера
    mov red_led_state, pos_reg
    mov blue_led_state, pos_reg

    ldi temp, 255
    sub temp, pos_reg
    mov green_led_state, temp 
    
    rcall update_leds

    ; Мигаем светодиодом на D13 для индикации работы
    sbi PORTB, 5
    rcall delay_100ms
    cbi PORTB, 5
    rcall delay_100ms
    
    rjmp main_loop


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


; Обработчик прерывания для канала A (PIN_A)
ISR_INT0:
    push temp        ; Сохраняем используемые регистры
    push r17
    push r18
    in r18, SREG    ; Сохраняем регистр статуса
    push r18

    ; Чтение состояния пинов
    in r17, PIND
    andi r17, (1<<PIN_A)|(1<<PIN_B)

    ; Проверка состояния канала A
    sbrs r17, PIN_A
    rjmp case_A_0

case_A_1:
    ; Если PIN_A = 1
    sbrc r17, PIN_B
    rjmp dec_pos    ; Если PIN_B = 1
    rjmp inc_pos    ; Если PIN_B = 0

case_A_0:
    ; Если PIN_A = 0
    sbrc r17, PIN_B
    rjmp inc_pos    ; Если PIN_B = 1
    rjmp dec_pos    ; Если PIN_B = 0

inc_pos:
    ; Увеличение позиции
    ldi temp, 8
    add pos_reg, temp
    rjmp end_int0

dec_pos:
    ; Уменьшение позиции
    ldi temp, 8
    sub pos_reg, temp

end_int0:
    pop r18         ; Восстанавливаем регистр статуса
    out SREG, r18
    pop r18
    pop r17
    pop temp
    reti

; Обработчик прерывания для канала B (PIN_B)
ISR_INT1:
    push temp       ; Сохраняем используемые регистры
    push r17        
    push r18
    in r18, SREG    ; Сохраняем регистр статуса
    push r18

    ; Чтение состояния пинов
    in r17, PIND
    andi r17, (1<<PIN_A)|(1<<PIN_B)

    ; Проверка состояния канала B
    sbrs r17, PIN_B
    rjmp case_B_0

case_B_1:
    ; Если PIN_B = 1
    sbrc r17, PIN_A
    rjmp inc_pos_B  ; Если PIN_A = 1
    rjmp dec_pos_B  ; Если PIN_A = 0

case_B_0:
    ; Если PIN_B = 0
    sbrc r17, PIN_A
    rjmp dec_pos_B  ; Если PIN_A = 1
    rjmp inc_pos_B  ; Если PIN_A = 0

inc_pos_B:
    ; Увеличение позиции
    ldi temp, 8
    add pos_reg, temp
    rjmp end_int1

dec_pos_B:
    ; Уменьшение позиции
    ldi temp, 8
    sub pos_reg, temp

end_int1:
    pop r18         ; Восстанавливаем регистр статуса
    out SREG, r18
    pop r18
    pop r17
    pop temp
    reti