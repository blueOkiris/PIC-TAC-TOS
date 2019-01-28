    #include "p16f887.inc"
    
    ; CONFIG1
    ; __config 0xE0F6
    __CONFIG _CONFIG1, _FOSC_HS & _WDTE_OFF & _PWRTE_OFF & _MCLRE_ON & _CP_OFF & _CPD_OFF & _BOREN_OFF & _IESO_OFF & _FCMEN_OFF & _LVP_OFF
    ; CONFIG2
    ; __config 0xFEFF
    __CONFIG _CONFIG2, _BOR4V_BOR21V & _WRT_OFF
    
    radix   dec
    
    ; Defines here:
    
    udata   0x020                       ; Banksel bank 0 (bank of portd)
    
    ; Registers here:
state       res     1

RES_VECT    CODE    0x0000
    goto    start
    
INT_VECT    CODE    0x0004
    goto    isr
    
MAIN_PROG   CODE    0x0005
start
    call    init_tmr0
    goto    $
    
; Decscription
; Handel timer 0 updates
; Total time = (call + return) + isr_code + tmr0_delay + stop_cycles
; Total time 4 us = (0.5 + 0.5) + 2.25 + 0.25 + 0.5
; Total time 8 us = (0.5 + 0.5) + 3 + 3.5 + 0
; Total time 52 us = (0.5 + 0.5) + 3.5 + 48.75 - 1.25
isr
    bcf     INTCON, GIE                 ; 0.25 us
    
    btfss   state, 0                    ; 0.75 us or 0.5 -> Check if sync state
    goto    isr_black                   ; If here then 1 us
    
    ; Delay 4 us
    rlf     state, f                    ; 1 us
    clrf    PORTD                       ; 1.25
    movlw   255                         ; 1.5 us -> delay for 0.25 us = 256 - 1
    movwf   TMR0                        ; 1.75 us
    bcf     INTCON, T0IF                ; 2 us
    bsf     INTCON, GIE                 ; 2.25 us
    return
    
isr_black
    btfss   state, 1                    ; 1.5 or 1.25 -> Check if black state
    goto    isr_white                   ; If here then 1.75
    
    rlf     state, f                    ; 1.75
    bsf     PORTD, RD0                  ; 2
    movlw   242                         ; 2.25 -> delay for 3.5 us = 256 - 14
    movwf   TMR0                        ; 2.5
    bcf     INTCON, T0IF                ; 2.75 us
    bsf     INTCON, GIE                 ; 3 us
    return
    
isr_white
    movlw   1                           ; 2
    movwf   state                       ; 2.25
    bsf     PORTD, RD1                  ; 2.5
    movlw   61                          ; 2.75 -> delay for 48.75 us = 256 - 195
    movwf   TMR0                        ; 3
    bcf     INTCON, T0IF                ; 3.25 us
    bsf     INTCON, GIE                 ; 3.5 us
    return
    
    
; Description
; Sets up timer 0
init_tmr0
    banksel OSCCON
    bsf     OSCCON, IRCF2               ; Set timer to use 8MHz clock 
    bsf     OSCCON, IRCF1
    bsf     OSCCON, IRCF0
    
    bcf     TRISD, TRISD0               ; Set an output port (RD0 in this case)
    bcf     TRISD, TRISD1
    
    bcf     OPTION_REG, T0CS            ; Use FOSC/4 for Timer 0
    bsf     OPTION_REG, PSA             ; Use WDT prescale so tmr0 is 1:1
    bcf     OPTION_REG, PS2             ; 000 -> 1:2 prescale
    bcf     OPTION_REG, PS1
    bcf     OPTION_REG, PS0
    
    banksel PORTD
    movlw   1
    movwf   state
    bcf     PORTD, RD0
    bsf     INTCON, T0IE                ; Enable Timer0
    bcf     INTCON, T0IF                ; Reset timer 0
    bsf     INTCON, PEIE                ; Enable interrupts
    bsf     INTCON, GIE
    
    return
    
    END