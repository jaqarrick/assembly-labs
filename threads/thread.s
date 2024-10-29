section .data
    child_msg db "Hello from the child process!",0
    child_msg_len equ $-child_msg
    parent_msg db "Parent process exiting.", 0
    parent_msg_length equ $-parent_msg

section .text
    global _start

_start:
    ; allocate memory for child stack
    mov ebx, 0      ; set to NULL to let OS decide starting address
    mov ecx, 4096   ; 4k of memory
    mov edx, 0x7    ; protection: PROT_EXEC | PROT_WRITE | PROT_READ
    mov esi, 0x22   ; flags: MAP_ANONYMOUS | MAP_PRIVATE
    mov edi, -1     ; fd: according to man page shoud be set to -1
    mov ebp, 0      ; offset: according to man page shoud be set to zero
    mov eax, 192    ; sys call number for mmap
    int 80h
    ; check if mmap returned a valid pointer
    
    cmp eax, -1     ; on failure mmap returns -1
    je exit_with_error

    ; store mmap address as the child stack pointer
    mov ecx, eax      ; ecx holds the mmap'd memory address (child stack)

    ; calculate the top of the stack (ESP grows downwards)
    add ecx, 4096     ; move ECX to the top of the allocated 4KB stack

    ; clone flags
    mov ebx, 0x00000100 | 0x00000400  ; CLONE_VM | CLONE_FILES

    ; clone sys call
    mov eax, 120       ; sys_clone
    int 0x80

    ; Check if we are in the parent or the child
    test eax, eax
    jnz parent_process ; If eax != 0, it's the parent process

    ; child process: set the stack pointer to the mmap-ed stack
    mov esp, ecx       ; set the stack pointer to the allocated memory

child_process:
    mov ecx, child_msg
    mov edx, child_msg_len
    call print

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

parent_process:
    ; print and exit
    mov ecx, parent_msg
    mov edx, parent_msg_length
    call print
    call exit

print:
    mov ebx, 1         ; File descriptor 1 (stdout)
    mov eax, 4         ; Syscall number for sys_write
    int 0x80           ; Make system call
    ret

exit_with_error:
    mov ebx, eax       ; Move syscall error code to EBX
    mov eax, 1         ; Syscall number for sys_exit
    int 0x80

exit:
    mov eax, 1         ; Syscall number for sys_exit
    mov ebx, 0         ; Exit code 0
    int 0x80
