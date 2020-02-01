os.loadAPI("/.ld/bin/lib/sha256.lua")

write("Enter key: ")
local input = read("*")
print("Please wait...")

local key = sha256.sha256(input)
local f = fs.open("/.ld/usr/key", "w")
f.write(key)
f.close()
print("Key set successfully")
