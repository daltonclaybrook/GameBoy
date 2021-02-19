extension GameBoy {
    /// This is used to bypass the boot rom. All necessary CPU and memory
    /// registers are updated with values that would normally be set by
    /// the boot rom. Notably, the PC register is set to 0x100, which is
    /// where the cartridge ROM takes over and begins execution.
    func bootstrap() {
        cpu.flags = 0xb0
        cpu.bc = 0x0013
        cpu.de = 0x00d8
        cpu.sp = 0xfffe
        cpu.pc = 0x100

        switch system {
        case .dmg:
            cpu.a = 0x01
        case .cgb:
            cpu.a = 0x11
        }

        mmu.write(byte: 0x00, to: 0xff05, privileged: true)
        mmu.write(byte: 0x00, to: 0xff06, privileged: true)
        mmu.write(byte: 0x00, to: 0xff07, privileged: true)
        mmu.write(byte: 0x80, to: 0xff10, privileged: true)
        mmu.write(byte: 0xbf, to: 0xff11, privileged: true)
        mmu.write(byte: 0xf3, to: 0xff12, privileged: true)
        mmu.write(byte: 0xbf, to: 0xff14, privileged: true)
        mmu.write(byte: 0x3f, to: 0xff16, privileged: true)
        mmu.write(byte: 0x00, to: 0xff17, privileged: true)
        mmu.write(byte: 0xbf, to: 0xff19, privileged: true)
        mmu.write(byte: 0x7f, to: 0xff1a, privileged: true)
        mmu.write(byte: 0xff, to: 0xff1b, privileged: true)
        mmu.write(byte: 0x9f, to: 0xff1c, privileged: true)
        mmu.write(byte: 0xbf, to: 0xff1e, privileged: true)
        mmu.write(byte: 0xff, to: 0xff20, privileged: true)
        mmu.write(byte: 0x00, to: 0xff21, privileged: true)
        mmu.write(byte: 0x00, to: 0xff22, privileged: true)
        mmu.write(byte: 0xbf, to: 0xff23, privileged: true)
        mmu.write(byte: 0x77, to: 0xff24, privileged: true)
        mmu.write(byte: 0xf3, to: 0xff25, privileged: true)
        mmu.write(byte: 0xf1, to: 0xff26, privileged: true)
        mmu.write(byte: 0x91, to: 0xff40, privileged: true)
        mmu.write(byte: 0x00, to: 0xff42, privileged: true)
        mmu.write(byte: 0x00, to: 0xff43, privileged: true)
        mmu.write(byte: 0x00, to: 0xff45, privileged: true)
        mmu.write(byte: 0xfc, to: 0xff47, privileged: true)
        mmu.write(byte: 0xff, to: 0xff48, privileged: true)
        mmu.write(byte: 0xff, to: 0xff49, privileged: true)
        mmu.write(byte: 0x00, to: 0xff4a, privileged: true)
        mmu.write(byte: 0x00, to: 0xff4b, privileged: true)
        mmu.write(byte: 0x00, to: 0xffff, privileged: true)
    }
}
