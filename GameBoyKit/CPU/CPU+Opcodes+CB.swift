extension CPU {
    static let cbOpcodes: [Opcode] =
        rangeCb0nOpcodes +
        rangeCb1nOpcodes +
        rangeCb2nOpcodes +
        rangeCb3nOpcodes +
        rangeCb4nOpcodes +
        rangeCb5nOpcodes +
        rangeCb6nOpcodes +
        rangeCb7nOpcodes +
        rangeCb8nOpcodes +
        rangeCb9nOpcodes +
        rangeCbAnOpcodes +
        rangeCbBnOpcodes +
        rangeCbCnOpcodes +
        rangeCbDnOpcodes +
        rangeCbEnOpcodes +
        rangeCbFnOpcodes

    // 0xCB0n
    static let rangeCb0nOpcodes: [Opcode] = [
        Opcode(mnemonic: "RLC B") { cpu, _ in cpu.rotateLeftCarry(value: &cpu.b) },
        Opcode(mnemonic: "RLC C") { cpu, _ in cpu.rotateLeftCarry(value: &cpu.c) },
        Opcode(mnemonic: "RLC D") { cpu, _ in cpu.rotateLeftCarry(value: &cpu.d) },
        Opcode(mnemonic: "RLC E") { cpu, _ in cpu.rotateLeftCarry(value: &cpu.e) },
        Opcode(mnemonic: "RLC H") { cpu, _ in cpu.rotateLeftCarry(value: &cpu.h) },
        Opcode(mnemonic: "RLC L") { cpu, _ in cpu.rotateLeftCarry(value: &cpu.l) },
        Opcode(mnemonic: "RLC (HL)") { cpu, ctx in cpu.rotateLeftCarry(address: cpu.hl, context: ctx) },
        Opcode(mnemonic: "RLC A") { cpu, _ in cpu.rotateLeftCarry(value: &cpu.a) },
        Opcode(mnemonic: "RRC B") { cpu, _ in cpu.rotateRightCarry(value: &cpu.b) },
        Opcode(mnemonic: "RRC C") { cpu, _ in cpu.rotateRightCarry(value: &cpu.c) },
        Opcode(mnemonic: "RRC D") { cpu, _ in cpu.rotateRightCarry(value: &cpu.d) },
        Opcode(mnemonic: "RRC E") { cpu, _ in cpu.rotateRightCarry(value: &cpu.e) },
        Opcode(mnemonic: "RRC H") { cpu, _ in cpu.rotateRightCarry(value: &cpu.h) },
        Opcode(mnemonic: "RRC L") { cpu, _ in cpu.rotateRightCarry(value: &cpu.l) },
        Opcode(mnemonic: "RRC (HL)") { cpu, ctx in cpu.rotateRightCarry(address: cpu.hl, context: ctx) },
        Opcode(mnemonic: "RRC A") { cpu, _ in cpu.rotateRightCarry(value: &cpu.a) },
    ]

    // 0xCB1n
    static let rangeCb1nOpcodes: [Opcode] = [
        Opcode(mnemonic: "RL B") { cpu, _ in cpu.rotateLeft(value: &cpu.b) },
        Opcode(mnemonic: "RL C") { cpu, _ in cpu.rotateLeft(value: &cpu.c) },
        Opcode(mnemonic: "RL D") { cpu, _ in cpu.rotateLeft(value: &cpu.d) },
        Opcode(mnemonic: "RL E") { cpu, _ in cpu.rotateLeft(value: &cpu.e) },
        Opcode(mnemonic: "RL H") { cpu, _ in cpu.rotateLeft(value: &cpu.h) },
        Opcode(mnemonic: "RL L") { cpu, _ in cpu.rotateLeft(value: &cpu.l) },
        Opcode(mnemonic: "RL (HL)") { cpu, ctx in cpu.rotateLeft(address: cpu.hl, context: ctx) },
        Opcode(mnemonic: "RL A") { cpu, _ in cpu.rotateLeft(value: &cpu.a) },
        Opcode(mnemonic: "RR B") { cpu, _ in cpu.rotateRight(value: &cpu.b) },
        Opcode(mnemonic: "RR C") { cpu, _ in cpu.rotateRight(value: &cpu.c) },
        Opcode(mnemonic: "RR D") { cpu, _ in cpu.rotateRight(value: &cpu.d) },
        Opcode(mnemonic: "RR E") { cpu, _ in cpu.rotateRight(value: &cpu.e) },
        Opcode(mnemonic: "RR H") { cpu, _ in cpu.rotateRight(value: &cpu.h) },
        Opcode(mnemonic: "RR L") { cpu, _ in cpu.rotateRight(value: &cpu.l) },
        Opcode(mnemonic: "RR (HL)") { cpu, ctx in cpu.rotateRight(address: cpu.hl, context: ctx) },
        Opcode(mnemonic: "RR A") { cpu, _ in cpu.rotateRight(value: &cpu.a) },
    ]

    // 0xCB2n
    static let rangeCb2nOpcodes: [Opcode] = [
        Opcode(mnemonic: "SLA B") { cpu, _ in cpu.shiftLeftArithmetic(value: &cpu.b) },
        Opcode(mnemonic: "SLA C") { cpu, _ in cpu.shiftLeftArithmetic(value: &cpu.c) },
        Opcode(mnemonic: "SLA D") { cpu, _ in cpu.shiftLeftArithmetic(value: &cpu.d) },
        Opcode(mnemonic: "SLA E") { cpu, _ in cpu.shiftLeftArithmetic(value: &cpu.e) },
        Opcode(mnemonic: "SLA H") { cpu, _ in cpu.shiftLeftArithmetic(value: &cpu.h) },
        Opcode(mnemonic: "SLA L") { cpu, _ in cpu.shiftLeftArithmetic(value: &cpu.l) },
        Opcode(mnemonic: "SLA (HL)") { cpu, ctx in cpu.shiftLeftArithmetic(address: cpu.hl, context: ctx) },
        Opcode(mnemonic: "SLA A") { cpu, _ in cpu.shiftLeftArithmetic(value: &cpu.a) },
        Opcode(mnemonic: "SRA B") { cpu, _ in cpu.shiftRightArithmetic(value: &cpu.b) },
        Opcode(mnemonic: "SRA C") { cpu, _ in cpu.shiftRightArithmetic(value: &cpu.c) },
        Opcode(mnemonic: "SRA D") { cpu, _ in cpu.shiftRightArithmetic(value: &cpu.d) },
        Opcode(mnemonic: "SRA E") { cpu, _ in cpu.shiftRightArithmetic(value: &cpu.e) },
        Opcode(mnemonic: "SRA H") { cpu, _ in cpu.shiftRightArithmetic(value: &cpu.h) },
        Opcode(mnemonic: "SRA L") { cpu, _ in cpu.shiftRightArithmetic(value: &cpu.l) },
        Opcode(mnemonic: "SRA (HL)") { cpu, ctx in cpu.shiftRightArithmetic(address: cpu.hl, context: ctx) },
        Opcode(mnemonic: "SRA A") { cpu, _ in cpu.shiftRightArithmetic(value: &cpu.a) },
    ]

    // 0xCB3n
    static let rangeCb3nOpcodes: [Opcode] = [
        Opcode(mnemonic: "SWAP B") { cpu, _ in cpu.swap(value: &cpu.b) },
        Opcode(mnemonic: "SWAP C") { cpu, _ in cpu.swap(value: &cpu.c) },
        Opcode(mnemonic: "SWAP D") { cpu, _ in cpu.swap(value: &cpu.d) },
        Opcode(mnemonic: "SWAP E") { cpu, _ in cpu.swap(value: &cpu.e) },
        Opcode(mnemonic: "SWAP H") { cpu, _ in cpu.swap(value: &cpu.h) },
        Opcode(mnemonic: "SWAP L") { cpu, _ in cpu.swap(value: &cpu.l) },
        Opcode(mnemonic: "SWAP (HL)") { cpu, ctx in cpu.swap(address: cpu.hl, context: ctx) },
        Opcode(mnemonic: "SWAP A") { cpu, _ in cpu.swap(value: &cpu.a) },
        Opcode(mnemonic: "SRL B") { cpu, _ in cpu.shiftRightLogical(value: &cpu.b) },
        Opcode(mnemonic: "SRL C") { cpu, _ in cpu.shiftRightLogical(value: &cpu.c) },
        Opcode(mnemonic: "SRL D") { cpu, _ in cpu.shiftRightLogical(value: &cpu.d) },
        Opcode(mnemonic: "SRL E") { cpu, _ in cpu.shiftRightLogical(value: &cpu.e) },
        Opcode(mnemonic: "SRL H") { cpu, _ in cpu.shiftRightLogical(value: &cpu.h) },
        Opcode(mnemonic: "SRL L") { cpu, _ in cpu.shiftRightLogical(value: &cpu.l) },
        Opcode(mnemonic: "SRL (HL)") { cpu, ctx in cpu.shiftRightLogical(address: cpu.hl, context: ctx) },
        Opcode(mnemonic: "SRL A") { cpu, _ in cpu.shiftRightLogical(value: &cpu.a) },
    ]

    // 0xCB4n
    static let rangeCb4nOpcodes: [Opcode] = [
        Opcode(mnemonic: "BIT 0, B") { cpu, _ in cpu.checkBit(index: 0, of: cpu.b) },
        Opcode(mnemonic: "BIT 0, C") { cpu, _ in cpu.checkBit(index: 0, of: cpu.c) },
        Opcode(mnemonic: "BIT 0, D") { cpu, _ in cpu.checkBit(index: 0, of: cpu.d) },
        Opcode(mnemonic: "BIT 0, E") { cpu, _ in cpu.checkBit(index: 0, of: cpu.e) },
        Opcode(mnemonic: "BIT 0, H") { cpu, _ in cpu.checkBit(index: 0, of: cpu.h) },
        Opcode(mnemonic: "BIT 0, L") { cpu, _ in cpu.checkBit(index: 0, of: cpu.l) },
        Opcode(mnemonic: "BIT 0, (HL)") { cpu, ctx in cpu.checkBit(index: 0, of: cpu.hl, context: ctx) },
        Opcode(mnemonic: "BIT 0, A") { cpu, _ in cpu.checkBit(index: 0, of: cpu.a) },
        Opcode(mnemonic: "BIT 1, B") { cpu, _ in cpu.checkBit(index: 1, of: cpu.b) },
        Opcode(mnemonic: "BIT 1, C") { cpu, _ in cpu.checkBit(index: 1, of: cpu.c) },
        Opcode(mnemonic: "BIT 1, D") { cpu, _ in cpu.checkBit(index: 1, of: cpu.d) },
        Opcode(mnemonic: "BIT 1, E") { cpu, _ in cpu.checkBit(index: 1, of: cpu.e) },
        Opcode(mnemonic: "BIT 1, H") { cpu, _ in cpu.checkBit(index: 1, of: cpu.h) },
        Opcode(mnemonic: "BIT 1, L") { cpu, _ in cpu.checkBit(index: 1, of: cpu.l) },
        Opcode(mnemonic: "BIT 1, (HL)") { cpu, ctx in cpu.checkBit(index: 1, of: cpu.hl, context: ctx) },
        Opcode(mnemonic: "BIT 1, A") { cpu, _ in cpu.checkBit(index: 1, of: cpu.a) },
    ]

    // 0xCB5n
    static let rangeCb5nOpcodes: [Opcode] = [
        Opcode(mnemonic: "BIT 2, B") { cpu, _ in cpu.checkBit(index: 2, of: cpu.b) },
        Opcode(mnemonic: "BIT 2, C") { cpu, _ in cpu.checkBit(index: 2, of: cpu.c) },
        Opcode(mnemonic: "BIT 2, D") { cpu, _ in cpu.checkBit(index: 2, of: cpu.d) },
        Opcode(mnemonic: "BIT 2, E") { cpu, _ in cpu.checkBit(index: 2, of: cpu.e) },
        Opcode(mnemonic: "BIT 2, H") { cpu, _ in cpu.checkBit(index: 2, of: cpu.h) },
        Opcode(mnemonic: "BIT 2, L") { cpu, _ in cpu.checkBit(index: 2, of: cpu.l) },
        Opcode(mnemonic: "BIT 2, (HL)") { cpu, ctx in cpu.checkBit(index: 2, of: cpu.hl, context: ctx) },
        Opcode(mnemonic: "BIT 2, A") { cpu, _ in cpu.checkBit(index: 2, of: cpu.a) },
        Opcode(mnemonic: "BIT 3, B") { cpu, _ in cpu.checkBit(index: 3, of: cpu.b) },
        Opcode(mnemonic: "BIT 3, C") { cpu, _ in cpu.checkBit(index: 3, of: cpu.c) },
        Opcode(mnemonic: "BIT 3, D") { cpu, _ in cpu.checkBit(index: 3, of: cpu.d) },
        Opcode(mnemonic: "BIT 3, E") { cpu, _ in cpu.checkBit(index: 3, of: cpu.e) },
        Opcode(mnemonic: "BIT 3, H") { cpu, _ in cpu.checkBit(index: 3, of: cpu.h) },
        Opcode(mnemonic: "BIT 3, L") { cpu, _ in cpu.checkBit(index: 3, of: cpu.l) },
        Opcode(mnemonic: "BIT 3, (HL)") { cpu, ctx in cpu.checkBit(index: 3, of: cpu.hl, context: ctx) },
        Opcode(mnemonic: "BIT 3, A") { cpu, _ in cpu.checkBit(index: 3, of: cpu.a) },
    ]

    // 0xCB6n
    static let rangeCb6nOpcodes: [Opcode] = [
        Opcode(mnemonic: "BIT 4, B") { cpu, _ in cpu.checkBit(index: 4, of: cpu.b) },
        Opcode(mnemonic: "BIT 4, C") { cpu, _ in cpu.checkBit(index: 4, of: cpu.c) },
        Opcode(mnemonic: "BIT 4, D") { cpu, _ in cpu.checkBit(index: 4, of: cpu.d) },
        Opcode(mnemonic: "BIT 4, E") { cpu, _ in cpu.checkBit(index: 4, of: cpu.e) },
        Opcode(mnemonic: "BIT 4, H") { cpu, _ in cpu.checkBit(index: 4, of: cpu.h) },
        Opcode(mnemonic: "BIT 4, L") { cpu, _ in cpu.checkBit(index: 4, of: cpu.l) },
        Opcode(mnemonic: "BIT 4, (HL)") { cpu, ctx in cpu.checkBit(index: 4, of: cpu.hl, context: ctx) },
        Opcode(mnemonic: "BIT 4, A") { cpu, _ in cpu.checkBit(index: 4, of: cpu.a) },
        Opcode(mnemonic: "BIT 5, B") { cpu, _ in cpu.checkBit(index: 5, of: cpu.b) },
        Opcode(mnemonic: "BIT 5, C") { cpu, _ in cpu.checkBit(index: 5, of: cpu.c) },
        Opcode(mnemonic: "BIT 5, D") { cpu, _ in cpu.checkBit(index: 5, of: cpu.d) },
        Opcode(mnemonic: "BIT 5, E") { cpu, _ in cpu.checkBit(index: 5, of: cpu.e) },
        Opcode(mnemonic: "BIT 5, H") { cpu, _ in cpu.checkBit(index: 5, of: cpu.h) },
        Opcode(mnemonic: "BIT 5, L") { cpu, _ in cpu.checkBit(index: 5, of: cpu.l) },
        Opcode(mnemonic: "BIT 5, (HL)") { cpu, ctx in cpu.checkBit(index: 5, of: cpu.hl, context: ctx) },
        Opcode(mnemonic: "BIT 5, A") { cpu, _ in cpu.checkBit(index: 5, of: cpu.a) },
    ]

    // 0xCB7n
    static let rangeCb7nOpcodes: [Opcode] = [
        Opcode(mnemonic: "BIT 6, B") { cpu, _ in cpu.checkBit(index: 6, of: cpu.b) },
        Opcode(mnemonic: "BIT 6, C") { cpu, _ in cpu.checkBit(index: 6, of: cpu.c) },
        Opcode(mnemonic: "BIT 6, D") { cpu, _ in cpu.checkBit(index: 6, of: cpu.d) },
        Opcode(mnemonic: "BIT 6, E") { cpu, _ in cpu.checkBit(index: 6, of: cpu.e) },
        Opcode(mnemonic: "BIT 6, H") { cpu, _ in cpu.checkBit(index: 6, of: cpu.h) },
        Opcode(mnemonic: "BIT 6, L") { cpu, _ in cpu.checkBit(index: 6, of: cpu.l) },
        Opcode(mnemonic: "BIT 6, (HL)") { cpu, ctx in cpu.checkBit(index: 6, of: cpu.hl, context: ctx) },
        Opcode(mnemonic: "BIT 6, A") { cpu, _ in cpu.checkBit(index: 6, of: cpu.a) },
        Opcode(mnemonic: "BIT 7, B") { cpu, _ in cpu.checkBit(index: 7, of: cpu.b) },
        Opcode(mnemonic: "BIT 7, C") { cpu, _ in cpu.checkBit(index: 7, of: cpu.c) },
        Opcode(mnemonic: "BIT 7, D") { cpu, _ in cpu.checkBit(index: 7, of: cpu.d) },
        Opcode(mnemonic: "BIT 7, E") { cpu, _ in cpu.checkBit(index: 7, of: cpu.e) },
        Opcode(mnemonic: "BIT 7, H") { cpu, _ in cpu.checkBit(index: 7, of: cpu.h) },
        Opcode(mnemonic: "BIT 7, L") { cpu, _ in cpu.checkBit(index: 7, of: cpu.l) },
        Opcode(mnemonic: "BIT 7, (HL)") { cpu, ctx in cpu.checkBit(index: 7, of: cpu.hl, context: ctx) },
        Opcode(mnemonic: "BIT 7, A") { cpu, _ in cpu.checkBit(index: 7, of: cpu.a) },
    ]

    // 0xCB8n
    static let rangeCb8nOpcodes: [Opcode] = [
        Opcode(mnemonic: "RES 0, B") { cpu, _ in cpu.resetBit(index: 0, of: &cpu.b) },
        Opcode(mnemonic: "RES 0, C") { cpu, _ in cpu.resetBit(index: 0, of: &cpu.c) },
        Opcode(mnemonic: "RES 0, D") { cpu, _ in cpu.resetBit(index: 0, of: &cpu.d) },
        Opcode(mnemonic: "RES 0, E") { cpu, _ in cpu.resetBit(index: 0, of: &cpu.e) },
        Opcode(mnemonic: "RES 0, H") { cpu, _ in cpu.resetBit(index: 0, of: &cpu.h) },
        Opcode(mnemonic: "RES 0, L") { cpu, _ in cpu.resetBit(index: 0, of: &cpu.l) },
        Opcode(mnemonic: "RES 0, (HL)") { cpu, ctx in cpu.resetBit(index: 0, of: cpu.hl, context: ctx) },
        Opcode(mnemonic: "RES 0, A") { cpu, _ in cpu.resetBit(index: 0, of: &cpu.a) },
        Opcode(mnemonic: "RES 1, B") { cpu, _ in cpu.resetBit(index: 1, of: &cpu.b) },
        Opcode(mnemonic: "RES 1, C") { cpu, _ in cpu.resetBit(index: 1, of: &cpu.c) },
        Opcode(mnemonic: "RES 1, D") { cpu, _ in cpu.resetBit(index: 1, of: &cpu.d) },
        Opcode(mnemonic: "RES 1, E") { cpu, _ in cpu.resetBit(index: 1, of: &cpu.e) },
        Opcode(mnemonic: "RES 1, H") { cpu, _ in cpu.resetBit(index: 1, of: &cpu.h) },
        Opcode(mnemonic: "RES 1, L") { cpu, _ in cpu.resetBit(index: 1, of: &cpu.l) },
        Opcode(mnemonic: "RES 1, (HL)") { cpu, ctx in cpu.resetBit(index: 1, of: cpu.hl, context: ctx) },
        Opcode(mnemonic: "RES 1, A") { cpu, _ in cpu.resetBit(index: 1, of: &cpu.a) },
    ]

    // 0xCB9n
    static let rangeCb9nOpcodes: [Opcode] = [
        Opcode(mnemonic: "RES 2, B") { cpu, _ in cpu.resetBit(index: 2, of: &cpu.b) },
        Opcode(mnemonic: "RES 2, C") { cpu, _ in cpu.resetBit(index: 2, of: &cpu.c) },
        Opcode(mnemonic: "RES 2, D") { cpu, _ in cpu.resetBit(index: 2, of: &cpu.d) },
        Opcode(mnemonic: "RES 2, E") { cpu, _ in cpu.resetBit(index: 2, of: &cpu.e) },
        Opcode(mnemonic: "RES 2, H") { cpu, _ in cpu.resetBit(index: 2, of: &cpu.h) },
        Opcode(mnemonic: "RES 2, L") { cpu, _ in cpu.resetBit(index: 2, of: &cpu.l) },
        Opcode(mnemonic: "RES 2, (HL)") { cpu, ctx in cpu.resetBit(index: 2, of: cpu.hl, context: ctx) },
        Opcode(mnemonic: "RES 2, A") { cpu, _ in cpu.resetBit(index: 2, of: &cpu.a) },
        Opcode(mnemonic: "RES 3, B") { cpu, _ in cpu.resetBit(index: 3, of: &cpu.b) },
        Opcode(mnemonic: "RES 3, C") { cpu, _ in cpu.resetBit(index: 3, of: &cpu.c) },
        Opcode(mnemonic: "RES 3, D") { cpu, _ in cpu.resetBit(index: 3, of: &cpu.d) },
        Opcode(mnemonic: "RES 3, E") { cpu, _ in cpu.resetBit(index: 3, of: &cpu.e) },
        Opcode(mnemonic: "RES 3, H") { cpu, _ in cpu.resetBit(index: 3, of: &cpu.h) },
        Opcode(mnemonic: "RES 3, L") { cpu, _ in cpu.resetBit(index: 3, of: &cpu.l) },
        Opcode(mnemonic: "RES 3, (HL)") { cpu, ctx in cpu.resetBit(index: 3, of: cpu.hl, context: ctx) },
        Opcode(mnemonic: "RES 3, A") { cpu, _ in cpu.resetBit(index: 3, of: &cpu.a) },
    ]

    // 0xCBAn
    static let rangeCbAnOpcodes: [Opcode] = [
        Opcode(mnemonic: "RES 4, B") { cpu, _ in cpu.resetBit(index: 4, of: &cpu.b) },
        Opcode(mnemonic: "RES 4, C") { cpu, _ in cpu.resetBit(index: 4, of: &cpu.c) },
        Opcode(mnemonic: "RES 4, D") { cpu, _ in cpu.resetBit(index: 4, of: &cpu.d) },
        Opcode(mnemonic: "RES 4, E") { cpu, _ in cpu.resetBit(index: 4, of: &cpu.e) },
        Opcode(mnemonic: "RES 4, H") { cpu, _ in cpu.resetBit(index: 4, of: &cpu.h) },
        Opcode(mnemonic: "RES 4, L") { cpu, _ in cpu.resetBit(index: 4, of: &cpu.l) },
        Opcode(mnemonic: "RES 4, (HL)") { cpu, ctx in cpu.resetBit(index: 4, of: cpu.hl, context: ctx) },
        Opcode(mnemonic: "RES 4, A") { cpu, _ in cpu.resetBit(index: 4, of: &cpu.a) },
        Opcode(mnemonic: "RES 5, B") { cpu, _ in cpu.resetBit(index: 5, of: &cpu.b) },
        Opcode(mnemonic: "RES 5, C") { cpu, _ in cpu.resetBit(index: 5, of: &cpu.c) },
        Opcode(mnemonic: "RES 5, D") { cpu, _ in cpu.resetBit(index: 5, of: &cpu.d) },
        Opcode(mnemonic: "RES 5, E") { cpu, _ in cpu.resetBit(index: 5, of: &cpu.e) },
        Opcode(mnemonic: "RES 5, H") { cpu, _ in cpu.resetBit(index: 5, of: &cpu.h) },
        Opcode(mnemonic: "RES 5, L") { cpu, _ in cpu.resetBit(index: 5, of: &cpu.l) },
        Opcode(mnemonic: "RES 5, (HL)") { cpu, ctx in cpu.resetBit(index: 5, of: cpu.hl, context: ctx) },
        Opcode(mnemonic: "RES 5, A") { cpu, _ in cpu.resetBit(index: 5, of: &cpu.a) },
    ]

    // 0xCBBn
    static let rangeCbBnOpcodes: [Opcode] = [
        Opcode(mnemonic: "RES 6, B") { cpu, _ in cpu.resetBit(index: 6, of: &cpu.b) },
        Opcode(mnemonic: "RES 6, C") { cpu, _ in cpu.resetBit(index: 6, of: &cpu.c) },
        Opcode(mnemonic: "RES 6, D") { cpu, _ in cpu.resetBit(index: 6, of: &cpu.d) },
        Opcode(mnemonic: "RES 6, E") { cpu, _ in cpu.resetBit(index: 6, of: &cpu.e) },
        Opcode(mnemonic: "RES 6, H") { cpu, _ in cpu.resetBit(index: 6, of: &cpu.h) },
        Opcode(mnemonic: "RES 6, L") { cpu, _ in cpu.resetBit(index: 6, of: &cpu.l) },
        Opcode(mnemonic: "RES 6, (HL)") { cpu, ctx in cpu.resetBit(index: 6, of: cpu.hl, context: ctx) },
        Opcode(mnemonic: "RES 6, A") { cpu, _ in cpu.resetBit(index: 6, of: &cpu.a) },
        Opcode(mnemonic: "RES 7, B") { cpu, _ in cpu.resetBit(index: 7, of: &cpu.b) },
        Opcode(mnemonic: "RES 7, C") { cpu, _ in cpu.resetBit(index: 7, of: &cpu.c) },
        Opcode(mnemonic: "RES 7, D") { cpu, _ in cpu.resetBit(index: 7, of: &cpu.d) },
        Opcode(mnemonic: "RES 7, E") { cpu, _ in cpu.resetBit(index: 7, of: &cpu.e) },
        Opcode(mnemonic: "RES 7, H") { cpu, _ in cpu.resetBit(index: 7, of: &cpu.h) },
        Opcode(mnemonic: "RES 7, L") { cpu, _ in cpu.resetBit(index: 7, of: &cpu.l) },
        Opcode(mnemonic: "RES 7, (HL)") { cpu, ctx in cpu.resetBit(index: 7, of: cpu.hl, context: ctx) },
        Opcode(mnemonic: "RES 7, A") { cpu, _ in cpu.resetBit(index: 7, of: &cpu.a) },
    ]

    // 0xCBCn
    static let rangeCbCnOpcodes: [Opcode] = [
        Opcode(mnemonic: "SET 0, B") { cpu, _ in cpu.setBit(index: 0, of: &cpu.b) },
        Opcode(mnemonic: "SET 0, C") { cpu, _ in cpu.setBit(index: 0, of: &cpu.c) },
        Opcode(mnemonic: "SET 0, D") { cpu, _ in cpu.setBit(index: 0, of: &cpu.d) },
        Opcode(mnemonic: "SET 0, E") { cpu, _ in cpu.setBit(index: 0, of: &cpu.e) },
        Opcode(mnemonic: "SET 0, H") { cpu, _ in cpu.setBit(index: 0, of: &cpu.h) },
        Opcode(mnemonic: "SET 0, L") { cpu, _ in cpu.setBit(index: 0, of: &cpu.l) },
        Opcode(mnemonic: "SET 0, (HL)") { cpu, ctx in cpu.setBit(index: 0, of: cpu.hl, context: ctx) },
        Opcode(mnemonic: "SET 0, A") { cpu, _ in cpu.setBit(index: 0, of: &cpu.a) },
        Opcode(mnemonic: "SET 1, B") { cpu, _ in cpu.setBit(index: 1, of: &cpu.b) },
        Opcode(mnemonic: "SET 1, C") { cpu, _ in cpu.setBit(index: 1, of: &cpu.c) },
        Opcode(mnemonic: "SET 1, D") { cpu, _ in cpu.setBit(index: 1, of: &cpu.d) },
        Opcode(mnemonic: "SET 1, E") { cpu, _ in cpu.setBit(index: 1, of: &cpu.e) },
        Opcode(mnemonic: "SET 1, H") { cpu, _ in cpu.setBit(index: 1, of: &cpu.h) },
        Opcode(mnemonic: "SET 1, L") { cpu, _ in cpu.setBit(index: 1, of: &cpu.l) },
        Opcode(mnemonic: "SET 1, (HL)") { cpu, ctx in cpu.setBit(index: 1, of: cpu.hl, context: ctx) },
        Opcode(mnemonic: "SET 1, A") { cpu, _ in cpu.setBit(index: 1, of: &cpu.a) },
    ]

    // 0xCBDn
    static let rangeCbDnOpcodes: [Opcode] = [
        Opcode(mnemonic: "SET 2, B") { cpu, _ in cpu.setBit(index: 2, of: &cpu.b) },
        Opcode(mnemonic: "SET 2, C") { cpu, _ in cpu.setBit(index: 2, of: &cpu.c) },
        Opcode(mnemonic: "SET 2, D") { cpu, _ in cpu.setBit(index: 2, of: &cpu.d) },
        Opcode(mnemonic: "SET 2, E") { cpu, _ in cpu.setBit(index: 2, of: &cpu.e) },
        Opcode(mnemonic: "SET 2, H") { cpu, _ in cpu.setBit(index: 2, of: &cpu.h) },
        Opcode(mnemonic: "SET 2, L") { cpu, _ in cpu.setBit(index: 2, of: &cpu.l) },
        Opcode(mnemonic: "SET 2, (HL)") { cpu, ctx in cpu.setBit(index: 2, of: cpu.hl, context: ctx) },
        Opcode(mnemonic: "SET 2, A") { cpu, _ in cpu.setBit(index: 2, of: &cpu.a) },
        Opcode(mnemonic: "SET 3, B") { cpu, _ in cpu.setBit(index: 3, of: &cpu.b) },
        Opcode(mnemonic: "SET 3, C") { cpu, _ in cpu.setBit(index: 3, of: &cpu.c) },
        Opcode(mnemonic: "SET 3, D") { cpu, _ in cpu.setBit(index: 3, of: &cpu.d) },
        Opcode(mnemonic: "SET 3, E") { cpu, _ in cpu.setBit(index: 3, of: &cpu.e) },
        Opcode(mnemonic: "SET 3, H") { cpu, _ in cpu.setBit(index: 3, of: &cpu.h) },
        Opcode(mnemonic: "SET 3, L") { cpu, _ in cpu.setBit(index: 3, of: &cpu.l) },
        Opcode(mnemonic: "SET 3, (HL)") { cpu, ctx in cpu.setBit(index: 3, of: cpu.hl, context: ctx) },
        Opcode(mnemonic: "SET 3, A") { cpu, _ in cpu.setBit(index: 3, of: &cpu.a) },
    ]

    // 0xCBEn
    static let rangeCbEnOpcodes: [Opcode] = [
        Opcode(mnemonic: "SET 4, B") { cpu, _ in cpu.setBit(index: 4, of: &cpu.b) },
        Opcode(mnemonic: "SET 4, C") { cpu, _ in cpu.setBit(index: 4, of: &cpu.c) },
        Opcode(mnemonic: "SET 4, D") { cpu, _ in cpu.setBit(index: 4, of: &cpu.d) },
        Opcode(mnemonic: "SET 4, E") { cpu, _ in cpu.setBit(index: 4, of: &cpu.e) },
        Opcode(mnemonic: "SET 4, H") { cpu, _ in cpu.setBit(index: 4, of: &cpu.h) },
        Opcode(mnemonic: "SET 4, L") { cpu, _ in cpu.setBit(index: 4, of: &cpu.l) },
        Opcode(mnemonic: "SET 4, (HL)") { cpu, ctx in cpu.setBit(index: 4, of: cpu.hl, context: ctx) },
        Opcode(mnemonic: "SET 4, A") { cpu, _ in cpu.setBit(index: 4, of: &cpu.a) },
        Opcode(mnemonic: "SET 5, B") { cpu, _ in cpu.setBit(index: 5, of: &cpu.b) },
        Opcode(mnemonic: "SET 5, C") { cpu, _ in cpu.setBit(index: 5, of: &cpu.c) },
        Opcode(mnemonic: "SET 5, D") { cpu, _ in cpu.setBit(index: 5, of: &cpu.d) },
        Opcode(mnemonic: "SET 5, E") { cpu, _ in cpu.setBit(index: 5, of: &cpu.e) },
        Opcode(mnemonic: "SET 5, H") { cpu, _ in cpu.setBit(index: 5, of: &cpu.h) },
        Opcode(mnemonic: "SET 5, L") { cpu, _ in cpu.setBit(index: 5, of: &cpu.l) },
        Opcode(mnemonic: "SET 5, (HL)") { cpu, ctx in cpu.setBit(index: 5, of: cpu.hl, context: ctx) },
        Opcode(mnemonic: "SET 5, A") { cpu, _ in cpu.setBit(index: 5, of: &cpu.a) },
    ]

    // 0xCBFn
    static let rangeCbFnOpcodes: [Opcode] = [
        Opcode(mnemonic: "SET 6, B") { cpu, _ in cpu.setBit(index: 6, of: &cpu.b) },
        Opcode(mnemonic: "SET 6, C") { cpu, _ in cpu.setBit(index: 6, of: &cpu.c) },
        Opcode(mnemonic: "SET 6, D") { cpu, _ in cpu.setBit(index: 6, of: &cpu.d) },
        Opcode(mnemonic: "SET 6, E") { cpu, _ in cpu.setBit(index: 6, of: &cpu.e) },
        Opcode(mnemonic: "SET 6, H") { cpu, _ in cpu.setBit(index: 6, of: &cpu.h) },
        Opcode(mnemonic: "SET 6, L") { cpu, _ in cpu.setBit(index: 6, of: &cpu.l) },
        Opcode(mnemonic: "SET 6, (HL)") { cpu, ctx in cpu.setBit(index: 6, of: cpu.hl, context: ctx) },
        Opcode(mnemonic: "SET 6, A") { cpu, _ in cpu.setBit(index: 6, of: &cpu.a) },
        Opcode(mnemonic: "SET 7, B") { cpu, _ in cpu.setBit(index: 7, of: &cpu.b) },
        Opcode(mnemonic: "SET 7, C") { cpu, _ in cpu.setBit(index: 7, of: &cpu.c) },
        Opcode(mnemonic: "SET 7, D") { cpu, _ in cpu.setBit(index: 7, of: &cpu.d) },
        Opcode(mnemonic: "SET 7, E") { cpu, _ in cpu.setBit(index: 7, of: &cpu.e) },
        Opcode(mnemonic: "SET 7, H") { cpu, _ in cpu.setBit(index: 7, of: &cpu.h) },
        Opcode(mnemonic: "SET 7, L") { cpu, _ in cpu.setBit(index: 7, of: &cpu.l) },
        Opcode(mnemonic: "SET 7, (HL)") { cpu, ctx in cpu.setBit(index: 7, of: cpu.hl, context: ctx) },
        Opcode(mnemonic: "SET 7, A") { cpu, _ in cpu.setBit(index: 7, of: &cpu.a) }
    ]
}
