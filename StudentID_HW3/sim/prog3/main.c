#include <stdio.h>

extern int div1;
extern int div2;
extern int _test_start[];

int mod_calc(int a, int b) {
    return a - (a / b) * b;
}

int gcd_recursive(int a, int b) {
    if (b == 0) {
        return a;
    }
    return gcd_recursive(b, mod_calc(a, b));
}

int main() {
    int a = div1;
    int b = div2;
    
    _test_start[0] = gcd_recursive(a, b);
    return 0;
}