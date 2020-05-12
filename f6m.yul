{

    //let bls12_mod := msize()
    //mstore(bls12_mod,          0xabaafffffffffeb9ffff53b1feffab1e24f6b0f6a0d23067bf1285f3844b7764)
    //mstore(add(bls12_mod, 32), 0xd7ac4b43b6a71b4b9ae67f39ea11011a00000000000000000000000000000000)

    // bls12_mod is at mem position 0

    function memcpy_384(dst, src) {
        let hi := mload(src)
        let lo := mload(add(src, 32))
        mstore(dst, hi)
        mstore(add(dst, 32), lo)
    }

    function mulNR2(x0, x1, r0, r1, arena) {
        let x0c := arena
        memcpy_384(x0c, x0) // copy x0 to x0c
        memcpy_384(r0, x0)
        memcpy_384(r1, x1)

        // r0 <- x0 - x1
        submod384(r0, x1, 0)
        // r1 <- x0 + x1
        addmod384(r1, x0c, 0)
    }

    // r <- x + y
    function f2m_add(x_0, x_1, y_0, y_1, r_0, r_1) {
        memcpy_384(r_0, x_0)
        memcpy_384(r_1, x_1)
        addmod384(r_0, y_0, 0)
        addmod384(r_1, y_1, 0)
    }

    // r <- x - y
    function f2m_sub(x_0, x_1, y_0, y_1, r_0, r_1) {
        memcpy_384(r_0, x_0)
        memcpy_384(r_1, x_1)
        submod384(r_0, y_0, 0)
        submod384(r_1, y_1, 0)
    }

    // r <- x * y
    function f2m_mul(x_0_offset, x_1_offset, y_0_offset, y_1_offset, r_0, r_1, mem) {
        let A := mem
        let B := add(mem, 64)
        let C := add(B, 64)
        let D := add(C, 64)

        let bls12_r_inv := 0x89f3fffcfffcfffd

        // A <- x_0 * y_0
        memcpy_384(A, x_0_offset)
        mulmodmont384(A, y_0_offset, 0, bls12_r_inv)

        // B <- x_1 * y_1
        memcpy_384(B, x_1_offset)
        mulmodmont384(B, y_1_offset, 0, bls12_r_inv)

        // C <- x_0 + x_1
        memcpy_384(C, x_0_offset)
        addmod384(C, x_1_offset, 0)

        // D <- y_0 + y_1
        memcpy_384(D, y_0_offset)
        addmod384(D, y_1_offset, 0)

        // C <- D * C
        mulmodmont384(C, D, 0, bls12_r_inv)

        // f1m_mulNonresidue = f1m_neg(val) = 0 - val 
        // r_0 <- 0 - B
        mstore(r_0,          0x0000000000000000000000000000000000000000000000000000000000000000)
        mstore(add(r_0, 32), 0x0000000000000000000000000000000000000000000000000000000000000000)
        submod384(r_0, B, 0)

        // r_0 <- r_0 + A
        addmod384(r_0, A, 0)

        // B <- A + B
        addmod384(B, A, 0)

        // C <- C - B 
        submod384(C, B, 0)

        // r_1 <- C
        memcpy_384(r_1, C)
    }

    // {r_0, r_1, r_2} <- {a, b, c} * {A, B, C}
    function f6m_mul(abc, ABC, r, arena) {
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
        f2m_mul(abc, add(abc, 64), ABC, add(ABC, 64), aA_0, aA_1, arena)

        // bB <- b * B
        f2m_mul(add(abc, 128), add(abc, 192), add(ABC, 128), add(ABC, 192), bB_0, bB_1, arena)

        // cC <- c * C
        f2m_mul(add(abc, 256), add(abc, 320), add(ABC, 256), add(ABC, 320), cC_0, cC_1, arena)

        /* 
            r_2 <- ((a + c) * (A + C) - (a * A + c * C)) + bB
        */

        // tmp1 [a_c] <- a + c
        f2m_add(abc, add(abc, 64), add(abc, 256), add(abc, 320), tmp1, add(tmp1, 64))

        // r_2 [A_C] <- A + C
        f2m_add(ABC, add(ABC, 64), add(ABC, 256), add(ABC, 320), add(r, 256), add(r, 320))
        
        // r_2 <- r_2 * tmp1 [a_c]
        f2m_mul(add(r, 256), add(r, 320), tmp1, add(tmp1, 64), add(r, 256), add(r, 320), arena)

        // tmp1 [aA_cC] <- aA + cC
        f2m_add(aA_0, aA_1, cC_0, cC_1, tmp1, add(tmp1, 64))

        // r_2 <- r_2 - tmp1 [aA_cC]
        f2m_sub(add(r, 256), add(r, 320), tmp1, add(tmp1, 64), add(r, 256), add(r, 320))

        // r_2 <- r_2 + bB
        f2m_add(add(r, 256), add(r, 320), bB_0, bB_1, add(r, 256), add(r, 320))

        // return(add(r, 256), 128)

        /*
            r1 = ((a_b * A_B) - aA_bB) + mulNonResidue(cC)
        */

        // tmp1 [a_b] <- a + b
        f2m_add(abc, add(abc, 64), add(abc, 128), add(abc, 192), tmp1, add(tmp1, 64))
        
        // r_1 [A_B] <- A + B
        f2m_add(ABC, add(ABC, 64), add(ABC, 128), add(ABC, 192), add(r, 128), add(r, 192))

        // r_1 <- r_1 [A_B] * tmp1 [a_b]
        f2m_mul(add(r, 128), add(r, 192), tmp1, add(tmp1, 64), add(r, 128), add(r, 192), arena)

        // tmp1 [aA_bB] <- aA * bB
        f2m_add(aA_0, aA_1, bB_0, bB_1, tmp1, add(tmp1, 64))

        // r_1 <- r_1 - tmp1 [aA_bB]
        f2m_sub(add(r, 128), add(r, 192), tmp1, add(tmp1, 64), add(r, 128), add(r, 192))

        // tmp1 [AUX] <- mulNonResidue(cC)
        mulNR2(cC_0, cC_1, tmp1, add(tmp1, 64), arena)

        // r_1 <- r_1 + tmp1 [AUX]
        f2m_add(add(r, 128), add(r, 192), tmp1, add(tmp1, 64), add(r, 128), add(r, 192))

        /*
            r0 = aA + mulNonResidue((b + c) * (B + C)) - (b * B + c * C))
        */

        // r_0 [b_c] <- b + c
        f2m_add(add(abc, 128), add(abc, 192), add(abc, 256), add(abc, 320), r, add(r, 64))

        // tmp1 [B_C] <- B + C
        f2m_add(add(ABC, 128), add(ABC, 192), add(ABC, 256), add(ABC, 320), tmp1, add(tmp1, 64))

        // r_0 <- r_0 [b_c] * tmp1 [B_C]
        f2m_mul(r, add(r, 64), tmp1, add(tmp1, 64), r, add(r, 64), arena)

        // tmp1 [bB_cC] <- bB + cC
        f2m_add(bB_0, bB_1, cC_0, cC_1, tmp1, add(tmp1, 64))

        // r_0 seems to be correctly calculated until the following statements

        // r_0 <- r_0 - tmp1 [bB_cC]
        f2m_sub(r, add(r, 64), tmp1, add(tmp1, 64), r, add(r, 64))

        // return(r, 128)
        // ^ this line causes "stack too deep" error

        // r_0 <- mulNonResidue(r_0)
        mulNR2(r, add(r, 64), r, add(r, 64), arena)

        // r_0 <- aA + r_0
        f2m_add(r, add(r, 64), aA_0, aA_1, r, add(r, 64))
    }

    function test_f6m_mul() {
            let bls12_mod := msize()
            mstore(bls12_mod,          0xabaafffffffffeb9ffff53b1feffab1e24f6b0f6a0d23067bf1285f3844b7764)
            mstore(add(bls12_mod, 32), 0xd7ac4b43b6a71b4b9ae67f39ea11011a00000000000000000000000000000000)

            //let point1_a := msize()
            let point1_a := add(bls12_mod, 64)

            /*
            p1 bytecode
            these coords are in montgomery form

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

            /*
            expected result, in montgomery form (little endian):
            f4f3f4e0a35068eaac665aee2e71f682aecd20923b420023b6d5420ba01ea98287c314107a998a650ab3247ef39c920e
            // 0e929c.. (big endian)
            2c9620d993a22bade623d165a9f4aa648af87cb7292b7821c0fcd0adcd14ba655da54df2ad93262e24fc62bcd97e7208
            // 08727e...
            ead1838e6c5e168543093c87eaeb576f940670026292dcb7a812600f4fb20a281be71ce1ef79f675e4a283b73906ca17
            // 17ca06..
            9c8b2c76405445b20dd7635d562309f69c2c87601d9055a5e10df2ea1d28237fafd0d32f7e8c19d4cd5a3d1ef65b120b
            // 0b125b...
            40591ef0c74dbec983b7bef145a87957c1e09049dbc85fbb3e9bb1174892ee83294ef8c4a5954fffbff4ca6aca74c718
            // 18c774...
            9b242b8f1c5d63bb525121bd68eda084ab7e6d015052d5adeb79ddb24091d2a8e5b1da00212d0e6c11f01d2379011308
            // 081301...
            */




            mstore(point1_a,          0x8f2990f3e598f5b1b8f480a3c388306bc023fac151c0104d13ec3aa181599402)
            mstore(add(point1_a, 32), 0x72d1c8c528a1ce3bcaa280a8e735aa0d00000000000000000000000000000000)
            mstore(add(point1_a, 64), 0x992d7a27906d4cd530b23a7e8c48c0778f8653fbc3332d63db24339d8bc65d7e)
            mstore(add(point1_a, 96), 0xe83b6e91c6550f5aceab102e88e9180900000000000000000000000000000000)

            let point1_b := add(point1_a, 128)
            mstore(point1_b,          0x7299907146816f08c4c6a394e91374ed6ff3618a57358cfb124ee6ab4c560e5c)
            mstore(add(point1_b, 32), 0xac40700b41e2ee8674680728f0c5a61800000000000000000000000000000000)
            mstore(add(point1_b, 64), 0x0fd77f62b39eb952a0f8d21cec1f93b1d62dd7923aa86882ddf7dd4d3532b0b7)
            mstore(add(point1_b, 96), 0xede8f3fc89fa4a79574067e2d9a9d20000000000000000000000000000000000)

            let point1_c := add(point1_b, 128)
            mstore(point1_c,          0x7a69de46b13d8cb4c4833224aaf9ef7ea6a48975ab35c6e123b8539ab84c381a)
            mstore(add(point1_c, 32), 0x2533401a73c4e79f47d714899d01ac1300000000000000000000000000000000)
            mstore(add(point1_c, 64), 0xa9fa0b0d8156c36a1a9ddacb73ef278f4d149b560e88789f2bfeb9f708b6cc2f)
            mstore(add(point1_c, 96), 0x988927bfe0186d5bf9cb40cb07f21b1800000000000000000000000000000000)

            let point2_A := add(point1_c, 128)
            mstore(point2_A,          0xecd347c808af644c7a3a971a556576f434e302b6b490004fb418a4a7da330a67)
            mstore(add(point2_A, 32), 0x43adeca931169b8b92e91df73ae1e11500000000000000000000000000000000)
            mstore(add(point2_A, 64), 0x12a2829e11e843d764d5e3b80e75432d93f69b23ad79c38d43ebbc9bd2b17b9e)
            mstore(add(point2_A, 96), 0x903033351357b03602624762e5ad360d00000000000000000000000000000000)

            let point2_B := add(point2_A, 128)
            mstore(point2_B,          0xd7f9857dce663301f393f9fac66f5c49168494e0d20797a6c4f96327ed4fa47d)
            mstore(add(point2_B, 32), 0xd36d0078d217a712407d35046871d40f00000000000000000000000000000000)
            mstore(add(point2_B, 64), 0x2f1b767f6c1ec190eb76a0bce7906ad2e4a7548d03e8aa745e34e1bf49d83ad6)
            mstore(add(point2_B, 96), 0x4c04f57fb4d31039cb4cf01987fda21300000000000000000000000000000000)

            let point2_C := add(point2_B, 128)
            mstore(point2_C,          0x7b3f8da2f2ae47885890b0d433a3eeed2f9f37cbcfc444e4f1d880390fcdb765)
            mstore(add(point2_C, 32), 0x18d558857be01b2b10a8010bcdc6d60600000000000000000000000000000000)
            mstore(add(point2_C, 64), 0x319c02f6132c8a786377868b5825ada9a5fe303e9ae3b03ce56e90734a17ce97)
            mstore(add(point2_C, 96), 0x0c88b321012cf8dabb58211e3d50f61000000000000000000000000000000000)



            let f6m_result1 := add(bls12_mod, 384) // allocate memory past bls12_mod
            let f6m_result2 := add(f6m_result1, 384)
            let f6m_result3 := add(f6m_result2, 384)
            let f6m_result4 := add(f6m_result3, 384)
            let f6m_result5 := add(f6m_result4, 384)

            let f6m_scratch_spaace := add(f6m_result5, 384)

            // just test one call
            //f6m_mul(point1_a, point2_A, f6m_result1, bls12_mod, bls12_r_inv, f6m_scratch_spaace)

            f6m_mul(point1_a, point2_A, f6m_result4, f6m_scratch_spaace)
            f6m_mul(point1_a, f6m_result4, f6m_result5, f6m_scratch_spaace)

            let i := 0
            for {} lt(i, 135) {i := add(i, 1)} {
                f6m_mul(f6m_result4, f6m_result5, f6m_result1, f6m_scratch_spaace)
                f6m_mul(f6m_result5, f6m_result1, f6m_result2, f6m_scratch_spaace)
                f6m_mul(f6m_result1, f6m_result2, f6m_result3, f6m_scratch_spaace)
                f6m_mul(f6m_result2, f6m_result3, f6m_result4, f6m_scratch_spaace)
                f6m_mul(f6m_result3, f6m_result4, f6m_result5, f6m_scratch_spaace)

                f6m_mul(f6m_result4, f6m_result5, f6m_result1, f6m_scratch_spaace)
                f6m_mul(f6m_result5, f6m_result1, f6m_result2, f6m_scratch_spaace)
                f6m_mul(f6m_result1, f6m_result2, f6m_result3, f6m_scratch_spaace)
                f6m_mul(f6m_result2, f6m_result3, f6m_result4, f6m_scratch_spaace)
                f6m_mul(f6m_result3, f6m_result4, f6m_result5, f6m_scratch_spaace)
            }

            return(f6m_result5, 64)
    }


/*
for a loop of 10, result should be:
2cf104a6407a2e8ce662ca3dc99bd1e97c62896e29e1e8291980a7fa306fb27056a3132b5e4c6c20f73542329c263e11
// 113e269c... (little endian)
7d32a392d6e84c5a1919e67a5c1b1bfa1ff6cc88e550b4578b18745e9568078c3dfac3a48f61dfc225e4edd33882790b
// 0b798238...
c58f113de32445bb24260d6d7524850bf55cb511f92945f519a88dd5c7cce1c977eda1ca61365baf70342b2ab6ab2216
// 1622abb6...
e1726632f1f1113f56386497ad044f9da494cc6d38b28d8c6df1b43c6e00f2eec931518850e130678262c7c12f330804
// 0408332fc1...
d69dfeb1abd4b977994892df84b22abcc092d0858fcccff85a2a2e72802960254583702e3e367a76bfd476da2e013f04
// 043f012eda...
97a886f1a62bffb25b2d6722149ae489d3c0c94babac1d18dab10a6e15cb6d89e4f3b3cddb9262666a23ebbf20eff809
// 09f8ef20bf...
*/

/*
for a loop of 135, result should be:
74229fc665e6c3f4401905c1a454ea57c8931739d05a074fd60400f19684d680a9e1305c25f13613dcc6cdd6e6e57d08
//087de5... (little endian)
66643d9f8c88aa618bbad33cfdd371c73a6378e4863e9b1368f79da18a0c6b5acb958e62ea89bbf52e40a34870ef8d04
//048def70...
511a414c750669a57a3f7e97e1d893240773e1c949b2c3eeeec9bd383087955052341dfff2ab76ea37efdda91005dc03
//03dc0510a9...
27ca26dff3265aa1e0ce3e8214b110d89a415996524226b1b0754135657ff01a3cc372830380986070f0f05c1a14dc04
//04dc141a5c...
f200f1e7c3f85d7cc7172d981654b827b60dced38b6f51ab8fb837669c310aaed71cfa12e470443ce9cbd8ec68c64005
//0540c668ec...
c4ec5f1698368dda3049991ea7d283af249b54f2e22006b8d7f9727dd160aff5af3f53dec4c586c5cd581bba6ef3dd0a
//0addf36eba...
*/



    test_f6m_mul()
}
