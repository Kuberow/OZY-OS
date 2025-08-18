shell.run("wget", "https://raw.github.com/Kuberow/OZY-OS-Lite/main/code/kernel.lua", "/kernel.lua")
shell.run("wget", "https://raw.github.com/Kuberow/OZY-OS-Lite/main/code/bootloader/main.lua", "/startup.lua")
print("Core Installed.")
sleep(2)
fs.makeDir("bin")
shell.run("wget", "https://raw.github.com/Kuberow/OZY-OS-Lite/main/defcmd/help", "/bin/help")
shell.run("wget", "https://raw.github.com/Kuberow/OZY-OS-Lite/main/defcmd/ozp", "/bin/ozp")
print("Fully Installed.")

