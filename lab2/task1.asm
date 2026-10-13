section .rodata
    x:     dd 1.5           ; аргумент, 0 < x < 2

    c_one: dd 1.0
    c_two: dd 2.0
    c3:    dd 0.33333334    ; 1/3
    c5:    dd 0.2           ; 1/5
    c7:    dd 0.14285715    ; 1/7
    c9:    dd 0.11111111    ; 1/9
    c11:   dd 0.09090909    ; 1/11

section .bss
    result: resd 1          ; сюда попадёт ln(x)

section .text
global main

main:
    ; t = (x - 1) / (x + 1)
    movss xmm0, [x]
    movss xmm2, xmm0
    subss xmm0, [c_one]     ; xmm0 = x - 1
    addss xmm2, [c_one]     ; xmm2 = x + 1
    divss xmm0, xmm2        ; xmm0 = t

    movss xmm2, xmm0
    mulss xmm2, xmm2        ; xmm2 = t^2

    ; схема Горнера
    movss xmm1, [c11]
    mulss xmm1, xmm2
    addss xmm1, [c9]
    mulss xmm1, xmm2
    addss xmm1, [c7]
    mulss xmm1, xmm2
    addss xmm1, [c5]
    mulss xmm1, xmm2
    addss xmm1, [c3]
    mulss xmm1, xmm2
    addss xmm1, [c_one]     ; xmm1 = 1 + t2/3 + t2^2/5 + ...

    mulss xmm1, xmm0        ; * t
    mulss xmm1, [c_two]     ; * 2

    movss [result], xmm1

    xor eax, eax
    ret
