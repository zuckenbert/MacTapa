# Plano: Fazer sons de porta funcionar no abrir/fechar da tampa

## Status: NAO FUNCIONA — precisa investigar

## O que foi feito (mas nao funciona)
- Sons novos baixados do SoundJay (door_open.wav, door_close.wav) em Resources/Sounds/DoorSounds/
- playDoorSound migrado pro AVAudioEngine com PCM buffers
- doorPlayerNode separado do playerNode
- Polling de clamshell reduzido de 1s para 0.5s
- Som de close toca antes de permitir sleep (1.5s delay)

## Hipoteses do que pode estar errado (investigar nesta ordem)

### 1. build.sh nao copia DoorSounds pro .app bundle
- Verificar se build.sh copia Resources/Sounds/DoorSounds/ para MacTapa.app/Contents/Resources/Sounds/DoorSounds/
- Se nao copia, os arquivos nao existem no runtime

### 2. AVAudioEngine morre durante sleep/wake
- AVAudioEngine pode ser interrompido pelo macOS ao entrar/sair de sleep
- O `if !engine.isRunning { try? engine.start() }` pode nao ser suficiente
- Talvez door sounds precisem usar AVAudioPlayer (mais resiliente a sleep) em vez do engine
- Ou: reiniciar engine no wake event explicitamente

### 3. AppleClamshellState nao funciona neste Mac
- Nem todo Mac retorna AppleClamshellState via IOKit
- Testar com: `ioreg -r -k AppleClamshellState | grep AppleClamshellState`
- Se nao retornar nada, precisa de approach diferente (display sleep/wake events)

### 4. LidDetector.start() pode nao estar sendo chamado
- Verificar logs "[MacTapa] LidDetector:" no terminal
- Se nao aparece, o start() nao esta rodando

### 5. Timing do sleep — som nao tem tempo de tocar
- Mesmo com 1.5s delay, o macOS pode cortar audio antes
- Alternativa: tocar som CURTISSIMO (<0.5s) tipo um "click" de porta
- Ou: usar NSSound em vez de AVAudioEngine pra door close (mais simples, bloqueia menos)

### 6. findDoorSound path errado
- O bundle path pode ser diferente do esperado com swift build
- Verificar com print(Bundle.main.resourcePath) no runtime

## Ordem de investigacao
1. Rodar o app e checar TODOS os logs de LidDetector no terminal
2. Verificar se DoorSounds esta no bundle: `ls MacTapa.app/Contents/Resources/Sounds/DoorSounds/`
3. Testar `ioreg -r -k AppleClamshellState` pra ver se o Mac suporta
4. Se clamshell funciona mas som nao toca: problema eh AVAudioEngine no contexto de sleep
5. Se clamshell NAO funciona: precisa de abordagem via display notifications (NSWorkspace)
