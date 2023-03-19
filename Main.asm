   FLAG  EQU 20H.0           ;T0计数溢出标志
    DAT  EQU 21H             ;距离，单位为CM
   CNT1  EQU 22H             ;计数1
   CNT2  EQU 23H             ;计数2
   INDX  EQU 24H             ;数码管索引
  _PAGE  EQU 25H             ;页面0为显示测距值，1为显示上限值，页面2为显示下限值
   DISH  EQU 26H             ;上限阈值
   DISL  EQU 27H             ;下限阈值
    BUF  EQU 30H             ;显示缓冲区
   KEY1  BIT P1.0            ;按键1
   KEY2  BIT P1.1            ;按键2
   KEY3  BIT P1.2            ;按键3
    LED  BIT P1.6            ;报警指示灯
    BUZ  BIT P1.7            ;蜂鸣器
   TRIG  BIT P3.2            ;超声波发射引脚
   ECHO  BIT P3.3            ;超声波接收引脚
    ORG  0000H
    LJMP MAIN
    ORG  000BH
    LJMP T0_ISR              ;定时器0中断子程序
    ORG  001BH
    LJMP T1_ISR              ;定时器1中断子程序
    ORG  0100H
;============================
; 主程序
;============================
MAIN:
    MOV   SP,#60H
    LCALL DATA_INIT
    LCALL T01_INIT
LOOP:
    MOV   A,_PAGE
    JNZ   KKK
    LCALL SRF04
KKK:LCALL KEYSCAN
    LCALL CALC
    LJMP  LOOP

;============================
; 超声波接收
;============================
SRF04:
    JNB   ECHO,$
    MOV   TH0,#0
    MOV   TL0,#0
    CLR   FLAG
    SETB  TR0
    JB    ECHO,$
    CLR   TR0
    RET

;============================
; 数据初始化
;============================
DATA_INIT:
    MOV  BUF+0,#0FFH
    MOV  BUF+1,#0FFH
    MOV  BUF+2,#0FFH
    MOV  BUF+3,#0FFH
    MOV  DISH,#30
    MOV  DISL,#5
    RET

;============================
; 计算距离
;============================
CALC:
    MOV   A,_PAGE
    CJNE  A,#0,PAGE_1
    MOV   R3,TH0
    MOV   R4,TL0
    MOV   R7,#10
    LCALL NDIV21
    MOV   R7,#17
    LCALL NMUL21
    CLR   CY
    MOV   A,#80
    ADD   A,R4
    MOV   R4,A
    CLR   A
    ADDC  A,R3
    MOV   R3,A
    MOV   R7,#100
    LCALL NDIV21
    MOV   DAT,R4
    MOV   BUF+3,#0FFH
    MOV   A,DAT
    LJMP  GET_CODE
PAGE_1:
    CJNE  A,#1,PAGE_2
    MOV   BUF+3,#89H
    MOV   A,DISH
    LJMP  GET_CODE
PAGE_2:
    MOV   BUF+3,#0C7H
    MOV   A,DISL
GET_CODE:
    MOV   DPTR,#TAB
    MOV   B,#10
    DIV   AB
    XCH   A,B
    MOVC  A,@A+DPTR
    MOV   BUF+0,A
    XCH   A,B
    MOV   B,#10
    DIV   AB
    XCH   A,B
    MOVC  A,@A+DPTR
    MOV   BUF+1,A
    XCH   A,B
    MOV   BUF+2,#0FFH
    JZ    CHECK
    MOVC  A,@A+DPTR
    MOV   BUF+2,A
CHECK:
    CLR   CY
    MOV   A,DAT
    MOV   B,DISH
    SUBB  A,B
    JNC   ALARM
    CLR   CY
    MOV   A,DAT
    MOV   B,DISL
    SUBB  A,B
    JC    ALARM
    SETB  LED
    SETB  BUZ
    RET
ALARM:
    CLR   LED
    CLR   BUZ
    RET

;============================
; 定时器初始化
;============================
T01_INIT:
    MOV   TMOD,#11H
    MOV   TH0,#0
    MOV   TL0,#0
    SETB  EA
    SETB  ET0
    CLR   TR0
    MOV   TH1,#0F8H
    MOV   TL1,#30H
    SETB  ET1
    SETB  TR1
    RET

;============================
; 定时器0中断子程序
;============================
T0_ISR:
    SETB  FLAG
    RETI

;============================
; 定时器1中断子程序
;============================
T1_ISR:
    PUSH  ACC
    MOV   TH1,#0F8H
    MOV   TL1,#30H
    LCALL DISPLAY
    INC   CNT1
    MOV   A,CNT1
    CJNE  A,#100,T1_END
    MOV   CNT1,#0
    INC   CNT2
    MOV   A,CNT2
    CJNE  A,#4,T1_END
    MOV   CNT2,#0
    SETB  TRIG
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    CLR   TRIG
T1_END:
    POP   ACC
    RETI

;============================
; 按键扫描子程序
;============================
KEYSCAN:
    JB    KEY1,K2
    LCALL DELAY1MS
    JB    KEY1,K2
    JNB   KEY1,$
    INC   _PAGE
    MOV   A,_PAGE
    CJNE  A,#3,KEY_END
    MOV   _PAGE,#0
    LJMP   KEY_END
K2: JB    KEY2,K3
    LCALL DELAY1MS
    JB    KEY2,K3
    JNB   KEY2,$
    MOV   A,_PAGE
    CJNE  A,#1,NEXT0
    INC   DISH
    LJMP  KEY_END
NEXT0:
    CJNE  A,#2,KEY_END
    INC   DISL
    LJMP  KEY_END
K3: JB    KEY3,KEY_END
    LCALL DELAY1MS
    JB    KEY3,KEY_END
    JNB   KEY3,$
    MOV   A,_PAGE
    CJNE  A,#1,NEXT1
    DEC   DISH
    LJMP  KEY_END
NEXT1:
    CJNE  A,#2,KEY_END
    DEC   DISL
    LJMP  KEY_END
KEY_END:
    RET


;============================
; 数码管显示子程序
;============================
DISPLAY:
    MOV   P0,#0FFH
    MOV   A,INDX
    INC   A
    ANL   A,#3
    MOV   INDX,A
    MOV   R0,#BUF
    ADD   A,R0
    MOV   R0,A
    MOV   A,@R0
    MOV   P0,A
    MOV   A,INDX
    MOV   DPTR,#WEI
    MOVC  A,@A+DPTR
    MOV   P2,A
    RET

;============================
; 延时子程序
;============================
DELAY1MS:
    MOV  R7,#01H
DL1:MOV  R6,#8EH
DL0:MOV  R5,#02H
    DJNZ R5,$
    DJNZ R6,DL0
    DJNZ R7,DL1
    RET

;============================
; 乘法子程序
; (R3R4*R7)=(R2R3R4)
;============================
NMUL21:
    MOV A,R4
    MOV B,R7
    MUL AB
    MOV R4,A
    MOV A,B
    XCH A,R3
    MOV B,R7
    MUL AB
    ADD A,R3
    MOV R3,A
    CLR A
    ADDC A,B
    MOV R2,A
    CLR OV
    RET

;============================
; 除法子程序
; (R3R4/R7)=(R3)R4 余数R7
;============================
NDIV21:
    MOV A,R3
    MOV B,R7
    DIV AB
    PUSH ACC
    MOV R3,B
    MOV B,#08H
NDV211:
    CLR C
    MOV A,R4
    RLC A
    MOV R4,A
    MOV A,R3
    RLC A
    MOV R3,A  
    MOV F0,C
    CLR C
    SUBB A,R7
    JB F0,NDV212
    JC NDV213
NDV212:
    MOV R3,A
    INC R4
NDV213:
    DJNZ B,NDV211
    POP ACC
    CLR OV
    JZ NDV214
    SETB OV
NDV214:
    XCH A,R3
    MOV R7,A
    RET

TAB:                         ;共阳数码管段码表
    DB  0C0H,0F9H,0A4H,0B0H,099H
    DB  092H,082H,0F8H,080H,090H
WEI:
    DB  0FEH,0FDH,0FBH,0F7H  ;位选码表

    END
