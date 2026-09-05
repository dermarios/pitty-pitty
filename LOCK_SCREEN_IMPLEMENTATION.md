# Implementação de Player na Tela Bloqueada do iPhone

## 📱 Visão Geral

Esta implementação permite que o usuário visualize e controle a reprodução de música diretamente na tela bloqueada do iPhone, sem precisar abrir o aplicativo.

## 🏗️ Arquitetura

### 1. **LockScreenManager.swift** (iOS Native)
Gerencia toda a lógica de MediaPlayer e controles remotos:
- Atualiza informações "Now Playing" (título, artista, duração)
- Configura controles remotos (play, pause, próxima, anterior)
- Gerencia callbacks dos comandos remotos
- Trata erros sem impactar o app principal

```swift
LockScreenManager.shared.updateNowPlaying(
  title: "Máscara",
  artist: "Pitty",
  duration: 245.5,
  imageData: nil
)
```

### 2. **AppDelegate.swift** (Flutter/iOS Bridge)
Inicializa o Method Channel que conecta Flutter (Dart) com código nativo (Swift):
- Setup minimalista (sem delays)
- Registra handlers para métodos chamados do Flutter
- Encaminha comandos remotos de volta para Flutter

### 3. **AudioService.dart** (Flutter Logic)
Orquestra a sincronização entre reprodução de áudio e tela bloqueada:
- Notifica tela bloqueada quando música começa/pausa
- Processa comandos remotos (play/pause/next/previous)
- Graceful degradation se comunicação nativa falhar

## 🔄 Fluxo de Dados

### Reproduzindo uma Música
```
User clica em música
    ↓
AudioService.play(track)
    ↓
Flutter/AudioPlayer reproduz
    ↓
Notifica tela bloqueada via Method Channel
    ↓
LockScreenManager atualiza "Now Playing"
    ↓
Tela bloqueada mostra: [◀ título ▶] [⏯]
```

### Controle Remoto
```
User clica "Próxima" na tela bloqueada
    ↓
MediaPlayer notifica AppDelegate
    ↓
AppDelegate invoca callback setup em Swift
    ↓
Enviado via Method Channel para Flutter
    ↓
AudioService.next() executa
    ↓
Nova música toca
    ↓
Atualiza tela bloqueada com novo título
```

## 📡 Method Channel: com.forven.pittyplayer/lockscreen

### Métodos Chamados do Flutter → Native

| Método | Argumentos | Descrição |
|--------|-----------|-----------|
| `updateNowPlaying` | title, artist, duration, imageBase64 | Atualiza info da música |
| `updatePlaybackState` | isPlaying | Define se está tocando/pausado |
| `updateElapsedTime` | elapsedTime | Atualiza tempo decorrido |
| `clearNowPlaying` | — | Remove info da tela bloqueada |
| `setCommandHandlers` | — | Ativa handlers para controles remotos |

### Métodos Chamados do Native → Flutter

| Método | Argumentos | Descrição |
|--------|-----------|-----------|
| `onRemoteCommand` | command | Comando: "play", "pause", "next", "previous" |

## 🛡️ Tratamento de Erros

Todos os método têm try-catch interno com **graceful degradation**:
```dart
try {
  await _lockScreenChannel.invokeMethod('updateNowPlaying', {...});
} catch (e) {
  // Não afeta reprodução, apenas log silencioso
  // Música continua tocando normalmente
}
```

Se a tela bloqueada não conseguir ser atualizada, a reprodução continua funcionando perfeitamente.

## 🚀 Como Funciona

### Inicialização
1. AppDelegate registra Method Channel `com.forven.pittyplayer/lockscreen`
2. AudioService configura handlers para receber comandos remotos
3. LockScreenManager setup lazy (só quando primeira música toca)

### Durante Reprodução
1. `AudioService.play(track)` é chamado
2. Music player inicia reprodução
3. Chama `_updateLockScreenNowPlaying(track)` via Method Channel
4. LockScreenManager atualiza `MPNowPlayingInfoCenter`
5. iOS mostra na tela bloqueada automaticamente

### Comandos Remotos
1. User interage com controles na tela bloqueada
2. iOS notifica `RemoteCommandCenter`
3. LockScreenManager invoca callback apropriado
4. Envia de volta para Flutter via `onRemoteCommand`
5. AudioService processa (play/pause/next/previous)

## 💪 Recursos Implementados

✅ **Exibição de Informações**
- Título da música
- Artista
- Duração total
- Estado de reprodução (▶️ ou ⏸)

✅ **Controles Remotos**
- ⏮ Anterior
- ⏯ Play/Pause
- ⏭ Próxima

✅ **Robustez**
- Inicialização lazy (sem race conditions)
- Tratar de falhas graciosamente
- Sem crashes mesmo se native code falhar
- Música continua tocando em qualquer caso

✅ **Sincronização**
- Play/Pause automático na tela bloqueada
- Mudança de música atualiza tela bloqueada em tempo real

## 🔧 Próximas Melhorias

- [ ] Adicionar arte da música (albumArt)
- [ ] Atualizar tempo decorrido em tempo real
- [ ] Suportar rewind/fast-forward na tela bloqueada
- [ ] Persistir estado entre app restarts

## 📚 Referências

- [Apple MediaPlayer Framework](https://developer.apple.com/documentation/mediaplayer)
- [Flutter Method Channels](https://docs.flutter.dev/platform-integration/platform-channels)
- [iOS Now Playing Info](https://developer.apple.com/documentation/mediaplayer/mpnowplayinginfocentr)