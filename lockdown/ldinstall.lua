os.loadAPI("/.ld/bin/lib/sha256.lua")

write("Please enter a password: ")
local input = read("*")
print("Please wait...")

local key = sha256.sha256(input)
local f = fs.open("/.ld/usr/key", "w")
f.write(key)
f.close()
print("Password set successfully")

settings.set("shell.allow_disk_startup", false)

fs.makeDir('startup')

if fs.exists("startup.lua") then
  shell.run("mv startup.lua /startup/01_startup.lua")
  print("Moved startup file to /startup/01_startup.lua")
end

local file = fs.open("/startup/00_lockdown.lua", "w")
file.write("shell.run(\"/.ld/bin/lockdown.lua\")")

