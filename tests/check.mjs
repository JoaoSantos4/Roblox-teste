// node tests/check.mjs /caminho/node_modules/luau-web/src/index.js
import fs from 'node:fs';
import { fileURLToPath, pathToFileURL } from 'node:url';
import path from 'node:path';
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const { LuauState } = await import(pathToFileURL(path.resolve(process.argv[2])).href);
const state = await LuauState.createAsync({ print: (...args) => console.log(...args) });
const read = file => fs.readFileSync(path.join(root, file), 'utf8');
const files = [
    'roblox/ServerScriptService/RNGConfig.lua',
    'roblox/ServerScriptService/RNGProfile.lua',
    'roblox/ServerScriptService/RNGAuraEffect.lua',
    'roblox/ServerScriptService/RNGServer.server.lua',
    'roblox/StarterPlayerScripts/RNGClient.client.lua',
    'roblox/StarterPlayerScripts/RNGInventory.client.lua',
    'roblox/ServerScriptService/RNGDaily.lua',
    'roblox/ServerScriptService/RNGQuests.lua',
    'roblox/StarterPlayerScripts/RNGQuestClient.client.lua',
    'roblox/StarterPlayerScripts/RNGShopClient.client.lua',
];
try {
    for (const file of files) {
        state.loadstring(read(file), file, true);
        console.log('Compilação Luau OK:', file);
    }
    const profile = read(files[1]);
    for (const file of ['tests/profile.spec.luau', 'tests/server.spec.luau', 'tests/effects.spec.luau', 'tests/client.spec.luau', 'tests/daily.spec.luau', 'tests/quests.spec.luau']) {
        const source = read(file)
            .replace('require("../roblox/ServerScriptService/RNGProfile")', `(function()\n${profile}\nend)()`)
            .replace('require("../roblox/ServerScriptService/RNGDaily")', `(function()\n${read('roblox/ServerScriptService/RNGDaily.lua')}\nend)()`)
            .replace('require("../roblox/ServerScriptService/RNGAuraEffect")', `(function()\n${read('roblox/ServerScriptService/RNGAuraEffect.lua')}\nend)()`)
            .replace('-- CLIENT_SOURCE', read('roblox/StarterPlayerScripts/RNGClient.client.lua'))
            .replace('-- QUEST_SOURCE', read('roblox/ServerScriptService/RNGQuests.lua'))
            .replace('-- SERVER_SOURCE', read('roblox/ServerScriptService/RNGServer.server.lua'));
        await state.loadstring(source, file, true)();
    }
} finally {
    state.destroy();
}
