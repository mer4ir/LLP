/* ЛР №1, вариант 1, сложный уровень.
 * Задача: отсортировать введённый пользователем массив
 * с помощью сортировки расчёской (comb sort).
 * Версия 1: обычный код на C.
 */
#include <stdio.h>

#define MAX_SIZE 100

int arr[MAX_SIZE]; /* массив хранится как глобальная переменная */

int main() {
    int n;

    printf("Enter array size: ");
    scanf("%d", &n);

    printf("Enter %d elements: ", n);
    for (int i = 0; i < n; i++) {
        scanf("%d", &arr[i]);
    }

    int gap = n;
    int swapped = 1;

    while (gap > 1 || swapped) {
        gap = gap * 10 / 13;   /* целочисленное приближение gap /= 1.3 */
        if (gap < 1) gap = 1;

        swapped = 0;
        for (int i = 0; i + gap < n; i++) {
            if (arr[i] > arr[i + gap]) {
                int temp = arr[i];
                arr[i] = arr[i + gap];
                arr[i + gap] = temp;
                swapped = 1;
            }
        }
    }

    printf("Sorted array: ");
    for (int i = 0; i < n; i++) {
        printf("%d ", arr[i]);
    }
    printf("\n");

    return 0;
}
