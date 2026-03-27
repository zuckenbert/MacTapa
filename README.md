# MacTapa

Da um tapa no Mac. Ele reage.

App macOS menu bar que usa o acelerometro do Apple Silicon pra detectar tapas e tocar sons brasileiros.

## Requisitos

- macOS 14+ (Sonoma)
- Apple Silicon (M1/M2/M3/M4)
- Precisa rodar com `sudo` pra acessar o acelerometro

## Como usar

```bash
swift build -c release
sudo .build/release/MacTapa
```

## Sound Packs

Coloque arquivos `.mp3` ou `.wav` em `~/.mactapa/sounds/<NomeDoPack>/`

### Packs incluidos
- **Gemidao Classic** - O classico que dispensa apresentacoes

## Atalho de teclado

Se o acelerometro nao estiver disponivel, use `Ctrl+Shift+T` pra simular um tapa.

## Licenca

MIT
