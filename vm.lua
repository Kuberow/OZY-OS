-- Virtual cpu here:
-- 32-bit Virtual CPU Emulator - Fixed Instruction Decoding
-- Corrected register field extraction

local bit32 = bit32 or require("bit32")
if not bit32 then
    error("bit32 library not available")
end

-- CPU State
local registers = {[0]=0, [1]=0, [2]=0, [3]=0, [4]=0, [5]=0, [6]=0, [7]=0}
local memory = {}
local pc = 0
local sp = 0x100000
local running = false
local debug_mode = true

-- Initialize memory
for i = 0, 0xFFFFF do memory[i] = 0 end

-- Instruction set
local INSTRUCTIONS = {
    [0x01] = "ADD",   -- ADD Rd, Rn, Rm
    [0x02] = "SUB",   -- SUB Rd, Rn, Rm
    [0x03] = "MOV",   -- MOV Rd, Rm
    [0x04] = "MOVI",  -- MOVI Rd, imm
    [0x05] = "LDR",   -- LDR Rd, [Rn]
    [0x06] = "STR",   -- STR Rd, [Rn]
    [0x07] = "B",     -- B addr
    [0x08] = "BEQ",   -- BEQ addr
    [0x09] = "BNE",   -- BNE addr
    [0x0A] = "PUSH",  -- PUSH Rm
    [0x0B] = "POP",   -- POP Rd
    [0xFF] = "HALT"   -- HALT
}

-- Read 32-bit value from memory (big-endian)
local function read32(addr)
    if addr % 4 ~= 0 then
        error("Unaligned memory access: " .. addr)
    end
    
    local b0 = memory[addr] or 0
    local b1 = memory[addr+1] or 0
    local b2 = memory[addr+2] or 0
    local b3 = memory[addr+3] or 0
    
    return bit32.bor(
        bit32.lshift(b0, 24),
        bit32.lshift(b1, 16),
        bit32.lshift(b2, 8),
        b3
    )
end

-- Write 32-bit value to memory (big-endian)
local function write32(addr, value)
    if addr % 4 ~= 0 then
        error("Unaligned memory access: " .. addr)
    end
    
    memory[addr]   = bit32.band(bit32.rshift(value, 24), 0xFF)
    memory[addr+1] = bit32.band(bit32.rshift(value, 16), 0xFF)
    memory[addr+2] = bit32.band(bit32.rshift(value, 8), 0xFF)
    memory[addr+3] = bit32.band(value, 0xFF)
end

-- Load program as array of 32-bit instructions
function load_program(instructions, start_addr)
    for i, instr in ipairs(instructions) do
        write32(start_addr + (i-1)*4, instr)
    end
    
    pc = start_addr
    sp = 0x100000
    running = true
    
    if debug_mode then
        print("Program loaded at address 0x" .. string.format("%X", start_addr))
        print("First instruction: 0x" .. string.format("%X", read32(start_addr)))
    end
end

-- Execute one instruction
function step()
    if not running then
        return false, "CPU not running"
    end
    
    if pc >= 0x100000 then
        running = false
        return false, "PC out of bounds"
    end
    
    -- Fetch instruction
    local instruction = read32(pc)
    local opcode = bit32.rshift(instruction, 24)
    local rd = bit32.band(bit32.rshift(instruction, 20), 0xF)
    local rn = bit32.band(bit32.rshift(instruction, 16), 0xF)
    local rm = bit32.band(bit32.rshift(instruction, 12), 0xF)  -- Fixed: extract from bits 15:12
    local imm = bit32.band(instruction, 0xFFF)  -- Fixed: 12-bit immediate
    local addr = bit32.band(instruction, 0xFFFFFF)  -- 24-bit address for branches
    
    if debug_mode then
        local op_name = INSTRUCTIONS[opcode] or "UNKNOWN"
        print(string.format("PC:0x%08X | OP:0x%02X (%s) | R%d, R%d, R%d | IMM:0x%03X | ADDR:0x%06X", 
              pc, opcode, op_name, rd, rn, rm, imm, addr))
    end
    
    -- Move to next instruction
    pc = pc + 4
    
    -- Execute instruction
    if opcode == 0x01 then -- ADD Rd, Rn, Rm
        registers[rd] = registers[rn] + registers[rm]
        
    elseif opcode == 0x02 then -- SUB Rd, Rn, Rm
        registers[rd] = registers[rn] - registers[rm]
        
    elseif opcode == 0x03 then -- MOV Rd, Rm
        registers[rd] = registers[rm]
        
    elseif opcode == 0x04 then -- MOVI Rd, imm
        registers[rd] = imm
        
    elseif opcode == 0x05 then -- LDR Rd, [Rn]
        registers[rd] = read32(registers[rn])
        
    elseif opcode == 0x06 then -- STR Rd, [Rn]
        write32(registers[rn], registers[rd])
        
    elseif opcode == 0x07 then -- B addr
        pc = addr
        
    elseif opcode == 0x08 then -- BEQ addr
        if registers[0] == 0 then pc = addr end
        
    elseif opcode == 0x09 then -- BNE addr
        if registers[0] ~= 0 then pc = addr end
        
    elseif opcode == 0x0A then -- PUSH Rm
        sp = sp - 4
        write32(sp, registers[rm])
        
    elseif opcode == 0x0B then -- POP Rd
        registers[rd] = read32(sp)
        sp = sp + 4
        
    elseif opcode == 0xFF then -- HALT
        running = false
        return true, "HALT instruction"
        
    else
        return false, "Invalid opcode: 0x" .. string.format("%X", opcode)
    end
    
    return true
end

-- Run program with optional instruction limit
function run(max_instructions)
    local instruction_count = 0
    local status, err
    
    while running do
        status, err = step()
        if not status then
            print("Error: " .. err)
            break
        end
        
        instruction_count = instruction_count + 1
        if max_instructions and instruction_count >= max_instructions then
            print("Reached maximum instruction limit")
            break
        end
    end
    
    if debug_mode then
        print("\nExecution completed after " .. instruction_count .. " instructions")
        print("Final register state:")
        for i = 0, 7 do
            print("R" .. i .. ": 0x" .. string.format("%08X", registers[i]))
        end
        print("PC: 0x" .. string.format("%X", pc))
        print("SP: 0x" .. string.format("%X", sp))
    end
end

-- Helper function to create instructions
function make_instruction(opcode, rd, rn, rm, imm_or_addr)
    local instr = bit32.lshift(opcode, 24)
    instr = bit32.bor(instr, bit32.lshift(rd, 20))
    instr = bit32.bor(instr, bit32.lshift(rn, 16))
    instr = bit32.bor(instr, bit32.lshift(rm, 12))
    instr = bit32.bor(instr, bit32.band(imm_or_addr, 0xFFF))
    return instr
end

-- Create a simple test program
local function test_program()
    -- Program that calculates 5 + 3 and stores the result
    local program = {
        -- MOVI R0, 5
        make_instruction(0x04, 0, 0, 0, 5),
        -- MOVI R1, 3
        make_instruction(0x04, 1, 0, 0, 3),
        -- ADD R2, R0, R1
        make_instruction(0x01, 2, 0, 1, 0),
        -- HALT
        make_instruction(0xFF, 0, 0, 0, 0)
    }
    
    print("Running test program (5 + 3)...")
    load_program(program, 0)
    run(10)
    
    print("\nResult: R2 = " .. registers[2] .. " (should be 8)")
end

-- Run the test
test_program()
