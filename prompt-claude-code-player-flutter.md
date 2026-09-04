# Prompt para o Claude Code — App Player de Músicas (Flutter, offline)

> Cole o conteúdo abaixo (tudo dentro do bloco) diretamente no Claude Code, na raiz onde você quer criar o projeto.

---

## Objetivo

Construa um app **player de músicas em Flutter** que toca arquivos **.mp3 empacotados dentro do próprio app** (nos *assets*), **100% offline — sem streaming e sem qualquer chamada a servidor**. O app deve reaproveitar **toda a base de configuração de build para iOS** do app já existente da Forven: `https://github.com/forven-sistemas/notifica`.

## Base de build iOS a reaproveitar (primeiro passo, obrigatório)

Antes de escrever qualquer código do player:

1. Clone/inspecione o repositório base `forven-sistemas/notifica` (se você tiver acesso local a ele; caso não tenha, me peça o caminho local ou o `.zip`).
2. Detecte se `notifica` é um projeto Flutter. Em seguida, **extraia e replique no novo projeto exatamente a configuração de build iOS**, incluindo:
   - Versão do **deployment target** iOS e a `platform :ios` do `ios/Podfile`.
   - Estrutura e chaves relevantes do `ios/Runner/Info.plist`.
   - Esquema de **assinatura / Team ID / provisioning** e as `build settings` do `Runner.xcodeproj` / `Runner.xcworkspace` (mantendo o mesmo time/conta Apple da Forven, mas **criando um novo `PRODUCT_BUNDLE_IDENTIFIER`** seguindo o padrão de nomes da `notifica`, ex.: `com.forven.<algo>`).
   - Configurações de `flutter` / versão do SDK no `pubspec.yaml`, versões fixadas e `Podfile.lock` de referência quando fizer sentido.
   - Ícones e *launch screen* (abordagem usada na `notifica`), fastlane e/ou CI (workflows) de build/deploy iOS, se existirem.
3. **Não invente** valores dessas configs: leia do repositório base e reutilize. Onde precisar de um valor novo (ex.: novo bundle id, nome do app), pergunte ou siga o padrão existente e deixe explícito no diff.

> Assuma que `notifica` é Flutter. Se for nativo (Swift/Obj-C) ou outra stack, **pare e me avise** antes de prosseguir, explicando o que muda no reaproveitamento.

## Tecnologia

- **Flutter** (canal stable) + Dart.
- Reprodução de áudio local: **`just_audio`**.
- Controles em segundo plano / tela de bloqueio no iOS: **`just_audio_background`**.
- Configuração de sessão de áudio: **`audio_session`**.
- Sem nenhuma dependência de rede, HTTP, streaming ou backend.

## Como as músicas ficam no app

- Os `.mp3` ficam em uma pasta de assets, ex.: **`assets/musicas/`**.
- Declare a pasta em `pubspec.yaml` (`flutter: assets: - assets/musicas/`).
- A lista de faixas deve ser **descoberta automaticamente** lendo o `AssetManifest.json` (via `rootBundle`) e filtrando os arquivos `.mp3` dentro de `assets/musicas/`. Assim, **adicionar um novo mp3 na pasta é suficiente** — sem alterar código.
- O título exibido de cada faixa deve vir do nome do arquivo (limpo, sem extensão); se você conseguir ler tags ID3 de forma simples/offline, use-as como melhoria opcional, sem quebrar o app caso não existam.
- Inclua 2 ou 3 mp3s de placeholder (silêncio/curtos, livres de direitos) apenas para o app rodar; deixe claro no README que devem ser substituídos pelos arquivos reais.

## Layout da tela inicial

A **tela inicial é o próprio player**, dividida verticalmente:

- **Metade de cima (≈ 50% da altura da tela): o PLAYER**, contendo:
  - Título da faixa atual (e artista, se disponível).
  - Uma arte/placeholder visual da faixa.
  - **Barra de progresso (seek)** com tempo atual e duração total, arrastável.
  - Controles: **anterior, play/pause, próximo**. Opcional: *shuffle* e *repeat*.
- **Metade de baixo (≈ 50% da altura): a LISTA DE MÚSICAS**, rolável:
  - Cada item mostra o título da faixa.
  - Tocar em um item inicia a reprodução daquela faixa.
  - A faixa em reprodução fica **destacada** na lista.

Divida a tela usando um `Column` com dois blocos de proporção equivalente (ex.: `Expanded(flex: 1)` para o player e `Expanded(flex: 1)` para a lista), respeitando `SafeArea`. Deve funcionar em telas de tamanhos diferentes sem overflow.

## Requisitos de reprodução

- Play/pause, avançar/voltar faixa, e **seek** funcionando.
- Continuar tocando com o app em segundo plano e mostrar controles na tela de bloqueio do iOS (via `just_audio_background`).
- No `ios/Runner/Info.plist`, garanta `UIBackgroundModes` com `audio`.
- Gerenciar o ciclo de vida do player (dispose correto) para não vazar recursos.

## Estrutura e qualidade de código

- Organize em algo como: `lib/main.dart`, `lib/screens/player_screen.dart`, `lib/services/audio_service.dart` (carrega assets + controla o `just_audio`), `lib/models/track.dart`, `lib/widgets/` (controles do player, item da lista, barra de progresso).
- Estado gerenciado de forma simples e clara (pode ser `StatefulWidget` + `Stream`s do `just_audio`, ou um provider leve). Evite over-engineering.
- Código comentado nos pontos não óbvios, nomes em português ou inglês consistentes.

## Entregáveis

1. Projeto Flutter completo e compilável.
2. Configuração iOS reaproveitada da `notifica` (com o diff do que foi copiado/adaptado e o novo bundle id destacados).
3. `pubspec.yaml` com as dependências e a pasta de assets declaradas.
4. `README.md` explicando: como adicionar mp3s em `assets/musicas/`, como rodar (`flutter pub get`, `cd ios && pod install`, `flutter run`) e como gerar o build iOS.

## Critérios de aceite

- [ ] `flutter analyze` sem erros.
- [ ] App abre já na tela do player (metade de cima player, metade de baixo lista).
- [ ] A lista é preenchida automaticamente a partir dos mp3s em `assets/musicas/`.
- [ ] Play/pause, próxima/anterior e seek funcionam; faixa tocando fica destacada na lista.
- [ ] Nenhuma chamada de rede/streaming no código.
- [ ] Build iOS usa a mesma base de configuração da `notifica`, com bundle id novo.

## Passos sugeridos (execute nesta ordem e vá me mostrando o progresso)

1. Inspecionar `notifica` e documentar a config iOS a reaproveitar.
2. Criar o projeto Flutter e aplicar a config iOS (Podfile, Info.plist, signing, deployment target, bundle id, ícones/launch).
3. Adicionar dependências (`just_audio`, `just_audio_background`, `audio_session`) e a pasta `assets/musicas/`.
4. Implementar o `audio_service` com descoberta automática via `AssetManifest.json`.
5. Implementar a `player_screen` com o layout 50/50 e os controles.
6. Testar reprodução, seek, background e destaque da faixa atual.
7. Escrever o README e rodar `flutter analyze`.

Comece pelo passo 1 e me confirme o que encontrou na base `notifica` antes de gerar o código do player.
