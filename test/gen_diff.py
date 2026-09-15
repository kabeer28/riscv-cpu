#!/usr/bin/env python3
import argparse
import random
from pathlib import Path

MASK32 = 0xFFFFFFFF

OP_IMM = 0b0010011
OP = 0b0110011
LOAD = 0b0000011
STORE = 0b0100011
BRANCH = 0b1100011
LUI = 0b0110111
AUIPC = 0b0010111
JAL = 0b1101111
JALR = 0b1100111


def u32(value):
    return value & MASK32


def signed(value, bits=32):
    value &= (1 << bits) - 1
    sign = 1 << (bits - 1)
    return value - (1 << bits) if value & sign else value


def enc_r(funct7, rs2, rs1, funct3, rd):
    return (funct7 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | OP


def enc_i(imm, rs1, funct3, rd, opcode=OP_IMM):
    return ((imm & 0xFFF) << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode


def enc_s(imm, rs2, rs1, funct3):
    value = imm & 0xFFF
    return ((value >> 5) << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | ((value & 0x1F) << 7) | STORE


def enc_b(imm, rs2, rs1, funct3):
    value = imm & 0x1FFF
    return (((value >> 12) & 1) << 31) | (((value >> 5) & 0x3F) << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (((value >> 1) & 0xF) << 8) | (((value >> 11) & 1) << 7) | BRANCH


def enc_u(imm, rd, opcode):
    return ((imm & 0xFFFFF) << 12) | (rd << 7) | opcode


def enc_j(imm, rd):
    value = imm & 0x1FFFFF
    return (((value >> 20) & 1) << 31) | (((value >> 1) & 0x3FF) << 21) | (((value >> 11) & 1) << 20) | (((value >> 12) & 0xFF) << 12) | (rd << 7) | JAL


def append_constant(program, rd, value):
    value = u32(value)
    upper = ((value + 0x800) >> 12) & 0xFFFFF
    lower = signed(value - (upper << 12), 12)
    program.append(enc_u(upper, rd, LUI))
    program.append(enc_i(lower, rd, 0b000, rd))


def build_program(seed):
    rng = random.Random(seed)
    program = [enc_i(0, 0, 0b000, 1)]

    for rd in range(2, 16):
        append_constant(program, rd, rng.getrandbits(32))

    r_operations = [
        (0b0000000, 0b000), (0b0100000, 0b000), (0b0000000, 0b001),
        (0b0000000, 0b010), (0b0000000, 0b011), (0b0000000, 0b100),
        (0b0000000, 0b101), (0b0100000, 0b101), (0b0000000, 0b110),
        (0b0000000, 0b111),
    ]
    for _ in range(3):
        for funct7, funct3 in r_operations:
            rd = rng.randint(2, 23)
            rs1 = rng.randint(2, 23)
            rs2 = rng.randint(2, 23)
            program.append(enc_r(funct7, rs2, rs1, funct3, rd))

    i_operations = [0b000, 0b010, 0b011, 0b100, 0b110, 0b111]
    for _ in range(3):
        for funct3 in i_operations:
            program.append(enc_i(rng.randint(-2048, 2047), rng.randint(2, 23), funct3, rng.randint(2, 23)))
        shamt = rng.randint(0, 31)
        program.append(enc_i(shamt, rng.randint(2, 23), 0b001, rng.randint(2, 23)))
        program.append(enc_i(shamt, rng.randint(2, 23), 0b101, rng.randint(2, 23)))
        program.append(enc_i((0b0100000 << 5) | shamt, rng.randint(2, 23), 0b101, rng.randint(2, 23)))

    for offset in range(0, 32, 4):
        program.append(enc_s(offset, rng.randint(2, 23), 1, 0b010))
    program.extend([
        enc_s(1, 7, 1, 0b000),
        enc_s(2, 8, 1, 0b001),
        enc_i(0, 1, 0b000, 16, LOAD),
        enc_i(1, 1, 0b100, 17, LOAD),
        enc_i(2, 1, 0b001, 18, LOAD),
        enc_i(2, 1, 0b101, 19, LOAD),
        enc_i(4, 1, 0b010, 20, LOAD),
        enc_i(1, 20, 0b000, 21),
        enc_r(0b0000000, 21, 20, 0b000, 22),
    ])

    program.extend([
        enc_i(-1, 0, 0b000, 24),
        enc_i(1, 0, 0b000, 25),
        enc_b(8, 25, 25, 0b000),
        enc_i(1, 23, 0b000, 23),
        enc_b(8, 25, 24, 0b001),
        enc_i(2, 23, 0b000, 23),
        enc_b(8, 25, 24, 0b100),
        enc_i(4, 23, 0b000, 23),
        enc_b(8, 24, 25, 0b101),
        enc_i(8, 23, 0b000, 23),
        enc_b(8, 25, 24, 0b110),
        enc_i(16, 23, 0b000, 23),
        enc_b(8, 25, 24, 0b111),
        enc_i(32, 23, 0b000, 23),
        enc_j(8, 26),
        enc_i(64, 23, 0b000, 23),
    ])

    jalr_index = len(program)
    program.extend([
        enc_u(0, 27, AUIPC),
        enc_i(12, 27, 0b000, 27),
        enc_i(0, 27, 0b000, 28, JALR),
        enc_i(128, 23, 0b000, 23),
        enc_i(jalr_index, 0, 0b000, 0),
    ])
    program.append(enc_j(0, 0))

    if len(program) > 256:
        raise ValueError("generated program exceeds instruction memory")
    return program


def load(memory, address, width, unsigned):
    if address < 0 or address + width > len(memory) or address % width:
        return 0
    value = sum(memory[address + index] << (8 * index) for index in range(width))
    return value if unsigned else u32(signed(value, width * 8))


def store(memory, address, width, value):
    if address < 0 or address + width > len(memory) or address % width:
        return
    for index in range(width):
        memory[address + index] = (value >> (8 * index)) & 0xFF


def run_reference(program):
    registers = [0] * 32
    memory = bytearray(1024)
    pc = 0

    for _ in range(10000):
        instruction = program[pc // 4]
        if instruction == enc_j(0, 0):
            break

        opcode = instruction & 0x7F
        rd = (instruction >> 7) & 0x1F
        funct3 = (instruction >> 12) & 0x7
        rs1 = (instruction >> 15) & 0x1F
        rs2 = (instruction >> 20) & 0x1F
        funct7 = (instruction >> 25) & 0x7F
        lhs = registers[rs1]
        rhs = registers[rs2]
        next_pc = u32(pc + 4)
        result = None

        if opcode == OP:
            shamt = rhs & 0x1F
            operations = {
                (0b0000000, 0b000): lambda: lhs + rhs,
                (0b0100000, 0b000): lambda: lhs - rhs,
                (0b0000000, 0b001): lambda: lhs << shamt,
                (0b0000000, 0b010): lambda: int(signed(lhs) < signed(rhs)),
                (0b0000000, 0b011): lambda: int(lhs < rhs),
                (0b0000000, 0b100): lambda: lhs ^ rhs,
                (0b0000000, 0b101): lambda: lhs >> shamt,
                (0b0100000, 0b101): lambda: signed(lhs) >> shamt,
                (0b0000000, 0b110): lambda: lhs | rhs,
                (0b0000000, 0b111): lambda: lhs & rhs,
            }
            operation = operations.get((funct7, funct3))
            result = operation() if operation else None
        elif opcode == OP_IMM:
            immediate = signed(instruction >> 20, 12)
            shamt = (instruction >> 20) & 0x1F
            if funct3 == 0b000:
                result = lhs + immediate
            elif funct3 == 0b010:
                result = int(signed(lhs) < immediate)
            elif funct3 == 0b011:
                result = int(lhs < u32(immediate))
            elif funct3 == 0b100:
                result = lhs ^ u32(immediate)
            elif funct3 == 0b110:
                result = lhs | u32(immediate)
            elif funct3 == 0b111:
                result = lhs & u32(immediate)
            elif funct3 == 0b001 and funct7 == 0:
                result = lhs << shamt
            elif funct3 == 0b101 and funct7 == 0:
                result = lhs >> shamt
            elif funct3 == 0b101 and funct7 == 0b0100000:
                result = signed(lhs) >> shamt
        elif opcode == LOAD:
            address = u32(lhs + signed(instruction >> 20, 12))
            widths = {0b000: (1, False), 0b001: (2, False), 0b010: (4, False), 0b100: (1, True), 0b101: (2, True)}
            if funct3 in widths:
                result = load(memory, address, *widths[funct3])
        elif opcode == STORE:
            immediate = signed(((instruction >> 25) << 5) | ((instruction >> 7) & 0x1F), 12)
            widths = {0b000: 1, 0b001: 2, 0b010: 4}
            if funct3 in widths:
                store(memory, u32(lhs + immediate), widths[funct3], rhs)
        elif opcode == BRANCH:
            immediate = signed((((instruction >> 31) & 1) << 12) | (((instruction >> 7) & 1) << 11) | (((instruction >> 25) & 0x3F) << 5) | (((instruction >> 8) & 0xF) << 1), 13)
            conditions = {
                0b000: lhs == rhs, 0b001: lhs != rhs,
                0b100: signed(lhs) < signed(rhs), 0b101: signed(lhs) >= signed(rhs),
                0b110: lhs < rhs, 0b111: lhs >= rhs,
            }
            if conditions.get(funct3, False):
                next_pc = u32(pc + immediate)
        elif opcode == LUI:
            result = instruction & 0xFFFFF000
        elif opcode == AUIPC:
            result = pc + (instruction & 0xFFFFF000)
        elif opcode == JAL:
            immediate = signed((((instruction >> 31) & 1) << 20) | (((instruction >> 12) & 0xFF) << 12) | (((instruction >> 20) & 1) << 11) | (((instruction >> 21) & 0x3FF) << 1), 21)
            result = pc + 4
            next_pc = u32(pc + immediate)
        elif opcode == JALR and funct3 == 0:
            result = pc + 4
            next_pc = u32(lhs + signed(instruction >> 20, 12)) & ~1

        if result is not None and rd:
            registers[rd] = u32(result)
        registers[0] = 0
        pc = next_pc
    else:
        raise RuntimeError("reference model did not reach halt loop")

    words = [sum(memory[index + byte] << (8 * byte) for byte in range(4)) for index in range(0, 1024, 4)]
    return registers, words


def write_hex(path, values, length):
    padded = list(values) + [0x00000013] * (length - len(values))
    Path(path).write_text("".join(f"{value & MASK32:08x}\n" for value in padded), encoding="ascii")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--seed", type=int, required=True)
    parser.add_argument("--program", required=True)
    parser.add_argument("--registers", required=True)
    parser.add_argument("--memory", required=True)
    args = parser.parse_args()

    program = build_program(args.seed)
    registers, memory = run_reference(program)
    write_hex(args.program, program, 256)
    write_hex(args.registers, registers, 32)
    write_hex(args.memory, memory, 256)


if __name__ == "__main__":
    main()
