; Program that creates a new socket
; After socket call we get a new fd (3) in eax
section .text
    global _start

_start:
    ; clear registers
    xor eax, eax
    xor ebx, ebx
    xor esi, esi
    xor edi, edi

create_socket:
    ; argument for protocol (IPPROTO_TCP)
    push byte 6
    ; argument for type (SOCK_STREAM)
    push byte 1
    ; argument for domain (PF_INET - IPv4)
    push byte 2
    ; system call arguments
    ; provide address of stack
    mov ecx, esp 
    ; specific socket call (SOCKET 1)
    mov ebx, 1
    ; sys call number for SYS_SOCKETCALL
    mov eax, 102
    int 80h

exit:
    mov eax, 1
    mov ebx, 0
    int 80h
