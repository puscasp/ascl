.global main

.section .data
msg:    .asciz "Hello, ARM world!\n"

.section .text
main:
    ldr r0, =msg       @ Load the address of the string into r0 (argument to puts)
    bl printf            @ Call the puts function

    mov r7, #1         @ Exit syscall number
    mov r0, #0         @ Exit code
    svc #0             @ Trigger the syscall