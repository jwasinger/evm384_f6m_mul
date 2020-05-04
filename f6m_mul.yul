
{
    // add 1 to modulus, result should be 1 
    function test_addmod384_1_modulus() {
        let bls12_mod := msize()
        mstore(bls12_mod,          0x1a0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f624)
        mstore(add(bls12_mod, 32), 0x1eabfffeb153ffffb9feffffffffaaab00000000000000000000000000000000)

        let value_1 := add(bls12_mod, 64)
        mstore(value_1, 0x00)
        mstore(add(value_1, 32),   0x0100000000000000000000000000000000)

        let value_2 := add(value_1, 64)
        mstore(value_2,          0x1a0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f624)
        mstore(add(value_2, 32), 0x1eabfffeb153ffffb9feffffffffaaab00000000000000000000000000000000)

        addmod384(value_1, value_2, bls12_mod)

        return(value_1, 64)
    }

    // add 0 to modulus, result should be 0
    function test_addmod384_0_modulus() {
        let bls12_mod := msize()
        mstore(bls12_mod,          0x1a0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f624)
        mstore(add(bls12_mod, 32), 0x1eabfffeb153ffffb9feffffffffaaab00000000000000000000000000000000)

        let value_1 := add(bls12_mod, 64)
        mstore(value_1, 0x00)
        mstore(add(value_1, 32),   0x0000000000000000000000000000000000)

        let value_2 := add(value_1, 64)
        mstore(value_2,          0x1a0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f624)
        mstore(add(value_2, 32), 0x1eabfffeb153ffffb9feffffffffaaab00000000000000000000000000000000)

        addmod384(value_1, value_2, bls12_mod)

        return(value_1, 64)
    }

    function test_mulmodmont384() {
/*
from cdetrio/scout.ts/bls12:
mulmodmont a: 17f1d3a73197d7942695638c4fa9ac0fc3688c4f9774b905a14e3a3f171bac586c55e83ff97a1aeffb3af00adb22c6bb
mulmodmont b: 11988fe592cae3aa9a793e85b519952d67eb88a9939d83c08de5476c4c95b6d50a76e6a609d104f1f4df1f341c341746
mulmodmont result: 120177419e0bfb75edce6ecc21dbf440f0ae6acdf3d0e747154f95c7143ba1c17817fc679976fff55cb38790fd530c16
*/
        let bls12_mod := msize()
        mstore(bls12_mod,          0x1a0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f624)
        mstore(add(bls12_mod, 32), 0x1eabfffeb153ffffb9feffffffffaaab00000000000000000000000000000000)

        let bls12_r_inv :=         0x89f3fffcfffcfffd 

        let value_1 := add(bls12_mod, 64)
        mstore(value_1,            0x17f1d3a73197d7942695638c4fa9ac0fc3688c4f9774b905a14e3a3f171bac58)
        mstore(add(value_1, 32),   0x6c55e83ff97a1aeffb3af00adb22c6bb00000000000000000000000000000000)

        let value_2 := add(value_1, 64)
        mstore(value_2,            0x11988fe592cae3aa9a793e85b519952d67eb88a9939d83c08de5476c4c95b6d5)
        mstore(add(value_2, 32),   0x0a76e6a609d104f1f4df1f341c34174600000000000000000000000000000000)

        mulmodmont384(value_1, value_2, bls12_mod, bls12_r_inv)

        return(value_1, 64)
    }

    test_mulmodmont384()
}
