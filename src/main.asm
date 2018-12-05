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
    
    udata   0x20		    ; Register file locations for system variables
    
KEY_ROW	    equ	    0		    ; Which byte to of key_buff to store row data in
KEY_COL	    equ	    1		    ; Which byte to store row and shift data in
key_buff    res	    2
    
RES_VECT    CODE    0x0000	    ; Processor reset vector
    goto    start
    
INT_VECT  CODE	    0x0004	    ; interrupt vector
    goto    isr			    ; go to interrupt service routine
    
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
    movwf   INTCON		    ; Disable other interrupts
    
    call    key_update
    
    movlw   b'10001000'		    ; Enable keyboard interrupt
    movwf   INTCON
    return			    ; Highly suspicious. May not worlk!
    
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
; Update: Dylan - Created function (only works with column 6 for all buttons)
key_update
    ; See if shift is pressed
    btfsc   PORTD, 7		    ; Is the button pressed? (active low)
    bsf	    key_buff + KEY_COL, 7   ; If so, set the column register to store shift @ b7
    
    ; TODO: This can be made into a double loop (and thus more efficient)
    ; Check column 0 for each row
    movlw   0x6F		    ; b7 is input, turn off b6 with others on
    movwf   PORTD
c_66
    btfsc   PORTC, 6		    ; Test row 6
    goto _66
    goto c_65
_66
    btfsc   key_buff + KEY_COL, 6   ; If col 6 is already on don't set again
    bsf	    key_buff + KEY_COL, 6
    bsf	    key_buff + KEY_ROW, 6
    
c_65
    btfsc   PORTC, 5		    ; Test row 5
    goto _65
    goto c_64
_65
    btfsc   key_buff + KEY_COL, 6   ; If col 6 is already on don't set again
    bsf	    key_buff + KEY_COL, 6
    bsf	    key_buff + KEY_ROW, 5
    
c_64
    btfsc   PORTC, 4		    ; Test row 4
    goto _64
    goto c_63
_64
    btfsc   key_buff + KEY_COL, 6   ; If col 6 is already on don't set again
    bsf	    key_buff + KEY_COL, 6
    bsf	    key_buff + KEY_ROW, 4
    
c_63
    btfsc   PORTC, 3		    ; Test row 3
    goto _63
    goto c_62
_63
    btfsc   key_buff + KEY_COL, 6   ; If col 6 is already on don't set again
    bsf	    key_buff + KEY_COL, 6
    bsf	    key_buff + KEY_ROW, 3
    
c_62
    btfsc   PORTC, 2		    ; Test row 2
    goto _62
    goto c_61
_62
    btfsc   key_buff + KEY_COL, 6   ; If col 6 is already on don't set again
    bsf	    key_buff + KEY_COL, 6
    bsf	    key_buff + KEY_ROW, 2
    
c_61
    btfsc   PORTC, 1		    ; Test row 1
    goto _61
    goto c_60
_61
    btfsc   key_buff + KEY_COL, 6   ; If col 6 is already on don't set again
    bsf	    key_buff + KEY_COL, 6
    bsf	    key_buff + KEY_ROW, 1
    
c_60
    btfsc   PORTC, 0		    ; Test row 0
    goto _60
    return
_60
    btfsc   key_buff + KEY_COL, 6   ; If col 6 is already on don't set again
    bsf	    key_buff + KEY_COL, 6
    bsf	    key_buff + KEY_ROW, 0
    
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
    movlw   0x7F		    ; Don't set last bit! (MSB)
    movwf   PORTD
    clrf    PORTC
    
    ; Setup the keyboard interrupt bit
    movlw   b'10001000'
    movwf   INTCON		    ; Enable B0 interrupt
    
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