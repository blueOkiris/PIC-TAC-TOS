; ***** Program Memory (EEPROM) Read-Write Test ****
; Nicklas Carpenter
; December 6, 2018
;
; This is a simple program that attempts to read from and write to the program
; memory of the PIC16F887. It's purpose is to test the extent and ability of
; the programmer to read instructions and insert them at runtime.

#include "p16f887.inc"

; CONFIG1
; __config 0xE0D4
 __CONFIG _CONFIG1, _FOSC_INTRC_NOCLKOUT & _WDTE_OFF & _PWRTE_OFF & _MCLRE_OFF & _CP_OFF & _CPD_OFF & _BOREN_OFF & _IESO_OFF & _FCMEN_OFF & _LVP_OFF
; CONFIG2
; __config 0xFEFF
 __CONFIG _CONFIG2, _BOR4V_BOR21V & _WRT_OFF


TEST_LITERAL	equ 0xFF    ; Test literal so movlw command is clearly visible
TEST_INSTR_H	equ 0x00    ; High byte of instruction to read from
TEST_INSTR_L	equ 0x08    ; Low byte of instruction to read from

; The instruction we are writing is "movlw 0x00".
WRITE_INSTR_H	equ 0x30    ; High byte of instruction to write  
WRITE_INSTR_L	equ 0x0F    ; Low byte of instruction to write     

bank_0	udata   0x20
inst_rslt   res 1	; The result of the operation we read and change
    
; We store instructions in bank 3 to prevent continuous switching during write
bank_3	udata   0x110		 
cur_addr    res 1	; The offset from the instruction we are writing.
inst_l res 1   ; The low byte of the instruction read
inst_h  res 1   ; The high byte of the instruction read 
    

    radix dec
RST_VECT    code    0x0000
    goto    start

MAIN_PROG   code    0x0005
start
    call    pm_write
end_loop
    goto    end_loop

test_sequence
    clrf    inst_rslt
    ; The next instruction is addressed at 0x008 so we can write to it.
    ; In general it seems you can only write to addresses with zeroes in the 
    ; least significant bit.
    movlw   TEST_LITERAL    ; This is the instruction we want to read or change.
    movwf   inst_rslt
    return

;   ****  pm_read ****
;   Read the instruction we wrote to the specified address 
;   We skip a few addresses between test_sequence and this function to ensure
;   this function is not overwriten by pm_write
SECT_2	code	0x0010
pm_read	    	
    ; **** Initiating the read from program memory
    banksel EEADR   ; Select bank to specify where to read from in PM
    movlw   TEST_INSTR_H
    movwf   EEADRH  ; High byte of program memory to read
    movlw   TEST_INSTR_L
    movwf   EEADR   ; Low byte or program memory to read
    banksel EECON1  ; Select bank to specify when to read from PM
    bsf	    EECON1, EEPGD   ; Read from program memory as opposed to data memory
    bsf	    EECON1, RD	; Initiate a read from program memory
    
    ; It takes two instruction cycles to read from program memory.
    ; We can do something during the first instruction, but the second
    ; instuction is ignored. We have nothing better to do here, so we'll make
    ; both instructions No-ops.
    nop
    nop
    
    ; *** Reading from program memory
    banksel EEDAT   ; Select the bank where our PM read was stored
    
    ; Clear our instruction registers.
    clrf    inst_h
    clrf    inst_l

    movf    EEDATH,w
    movwf   inst_h  ; Store the high byte of the instruction
    movf    EEDAT,w
    movwf   inst_l  ; Store the low byte of the instruction
    return

; **** pm_write ****
; Writes an instruction to program memory
pm_write
    ; **** Load the instruction into data and select its address
    banksel EEADR
    movlw   TEST_INSTR_H    
    movwf   EEADRH	    ; Load high byte of initial instruction address.
    movlw   TEST_INSTR_L
    movwf   EEADR	    ; Load low byte of initial instruction address
    movlw   WRITE_INSTR_H  
    movwf   EEDATH	    ; Load high byte of instruction into buffer
    movlw   WRITE_INSTR_L   
    movwf   EEDAT	    ; Load low byte of instruction into buffer
    movlw   TEST_INSTR_L
    movwf   cur_addr	    
    incf    cur_addr, f	    ; Set offset to one so we can write to next address

; **** Write EEDAT and EEDATH
write
    ; Preform the write operation
    banksel EECON1	    ; Select the program memory read configureation
    bsf	    EECON1, EEPGD   ; Write to program data instead of EEPROM
    bsf	    EECON1, WREN    ; Enable writing to program memory

    ; Loading the required write sequence 0x55AA
    movlw   0x55
    movwf   EECON2	    ; Load the first byte of the write sequence
    movlw   0xAA
    movwf   EECON2	    ; Load the second byte of the write sequence
    bsf	    EECON1, WR	    ; Initiate the write

    ; It takes two instruction cycles to write to memory
    nop
    nop
    bcf	    EECON1, WREN    ; Disable writing to program memory (for safety)
    
    banksel EEADR
    movlw   0x00    	    
    movwf   EEADRH
    movf    cur_addr, w
    movwf   EEADR
    incf    cur_addr
    banksel EECON1  ; Select bank to specify when to read from PM
    bsf	    EECON1, EEPGD   ; Read from program memory as opposed to data memory
    bsf	    EECON1, RD	; Initiate a read from program memory
    
    ; It takes two instruction cycles to read from program memory.
    ; We can do something during the first instruction, but the second
    ; instuction is ignored. We have nothing better to do here, so we'll make
    ; both instructions No-ops.
    nop
    nop
    
    banksel cur_addr
    ; Check to see if we should stop writing to the buffer
    movlw   0x11 ; This is one past the address where we want to stop
		 ; cur_addr is incremented but not used for the last value.
    subwf   cur_addr,w
    btfss   STATUS,Z
    goto    write
    
    ; Test our changes.
    call    pm_read
    banksel inst_rslt
    call    test_sequence
    return
    
    end

    
 

 
 
    
    







