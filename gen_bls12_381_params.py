modulus = "0x1a0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaaab"

abc = "8f2990f3e598f5b1b8f480a3c388306bc023fac151c0104d13ec3aa18159940272d1c8c528a1ce3bcaa280a8e735aa0d992d7a27906d4cd530b23a7e8c48c0778f8653fbc3332d63db24339d8bc65d7ee83b6e91c6550f5aceab102e88e918097299907146816f08c4c6a394e91374ed6ff3618a57358cfb124ee6ab4c560e5cac40700b41e2ee8674680728f0c5a6180fd77f62b39eb952a0f8d21cec1f93b1d62dd7923aa86882ddf7dd4d3532b0b7ede8f3fc89fa4a79574067e2d9a9d2007a69de46b13d8cb4c4833224aaf9ef7ea6a48975ab35c6e123b8539ab84c381a2533401a73c4e79f47d714899d01ac13a9fa0b0d8156c36a1a9ddacb73ef278f4d149b560e88789f2bfeb9f708b6cc2f988927bfe0186d5bf9cb40cb07f21b18"
ABC = "ecd347c808af644c7a3a971a556576f434e302b6b490004fb418a4a7da330a6743adeca931169b8b92e91df73ae1e11512a2829e11e843d764d5e3b80e75432d93f69b23ad79c38d43ebbc9bd2b17b9e903033351357b03602624762e5ad360dd7f9857dce663301f393f9fac66f5c49168494e0d20797a6c4f96327ed4fa47dd36d0078d217a712407d35046871d40f2f1b767f6c1ec190eb76a0bce7906ad2e4a7548d03e8aa745e34e1bf49d83ad64c04f57fb4d31039cb4cf01987fda2137b3f8da2f2ae47885890b0d433a3eeed2f9f37cbcfc444e4f1d880390fcdb76518d558857be01b2b10a8010bcdc6d606319c02f6132c8a786377868b5825ada9a5fe303e9ae3b03ce56e90734a17ce970c88b321012cf8dabb58211e3d50f610"

def split_f6(f6):
    size_f1 = 96
    size_f2 = 192

    a = f6[0:size_f2]
    a_0 = a[:size_f1]
    a_1 = a[size_f1:]

    b = f6[size_f2:-size_f2]
    b_0 = b[:size_f1]
    b_1 = b[size_f1:]

    c = f6[-size_f2:]
    c_0 = c[:size_f1]
    c_1 = c[size_f1:]

    return ((a_0, a_1), (b_0, b_1), (c_0, c_1))

print("p1")
print(split_f6(abc))
print("p2")
print(split_f6(ABC))

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

def endian_swap(hex_str):
    assert len(hex_str) % 2 == 0
    result = ''
    for i in reversed(range(0,len(hex_str)+1, 2)):
        result += hex_str[i:i+2]
    return result

def print_as_u256(u512):
    lower = u512 & (2**256-1)
    upper = u512 >> 256

    print("lower")
    print(hex(lower))
    print("upper")
    print(hex(upper))

def formatMstore(hex_str):
    # hex_str = endian_swap(hex_str)
    first = hex_str[0:64]
    second = hex_str[64:96] + '0'*32
    print("mstore(x,          0x{})".format(first))
    print("mstore(add(x, 32), 0x{})".format(second))

import pdb; pdb.set_trace()
print(hexBswap(modulus[2:]))
# formatMstore("8f2990f3e598f5b1b8f480a3c388306bc023fac151c0104d13ec3aa18159940272d1c8c528a1ce3bcaa280a8e735aa0d")
# print("modulus")
# print_as_u256(modulus)
# print("r_inv")
# print_as_u256(r_inv)
