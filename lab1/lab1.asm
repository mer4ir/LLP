; ЛР №1, вариант 1, сложный уровень.
; Задача: отсортировать введённый пользователем массив
; с помощью сортировки расчёской (comb sort).
; Версия 3: NASM, x86-64, SASM (io64.inc).
;
; По условию сложного уровня секции .data/.bss используются
; ТОЛЬКО для массива (arr) и текстовых констант для вывода;
; все скалярные переменные (n, i, gap, swapped, temp, idx)
; расположены на стеке в кадре функции main.

%include "io64.inc"

section .bss
    arr: resd 100          ; массив из не менее 100 элементов типа int

section .data
    msg_size:  db "Enter array size: ", 0
    msg_elems: db "Enter array elements: ", 0
    msg_sorted: db "Sorted array: ", 0
    msg_space: db " ", 0
    msg_nl:    db 10, 0

section .text
global main

main:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    ; Локальные переменные на стеке:
    ; [rbp-4]  - n
    ; [rbp-8]  - i
    ; [rbp-12] - gap
    ; [rbp-16] - swapped
    ; [rbp-20] - temp / idx (используются последовательно, не одновременно)

    ; ---------- Ввод размера массива ----------
    PRINT_STRING msg_size
    GET_DEC 4, eax
    mov [rbp-4], eax                 ; n = введённое число

    ; ---------- Ввод элементов массива ----------
    PRINT_STRING msg_elems
    mov dword [rbp-8], 0             ; i = 0
input_loop:
    mov eax, [rbp-8]
    cmp eax, [rbp-4]
    jge input_end
    GET_DEC 4, eax
    mov ecx, [rbp-8]                 ; полный регистр rcx для адресации
    mov [arr+rcx*4], eax             ; arr[i] = введённое число
    mov eax, [rbp-8]
    add eax, 1
    mov [rbp-8], eax                 ; i += 1
    jmp input_loop
input_end:

    ; ---------- Инициализация сортировки ----------
    mov eax, [rbp-4]
    mov [rbp-12], eax                ; gap = n
    mov dword [rbp-16], 1            ; swapped = 1

outer_loop:
    mov eax, [rbp-12]
    cmp eax, 1
    jg do_body                       ; if (gap > 1) goto do_body
    mov eax, [rbp-16]
    cmp eax, 0
    jne do_body                      ; if (swapped != 0) goto do_body
    jmp sort_end

do_body:
    ; gap = gap * 10 / 13  (целочисленное приближение gap /= 1.3)
    mov eax, [rbp-12]
    imul eax, eax, 10
    mov ecx, 13
    cdq
    idiv ecx
    mov [rbp-12], eax
    cmp dword [rbp-12], 1
    jge gap_ok
    mov dword [rbp-12], 1
gap_ok:
    mov dword [rbp-16], 0            ; swapped = 0
    mov dword [rbp-8], 0             ; i = 0

inner_loop:
    mov eax, [rbp-8]
    add eax, [rbp-12]                ; eax = i + gap = idx
    cmp eax, [rbp-4]
    jge inner_end                    ; if (idx >= n) goto inner_end
    mov [rbp-20], eax                ; idx сохраняем во временный слот

    mov ecx, [rbp-8]                 ; rcx = i
    mov eax, [arr+rcx*4]             ; eax = arr[i]

    mov edx, [rbp-20]                ; rdx = idx
    mov ebx, [arr+rdx*4]             ; ebx = arr[idx]

    cmp eax, ebx
    jle no_swap                      ; if (arr[i] <= arr[idx]) goto no_swap

    ; обмен местами arr[i] и arr[idx]
    mov [rbp-20], eax                ; временно используем ту же ячейку под temp
    ; (idx уже не нужен, пересчитаем при необходимости, но он есть в edx)
    mov ecx, [rbp-8]
    mov [arr+rcx*4], ebx             ; arr[i] = arr[idx]
    mov [arr+rdx*4], eax             ; arr[idx] = temp (старое arr[i])
    mov dword [rbp-16], 1            ; swapped = 1

no_swap:
    mov eax, [rbp-8]
    add eax, 1
    mov [rbp-8], eax                 ; i += 1
    jmp inner_loop
inner_end:
    jmp outer_loop

sort_end:
    ; ---------- Вывод отсортированного массива ----------
    PRINT_STRING msg_sorted
    mov dword [rbp-8], 0
print_loop:
    mov eax, [rbp-8]
    cmp eax, [rbp-4]
    jge print_end
    mov ecx, [rbp-8]
    mov eax, [arr+rcx*4]
    PRINT_DEC 4, eax
    PRINT_STRING msg_space
    mov eax, [rbp-8]
    add eax, 1
    mov [rbp-8], eax
    jmp print_loop
print_end:
    PRINT_STRING msg_nl

    mov rsp, rbp
    pop rbp
    xor eax, eax
    ret
