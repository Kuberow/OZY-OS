function main(usr)
  while running do
    fsloc = fs.getCurrentDir()
    line(colors.white, usr, loc)
    cmd = read()
    interpret(cmd)
  end
end

function line(c, user, loc)
  term.setTextColor(colors.green)
  term.write(user)
  term.setTextColor(colors.white)
  term.write("!")
  term.setTextColor(colors.purple)
  term.write(loc.." | ")
  term.setTextColor(c)
end

function interpret(inc)
  if fs.exists("/bin/"..inc) then
    local filename = inc  -- your custom executable

-- open the file in binary mode
local file = fs.open(filename, "rb")
if not file then error("Cannot open file: "..filename) end

local content = file.readAll()
file.close()

-- check the header
local header = string.sub(content, 1, 4)
if header ~= "OZLE" then
    term.write("Invalid format: ")
    if header == "OZEX" then
    term.write("Not a Lite Format!")
    end
end

-- get the Lua bytecode part
local bytecode = string.sub(content, 5)

-- load and run the bytecode
local f, err = load(bytecode)
if not f then error("Failed to load bytecode: "..err) end
f()
  else
  end
end

