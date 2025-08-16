-- ARM Virtual CPU for CC:Tweaked (Clean Version)
local bit = bit32 or require("bit")

local ARMvCPU = {
    registers = {},
    memory = {},
    flags = {N = false, Z = false, C = false, V = false},
    running = false,
    syscalls = {}
}

function ARMvCPU:init()
    self.registers = {}
    for i = 0, 15 do self.registers[i] = 0 end
    self.flags = {N = false, Z = false, C = false, V = false}
    self.memory = {}
    self.running = false
    self.syscalls = {}
end

function ARMvCPU:loadBinary(path, baseAddress)
    local file = fs.open(path, "rb")
    if not file then error("File not found: " .. path) end
    
    local data = file.readAll()
    file.close()
    
    for i = 1, #data do
        self.memory[baseAddress + i - 1] = data:byte(i)
    end
end

function ARMvCPU:read8(addr)
    return self.memory[addr] or 0
end

function ARMvCPU:write8(addr, value)
    self.memory[addr] = bit.band(value, 0xFF)
end

function ARMvCPU:read32(addr)
    return (self:read8(addr)) +
           (self:read8(addr+1) * 0x100) +
           (self:read8(addr+2) * 0x10000) +
           (self:read8(addr+3) * 0x1000000)
end

function ARMvCPU:write32(addr, value)
    self:write8(addr, bit.band(value, 0xFF))
    self:write8(addr+1, bit.band(bit.rshift(value, 8), 0xFF))
    self:write8(addr+2, bit.band(bit.rshift(value, 16), 0xFF))
    self:write8(addr+3, bit.band(bit.rshift(value, 24), 0xFF))
end

function ARMvCPU:checkCondition(cond)
    if cond == 0x0 then
        return self.flags.Z
    elseif cond == 0x1 then
        return not self.flags.Z
    elseif cond == 0x2 then
        return self.flags.C
    elseif cond == 0x3 then
        return not self.flags.C
    elseif cond == 0x4 then
        return self.flags.N
    elseif cond == 0x5 then
        return not self.flags.N
    elseif cond == 0x6 then
        return self.flags.V
    elseif cond == 0x7 then
        return not self.flags.V
    elseif cond == 0x8 then
        return self.flags.C and not self.flags.Z
    elseif cond == 0x9 then
        return not (self.flags.C and not self.flags.Z)
    elseif cond == 0xA then
        return self.flags.N == self.flags.V
    elseif cond == 0xB then
        return self.flags.N ~= self.flags.V
    elseif cond == 0xC then
        return not self.flags.Z and (self.flags.N == self.flags.V)
    elseif cond == 0xD then
        return self.flags.Z or (self.flags.N ~= self.flags.V)
    elseif cond == 0xE then
        return true
    else
        return false
    end
end


function ARMvCPU:shiftOperand(operand, shiftType, shiftAmount)
    local result = operand
    local carry = self.flags.C
    
    if shiftAmount == 0 then
        return result, carry
    end
    
    if shiftType == 0 then
        if shiftAmount > 32 then
            result = 0
            carry = bit.band(operand, 1) ~= 0
        else
            result = bit.lshift(operand, shiftAmount)
            carry = bit.band(bit.rshift(operand, 32 - shiftAmount), 1) ~= 0
        end
    elseif shiftType == 1 then
        if shiftAmount > 32 then
            result = 0
            carry = bit.band(bit.rshift(operand, 31), 1) ~= 0
        else
            result = bit.rshift(operand, shiftAmount)
            carry = bit.band(bit.rshift(operand, shiftAmount - 1), 1) ~= 0
        end
    elseif shiftType == 2 then
        if shiftAmount >= 32 then
            result = (bit.band(operand, 0x80000000) ~= 0) and 0xFFFFFFFF or 0
            carry = bit.band(operand, 0x80000000) ~= 0
        else
            result = bit.arshift(operand, shiftAmount)
            carry = bit.band(bit.rshift(operand, shiftAmount - 1), 1) ~= 0
        end
    elseif shiftType == 3 then
        shiftAmount = bit.band(shiftAmount, 0x1F)
        if shiftAmount == 0 then
            result = operand
            carry = bit.band(operand, 0x80000000) ~= 0
        else
            result = bit.ror(operand, shiftAmount)
            carry = bit.band(operand, bit.lshift(1, shiftAmount - 1)) ~= 0
        end
    end
    
    return result, carry
end

function ARMvCPU:step()
    local pc = self.registers[15]
    local instr = self:read32(pc)
    self.registers[15] = pc + 4
    
    local cond = bit.rshift(instr, 28)
    if not self:checkCondition(cond) then
        return
    end
    
    local opcode = bit.band(bit.rshift(instr, 21), 0xF)
    local rd = bit.band(bit.rshift(instr, 12), 0xF)
    local rn = bit.band(bit.rshift(instr, 16), 0xF)
    local rm = bit.band(instr, 0xF)
    local imm = bit.band(instr, 0xFFF)
    
    if bit.band(bit.rshift(instr, 26), 0x3) == 0 then
        local I = bit.band(bit.rshift(instr, 25), 1) ~= 0
        local S = bit.band(bit.rshift(instr, 20), 1) ~= 0
        local op2
        local carry = self.flags.C
        
        if I then
            local immVal = bit.band(imm, 0xFF)
            local rotate = bit.band(bit.rshift(imm, 8), 0xF)
            op2 = bit.ror(immVal, rotate * 2)
        else
            local shiftType = bit.band(bit.rshift(instr, 5), 0x3)
            local shiftAmount
            if bit.band(bit.rshift(instr, 4), 1) ~= 0 then
                local rs = bit.band(bit.rshift(instr, 8), 0xF)
                shiftAmount = bit.band(self.registers[rs], 0xFF)
            else
                shiftAmount = bit.band(bit.rshift(instr, 7), 0x1F)
            end
            op2, carry = self:shiftOperand(self.registers[rm], shiftType, shiftAmount)
        end
        
        local result
        if opcode == 0x0 then
            result = bit.band(self.registers[rn], op2)
            self.registers[rd] = result
        elseif opcode == 0x1 then
            result = bit.bxor(self.registers[rn], op2)
            self.registers[rd] = result
        elseif opcode == 0x2 then
            result = self.registers[rn] - op2
            self.registers[rd] = result
        elseif opcode == 0x3 then
            result = op2 - self.registers[rn]
            self.registers[rd] = result
        elseif opcode == 0x4 then
            result = self.registers[rn] + op2
            self.registers[rd] = result
        elseif opcode == 0x5 then
            result = self.registers[rn] + op2 + (self.flags.C and 1 or 0)
            self.registers[rd] = result
        elseif opcode == 0x6 then
            result = self.registers[rn] - op2 - (self.flags.C and 0 or 1)
            self.registers[rd] = result
        elseif opcode == 0x7 then
            result = op2 - self.registers[rn] - (self.flags.C and 0 or 1)
            self.registers[rd] = result
        elseif opcode == 0x8 then
            result = bit.band(self.registers[rn], op2)
        elseif opcode == 0x9 then
            result = bit.bxor(self.registers[rn], op2)
        elseif opcode == 0xA then
            result = self.registers[rn] - op2
        elseif opcode == 0xB then
            result = self.registers[rn] + op2
        elseif opcode == 0xC then
            result = bit.bor(self.registers[rn], op2)
            self.registers[rd] = result
        elseif opcode == 0xD then
            result = op2
            self.registers[rd] = result
        elseif opcode == 0xE then
            result = bit.band(self.registers[rn], bit.bnot(op2))
            self.registers[rd] = result
        elseif opcode == 0xF then
            result = bit.bnot(op2)
            self.registers[rd] = result
        end
        
        if S then
            self.flags.N = bit.band(result, 0x80000000) ~= 0
            self.flags.Z = result == 0
            self.flags.C = carry
        end
        
    elseif bit.band(bit.rshift(instr, 26), 0x3) == 1 then
        local P = bit.band(bit.rshift(instr, 24), 1) ~= 0
        local U = bit.band(bit.rshift(instr, 23), 1) ~= 0
        local B = bit.band(bit.rshift(instr, 22), 1) ~= 0
        local W = bit.band(bit.rshift(instr, 21), 1) ~= 0
        local L = bit.band(bit.rshift(instr, 20), 1) ~= 0
        local offset
        
        if bit.band(bit.rshift(instr, 25), 1) ~= 0 then
            offset = bit.band(instr, 0xFFF)
        else
            local rm = bit.band(instr, 0xF)
            local shiftType = bit.band(bit.rshift(instr, 5), 0x3)
            local shiftAmount = bit.band(bit.rshift(instr, 7), 0x1F)
            offset, _ = self:shiftOperand(self.registers[rm], shiftType, shiftAmount)
        end
        
        local addr = self.registers[rn]
        if P then
            addr = addr + (U and offset or -offset)
        end
        
        if L then
            if B then
                self.registers[rd] = self:read8(addr)
            else
                self.registers[rd] = self:read32(addr)
            end
        else
            if B then
                self:write8(addr, bit.band(self.registers[rd], 0xFF))
            else
                self:write32(addr, self.registers[rd])
            end
        end
        
        if not P then
            self.registers[rn] = self.registers[rn] + (U and offset or -offset)
        elseif W then
            self.registers[rn] = addr
        end
        
    elseif bit.band(bit.rshift(instr, 25), 0x7) == 5 then
        local L = bit.band(bit.rshift(instr, 24), 1) ~= 0
        local offset = bit.band(instr, 0xFFFFFF)
        if bit.band(offset, 0x800000) ~= 0 then
            offset = offset - 0x1000000
        end
        local target = pc + 8 + (offset * 4)
        
        if L then
            self.registers[14] = pc + 4
        end
        self.registers[15] = target
        
    elseif bit.band(bit.rshift(instr, 22), 0x3F) == 0 then
        local A = bit.band(bit.rshift(instr, 21), 1) ~= 0
        local S = bit.band(bit.rshift(instr, 20), 1) ~= 0
        local rd = bit.band(bit.rshift(instr, 16), 0xF)
        local rn = bit.band(bit.rshift(instr, 12), 0xF)
        local rs = bit.band(bit.rshift(instr, 8), 0xF)
        local rm = bit.band(instr, 0xF)
        
        local result = self.registers[rm] * self.registers[rs]
        if A then
            result = result + self.registers[rn]
        end
        self.registers[rd] = result
        
        if S then
            self.flags.N = bit.band(result, 0x80000000) ~= 0
            self.flags.Z = result == 0
        end
        
    elseif bit.band(bit.rshift(instr, 24), 0xF) == 0xF then
        local svcNum = bit.band(instr, 0xFFFFFF)
        if self.syscalls[svcNum] then
            self.syscalls[svcNum](self)
        end
    end
end

function ARMvCPU:registerSyscall(number, handler)
    self.syscalls[number] = handler
end

function ARMvCPU:run(startAddress)
    self.registers[15] = startAddress or 0
    self.running = true
    
    while self.running do
        self:step()
        
        if self.registers[15] == self.registers[14] then
            self.running = false
        end
    end
end

return ARMvCPU
