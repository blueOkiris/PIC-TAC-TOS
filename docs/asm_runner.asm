user_w          res 1
user_comm       res 1
user_pc         res 2
user_mem        res 32

CMD_ADDWF       equ 0
CND_ANDWF       equ 1
; ...

; Let users access special registers, but only 32 of general purpose
; Also allow a working register for when they access w
; Also have a separate p.c. for user memory

; TODO: Reimplement functions for:
    ; addwf     f, d
    ; andwf     f, d
    ; clrf      f
    ; clrw
    ; comf      f, d
    ; decf      f, d
    ; decfsz    f, d
    ; incf      f, d
    ; incfsz    f, d
    ; iorwf     f, d
    ; movf      f, d
    ; movwf     f, d
    ; nop
    ; rlf       f, d
    ; rrf       f, d
    ; subwf     f, d
    ; swapf     f, d
    ; xorfwf    f, d

    ; bcf       f, b
    ; bsf       f, b
    ; btfsc     f, b
    ; btfss     f, b

    ; addlw     k
    ; andlw     k
    ; call      k
    ; clrwdt
    ; goto      k
    ; iorwl     k
    ; movlw     k
    ; retfie
    ; retlw     k
    ; return
    ; sleep
    ; sublw
    ; xorlw

run_program
; Assume memory @ loc user_pc is loaded here
; It loads an instruction into user_comm
execute_command
    movlw       CMD_ADDWF
    subwf       user_comm, w
    btfsc       STATUS, Z
    goto        execute_cmd_addwf

    movlw       CMD_ANDWF
    subwf       user_comm, w
    btfsc       STATUS, Z
    goto        execute_cmd_andwf

    ; ...

    goto run_program

execute_cmd_addwf
    ; Addwf for user
    goto run_program

execute_cmd_andwf
    ; Addwf for user
    goto run_program

    ; ... All command implementations