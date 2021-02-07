



def zBody():
    global z1, z2, c1, c2
    tmp =  z1 * z1 - z2 * z2 + c1
    z2 = 2 * z1 * z2 + c2
    z1 = tmp
    print(z1)
    print(z2)


c1 = -2
c2 = -1
z1 = 0
z2 = 0

print(c1)
print(c2)
zBody()
zBody()
zBody()
zBody()