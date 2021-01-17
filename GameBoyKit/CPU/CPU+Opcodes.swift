extension CPU {
    public static let allOpcodes: [Opcode] =
        range0nOpcodes +
        range1nOpcodes +
        range2nOpcodes +
        range3nOpcodes +
        range4nOpcodes +
        range5nOpcodes +
        range6nOpcodes +
        range7nOpcodes +
        range8nOpcodes +
        range9nOpcodes +
        rangeAnOpcodes +
        rangeBnOpcodes +
        rangeCnOpcodes +
        rangeDnOpcodes +
        rangeEnOpcodes +
        rangeFnOpcodes


    // 0x0n
    public static let range0nOpcodes: [Opcode] = [
        Opcode(mnemonic: "NOP") { cpu, _ in cpu.nop() },
        Opcode(mnemonic: "LD BC, nn") { cpu, ctx in cpu.loadOperand(into: &cpu.bc, context: ctx) },
        Opcode(mnemonic: "LD (BC), A") { cpu, ctx in cpu.load(value: cpu.a, into: cpu.bc, context: ctx) },
        Opcode(mnemonic: "INC BC") { cpu, ctx in cpu.increment(pair: &cpu.bc, context: ctx) },
        Opcode(mnemonic: "INC B") { cpu, _ in cpu.increment(register: &cpu.b) },
        Opcode(mnemonic: "DEC B") { cpu, _ in cpu.decrement(register: &cpu.b) },
        Opcode(mnemonic: "LD B, n") { cpu, ctx in cpu.loadOperand(into: &cpu.b, context: ctx) },
        Opcode(mnemonic: "RLCA") { cpu, _ in cpu.rotateLeftCarryA() },
        Opcode(mnemonic: "LD (nn), SP") { cpu, ctx in cpu.loadIntoAddressOperand(word: cpu.sp, context: ctx) },
        Opcode(mnemonic: "ADD HL, BC") { cpu, ctx in cpu.add(value: cpu.bc, to: &cpu.hl, context: ctx) },
        Opcode(mnemonic: "LD A, (BC)") { cpu, ctx in cpu.load(address: cpu.bc, into: &cpu.a, context: ctx) },
        Opcode(mnemonic: "DEC BC") { cpu, ctx in cpu.decrement(pair: &cpu.bc, context: ctx) },
        Opcode(mnemonic: "INC C") { cpu, _ in cpu.increment(register: &cpu.c) },
        Opcode(mnemonic: "DEC C") { cpu, _ in cpu.decrement(register: &cpu.c) },
        Opcode(mnemonic: "LD C, n") { cpu, ctx in cpu.loadOperand(into: &cpu.c, context: ctx) },
        Opcode(mnemonic: "RRCA") { cpu, _ in cpu.rotateRightCarryA() },
    ]

    // 0x1n
    public static let range1nOpcodes: [Opcode] = [
        Opcode(mnemonic: "STOP") { cpu, _ in cpu.stop() },
        Opcode(mnemonic: "LD DE, nn") { cpu, ctx in cpu.loadOperand(into: &cpu.de, context: ctx) },
        Opcode(mnemonic: "LD (DE), A") { cpu, ctx in cpu.load(value: cpu.a, into: cpu.de, context: ctx) },
        Opcode(mnemonic: "INC DE") { cpu, ctx in cpu.increment(pair: &cpu.de, context: ctx) },
        Opcode(mnemonic: "INC D") { cpu, _ in cpu.increment(register: &cpu.d) },
        Opcode(mnemonic: "DEC D") { cpu, _ in cpu.decrement(register: &cpu.d) },
        Opcode(mnemonic: "LD D, n") { cpu, ctx in cpu.loadOperand(into: &cpu.d, context: ctx) },
        Opcode(mnemonic: "RLA") { cpu, _ in cpu.rotateLeftA() },
        Opcode(mnemonic: "JR n") { cpu, ctx in cpu.jumpRelative(context: ctx) },
        Opcode(mnemonic: "ADD HL, DE") { cpu, ctx in cpu.add(value: cpu.de, to: &cpu.hl, context: ctx) },
        Opcode(mnemonic: "LD A, (DE)") { cpu, ctx in cpu.load(address: cpu.de, into: &cpu.a, context: ctx) },
        Opcode(mnemonic: "DEC DE") { cpu, ctx in cpu.decrement(pair: &cpu.de, context: ctx) },
        Opcode(mnemonic: "INC E") { cpu, _ in cpu.increment(register: &cpu.e) },
        Opcode(mnemonic: "DEC E") { cpu, _ in cpu.decrement(register: &cpu.e) },
        Opcode(mnemonic: "LD E, n") { cpu, ctx in cpu.loadOperand(into: &cpu.e, context: ctx) },
        Opcode(mnemonic: "RRA") { cpu, _ in cpu.rotateRightA() },
    ]

    // 0x2n
    public static let range2nOpcodes: [Opcode] = [
        Opcode(mnemonic: "JR NZ, n") { cpu, ctx in cpu.jumpRelative(condition: !cpu.flags.contains(.zero), context: ctx) },
        Opcode(mnemonic: "LD HL, nn") { cpu, ctx in cpu.loadOperand(into: &cpu.hl, context: ctx) },
        Opcode(mnemonic: "LD (HL+), A") { cpu, ctx in cpu.loadAddressAndIncrementHL(from: cpu.a, context: ctx) },
        Opcode(mnemonic: "INC HL") { cpu, ctx in cpu.increment(pair: &cpu.hl, context: ctx) },
        Opcode(mnemonic: "INC H") { cpu, _ in cpu.increment(register: &cpu.h) },
        Opcode(mnemonic: "DEC H") { cpu, _ in cpu.decrement(register: &cpu.h) },
        Opcode(mnemonic: "LD H, n") { cpu, ctx in cpu.loadOperand(into: &cpu.h, context: ctx) },
        Opcode(mnemonic: "DAA") { cpu, _ in cpu.decimalAdjustAccumulator() },
        Opcode(mnemonic: "JR Z, n") { cpu, ctx in cpu.jumpRelative(condition: cpu.flags.contains(.zero), context: ctx) },
        Opcode(mnemonic: "ADD HL, HL") { cpu, ctx in cpu.add(value: cpu.hl, to: &cpu.hl, context: ctx) },
        Opcode(mnemonic: "LD A, (HL+)") { cpu, ctx in cpu.loadFromAddressAndIncrementHL(to: &cpu.a, context: ctx) },
        Opcode(mnemonic: "DEC HL") { cpu, ctx in cpu.decrement(pair: &cpu.hl, context: ctx) },
        Opcode(mnemonic: "INC L") { cpu, _ in cpu.increment(register: &cpu.l) },
        Opcode(mnemonic: "DEC L") { cpu, _ in cpu.decrement(register: &cpu.l) },
        Opcode(mnemonic: "LD L, n") { cpu, ctx in cpu.loadOperand(into: &cpu.l, context: ctx) },
        Opcode(mnemonic: "CPL") { cpu, _ in cpu.complementAccumulator() },
    ]

    // 0x3n
    public static let range3nOpcodes: [Opcode] = [
        Opcode(mnemonic: "JR NC, n") { cpu, ctx in cpu.jumpRelative(condition: !cpu.flags.contains(.fullCarry), context: ctx) },
        Opcode(mnemonic: "LD SP, nn") { cpu, ctx in cpu.loadOperand(into: &cpu.sp, context: ctx) },
        Opcode(mnemonic: "LD (HL-), A") { cpu, ctx in cpu.loadAddressAndDecrementHL(from: cpu.a, context: ctx) },
        Opcode(mnemonic: "INC SP") { cpu, ctx in cpu.increment(pair: &cpu.sp, context: ctx) },
        Opcode(mnemonic: "INC (HL)") { cpu, ctx in cpu.incrementValue(at: cpu.hl, context: ctx) },
        Opcode(mnemonic: "DEC (HL)") { cpu, ctx in cpu.decrementValue(at: cpu.hl, context: ctx) },
        Opcode(mnemonic: "LD (HL), n") { cpu, ctx in cpu.loadOperand(into: cpu.hl, context: ctx) },
        Opcode(mnemonic: "SCF") { cpu, _ in cpu.setCarryFlag() },
        Opcode(mnemonic: "JR C, n") { cpu, ctx in cpu.jumpRelative(condition: cpu.flags.contains(.fullCarry), context: ctx) },
        Opcode(mnemonic: "ADD HL, SP") { cpu, ctx in cpu.add(value: cpu.sp, to: &cpu.hl, context: ctx) },
        Opcode(mnemonic: "LD A, (HL-)") { cpu, ctx in cpu.loadFromAddressAndDecrementHL(to: &cpu.a, context: ctx) },
        Opcode(mnemonic: "DEC SP") { cpu, ctx in cpu.decrement(pair: &cpu.sp, context: ctx) },
        Opcode(mnemonic: "INC A") { cpu, _ in cpu.increment(register: &cpu.a) },
        Opcode(mnemonic: "DEC A") { cpu, _ in cpu.decrement(register: &cpu.a) },
        Opcode(mnemonic: "LD A, n") { cpu, ctx in cpu.loadOperand(into: &cpu.a, context: ctx) },
        Opcode(mnemonic: "CCF") { cpu, _ in cpu.complementCarryFlag() },
    ]

    // 0x4n
    public static let range4nOpcodes: [Opcode] = [
        Opcode(mnemonic: "LD B, B") { cpu, _ in cpu.load(value: cpu.b, into: &cpu.b) },
        Opcode(mnemonic: "LD B, C") { cpu, _ in cpu.load(value: cpu.c, into: &cpu.b) },
        Opcode(mnemonic: "LD B, D") { cpu, _ in cpu.load(value: cpu.d, into: &cpu.b) },
        Opcode(mnemonic: "LD B, E") { cpu, _ in cpu.load(value: cpu.e, into: &cpu.b) },
        Opcode(mnemonic: "LD B, H") { cpu, _ in cpu.load(value: cpu.h, into: &cpu.b) },
        Opcode(mnemonic: "LD B, L") { cpu, _ in cpu.load(value: cpu.l, into: &cpu.b) },
        Opcode(mnemonic: "LD B, (HL)") { cpu, ctx in cpu.load(address: cpu.hl, into: &cpu.b, context: ctx) },
        Opcode(mnemonic: "LD B, A") { cpu, _ in cpu.load(value: cpu.a, into: &cpu.b) },
        Opcode(mnemonic: "LD C, B") { cpu, _ in cpu.load(value: cpu.b, into: &cpu.c) },
        Opcode(mnemonic: "LD C, C") { cpu, _ in cpu.load(value: cpu.c, into: &cpu.c) },
        Opcode(mnemonic: "LD C, D") { cpu, _ in cpu.load(value: cpu.d, into: &cpu.c) },
        Opcode(mnemonic: "LD C, E") { cpu, _ in cpu.load(value: cpu.e, into: &cpu.c) },
        Opcode(mnemonic: "LD C, H") { cpu, _ in cpu.load(value: cpu.h, into: &cpu.c) },
        Opcode(mnemonic: "LD C, L") { cpu, _ in cpu.load(value: cpu.l, into: &cpu.c) },
        Opcode(mnemonic: "LD C, (HL)") { cpu, ctx in cpu.load(address: cpu.hl, into: &cpu.c, context: ctx) },
        Opcode(mnemonic: "LD C, A") { cpu, _ in cpu.load(value: cpu.a, into: &cpu.c) },
    ]

    // 0x5n
    public static let range5nOpcodes: [Opcode] = [
        Opcode(mnemonic: "LD D, B") { cpu, _ in cpu.load(value: cpu.b, into: &cpu.d) },
        Opcode(mnemonic: "LD D, C") { cpu, _ in cpu.load(value: cpu.c, into: &cpu.d) },
        Opcode(mnemonic: "LD D, D") { cpu, _ in cpu.load(value: cpu.d, into: &cpu.d) },
        Opcode(mnemonic: "LD D, E") { cpu, _ in cpu.load(value: cpu.e, into: &cpu.d) },
        Opcode(mnemonic: "LD D, H") { cpu, _ in cpu.load(value: cpu.h, into: &cpu.d) },
        Opcode(mnemonic: "LD D, L") { cpu, _ in cpu.load(value: cpu.l, into: &cpu.d) },
        Opcode(mnemonic: "LD D, (HL)") { cpu, ctx in cpu.load(address: cpu.hl, into: &cpu.d, context: ctx) },
        Opcode(mnemonic: "LD D, A") { cpu, _ in cpu.load(value: cpu.a, into: &cpu.d) },
        Opcode(mnemonic: "LD E, B") { cpu, _ in cpu.load(value: cpu.b, into: &cpu.e) },
        Opcode(mnemonic: "LD E, C") { cpu, _ in cpu.load(value: cpu.c, into: &cpu.e) },
        Opcode(mnemonic: "LD E, D") { cpu, _ in cpu.load(value: cpu.d, into: &cpu.e) },
        Opcode(mnemonic: "LD E, E") { cpu, _ in cpu.load(value: cpu.e, into: &cpu.e) },
        Opcode(mnemonic: "LD E, H") { cpu, _ in cpu.load(value: cpu.h, into: &cpu.e) },
        Opcode(mnemonic: "LD E, L") { cpu, _ in cpu.load(value: cpu.l, into: &cpu.e) },
        Opcode(mnemonic: "LD E, (HL)") { cpu, ctx in cpu.load(address: cpu.hl, into: &cpu.e, context: ctx) },
        Opcode(mnemonic: "LD E, A") { cpu, _ in cpu.load(value: cpu.a, into: &cpu.e) },
    ]

    // 0x6n
    public static let range6nOpcodes: [Opcode] = [
        Opcode(mnemonic: "LD H, B") { cpu, _ in cpu.load(value: cpu.b, into: &cpu.h) },
        Opcode(mnemonic: "LD H, C") { cpu, _ in cpu.load(value: cpu.c, into: &cpu.h) },
        Opcode(mnemonic: "LD H, D") { cpu, _ in cpu.load(value: cpu.d, into: &cpu.h) },
        Opcode(mnemonic: "LD H, E") { cpu, _ in cpu.load(value: cpu.e, into: &cpu.h) },
        Opcode(mnemonic: "LD H, H") { cpu, _ in cpu.load(value: cpu.h, into: &cpu.h) },
        Opcode(mnemonic: "LD H, L") { cpu, _ in cpu.load(value: cpu.l, into: &cpu.h) },
        Opcode(mnemonic: "LD H, (HL)") { cpu, ctx in cpu.load(address: cpu.hl, into: &cpu.h, context: ctx) },
        Opcode(mnemonic: "LD H, A") { cpu, _ in cpu.load(value: cpu.a, into: &cpu.h) },
        Opcode(mnemonic: "LD L, B") { cpu, _ in cpu.load(value: cpu.b, into: &cpu.l) },
        Opcode(mnemonic: "LD L, C") { cpu, _ in cpu.load(value: cpu.c, into: &cpu.l) },
        Opcode(mnemonic: "LD L, D") { cpu, _ in cpu.load(value: cpu.d, into: &cpu.l) },
        Opcode(mnemonic: "LD L, E") { cpu, _ in cpu.load(value: cpu.e, into: &cpu.l) },
        Opcode(mnemonic: "LD L, H") { cpu, _ in cpu.load(value: cpu.h, into: &cpu.l) },
        Opcode(mnemonic: "LD L, L") { cpu, _ in cpu.load(value: cpu.l, into: &cpu.l) },
        Opcode(mnemonic: "LD L, (HL)") { cpu, ctx in cpu.load(address: cpu.hl, into: &cpu.l, context: ctx) },
        Opcode(mnemonic: "LD L, A") { cpu, _ in cpu.load(value: cpu.a, into: &cpu.l) },
    ]

    // 0x7n
    public static let range7nOpcodes: [Opcode] = [
        Opcode(mnemonic: "LD (HL), B") { cpu, ctx in cpu.load(value: cpu.b, into: cpu.hl, context: ctx) },
        Opcode(mnemonic: "LD (HL), C") { cpu, ctx in cpu.load(value: cpu.c, into: cpu.hl, context: ctx) },
        Opcode(mnemonic: "LD (HL), D") { cpu, ctx in cpu.load(value: cpu.d, into: cpu.hl, context: ctx) },
        Opcode(mnemonic: "LD (HL), E") { cpu, ctx in cpu.load(value: cpu.e, into: cpu.hl, context: ctx) },
        Opcode(mnemonic: "LD (HL), H") { cpu, ctx in cpu.load(value: cpu.h, into: cpu.hl, context: ctx) },
        Opcode(mnemonic: "LD (HL), L") { cpu, ctx in cpu.load(value: cpu.l, into: cpu.hl, context: ctx) },
        Opcode(mnemonic: "HALT") { cpu, _ in cpu.halt() },
        Opcode(mnemonic: "LD (HL), A") { cpu, ctx in cpu.load(value: cpu.a, into: cpu.hl, context: ctx) },
        Opcode(mnemonic: "LD A, B") { cpu, _ in cpu.load(value: cpu.b, into: &cpu.a) },
        Opcode(mnemonic: "LD A, C") { cpu, _ in cpu.load(value: cpu.c, into: &cpu.a) },
        Opcode(mnemonic: "LD A, D") { cpu, _ in cpu.load(value: cpu.d, into: &cpu.a) },
        Opcode(mnemonic: "LD A, E") { cpu, _ in cpu.load(value: cpu.e, into: &cpu.a) },
        Opcode(mnemonic: "LD A, H") { cpu, _ in cpu.load(value: cpu.h, into: &cpu.a) },
        Opcode(mnemonic: "LD A, L") { cpu, _ in cpu.load(value: cpu.l, into: &cpu.a) },
        Opcode(mnemonic: "LD A, (HL)") { cpu, ctx in cpu.load(address: cpu.hl, into: &cpu.a, context: ctx) },
        Opcode(mnemonic: "LD A, A") { cpu, _ in cpu.load(value: cpu.a, into: &cpu.a) },
    ]

    // 0x8n
    public static let range8nOpcodes: [Opcode] = [
        Opcode(mnemonic: "ADD A, B") { cpu, _ in cpu.add(value: cpu.b, to: &cpu.a) },
        Opcode(mnemonic: "ADD A, C") { cpu, _ in cpu.add(value: cpu.c, to: &cpu.a) },
        Opcode(mnemonic: "ADD A, D") { cpu, _ in cpu.add(value: cpu.d, to: &cpu.a) },
        Opcode(mnemonic: "ADD A, E") { cpu, _ in cpu.add(value: cpu.e, to: &cpu.a) },
        Opcode(mnemonic: "ADD A, H") { cpu, _ in cpu.add(value: cpu.h, to: &cpu.a) },
        Opcode(mnemonic: "ADD A, L") { cpu, _ in cpu.add(value: cpu.l, to: &cpu.a) },
        Opcode(mnemonic: "ADD A, (HL)") { cpu, ctx in cpu.add(address: cpu.hl, to: &cpu.a, context: ctx) },
        Opcode(mnemonic: "ADD A, A") { cpu, _ in cpu.add(value: cpu.a, to: &cpu.a) },
        Opcode(mnemonic: "ADC A, B") { cpu, _ in cpu.addWithCarry(value: cpu.b, to: &cpu.a) },
        Opcode(mnemonic: "ADC A, C") { cpu, _ in cpu.addWithCarry(value: cpu.c, to: &cpu.a) },
        Opcode(mnemonic: "ADC A, D") { cpu, _ in cpu.addWithCarry(value: cpu.d, to: &cpu.a) },
        Opcode(mnemonic: "ADC A, E") { cpu, _ in cpu.addWithCarry(value: cpu.e, to: &cpu.a) },
        Opcode(mnemonic: "ADC A, H") { cpu, _ in cpu.addWithCarry(value: cpu.h, to: &cpu.a) },
        Opcode(mnemonic: "ADC A, L") { cpu, _ in cpu.addWithCarry(value: cpu.l, to: &cpu.a) },
        Opcode(mnemonic: "ADC A, (HL)") { cpu, ctx in cpu.addWithCarry(address: cpu.hl, to: &cpu.a, context: ctx) },
        Opcode(mnemonic: "ADC A, A") { cpu, _ in cpu.addWithCarry(value: cpu.a, to: &cpu.a) },
    ]

    // 0x9n
    public static let range9nOpcodes: [Opcode] = [
        Opcode(mnemonic: "SUB B") { cpu, _ in cpu.subtract(value: cpu.b, from: &cpu.a) },
        Opcode(mnemonic: "SUB C") { cpu, _ in cpu.subtract(value: cpu.c, from: &cpu.a) },
        Opcode(mnemonic: "SUB D") { cpu, _ in cpu.subtract(value: cpu.d, from: &cpu.a) },
        Opcode(mnemonic: "SUB E") { cpu, _ in cpu.subtract(value: cpu.e, from: &cpu.a) },
        Opcode(mnemonic: "SUB H") { cpu, _ in cpu.subtract(value: cpu.h, from: &cpu.a) },
        Opcode(mnemonic: "SUB L") { cpu, _ in cpu.subtract(value: cpu.l, from: &cpu.a) },
        Opcode(mnemonic: "SUB (HL)") { cpu, ctx in cpu.subtract(address: cpu.hl, from: &cpu.a, context: ctx) },
        Opcode(mnemonic: "SUB A") { cpu, _ in cpu.subtract(value: cpu.a, from: &cpu.a) },
        Opcode(mnemonic: "SBC A, B") { cpu, _ in cpu.subtractWithCarry(value: cpu.b, from: &cpu.a) },
        Opcode(mnemonic: "SBC A, C") { cpu, _ in cpu.subtractWithCarry(value: cpu.c, from: &cpu.a) },
        Opcode(mnemonic: "SBC A, D") { cpu, _ in cpu.subtractWithCarry(value: cpu.d, from: &cpu.a) },
        Opcode(mnemonic: "SBC A, E") { cpu, _ in cpu.subtractWithCarry(value: cpu.e, from: &cpu.a) },
        Opcode(mnemonic: "SBC A, H") { cpu, _ in cpu.subtractWithCarry(value: cpu.h, from: &cpu.a) },
        Opcode(mnemonic: "SBC A, L") { cpu, _ in cpu.subtractWithCarry(value: cpu.l, from: &cpu.a) },
        Opcode(mnemonic: "SBC A, (HL)") { cpu, ctx in cpu.subtractWithCarry(address: cpu.hl, from: &cpu.a, context: ctx) },
        Opcode(mnemonic: "SBC A, A") { cpu, _ in cpu.subtractWithCarry(value: cpu.a, from: &cpu.a) },
    ]

    // 0xAn
    public static let rangeAnOpcodes: [Opcode] = [
        Opcode(mnemonic: "AND B") { cpu, _ in cpu.and(value: cpu.b, into: &cpu.a) },
        Opcode(mnemonic: "AND C") { cpu, _ in cpu.and(value: cpu.c, into: &cpu.a) },
        Opcode(mnemonic: "AND D") { cpu, _ in cpu.and(value: cpu.d, into: &cpu.a) },
        Opcode(mnemonic: "AND E") { cpu, _ in cpu.and(value: cpu.e, into: &cpu.a) },
        Opcode(mnemonic: "AND H") { cpu, _ in cpu.and(value: cpu.h, into: &cpu.a) },
        Opcode(mnemonic: "AND L") { cpu, _ in cpu.and(value: cpu.l, into: &cpu.a) },
        Opcode(mnemonic: "AND (HL)") { cpu, ctx in cpu.and(address: cpu.hl, into: &cpu.a, context: ctx) },
        Opcode(mnemonic: "AND A") { cpu, _ in cpu.and(value: cpu.a, into: &cpu.a) },
        Opcode(mnemonic: "XOR B") { cpu, _ in cpu.xor(value: cpu.b, into: &cpu.a) },
        Opcode(mnemonic: "XOR C") { cpu, _ in cpu.xor(value: cpu.c, into: &cpu.a) },
        Opcode(mnemonic: "XOR D") { cpu, _ in cpu.xor(value: cpu.d, into: &cpu.a) },
        Opcode(mnemonic: "XOR E") { cpu, _ in cpu.xor(value: cpu.e, into: &cpu.a) },
        Opcode(mnemonic: "XOR H") { cpu, _ in cpu.xor(value: cpu.h, into: &cpu.a) },
        Opcode(mnemonic: "XOR L") { cpu, _ in cpu.xor(value: cpu.l, into: &cpu.a) },
        Opcode(mnemonic: "XOR (HL)") { cpu, ctx in cpu.xor(address: cpu.hl, into: &cpu.a, context: ctx) },
        Opcode(mnemonic: "XOR A") { cpu, _ in cpu.xor(value: cpu.a, into: &cpu.a) },
    ]

    // 0xBn
    public static let rangeBnOpcodes: [Opcode] = [
        Opcode(mnemonic: "OR B") { cpu, _ in cpu.or(value: cpu.b, into: &cpu.a) },
        Opcode(mnemonic: "OR C") { cpu, _ in cpu.or(value: cpu.c, into: &cpu.a) },
        Opcode(mnemonic: "OR D") { cpu, _ in cpu.or(value: cpu.d, into: &cpu.a) },
        Opcode(mnemonic: "OR E") { cpu, _ in cpu.or(value: cpu.e, into: &cpu.a) },
        Opcode(mnemonic: "OR H") { cpu, _ in cpu.or(value: cpu.h, into: &cpu.a) },
        Opcode(mnemonic: "OR L") { cpu, _ in cpu.or(value: cpu.l, into: &cpu.a) },
        Opcode(mnemonic: "OR (HL)") { cpu, ctx in cpu.or(address: cpu.hl, into: &cpu.a, context: ctx) },
        Opcode(mnemonic: "OR A") { cpu, _ in cpu.or(value: cpu.a, into: &cpu.a) },
        Opcode(mnemonic: "CP B") { cpu, _ in cpu.compare(value: cpu.b, with: cpu.a) },
        Opcode(mnemonic: "CP C") { cpu, _ in cpu.compare(value: cpu.c, with: cpu.a) },
        Opcode(mnemonic: "CP D") { cpu, _ in cpu.compare(value: cpu.d, with: cpu.a) },
        Opcode(mnemonic: "CP E") { cpu, _ in cpu.compare(value: cpu.e, with: cpu.a) },
        Opcode(mnemonic: "CP H") { cpu, _ in cpu.compare(value: cpu.h, with: cpu.a) },
        Opcode(mnemonic: "CP L") { cpu, _ in cpu.compare(value: cpu.l, with: cpu.a) },
        Opcode(mnemonic: "CP (HL)") { cpu, ctx in cpu.compare(address: cpu.hl, with: cpu.a, context: ctx) },
        Opcode(mnemonic: "CP A") { cpu, _ in cpu.compare(value: cpu.a, with: cpu.a) },
    ]

    // 0xCn
    public static let rangeCnOpcodes: [Opcode] = [
        Opcode(mnemonic: "RET NZ") { cpu, ctx in cpu.return(condition: !cpu.flags.contains(.zero), context: ctx) },
        Opcode(mnemonic: "POP BC") { cpu, ctx in cpu.pop(pair: &cpu.bc, context: ctx) },
        Opcode(mnemonic: "JP NZ, nn") { cpu, ctx in cpu.jump(condition: !cpu.flags.contains(.zero), context: ctx) },
        Opcode(mnemonic: "JP nn") { cpu, ctx in cpu.jump(context: ctx) },
        Opcode(mnemonic: "CALL NZ, nn") { cpu, ctx in cpu.call(condition: !cpu.flags.contains(.zero), context: ctx) },
        Opcode(mnemonic: "PUSH BC") { cpu, ctx in cpu.push(pair: cpu.bc, context: ctx) },
        Opcode(mnemonic: "ADD A, n") { cpu, ctx in cpu.addOperand(to: &cpu.a, context: ctx) },
        Opcode(mnemonic: "RST 0x00") { cpu, ctx in cpu.reset(vector: 0x00, context: ctx) },
        Opcode(mnemonic: "RET Z") { cpu, ctx in cpu.return(condition: cpu.flags.contains(.zero), context: ctx) },
        Opcode(mnemonic: "RET") { cpu, ctx in cpu.return(context: ctx) },
        Opcode(mnemonic: "JP Z, nn") { cpu, ctx in cpu.jump(condition: cpu.flags.contains(.zero), context: ctx) },
        Opcode(mnemonic: "PREFIX CB") { cpu, ctx in cpu.prefixCB(context: ctx) },
        Opcode(mnemonic: "CALL Z, nn") { cpu, ctx in cpu.call(condition: cpu.flags.contains(.zero), context: ctx) },
        Opcode(mnemonic: "CALL") { cpu, ctx in cpu.call(context: ctx) },
        Opcode(mnemonic: "ADC A, n") { cpu, ctx in cpu.addOperandWithCarry(to: &cpu.a, context: ctx) },
        Opcode(mnemonic: "RST 0x08") { cpu, ctx in cpu.reset(vector: 0x08, context: ctx) },
    ]

    // 0xDn
    public static let rangeDnOpcodes: [Opcode] = [
        Opcode(mnemonic: "RET NC") { cpu, ctx in cpu.return(condition: !cpu.flags.contains(.fullCarry), context: ctx) },
        Opcode(mnemonic: "POP DE") { cpu, ctx in cpu.pop(pair: &cpu.de, context: ctx) },
        Opcode(mnemonic: "JP NC, nn    16/12") { cpu, ctx in cpu.jump(condition: !cpu.flags.contains(.fullCarry), context: ctx) },
        Opcode(mnemonic: "UNDEFINED") { cpu, _ in cpu.undefined() },
        Opcode(mnemonic: "CALL NC, nn") { cpu, ctx in cpu.call(condition: !cpu.flags.contains(.fullCarry), context: ctx) },
        Opcode(mnemonic: "PUSH DE") { cpu, ctx in cpu.push(pair: cpu.de, context: ctx) },
        Opcode(mnemonic: "SUB n") { cpu, ctx in cpu.subtractOperand(from: &cpu.a, context: ctx) },
        Opcode(mnemonic: "RST 0x10") { cpu, ctx in cpu.reset(vector: 0x10, context: ctx) },
        Opcode(mnemonic: "RET C") { cpu, ctx in cpu.return(condition: cpu.flags.contains(.fullCarry), context: ctx) },
        Opcode(mnemonic: "RETI") { cpu, ctx in cpu.returnEnableInterrupts(context: ctx) },
        Opcode(mnemonic: "JP C, nn") { cpu, ctx in cpu.jump(condition: cpu.flags.contains(.fullCarry), context: ctx) },
        Opcode(mnemonic: "UNDEFINED") { cpu, _ in cpu.undefined() },
        Opcode(mnemonic: "CALL C, nn") { cpu, ctx in cpu.call(condition: cpu.flags.contains(.fullCarry), context: ctx) },
        Opcode(mnemonic: "UNDEFINED") { cpu, _ in cpu.undefined() },
        Opcode(mnemonic: "SBC A, n") { cpu, ctx in cpu.subtractOperandWithCarry(from: &cpu.a, context: ctx) },
        Opcode(mnemonic: "RST 0x18") { cpu, ctx in cpu.reset(vector: 0x18, context: ctx) },
    ]

    // 0xEn
    public static let rangeEnOpcodes: [Opcode] = [
        Opcode(mnemonic: "LDH (n), A") { cpu, ctx in cpu.loadHRAMOperand(from: cpu.a, context: ctx) },
        Opcode(mnemonic: "POP HL") { cpu, ctx in cpu.pop(pair: &cpu.hl, context: ctx) },
        Opcode(mnemonic: "LD (C), A") { cpu, ctx in cpu.loadHRAM(from: cpu.a, intoAddressWithLowByte: cpu.c, context: ctx) },
        Opcode(mnemonic: "UNDEFINED") { cpu, _ in cpu.undefined() },
        Opcode(mnemonic: "UNDEFINED") { cpu, _ in cpu.undefined() },
        Opcode(mnemonic: "PUSH HL") { cpu, ctx in cpu.push(pair: cpu.hl, context: ctx) },
        Opcode(mnemonic: "AND n") { cpu, ctx in cpu.andOperand(into: &cpu.a, context: ctx) },
        Opcode(mnemonic: "RST 0x20") { cpu, ctx in cpu.reset(vector: 0x20, context: ctx) },
        Opcode(mnemonic: "ADD SP, e") { cpu, ctx in cpu.addSignedOperandToStackPointer(context: ctx) },
        Opcode(mnemonic: "JP HL") { cpu, _ in cpu.jump(to: cpu.hl) },
        Opcode(mnemonic: "LD (nn), A") { cpu, ctx in cpu.loadIntoAddressOperand(byte: cpu.a, context: ctx) },
        Opcode(mnemonic: "UNDEFINED") { cpu, _ in cpu.undefined() },
        Opcode(mnemonic: "UNDEFINED") { cpu, _ in cpu.undefined() },
        Opcode(mnemonic: "UNDEFINED") { cpu, _ in cpu.undefined() },
        Opcode(mnemonic: "XOR n") { cpu, ctx in cpu.xorOperand(into: &cpu.a, context: ctx) },
        Opcode(mnemonic: "RST 0x28") { cpu, ctx in cpu.reset(vector: 0x28, context: ctx) },
    ]

    // 0xFn
    public static let rangeFnOpcodes: [Opcode] = [
        Opcode(mnemonic: "LDH A, (n)") { cpu, ctx in cpu.loadFromHRAMOperand(int: &cpu.a, context: ctx) },
        Opcode(mnemonic: "POP AF") { cpu, ctx in cpu.pop(pair: &cpu.af, context: ctx) },
        Opcode(mnemonic: "LD A, (C)") { cpu, ctx in cpu.loadFromHRAMAddress(withLoadByte: cpu.c, into: &cpu.a, context: ctx) },
        Opcode(mnemonic: "DI") { cpu, _ in cpu.disableInterrupts() },
        Opcode(mnemonic: "UNDEFINED") { cpu, _ in cpu.undefined() },
        Opcode(mnemonic: "PUSH AF") { cpu, ctx in cpu.push(pair: cpu.af, context: ctx) },
        Opcode(mnemonic: "OR n") { cpu, ctx in cpu.orOperand(into: &cpu.a, context: ctx) },
        Opcode(mnemonic: "RST 0x30") { cpu, ctx in cpu.reset(vector: 0x30, context: ctx) },
        Opcode(mnemonic: "LD HL, SP+e") { cpu, ctx in cpu.addSignedOperandToStackPointer(storeIn: &cpu.hl, context: ctx) },
        Opcode(mnemonic: "LD SP, HL") { cpu, ctx in cpu.load(value: cpu.hl, into: &cpu.sp, context: ctx) },
        Opcode(mnemonic: "LD A, (nn)") { cpu, ctx in cpu.loadFromAddressOperand(into: &cpu.a, context: ctx) },
        Opcode(mnemonic: "EI") { cpu, _ in cpu.enableInterrupts() },
        Opcode(mnemonic: "UNDEFINED") { cpu, _ in cpu.undefined() },
        Opcode(mnemonic: "UNDEFINED") { cpu, _ in cpu.undefined() },
        Opcode(mnemonic: "CP n") { cpu, ctx in cpu.compareOperand(with: cpu.a, context: ctx) },
        Opcode(mnemonic: "RST 0x38") { cpu, ctx in cpu.reset(vector: 0x38, context: ctx) }
    ]
}
