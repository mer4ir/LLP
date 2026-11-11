; ЛР №3, задание 1, сложный уровень.
; Та же программа, что и в lab3_task1_x64.asm, но для x86-32 (cdecl).
;
; Отличия от x86-64 версии:
;  - аргументы передаются на стеке (PUSH в обратном порядке), а не в регистрах;
;  - стек от аргументов очищает ВЫЗЫВАЮЩАЯ функция (ADD ESP, N после CALL);
;  - нет требования к 16-байтному выравниванию и теневому пространству
;    (для x86 выравнивание стека — 4 байта, раздел 2.1 методички);
;  - используются 32-битные регистры (EAX/ECX/EDX), т.к. регистров меньше,
;    чем в x86-64, значения чаще перечитываются из памяти вместо
;    удержания в регистрах.
;
; ПРИМЕЧАНИЕ: не компилировалось и не запускалось. Дополнительно проверь
; в SASM, под каким именно символом нужно объявить точку входа для 32-битной
; сборки — в разных версиях SASM использовалось то "global main", то
; отдельный макрос вроде CMAIN (методичка упоминает CMAIN в разделе 3.6
; применительно к анализу через IDA). Если "global main" не слинкуется,
; попробуй "global _main" или посмотри, что генерирует шаблон нового
; 32-битного проекта SASM по умолчанию.

%include "io32.inc"

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
    push ebp
    mov ebp, esp
    sub esp, 32

    ; Локальные переменные (на стеке):
    ; [ebp-4]  - n
    ; [ebp-8]  - i
    ; [ebp-12] - gap
    ; [ebp-16] - swapped
    ; [ebp-20] - idx (i + gap)
    ; [ebp-24] - arr (указатель на массив, от malloc)
    ; [ebp-28] - a_i (временное значение arr[i])
    ; [ebp-32] - a_idx (временное значение arr[idx])

    ; ---------- "Enter array size: " ----------
    push msg_size
    call printf
    add esp, 4

    ; ---------- scanf("%d", &n) ----------
    lea eax, [ebp-4]
    push eax
    push fmt_in
    call scanf
    add esp, 8

    ; ---------- arr = (int*)malloc(n * sizeof(int)) ----------
    mov eax, [ebp-4]
    imul eax, eax, 4
    push eax
    call malloc
    add esp, 4
    mov [ebp-24], eax

    ; ---------- "Enter array elements: " ----------
    push msg_elems
    call printf
    add esp, 4

    ; ---------- ввод массива ----------
    mov dword [ebp-8], 0          ; i = 0
.input_loop:
    mov eax, [ebp-8]
    cmp eax, [ebp-4]
    jge .input_end

    mov eax, [ebp-24]             ; arr
    mov ecx, [ebp-8]              ; i
    lea eax, [eax + ecx*4]        ; &arr[i]
    push eax
    push fmt_in
    call scanf
    add esp, 8

    mov eax, [ebp-8]
    add eax, 1
    mov [ebp-8], eax
    jmp .input_loop
.input_end:

    ; ---------- инициализация сортировки ----------
    mov eax, [ebp-4]
    mov [ebp-12], eax             ; gap = n
    mov dword [ebp-16], 1         ; swapped = 1

.outer_loop:
    mov eax, [ebp-12]
    cmp eax, 1
    jg .do_body
    mov eax, [ebp-16]
    cmp eax, 0
    jne .do_body
    jmp .sort_end

.do_body:
    mov eax, [ebp-12]
    imul eax, eax, 10
    mov ecx, 13
    cdq
    idiv ecx
    mov [ebp-12], eax
    cmp dword [ebp-12], 1
    jge .gap_ok
    mov dword [ebp-12], 1
.gap_ok:
    mov dword [ebp-16], 0
    mov dword [ebp-8], 0

.inner_loop:
    mov eax, [ebp-8]
    add eax, [ebp-12]
    cmp eax, [ebp-4]
    jge .inner_end
    mov [ebp-20], eax             ; idx = i + gap

    mov eax, [ebp-24]             ; arr
    mov ecx, [ebp-8]              ; i
    mov edx, [eax + ecx*4]        ; edx = arr[i]
    mov [ebp-28], edx             ; a_i = arr[i]

    mov eax, [ebp-24]             ; arr
    mov ecx, [ebp-20]             ; idx
    mov edx, [eax + ecx*4]        ; edx = arr[idx]
    mov [ebp-32], edx             ; a_idx = arr[idx]

    mov eax, [ebp-28]             ; a_i
    mov edx, [ebp-32]             ; a_idx
    cmp eax, edx
    jle .no_swap                  ; if (a_i <= a_idx) goto no_swap

    mov eax, [ebp-24]
    mov ecx, [ebp-8]
    mov edx, [ebp-32]             ; a_idx
    mov [eax + ecx*4], edx        ; arr[i] = a_idx

    mov eax, [ebp-24]
    mov ecx, [ebp-20]
    mov edx, [ebp-28]             ; a_i
    mov [eax + ecx*4], edx        ; arr[idx] = a_i

    mov dword [ebp-16], 1         ; swapped = 1

.no_swap:
    mov eax, [ebp-8]
    add eax, 1
    mov [ebp-8], eax
    jmp .inner_loop
.inner_end:
    jmp .outer_loop

.sort_end:
    push msg_sorted
    call printf
    add esp, 4

    mov dword [ebp-8], 0
.print_loop:
    mov eax, [ebp-8]
    cmp eax, [ebp-4]
    jge .print_end

    mov eax, [ebp-24]
    mov ecx, [ebp-8]
    mov edx, [eax + ecx*4]
    push edx
    push fmt_out
    call printf
    add esp, 8

    mov eax, [ebp-8]
    add eax, 1
    mov [ebp-8], eax
    jmp .print_loop
.print_end:
    push fmt_nl
    call printf
    add esp, 4

    ; ---------- free(arr) ----------
    push dword [ebp-24]
    call free
    add esp, 4

    xor eax, eax
    mov esp, ebp
    pop ebp
    ret
