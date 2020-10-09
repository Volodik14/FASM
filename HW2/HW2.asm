; Motorkin Vladimir BSE198
format PE console
entry start
include 'win32a.inc'

section '.dconst' readable

        endl db 10,0
        print_number_str db '%d',0
        print_element_str db '%d, ',0
        start_str db 'This program will create an array A consisting of positive elements of array B', 10, 0
        get_len_str db 'Input the size of array A:', 10, 0
        wrong_size_str db 'Invalid input data!', 10, 0
        print_index_str db 'A[%d] = ', 0
        print_a_str db 'A:', 10, 0
        print_b_str db 'B:', 10, 0
        invalid_a_str db 'Array A do not contain any positive elements.', 10, 0
        error_str db 'ERROR: CANNOT MALLOC', 10, 0
        exit_str db 'Press any key to exit.', 10, 0

section '.data' readable writable

        length_a dd ?
        length_b dd ?
        ; pointers of arrays a and b
        pointer_a dd 0
        pointer_b dd 0

section '.code' code readable executable
start:
        ;welcoming text
        push start_str
        call [printf]
        add esp, 4

        ;getting array a
        push get_len_str
        call [printf]
        add esp, 4

        call input_a
        ;printing array a
        push print_a_str
        call [printf]
        add esp, 4

        call print_a

        ;creating array b
        call create_b

        ;printing array b
        push print_b_str
        call [printf]
        add esp, 4

        call print_b

        ;exiting program
        jmp finish

input_a:
        ;getting length of array a
        push length_a
        push print_number_str
        call [scanf]
        add esp, 8

        ;checking input
        cmp eax, 1
        jne input_err

        cmp [length_a], 0
        jle input_err

        ;4 bits * length_a = recuired amount of memory for malloc
        mov ebx, [length_a]
        imul ebx, 4
        push ebx
        call [malloc]

        mov [pointer_a], eax

        add esp, 4
        ;setting ebx to 0
        xor ebx, ebx
        ;filling array A
        loop_a:
                ;ebx - position in array
                push ebx
                push print_index_str
                call [printf]
                add esp, 8

                mov ecx, ebx
                imul ecx, 4
                add ecx, [pointer_a]

                ;getting A[ebx]
                push ecx
                push print_number_str
                call [scanf]
                add esp, 8

                ;checking input
                cmp eax, 1
                jne input_err

                inc ebx
                cmp ebx, [length_a]
                jne loop_a
        ret

create_b:
        ;setting eax and ebx to 0
        xor eax, eax
        xor ebx, ebx

        ;getting number of positive elements
        loop_b:
                ;ebx - position in array A
                ;eax - position in array B
                mov ecx, ebx
                imul ecx, 4
                add ecx, [pointer_a]

                ;skipping increasing if value <= 0
                cmp dword [ecx], 0
                jle skip_inc

                inc eax

                skip_inc:
                inc ebx
                cmp ebx, [length_a]
                jne loop_b

        mov [length_b], eax

        ;printing error if array b is empty
        cmp eax, 0
        je empty_b

        mov ebx, [length_b]
        imul ebx, 4
        push ebx
        call [malloc]

        mov [pointer_b], eax

        add esp, 4

        ;setting eax and ebx to 0
        xor ebx, ebx
        xor eax, eax

        fill_b:
                ;eax - position in array B
                ;ebx - position in array A
                mov ecx, ebx
                imul ecx, 4
                add ecx, [pointer_a]

                ;skipping increasing if value <= 0
                cmp dword [ecx], 0
                jle skip

                mov edx, eax
                imul edx, 4
                add edx, [pointer_b]

                mov ecx, dword [ecx]
                mov [edx], ecx

                inc eax

                skip:

                inc ebx
                cmp ebx, [length_a]
                jne fill_b

      ret

print_a:
        ;setting ebx to 0
        xor ebx, ebx
        arr_out:
                ;ebx - position in array A
                mov ecx, ebx
                imul ecx, 4
                add ecx, [pointer_a]

                push dword [ecx]
                push print_element_str
                call [printf]
                add esp, 8

                inc ebx
                cmp ebx, [length_a]
                jne arr_out

       push endl
       call [printf]
       add esp, 4

       ret

print_b:
        ;setting ebx to 0
        xor ebx, ebx
        print_b_loop:
                ;ebx - position in array B
                mov ecx, ebx
                imul ecx, 4
                add ecx, [pointer_b]

                push dword [ecx]
                push print_element_str
                call [printf]
                add esp, 8

                inc ebx
                cmp ebx, [length_b]
                jne print_b_loop

       push endl
       call [printf]
       add esp, 4

       ret

finish:
        push exit_str
        call [printf]
        add esp, 4

        call [getch]

        ; clear memory
        push [pointer_a]
        call [free]
        add esp, 4
        push [pointer_b]
        call [free]
        add esp, 4
        push 0
        call [ExitProcess]

input_err:
        push wrong_size_str
        call [printf]
        add esp, 4

        jmp finish

empty_b:
     push invalid_a_str
     call [printf]
     add esp, 4

     jmp finish

section '.idata' import data readable

library kernel32, 'kernel32.dll',\
        msvcrt, 'msvcrt.dll'

import msvcrt,\
       printf, 'printf',\
       scanf, 'scanf',\
       malloc, 'malloc',\
       getch, '_getch',\
       free, 'free'

import kernel32,\
       ExitProcess, 'ExitProcess'