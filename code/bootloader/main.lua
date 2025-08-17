-- Actual GRUB Bootloader Replica
-- Place this file as startup.lua in the root directory

local w, h = term.getSize()
local selected = 1
local timeout = 5
local startTime = os.clock()

-- Boot menu options
local options = {
    {name = "Ozy OS", kernel = "Kernel.lua", action = "ozy"},
    {name = "ComputerCraft OS", action = "computercraft"},
    {name = "Advanced options for Ozy OS", action = "advanced"},
    {name = "System setup", action = "setup"}
}

-- GRUB colors (exactly like real GRUB)
local grub_bg = colors.black
local grub_text = colors.white
local grub_selected_bg = colors.white
local grub_selected_text = colors.black
local grub_highlight = colors.lightBlue

-- Initialize screen exactly like GRUB
local function initScreen()
    term.setBackgroundColor(grub_bg)
    term.setTextColor(grub_text)
    term.clear()
end

-- Draw exactly like real GRUB header
local function drawGrubHeader()
    term.setCursorPos(1, 1)
    term.write("              OZY RUB  version 1.0.0")
    term.setCursorPos(1, 2)
    term.write("")
    term.setCursorPos(1, 3)
    term.write(" +" .. string.rep("-", w-4) .. "+")
    term.setCursorPos(1, 4)
    term.write(" |" .. string.rep(" ", w-4) .. "|")
end

-- Draw the menu exactly like GRUB
local function drawGrubMenu()
    local menuStart = 5
    local menuWidth = w - 4
    
    for i, option in ipairs(options) do
        local line = menuStart + i - 1
        term.setCursorPos(1, line)
        
        if i == selected then
            -- Selected item (white background, black text)
            term.write(" |")
            term.setBackgroundColor(grub_selected_bg)
            term.setTextColor(grub_selected_text)
            local padding = string.rep(" ", menuWidth - #option.name - 2)
            term.write(option.name .. padding)
            term.setBackgroundColor(grub_bg)
            term.setTextColor(grub_text)
            term.write("|")
        else
            -- Normal item
            term.write(" |  " .. option.name)
            local spaces = menuWidth - #option.name - 3
            term.write(string.rep(" ", spaces) .. "|")
        end
    end
    
    -- Fill remaining menu space
    local remainingLines = 4 - #options
    for i = 1, remainingLines do
        local line = menuStart + #options + i - 1
        term.setCursorPos(1, line)
        term.write(" |" .. string.rep(" ", menuWidth) .. "|")
    end
    
    -- Bottom border
    term.setCursorPos(1, menuStart + 4)
    term.write(" +" .. string.rep("-", menuWidth) .. "+")
end

-- Draw GRUB footer/instructions exactly like real GRUB
local function drawGrubFooter(showTimeout, remaining)
    local footerStart = h - 3
    
    term.setCursorPos(1, footerStart)
    if showTimeout then
        local timeoutMsg = string.format("  Entry will boot automatically in %ds.", remaining)
        term.write(timeoutMsg)
    else
        term.write("")
    end
    
    term.setCursorPos(1, footerStart + 1)
    term.write("  Use ^ and v keys to select, enter to boot.")
    term.setCursorPos(1, footerStart + 2)
    term.write("  Press 'e' to edit commands, 'c' for command-line.")
end

-- GRUB-style boot messages
local function grubBoot(option)
    initScreen()
    
    if option.action == "ozy" then
        print("Loading Ozy OS...")
        print("Loading initial ramdisk...")
        sleep(0.5)
        
        if fs.exists(option.kernel) then
            print("Booting kernel...")
            sleep(0.5)
            print("")
            term.setBackgroundColor(colors.black)
            term.setTextColor(colors.white)
            dofile(option.kernel)
        else
            print("error: file `" .. option.kernel .. "' not found.")
            print("error: you need to load the kernel first.")
            print("")
            print("Press any key to continue...")
            os.pullEvent("key")
            os.reboot()
        end
        
    elseif option.action == "computercraft" then
        print("Loading ComputerCraft OS...")
        print("Loading initial ramdisk...")
        sleep(0.5)
        print("Booting kernel...")
        sleep(0.5)
        term.clear()
        term.setCursorPos(1, 1)
        return -- Boot normal CC OS
        
    elseif option.action == "advanced" then
        initScreen()
        term.setCursorPos(1, 1)
        term.write("              OZY GRUB  version 1.0.0")
        term.setCursorPos(1, 2)
        term.write("")
        term.setCursorPos(1, 3)
        term.write(" +" .. string.rep("-", w-4) .. "+")
        term.setCursorPos(1, 4)
        term.write(" |" .. string.rep(" ", w-4) .. "|")
        term.setCursorPos(1, 5)
        term.write(" |  Ozy OS (recovery mode)" .. string.rep(" ", w-4-25) .. "|")
        term.setCursorPos(1, 6)
        term.write(" |  Ozy OS (safe mode)" .. string.rep(" ", w-4-21) .. "|")
        term.setCursorPos(1, 7)
        term.write(" |  Memory test (memtest86+)" .. string.rep(" ", w-4-27) .. "|")
        term.setCursorPos(1, 8)
        term.write(" |" .. string.rep(" ", w-4) .. "|")
        term.setCursorPos(1, 9)
        term.write(" +" .. string.rep("-", w-4) .. "+")
        term.setCursorPos(1, h - 1)
        term.write("  Use ^ and v keys to select, enter to boot.")
        term.setCursorPos(1, h)
        term.write("  Press any key to return to main menu.")
        
        os.pullEvent("key")
        os.reboot()
        
    elseif option.action == "setup" then
        print("Loading system setup...")
        sleep(1)
        print("Entering BIOS setup utility...")
        sleep(1)
        initScreen()
        
        term.setCursorPos(15, 5)
        term.write("ComputerCraft BIOS Setup Utility")
        term.setCursorPos(20, 7)
        term.write("Computer ID: " .. os.getComputerID())
        term.setCursorPos(20, 8)
        term.write("Label: " .. (os.getComputerLabel() or "None"))
        term.setCursorPos(20, 9)
        term.write("CC Version: " .. os.version())
        term.setCursorPos(20, 11)
        term.write("Press any key to exit setup...")
        
        os.pullEvent("key")
        os.reboot()
    end
end

-- Main GRUB bootloader
local function grubBootloader()
    local keyPressed = false
    
    while true do
        local elapsed = os.clock() - startTime
        local remaining = math.max(0, timeout - math.floor(elapsed))
        
        initScreen()
        drawGrubHeader()
        drawGrubMenu()
        drawGrubFooter(not keyPressed, remaining)
        
        -- Auto-boot default entry (Ozy OS)
        if not keyPressed and remaining <= 0 then
            grubBoot(options[1]) -- Boot Ozy OS (first option)
            return
        end
        
        -- Handle events with proper timeout
        local timer = os.startTimer(0.1)
        local event, p1 = os.pullEvent()
        
        if event == "timer" and p1 == timer then
            -- Continue loop for timeout countdown
        elseif event == "terminate" then
            initScreen()
            print("OZY RUB loading.")
            print("")
            print("Welcome to OZY RUB!")
            print("")
            print("error: no suitable video mode found.")
            print("Booting in blind mode")
            return
        elseif event == "key" then
            keyPressed = true
            local key = p1
            
            if key == keys.up then
                selected = selected - 1
                if selected < 1 then
                    selected = #options
                end
            elseif key == keys.down then
                selected = selected + 1
                if selected > #options then
                    selected = 1
                end
            elseif key == keys.enter then
                grubBoot(options[selected])
                return
            elseif key == keys.e then
                -- GRUB edit mode
                initScreen()
                term.setCursorPos(1, 1)
                term.write("              OZY RUB  version 1.0.0")
                term.setCursorPos(1, 3)
                term.write("  Minimum Emacs-like screen editing is supported.")
                term.setCursorPos(1, 4)
                term.write("  Press Ctrl-x to boot, ESC to return to menu.")
                term.setCursorPos(1, 6)
                term.write("menuentry '" .. options[selected].name .. "' {")
                term.setCursorPos(1, 7)
                if options[selected].kernel then
                    term.write("        linux   /" .. options[selected].kernel)
                else
                    term.write("        chainloader +1")
                end
                term.setCursorPos(1, 8)
                term.write("        boot")
                term.setCursorPos(1, 9)
                term.write("}")
                
                os.pullEvent("key")
                -- Return to menu
            elseif key == keys.c then
                -- GRUB command line
                initScreen()
                term.setCursorPos(1, 1)
                term.write("              OZY RUB  version 1.0.0")
                term.setCursorPos(1, 3)
                term.write("    Minimal BASH-like line editing is supported.")
                term.setCursorPos(1, 5)
                term.write("rub> ")
                
                os.pullEvent("key")
                -- Return to menu
            end
        end
    end
end

-- Start the authentic GRUB bootloader
term.clear()
print("OZY RUB loading.")
sleep(0.5)
print("Welcome to OZY RUB!")
sleep(0.5)

grubBootloader()
