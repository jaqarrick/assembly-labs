; Program that accepts and writes to an incoming request
section .data
    response db 'HTTP/1.1 200 OK', 0Dh, 0Ah, 'Content-Type: text/html', 0Dh, 0Ah, 'Content-Length: 24', 0Dh, 0Ah, 0Dh, 0Ah, 'Hello from the server!', 0Dh, 0Ah, 0h
    response_length equ $ - response
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
    ; first two args are optional so we'll set to zero
    push byte 0
    push byte 0
    ; edi holds the fd for socket
    push edi
    mov ecx, esp
    ; subroutine ACCEPT call
    mov ebx, 5
    mov eax, 102
    int 80h

fork:
    ; create a child process that handles the incoming connection
    mov esi, eax
    mov eax, 2
    int 80h
    cmp eax, 0
    jz write
    jmp accept

write:
    ; respond to request by simply writing to the socket fd
    mov ebx, esi
    mov ecx, response
    mov edx, response_length
    mov eax, 4
    int 80h

close:
    ; close the request by closing the fd
    mov ebx, esi
    mov eax, 6
    int 80h

exit:
    mov eax, 1
    mov ebx, 0

    int 80h
