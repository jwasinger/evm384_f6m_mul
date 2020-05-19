import os
import subprocess
import sys

def invoke_shell_cmd(cmd):
    proc = subprocess.Popen(cmd, stderr=subprocess.STDOUT, stdout=subprocess.PIPE, shell=True)

    try:
        outs, errs = proc.communicate(timeout=20)
    except TimeoutExpired:
        proc.kill()
        sys.exit(-1)
        # outs, errs = proc.communicate()
    if errs:
        raise Exception(errs)

    result = str(outs, "utf8").split("\n")
    result = [line for line in result if line]
    return result

def parse_solc_output(output):
    for i, line in enumerate(output):
        if "binary" in line.lower():
            return output[i + 1]

def build():
    solc_cmd = "solidity/build/solc/solc --strict-assembly --optimize src/f6m_mul/benchmark.yul"
    solc_output = invoke_shell_cmd(solc_cmd)
    return parse_solc_output(solc_output)

def benchmark(bytecode):
    benchmark_cmd = "time evmc/build/bin/evmc run --gas 100000000 --vm evmone/build/lib/libevmone.so " + bytecode
    output = invoke_shell_cmd(benchmark_cmd)
    for line in output:
        if "time elapsed" in line.lower():
            print("took {} milliseconds".format(line.split(":")[-1]))
            return

    raise Exception("could not parse elapsed execution time from evmc output")

if __name__ == "__main__":
    bytecode = build()
    benchmark(bytecode)
