# RNG para Roblox Studio

Scripts completos de RNG, inventário, auras, Auto Roll, rolagem rápida, missões e loja.

## Copiar para o Studio

Pare o teste antes de editar. Abra cada arquivo pelo link abaixo e clique em **Raw** para copiar o código completo. No editor do Studio, use **Ctrl+A** e cole. Os nomes dos objetos não incluem a extensão do arquivo. Instale uma única cópia de cada script.

### ServerScriptService

| Nome no Studio | Tipo | Código completo |
|---|---|---|
| RNGConfig | ModuleScript | [RNGConfig.lua](roblox/ServerScriptService/RNGConfig.lua) |
| RNGProfile | ModuleScript | [RNGProfile.lua](roblox/ServerScriptService/RNGProfile.lua) |
| RNGAuraEffect | ModuleScript | [RNGAuraEffect.lua](roblox/ServerScriptService/RNGAuraEffect.lua) |
| RNGDaily | ModuleScript | [RNGDaily.lua](roblox/ServerScriptService/RNGDaily.lua) |
| RNGQuests | ModuleScript | [RNGQuests.lua](roblox/ServerScriptService/RNGQuests.lua) |
| RNGServer | Script | [RNGServer.server.lua](roblox/ServerScriptService/RNGServer.server.lua) |

### StarterPlayer → StarterPlayerScripts

| Nome no Studio | Tipo | Código completo |
|---|---|---|
| RNGClient | LocalScript | [RNGClient.client.lua](roblox/StarterPlayerScripts/RNGClient.client.lua) |
| RNGInventory | LocalScript | [RNGInventory.client.lua](roblox/StarterPlayerScripts/RNGInventory.client.lua) |
| RNGQuestClient | LocalScript | [RNGQuestClient.client.lua](roblox/StarterPlayerScripts/RNGQuestClient.client.lua) |
| RNGShopClient | LocalScript | [RNGShopClient.client.lua](roblox/StarterPlayerScripts/RNGShopClient.client.lua) |

A interface e os RemoteEvents são criados automaticamente. RNGAuraEffect é singular. Para atualizar a loja na instalação existente, substitua RNGDaily, RNGQuests e RNGServer juntos e adicione RNGShopClient.

## Funcionalidades

- Seis raridades configuráveis, de Comum (1 em 2) a Divino (1 em 50.000). Sem poções, as probabilidades somam 72,222%; o restante é Sem aura.
- Recorde, inventário de auras únicas e equipamento persistidos no servidor.
- Efeitos de aura, título sobre o personagem e anúncios de Lendário/Divino.
- Animação e som de rolagem, Auto Roll e modo rápido.
- Dezoito missões diárias, semanais e mensais: rodadas, auras específicas, coleção, equipamento e tempo no jogo.
- Moedas por missão e por roll válido, inclusive Sem aura.
- Loja com preços e benefícios controlados no servidor.

## Loja

| Produto | Preço | Benefício |
|---|---:|---|
| Poção de sorte | 750 | 2x probabilidade base de Raro ou superior por 300 segundos |
| Poção de velocidade | 500 | Intervalo mínimo de roll 25% menor por 300 segundos |
| Melhoria de moedas | 1.000 × nível comprado | +1 moeda por roll por nível, máximo cinco níveis |

Cada roll válido rende 1 moeda no nível zero e 6 no nível cinco. As poções ativam ao comprar, expiram em tempo real mesmo fora do jogo e não podem ser compradas novamente enquanto ativas. O texto “1 em X” mostra a raridade base. A animação pode tornar as rodadas mais lentas que o intervalo mínimo do servidor.

## Salvamento

Publique a experiência pelo Studio. Para testar DataStore no Studio, habilite acesso aos serviços de API em Configurações do jogo → Segurança.

RNG_Best_v1 mantém recorde, coleção e equipamento. RNG_Daily_v1 mantém missões, saldo, gastos, melhoria e validade das poções. Dados antigos são migrados. Não reverta os módulos para versões antigas depois da atualização.

Compras e resgates são confirmados após UpdateAsync. Ganhos das rodadas são salvos no autosave de 60 segundos, na saída e junto de compras/resgates. Uma interrupção abrupta pode perder ganhos ainda não salvos. Contadores de progresso e ganhos usam fusão por máximo entre sessões; sessões simultâneas da mesma conta podem subcontar ganhos.

Os períodos seguem UTC: diário à meia-noite, semanal na segunda-feira e mensal no primeiro dia do mês.

## Verificar no Studio

Teste roll, Auto Roll, modo rápido, inventário, troca de aura e respawn. Abra as três abas de missões e resgate uma recompensa. Faça uma compra, confira a redução do saldo e entre novamente para confirmar persistência. Teste sem saldo e com dois clientes para conferir efeitos e anúncios.

Se algo travar, abra **Janela → Saída** e confira a primeira mensagem vermelha. Verifique nomes, tipos e se o código foi copiado até a última linha.

## Testes locais

```sh
npm install --prefix /tmp/rng-luau-check --cache /tmp/rng-npm-cache --ignore-scripts --no-audit --no-fund luau-web@1.4.0
node tests/check.mjs /tmp/rng-luau-check/node_modules/luau-web/src/index.js
```

Os dez scripts compilam em Luau. Testes com serviços simulados: 13 do perfil, 27 do servidor, 17 do cliente, 39 das regras de missões/loja e 33 do serviço, além de criação e limpeza das auras. Renderização, som, replicação e DataStore real exigem Roblox Studio.
