# Fala Brincando (título provisório)

Protótipo em **Godot 4.3** do *GDD – App de Jogos para Comunicação e Fala (crianças autistas)*.
Hub com dois jogos (**Torre do Castelo** e **Bolhas de Sabão**), um personagem amigo e o ciclo
**modelo → pausa → aceitação**: sem erro, sem pontuação, sem estrelas e sem "tente de novo".

Tudo foi feito com **código simples**: o personagem, os blocos, as bolhas e os sons são
desenhados ou gerados por código. Quando os sprites, ícones e botões ficarem prontos, é só colocar
os arquivos nas pastas abaixo, sem mexer no código.

---

## Como abrir no celular (Godot para Android)

1. Instale o **Godot Engine 4.3 ou mais novo** pela Play Store ou pelo site godotengine.org.
2. Baixe este repositório como ZIP (GitHub → *Code* → *Download ZIP*) e extraia em uma pasta do celular.
3. No Godot, toque em **Importar**, escolha o arquivo `project.godot` dessa pasta e abra.
4. Para testar, toque em **▶ (Executar projeto)**.

Para gerar o APK: **Projeto → Exportar → Android**. O preset já vem com a permissão de
microfone (para o sopro) e com a de vibração. Você só precisa configurar sua keystore de assinatura.

---

## Telas

| Tela | Quem usa | O que faz |
|---|---|---|
| Primeira abertura (`inicio`) | Responsável | Aviso, consentimento, apelido, temas, sopro ou toque, medir o barulho do lugar e ajustar o sopro |
| Hub (`hub`) | Criança | Ícones grandes dos jogos, sempre na mesma posição; o personagem cumprimenta |
| Torre do Castelo (`torre`) | Criança | A torre já começa montada. **Sopro fraco** só balança; **sopro forte** derruba a torre e aparece um item dos temas escolhidos pelo responsável, que o personagem nomeia. Depois a torre se remonta sozinha. Sem microfone: segurar o dedo na torre (toque curto balança, segurar derruba) |
| Bolhas de Sabão (`bolhas`) | Criança | Soprar no microfone **ou** segurar a varinha ✨; tocar na bolha revela uma imagem |
| Configurações (`responsaveis`) | Responsável | Apelido e temas, fala, sopro com medidor, torre, som |

- **Cadeado 🔒 (segurar 3 segundos):**
  - No **hub**, abre as **Configurações**: apelido e temas, como o personagem fala, sopro
    (Fraco ↔ Forte, com medidor ao vivo e botão para medir o barulho do ambiente), torre
    (voltar para a torre pequena), som e "refazer a configuração inicial".
  - **Dentro dos jogos**, abre os **Ajustes**: como o personagem fala e o sopro, sem sair do jogo.
- **Configuração inicial:** aviso, apelido e temas, sopro ou toque, **medir o barulho do lugar**
  (desligar ventilador e ar-condicionado) e **ajustar o sopro** com a criança soprando.
- **Sopro "Fraco ↔ Forte":** no "fraco" o celular fica bem sensível (para quem ainda não sabe
  soprar), mas também capta ventilador e ar-condicionado. No "forte" precisa de mais sopro.
- **Torre:** começa com 1 fileira e **qualquer sopro derruba**, de qualquer tamanho. A cada queda
  ganha uma fileira (só pela diversão), até o topo da tela (15 fileiras).
- **Proteções contra sopro falso:** o microfone fica surdo enquanto o personagem fala; o som
  precisa durar um pouquinho para contar; o barulho do ambiente é reaprendido aos poucos.
- **Bolhas:** cada sopro solta logo 4 bolhas espalhadas; soprando mais forte saem mais. A imagem
  só aparece depois de a criança estourar algumas bolhas vazias.
- **Fim suave:** depois de alguns minutos (3, 6 ou 10, a configurar), o personagem convida
  "De novo?" com dois botões grandes (🔁 continuar ou 🏠 casa). O jogo nunca fecha à força.
- **Botão voltar do Android:** no jogo, volta ao hub. No hub, não faz nada (modo criança travado).

---

## Onde colocar os assets feitos no ChatGPT

| O quê | Pasta e nome | Formato sugerido |
|---|---|---|
| Imagens dos temas | `assets/imagens/<id>.png`, ex.: `banana.png`, `cachorro.png` | PNG quadrado com fundo transparente, 512×512 |
| Ícones dos jogos no hub | `assets/imagens/jogo_torre.png`, `assets/imagens/jogo_bolhas.png` | PNG 512×512 |
| Personagem | `assets/personagem/observando.png`, `falando.png`, `esperando.png`, `celebrando.png`, `convidando.png` | PNG transparente, 512×512 |
| Falas pré-gravadas (opcional) | `assets/falas/<grupo>_<evento>_<nível>.ogg`, ex.: `torre_alta_1.ogg` | OGG ou WAV |

Se uma imagem não existir, o app usa o emoji do item. Os `id` de cada item estão em `data/temas.json`.

**Já incluído:** todos os itens dos temas já têm imagem.
- **Animais:** Animal Pack Redux do Kenney (CC0), convertido do vetor para 512×512.
- **Frutas, carros, máquinas, comidas e brinquedos:** pictogramas do **ARASAAC**, o banco mais usado em
  comunicação alternativa (CAA) para autismo (CC BY-NC-SA: uso gratuito não comercial, com crédito,
  que já aparece no app). Para trocar uma imagem, basta
substituir o arquivo com o mesmo nome. Os créditos estão em `assets/CREDITOS.md`.

---

## Editar palavras, frases e temas (sem programar)

- `data/temas.json`: temas de interesse e seus itens (texto, artigo, emoji, `voz` opcional para ajustar a pronúncia).
- `data/frases.json`: banco de frases do personagem. Cada evento tem **3 formas**, uma por nível de apoio:
  `[só a palavra, palavra com artigo, frase curta]`. Marcadores: `{nome}`, `{item}`, `{artigo}`, `{cor}`.
  Use `"ativo": false` para desligar uma frase.

---

## Paleta e interface

Baseada nos apps de comunicação mais bem avaliados (Otsimo, Proloquo2Go, Livox e Matraquinha) e
nas diretrizes de conforto sensorial do GDD (seção 13): fundo claro e calmo, tons pastel com bom
contraste, cantos bem arredondados, alvos de toque grandes (96 px ou mais), poucos elementos por tela,
animações lentas e sons graves e curtos.

| Uso | Cor |
|---|---|
| Fundo | `#EEF5FB` (tema calmo: `#F3F4F6`) |
| Texto | `#2D3A4A` |
| Primária / destaque | `#5B8DEF` / `#3F6FD1` |
| Menta | `#8FD9C0` |
| Pêssego | `#FFC9A8` |
| Amarelo | `#FFE29A` |
| Lilás | `#CBB8F0` |
| Céu | `#BFDCF7` |
| Blocos | vermelho `#F28B82`, laranja `#FBBC77`, amarelo `#FDD663`, verde `#81C995`, azul `#78A9F0`, roxo `#B39DDB` |

Fontes embutidas: **Nunito** (arredondada e legível) e **Noto Color Emoji**, para que os emojis
apareçam iguais em qualquer celular (as duas fontes são livres, licença SIL OFL).

---

## Estrutura do código

```
autoload/
  ui.gd          paleta, fontes e construtores de botões, painéis e interruptores
  perfil.gd      perfil da criança, ajustes e temas (salvos só no aparelho, em user://)
  fala.gd        voz única (síntese pt-BR), texto e CICLO DE COMUNICAÇÃO (modelo, pausa, aceitação)
  microfone.gd   sopro e presença de voz em tempo real, SEM gravar áudio
  jogo.gd        catálogo modular de jogos e navegação
scripts/
  base_jogo.gd   "contrato" de todo jogo: casa, balão, personagem, cadeado de ajustes, fim suave
  ajustes_rapidos.gd  painel de ajustes dentro do jogo
  torre.gd       Jogo 1: Torre do Castelo (soprar para derrubar)
  bolhas.gd      Jogo 2: Bolhas de Sabão
  personagem.gd  personagem desenhado por código (sem boca animada, só poses)
  balao.gd       balão de fala (sempre no mesmo lugar, com palavra-chave destacada)
  portao.gd      portão dos responsáveis (segurar 3 s)
  hub.gd, inicio.gd, responsaveis.gd
data/
  temas.json, frases.json
```

**Para adicionar um jogo novo** (GDD seção 18): crie `scenes/<id>.tscn` com um script que faça
`extends "res://scripts/base_jogo.gd"`, implemente `_montar(area)` e acrescente uma linha em
`Jogo.CATALOGO` (`autoload/jogo.gd`).

---

## O que do GDD já está no protótipo e o que falta

**Já está:** hub modular; primeira sessão guiada com consentimento, medição do ambiente e ajuste
do sopro; apelido e temas; tipo de fala (só a palavra, com artigo, frase curta) mudável dentro do
jogo; voz única por síntese pt-BR com texto sempre junto; ciclo modelo → pausa → aceitação igual
para qualquer resposta; personagem com 5 estados; Torre do Castelo que cresce de 1 a 15 fileiras
(qualquer sopro derruba) com alternativa por toque; Bolhas (rajada a cada sopro, quantidade
proporcional à força, varinha por toque); microfone sem gravação, com calibração do ambiente e
controle Fraco ↔ Forte; volume e sons; apagar todos os dados; botão voltar do Android tratado.

**Retirado a pedido:** o diário de sessões (o responsável anota no papel, se quiser).

**Falta (próximas etapas):**
- Fotos da câmera e da galeria com recorte e rótulo (por enquanto, as imagens vêm de `assets/imagens/`).
- Vários perfis de criança no mesmo aparelho.
- Falas fixas pré-geradas em áudio (o suporte já existe em `assets/falas/`; faltam os arquivos).
- Música de fundo (desligada por padrão no GDD).
- Testes com famílias e revisão por fonoaudiólogos (GDD seção 17).

> Este app é uma brincadeira de apoio à comunicação. Ele não diagnostica, não trata e não substitui
> o acompanhamento profissional.
