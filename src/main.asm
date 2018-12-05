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
    
    udata   0x20		; Register file locations for system variables
    
RES_VECT    CODE    0x0000	; Processor reset vector
    pagesel start
    goto    start
    
MAIN_PROG   CODE
start
    
    