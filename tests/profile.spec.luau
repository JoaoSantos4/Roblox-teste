-- Execute com Luau CLI na raiz do repositório: luau tests/profile.spec.luau
local Profile = require("../roblox/ServerScriptService/RNGProfile")
local count = 0
local function check(condition)
    assert(condition)
    count += 1
end
local empty = Profile.Decode(nil)
check(empty.Version == 2 and next(empty.Owned) == nil and empty.BestOdds == 0)
local legacy = Profile.Decode({ Version = 1, BestOdds = 50, BestId = "rare" })
check(legacy.Owned.rare and legacy.BestOdds == 50 and legacy.Equipped == nil)
local equipped = Profile.Decode(legacy)
equipped.Owned.common = true
equipped.Equipped, equipped.EquipTime = "common", 100
local stored = Profile.Merge(equipped, { Version = 1, BestOdds = 5000, BestId = "legendary" })
check(stored.BestOdds == 5000 and stored.Owned.legendary and stored.Owned.rare and stored.Owned.common)
check(stored.Equipped == "common")
local stale = Profile.Decode(legacy)
stale.Equipped, stale.EquipTime = "rare", 90
check(Profile.Merge(stale, stored).Equipped == "common")
local removed = Profile.Decode(stored)
removed.Equipped, removed.EquipTime = nil, 101
check(Profile.Merge(removed, stored).Equipped == nil)
check(Profile.Merge(stale, removed).Equipped == nil)
local snapshot = Profile.Decode(stored)
snapshot.Owned.epic = true
check(stored.Owned.epic == nil)
check(not pcall(Profile.Decode, { Version = 3, BestOdds = 0 }))
check(not pcall(Profile.Decode, { Version = 1, BestOdds = 0 / 0 }))
check(not pcall(Profile.Decode, { Version = 2, BestOdds = 0, Owned = {}, Equipped = "divine", EquipTime = 1 }))
check(not pcall(Profile.Decode, { Version = 2, BestOdds = 0, Owned = { rare = 3 }, EquipTime = 0 }))
local union = Profile.Merge(stored, stale)
check(union.Owned.legendary and union.Owned.rare and union.Owned.common)
check(empty.TotalRolls == 0 and legacy.TotalRolls == 0)
local rolled = Profile.Decode(stored)
rolled.TotalRolls = 1234
check(Profile.Merge(rolled, stored).TotalRolls == 1234)
check(Profile.Merge(stored, rolled).TotalRolls == 1234)
check(Profile.Merge(rolled, rolled).TotalRolls == 1234)
check(not pcall(Profile.Decode, { Version = 1, BestOdds = 0, TotalRolls = -1 }))
check(empty.PlaySeconds == 0 and legacy.PlaySeconds == 0)
rolled.PlaySeconds = 3600
check(Profile.Merge(rolled, stored).PlaySeconds == 3600)
check(Profile.Merge(stored, rolled).PlaySeconds == 3600)
check(not pcall(Profile.Decode, { Version = 1, BestOdds = 0, PlaySeconds = -1 }))
print("Profile: " .. count .. " verificações passaram")
