; Multiple threads accessing a counter with no lock
; Produces unexpected results
section .data
    spawn_msg db "Spawning new thread",0xa,0
    spawn_msg_len equ $-spawn_msg
    counter_msg db "Value in counter: ",0
    counter_msg_len equ $-counter_msg
    newline db 0xa,0x00
    newline_len equ $-newline
    max_threads db 8
    counter db 0

section .bss
    num_threads resb 1

section .text
    global _start

_start:
    call init_threads

init_threads:
    ; check num threads
    mov al, [num_threads]
    cmp al, [max_threads]
    jge exit
    inc byte [num_threads]
    call spawn_thread
    test eax, eax
    jnz init_threads
    mov esp, eax
    call child_process

spawn_thread:
    mov ecx, spawn_msg
    mov edx, spawn_msg_len
    call print
    call allocate_stack
    ; store mmap address as the child stack pointer
    mov ecx, eax      ; ecx holds the mmap'd memory address (child stack)
    ; calculate the top of the stack (ESP grows downwards)
    add ecx, 4096     ; move ECX to the top of the allocated 4KB stack

    ; clone flags
    mov ebx, 0x00000100 | 0x00000400  ; CLONE_VM | CLONE_FILES
    mov eax, 120      ; sys_clone
    xor edx, edx
    int 0x80

    cmp eax, 0
    jl exit_with_error
    test eax, eax
    jnz parent_process  ; If eax != 0, it's the parent process
    ; Child thread continues here
    call child_process
    jmp exit

parent_process:
    ret

allocate_stack:
    ; allocate memory for child stack
    mov ebx, 0      ; set to NULL to let OS decide starting address
    mov ecx, 4096   ; 4k of memory
    mov edx, 0x7    ; protection: PROT_EXEC | PROT_WRITE | PROT_READ
    mov esi, 0x22   ; flags: MAP_ANONYMOUS | MAP_PRIVATE
    mov edi, -1     ; fd: according to man page should be set to -1
    mov ebp, 0      ; offset: according to man page should be set to zero
    mov eax, 192    ; sys call number for mmap
    int 0x80
    ; check if mmap returned a valid pointer
    cmp eax, -1     ; on failure mmap returns -1
    je exit_with_error
    ret

child_process:
    ; increment counter
    mov al, [counter]
    inc byte al
    mov [counter], al
    call print_counter_val
    ; free the allocated stack using munmap
    mov eax, 91
    mov ebx, [esp+4]
    mov ecx, 4096
    int 0x80
    ; check for negative status code
    cmp eax, 0
    jl exit_with_error
    ; exit the child process
    jmp exit

print_counter_val:
    mov ecx, counter_msg
    mov edx, counter_msg_len
    call print
    add byte [counter], 0x00000030
    mov ecx, counter
    mov edx, 1
    call print
    sub byte [counter], 0x30
    mov ecx, newline
    mov edx, newline_len
    call print
    ret

print:
    mov ebx, 1
    mov eax, 4
    int 0x80
    ret

exit_with_error:
    mov ebx, eax
    mov eax, 1
    int 0x80

exit:
    mov eax, 1
    mov ebx, 0
    int 0x80