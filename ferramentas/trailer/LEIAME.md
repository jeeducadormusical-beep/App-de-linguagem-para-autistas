# Como gerar o trailer de novo

O trailer é gravado com o próprio jogo, pelo Movie Maker do Godot. O script `trailer.gd`
joga sozinho e mostra as legendas. A trilha calma é gerada por `musica.py`.

```bash
# 1. gravar (720x1280, 30 fps)
godot --path . --resolution 720x1280 --write-movie bruto.avi --fixed-fps 30 -s ferramentas/trailer/trailer.gd

# 2. gerar a trilha com a mesma duração do vídeo (precisa de numpy)
python3 ferramentas/trailer/musica.py 65.4 musica.wav

# 3. juntar e converter para MP4
ffmpeg -i bruto.avi -i musica.wav -filter_complex "[1:a]volume=0.55[m];[0:a][m]amix=inputs=2:duration=first:normalize=0,alimiter=limit=0.9[a]" \
  -map 0:v -map "[a]" -c:v libx264 -crf 21 -pix_fmt yuv420p -movflags +faststart -c:a aac -b:a 160k divulgacao/Fala-Brincando-trailer.mp4
```

Os textos das legendas ficam no fim de `trailer.gd` (funções `dizer` e `cartela`).
