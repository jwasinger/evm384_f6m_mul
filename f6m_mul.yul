
{
    function test_addmod384() {
        let bls12_mod := msize()
        mstore(bls12_mod,          0x64774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaaab)
        mstore(add(bls12_mod, 32), 0x1a0111ea397fe69a4b1ba7b6434bacd7)

        let value_1 := add(bls12_mod, 64)
        mstore(value_1, 0x00)
        mstore(add(value_1, 32), 0x00)

        let value_2 := add(value_1, 64)
        mstore(value_2,          0x64774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaaab)
        mstore(add(value_2, 32), 0x1a0111ea397fe69a4b1ba7b6434bacd7)

        addmod384(value_1, value_2, bls12_mod)

        return(value_1, 64)
    }

	test_addmod384()
}
