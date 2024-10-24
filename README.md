# Assembly Labs
This repo contains some x86-32bit assembly code I've written to learn about the linux programming interface, system calls, and operating systems. Find more info at my [blog](https://jackcarrick.net/blog).

Assemble and run each example with `nasm` and `ld` if using x86 architecture:
```sh
nasm -f elf -o my_program.o my_program.s
ld -m elf_i386 -o my_program my_program.o
./my_program
```
