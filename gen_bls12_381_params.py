modulus = "0x1a0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaaab"

def hexBswap(hex_str):
    if len(hex_str) % 2 is not 0:
            hex_str = "0" + hex_str
    ba = bytearray.fromhex(hex_str)
    ba.reverse() # swap endianness
    hex_str = hex(int.from_bytes(ba, byteorder='big'))
    hex_str = hex_str[2:]
    while len(hex_str) < 16:
        hex_str = "0{}".format(hex_str)
    return hex_str

def print_as_u256(u512):
    lower = u512 & (2**256-1)
    upper = u512 >> 256

    print("lower")
    print(hex(lower))
    print("upper")
    print(hex(upper))

def formatMstore(value):
    hex_str = hexBswap(value)
    assert len(hex_str) == 96, "result should be 384 bits in size"
    first = hex_str[0:64]
    second = hex_str[64:96] + '0'*32
    print("mstore(x,          0x{})".format(first))
    print("mstore(add(x, 64), 0x{})".format(second))

import pdb; pdb.set_trace()
print(hexBswap(modulus[2:]))
# print("modulus")
# print_as_u256(modulus)
# print("r_inv")
# print_as_u256(r_inv)
