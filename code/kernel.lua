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
  
end

