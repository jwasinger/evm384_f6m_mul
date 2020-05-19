# EVM384

Benchmarks for cryptographic primitives in an EVM augmented to support 384 bit modular arithmetic.

{{Snippet about what `f6m_mul` is}}

## Usage

### Build dependencies:
```
git submodule update --init --recursive
(cd evmone && mkdir build && cd build && cmake .. && make -j4)
(cd evmc && mkdir build && cd build && cmake -DEVMC_TOOLS=ON .. && make -j4)
(cd solidity && mkdir build && cd build && cmake .. && make -j4)
```

### Build and benchmar`f6m_mul`:
`python3 benchmark.py`
