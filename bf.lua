-- bf.lua - Brainfuck interpreter for CC:Tweaked

local args = {...}
if #args < 1 then
  print("Usage: bf <file>")
  return
end

-- Read Brainfuck source
local h = fs.open(args[1], "r")
if not h then
  print("File not found: " .. args[1])
  return
end
local code = h.readAll()
h.close()

-- State
local tape = {}
local ptr = 1
local ip = 1
local loop_stack = {}

for i = 1, 30000 do tape[i] = 0 end

-- Interpreter
while ip <= #code do
  local c = code:sub(ip, ip)
  if c == ">" then
    ptr = ptr + 1
    if ptr > #tape then ptr = 1 end
  elseif c == "<" then
    ptr = ptr - 1
    if ptr < 1 then ptr = #tape end
  elseif c == "+" then
    tape[ptr] = (tape[ptr] + 1) % 256
  elseif c == "-" then
    tape[ptr] = (tape[ptr] - 1) % 256
    if tape[ptr] < 0 then tape[ptr] = 255 end
  elseif c == "." then
    io.write(string.char(tape[ptr]))
  elseif c == "," then
    local ch = read()
    if #ch > 0 then
      tape[ptr] = string.byte(ch:sub(1,1))
    else
      tape[ptr] = 0
    end
  elseif c == "[" then
    if tape[ptr] == 0 then
      local depth = 1
      while depth > 0 do
        ip = ip + 1
        local cc = code:sub(ip, ip)
        if cc == "[" then depth = depth + 1 end
        if cc == "]" then depth = depth - 1 end
      end
    else
      table.insert(loop_stack, ip)
    end
  elseif c == "]" then
    if tape[ptr] ~= 0 then
      ip = loop_stack[#loop_stack]
    else
      table.remove(loop_stack)
    end
  end
  ip = ip + 1
end
