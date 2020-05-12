#! /usr/bin/env bash

./evmc/build/bin/evmc run --gas 1000000000 --vm evmone/build/lib/libevmone.so $1
