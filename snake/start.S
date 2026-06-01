.section .text.start
.global _start
_start:
    li sp, 0x1FF0
    call main
loop:
    j loop