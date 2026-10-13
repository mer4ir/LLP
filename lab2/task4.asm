%include "io64.inc"

section .rodata
    a:    dd 1.0
    x:    dd 0.5
    y:    dd 1.2
    half: dd 0.5

section .text
global main

main:
    ; ---------- z = a - x ----------
    fld dword[a]            ; стек: [a]
    fld dword[x]            ; стек: [x, a]
    fsub                    ; ST1 -= ST0, pop -> стек: [a - x] = [z]

    ; ---------- E = e^z = 2^(z*log2(e)) ----------
    fldl2e                  ; стек: [log2e, z]
    fmul                    ; стек: [z*log2e]  (показатель степени 2)
    fld1                    ; стек: [1, p]
    fld st1                 ; стек: [p, 1, p]
    fprem                   ; ST0 = дробная часть p
    f2xm1                   ; ST0 = 2^frac - 1
    fadd                    ; ST1(=1) += ST0, pop -> стек: [2^frac, p]
    fscale                  ; ST0 = 2^frac * 2^trunc(p) = 2^p
    fstp st1                ; стек: [E] = [e^z]

    ; ---------- ch = (E + 1/E) / 2 ----------
    fld1                    ; стек: [1, E]
    fld st1                 ; стек: [E, 1, E]
    fdiv                    ; ST1 /= ST0, pop -> стек: [1/E, E]
    fadd                    ; стек: [E + 1/E]
    fmul dword[half]        ; стек: [ch(z)]

    ; ---------- сравнение y <= ch ----------
    fld dword[y]            ; стек: [y, ch]
    fcomip st1              ; сравнить y (ST0) с ch (ST1), pop -> стек: [ch]

    ja false                ; y > ch -> условие ложно
    fstp st0                ; очистить стек x87 (стек пуст), потом вывод
    PRINT_DEC 4, 1
    jmp end
false:
    fstp st0
    PRINT_DEC 4, 0
end:
    xor eax, eax
    ret