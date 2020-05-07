{
    function memcpy_384(dst, src) {
        let hi := mload(src)
        let lo := mload(add(src, 32))
        mstore(dst, hi)
        mstore(add(dst, 32), lo)
    }

    // r <- x + y
    function f2m_add(x_0, x_1, y_0, y_1, r_0, r_1, modulus) {
        // r_0 <- x_0 + y_0
        // r_1 <- x_1 + y_1
        memcpy_384(r_0, x_0)
        memcpy_384(r_1, x_1)
        addmod384(r_0, y_0, modulus)
        addmod384(r_1, y_1, modulus)
    }

    // r <- x - y
    function f2m_sub(x_0, x_1, y_0, y_1, r_0, r_1, modulus) {
        memcpy_384(r_0, x_0)
        memcpy_384(r_1, x_1)
        submod384(r_0, y_0, modulus)
        submod384(r_1, y_1, modulus)
    }

    // r <- x * y
    function f2m_mul(x_0_offset, x_1_offset, y_0_offset, y_1_offset, r_0, r_1, modulus, inv, mem) {
        let A := mem
        let B := add(mem, 64)
        let C := add(B, 64)
        let D := add(C, 64)

        // TODO cover case where r == x or r == y

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
        // r_0 <- 0 - B
        mstore(x_0_offset,          0x0000000000000000000000000000000000000000000000000000000000000000)
        mstore(add(x_0_offset, 32), 0x0000000000000000000000000000000000000000000000000000000000000000)
        submod384(r_0, B, modulus)

        // B <- A + B
        addmod384(B, A, modulus)

        // C <- C - B 
        submod384(C, B, modulus)

        // r_1 <- C
        memcpy_384(r_1, C)
    }

	// R <- abc * ABC
	function f6m_mul(x_0, x_1, x_2,
					 y_0, y_1, y_2,
					 r_0, r_1, r_2, 
					 inv, modulus, arena) {

		let aA_0 := arena
		let aA_1 := add(aA_0, 64)

		let bB_0 := add(aA_1, 64)
		let bB_1 := add(bB_0, 64)

		let cC_0 := add(bB_1, 64)
		let cC_1 := add(cC_0, 64)

		arena := add(cC_1, 64)
		// all memory after 'arena' should be unused

		// aA <- a * A
    	f2m_mul(x_0, add(x_0, 64), y_0, add(y_0, 64), aA_0, aA_1, inv, modulus, arena)

        // add below line (same function call as above, to trigger stack-too-deep error)
        // f2m_mul(x_0, add(x_0, 64), y_0, add(y_0, 64), aA_0, aA_1, inv, modulus, arena)
	}

    let a := msize()

    // a_0 = 13ed51a99d037cd55a2fa85160fcf5d82c2bb3d746c86756c8aa63dbd13c328d15edddee18fd85985be2542890abf981
    mstore(a,          0x81f9ab902854e25b9885fd18eedded158d323cd1db63aac85667c846d7b32b2c)
    mstore(add(a, 32), 0xd8f5fc6051a82f5ad57c039da951ed1300000000000000000000000000000000)

    // a_1 = 13cce68eef65989a76ba5c8e56c8820cadf78b83c8315b7b9c7a9f00dda664b944bf45b82e9696b4845fd6846a18b0d3
    mstore(add(a, 64), 0xd3b0186a84d65f84b496962eb845bf44b964a6dd009f7a9c7b5b31c8838bf7ad)
    mstore(add(a, 96), 0x0c82c8568e5cba769a9865ef8ee6cc1300000000000000000000000000000000)

    let b := add(a, 128)

    // b_0 = 1435551e6ff298fd2687f88c1dbba7ae6f75b271e92098e2041cf951b852a15531d92f059ef88de74eae1bd66894f293
    // b_1 = 183ba80af1167cd0294a706c9e0dab21b6f4c01be217dbabeac7963ab9d4ae2e60514b7859717d5694d0e2f369931864

    let c := add(b, 128)
    // C_0 = 
    // C_1 = 

    /*
    A_0 := 000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
    A_1 := 000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
    */
    let A := add(c, 128)
    mstore(A,          0x0000000000000000000000000000000000000000000000000000000000000000)
    mstore(add(A, 32), 0x0000000000000000000000000000000000000000000000000000000000000000)
    mstore(add(A, 64), 0x0000000000000000000000000000000000000000000000000000000000000000)
    mstore(add(A, 96), 0x0000000000000000000000000000000000000000000000000000000000000000)


    let B := add(A, 128)
    // B_0 = 19311306bbf7a8a3dfc4bfd322c424447587e86969207effe6c338993b599e83848af99685c1ab185ce935628a32c28f
    // B_1 = 0ec6d7b5cff8f07d70eaf6c567f6f04ac5c5a43ede3a879778e67f339237073b02abecaad6cc7262b83e98414923f9fa

    let C := add(B, 128)
    // C_0
    // C_1

    let r_0 := add(C, 128)
    let r_1 := add(r_0, 128)
    let r_2 := add(r_1, 128)

    let bls12_mod := add(r_2, 128)
    mstore(bls12_mod,          0xabaafffffffffeb9ffff53b1feffab1e24f6b0f6a0d23067bf1285f3844b7764)
    mstore(add(bls12_mod, 32), 0xd7ac4b43b6a71b4b9ae67f39ea11011a00000000000000000000000000000000)

    let bls12_r_inv :=         0x89f3fffcfffcfffd

    f6m_mul(a, b, c, A, B, C, r_0, r_1, r_2, bls12_mod, bls12_r_inv, add(bls12_mod, 128)) 
}
