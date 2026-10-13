section .rodata
    v1: dd 1.0, 2.0, 3.0, 4.0
    v2: dd 5.0, 6.0, 7.0, 8.0

section .bss
    result_scalar: resd 1
    result_vector: resd 1

section .text
global main

main:
    ; ================= Способ 1: скалярные инструкции =================
    ; dot = v1[0]*v2[0] + v1[1]*v2[1] + v1[2]*v2[2] + v1[3]*v2[3]
    movss xmm0, [v1]
    mulss xmm0, [v2]            ; xmm0 = v1[0]*v2[0]

    movss xmm1, [v1+4]
    mulss xmm1, [v2+4]
    addss xmm0, xmm1            ; += v1[1]*v2[1]

    movss xmm1, [v1+8]
    mulss xmm1, [v2+8]
    addss xmm0, xmm1            ; += v1[2]*v2[2]

    movss xmm1, [v1+12]
    mulss xmm1, [v2+12]
    addss xmm0, xmm1            ; xmm0 = dot(v1,v2)

    ; |v1|
    movss xmm2, [v1]
    mulss xmm2, xmm2
    movss xmm3, [v1+4]
    mulss xmm3, xmm3
    addss xmm2, xmm3
    movss xmm3, [v1+8]
    mulss xmm3, xmm3
    addss xmm2, xmm3
    movss xmm3, [v1+12]
    mulss xmm3, xmm3
    addss xmm2, xmm3            ; xmm2 = |v1|^2
    sqrtss xmm2, xmm2           ; xmm2 = |v1|

    ; |v2|
    movss xmm3, [v2]
    mulss xmm3, xmm3
    movss xmm4, [v2+4]
    mulss xmm4, xmm4
    addss xmm3, xmm4
    movss xmm4, [v2+8]
    mulss xmm4, xmm4
    addss xmm3, xmm4
    movss xmm4, [v2+12]
    mulss xmm4, xmm4
    addss xmm3, xmm4            ; xmm3 = |v2|^2
    sqrtss xmm3, xmm3           ; xmm3 = |v2|

    mulss xmm2, xmm3            ; xmm2 = |v1| * |v2|
    divss xmm0, xmm2            ; xmm0 = cos(theta) (скалярный способ)

    movss [result_scalar], xmm0

    ; ================= Способ 2: векторные (packed) инструкции =================
    movups xmm0, [v1]           ; xmm0 = {v1[0], v1[1], v1[2], v1[3]}
    movups xmm1, [v2]           ; xmm1 = {v2[0], v2[1], v2[2], v2[3]}

    ; скалярное произведение через покомпонентное умножение + горизонтальное сложение
    movaps xmm2, xmm0
    mulps xmm2, xmm1            ; xmm2 = {v1[i]*v2[i]}
    haddps xmm2, xmm2           ; xmm2[0]=e0+e1, xmm2[1]=e2+e3
    haddps xmm2, xmm2           ; xmm2[0] = полная сумма = dot(v1,v2)

    ; |v1|
    movaps xmm3, xmm0
    mulps xmm3, xmm0            ; {v1[i]^2}
    haddps xmm3, xmm3
    haddps xmm3, xmm3           ; xmm3[0] = |v1|^2
    sqrtss xmm3, xmm3           ; xmm3[0] = |v1|

    ; |v2|
    movaps xmm4, xmm1
    mulps xmm4, xmm1            ; {v2[i]^2}
    haddps xmm4, xmm4
    haddps xmm4, xmm4           ; xmm4[0] = |v2|^2
    sqrtss xmm4, xmm4           ; xmm4[0] = |v2|

    mulss xmm3, xmm4            ; xmm3[0] = |v1| * |v2|
    divss xmm2, xmm3            ; xmm2[0] = cos(theta) (векторный способ)

    movss [result_vector], xmm2

    xor eax, eax
    ret