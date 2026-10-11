# claude-plugins

My [Claude Code](https://docs.claude.com/en/docs/claude-code/overview) *harness* plugins (workflow, behavior, review, design, LSP, security), grouped by use, plus a script to install, reinstall or update them on any machine (macOS, Linux, WSL, Windows).

## Quick install

**macOS / Linux / WSL / Git Bash**
```bash
curl -fsSL https://raw.githubusercontent.com/gudoy/claude-plugins/main/install.sh | bash
```

**Windows (PowerShell)**
```powershell
irm https://raw.githubusercontent.com/gudoy/claude-plugins/main/install.ps1 | iex
```

Or locally, after a `git clone`:
```bash
./install.sh                  # all plugins: install the missing ones, update the rest
./install.sh caveman serena   # only the named plugins
./install.sh --pick           # numbered list, answer e.g. "1 4 7-9" or "all"
./install.sh --export         # add to plugins.txt the plugins installed here but not listed yet
```
Windows: `.\install.ps1`, `.\install.ps1 caveman serena`, `.\install.ps1 -Pick`, `.\install.ps1 -Export`.

To choose plugins from the remote command:
```bash
curl -fsSL https://raw.githubusercontent.com/gudoy/claude-plugins/main/install.sh | bash -s -- --pick
```
```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/gudoy/claude-plugins/main/install.ps1))) -Pick
```

The script is safe to run again: plugins that are already installed are only updated. Then restart Claude Code (or run `/reload-plugins`).

### Sync several machines

1. On the reference machine: run `./install.sh --export`, review what it added, then commit and push `plugins.txt`.
2. On the other machines: `git pull && ./install.sh`.

`plugins.txt` is the single source of truth. Format:
```
marketplace <name> <source>     # source = GitHub owner/repo, git URL, or builtin
plugin <name>@<marketplace>     # installed and updated by the script
exclude <name>@<marketplace>    # installed on my machine but kept out of this repo; --export never adds it back
```
Third-party service connectors (Stripe, Supabase, GitHub, Notion…) are marked `exclude`: this repo keeps only the harness.

### After installing

- **headroom** needs its CLI: `uv tool install --python 3.13 "headroom-ai[all]"` (or `pip install "headroom-ai[all]"`).
- **LSP plugins** need the matching language server on your `PATH` (`pyright`, `typescript-language-server`, `clangd`, `rust-analyzer`…).
- The script clones over HTTPS, so you don't need an SSH key.

## Plugins

### Development workflow and method
| Plugin | What it does | Source |
|---|---|---|
| superpowers | Process skills library: brainstorming, plans, TDD, systematic debugging | [obra/superpowers](https://github.com/obra/superpowers) |
| ecc | Very broad toolkit: agents, skills, hooks and commands for the whole dev cycle | [affaan-m/ECC](https://github.com/affaan-m/ECC) |
| agent-skills | Engineering skills covering spec, plan, build, verify and review | [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills) |
| mattpocock-skills | Matt Pocock's skills: grilling, specs, TDD, code review, domain modeling | [mattpocock/skills](https://github.com/mattpocock/skills) |
| andrej-karpathy-skills | Guidelines that prevent common LLM coding mistakes | [multica-ai/andrej-karpathy-skills](https://github.com/multica-ai/andrej-karpathy-skills) |
| feature-dev | Guided feature development with exploration and architecture agents | [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/feature-dev) |
| code-review | Automated PR review by several specialized agents | [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/code-review) |
| pr-review-toolkit | Focused review agents: tests, error handling, types, comments | [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/pr-review-toolkit) |
| code-simplifier | Agent that simplifies recently changed code without changing behavior | [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/code-simplifier) |
| commit-commands | Commands to commit, push and open a PR | [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/commit-commands) |

### Claude's behavior, memory and configuration
| Plugin | What it does | Source |
|---|---|---|
| caveman | Ultra-compressed replies: about 75% fewer tokens, same technical accuracy | [JuliusBrussee/caveman](https://github.com/JuliusBrussee/caveman) |
| headroom | Starts the Headroom runtime, which compresses tool outputs, logs and files before they reach the model (needs the `headroom` CLI) | [headroomlabs-ai/headroom](https://github.com/headroomlabs-ai/headroom) |
| i-have-adhd | Action-first replies, shaped for ADHD readers | [ayghri/i-have-adhd](https://github.com/ayghri/i-have-adhd) |
| remember | Continuous memory: summarizes sessions into compressed daily logs | [Digital-Process-Tools/claude-remember](https://github.com/Digital-Process-Tools/claude-remember) |
| claude-md-management | Audits and improves CLAUDE.md files | [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/claude-md-management) |
| claude-code-setup | Analyzes a project and recommends fitting hooks, skills, MCP servers and subagents | [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/claude-code-setup) |
| skill-creator | Creates, improves and evaluates skills | [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/skill-creator) |

### Design and frontend
| Plugin | What it does | Source |
|---|---|---|
| frontend-design | Polished frontend interfaces that avoid generic-looking output | [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/frontend-design) |
| ui-ux-pro-max | UI/UX knowledge base: styles, palettes, typography, patterns | [nextlevelbuilder/ui-ux-pro-max-skill](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill) |
| taste-skill | Frontend aesthetic directions: brutalist, minimalist, soft, redesign… | [Leonxlnx/taste-skill](https://github.com/Leonxlnx/taste-skill) |

### Documents
| Plugin | What it does | Source |
|---|---|---|
| document-skills | Reads and creates Word, Excel, PowerPoint and PDF files | [anthropics/skills](https://github.com/anthropics/skills) |
| example-skills | Anthropic example skills: skill creation, MCP, visual design, artifacts | [anthropics/skills](https://github.com/anthropics/skills) |

### Code intelligence and language servers (LSP)
| Plugin | What it does | Source |
|---|---|---|
| serena | MCP server for semantic code analysis: symbols, references, refactoring | [oraios/serena](https://github.com/oraios/serena) |
| typescript-lsp | TypeScript / JavaScript language server | [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/typescript-lsp) |
| pyright-lsp | Python language server (Pyright) | [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/pyright-lsp) |
| rust-analyzer-lsp | Rust language server | [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/rust-analyzer-lsp) |
| swift-lsp | Swift language server (SourceKit-LSP) | [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/swift-lsp) |
| kotlin-lsp | Kotlin language server | [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/kotlin-lsp) |
| clangd-lsp | C / C++ language server (clangd) | [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/clangd-lsp) |
| php-lsp | PHP language server (Intelephense) | [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/php-lsp) |
| ruby-lsp | Ruby language server | [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/ruby-lsp) |
| vue-volar | Vue.js language server (Volar) | [Piebald-AI/claude-code-lsps](https://github.com/Piebald-AI/claude-code-lsps) |

### Security
| Plugin | What it does | Source |
|---|---|---|
| claude-security | Scans code for vulnerabilities and generates verified patches | [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/claude-security) |
| security-guidance | Security warnings while editing, plus a diff review at the end of each turn | [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/security-guidance) |

### Browser, testing and documentation
| Plugin | What it does | Source |
|---|---|---|
| playwright | Browser automation and end-to-end testing (Microsoft MCP) | [microsoft/playwright-mcp](https://github.com/microsoft/playwright-mcp) |
| chrome-devtools-mcp | Controls and inspects a real Chrome: network, performance, console | [ChromeDevTools/chrome-devtools-mcp](https://github.com/ChromeDevTools/chrome-devtools-mcp) |
| context7 | Up-to-date documentation for libraries and frameworks | [upstash/context7](https://github.com/upstash/context7) |

## Plugins synced from claude.ai (not handled by the script)

These plugins follow my claude.ai account and sync on their own. The script does not manage them. Third-party connectors are not listed.

| Plugin | What it does | Source |
|---|---|---|
| engineering, design, data, productivity, product-management, cowork-plugin-management | Anthropic knowledge-work workflows | [anthropics/knowledge-work-plugins](https://github.com/anthropics/knowledge-work-plugins) |
| pdf-viewer | Reads, annotates and signs PDFs | [anthropics/knowledge-work-plugins](https://github.com/anthropics/knowledge-work-plugins) |
| dev-mentor | Mentor that guides with questions instead of answers | [IrinaTerebiznik/claud-coach](https://github.com/IrinaTerebiznik/claud-coach) |

## License

[MIT](LICENSE)
