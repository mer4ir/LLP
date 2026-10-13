section .rodata
    eq_a: dd 2.0      ; параметр a уравнения
    eq_b: dd 0.5      ; параметр b уравнения (должен быть в [-1; 1])
    ten:  dd 10.0

section .bss
    eq_x: resd 1      ; результат: корень уравнения x

section .text
global main

main:
    ; ---------- theta = arccos(b) ----------
    fld1
    fld dword[eq_b]
    fmul st0, st0        ; ST0 = b^2
    fsub                 ; ST0 = 1 - b^2      (ST1(=1) -= ST0, pop)
    fsqrt                ; ST0 = sqrt(1-b^2)  = sin(theta)

    fld dword[eq_b]      ; ST0 = b = cos(theta), ST1 = sin(theta)
    fpatan                ; ST0 = atan2(sin(theta), cos(theta)) = theta = arccos(b)

    ; ---------- 10^theta ----------
    fld dword[ten]        ; ST0 = 10, ST1 = theta
    fyl2x                  ; ST0 = theta * log2(10)   (показатель степени 2)

    fld1                   ; ST0 = 1,           ST1 = показатель
    fld st1                ; ST0 = показатель(копия), ST1 = 1, ST2 = показатель
    fprem                  ; ST0 = дробная часть показателя (mod 1)
    f2xm1                  ; ST0 = 2^(дробная часть) - 1
    fadd                   ; ST0 = 2^(дробная часть)          (ST1(=1) += ST0, pop)
    fscale                 ; ST0 = ST0 * 2^floor(ST1=показатель) = 2^показатель = 10^theta
    fstp st1               ; убираем лишний показатель со стека; ST0 = 10^theta

    ; ---------- x = a + 10^theta ----------
    fadd dword[eq_a]
    fstp dword[eq_x]        ; сохранить результат, стек x87 пуст

    xor eax, eax
    ret