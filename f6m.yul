{
	// R <- abc * ABC
	function f6m_mul(a_0,   a_1,   b_0,   b_1,   c_0,   c_1,
					 A_0,   A_1,   B_0,   B_1,   C_0,   C_1,
					 r_0_0, r_0_1, r_1_0, r_1_1, r_2_0, r_2_1,
					 inv, modulus) {
	/*
            cd.call(f1mPrefix + "_mul", a, A, aA),
            cd.call(f1mPrefix + "_mul", b, B, bB),
            cd.call(f1mPrefix + "_mul", c, C, cC),

            cd.call(f1mPrefix + "_add", a, b, a_b),
            cd.call(f1mPrefix + "_add", A, B, A_B),
            cd.call(f1mPrefix + "_add", a, c, a_c),
            cd.call(f1mPrefix + "_add", A, C, A_C),
            cd.call(f1mPrefix + "_add", b, c, b_c),
            cd.call(f1mPrefix + "_add", B, C, B_C),

            cd.call(f1mPrefix + "_add", aA, bB, aA_bB),
            cd.call(f1mPrefix + "_add", aA, cC, aA_cC),
            cd.call(f1mPrefix + "_add", bB, cC, bB_cC),

            cd.call(f1mPrefix + "_mul", b_c, B_C, r0),
            cd.call(f1mPrefix + "_sub", r0, bB_cC, r0),
            cd.call(mulNonResidueFn, r0, r0),
            cd.call(f1mPrefix + "_add", aA, r0, r0),

            cd.call(f1mPrefix + "_mul", a_b, A_B, r1),
            cd.call(f1mPrefix + "_sub", r1, aA_bB, r1),
            cd.call(mulNonResidueFn, cC, AUX),
            cd.call(f1mPrefix + "_add", r1, AUX, r1),

            cd.call(f1mPrefix + "_mul", a_c, A_C, r2),
            cd.call(f1mPrefix + "_sub", r2, aA_cC, r2),
            cd.call(f1mPrefix + "_add", r2, bB, r2),
	*/
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

	    r2 = aA + cC + bB
	    r1 = ((a_b * A_B) - aA_bB) + mulNonResidue(cC)
	    r0 = aA + mulNonResidue((b_c + B_C) - bBcC)
	}

	let aA := &bytes[0x00..0]
	let bB := &bytes[0x00..0]
	let cC := &bytes[0x00..0]

	/*
	tmp variables defined here
	*/

	let arena := &bytes[0x00...0]

	f2m_mul(a_0, a_1, A_0, A_1, aA_0, aA_1)
	f2m_mul(b_0, b_1, B_0, B_1, bB_0, bB_1)
	f2m_mul(c_0, c_1, C_0, C_1, cC_0, cC_1)

	f2m_add(aA_0, aA_1, bB_0, bB_1, r_0_0, r_0_1)
	f2m_add(r_0_0, r_0_1, cC_0, cC_1, r_0_0, r_0_1)
}