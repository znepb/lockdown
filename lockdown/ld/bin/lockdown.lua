local oldPullEvent = os.pullEvent
os.pullEvent = os.pullEventRaw

os.loadAPI("/.ld/bin/lib/aeslua.lua")
os.loadAPI("/.ld/bin/lib/sha256.lua")
local keyFile = fs.open("/.ld/usr/key", "r")
local key = keyFile.readAll()
keyFile.close()

print("Please wait...")

local restrictedDirs = {"rom", ".ld", "startup"}
local restrictedFiles = {"startup.lua", "startup", ".settings", "ldinstall.lua"}
local encryptedFiles = {}

local versionFile = fs.open("/.ld/bin/version", "r")
local version = versionFile.readAll()
versionFile.close()

local function isRestricted(query)
  for i, v in pairs(restrictedDirs) do
    if v == query then
      return true
    end
  end
  for i, v in pairs(restrictedFiles) do
    if v == query then
      return true
    end
  end
  return false
end

local function writeEncryptedFiles()
  local file = fs.open("/.ld/usr/encryptedFiles", "w")
  file.write(textutils.serialize(encryptedFiles))
  file.close()
end

local function updateEncryptedFiles()
  local file = fs.open("/.ld/usr/encryptedFiles", "r")
  encryptedFiles = textutils.unserialize(file.readAll())
  file.close()
end

local function isEncrypted(query)
  for i, v in pairs(encryptedFiles) do
    if v == query then
      return true
    end
  end

  return false
end

local function encryptAll(dir)
  for i, v in pairs(fs.list(dir)) do

    if fs.isDir(dir .. "/" .. v) and not isRestricted(v) then
      encryptAll(dir .. "/" .. v)
    elseif not isRestricted(v) and not isEncrypted(dir .. "/" .. v) then
      local file = fs.open(dir .. "/" .. v, "r")
      local data = file.readAll()
      file.close()
      local encryptedData = aeslua.encrypt(key, data)
      local file = fs.open(dir .. "/" .. v, "w")
      file.write(encryptedData)
      file.close()
      table.insert(encryptedFiles, dir .. "/" .. v)
    end
  end
end

local function decryptAll(dir)
  for i, v in pairs(fs.list(dir)) do
    if fs.isDir(dir .. "/" .. v) and not isRestricted(v) then
      decryptAll(dir .. "/" .. v)
    elseif not isRestricted(v) and isEncrypted(dir .. "/" .. v) then
      local file = fs.open(dir .. "/" .. v, "r")
      local data = file.readAll()
      file.close()
      local decryptedData = aeslua.decrypt(key, data)
      local file = fs.open(dir .. "/" .. v, "w")
      file.write(decryptedData)
      file.close()
      table.insert(encryptedFiles, dir .. "/" .. v)
    end
  end
end

term.clear()
term.setCursorPos(1, 1)

updateEncryptedFiles()
encryptAll("/")
writeEncryptedFiles()

term.clear()
local success = false

if term.isColour() then
  term.setTextColour(colours.yellow)
end
print("Lockdown v" .. version)
term.setTextColour(colours.white)

repeat
  term.write("Please enter your password: ")
  local password = read("*")
  local enteredKey = sha256.sha256(password)
  if enteredKey == key then
    print("Welcome.")
    success = true
    decryptAll("/")
    shell.setAlias("setkey", "/.ld/bin/setkey.lua")
    shell.setAlias("lock", "/.ld/bin/lockdown.lua")
    encryptedFiles = {}
    writeEncryptedFiles()
    os.pullEvent = oldPullEvent
  else
    print("Sorry, try again")
  end
until success == true
