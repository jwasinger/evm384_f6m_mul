
{
    function memcpy_384(dst, src) {
        let hi := mload(src)
        let lo := mload(add(src, 32))
        mstore(dst, hi)
        mstore(add(dst, 32), lo)
    }

    function f2m_mul(x_0_offset, x_1_offset, y_0_offset, y_1_offset, modulus, inv, mem) {
        let A := mem
        let B := add(mem, 64)
        let C := add(B, 64)
        let D := add(C, 64)

        // A <- x_0 * y_0
        memcpy_384(A, x_0_offset)
        mulmodmont384(A, y_0_offset, modulus, inv)

        // B <- x_1 * y_1
        memcpy_384(B, x_1_offset)
        mulmodmont384(B, y_1_offset, modulus, inv)

        // C <- x_0 + x_1
        memcpy_384(C, x_0_offset)
        addmod384(C, x_1_offset, modulus)

        // D <- y_0 + y_1
        memcpy_384(D, y_0_offset)
        addmod384(D, y_1_offset, modulus)

        // C <- D * C
        mulmodmont384(C, D, modulus, inv)

        // f1m_mulNonresidue = f1m_neg(val) = 0 - val 
        // x_0 <- 0 - B
        mstore(x_0_offset,          0x0000000000000000000000000000000000000000000000000000000000000000)
        mstore(add(x_0_offset, 32), 0x0000000000000000000000000000000000000000000000000000000000000000)
        submod384(x_0_offset, B, modulus)

        // B <- A + B
        addmod384(B, A, modulus)

        // C <- C - B 
        submod384(C, B, modulus)

        // x_1 <- C
        memcpy_384(x_1_offset, C)
        return(x_1_offset, 64)

        // TODO: use x_1 instead of tmp variable C (to reduce memory usage) if possible
    }

    let x_offset := msize()

    // x_0 = 0x0083fd8e7e80dae507d3a975f0ef25a2bbefb5e96e0d495fe7e6856caa0a635a597cfa1f5e369c5a4c730af860494c4a
    mstore(x_offset,            0x4a4c4960f80a734c5a9c365e1ffa7c595a630aaa6c85e6e75f490d6ee9b5efbb)
    mstore(add(x_offset, 32),   0xa225eff075a9d307e5da807e8efd830000000000000000000000000000000000)

    // x_1 = 0x0b2bc2a163de1bf2e7175850a43ccaed79495c4ec93da33a86adac6a3be4eba018aa270a2b1461dcadc0fc92df64b05d
    mstore(add(x_offset, 64),   0x5db064df92fcc0addc61142b0a27aa18a0ebe43b6aacad863aa33dc94e5c4979)
    mstore(add(x_offset, 96),   0xedca3ca4505817e7f21bde63a1c22b0b00000000000000000000000000000000)

    let y_offset := msize()

    // y_0 = 0x15f65ec3fa80e4935c071a97a256ec6d77ce5853705257455f48985753c758baebf4000bc40c0002760900000002fffd
    mstore(y_offset,            0xfdff02000000097602000cc40b00f4ebba58c7535798485f455752705358ce77)
    mstore(add(y_offset, 32),   0x6dec56a2971a075c93e480fac35ef61500000000000000000000000000000000)

    // y_1 = 000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
    mstore(add(y_offset, 64),   0x0000000000000000000000000000000000000000000000000000000000000000)
    mstore(add(y_offset, 96),   0x0000000000000000000000000000000000000000000000000000000000000000)

    // TODO: is memory already zeroed out if i read from this offset ^?

    // result should be 
    // x_0 = 000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
    // x_1 = 5db064df92fcc0addc61142b0a27aa18a0ebe43b6aacad863aa33dc94e5c4979edca3ca4505817e7f21bde63a1c22b00

    let bls12_mod := msize()
    mstore(bls12_mod,          0xabaafffffffffeb9ffff53b1feffab1e24f6b0f6a0d23067bf1285f3844b7764)
    mstore(add(bls12_mod, 32), 0xd7ac4b43b6a71b4b9ae67f39ea11011a00000000000000000000000000000000)

    let bls12_r_inv :=         0x89f3fffcfffcfffd 

    let mem := msize()

    f2m_mul(x_offset, add(x_offset, 64), y_offset, add(y_offset, 64), bls12_mod, bls12_r_inv, mem)
}
