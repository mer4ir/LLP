; ЛР №3, задание 1, сложный уровень.
; Доработка ЛР1 (сортировка расчёской), вариант 1:
;  - все макросы SASM (GET_DEC/PRINT_DEC/PRINT_STRING) заменены на
;    вызовы printf/scanf из стандартной библиотеки C;
;  - все скалярные переменные — локальные переменные на стеке;
;  - массив НЕ лежит в .data/.bss: память под него выделяется
;    динамически через malloc и освобождается через free;
;  - кадр стека стандартный: [адрес возврата]-[сохранённый rbp]-[локальные
;    переменные], без каких-либо дополнительных трюков (раздел 2.4 методички).
;
; Версия для x86-64, соглашение Microsoft x64 (используется SASM/MinGW
; на Windows): целочисленные аргументы в RCX, RDX, R8, R9 по порядку,
; 32 байта теневого пространства перед каждым вызовом, стек выровнен
; по 16 байт в момент CALL.
;
; ПРИМЕЧАНИЕ: код не компилировался и не запускался (в среде, где он
; писался, нет NASM/MinGW); проверь сборку и работу в SASM самостоятельно.
;
; ПРИМЕЧАНИЕ 2: строки форматов для printf/scanf лежат в .data как
; константы (а не как буферы для хранения данных программы) — по той же
; логике, что и в ЛР1/ЛР2: запрет методички касается буферов ПОД ДАННЫЕ
; программы (в первую очередь — массива), а не литералов для вызовов
; стандартной библиотеки. Если преподаватель трактует это строже, строки
; можно передать через непосредственные байты на стеке — но это сильно
; усложнит код без увеличения его корректности.

%include "io64.inc"

section .data
    msg_size:   db "Enter array size: ", 0
    msg_elems:  db "Enter array elements: ", 0
    msg_sorted: db "Sorted array: ", 0
    fmt_in:     db "%d", 0
    fmt_out:    db "%d ", 0
    fmt_nl:     db 10, 0

section .text
    CEXTERN printf
    CEXTERN scanf
    CEXTERN malloc
    CEXTERN free
    global main

main:
    push rbp
    mov rbp, rsp
    sub rsp, 80              ; 32 байта теневого пространства + 48 байт локальных переменных (16-выровнено)

    ; Локальные переменные (на стеке):
    ; [rbp-8]  - n (размер массива)
    ; [rbp-16] - i (индекс/счётчик)
    ; [rbp-24] - gap (шаг сортировки расчёской)
    ; [rbp-32] - swapped (флаг обмена)
    ; [rbp-40] - idx (i + gap, временная)
    ; [rbp-48] - arr (указатель на массив, полученный от malloc)

    ; ---------- "Enter array size: " ----------
    lea rcx, [msg_size]
    call printf

    ; ---------- scanf("%d", &n) ----------
    lea rcx, [fmt_in]
    lea rdx, [rbp-8]
    call scanf

    ; ---------- arr = (int*)malloc(n * sizeof(int)) ----------
    mov eax, [rbp-8]
    imul eax, eax, 4
    movsxd rcx, eax
    call malloc
    mov [rbp-48], rax

    ; ---------- "Enter array elements: " ----------
    lea rcx, [msg_elems]
    call printf

    ; ---------- ввод массива ----------
    mov dword [rbp-16], 0        ; i = 0
.input_loop:
    mov eax, [rbp-16]
    cmp eax, [rbp-8]
    jge .input_end

    mov rax, [rbp-48]            ; arr
    movsxd rdx, dword [rbp-16]   ; i
    lea rdx, [rax + rdx*4]       ; &arr[i]
    lea rcx, [fmt_in]
    call scanf

    mov eax, [rbp-16]
    add eax, 1
    mov [rbp-16], eax
    jmp .input_loop
.input_end:

    ; ---------- инициализация сортировки ----------
    mov eax, [rbp-8]
    mov [rbp-24], eax            ; gap = n
    mov dword [rbp-32], 1        ; swapped = 1

.outer_loop:
    mov eax, [rbp-24]
    cmp eax, 1
    jg .do_body                  ; if (gap > 1) goto do_body
    mov eax, [rbp-32]
    cmp eax, 0
    jne .do_body                 ; if (swapped != 0) goto do_body
    jmp .sort_end

.do_body:
    ; gap = gap * 10 / 13  (целочисленное приближение gap /= 1.3)
    mov eax, [rbp-24]
    imul eax, eax, 10
    mov ecx, 13
    cdq
    idiv ecx
    mov [rbp-24], eax
    cmp dword [rbp-24], 1
    jge .gap_ok
    mov dword [rbp-24], 1
.gap_ok:
    mov dword [rbp-32], 0        ; swapped = 0
    mov dword [rbp-16], 0        ; i = 0

.inner_loop:
    mov eax, [rbp-16]
    add eax, [rbp-24]            ; idx = i + gap
    cmp eax, [rbp-8]
    jge .inner_end
    mov [rbp-40], eax            ; сохранить idx

    mov r8, [rbp-48]             ; r8 = arr
    movsxd r9, dword [rbp-16]    ; r9 = i
    mov eax, [r8 + r9*4]         ; eax = arr[i]

    movsxd r10, dword [rbp-40]   ; r10 = idx
    mov r11d, [r8 + r10*4]       ; r11d = arr[idx]

    cmp eax, r11d
    jle .no_swap                 ; if (arr[i] <= arr[idx]) goto no_swap

    mov [r8 + r9*4], r11d        ; arr[i] = arr[idx]
    mov [r8 + r10*4], eax        ; arr[idx] = старое arr[i]
    mov dword [rbp-32], 1        ; swapped = 1

.no_swap:
    mov eax, [rbp-16]
    add eax, 1
    mov [rbp-16], eax
    jmp .inner_loop
.inner_end:
    jmp .outer_loop

.sort_end:
    ; ---------- "Sorted array: " ----------
    lea rcx, [msg_sorted]
    call printf

    mov dword [rbp-16], 0
.print_loop:
    mov eax, [rbp-16]
    cmp eax, [rbp-8]
    jge .print_end

    mov rax, [rbp-48]
    movsxd rdx, dword [rbp-16]
    mov edx, [rax + rdx*4]       ; edx = arr[i] (адрес считается по старому rdx, затем edx перезаписывается результатом — это нормально и безопасно)
    lea rcx, [fmt_out]
    call printf

    mov eax, [rbp-16]
    add eax, 1
    mov [rbp-16], eax
    jmp .print_loop
.print_end:
    lea rcx, [fmt_nl]
    call printf

    ; ---------- free(arr) ----------
    mov rcx, [rbp-48]
    call free

    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
