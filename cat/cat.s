section .data
	error_message db "Something went wrong. Check arguments and try again!",0xa
	error_message_length equ $ - error_message
section .bss
    buffer resb 4096 ; for loading file contents. 4096B is typical page size.
    fd     resd 1  ; 4 bytes for the file descriptor
    filename resd 5 ; 20 bytes for filename

section .text
    global _start

_start:
    mov ebx, [esp + 8] ; argv[1] begins at an offset of 8 bytes on esp
    cmp ebx, 0; check argv[1] is not null
    je exit_with_error
    xor esi, esi; initialize esi to 0
    call set_filename

cat:
    mov ebx, filename
    call open
    cmp eax, 0
    jl exit_with_error
    mov [fd], eax ; set fd from open sys call
    call rw_loop

open:
    mov eax, 5
    mov ebx, filename
    mov ecx, 0 ; O_READONLY
    int 80h;
    ret

rw_loop:
    mov eax, 3 ; read sys call
    mov ebx, [fd]
    mov ecx, buffer
    mov edx, 4096
    int 80h
    ; check if we have reached EOF
    cmp eax, 0
    je .done
    mov ecx, buffer
    mov edx, eax; eax now stores bytes read
    call print
    jmp rw_loop
.done:
    call close
    call exit

print:
    mov eax, 4; write sys call
    mov ebx, 1
    int 80h
    ret

close:
    mov eax, 6; close sys call
    mov ebx, [fd]
    int 80h
    ret

exit:
    mov eax, 1 ; exit sys call
    mov ebx, 0 ; exit code
    int 80h

set_filename:
    mov al, [ebx + esi] ; get current byte of argv[1]
    cmp al, 0
    je filename_copied
    ; check for buffer overflow
    cmp esi, 19 ; leave 1 byte of space for null terminator
    jge exit_with_error

    ; write current byte to buffer
    mov [filename + esi], al
    ; increment esi and restart loop
    inc esi
    jmp set_filename

filename_copied:
    mov byte [filename + esi], 0; null terminate the buffer
    call cat ; now enter main program

exit_with_error:
    mov ecx, error_message
    mov edx, error_message_length
    call print
    mov eax, 1 ; exit sys call
    mov ebx, 1 ; non zero exit code
    int 80h

