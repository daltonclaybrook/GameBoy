#if DEBUG
public extension CPU {
    func assertRegistersAreCorrectAfterBoot() {
        assert(af == 0x01b0)
        assert(bc == 0x0013)
        assert(de == 0x00d8)
        assert(hl == 0x014d)
        assert(sp == 0xfffe)

//        assert(mmu.read(address: 0xffff) == 0x00)
//        assert(mmu.read(address: 0xff05) == 0x00)
//        assert(mmu.read(address: 0xff06) == 0x00)
//        assert(mmu.read(address: 0xff07) == 0x00)
//        assert(mmu.read(address: 0xff10) == 0x80)
//        assert(mmu.read(address: 0xff11) == 0xbf)
//        assert(mmu.read(address: 0xff12) == 0xf3)
//        assert(mmu.read(address: 0xff14) == 0xbf)
//        assert(mmu.read(address: 0xff16) == 0x3f)
//        assert(mmu.read(address: 0xff17) == 0x00)
//        assert(mmu.read(address: 0xff19) == 0xbf)
//        assert(mmu.read(address: 0xff1a) == 0x7f)
//        assert(mmu.read(address: 0xff1b) == 0xff)
//        assert(mmu.read(address: 0xff1c) == 0x9f)
//        assert(mmu.read(address: 0xff1e) == 0xbf)
//        assert(mmu.read(address: 0xff20) == 0xff)
//        assert(mmu.read(address: 0xff21) == 0x00)
//        assert(mmu.read(address: 0xff22) == 0x00)
//        assert(mmu.read(address: 0xff23) == 0xbf)
//        assert(mmu.read(address: 0xff24) == 0x77)
//        assert(mmu.read(address: 0xff25) == 0xf3)
//        assert(mmu.read(address: 0xff26) == 0xf1)
//        assert(mmu.read(address: 0xff40) == 0x91)
//        assert(mmu.read(address: 0xff42) == 0x00)
//        assert(mmu.read(address: 0xff43) == 0x00)
//        assert(mmu.read(address: 0xff45) == 0x00)
//        assert(mmu.read(address: 0xff47) == 0xfc)
//        assert(mmu.read(address: 0xff48) == 0xff)
//        assert(mmu.read(address: 0xff49) == 0xff)
//        assert(mmu.read(address: 0xff4a) == 0x00)
//        assert(mmu.read(address: 0xff4b) == 0x00)
//        assert(mmu.read(address: 0xffff) == 0x00)
    }
}
#endif
