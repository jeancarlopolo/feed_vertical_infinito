# Feed Vertical Infinito (estilo TikTok/Reels com BlueSky)

Um aplicativo móvel em Flutter (Dart) que apresenta um feed de vídeos verticais, no estilo TikTok/Reels, utilizando a rede social Bluesky como backend, via a biblioteca `atproto`.

## 🤔 Visão Geral

Este projeto demonstra como construir um feed de vídeo vertical infinito em Flutter. Ele busca vídeos de um feed específico do BlueSky, faz o pré-cache dos vídeos para uma reprodução suave e gerencia o estado dos players de vídeo conforme o usuário rola.

## ✨ Funcionalidades

- Feed vertical infinito de vídeos.
- Reprodução de vídeo com `video_player`.
- Pré-cache assíncrono de vídeos usando `flutter_cache_manager` para carregamento rápido.
- Busca de vídeos da rede social BlueSky usando `bluesky` (que é um wrapper de `atproto`) e `atproto`.
- Gerenciamento de estado simples com `signals_flutter`.
- Injeção de dependência com `get_it`.
- Splash screen inicial.
- Sistema de fila duplamente encadeada para gerenciar os vídeos anteriores e seguintes.
- Testado em Android e iOS.

## 📁 Estrutura do Projeto

```
lib/
├── app/              # Configuração principal do app e ponto de entrada (main.dart)
├── models/           # Modelos de dados (ex: Video)
├── pages/            # Widgets de página/tela (ex: Feed, SplashScreen)
├── services/         # Lógica de negócios e comunicação com API (ex: BskyVideos)
├── utils/            # Funções e classes utilitárias (ex: Queue)
└── widgets/          # Widgets reutilizáveis (ex: MyVideoPlayer)
```

## ▶️ Como Executar

1.  **Clone o repositório:**
    ```bash
    git clone https://github.com/jeancarlopolo/feed_vertical_infinito.git
    cd feed_vertical_infinito
    ```
2.  **Instale as dependências:**
    ```bash
    flutter pub get
    ```
3.  **Execute o aplicativo:**
    ```bash
    flutter run
    ```

**Nota:** O aplicativo atualmente usa credenciais de autenticação fixas no código (`lib/app/main.dart`) para acessar o feed do BlueSky. Isso foi feito porque o feed específico usado para os vídeos não é público. Para produção ou um caso de uso mais robusto, um sistema de autenticação de usuário adequado deve ser implementado.

## 📦 Dependências Principais

- `flutter`: Framework de UI.
- `bluesky` / `atproto`: Bibliotecas para interagir com a API do BlueSky.
- `video_player`: Para reprodução de vídeos.
- `flutter_cache_manager`: Para cacheamento de arquivos (vídeos).
- `get_it`: Service locator para injeção de dependência.
- `signals_flutter`: Para gerenciamento de estado reativo.
- `logging`: Para logs.

## 🤖 Como IAs foram usadas nesse projeto

- [Cursor](https://www.cursor.com/) foi usada para escrever o código inicial, a maioria dos widgets (exceto o feed.dart que foi feito manualmente em sua maior parte), escrever o README, consertar erros de casos especiais e entender o funcionamento do ATProto e da API do BlueSky. O modelo usado foi o gemini-2.5-pro-exp-03-25.
- [Deepseek](https://chat.deepseek.com/) foi usada para planejar o projeto, a estratégia de cacheamento, consertar erros conceituais e outras dúvidas.

## 👨‍💻 Desenvolvido por

- [Jean Carlo Polo](https://github.com/jeancarlopolo)
