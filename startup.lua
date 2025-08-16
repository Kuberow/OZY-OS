local bit = bit32 or require("bit")
local cpu = require("vm")
cpu:init()

-- Syscall 0 = putchar
cpu:registerSyscall(0, function(self)
    local ch = self.registers[0] or 0
    io.write(string.char(bit.band(ch, 0xFF)))
end)

cpu:loadBinary("kernel.bin", 0x0)
cpu:run(0x0)

term.clear()
term.setCursorPos(1,1)
print("Its safe to unplug your computer now.") -- message for rpi when using CraftOS-Pi

