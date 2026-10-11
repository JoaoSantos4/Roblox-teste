local Missions = require("../roblox/ServerScriptService/RNGDaily")
local ctx = { Now = 10 * 86400 + 7200, Keys = { daily = 10, weekly = 1, monthly = 100 },
    Starts = { daily = 10 * 86400, weekly = 4 * 86400, monthly = 0 },
    Resets = { daily = 11 * 86400, weekly = 11 * 86400, monthly = 31 * 86400 } }
local count = 0
local function check(value) assert(value); count += 1 end
local empty = Missions.Decode(nil, ctx)
check(empty.Version == 2 and empty.Coins == 0 and empty.Periods.daily.Rolls == 0)
local legacy = Missions.Decode({ Version = 1, Day = 10, Coins = 700, Rolls = 100, LoginClaimed = true, RollClaimed = true }, ctx)
check(legacy.Coins == 700 and legacy.Periods.daily.Claimed.login and legacy.Periods.daily.Claimed.rolls)
check(legacy.Periods.weekly.Rolls == 0)
check(Missions.Claim(legacy, nil, ctx, "daily", "rolls", 10).Coins == 700)
local data = Missions.Decode(nil, ctx)
Missions.Record(data, "roll", "rare", 0, ctx)
Missions.Record(data, "roll", "legendary", 0, ctx)
check(data.Periods.daily.Counts.rare == 1)
Missions.Record(data, "roll", "rare", 0, ctx)
local reward = Missions.Claim(data, nil, ctx, "daily", "rare2", 10)
check(reward.Coins == 400)
check(Missions.Claim(data, reward, ctx, "daily", "rare2", 10).Coins == 400)
check(Missions.Claim(data, reward, ctx, "weekly", "epic3", 1).Coins == 400)
for _ = 1, 3 do Missions.Record(data, "roll", "epic", 0, ctx) end
reward = Missions.Claim(data, reward, ctx, "weekly", "epic3", 1)
check(reward.Coins == 2900 and reward.Periods.weekly.Claimed.epic3)
reward = Missions.Claim(data, reward, ctx, "monthly", "legendary1", 100)
check(reward.Coins == 17900)
check(Missions.Claim(data, reward, ctx, "monthly", "legendary1", 100).Coins == 17900)
Missions.Record(data, "equip", "common", 0, ctx)
Missions.Record(data, "equip", "common", 0, ctx)
check(Missions.Progress(data.Periods.weekly, Missions.Quest("weekly", "style3")) == 1)
Missions.Record(data, "equip", "rare", 0, ctx)
Missions.Record(data, "equip", "epic", 0, ctx)
check(Missions.Progress(data.Periods.weekly, Missions.Quest("weekly", "style3")) == 3)
check(Missions.Progress(data.Periods.daily, Missions.Quest("daily", "found2")) == 2)
Missions.Record(data, "time", nil, 7200, ctx)
check(data.Periods.daily.Seconds == 600 and data.Periods.weekly.Seconds == 3600 and data.Periods.monthly.Seconds == 7200)
local nextDay = { Now = 11 * 86400 + 60, Keys = { daily = 11, weekly = 1, monthly = 100 },
    Starts = { daily = 11 * 86400, weekly = 4 * 86400, monthly = 0 }, Resets = ctx.Resets }
local fresh = Missions.Decode(reward, nextDay)
check(fresh.Coins == 17900 and fresh.Periods.daily.Rolls == 0 and not fresh.Periods.daily.Claimed.rare2)
check(fresh.Periods.weekly.Claimed.epic3 and fresh.Periods.monthly.Claimed.legendary1)
check(Missions.Claim(data, reward, nextDay, "daily", "rare2", 10).Coins == 17900)
Missions.Record(fresh, "time", nil, 1000, nextDay)
check(fresh.Periods.daily.Seconds == 60)
local nextWeek = { Now = 18 * 86400, Keys = { daily = 18, weekly = 2, monthly = 100 }, Starts = nextDay.Starts, Resets = ctx.Resets }
local weeklyReset = Missions.Decode(reward, nextWeek)
check(not weeklyReset.Periods.weekly.Claimed.epic3 and weeklyReset.Periods.monthly.Claimed.legendary1)
local nextMonth = { Now = 31 * 86400, Keys = { daily = 31, weekly = 4, monthly = 101 }, Starts = ctx.Starts, Resets = ctx.Resets }
check(Missions.Decode(reward, nextMonth).Periods.monthly.Counts.legendary == nil)
check(Missions.Merge(data, reward, ctx).Coins == 17900)
local pending = Missions.Decode(nil, ctx)
Missions.Record(pending, "roll", "rare", 0, ctx)
check(Missions.Merge(pending, data, ctx, true).Periods.monthly.Counts.rare == 3)
check(Missions.View(data, ctx).weekly.Missions[3].Progress == 3)
check(not pcall(Missions.Decode, { Version = 1, Day = 100, Coins = 0, Rolls = 0, LoginClaimed = false, RollClaimed = false }, ctx))
check(Missions.Claim(data, reward, ctx, "daily", "fake", 10).Coins == 17900)
local wallet = Missions.Decode(nil, ctx)
wallet.Coins = 10000
local bought = Missions.Buy(wallet, nil, ctx, "luck", "one")
check(bought.Coins == 9250 and bought.Spent == 750 and bought.Shop.LuckUntil == ctx.Now + 300)
check(Missions.Buy(wallet, bought, ctx, "luck", "one").Spent == 750)
check(Missions.Merge(wallet, bought, ctx).Coins == 9250) -- autosave antigo não devolve gasto
check(Missions.Buy(bought, bought, ctx, "luck", "two").Spent == 750) -- não acumula ativa
local speed = Missions.Buy(bought, bought, ctx, "speed", "speed")
check(speed.Coins == 8750 and speed.Shop.SpeedUntil == ctx.Now + 300)
local income = Missions.Buy(speed, speed, ctx, "income", "income")
check(income.Coins == 7750 and income.Shop.Level == 1)
local second = Missions.Buy(income, income, ctx, "income", "income2")
check(second.Coins == 5750 and second.Shop.Level == 2)
check(Missions.Buy(speed, second, ctx, "income", "conflict").Spent == second.Spent)
check(Missions.Buy(second, second, ctx, "fake", "fake").Spent == second.Spent)
local poor = Missions.Decode(nil, ctx)
check(Missions.Buy(poor, nil, ctx, "luck", "poor").Coins == 0)
local expiredCtx = table.clone(ctx)
expiredCtx.Now += 301
local renewed = Missions.Buy(second, second, expiredCtx, "luck", "renew")
check(renewed.Spent == second.Spent + 750)
local maxed = Missions.Decode(nil, ctx)
maxed.Coins = 50000
for i = 1, 5 do maxed = Missions.Buy(maxed, maxed, ctx, "income", "level" .. i) end
check(maxed.Shop.Level == 5 and maxed.Coins == 35000)
check(Missions.Buy(maxed, maxed, ctx, "income", "over").Coins == 35000)
print("Missions: " .. count .. " verificações passaram")
