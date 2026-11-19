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
| Primeira abertura (`inicio`) | Responsável | Aviso ("não é terapia nem diagnóstico"), consentimento, apelido, prévia da voz, temas e escolha entre sopro e toque |
| Hub (`hub`) | Criança | Ícones grandes dos jogos, sempre na mesma posição; o personagem cumprimenta |
| Torre do Castelo (`torre`) | Criança | A torre já começa montada. **Sopro fraco** só balança; **sopro forte** derruba a torre e aparece um item dos temas escolhidos pelo responsável, que o personagem nomeia. Depois a torre se remonta sozinha. Sem microfone: segurar o dedo na torre (toque curto balança, segurar derruba) |
| Bolhas de Sabão (`bolhas`) | Criança | Soprar no microfone **ou** segurar a varinha ✨; tocar na bolha revela uma imagem |
| Área dos responsáveis (`responsaveis`) | Responsável | Perfil, fala, conforto sensorial, jogos, microfone com teste ao vivo, diário e privacidade |

- **Portão dos responsáveis:** segure o cadeado 🔒 por **3 segundos**.
  - No **hub**, abre a área dos responsáveis completa.
  - **Dentro dos jogos**, abre os **ajustes rápidos**: tipo de fala (só a palavra, com artigo ou frase
    curta), sensibilidade do microfone com medidor ao vivo e, na torre, o tamanho atual e a força
    para derrubar. O jogo fica parado enquanto o painel está aberto.
- **Refazer configuração inicial:** na área dos responsáveis (apelido, temas, sopro ou toque).
- **Torre em níveis:** começa com 1 fileira e cai com um sopro bem fraquinho; a cada queda volta
  um nível maior (até 5) e pede mais força. Dá para escolher o nível ou travar o crescimento.
- **Microfone para quem ainda não sabe soprar:** mede o barulho do ambiente, conta como sopro
  qualquer som um pouco acima dele e calcula a força em decibéis. Sensibilidade de 1 a 10.
- **Bolhas:** cada sopro solta logo uma rajada de 4 bolhas espalhadas; soprando mais forte saem mais.
  A imagem só aparece depois de a criança estourar algumas bolhas vazias.
- **Botão 👍 discreto nos jogos:** o responsável marca "ele respondeu" (gesto, olhar). Isso vai
  para o diário e **não muda** a reação do jogo.
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
  perfil.gd      perfil da criança, ajustes, temas e diário (salvos só no aparelho, em user://)
  fala.gd        voz única (síntese pt-BR), texto e CICLO DE COMUNICAÇÃO (modelo, pausa, aceitação)
  microfone.gd   sopro e presença de voz em tempo real, SEM gravar áudio
  jogo.gd        catálogo modular de jogos e navegação
scripts/
  base_jogo.gd   "contrato" de todo jogo: casa, balão, personagem, 👍, fim suave, diário
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

**Já está:** hub modular; primeira sessão guiada com consentimento; perfil com apelido, grafia para
a voz, temas, nível de apoio, tempo de pausa, repetição única do modelo e texto ligado/grande; voz
única por síntese pt-BR com texto sempre junto (e som neutro quando o aparelho não tem voz);
ciclo modelo → pausa → aceitação igual para qualquer resposta; personagem com 5 estados;
Torre do Castelo (sopro fraco balança, sopro forte derruba e revela um item de interesse, força
para derrubar ajustável em fraco/médio/forte, alternativa por toque, opção "nunca cai", convite após 20 s parado); Bolhas (sopro com sensibilidade em 3 níveis,
calibração do ruído, teste ao vivo, varinha por toque, revelação de imagem, bolhas mais lentas quando
há muitas, orientação do microfone uma vez por dia); conforto sensorial (volume, efeitos, reduzir
movimento, tema calmo, vibração); detecção opcional de voz (só presença de som); diário com palavras
favoritas, notas e "copiar resumo"; apagar todos os dados; botão voltar do Android tratado.

**Falta (próximas etapas):**
- Fotos da câmera e da galeria com recorte e rótulo (por enquanto, as imagens vêm de `assets/imagens/`).
- Vários perfis de criança no mesmo aparelho.
- Falas fixas pré-geradas em áudio (o suporte já existe em `assets/falas/`; faltam os arquivos).
- Música de fundo (desligada por padrão no GDD).
- Exportar o diário em PDF (hoje: copiar o resumo em texto).
- Testes com famílias e revisão por fonoaudiólogos (GDD seção 17).

> Este app é uma brincadeira de apoio à comunicação. Ele não diagnostica, não trata e não substitui
> o acompanhamento profissional.
