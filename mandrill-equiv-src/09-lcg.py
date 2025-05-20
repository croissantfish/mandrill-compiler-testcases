mod = 214748 * 10000 + 3647
b = 65537
c = 7
seed = int(input())
num = 20
i = 0
while (i < num):
    seed = (seed * b + c) % mod
    print(seed)
    i = i + 1

