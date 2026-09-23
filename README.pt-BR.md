<div align="center">

<img src="docs/images/icon.png" width="112" alt="Ícone do Pomelo">

# Pomelo

**Um timer Pomodoro calmo e bonito, para o navegador e para o Mac.**

Arraste o mostrador para definir a sessão, escreva no que você vai trabalhar e deixe a cor da tela dizer se é hora de focar ou de descansar.

[![Web app](https://img.shields.io/badge/web-abrir%20Pomelo-3346E0?style=flat-square)](https://d-henrique.github.io/pomelo/)
[![Baixar para macOS](https://img.shields.io/github/v/release/D-henrique/pomelo?style=flat-square&label=macOS&color=151827)](https://github.com/D-henrique/pomelo/releases/latest)
[![Build macOS](https://img.shields.io/github/actions/workflow/status/D-henrique/pomelo/macos.yml?branch=main&style=flat-square&label=build)](https://github.com/D-henrique/pomelo/actions/workflows/macos.yml)
[![Licença: MIT](https://img.shields.io/badge/licen%C3%A7a-MIT-0C8467?style=flat-square)](LICENSE)

[**Abrir o web app**](https://d-henrique.github.io/pomelo/) · [**Baixar para macOS**](https://github.com/D-henrique/pomelo/releases/latest) · [Read in English](README.md)

<br>

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/images/web-dark.png">
  <img src="docs/images/web-light.png" alt="Web app do Pomelo: mostrador de 60 minutos com 17:42 restantes, a intenção 'Draft the Q4 roadmap', progresso do ciclo, estatísticas do dia e gráfico de 7 dias" width="100%">
</picture>

</div>

## Por que o Pomelo

A maioria dos apps Pomodoro é um cronômetro cru ou um painel que disputa sua atenção. O Pomelo fica no meio. Ele foi desenhado depois de estudar os timers mais bem avaliados da Mac App Store, e só as ideias que realmente ajudam a focar ficaram:

| Ideia | Inspirada em | Como o Pomelo faz |
| --- | --- | --- |
| Definir uma intenção antes de começar | Session | Uma linha acima do timer; ela aparece dentro do mostrador enquanto você trabalha e fica salva com a sessão |
| A tela inteira reflete o modo | Session | Foco é azul, pausa curta é verde, pausa longa é ameixa; o tom do fundo muda suavemente entre eles |
| Ajuste físico e direto do tempo | Focus Keeper, Time Timer | Um mostrador de 60 minutos, como um timer de cozinha, que você arrasta; a fatia diminui conforme o tempo passa |
| Contagem sempre à vista | Flow, Be Focused, Tomito | Contagem ao vivo na barra de menus (Mac) e no título da aba (web) |
| Não parar no meio de um raciocínio | Session | O modo *Overflow* continua contando depois do zero até você decidir terminar |
| Não atrapalhar | TomatoBar | Sem conta, sem rastreamento, pensado para o teclado, e um modo zen que esconde tudo menos o mostrador |

## Recursos

| | Web | macOS |
| --- | :---: | :---: |
| Mostrador de 60 minutos para arrastar | ✓ | ✓ |
| Foco, pausa curta e pausa longa com ciclo automático | ✓ | ✓ |
| Intenções e tags (Deep work, Writing, Study, Admin) | ✓ | ✓ |
| Modo overflow | ✓ | ✓ |
| Início automático de pausas e sessões de foco | ✓ | ✓ |
| Som ao terminar uma sessão | ✓ | ✓ |
| Som ambiente durante o foco (ruído marrom, chuva leve), gerado na hora | ✓ | ✓ |
| Minutos, sessões, sequência de dias, meta diária e gráfico de 7 dias | ✓ | ✓ |
| Temas claro, escuro e do sistema | ✓ | ✓ |
| Modo zen | ✓ | |
| Contagem na barra de menus com painel de controle compacto | | ✓ |
| Notificações do sistema | | ✓ |
| Mantém a tela acordada durante a sessão | ✓ ¹ | ✓ |
| Janela sempre visível | | ✓ |

¹ Em navegadores com suporte à Screen Wake Lock API.

## Capturas de tela

<table>
  <tr>
    <td width="68%"><img src="docs/images/macos-light.png" alt="Pomelo para macOS, tema claro"></td>
    <td width="32%" rowspan="2"><img src="docs/images/web-mobile-dark.png" alt="Web app do Pomelo no celular, tema escuro"></td>
  </tr>
  <tr>
    <td><img src="docs/images/macos-dark.png" alt="Pomelo para macOS, tema escuro"></td>
  </tr>
</table>

<p align="center">
  <img src="docs/images/macos-menubar-light.png" width="300" alt="Painel da barra de menus, claro">
  &nbsp;&nbsp;
  <img src="docs/images/macos-menubar-dark.png" width="300" alt="Painel da barra de menus, escuro">
</p>

## Como usar

### No navegador

Abra **[d-henrique.github.io/pomelo](https://d-henrique.github.io/pomelo/)**. Funciona no computador e no celular, sem instalar nada.

O web app é um único arquivo HTML, sem etapa de build e sem dependências. Para rodar por conta própria, abra [`web/index.html`](web/index.html) direto no navegador ou publique em qualquer hospedagem estática.

### No Mac

1. Baixe o **Pomelo-macOS.zip** da [versão mais recente](https://github.com/D-henrique/pomelo/releases/latest) e descompacte.
2. Mova o **Pomelo.app** para a pasta Aplicativos.
3. Na primeira vez, clique com o botão direito no app e escolha **Abrir**.

Requer macOS 14 Sonoma ou mais recente. É um app universal: roda nativamente em Apple silicon e Intel.

> [!NOTE]
> As versões publicadas têm assinatura ad-hoc, mas não são notarizadas pela Apple, por isso o macOS pede confirmação na primeira abertura. Se preferir, compile a partir do código-fonte; leva cerca de um minuto.

### Compilar a partir do código-fonte

Você só precisa das Command Line Tools do Xcode (`xcode-select --install`). O Xcode completo não é necessário.

```bash
git clone https://github.com/D-henrique/pomelo.git
cd pomelo
./macos/build.sh
open macos/build/Pomelo.app
```

O `build.sh` compila um binário universal com `swiftc`, gera o ícone do app, escreve o `Info.plist` e assina o pacote com assinatura ad-hoc.

## Atalhos de teclado

| Ação | Web | macOS |
| --- | --- | --- |
| Iniciar / pausar / terminar | <kbd>Espaço</kbd> | <kbd>⌘</kbd> <kbd>↩</kbd> |
| Reiniciar | <kbd>R</kbd> | <kbd>⌘</kbd> <kbd>R</kbd> |
| Pular para o próximo | <kbd>S</kbd> | <kbd>⌘</kbd> <kbd>→</kbd> |
| Foco / pausa curta / pausa longa | <kbd>1</kbd> <kbd>2</kbd> <kbd>3</kbd> | <kbd>⌘</kbd> <kbd>1</kbd> <kbd>2</kbd> <kbd>3</kbd> |
| Editar intenção | <kbd>I</kbd> | |
| Trocar tema | <kbd>T</kbd> | |
| Modo zen | <kbd>Z</kbd> | |
| Ajustes | <kbd>,</kbd> | <kbd>⌘</kbd> <kbd>,</kbd> |
| Janela sempre visível | | <kbd>⇧</kbd> <kbd>⌘</kbd> <kbd>T</kbd> |

## Como funciona

- **Tempo preciso.** O timer guarda o horário de término em vez de contar ticks, então continua exato com a aba em segundo plano ou com o Mac em repouso.
- **O ciclo.** Depois de cada sessão de foco vem uma pausa curta; depois da quarta (configurável), uma pausa longa. Pular uma sessão de foco avança o ciclo, mas não a registra.
- **O som ambiente** é sintetizado na hora (Web Audio na web, `AVAudioEngine` no Mac), então não há arquivos de áudio para baixar.
- **As estatísticas** mostram uma *Semana de exemplo*, claramente identificada, até você terminar sua primeira sessão; depois disso, só os seus dados.

## Privacidade

O Pomelo não tem contas, analytics nem servidores. Tudo fica no seu dispositivo:

- **Web:** ajustes e histórico ficam no `localStorage` do navegador. As únicas requisições de rede são das fontes do Google Fonts.
- **macOS:** ajustes e histórico ficam no `UserDefaults` do seu Mac. O app não faz nenhuma requisição de rede.

## Estrutura do projeto

```
pomelo/
├── web/
│   └── index.html          # O web app inteiro: HTML, CSS e JS, sem dependências
├── macos/
│   ├── Sources/
│   │   ├── App.swift       # Entrada do app: janela, barra de menus, ajustes, comandos
│   │   ├── Model.swift     # Máquina de estados do timer, persistência, estatísticas, áudio
│   │   └── Views.swift     # Mostrador, controles, coluna lateral, painel da barra de menus, ajustes
│   ├── Scripts/
│   │   └── make_icon.swift # Gera o ícone do app em todos os tamanhos
│   └── build.sh            # Compila, assina e empacota o Pomelo.app
├── scripts/                # Regenera as capturas de tela do README
├── docs/images/            # Capturas de tela e ícone usados no README
└── .github/workflows/      # Deploy no Pages, build e release do app para macOS
```

## Design

Os dois apps compartilham um pequeno conjunto de tokens de design:

| Token | Claro | Escuro | Uso |
| --- | --- | --- | --- |
| Foco | `#3346E0` | `#8190FF` | Modo foco, progresso, meta diária |
| Pausa curta | `#0C8467` | `#3ECFA6` | Modo pausa curta |
| Pausa longa | `#A93D7A` | `#F07DB8` | Modo pausa longa |
| Fundo | `#F2F3F7` | `#0C0E16` | Fundo do app |
| Superfície | `#FFFFFF` | `#151827` | Centro do mostrador, cartões |
| Texto | `#151827` | `#E9EBF4` | Texto principal |

O web app usa [Bricolage Grotesque](https://fonts.google.com/specimen/Bricolage+Grotesque) nos números e títulos, [Onest](https://fonts.google.com/specimen/Onest) no texto e [JetBrains Mono](https://fonts.google.com/specimen/JetBrains+Mono) nos rótulos. O app para Mac usa SF Pro Rounded e SF Mono.

Para regenerar as capturas de tela depois de mudar a interface, rode `scripts/screenshots.sh`.

## Publicando uma nova versão

1. Atualize o [CHANGELOG.md](CHANGELOG.md) e a versão em `CFBundleShortVersionString` no `macos/build.sh`.
2. Crie a tag e envie:

   ```bash
   git tag v1.1.0
   git push origin v1.1.0
   ```

3. O GitHub Actions compila o app universal e publica uma release com o zip e o checksum SHA-256. Mudanças em `web/` vão para o GitHub Pages automaticamente a cada push na `main`.

## Próximos passos

- Atalho global para iniciar e pausar de qualquer app
- Sincronização do histórico entre Macs pelo iCloud
- Ações do Atalhos e um esquema de URL (`pomelo://start`)
- Bloqueio opcional de distrações durante o foco
- Exportação do histórico em CSV

Ideias e pull requests são bem-vindos. Veja [Contribuindo](#contribuindo).

## Contribuindo

1. Faça um fork e crie uma branch: `git checkout -b feature/minha-ideia`.
2. Para o web app, edite `web/index.html` e abra no navegador. Para o app do Mac, rode `./macos/build.sh`.
3. Mantenha os dois apps consistentes: um recurso ou token alterado em um deve ser espelhado no outro quando fizer sentido.
4. Abra um pull request descrevendo a mudança, com uma captura de tela se mexer na interface. O CI compila o app do Mac em todo pull request.

## Licença

[MIT](LICENSE) © 2026 Doug Moreira
