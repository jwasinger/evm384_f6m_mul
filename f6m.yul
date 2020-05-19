{
    function memcpy_384(dst, src) {
        let hi := mload(src)
        let lo := mload(add(src, 32))
        mstore(dst, hi)
        mstore(add(dst, 32), lo)
    }

    function mulNR2(x0, x1, r0, r1, modulus) {
        // r0 <- x0 - x1
        submod384(r0, x0, x1, modulus)
        // r1 <- x0 + x1
        addmod384(r1, x0, x1, modulus)
    }

    // r <- x + y
    function f2m_add(x_0, x_1, y_0, y_1, r_0, r_1, modulus, arena) {
        addmod384(r_0, x_0, y_0, modulus)
        addmod384(r_1, x_1, y_1, modulus)
    }

    // r <- x - y
    function f2m_sub(x_0, x_1, y_0, y_1, r_0, r_1, modulus, arena) {
        submod384(r_0, x_0, y_0, modulus)
        submod384(r_1, x_1, y_1, modulus)
    }

    // r <- x * y
    function f2m_mul(x, y, r, modulus, inv, mem) {
        
        let tmp := add(mem, 64)
        let tmp2 := add(tmp, 64)
        let zero := add(tmp2, 64)

        // TODO also cache x0y0 calculation

        // tmp2 = x1y1
        mulmodmont384(tmp2, add(x, 64), add(y, 64), modulus, inv)

        //r0 = mulNR(tmp2)
        submod384(r, zero, tmp2, modulus)

        // tmp = x0y0
        mulmodmont384(tmp, x, y, modulus, inv)

        //r0 = r0 + tmp (x0y0)
        addmod384(r, r, tmp, modulus)

        // r1 -------------------------------------

        // r1 = ((y0 + y1) * (x0 + x1)) - ((x0 * y0) + (x1 * y1))

        // tmp2 <- x1 * y1
        mulmodmont384(tmp2, add(x, 64), add(y, 64), modulus, inv)

        // tmp2 <- tmp (x0 * y0) + tmp2 (x1 * y1)
        addmod384(tmp2, tmp, tmp2, modulus)

        // tmp = y0 + y1
        addmod384(tmp, y, add(y, 64), modulus)

        // r1 = x0 + x1
        addmod384(add(r, 64), x, add(x, 64), modulus)

        // r1 <- r1 (x0 + x1) * tmp (y0 + y1)
        mulmodmont384(add(r, 64), add(r, 64), tmp, modulus, inv)

        // r1 = r1 [(x0 + x1) * (y0 + y1)] - tmp2 [(x0 * y0) + (x1 * y1)]
        submod384(add(r, 64), add(r, 64), tmp2, modulus)
    }

    function f6m_mul_r2(abc, ABC,aA,bB,cC,r2, modulus, inv, mem) {
        /* 
            r_2 <- ((a + c) * (A + C) - (a * A + c * C)) + bB
        */

        let tmp1 := mem
        let tmp2 := add(mem, 128)
        let tmp3 := add(tmp2, 128)

        let arena := add(tmp3, 128)

        // tmp1 <- a + c
        f2m_add(abc, add(abc, 64), add(abc, 256), add(abc, 320), tmp1, add(tmp1, 64), modulus, arena)

        // tmp2 <- A + C
        f2m_add(ABC, add(ABC, 64), add(ABC, 256), add(ABC, 320), tmp2, add(tmp2, 64), modulus, arena)

        // tmp3 <- tmp1 * tmp2
        f2m_mul(tmp1, tmp2, tmp3, modulus, inv, arena)

        // tmp1 <- aA + cC
        f2m_add(aA, add(aA, 64), cC, add(cC, 64), tmp1, add(tmp1, 64), modulus, arena)

        // tmp2 <- tmp3 - tmp1
        f2m_sub(tmp3, add(tmp3, 64), tmp1, add(tmp1, 64), tmp2, add(tmp2, 64), modulus, arena)

        // r_2 <- bB + tmp2 
        f2m_add(tmp2, add(tmp2, 64), bB, add(bB, 64), r2, add(r2, 64), modulus, arena)
    }


    /*
        r1 = ((a_b * A_B) - aA_bB) + mulNonResidue(cC)
    */
    function f6m_mul_r1(abc, ABC, aA, bB, cC, r1, modulus, inv, mem) {
        let tmp1 := mem
        let tmp2 := add(mem, 128)
        let tmp3 := add(tmp2, 128)
        let arena := add(tmp3, 128)

        // tmp1 <- a + b
        f2m_add(abc, add(abc, 64), add(abc, 128), add(abc, 192), tmp1, add(tmp1, 64), modulus, arena)
        
        // tmp2 <- A + B
        f2m_add(ABC, add(ABC, 64), add(ABC, 128), add(ABC, 192), tmp2, add(tmp2, 64), modulus, arena)

        // tmp3 <- tmp2 * tmp1
        f2m_mul(tmp2, tmp1, tmp3, modulus, inv, arena)

        // tmp1 <- aA * bB
        f2m_add(aA, add(aA, 64), bB, add(bB, 64), tmp1, add(tmp1, 64), modulus, arena)

        // tmp2 <- tmp3 - tmp1
        f2m_sub(tmp3, add(tmp3, 64), tmp1, add(tmp1, 64), tmp2, add(tmp2, 64), modulus, arena)

        // tmp1 <- mulNonResidue(cC)
        mulNR2(cC, add(cC, 64), tmp1, add(tmp1, 64), modulus)

        // r_1 <- tmp2 + tmp1
        f2m_add(tmp2, add(tmp2, 64), tmp1, add(tmp1, 64), r1, add(r1, 64), modulus, arena)
    }

    function f6m_mul_r0(abc, ABC, aA, bB, cC, r0, modulus, inv, mem) {
        /*
            r0 = aA + mulNonResidue((b + c) * (B + C) - (b * B + c * C))
        */

        let tmp1 := mem
        let tmp2 := add(mem, 128)
        let tmp3 := add(tmp2, 128)
        let arena := add(tmp3, 128)

        // tmp1 <- b + c
        f2m_add(add(abc, 128), add(abc, 192), add(abc, 256), add(abc, 320), tmp1, add(tmp1, 64), modulus, arena)

        // tmp2 <- B + C
        f2m_add(add(ABC, 128), add(ABC, 192), add(ABC, 256), add(ABC, 320), tmp2, add(tmp2, 64),  modulus, arena)

        // tmp3 <- tmp2 * tmp1
        f2m_mul(tmp1, tmp2, tmp3, modulus, inv, arena)

        // tmp1 <- bB + cC
        f2m_add(bB, add(bB, 64), cC, add(cC, 64), tmp1, add(tmp1, 64), modulus, arena)

        // tmp2 <- tmp3 - tmp1
        f2m_sub(tmp3, add(tmp3, 64), tmp1, add(tmp1, 64), tmp2, add(tmp2, 64), modulus, arena)

        // tmp3 <- mulnonresidue(tmp2)
        mulNR2(tmp2, add(tmp2, 64), tmp3, add(tmp3, 64), modulus)

        // r0 <- tmp3 + aA
        f2m_add(tmp3, add(tmp3, 64), aA, add(aA, 64), r0, add(r0, 64), modulus, arena)
    }

    // {r_0, r_1, r_2} <- {a, b, c} * {A, B, C}
    function f6m_mul(abc, ABC, r, modulus, inv, arena) {
        let aA := arena
        let bB := add(aA, 128)
        let cC := add(bB, 128)

        arena := add(cC, 128)
        // all memory after 'arena' should be unused

        // aA <- a * A
        f2m_mul(abc, ABC, aA, modulus, inv, arena)

        // bB <- b * B
        f2m_mul(add(abc, 128), add(ABC, 128), bB, modulus, inv, arena)

        // cC <- c * C
        f2m_mul(add(abc, 256), add(ABC, 256), cC, modulus, inv, arena)

        f6m_mul_r2(abc, ABC, aA, bB, cC, add(r, 256), modulus, inv, arena)
        f6m_mul_r1(abc, ABC, aA, bB, cC, add(r, 128), modulus, inv, arena)
        f6m_mul_r0(abc, ABC, aA, bB, cC, r, modulus, inv, arena)
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
            if eq(eq(mload(r_0), 0xf4f3f4e0a35068eaac665aee2e71f682aecd20923b420023b6d5420ba01ea982), false) {
                revert(0,32)
            }

            if eq(eq(mload(add(r_0, 32)), 0x87c314107a998a650ab3247ef39c920e00000000000000000000000000000000), false) {
                revert(0,0)
            }

            // check r_0_1
            if eq(eq(mload(add(r_0, 64)), 0x2c9620d993a22bade623d165a9f4aa648af87cb7292b7821c0fcd0adcd14ba65), false) {
                revert(0,0)
            }

            if eq(eq(mload(add(r_0, 96)), 0x5da54df2ad93262e24fc62bcd97e720800000000000000000000000000000000), false) {
                revert(0,0)
            }

            // check r_1_0
            if eq(eq(mload(r_1), 0xead1838e6c5e168543093c87eaeb576f940670026292dcb7a812600f4fb20a28), false) {
                revert(0,0)
            }

            if eq(eq(mload(add(r_1, 32)), 0x1be71ce1ef79f675e4a283b73906ca1700000000000000000000000000000000), false) {
                revert(0,0)
            }

            // check r_1_1 ==            0x9c8b2c76405445b20dd7635d562309f69c2c87601d9055a5e10df2ea1d28237fafd0d32f7e8c19d4cd5a3d1ef65b120b
            if eq(eq(mload(add(r_1, 64)), 0x9c8b2c76405445b20dd7635d562309f69c2c87601d9055a5e10df2ea1d28237f), false) {
                revert(0,0)
            }

            if eq(eq(mload(add(r_1, 96)), 0xafd0d32f7e8c19d4cd5a3d1ef65b120b00000000000000000000000000000000), false) {
                revert(0,0)
            }

            // r_2_0 == 0x40591ef0c74dbec983b7bef145a87957c1e09049dbc85fbb3e9bb1174892ee83294ef8c4a5954fffbff4ca6aca74c718
            if eq(eq(mload(r_2), 0x40591ef0c74dbec983b7bef145a87957c1e09049dbc85fbb3e9bb1174892ee83), false) {
                revert(0,0)
            }

            if eq(eq(mload(add(r_2, 32)), 0x294ef8c4a5954fffbff4ca6aca74c71800000000000000000000000000000000), false) {
                revert(0,0)
            }

            // check r_2_1
            if eq(eq(mload(add(r_2, 64)), 0x9b242b8f1c5d63bb525121bd68eda084ab7e6d015052d5adeb79ddb24091d2a8), false) {
                revert(0,0)
            }

            if eq(eq(mload(add(r_2, 96)), 0xe5b1da00212d0e6c11f01d237901130800000000000000000000000000000000), false) {
                revert(0,0)
            }
    }


    function test_f2m_mul() {
    /*
        8f2990f3e598f5b1b8f480a3c388306bc023fac151c0104d13ec3aa18159940272d1c8c528a1ce3bcaa280a8e735aa0d992d7a27906d4cd530b23a7e8c48c0778f8653fbc3332d63db24339d8bc65d7ee83b6e91c6550f5aceab102e88e918097299907146816f08c4c6a394e91374ed6ff3618a57358cfb124ee6ab4c560e5cac40700b41e2ee8674680728f0c5a618 *
        ecd347c808af644c7a3a971a556576f434e302b6b490004fb418a4a7da330a6743adeca931169b8b92e91df73ae1e11512a2829e11e843d764d5e3b80e75432d93f69b23ad79c38d43ebbc9bd2b17b9e903033351357b03602624762e5ad360dd7f9857dce663301f393f9fac66f5c49168494e0d20797a6c4f96327ed4fa47dd36d0078d217a712407d35046871d40f =

        1a984f235709ab3941e22b5e67d5ba892ce9242e227c0c6bb38aa1ace4d4b64aaba753d350d98f4c05570f525d67a901b1297e4e9ca0c757dfe693ea0d2f5216daeaa4ad06964e2f7c242200049d386d860b25d4718a2c4240fb89c90abe4e10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
    */
            let mem := msize()

            let bls12_mod := mem
            mstore(bls12_mod,          0xabaafffffffffeb9ffff53b1feffab1e24f6b0f6a0d23067bf1285f3844b7764)
            mstore(add(bls12_mod, 32), 0xd7ac4b43b6a71b4b9ae67f39ea11011a00000000000000000000000000000000)

            let bls12_r_inv :=         0x89f3fffcfffcfffd


            let x := add(bls12_mod, 128)
            mstore(x,          0x8f2990f3e598f5b1b8f480a3c388306bc023fac151c0104d13ec3aa181599402)
            mstore(add(x, 32), 0x72d1c8c528a1ce3bcaa280a8e735aa0d00000000000000000000000000000000)
            mstore(add(x, 64), 0x992d7a27906d4cd530b23a7e8c48c0778f8653fbc3332d63db24339d8bc65d7e)
            mstore(add(x, 96), 0xe83b6e91c6550f5aceab102e88e9180900000000000000000000000000000000)

            let y := add(x, 128)
            mstore(y,          0xecd347c808af644c7a3a971a556576f434e302b6b490004fb418a4a7da330a67)
            mstore(add(y, 32), 0x43adeca931169b8b92e91df73ae1e11500000000000000000000000000000000)
            mstore(add(y, 64), 0x12a2829e11e843d764d5e3b80e75432d93f69b23ad79c38d43ebbc9bd2b17b9e)
            mstore(add(y, 96), 0x903033351357b03602624762e5ad360d00000000000000000000000000000000)

            let r := add(y, 128)

            f2m_mul(x, y, r, bls12_mod, bls12_r_inv, add(r, 128))

            if eq(eq(mload(r), 0x1a984f235709ab3941e22b5e67d5ba892ce9242e227c0c6bb38aa1ace4d4b64a), false) {
                revert(0,0)
            }

            if eq(eq(mload(add(r, 32)), 0xaba753d350d98f4c05570f525d67a90100000000000000000000000000000000), false) {
                revert(0,0)
            }

            if eq(eq(mload(add(r, 64)), 0xb1297e4e9ca0c757dfe693ea0d2f5216daeaa4ad06964e2f7c242200049d386d), false) {
                revert(0,0)
            }

            if eq(eq(mload(add(r, 96)), 0x860b25d4718a2c4240fb89c90abe4e1000000000000000000000000000000000), false) {
                revert(0,0)
            }
    }

    test_f6m_mul()
}
