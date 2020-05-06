
{
    function test_mulmodmont384() {
        let bls12_mod := msize()
        /*
            Correct result should be:
            mulmodmont384
            x = 17f1d3a73197d7942695638c4fa9ac0fc3688c4f9774b905a14e3a3f171bac586c55e83ff97a1aeffb3af00adb22c6bb
            y = 11988fe592cae3aa9a793e85b519952d67eb88a9939d83c08de5476c4c95b6d50a76e6a609d104f1f4df1f341c341746
            mod = 1a0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaaab
            inv= 0a76e6a609d104f1f4df1f341c341746000000000000000016ef2ef0c8e30b48286adb92d9d113e889f3fffcfffcfffd
            result = 120177419e0bfb75edce6ecc21dbf440f0ae6acdf3d0e747154f95c7143ba1c17817fc679976fff55cb38790fd530c16
        */

        // mstore(bls12_mod,          0x1a0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f624)
        // mstore(add(bls12_mod, 32), 0x1eabfffeb153ffffb9feffffffffaaab00000000000000000000000000000000)
        
        // correct little-endian modulus
        mstore(bls12_mod,          0xabaafffffffffeb9ffff53b1feffab1e24f6b0f6a0d23067bf1285f3844b7764)
        mstore(add(bls12_mod, 32), 0xd7ac4b43b6a71b4b9ae67f39ea11011a00000000000000000000000000000000)

        let bls12_r_inv :=         0x89f3fffcfffcfffd 

        let value_1 := add(bls12_mod, 64)
        mstore(value_1,            0xbbc622db0af03afbef1a7af93fe8556c58ac1b173f3a4ea105b974974f8c68c3)
        mstore(add(value_1, 32),   0x0faca94f8c63952694d79731a7d3f11700000000000000000000000000000000)

        let value_2 := add(value_1, 64)
        mstore(value_2,            0x4617341c341fdff4f104d109a6e6760ad5b6954c6c47e58dc0839d93a988eb67)
        mstore(add(value_2, 32),   0x2d9519b5853e799aaae3ca92e58f981100000000000000000000000000000000)

        mulmodmont384(value_1, value_2, bls12_mod, bls12_r_inv)

        return(value_1, 64)
    }

    function memcpy_384(dst, src) {
        let hi := mload(src)
        let lo := mload(add(src, 32))
        mstore(dst, hi)
        mstore(add(dst, 32), lo)
    }

    function f2m_mul(x_offset, y_offset, mod, mem) {
        /*
        A <- x_0 + y_0
        B <- x_1 + y_1
        C <- x_0 + x_1
        D <- y_0 + y_1
        C <- C + D
        */

        let A := mem
        let B := add(mem, 64)
        let C := add(B, 64)

        // A <- x_0 + y_0
        mempy_384(A, x_offset)
        addmod384(A, y_offset, mod)

        // B <- x_1 + y_1
        memcpy_384(B, add(x_offset, 64))
        addmod384(A, add(y_offset, 64), mod)

        // C <- x_0 + x_1
        memcpy_384(C, x_offset)
        addmod384(C, add(x_offset, 64), mod)

        // D <- y_0 + y_1
        memcpy(D, y_offset)
        addmod384(D, add(y_offset, 64), mod)

        // C <- D + C
        addmod384(C, D)

        return(C, 64)
    }

/*
mulmodmont384
   x = 0083fd8e7e80dae507d3a975f0ef25a2bbefb5e96e0d495fe7e6856caa0a635a597cfa1f5e369c5a4c730af860494c4a
  y = 15f65ec3fa80e4935c071a97a256ec6d77ce5853705257455f48985753c758baebf4000bc40c0002760900000002fffd
  mod = 1a0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaaab
  inv= 0a76e6a609d104f1f4df1f341c341746000000000000000016ef2ef0c8e30b48286adb92d9d113e889f3fffcfffcfffd
  result = 0083fd8e7e80dae507d3a975f0ef25a2bbefb5e96e0d495fe7e6856caa0a635a597cfa1f5e369c5a4c730af860494c4a

mulmodmont384
   x = 0b2bc2a163de1bf2e7175850a43ccaed79495c4ec93da33a86adac6a3be4eba018aa270a2b1461dcadc0fc92df64b05d
  y = 000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
  mod = 1a0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaaab
  inv= 0a76e6a609d104f1f4df1f341c341746000000000000000016ef2ef0c8e30b48286adb92d9d113e889f3fffcfffcfffd
  result = 000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
*/
    let x_offset := msize();

    // x_0 = 0x0083fd8e7e80dae507d3a975f0ef25a2bbefb5e96e0d495fe7e6856caa0a635a597cfa1f5e369c5a4c730af860494c4a
    mstore(x_offset,            0x4a4c4960f80a734c5a9c365e1ffa7c595a630aaa6c85e6e75f490d6ee9b5efbb)
    mstore(add(x_offset, 32),   0xa225eff075a9d307e5da807e8efd830000000000000000000000000000000000)

    // x_1 = 0x0b2bc2a163de1bf2e7175850a43ccaed79495c4ec93da33a86adac6a3be4eba018aa270a2b1461dcadc0fc92df64b05d
    mstore(add(x_offset, 64),   0x5db064df92fcc0addc61142b0a27aa18a0ebe43b6aacad863aa33dc94e5c4979)
    mstore(add(x_offset, 96),   0xedca3ca4505817e7f21bde63a1c22b0b00000000000000000000000000000000)

    let y_offset := msize();

    // y_0 = 0x15f65ec3fa80e4935c071a97a256ec6d77ce5853705257455f48985753c758baebf4000bc40c0002760900000002fffd
    mstore(y_offset,            0xfdff02000000097602000cc40b00f4ebba58c7535798485f455752705358ce77)
    mstore(add(y_offset, 32),   0x6dec56a2971a075c93e480fac35ef61500000000000000000000000000000000)

    // y_1 = 000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
    mstore(add(y_offset, 32),   0x0000000000000000000000000000000000000000000000000000000000000000)
    mstore(add(y_offset, 96),   0x0000000000000000000000000000000000000000000000000000000000000000)

    // TODO: is memory already zeroed out if i read from this offset ^?

    let mem_heap := msize()

    test_f2m_mul(x_offset, y_offset, mem_heap)
}
