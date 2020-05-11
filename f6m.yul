{
    function memcpy_384(dst, src) {
        let hi := mload(src)
        let lo := mload(add(src, 32))
        mstore(dst, hi)
        mstore(add(dst, 32), lo)
    }

    function mulNR2(x0, x1, r0, r1, modulus, arena) {
        memcpy_384(r0, x0)
        memcpy_384(r1, x1)

        // r0 <- x0 - x1
        submod384(r0, x1, modulus)
        // r1 <- x0 + x1
        addmod384(r1, x1, modulus)
    }

    // r <- x + y
    function f2m_add(x_0, x_1, y_0, y_1, r_0, r_1, modulus, arena) {
        memcpy_384(r_0, x_0)
        memcpy_384(r_1, x_1)
        addmod384(r_0, y_0, modulus)
        addmod384(r_1, y_1, modulus)
    }

    // r <- x - y
    function f2m_sub(x_0, x_1, y_0, y_1, r_0, r_1, modulus, arena) {
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
        mstore(r_0,          0x0000000000000000000000000000000000000000000000000000000000000000)
        mstore(add(r_0, 32), 0x0000000000000000000000000000000000000000000000000000000000000000)
        submod384(r_0, B, modulus)

        // r_0 <- r_0 + A
        addmod384(r_0, A, modulus)

        // B <- A + B
        addmod384(B, A, modulus)

        // C <- C - B 
        submod384(C, B, modulus)

        // r_1 <- C
        memcpy_384(r_1, C)
    }

	// {r_0, r_1, r_2} <- {a, b, c} * {A, B, C}
	function f6m_mul(abc, ABC, r, modulus, inv, arena) {
		let aA_0 := arena
		let aA_1 := add(aA_0, 64)

		let bB_0 := add(aA_1, 64)
		let bB_1 := add(bB_0, 64)

		let cC_0 := add(bB_1, 64)
		let cC_1 := add(cC_0, 64)

        let tmp1 := add(cC_1, 64)

		arena := add(tmp1, 128)
		// all memory after 'arena' should be unused

		// aA <- a * A
    	f2m_mul(abc, add(abc, 64), ABC, add(ABC, 64), aA_0, aA_1, modulus, inv, arena)

        // bB <- b * B
        f2m_mul(add(abc, 128), add(abc, 192), add(ABC, 128), add(ABC, 192), bB_0, bB_1, modulus, inv, arena)

        // cC <- c * C
        f2m_mul(add(abc, 256), add(abc, 320), add(ABC, 256), add(ABC, 320), cC_0, cC_1, modulus, inv, arena)

        /* 
            r_2 <- ((a + c) * (A + C) - (a * A + c * C)) + bB
        */

		// tmp1 <- a + c
        f2m_add(abc, add(abc, 64), add(abc, 256), add(abc, 320), tmp1, add(tmp1, 64), modulus, arena)

        // r_2 <- A + C
        f2m_add(ABC, add(ABC, 64), add(ABC, 256), add(ABC, 320), add(r, 256), add(r, 320), modulus, arena)
        
        // r_2 <- r_2 * tmp1
        f2m_mul(add(r, 256), add(r, 320), tmp1, add(tmp1, 64), add(r, 256), add(r, 320), modulus, inv, arena)

        // tmp1 <- aA + cC
        f2m_add(aA_0, aA_1, cC_0, cC_1, tmp1, add(tmp1, 64), modulus, arena)

        // r_2 <- r_2 - tmp1
        f2m_sub(add(r, 256), add(r, 320), tmp1, add(tmp1, 64), add(r, 256), add(r, 320), modulus, arena)

        // r_2 <- r_2 + bB
        f2m_add(add(r, 256), add(r, 320), bB_0, bB_1, add(r, 256), add(r, 320), modulus, arena)

        // return(add(r, 256), 128)

        /*
            r1 = ((a_b * A_B) - aA_bB) + mulNonResidue(cC)
        */

        // tmp1 <- a + b
        f2m_add(abc, add(abc, 64), add(abc, 128), add(abc, 192), tmp1, add(tmp1, 64), modulus, arena)
        
        // r_1 <- A + B
        f2m_add(ABC, add(ABC, 64), add(ABC, 128), add(ABC, 192), add(r, 128), add(r, 192), modulus, arena)

        // r_1 <- r_1 * tmp1
        f2m_mul(add(r, 128), add(r, 192), tmp1, add(tmp1, 64), add(r, 128), add(r, 192), modulus, inv, arena)

        // tmp1 <- aA * bB
        f2m_add(aA_0, aA_1, bB_0, bB_1, tmp1, add(tmp1, 64), modulus, arena)

        // r_1 <- r_1 - tmp1
        f2m_sub(add(r, 128), add(r, 192), tmp1, add(tmp1, 64), add(r, 128), add(r, 192), modulus, arena)

        // tmp1 <- mulNonResidue(cC)
        mulNR2(cC_0, cC_1, tmp1, add(tmp1, 64), modulus, arena)

        // r_1 <- r_1 + tmp1
        f2m_add(add(r, 128), add(r, 192), tmp1, add(tmp1, 64), add(r, 128), add(r, 192), modulus, arena)

        /*
            r0 = aA + mulNonResidue((b + c) * (B + C)) - (b * B + c * C))
        */

        // r_0 <- b + c
        f2m_add(add(abc, 128), add(abc, 192), add(abc, 256), add(abc, 320), r, add(r, 64), modulus, arena)

        // tmp1 <- B + C
        f2m_add(add(ABC, 128), add(ABC, 192), add(ABC, 256), add(ABC, 320), tmp1, add(tmp1, 64),  modulus, arena)

        // r_0 <- r_0 * tmp1
        f2m_mul(r, add(r, 64), tmp1, add(tmp1, 64), r, add(r, 64), modulus, inv, arena)

        // tmp1 <- bB + cC
        f2m_add(bB_0, bB_1, cC_0, cC_1, tmp1, add(tmp1, 64), modulus, arena)

        // r_0 seems to be correctly calculated until the following statements

        // r_0 <- r_0 - tmp1
        f2m_sub(r, add(r, 64), tmp1, add(tmp1, 64), r, add(r, 64), modulus, arena)

        // return(r, 128)
        // ^ this line causes "stack too deep" error

        // r_0 <- mulNonResidue(r_0)
        mulNR2(r, add(r, 64), r, add(r, 64), modulus, arena)

        // r_0 <- aA + r_0
        f2m_add(r, add(r, 64), aA_0, aA_1, r, add(r, 64), modulus, arena)
	}

    function test_f6m_mul() {
            let a := msize()

            /*
            p1 bytecode

            8f2990f3e598f5b1b8f480a3c388306bc023fac151c0104d13ec3aa18159940272d1c8c528a1ce3bcaa280a8e735aa0d992d7a27906d4cd530b23a7e8c48c0778f8653fbc3332d63db24339d8bc65d7ee83b6e91c6550f5aceab102e88e918097299907146816f08c4c6a394e91374ed6ff3618a57358cfb124ee6ab4c560e5cac40700b41e2ee8674680728f0c5a6180fd77f62b39eb952a0f8d21cec1f93b1d62dd7923aa86882ddf7dd4d3532b0b7ede8f3fc89fa4a79574067e2d9a9d2007a69de46b13d8cb4c4833224aaf9ef7ea6a48975ab35c6e123b8539ab84c381a2533401a73c4e79f47d714899d01ac13a9fa0b0d8156c36a1a9ddacb73ef278f4d149b560e88789f2bfeb9f708b6cc2f988927bfe0186d5bf9cb40cb07f21b18

            p2 bytecode

            ecd347c808af644c7a3a971a556576f434e302b6b490004fb418a4a7da330a6743adeca931169b8b92e91df73ae1e11512a2829e11e843d764d5e3b80e75432d93f69b23ad79c38d43ebbc9bd2b17b9e903033351357b03602624762e5ad360dd7f9857dce663301f393f9fac66f5c49168494e0d20797a6c4f96327ed4fa47dd36d0078d217a712407d35046871d40f2f1b767f6c1ec190eb76a0bce7906ad2e4a7548d03e8aa745e34e1bf49d83ad64c04f57fb4d31039cb4cf01987fda2137b3f8da2f2ae47885890b0d433a3eeed2f9f37cbcfc444e4f1d880390fcdb76518d558857be01b2b10a8010bcdc6d606319c02f6132c8a786377868b5825ada9a5fe303e9ae3b03ce56e90734a17ce970c88b321012cf8dabb58211e3d50f610
            */

            /*

            // values are in little-endian (as expected by the EVM384 opcodes)
            p1:
                (('8f2990f3e598f5b1b8f480a3c388306bc023fac151c0104d13ec3aa18159940272d1c8c528a1ce3bcaa280a8e735aa0d', '992d7a27906d4cd530b23a7e8c48c0778f8653fbc3332d63db24339d8bc65d7ee83b6e91c6550f5aceab102e88e91809'), ('7299907146816f08c4c6a394e91374ed6ff3618a57358cfb124ee6ab4c560e5cac40700b41e2ee8674680728f0c5a618', '0fd77f62b39eb952a0f8d21cec1f93b1d62dd7923aa86882ddf7dd4d3532b0b7ede8f3fc89fa4a79574067e2d9a9d200'), ('7a69de46b13d8cb4c4833224aaf9ef7ea6a48975ab35c6e123b8539ab84c381a2533401a73c4e79f47d714899d01ac13', 'a9fa0b0d8156c36a1a9ddacb73ef278f4d149b560e88789f2bfeb9f708b6cc2f988927bfe0186d5bf9cb40cb07f21b18'))
            p2:
                (('ecd347c808af644c7a3a971a556576f434e302b6b490004fb418a4a7da330a6743adeca931169b8b92e91df73ae1e115', '12a2829e11e843d764d5e3b80e75432d93f69b23ad79c38d43ebbc9bd2b17b9e903033351357b03602624762e5ad360d'), ('d7f9857dce663301f393f9fac66f5c49168494e0d20797a6c4f96327ed4fa47dd36d0078d217a712407d35046871d40f', '2f1b767f6c1ec190eb76a0bce7906ad2e4a7548d03e8aa745e34e1bf49d83ad64c04f57fb4d31039cb4cf01987fda213'), ('7b3f8da2f2ae47885890b0d433a3eeed2f9f37cbcfc444e4f1d880390fcdb76518d558857be01b2b10a8010bcdc6d606', '319c02f6132c8a786377868b5825ada9a5fe303e9ae3b03ce56e90734a17ce970c88b321012cf8dabb58211e3d50f610'))

            */

            mstore(a,          0x8f2990f3e598f5b1b8f480a3c388306bc023fac151c0104d13ec3aa181599402)
            mstore(add(a, 32), 0x72d1c8c528a1ce3bcaa280a8e735aa0d00000000000000000000000000000000)
            mstore(add(a, 64), 0x992d7a27906d4cd530b23a7e8c48c0778f8653fbc3332d63db24339d8bc65d7e)
            mstore(add(a, 96), 0xe83b6e91c6550f5aceab102e88e9180900000000000000000000000000000000)

            let b := add(a, 128)
            mstore(b,          0x7299907146816f08c4c6a394e91374ed6ff3618a57358cfb124ee6ab4c560e5c)
            mstore(add(b, 32), 0xac40700b41e2ee8674680728f0c5a61800000000000000000000000000000000)
            mstore(add(b, 64), 0x0fd77f62b39eb952a0f8d21cec1f93b1d62dd7923aa86882ddf7dd4d3532b0b7)
            mstore(add(b, 96), 0xede8f3fc89fa4a79574067e2d9a9d20000000000000000000000000000000000)

            let c := add(b, 128)
            mstore(c,          0x7a69de46b13d8cb4c4833224aaf9ef7ea6a48975ab35c6e123b8539ab84c381a)
            mstore(add(c, 32), 0x2533401a73c4e79f47d714899d01ac1300000000000000000000000000000000)
            mstore(add(c, 64), 0xa9fa0b0d8156c36a1a9ddacb73ef278f4d149b560e88789f2bfeb9f708b6cc2f)
            mstore(add(c, 96), 0x988927bfe0186d5bf9cb40cb07f21b1800000000000000000000000000000000)

            let A := add(c, 128)
            mstore(A,          0xecd347c808af644c7a3a971a556576f434e302b6b490004fb418a4a7da330a67)
            mstore(add(A, 32), 0x43adeca931169b8b92e91df73ae1e11500000000000000000000000000000000)
            mstore(add(A, 64), 0x12a2829e11e843d764d5e3b80e75432d93f69b23ad79c38d43ebbc9bd2b17b9e)
            mstore(add(A, 96), 0x903033351357b03602624762e5ad360d00000000000000000000000000000000)

            let B := add(A, 128)
            mstore(B,          0xd7f9857dce663301f393f9fac66f5c49168494e0d20797a6c4f96327ed4fa47d)
            mstore(add(B, 32), 0xd36d0078d217a712407d35046871d40f00000000000000000000000000000000)
            mstore(add(B, 64), 0x2f1b767f6c1ec190eb76a0bce7906ad2e4a7548d03e8aa745e34e1bf49d83ad6)
            mstore(add(B, 96), 0x4c04f57fb4d31039cb4cf01987fda21300000000000000000000000000000000)

            let C := add(B, 128)
            mstore(C,          0x7b3f8da2f2ae47885890b0d433a3eeed2f9f37cbcfc444e4f1d880390fcdb765)
            mstore(add(C, 32), 0x18d558857be01b2b10a8010bcdc6d60600000000000000000000000000000000)
            mstore(add(C, 64), 0x319c02f6132c8a786377868b5825ada9a5fe303e9ae3b03ce56e90734a17ce97)
            mstore(add(C, 96), 0x0c88b321012cf8dabb58211e3d50f61000000000000000000000000000000000)

            let r_0 := add(C, 128)
            let r_1 := add(r_0, 128)
            let r_2 := add(r_1, 128)

            let bls12_mod := add(r_2, 128)
            mstore(bls12_mod,          0xabaafffffffffeb9ffff53b1feffab1e24f6b0f6a0d23067bf1285f3844b7764)
            mstore(add(bls12_mod, 32), 0xd7ac4b43b6a71b4b9ae67f39ea11011a00000000000000000000000000000000)

            let bls12_r_inv :=         0x89f3fffcfffcfffd

            f6m_mul(a, A, r_0, bls12_mod, bls12_r_inv, add(bls12_mod, 128)) 

            // check r_0_0

            // check r_0_1
            
            // check r_1_0
            if eq(eq(mload(r_1), 0xead1838e6c5e168543093c87eaeb576f940670026292dcb7a812600f4fb20a28), false) {
                revert(0,0)
            }

            if eq(eq(mload(add(r_1, 32)), 0x1be71ce1ef79f675e4a283b73906ca1700000000000000000000000000000000), false) {
                revert(0,0)
            }

            // check r_1_1

            // r_2_0 == 0x40591ef0c74dbec983b7bef145a87957c1e09049dbc85fbb3e9bb1174892ee83294ef8c4a5954fffbff4ca6aca74c718
            if eq(eq(mload(r_2), 0x40591ef0c74dbec983b7bef145a87957c1e09049dbc85fbb3e9bb1174892ee83), false) {
                revert(0,0)
            }

            if eq(eq(mload(add(r_2, 32)), 0x294ef8c4a5954fffbff4ca6aca74c71800000000000000000000000000000000), false) {
                revert(0,0)
            }

            // check r_2_1

            // assert(r_2_1 == 0x9b242b8f1c5d63bb525121bd68eda084ab7e6d015052d5adeb79ddb24091d2a8e5b1da00212d0e6c11f01d23790113)
    }

    test_f6m_mul()
}
