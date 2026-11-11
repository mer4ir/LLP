; ЛР №3, задание 2, сложный уровень (средний уровень обязателен вместе со
; сложным), вариант 1.
; Программа, вызывающая access1 из medium.a с параметрами, проходящими
; внутреннюю проверку (должна напечатать "Access granted").
;
; Восстановленная сигнатура (см. lab3_task2_restored_code.md для разбора):
;   namespace medium {
;       struct S {
;           int   magic;   // offset 0
;           char  flag;    // offset 4
;           float value;   // offset 8  (sizeof(S) == 12)
;       };
;       extern "C" void access1(const S& a, char b, float c);
;   }
;
; Условия прохождения (все одновременно):
;   a.magic == 0x58583336
;   a.flag  == 0
;   a.value > 1.0f
;   b > 0
;   (float)b > c
;
; Подобранные значения: a = {magic=0x58583336, flag=0, value=2.0f},
; b = 1, c = 0.0f.  Проверка: 1 > 0, и (float)1 = 1.0 > 0.0 = c — выполнено.
;
; Соглашение Microsoft x64: const S& a — указатель в RCX (позиция 1);
; char b — в регистре позиции 2 (RDX/DL); float c — в XMM-регистре
; позиции 3 (XMM2, т.к. для каждой позиции аргумента используется либо
; целочисленный, либо XMM-регистр из соответствующей пары, в зависимости
; от типа именно этого аргумента).
;
; ПРИМЕЧАНИЕ: не компилировалось и не линковалось с medium.a. Восстановленная
; логика проверена только чтением дизассемблированного кода, без запуска.

section .data
    s_med:
        dd 0x58583336      ; S.magic (offset 0)
        db 0               ; S.flag  (offset 4)
        db 0, 0, 0         ; выравнивание до offset 8 под float
        dd 2.0             ; S.value (offset 8), > 1.0 — условие выполнено

    c_arg: dd 0.0          ; float c = 0.0  (меньше, чем (float)b = 1.0)

section .text
    extern access1
    global main

main:
    push rbp
    mov rbp, rsp
    sub rsp, 32            ; теневое пространство для вызова access1

    lea rcx, [s_med]       ; const S& a = &s_med
    mov edx, 1             ; char b = 1  (используется низкий байт DL)
    movss xmm2, [c_arg]    ; float c = 0.0  (3-я позиция аргумента -> XMM2)

    call access1           ; должна напечатать "Access granted"

    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
