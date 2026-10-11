# claude-plugins

Mes plugins [Claude Code](https://docs.claude.com/en/docs/claude-code/overview), regroupés par usage, plus un script pour les installer, les réinstaller ou les mettre à jour sur n'importe quelle machine (macOS, Linux, WSL, Windows).

## Installation rapide

**macOS / Linux / WSL / Git Bash**
```bash
curl -fsSL https://raw.githubusercontent.com/gudoy/claude-plugins/main/install.sh | bash
```

**Windows (PowerShell)**
```powershell
irm https://raw.githubusercontent.com/gudoy/claude-plugins/main/install.ps1 | iex
```

Ou en local, après un `git clone` :
```bash
./install.sh            # ajoute les marketplaces manquantes, installe les plugins manquants, met à jour les autres
./install.sh --export   # réécrit plugins.txt à partir des plugins installés sur cette machine
```
(`.\install.ps1` et `.\install.ps1 -Export` sous Windows.)

Le script peut être relancé sans risque : ce qui est déjà installé est seulement mis à jour. Redémarre ensuite Claude Code (ou lance `/reload-plugins`).

### Synchroniser plusieurs machines

1. Sur la machine de référence : `./install.sh --export`, puis commit et push de `plugins.txt`.
2. Sur les autres machines : `git pull && ./install.sh`.

`plugins.txt` est la seule source de vérité. Format :
```
marketplace <nom> <source>     # source = owner/repo GitHub, URL git, ou builtin
plugin <nom>@<marketplace>
```

### Après installation

- **github** : le serveur MCP lit `GITHUB_PERSONAL_ACCESS_TOKEN`. Avec le CLI `gh`, ajoute dans ton profil shell :
  `export GITHUB_PERSONAL_ACCESS_TOKEN="$(gh auth token 2>/dev/null)"`
- **Services hébergés** (Notion, Slack, Linear, Sentry, Stripe, Supabase…) : authentifie-toi via `/mcp` dans Claude Code.
- **Plugins LSP** : ils ont besoin du serveur de langage correspondant dans le `PATH` (`pyright`, `typescript-language-server`, `clangd`, `rust-analyzer`…).
- Le script clone en HTTPS : une clé SSH n'est pas nécessaire.

## Plugins

### Méthode et workflow de développement
| Plugin | Rôle | Source |
|---|---|---|
| superpowers | Bibliothèque de skills de process : brainstorming, plans, TDD, débogage systématique | [obra/superpowers](https://github.com/obra/superpowers) |
| ecc | Couche d'outillage très large : agents, skills, hooks et commandes pour tout le cycle de dev | [affaan-m/ECC](https://github.com/affaan-m/ECC) |
| agent-skills | Skills d'ingénierie couvrant spec, plan, build, vérification et revue | [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills) |
| mattpocock-skills | Skills de Matt Pocock : grilling, specs, TDD, revue de code, modélisation de domaine | [mattpocock/skills](https://github.com/mattpocock/skills) |
| andrej-karpathy-skills | Règles de conduite pour éviter les erreurs de code classiques des LLM | [multica-ai/andrej-karpathy-skills](https://github.com/multica-ai/andrej-karpathy-skills) |
| feature-dev | Workflow guidé de développement de feature avec agents d'exploration et d'architecture | [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/feature-dev) |
| code-review | Revue automatique de PR par plusieurs agents spécialisés | [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/code-review) |
| pr-review-toolkit | Agents de revue ciblés : tests, gestion d'erreurs, types, commentaires | [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/pr-review-toolkit) |
| code-simplifier | Agent qui simplifie le code récemment modifié sans changer son comportement | [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/code-simplifier) |
| commit-commands | Commandes pour commit, push et création de PR | [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/commit-commands) |

### Comportement de Claude, mémoire et configuration
| Plugin | Rôle | Source |
|---|---|---|
| caveman | Réponses ultra-compressées : environ 75 % de tokens en moins, précision technique intacte | [JuliusBrussee/caveman](https://github.com/JuliusBrussee/caveman) |
| i-have-adhd | Réponses orientées action, adaptées aux lecteurs TDAH | [ayghri/i-have-adhd](https://github.com/ayghri/i-have-adhd) |
| remember | Mémoire continue : résume les sessions en journaux quotidiens compressés | [Digital-Process-Tools/claude-remember](https://github.com/Digital-Process-Tools/claude-remember) |
| claude-md-management | Audit et amélioration des fichiers CLAUDE.md | [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/claude-md-management) |
| claude-code-setup | Analyse un projet et recommande hooks, skills, MCP et sous-agents adaptés | [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/claude-code-setup) |
| skill-creator | Création, amélioration et évaluation de skills | [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/skill-creator) |

### Design et frontend
| Plugin | Rôle | Source |
|---|---|---|
| frontend-design | Interfaces frontend soignées, loin des rendus génériques | [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/frontend-design) |
| ui-ux-pro-max | Base de connaissances UI/UX : styles, palettes, typographies, patterns | [nextlevelbuilder/ui-ux-pro-max-skill](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill) |
| taste-skill | Directions esthétiques frontend : brutaliste, minimaliste, soft, refonte… | [Leonxlnx/taste-skill](https://github.com/Leonxlnx/taste-skill) |

### Documents
| Plugin | Rôle | Source |
|---|---|---|
| document-skills | Lecture et création de fichiers Word, Excel, PowerPoint et PDF | [anthropics/skills](https://github.com/anthropics/skills) |
| example-skills | Skills d'exemple Anthropic : création de skills, MCP, design visuel, artefacts | [anthropics/skills](https://github.com/anthropics/skills) |

### Analyse de code et langages (LSP)
| Plugin | Rôle | Source |
|---|---|---|
| serena | Serveur MCP d'analyse sémantique du code : symboles, références, refactoring | [oraios/serena](https://github.com/oraios/serena) |
| typescript-lsp | Serveur de langage TypeScript / JavaScript | [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/typescript-lsp) |
| pyright-lsp | Serveur de langage Python (Pyright) | [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/pyright-lsp) |
| rust-analyzer-lsp | Serveur de langage Rust | [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/rust-analyzer-lsp) |
| swift-lsp | Serveur de langage Swift (SourceKit-LSP) | [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/swift-lsp) |
| kotlin-lsp | Serveur de langage Kotlin | [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/kotlin-lsp) |
| clangd-lsp | Serveur de langage C / C++ (clangd) | [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/clangd-lsp) |
| php-lsp | Serveur de langage PHP (Intelephense) | [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/php-lsp) |
| ruby-lsp | Serveur de langage Ruby | [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/ruby-lsp) |
| vue-volar | Serveur de langage Vue.js (Volar) | [Piebald-AI/claude-code-lsps](https://github.com/Piebald-AI/claude-code-lsps) |

### Sécurité et monitoring
| Plugin | Rôle | Source |
|---|---|---|
| claude-security | Scan de vulnérabilités du code, avec génération de patchs vérifiés | [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/claude-security) |
| security-guidance | Alertes de sécurité pendant l'édition et revue du diff en fin de tour | [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/security-guidance) |
| sentry | Erreurs Sentry : issues, stack traces, analyse et correction | [getsentry/plugin-claude](https://github.com/getsentry/plugin-claude) |
| sentry-cli | Skills pour piloter Sentry en ligne de commande | [getsentry/cli](https://github.com/getsentry/cli) |

### Navigateur, tests et documentation
| Plugin | Rôle | Source |
|---|---|---|
| playwright | Automatisation de navigateur et tests end-to-end (MCP Microsoft) | [microsoft/playwright-mcp](https://github.com/microsoft/playwright-mcp) |
| chrome-devtools-mcp | Contrôle et inspection d'un Chrome réel : réseau, performance, console | [ChromeDevTools/chrome-devtools-mcp](https://github.com/ChromeDevTools/chrome-devtools-mcp) |
| context7 | Documentation à jour des librairies et frameworks | [upstash/context7](https://github.com/upstash/context7) |

### Cloud, bases de données et backend
| Plugin | Rôle | Source |
|---|---|---|
| aws-core | Construire, déployer et opérer sur AWS : IaC, services, IAM, coûts | [aws/agent-toolkit-for-aws](https://github.com/aws/agent-toolkit-for-aws) |
| cloudflare | Workers, Durable Objects, Agents SDK, Wrangler et plateforme Cloudflare | [cloudflare/skills](https://github.com/cloudflare/skills) |
| supabase | MCP Supabase : base, auth, stockage, temps réel | [supabase-community/supabase-plugin](https://github.com/supabase-community/supabase-plugin) |
| neon-postgres | Postgres serverless Neon : branches, auth, stockage, MCP | [neondatabase/agent-skills](https://github.com/neondatabase/agent-skills) |
| mongodb | MCP et skills MongoDB : requêtes, schémas, index, Atlas | [mongodb/agent-skills](https://github.com/mongodb/agent-skills) |
| redis-development | Bonnes pratiques Redis : structures, recherche vectorielle, cache | [redis/agent-skills](https://github.com/redis/agent-skills) |
| apollo-skills | GraphQL avec Apollo : Client, Server, Federation, Router, Rover | [apollographql/skills](https://github.com/apollographql/skills) |
| expo | Applications React Native avec Expo : UI, EAS, mises à jour, publication | [expo/skills](https://github.com/expo/skills) |
| huggingface-skills | Modèles, datasets et Spaces Hugging Face : recherche, entraînement, déploiement | [huggingface/skills](https://github.com/huggingface/skills) |
| dominodatalab | Plateforme Domino Data Lab : jobs, modèles, expériences, déploiements | [dominodatalab/domino-claude-plugin](https://github.com/dominodatalab/domino-claude-plugin) |

### APIs, paiement, email et analytics
| Plugin | Rôle | Source |
|---|---|---|
| stripe | Intégration Stripe : paiements, abonnements, bonnes pratiques | [stripe/ai](https://github.com/stripe/ai/tree/main/providers/claude/plugin) |
| resend | Envoi et réception d'emails avec Resend, React Email | [resend/resend-skills](https://github.com/resend/resend-skills) |
| postman | Collections, mocks, tests et monitoring d'API avec Postman | [postmanlabs/postman-plugin](https://github.com/postmanlabs/postman-plugin) |
| product-tracking | Plan de tracking et instrumentation analytics pour produits SaaS | [accoil/product-tracking-skills](https://github.com/accoil/product-tracking-skills) |

### Collaboration et gestion de projet
| Plugin | Rôle | Source |
|---|---|---|
| github | MCP GitHub officiel : issues, PR, revue, recherche de code | [github/github-mcp-server](https://github.com/github/github-mcp-server) |
| linear | Tickets et projets Linear | [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official/tree/main/external_plugins/linear) |
| notion | Pages et bases Notion : recherche, création, mise à jour | [makenotion/claude-code-notion-plugin](https://github.com/makenotion/claude-code-notion-plugin) |
| slack | Messages, canaux et fils Slack | [slackapi/slack-mcp-plugin](https://github.com/slackapi/slack-mcp-plugin) |

## Plugins synchronisés depuis claude.ai (hors script)

Ces plugins suivent mon compte claude.ai et se synchronisent tout seuls. Le script ne les gère pas.

| Plugin | Rôle | Source |
|---|---|---|
| engineering, design, data, productivity, product-management, cowork-plugin-management | Workflows métier Anthropic (knowledge work) | [anthropics/knowledge-work-plugins](https://github.com/anthropics/knowledge-work-plugins) |
| pdf-viewer | Lecture, annotation et signature de PDF | [anthropics/knowledge-work-plugins](https://github.com/anthropics/knowledge-work-plugins) |
| dev-mentor | Mentor qui guide par des questions plutôt que des réponses | [IrinaTerebiznik/claud-coach](https://github.com/IrinaTerebiznik/claud-coach) |
| desktop-commander | Terminal, processus et fichiers via MCP | [wonderwhy-er/DesktopCommanderMCP](https://github.com/wonderwhy-er/DesktopCommanderMCP) |
| slack-by-salesforce | MCP Slack officiel | [slackapi/slack-mcp-plugin](https://github.com/slackapi/slack-mcp-plugin) |
| dropbox | Fichiers Dropbox : recherche, rangement, partage | [dropbox.com](https://www.dropbox.com) |
| figma | MCP Figma et skills associés | — |
| prisma | MCP Prisma : Postgres, migrations, requêtes | — |

## Licence

[MIT](LICENSE)
