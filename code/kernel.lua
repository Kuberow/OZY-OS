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
  if fs.exists("/bin/"..inc) then
  shell.run("/bin/"..inc)
  else
    redError("Unknown Command: "..inc)
  end
end


print("Running in admin mode!")
main("admin")
term.clear()
os.shutdown()
