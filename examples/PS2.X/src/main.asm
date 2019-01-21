; Author: Dylan Turner
; Filename: main.asm
; Description: 
; Test file for testing ps/2 keyboard input on the PIC
    
    list    p=16F887
    #include "p16f887.inc"
    ; PIC16F887 Configuration Bit Settings
    ; CONFIG1
    ; __config 0x20F5
     __CONFIG _CONFIG1, _FOSC_INTRC_CLKOUT & _WDTE_OFF & _PWRTE_OFF & _MCLRE_ON & _CP_OFF & _CPD_OFF & _BOREN_OFF & _IESO_OFF & _FCMEN_OFF & _LVP_OFF
    ; CONFIG2
    ; __config 0x3EFF
     __CONFIG _CONFIG2, _BOR4V_BOR21V & _WRT_OFF
    
    radix   dec
   
BUFF_SIZE   equ     40
   
    udata   0x20                        ; Register file locations for system variables
    
key_storage res     BUFF_SIZE           ; Buffer to store inputted keys
key_index   res     1

RES_VECT    CODE    0x0000              ; Processor reset vector
    goto    start
    
INT_VECT    CODE    0x0004              ; interrupt vector
    bcf     INTCON, GIE                 ; Disable interrupts
    call    keyboard_handler            ; Read in keyboard data
    bsf     INTCON, GIE                 ; Re-enable interrupts
    
MAIN_PROG   CODE
start
    call    setup
    goto $

; Description:
; Initialize which ever two pins on whatever port you want in oreder to be read from the clock
setup
    ; Initialize port b as interrupt and read data
    banksel TRISB
    bsf     TRISB, RB0                  ; Set data and clock as inputs (RB0 & RB1)
    bsf     TRISB, RB1
    banksel ANSELH
    clrf    ANSELH                      ; Digital not analog
    banksel OPTION_REG
    bcf     OPTION_REG, NOT_RBPU        ; Set up internal pullups
    banksel WPUB
    bsf     WPUB, WPUB0
    bsf     WPUB, WPUB1
    banksel IOCB
    bsf     IOCB, IOCB1                 ; Set change of state interrupt to CLOCK pin (RB1)

    ; Enable interrupts
    banksel INTCON
    bsf     INTCON, GIE                 ; Enable global interrupts
    bsf     INTCON, RBIE                ; Enable RBIE
    bcf     INTCON, RBIF                ; Clear RBIF
    
    banksel PORTB

    return

; Description:
; Triggering on keyboard clock down, this takes in data from a PS/2 keyboard
keyboard_handler
    btfss   INTCON, RBIF                ; If interrupt is not port b then return
    return
    bcf     INTCON, RBIF                ; Reset interrupt
    btfsc   PORTB, RB1                  ; Skip if rising edge and return
    return

    ; Read ll bits from keyboard
    movf    key_index, w
    sublw   BUFF_SIZE
    btfsc   STATUS, Z                   ; If index is at 40
    clrf    key_index                   ; then clear it
    
    movlw   key_storage                 ; Move the fsr to point to current place in buffer
    movwf   FSR
    movf    key_index, w
    addwf   FSR, f
   
wait_for_data0_high
    btfss   PORTB, RB1
    goto    wait_for_data0_high
wait_for_data0_low
    btfsc   PORTB, RB1
    goto wait_for_data0_low
    btfss   PORTB, RB0                  ; Read 1st data bit; if 0 then set address to 0
    bcf     INDF, 0                     ; NOTE: LSB 1st
    btfsc   PORTB, RB0
    bsf     INDF, 0
   
wait_for_data1_high
    btfss   PORTB, RB1
    goto    wait_for_data1_high
wait_for_data1_low
    btfsc   PORTB, RB1
    goto    wait_for_data1_low
    btfss   PORTB, RB0                  ; Read 1st data bit; if 0 then set address to 0
    bcf     INDF, 1  ; NOTE: LSB 1st
    btfsc   PORTB, RB0
    bsf     INDF, 1
   
wait_for_data2_high
    btfss   PORTB, RB1
    goto    wait_for_data2_high
wait_for_data2_low
    btfsc   PORTB, RB1
    goto    wait_for_data2_low
    btfss   PORTB, RB0                  ; Read 1st data bit; if 0 then set address to 0
    bcf     INDF, 2  ; NOTE: LSB 1st
    btfsc   PORTB, RB0
    bsf     INDF, 2
   
wait_for_data3_high
    btfss   PORTB, RB1
    goto    wait_for_data3_high
wait_for_data3_low
    btfsc   PORTB, RB1
    goto wait_for_data3_low
    btfss   PORTB, RB0                  ; Read 1st data bit; if 0 then set address to 0
    bcf     INDF, 3  ; NOTE: LSB 1st
    btfsc   PORTB, RB0
    bsf     INDF, 3
   
wait_for_data4_high
    btfss   PORTB, RB1
    goto    wait_for_data4_high
wait_for_data4_low
    btfsc   PORTB, RB1
    goto    wait_for_data4_low
    btfss   PORTB, RB0                  ; Read 1st data bit; if 0 then set address to 0
    bcf     INDF, 4  ; NOTE: LSB 1st
    btfsc   PORTB, RB0
    bsf     INDF, 4
   
wait_for_data5_high
    btfss   PORTB, RB1
    goto    wait_for_data5_high
wait_for_data5_low
    btfsc   PORTB, RB1
    goto    wait_for_data5_low
    btfss   PORTB, RB0                  ; Read 1st data bit; if 0 then set address to 0
    bcf     INDF, 5  ; NOTE: LSB 1st
    btfsc   PORTB, RB0
    bsf     INDF, 5
   
wait_for_data6_high
    btfss   PORTB, RB1
    goto    wait_for_data6_high
wait_for_data6_low
    btfsc   PORTB, RB1
    goto    wait_for_data6_low
    btfss   PORTB, RB0                  ; Read 1st data bit; if 0 then set address to 0
    bcf     INDF, 6  ; NOTE: LSB 1st
    btfsc   PORTB, RB0
    bsf     INDF, 6
   
wait_for_data7_high
    btfss    PORTB, RB1
    goto    wait_for_data7_high
wait_for_data7_low
    btfsc   PORTB, RB1
    goto    wait_for_data7_low
    btfss   PORTB, RB0                  ; Read 1st data bit; if 0 then set address to 0
    bcf     INDF, 7  ; NOTE: LSB 1st
    btfsc   PORTB, RB0
    bsf     INDF, 7
   
wait_for_parity_high
    btfss   PORTB, RB1
    goto    wait_for_parity_high
wait_for_parity_low
    btfsc   PORTB, RB1
    goto    wait_for_parity_low
    
wait_for_stop_high
    btfss   PORTB, RB1
    goto    wait_for_stop_high
wait_for_stop_low
    btfsc   PORTB, RB1
    goto    wait_for_stop_low
    
    incf    key_index                   ; Update the key_index to keep loading
    
    return
    end
   
   
   