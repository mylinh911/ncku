#include <stdio.h>

extern int array_size; 
extern int array_addr[]; 

extern int _test_start[];

void bubbleSort(int arr[], int n) {
    int i, j, temp;
    for (i = 0; i < n - 1; i++) {
        for (j = 0; j < n - i - 1; j++) {
            if (arr[j] > arr[j + 1]) {
                // swap
                temp = arr[j];
                arr[j] = arr[j + 1];
                arr[j + 1] = temp;
            }
        }
    }
}

int main() {
    int size = array_size;
    int* array = array_addr;

    bubbleSort(array, size);

    for (int i = 0; i < size; i++) {
        _test_start[i] = array[i];
    }

    return 0;
}
