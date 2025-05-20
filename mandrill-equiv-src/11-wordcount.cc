#include <cstdio>
#include <cstring>
#include <cctype>

int main(int argc, char *argv[]) {
    int cnt = 0;
    bool haschar = false;
    for (char c = getchar(); c != EOF; c = getchar()) {
        if ((c == ' ') || (c == '\n')){
            if (haschar) {
                cnt = cnt + 1;
                haschar = false;
            }
        } else {
            haschar = true;
        }
    }
    printf("%d\n", cnt);
}
