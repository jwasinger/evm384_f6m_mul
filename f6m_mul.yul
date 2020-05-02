
{
    //let sizef1 := 64
    // for testing?
    function eq_384(x_offset, y_offset) -> result {
        let x_0 := mload(x_offset)
        let x_1 := mload(add(x_offset, 64))
        
        let y_0 := mload(y_offset)
        let y_1 := mload(add(y_offset, 64))

        // TODO should zero the unused bits of X_1, Y_1 before comparison
        
        switch eq(eq(x_0, x_1), eq(y_0, y_1))
        case 0 { result := 0 }
        case 1 { result := 1 }
    }

    function memcpy_384(dst_offset, src_offset) {
        let src_0 := mload(src_offset)
        let src_1 := mload(add(src_offset, 64))

        // mask out the last 16 bytes 
        src_1 := and(src_1, 115792089237316195423570985008687907853269984665640564039457584007913129574400)
        mstore(dst_offset, src_0)
        mstore(add(dst_offset, 64), src_1)
    }

    function f6m_mul(x_offset, y_offset, ret_offset, mod_offset, inv_offset) {
        // translate https://github.com/iden3/wasmsnark/blob/master/src/build_f3m.js#L125-L189
        
        // store 384 bit points in 512 bits

        /*
        let sizef1 := 64
        let a := x_offset
        let b := add(x_offset, sizef1)
        let c := add(b, sizef1)

        let A := y_offset
        let B := add(y_offset, sizef1)
        let C := add(B, sizef1)

        let r_0 := ret_offset
        let r_1 := add(ret_offset, sizef1)
        let r_2 := add(r_1, sizef1)
        */

        let bls12_mod := msize()
        mstore(bls12_mod, 0x64774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaaab)
        mstore(add(bls12_mod, 32), 0x1a0111ea397fe69a4b1ba7b6434bacd7)

        let bls12_r_inv := add(bls12_mod, 64)
        mstore(bls12_r_inv, 0x16ef2ef0c8e30b48286adb92d9d113e889f3fffcfffcfffd)
        mstore(add(bls12_r_inv, 32), 0x0)

        // TODO figure out allocation for local variables aA, bB, ...

        let mem_end := add(bls12_r_inv, 64)
        
        /*
        let aA := msize()
        let bB := add(aA, sizef1)
        let cC := add(bB, sizef1)
        let a_b := add(cC, sizef1)
        let A_B := add(a_b, sizef1)
        let a_c := add(A_B, sizef1)
        let A_C := add(a_c, sizef1)
        let b_c := add(A_C, sizef1)
        let B_C := add(b_c, sizef1)
        */

/*
        // aA <- a
        memcpy_384(mem_end, x_offset)

        // aA <- aA * A
        mulmodmont384(mem_end, y_offset, bls12_mod, bls12_r_inv)

        // bB <- b
        memcpy_384(add(mem_end, 64), add(x_offset, 64))

        // bB <- bB * B
        mulmodmont384(add(mem_end, 64), add(y_offset, 64), bls12_mod, bls12_r_inv)
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

    /*
    test case from websnark (https://github.com/iden3/wasmsnark/blob/master/test/bls12381.js#L217):

    '[["0","0"],["1","0"],["0","1"]]'
    *
    '[["0","0"],["1","0"],["0","1"]]'
    =
    '[["4002409555221667393417789825735904156556882819939007885332058136124031650490837864442687629129015664037894272559785","2"],["4002409555221667393417789825735904156556882819939007885332058136124031650490837864442687629129015664037894272559786","4002409555221667393417789825735904156556882819939007885332058136124031650490837864442687629129015664037894272559786"],["1","0"]]'   
    */

    let sizef2 := 64
    let x := msize()
    let y := add(x, sizef2)
    
	mstore(x, 0x0)
	mstore(add(x, 32), 0x1)

	mstore(96, 0x01)
	mstore(144, 0x00)

	mstore(192, 0x00)
	mstore(240, 0x00)

    f6m_mul(x, 48, 96, 96, 96)

    // TODO assert correct result
}
