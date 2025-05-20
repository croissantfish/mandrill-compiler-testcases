#include <cstdio>

int main() {
    bool prefixprinted = false;
    for (char c = getchar(); c != EOF; c = getchar()) {
        if ((c == '+') || (c == '-') || (c == '*') || (c == '/')) {
            if (prefixprinted) {
                printf("]\n");
                prefixprinted = false;
            }
            printf("[op:%c]\n", c);
        }
        if ((c >= '0') && (c <= '9')) {
            if (!prefixprinted) {
                printf("[digit:");
                prefixprinted = true;
            }
            putchar(c);
        }
        if ((c == ' ') || (c == '\n')) {
            if (prefixprinted) {
                printf("]\n");
                prefixprinted = false;
            }
        }
    }
}