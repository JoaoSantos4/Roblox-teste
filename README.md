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
| RNGRankings | ModuleScript | [RNGRankings.lua](roblox/ServerScriptService/RNGRankings.lua) |
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
| RNGCollection | LocalScript | [RNGCollection.client.lua](roblox/StarterPlayerScripts/RNGCollection.client.lua) |
| RNGRankingClient | LocalScript | [RNGRankingClient.client.lua](roblox/StarterPlayerScripts/RNGRankingClient.client.lua) |
| RNGStatusClient | LocalScript | [RNGStatusClient.client.lua](roblox/StarterPlayerScripts/RNGStatusClient.client.lua) |

A interface e os RemoteEvents são criados automaticamente. RNGAuraEffect é singular. Para atualizar a loja na instalação existente, substitua RNGDaily, RNGQuests e RNGServer juntos e adicione RNGShopClient.

## Funcionalidades

- Sete raridades configuráveis, de Comum (1 em 2) a Segredo (1 em 1.000.000). Sem poções, as probabilidades somam 72,2221%; o restante é Sem aura.
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

Os quatorze scripts compilam em Luau. Testes com serviços simulados: 22 do perfil, 34 do servidor, 17 do cliente, 39 das regras de missões/loja e 33 do serviço, 12 da coleção, 28 do ranking, 13 de status, além de criação e limpeza das auras. Renderização, som, replicação e DataStore real exigem Roblox Studio.

## Coleção de auras

Para instalar a coleção, substitua o conteúdo de RNGConfig e RNGServer pelas versões completas atuais. Em StarterPlayer → StarterPlayerScripts, crie um LocalScript chamado RNGCollection e cole RNGCollection.client.lua inteiro. Mantenha o inventário e os outros scripts.

COLEÇÃO aparece à esquerda, abaixo de INVENTÁRIO. Mostra as descobertas, chances base, bloqueadas, aura equipada, contagem e barra de progresso. Recebe o mesmo catálogo e inventário do servidor, sem gravar dados novos ou conceder auras. Auras já salvas aparecem descobertas; o item Sem aura não faz parte da coleção.

A nova aura secret (Segredo) tem chance base de 1 em 1.000.000, cor rosa/vermelha e anúncio no chat. Aparece como ??? até ser obtida, com a chance visível. Secret é uma ocultação visual do nome no catálogo; não oculta o código da raridade de clientes modificados. Se obtida, entra no inventário normalmente e usa os efeitos genéricos existentes na sua cor. Nenhuma aura é concedida automaticamente por esta atualização.

Teste coleção antes e depois de uma descoberta, troca de equipamento, respawn e nova entrada. Confira os botões no celular. A compilação e 12 verificações da coleção passaram com interface simulada; a renderização exige Studio.

## Ranking global

Pare o teste. Substitua RNGProfile e RNGServer inteiros. Crie um ModuleScript RNGRankings em ServerScriptService e um LocalScript RNGRankingClient em StarterPlayer → StarterPlayerScripts, copiando os respectivos arquivos completos. Crie RNGRankings antes de iniciar o servidor atualizado; não remova os outros módulos.

RANKING aparece à esquerda abaixo de COLEÇÃO. Há duas abas, cada uma com Top 20: maiores denominadores de raridade e total permanente de rolls aceitos. Os três primeiros têm destaque dourado e sua linha fica verde se estiver no Top 20. Em empates de score, a ordem é definida pelo OrderedDataStore.

TotalRolls é salvo junto do perfil RNG_Best_v1 e começa em zero para perfis antigos: os antigos contadores de missões eram limitados e reiniciavam, portanto não recuperam todo o histórico de rolls. Recordes antigos são preservados e entram no ranking quando os jogadores voltam, salvam e o espelho atualiza. Não há varredura de todos os perfis antigos. Como os demais contadores, a fusão por máximo evita repetição de saves; duas sessões simultâneas da mesma conta podem subcontar rolagens.

Os OrderedDataStores RNG_GlobalBest_v1 e RNG_GlobalRolls_v1 recebem somente valores de perfis confirmados no DataStore normal. A fila de publicação e a leitura do Top 20 rodam a cada 60 segundos, em cada servidor. Dados costumam aparecer em 1–2 minutos; limites, falhas e consistência eventual podem aumentar esse atraso. Pedidos dos clientes só leem um cache e nunca informam scores nem disparam consultas ao DataStore. Falhas de gravação mantêm a fila para tentar novamente; se o servidor fechar, o perfil salvo republica ao voltar.

Teste em uma experiência publicada com acesso à API: faça rolls, aguarde as atualizações e veja as duas abas. Saia e entre para conferir que o total permanece. Os rankings são da mesma experiência Roblox em todos os seus servidores; uma experiência de teste separada tem outros DataStores. Falhas de leitura preservam o último ranking válido e são registradas na Saída. A verificação real entre servidores ainda exige Roblox Studio/Roblox.

## Status do jogador

Pare o teste. Substitua todo o conteúdo de RNGProfile, RNGQuests e RNGServer pelas versões atuais. Crie o LocalScript RNGStatusClient em StarterPlayer → StarterPlayerScripts. Mantenha todos os outros módulos, incluindo RNGRankings.

O botão STATUS aparece à direita, abaixo de LOJA. Mostra tempo total online e da sessão atual; rolls totais e da sessão; melhor aura e chance base; aura equipada; descobertas no catálogo; moedas; nível da melhoria; e duração restante das poções. Atualiza a cada cinco segundos somente quando o painel está aberto. O servidor limita pedidos e ignora valores extras fornecidos pelo cliente. Não consulta DataStore para cada atualização do painel.

PlaySeconds é contado pelo relógio do servidor e salvo junto do perfil em RNG_Best_v1, no autosave, na saída e no encerramento. Começa em zero para dados antigos. Tempo das missões não é convertido porque reiniciava e tinha limites. Conta permanência online incluindo AFK e respawn; não conta tempo fora do jogo. Tempo e rolls da sessão reiniciam ao entrar novamente. Frações menores que um segundo podem ser descartadas ao sair. Interrupções abruptas podem perder tempo ainda não salvo. A fusão por máximo tem a mesma limitação de sessões simultâneas já descrita para rolls.

Teste abrir STATUS, rolar algumas vezes, equipar uma aura, comprar uma melhoria e conferir os valores. Aguarde um minuto, saia e entre novamente: tempo e rolls totais permanecem; sessão reinicia. Falha no serviço das missões mostra economia indisponível sem inventar saldo. Testes simulados verificam o tempo no servidor, persistência, limitação dos pedidos e renderização dos valores; confira a interface no Studio.
