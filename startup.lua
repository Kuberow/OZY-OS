shell.run("vm.lua kernel.bin")
term.clear()
term.setCursorPos(1,1)
print("Its safe to unplug your computer now.") -- message for rpi when using CraftOS-Pi
os.shutdown()
