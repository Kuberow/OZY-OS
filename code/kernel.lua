os.pullEvent = os.pullEventRaw
args = {...}
if not args[1] == "skip" then
local autostartDir = "/autostart/"

if fs.exists(autostartDir) then
    for _, file in ipairs(fs.list(autostartDir)) do
        local path = fs.combine(autostartDir, file)
        if not fs.isDir(path) then
            shell.run(path)
        end
    end
end
end
function main(usr)
  while true do
    fsloc = shell.dir()
    line(colors.white, usr, fsloc)
    cmd = read()
    interpret(cmd)
  end
end

function redError(s)
  term.setTextColor(colors.red)
  print(s)
  term.setTextColor(colors.white)
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
  if inc == "" then
  print(" ")
  else
  if fs.exists(string.match("/bin/"..inc, "^(%S+)")) then
  shell.run("/bin/"..inc)
  else
    redError("Unknown Command: "..inc)
  end
  end
end


print("Running in admin mode!")
main("admin")
term.clear()
