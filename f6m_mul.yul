
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
}
