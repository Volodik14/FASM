format          PE console 4.0
include         'win32a.inc'
entry           start
 
CR              = 0Dh
LF              = 0Ah
 
;---------------------------------------------------------------------------
 
section '.text' code readable executable
 
start:
        cinvoke printf,outfmt,msg1              ; ????? ?????????
        cinvoke printf,outfmt,msg2              ; ????? ?????????
        cinvoke _getch
exit:
        invoke  ExitProcess, 0
 
;-----------------------------------------------------------------------------------
 
section '.data' data readable writeable
 
msg1    db      'hello, world!!',CR,LF,0        ; ?????? ??? ?????? ? ???????? ?????
msg2    db      'press any key to exit',CR,LF,0 ; ?????? ??? ?????? ? ???????? ?????
outfmt  db      '%s',0                          ; ?????? ????????
 
;-----------------------------------------------------------------------------------
 
section '.idata' import data readable
 
library         kernel32,'KERNEL32.DLL',\
                msvcrt,'MSVCRT.DLL'
 
include         'api\kernel32.inc'
 
import          msvcrt,\
                printf,'printf',\
                _getch,'_getch'