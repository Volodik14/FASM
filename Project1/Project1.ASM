;Motorkin Vladimir BSE198
format PE console
entry start

include 'win32a.inc'

section '.data' data readable writable
        strIntro db 'With this program you can find the square root of a number with an accuracy of no worse than 0.05 percent, using the iterative formula of Heron of Alexandria', 10, 0
        strInput db 'Input an integer number A > 0: ', 0
        strScan db '%d',0
        strError db 'Number A must be integer, > 0 and < (2^31)-1!', 10 , 0
        strValue db 'Number A equals %d', 10, 0
        strAnswer db 'Square root of number A is %1f', 10, 0
        ;strD db 'Current x = %1f'
        leftA        dd 0
        x            dq 3.0
        a            dd ?
        delta        dq 0.0005
        prev         dq ?
        divideby2    dd 0.5

section '.code' code readable executable


macro Print [arg] {
  reverse
    push arg
  common
    call [printf]
}


macro Scan [args] {
  reverse
    push args
  common
    call [scanf]
}

;All the calcilations for getting the answer
macro GetAnswer {
local valueLoop

valueLoop:
            ;debugging
            ;Print strD, dword[x], dword[x+4]

            ;previos value = x
            FLD [x]
            FSTP [prev]

            ;x = (x+a/x)*0.5
            FILD [a]
            FDIV [x]
            FADD [x]
            FMUL [divideby2]
            FSTP [x]

            ;checking if (x-prev)<delta, then repeat calculation
            FLD [prev]
            FSUB [x]
            FABS
            FCOMP [delta]
            FSTSW ax
            sahf
            ja valueLoop
}
;---------------------------------Main-------------------------------------
Error:
       Print strError
       jmp finish
start:
       FINIT
       Print strIntro
       Print strInput
       Scan strScan, a
       xor ecx, ecx
       mov ecx, [a]
       cmp ecx, [leftA]
       jle Error
       Print strValue, [a]
       GetAnswer
       Print strAnswer, dword[x], dword[x+4]

finish:
       call [getch]
       push 0
       call [ExitProcess]

;-------------------------------import-------------------------------------
                                                 
section '.idata' import data readable
    library kernel, 'kernel32.dll',\
            msvcrt, 'msvcrt.dll',\
            user32,'USER32.DLL'

include 'api\user32.inc'
include 'api\kernel32.inc'
    import kernel,\
           ExitProcess, 'ExitProcess'
include 'api\kernel32.inc'
    import msvcrt,\
           printf, 'printf',\
           scanf, 'scanf',\
           getch, '_getch'