char mode = 0;

void delay_us(volatile unsigned char us_count)
{   //input value will be in W. "Volatile" attribute prevents an "unused" warning.
#asm
dlyloop:
        addlw   0xFE            ;1 clk  -2
        btfsc   STATUS,0        ;1 clk   will be clear if W was smaller than 2
        goto    dlyloop         ;2 clks
#endasm
}

void blank() {
    PORTE = NTSC_SET_SYNC;
    delay_us(4);
    PORTE = NTSC_SET_BLACK;
    delay_us(60);
}

void vsync() {
    PORTE = NTSC_SET_SYNC;
    delay_us(64);
}

void display() {
    PORTE = NTSC_SET_SYNC;
    delay_us(4);
    PORTE = NTSC_SET_BLACK;
    delay_us(8);
    PORTE = NTSC_SET_WHITE;
    delay_us(52);
}

void main() {
    while(1) {
        for(int i = 0; i < 3; i++)
            blank();
        for(int i = 0; i < 3; i++)
            vsync();
        for(int i = 0; i < 16; i++)
            blank();
        for(int i = 0; i < 240; i++)
            display();
    }
}
