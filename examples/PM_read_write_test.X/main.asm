; ***** Program Memory (EEPROM) Read-Write Test ****
; Nicklas Carpenter
; Created: December 6, 2018
; Updated: January 10, 2019
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
INST_ADDR_H	equ 0x00    ; High byte of instruction to read from / write to
INST_ADDR_L	equ 0x08    ; Low byte of instruction to read from / write to

END_ADDR_L  equ	0x0F	; The last memory address to write to

; The instruction we are writing is "movlw 0x0F".
INSTR_H	    equ 0x30    ; High byte of instruction to write  
INSTR_L	    equ 0x0F    ; Low byte of instruction to write
     
    
; We store instructions in bank 3 to prevent continuous switching during write
bank_2	    udata   0x110		 
inst_l	    res 1   ; The low byte of the instruction read
inst_h	    res 1   ; The high byte of the instruction read
inst_rslt   res 1	; The result of the operation we read and change 
    
; I don't know why I specify this, since nine out of ten times I use hexadecimal
; anyway. I guess I like to be explicit with my hexadecimal (i.e. including the
; '0x' prefix), but I would rather not include a prefix if and when I use 
; decimal.
    radix dec

MAIN_PROG    code    0x0000
start
    ; Read the line as it's initially written.
    call    pm_read
    ; Move the original literal to the specified register
    call    test_sequence
    ; Modify 'test_sequence to move a new, different literal to the specified
    ; register
    call    pm_write
    ; Read the same lines. Basically, we're verifying our changes to program 
    ; memory were actually made
    call    pm_read
    ; Run the updated function. Icing on the cake.
    call    test_sequence
end_loop
    goto    end_loop

; Jump so we write to the correct location in program memory. We leave some
; empyt spaces, but that shouldn't matter for our purposes. Additionally, we 
; overwrite the interrupt vector. This is also okay, since this program 
; doesn't use any interrupts. 
USER_SPACE  code    0x0007
test_sequence
    clrf    inst_rslt
    ; The next instruction is addressed at 0x008 so we can write to it.
    movlw   TEST_LITERAL    ; This is the instruction we want to read or change.
    movwf   inst_rslt
    return

; We start the definition for our other fucnction starting at the next write
; block (program memory address 16). Every write to program memory has to 
; contain exactly 8 instructions, and each write has to start at an address
; whose least three significant bytes are 0 (i.e. 0bxxxxxxxxxxxxx000). 
KERNAL_SPACE	code	0x0010

; ****  pm_read ****
; Read the instruction we wrote to the specified address
pm_read	    	
    ; **** Initiating the read from program memory
    banksel EEADR   ; Select bank to specify where to read from in PM
    movlw   INST_ADDR_H
    movwf   EEADRH  ; High byte of program memory to read
    movlw   INST_ADDR_L
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
; Writes an instruction to program memory. This can be made more efficient when
; generalized. For now, it serves to demonstrate the basic concept.
pm_write
    ; **** Load the test instruction into data and select its address.
    banksel EEADR
    movlw   INST_ADDR_H    
    movwf   EEADRH	    ; Load high byte of initial instruction address.
    movlw   INST_ADDR_L
    movwf   EEADR
    movlw   INSTR_H  
    movwf   EEDATH	    ; Load high byte of instruction into buffer
    movlw   INSTR_L   
    movwf   EEDAT	    ; Load low byte of instruction into buffer
    movlw   INST_ADDR_L

; **** Write to EEDAT and EEDATH
write
    ; Check to ensure  we are not writing out of bounds: see if the address to
    ; be loaded into EADDR is past the end address. If we are in bounds, 
    ; initiate the write, otherwise we are done.
    bcf	    STATUS, RP0
    movlw   END_ADDR_L + 1 
    subwf   EEADR, w
    btfsc   STATUS, Z
    return
    
    
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
    
    ; ** Initialize the next write cycle
    banksel EEADR
    movlw   INST_ADDR_H    	    
    movwf   EEADRH
    incf    EEADR   ; Move to the next instruction

    banksel EECON1	    ; Select bank to specify when to read from PM
    bsf	    EECON1, EEPGD   ; Read from program memory as opposed to data memory
    bsf	    EECON1, RD	    ; Initiate a read from program memory
    
    ; It takes two instruction cycles to read from program memory. After 
    ; initiating a write, the two following instructions must be nops. 
    ; Ostensibly, the instruction immediately following the read initiation
    ; should execute, but this did not seem to be the case on testing. Note that
    ; in the simulator the nops are not needed: the two instructions following
    ; the read initiation appear to be executed normally.
    nop
    nop
    
    goto write
    
    end

    
 

 
 
    
    







