#define _XTAL_FREQ 8000000

#pragma config FOSC = HS                            // Oscillator Selection bits (HS oscillator: High-speed crystal/resonator on RA6/OSC2/CLKOUT and RA7/OSC1/CLKIN)
#pragma config WDTE = OFF                           // Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
#pragma config PWRTE = OFF                          // Power-up Timer Enable bit (PWRT disabled)
#pragma config MCLRE = ON                           // RE3/MCLR pin function select bit (RE3/MCLR pin function is MCLR)
#pragma config CP = OFF                             // Code Protection bit (Program memory code protection is disabled)
#pragma config CPD = OFF                            // Data Code Protection bit (Data memory code protection is disabled)
#pragma config BOREN = OFF                          // Brown Out Reset Selection bits (BOR disabled)
#pragma config IESO = OFF                           // Internal External Switchover bit (Internal/External Switchover mode is disabled)
#pragma config FCMEN = OFF                          // Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
#pragma config LVP = OFF                            // Low Voltage Programming Enable bit (RB3 pin has digital I/O, HV on MCLR must be used for programming)
#pragma config BOR4V = BOR21V                       // Brown-out Reset Selection bit (Brown-out Reset set to 2.1V)
#pragma config WRT = OFF                            // Flash Program Memory Self Write Enable bits (Write protection off)

#include <xc.h>

void init_timer(void);
void __interrupt() isr(void);

// Main entry point
void main(void) {
    init_timer();
    
    while(1);
}
// Handle ntsc code
void __interrupt() isr(void) {
    if(T0IF) {
        RD0 = !RD0;
        T0IF = 0;
        TMR0 = 255;
    }
}

// Setup ccp1 and timers
void init_timer(void) {
    // Set 8 MHz clock
    IRCF2 = 1, IRCF1 = 1, IRCF0 = 1;
    
    TRISD0 = 0;
    
    // Init timer 0
    T0CS = 0;                                       // Use FOSC/4 (0.5 us)
    PSA = 1;                                        // Give timer 0 the wdt so no scale
    PS2 = 0;                                        // Prescale smallest value (1 : 2) for 1us increments
    PS1 = 0;
    PS0 = 0;
    T0IE = 1;                                       // Enable Timer 0
    T0IF = 0;                                       // Start off by default
    
    // Enable interrupts
    PEIE = 1;
    GIE = 1;
}