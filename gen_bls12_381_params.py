modulus = 0x1a0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaaab
r_inv = 0x16ef2ef0c8e30b48286adb92d9d113e889f3fffcfffcfffd

def print_as_u256(u512):
    lower = u512 & (2**256-1)
    upper = u512 >> 256

    print("lower")
    print(hex(lower))
    print("upper")
    print(hex(upper))

print("modulus")
print_as_u256(modulus)
print("r_inv")
print_as_u256(r_inv)
