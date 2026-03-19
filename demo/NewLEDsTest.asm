ORG 0
Reset:
	LOAD    LEDAllMask
    OUT     LEDs    ; Turn off all LEDs

; wait for all switches to be off. while doing so, display which switches are on using LEDs
WaitForZeroSwitches:
    LOADI   0
    OR      LEDAllMask
    OUT     LEDs
    IN      Switches
    OR      LEDOn
    OR      LEDBright07
    OUT     LEDs
    IN      Switches
    JPOS    WaitForZeroSwitches
    LOADI   0
; all switches zeroed

Outer:
    LOADI   11
    STORE   WaveCenter  ; int WaveCenter = 11;
Inner:
    LOADI   9
    STORE   CurrLed     ; int CurrLed = 9;

    LOAD    Bit9
    STORE   LEDMask     ; int LedMask = 0b1000000000;

; Do flashing stuff?
    IN      Switches   
    JPOS    FlashDemo
Update:
    LOAD    CurrLed     
    JNEG    Wait        ; if CurrLed < 0 goto Wait
; AC = CurrLedPos
    SUB     WaveCenter   
    CALL    Abs         ; find abs diff CurrLed - WaveCenter
    SHIFT   2           ; diff * 4
    CALL    Negate      ; -diff*4
    ADDI    15
    JPOS    LightUp     ; if (-diff*4 + 15 > 0) lightup, else 0
    LOADI   0
LightUp:
; AC = brightness
    SHIFT   10
    OR      LEDMask
    OR      LEDOn
    OUT     LEDs        ; set 1 led

    LOAD    CurrLed
    SUB     One         ; CurrLed -= 1
    STORE   CurrLed
    
    LOAD    LEDMask
    SHIFT   -1          ; LedMask <<= 1
    STORE   LEDMask

    JUMP    Update      ; next led
Wait:
    CALL    Delay       ; Sleep 0.2s;   

    LOAD    WaveCenter  
    SUB     One         ; WaveCenter--;
    STORE   WaveCenter

    ADDI    2           ; once hit -2, go back
    JZERO   Outer       ; Loop restart once WaveCenter == -2

    JUMP    Inner       ; Else inner loop

FlashDemo:
    LOADI   0
    OR      LEDOn
    OR      LEDBright15
    OR      LEDFlash
    OR      LEDEvenMask
    OUT     LEDs
    LOADI   0
    OR      LEDOn
    OR      LEDBright15
    OR      LEDOddMask
    OUT     LEDs

    IN      Switches
    JZERO   Outer
    JUMP    FlashDemo

Abs:
    JPOS  AbsRet
    STORE AbsTemp
    LOADI 0
    SUB   AbsTemp
    JUMP  AbsRet
AbsTemp: DW 0
AbsRet:
    RETURN

Negate:
    STORE NegateTemp
    LOADI 0
    SUB   NegateTemp
    JUMP  NegateRet
NegateTemp: DW 0
NegateRet:
    RETURN

; 0.2s delay subroutine
Delay:
	OUT    Timer
WaitingLoop:
	IN     Timer
	ADDI   -2
	JNEG   WaitingLoop
	RETURN


    

; variables
WaveCenter: DW 0
CurrLed:   DW 0 
LEDMask:   DW 0
LEDBright: DW 0
CurrLedDist: Dw 0

; IO address constants
Switches:  EQU 000
Timer:     EQU 002
Hex0:      EQU 004
Hex1:      EQU 005
LEDs:      EQU 032

One:       DW 1
Bit9:      DW &B1000000000

LEDAllMask: DW &B0000001111111111
LEDOddMask: DW &B0000001010101010
LEDEvenMask: DW &B0000000101010101
LEDOn:      DW &B1000000000000000
LEDFlash:   DW &B0100000000000000

LEDBright15: DW &B0011110000000000
LEDBright07: DW &B0001110000000000
LEDBright03: DW &B0000110000000000
