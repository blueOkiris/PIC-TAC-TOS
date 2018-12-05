; Author: Dylan Turner
; Filename: main.asm
; Description: The main overarching place for the program including:
;		    * Entry point
;		    * Port initialization
;		    * System variable descriptions

    list    p=16F887
    #include "p16f887.inc"
    
    list	p=16F887
    #include	"p16f887.inc"
    ; PIC16F887 Configuration Bit Settings
    ; CONFIG1
    ; __config 0x20F5
     __CONFIG _CONFIG1, _FOSC_INTRC_CLKOUT & _WDTE_OFF & _PWRTE_OFF & _MCLRE_ON & _CP_OFF & _CPD_OFF & _BOREN_OFF & _IESO_OFF & _FCMEN_OFF & _LVP_OFF
    ; CONFIG2
    ; __config 0x3EFF
     __CONFIG _CONFIG2, _BOR4V_BOR21V & _WRT_OFF
    
    radix   dec
    
KEY_ROW	    equ	    0                   ; Which byte to of key_buff to store row data in
KEY_COL	    equ	    1                   ; Which byte to store row and shift data in
    
    udata   0x20                        ; Register file locations for system variables

key_buff    res	    2
i	    res	    1                       ; small loop var
k	    res	    1                       ; outer loop var
m	    res	    2                       ; loop var for large numbers
n	    res	    2                       ; outer loop var for big numbers
t	    res	    1                       ; Second working directory

RES_VECT    CODE    0x0000              ; Processor reset vector
    goto    start
    
INT_VECT  CODE	    0x0004              ; interrupt vector
    goto    isr                         ; go to interrupt service routine
    
MAIN_PROG   CODE
start
    call    key_init
    call    output_init
    
    goto    sys_loop
    
; Description:
; Interrupt functions etc.
; Update: Dylan - added key_update
isr
    movlw   0x00
    movwf   INTCON                      ; Disable other interrupts
    
    call    key_update
    
    movlw   b'10001000'                 ; Enable keyboard interrupt
    movwf   INTCON
    return                              ; Highly suspicious. May not worlk!
    
; Description:
; This is the main program loop where all other functions are called.
; The program loops forever, reading input, processing, and displaying output
; Essentially, it will call 1 functions, Interpret data, and loop
; Update: Dylan - Created function
sys_loop
    ; Basic setup (will change/TODO)
    ; call interpret
    goto sys_loop
    
; Description:
; Update key data from the builtin matrix keyboard (as opposed to an external one)
; Update: Dylan - Implemented double function
key_update
    ; See if shift is pressed
    btfsc   PORTD, 7                    ; Is the button pressed? (active low)
    bsf	    key_buff + KEY_COL, 7       ; If so, set the column register to store shift @ b7
    
    movlw   0x77                        ; 0b0 1111110
    movwf   k
    call check_each_column
    return
    
; Description:
; Small loop to iterate through each column of the keyboard
; Update: Dylan - Created
check_each_column
    ; Check column 0 for each row
    movf    k                           ; move the mask into k
    movwf   PORTD
    movlw   0                           ; Set i to 1 to start (it will be shifted not incremented)
    movwf   i
    call check_each_row
    
    btfsc   k, 6                        ; return right before you would shift to the 7th bit (bc we don't want to do that!)
    return
    
    rlf	    k                           ; Shift mask (Don't forget to re-add 1 to the end)
    incf
    goto    check_each_column
    
; Description:
; Small loop to iterate through each row in the keyboard given a column from above
; Update: Dylan - Created
check_each_row
    ; Button is active low, so first read in C and flip it to be active high
    movf    PORTC, w
    comf    w                           ; Get 2's complement of w (invert and add 
    incf    w
    
    ; Now check if current w is correct
    andwf   i, w                        ; Will check only current bit
    btfsc   STATUS, Z                   ; Check if pressed (pressed => != 0 => Z = 0)
    call    row_check_set
    btfss   STATUS, Z
    call    row_check_clear
    
    rlf	    i                           ; Shift i to next bit
    btfss   i, 7                        ; When we get to the 8th row, i is 7th bit, stop
    return
    goto    check_each_row
row_check_set
    movf    k, w                        ; Get the current bit mask for Port D
    comf    w                           ; Invert to get something like 0b10010000 instead of 0b01101111
    bsf	    w, 7                        ; Set most significant bit to off so we don't affect it (it's shift remember!)
    iorwf   key_buff + KEY_COL, f       ; Or the current columns with the mask, 0b00010000 for example
    movf    i, w
    iorwf   key_buff + KEY_ROW, f       ; Mask, set the hit bit only
    return
row_check_clear
    movf    k, w                        ; Get the current bit mask for Port D
    bsf	    w, 7                        ; Set most significant bit to on so we don't affect it (it's shift remember!)
    andwf   key_buff + KEY_COL, f       ; And the current columns with the mask, 0b11101111 for example
    movf    i, w
    comf    w
    andwf   key_buff + KEY_ROW, f       ; Mask, clear the hit bit only
    return

; Description:
; This function sets up ports C and D for use with the button matrix keyboard
; C is used for rows, bits 0-7 as input
; D is used for columns, bits 0-7 as output
; D is also for Shift button, bit 8 as input
; B is used as an interrupt on bit 0 as output
; Update: Dylan - Added B interrupt logic
key_init
    ; Set all of C to input and all but bit 7 of D to output
    banksel TRISC
    clrf    TRISC
    movlw   0xFF
    movwf   TRISC
    movwf   TRISB
    clrf    TRISD
    bsf	    TRISD, 7
    
    ; Clear initial output pins (by setting high)
    banksel PORTC
    movlw   0x7F                        ; Don't set last bit! (MSB)
    movwf   PORTD
    clrf    PORTC
    
    ; Setup the keyboard interrupt bit
    movlw   b'10001000'
    movwf   INTCON                      ; Enable B0 interrupt
    
    return

; Description:
; Setup the outputs of the system: the LCD and the External Memory
; This is first 3 bits of Port E where
; bit 0 -> Serial out for LCD (Output)
; bit 1 -> I2C memory Clk (Output)
; bit 3 -> I2C data (In & Out)
; Update: Dylan - Initial creation
output_init
    ; Setup input & output (to start all as output)
    banksel TRISE
    clrf    TRISE
    
    ; Clear to start
    banksel PORTE
    clrf    PORTE
    
    return
    
    end