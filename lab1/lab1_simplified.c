/* ЛР №1, вариант 1, сложный уровень.
 * Задача: отсортировать введённый пользователем массив
 * с помощью сортировки расчёской (comb sort).
 * Версия 2: упрощённый C (приближен к ассемблеру):
 *  - составные операции разбиты на простые;
 *  - циклы заменены на if + goto;
 *  - if/else заменены на цепочки if + goto.
 */
#include <stdio.h>

#define MAX_SIZE 100

int arr[MAX_SIZE]; /* массив хранится как глобальная переменная */

int main() {
    int n;
    int i;
    int gap;
    int swapped;
    int temp;
    int idx;
    int a_i;
    int a_idx;

    printf("Enter array size: ");
    scanf("%d", &n);

    printf("Enter array elements: ");
    i = 0;
input_loop:
    if (i >= n) goto input_end;
    scanf("%d", &arr[i]);
    i += 1;
    goto input_loop;
input_end:

    gap = n;
    swapped = 1;

outer_loop:
    if (gap > 1) goto do_body;
    if (swapped != 0) goto do_body;
    goto sort_end;

do_body:
    gap = gap * 10;
    gap = gap / 13;
    if (gap >= 1) goto gap_ok;
    gap = 1;
gap_ok:
    swapped = 0;
    i = 0;

inner_loop:
    idx = i + gap;
    if (idx >= n) goto inner_end;

    a_i = arr[i];
    a_idx = arr[idx];
    if (a_i <= a_idx) goto no_swap;

    temp = a_i;
    arr[i] = a_idx;
    arr[idx] = temp;
    swapped = 1;

no_swap:
    i += 1;
    goto inner_loop;
inner_end:
    goto outer_loop;

sort_end:
    printf("Sorted array: ");
    i = 0;
print_loop:
    if (i >= n) goto print_end;
    printf("%d ", arr[i]);
    i += 1;
    goto print_loop;
print_end:
    printf("\n");

    return 0;
}
