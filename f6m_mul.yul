
{
    // for testing?
    function eq_384(x_offset, y_offset) -> result {
        let x_0 := mload(x_offset)
        let x_1 := mload(add(x_offset, 256))
        
        let y_0 := mload(y_offset)
        let y_1 := mload(add(y_offset, 256))

        // TODO should zero the unused bits of X_1, Y_1 before comparison
        
        switch eq(eq(x_0, x_1), eq(y_0, y_1))
        case 0 { result := 0 }
        case 1 { result := 1 }
    }

    function f6m_mul(x_offset, y_offset, ret_offset, mod_offset, inv_offset) {
        // translate https://github.com/iden3/wasmsnark/blob/master/src/build_f3m.js#L125-L189
        
        let sizef1 := 48

        let a := x_offset
        let b := add(x_offset, sizef1) //x_offset + sizef1
        let c := add(b, sizef1)

        let A := y_offset
        let B := add(y_offset, sizef1)
        let C := add(B, sizef1)

        let r_0 := ret_offset
        let r_1 := add(ret_offset, sizef1)
        let r_2 := add(r_1, sizef1)

        if eq_384(a, b) {
            revert(0, 0)
        }

        // TODO figure out allocation for local variables aA, bB, ...

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
    }

	mstore(0, 0x44444444)
	mstore(48, 0x66666666)
	mstore(96, 0xffffff)
	addmod384(0, 48, 96)
	mulmodmont384(0, 48, 96, 0xf7f7f7f7)
    f6m_mul(0,48,96,96)
}
