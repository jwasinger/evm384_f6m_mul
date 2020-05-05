
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

    test_mulmodmont384()
}
