# Pitty Player

Um app Flutter para reproduzir arquivos MP3 armazenados nos assets do app, 100% offline.

## Configuração iOS (reaproveitada da base `notifica`)

- **iOS Deployment Target**: 15.0
- **Supported Devices**: iPhone e iPad
- **Development Team**: WN6A2CJM96 (Forven)
- **Bundle ID**: com.forven.pittyplayer
- **Background Modes**: Audio (habilitado para reprodução em segundo plano)

## Como adicionar músicas

1. Coloque os arquivos `.mp3` em `assets/musicas/`
2. Não é necessário alterar código — o app carrega automaticamente os arquivos
3. O título exibido é derivado do nome do arquivo (sem extensão e com _ convertido em espaços)

## Como rodar

```bash
flutter pub get
cd ios && pod install && cd ..
flutter run
```

## Como gerar o build iOS

```bash
flutter build ios --release
```

O app precisa ser assinado com a conta Apple da Forven (Team ID WN6A2CJM96).

## Estrutura do projeto

- `lib/main.dart` — Ponto de entrada do app
- `lib/models/track.dart` — Modelo de uma faixa de áudio
- `lib/services/audio_service.dart` — Gerencimento de reprodução de áudio
- `lib/screens/player_screen.dart` — Tela principal do player
- `lib/widgets/` — Componentes da UI (controles, barra de progresso, etc.)
- `assets/musicas/` — Pasta para arquivos MP3

## Dependências

- **just_audio**: Reprodução de arquivos de áudio locais
- **just_audio_background**: Controles em segundo plano / tela de bloqueio
- **audio_session**: Configuração da sessão de áudio

## Funcionalidades

- ✅ Play/Pause
- ✅ Próxima/Anterior faixa
- ✅ Seek (arrastar a barra de progresso)
- ✅ Reprodução em segundo plano (iOS)
- ✅ Destaque da faixa em reprodução na lista
- ✅ Carregamento automático de arquivos MP3 dos assets

## Notas

- O app inclui 3 arquivos MP3 de placeholder (silêncio) para testes
- A faixa atual é armazenada em memória — será perdida ao fechar o app
- Sem chamadas de rede ou streaming