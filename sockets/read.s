; Program that reads an incoming request
section .bss
    buffer resb 256 
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
    ; just exit on error
    cmp eax, 0
    jl exit

bind_socket:
    ;int bind(int sockfd, const struct sockaddr *addr, socklen_t addrlen);
    ; store fd we get back from create call
    mov edi, eax
    ; argument for IP (0.0.0.0)
    push dword 0x00000000
    ; argument for port (5261 in big endian format)
    push word 0x8D14
    ; argument for address family (AF_INET e.g. IPv4)
    push word 2
    ; set up stack for bind call
    ; point ecx to stack address
    mov ecx, esp
    ; arguments length
    push byte 16
    ; address of arguments
    push ecx
    ; file descriptor
    push edi
    mov ecx, esp
    ; subroutine BIND call
    mov ebx, 2
    mov eax, 102
    int 80h
    ; just exit on error
    cmp eax, 0
    jl exit

listen:
    ; set up arguments 
    ; int listen(int sockfd, int backlog);
    ; backlog (allow up to 5 bending connections)
    push byte 1
    ; socket fd
    push edi
    mov ecx, esp
    ; subroutine LISTEN call
    mov ebx, 4
    mov eax, 102
    int 80h
    ; just exit on error
    cmp eax, 0
    jl exit

accept: 
    ; int accept(int sockfd, struct sockaddr *addr, socklen_t *addrlen);
    push byte 0
    push byte 0
    push edi
    mov ecx, esp
    mov ebx, 5
    mov eax, 102
    int 80h

fork:
    mov esi, eax
    mov eax, 2
    int 80h
    cmp eax, 0
    jz read
    jmp accept

read:
    mov edx, 256
    mov ecx, buffer
    mov ebx, esi
    mov eax, 3
    int 80h

print:
    mov eax, 4
	mov ebx, 1
	mov eax, 4
    mov ecx, buffer
    mov edx, 256
	int 80h

exit:
    mov eax, 1
    mov ebx, 0

    int 80h
