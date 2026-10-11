# Músicas do RNG

Oito composições instrumentais próprias, sem gravações ou amostras externas. Os MP3s são loops curtos.

| Uso | Arquivo | Estilo | Chave no script |
|---|---|---|---|
| Ambiente | [Praia_Ambiente.mp3](Praia_Ambiente.mp3) | Tropical, timbre metálico suave, chocalho e ondas sintetizadas | ambient |
| Comum | [Comum_Conforto.mp3](Comum_Conforto.mp3) | Kalimba alegre | common |
| Incomum | [Incomum_Natureza.mp3](Incomum_Natureza.mp3) | Flauta suave | uncommon |
| Raro | [Raro_Oceano.mp3](Raro_Oceano.mp3) | Sinos cristalinos | rare |
| Épico | [Epico_Sombras.mp3](Epico_Sombras.mp3) | Sintetizador em tom menor | epic |
| Lendário | [Lendario_Solar.mp3](Lendario_Solar.mp3) | Melodia brilhante com timbre de metais | legendary |
| Divino | [Divino_Cosmos.mp3](Divino_Cosmos.mp3) | Camadas suaves e lentas | divine |
| Segredo | [Segredo_Enigma.mp3](Segredo_Enigma.mp3) | Caixa de música misteriosa | secret |

## Usar as faixas completas no Roblox

1. Baixe os MP3s. No GitHub, abra cada arquivo e use Download raw file.
2. No Painel do Criador Roblox, abra Criações → Itens de desenvolvimento → Áudio e carregue os arquivos. Use o mesmo proprietário da experiência, inclusive grupo quando aplicável.
3. Aguarde processamento/moderação e conceda acesso dos áudios à experiência, quando necessário.
4. Copie o ID de cada áudio. Em RNGSettingsClient, encontre a tabela music e a chave correspondente. Preencha AssetId = "rbxassetid://SEU_ID". Não copie o texto SEU_ID como se fosse um ID real.
5. Execute e confira a Saída se um áudio não carregar. As faixas completas tocam em loop; os controles de música ambiente e aura continuam separados.

O script publicado não contém IDs de áudio fictícios: eles são criados pelo Roblox ao importar. Sem IDs preenchidos, a versão simples das novas melodias funciona com o som incluído no cliente. Para trocar de aura e música, equipe pelo inventário; o resultado do roll sozinho não troca a faixa.

As preferências continuam locais por sessão. Para editar o volume dos MP3s, ajuste AssetVolume (padrão 0.3). Volume controla as notas simples.

Para recriar os MP3s: instale numpy e ffmpeg e execute `python scripts/create_music.py` na raiz do repositório.
