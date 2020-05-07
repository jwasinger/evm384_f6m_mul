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
        //return(x_1_offset, 64)

        // TODO: use x_1 instead of tmp variable C (to reduce memory usage) if possible

        // x_0 <- 0 - (x_1 * y_1)
        // x_1 <- (y_0 * y_1 * (x_0 + x_1)) - (x_0 * y_0 + x_1 * y_1)

        // tmp <- x_1 * y_1
        // tmp1 <- x_0
        // x_0 <- tmp1 - tmp

        // tmp1 <- tmp1 * y_0
        // tmp3 <- tmp * tmp1

        // tmp1 <- x_0
        // x_0 <- x_0 + x_1
        // x_0 <- x_0 * y_1
        // x_0 <- x_0 * y_0
        // x_0 <- x_0 - 
    }

	// R <- abc * ABC
	function f6m_mul(x,
					 y,
					 r, 
					 inv, modulus) {
    /*

        f6m_pseudocode:
         
        aA = a * A
        bB = b * B
        cC = c * C
        a_b = a + b
        A_B = A + B
        a_c = a + c
        A_C = A + C
        b_c = b + c
        B_C = B + C
    */


    /*
        aA_bB = aA + bB
        aA_cC = aA + cC
        bB_cC = bB + cC

        r_0 = b_c + B_C
        r_0 = r_0 - bB_cC

        r_0 = mulNonResidue(r_0)
        r_0 = aA + r_0
        
        r_1 = a_b * A_B
        r_1 = r_1 - aA_bB
        AUX = mulNonResidue(cC)
        r_1 = r_1 + AUX

        r_2 = a_c + A_C
        r_2 = r_2 - aA_cC
        r_2 = r_2 + bB
    */

 
    	let mem_end := msize()

		let aA_0 := mem_end
		let aA_1 := add(aA_0, 64)

		let bB_0 := add(aA_1, 64)
		let bB_1 := add(bB_0, 64)

		let cC_0 := add(bB_1, 64)
		let cC_1 := add(cC_0, 64)

		let arena := add(cC_1, 64)
		// all memory after 'arena' should be unused

		// aA <- a * A
		f2m_mul(x, add(x, 64), y, add(y, 64), aA_0, aA_1, inv, modulus, arena)

		/*
		// r2 = aA + cC + bB
		f2m_mul(b_0, b_1, B_0, B_1, bB_0, bB_1)
		f2m_mul(c_0, c_1, C_0, C_1, cC_0, cC_1)

		f2m_add(aA_0, aA_1, bB_0, bB_1, r_0_0, r_0_1)
		f2m_add(r_0_0, r_0_1, cC_0, cC_1, r_0_0, r_0_1)
		*/

	/*
	    r2 = aA + cC + bB
	    r1 = ((a_b * A_B) - aA_bB) + mulNonResidue(cC)
	    r0 = aA + mulNonResidue((b_c + B_C) - bBcC)
    */
	}

	// TODO: an f6m test case
}