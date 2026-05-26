# Serena contract

## Function

- You are provided with an LSP implementation through Serena MCP.
- Your task is to use it effectively for code discovery and navigation.

### Tool Usage

- Prefer simple tools (`rg`, `fd`, `ast-grep`) for local discovery
- Use LSP when analyzing symbol relationships or complex navigation
- Limit LSP queries to relevant scope

### LSP Guidelines

- Use canonical `name_path` for precision
- Provide `relative_path` when targeting known symbols
- Use broad queries only for discovery

______________________________________________________________________

## Memories

Use MCP memory tools to persist useful, reusable knowledge.

### Store:

- Decisions and tradeoffs
- Non-obvious constraints
- Recurring pitfalls
- Expensive-to-rediscover insights

### Do not store:

- Information easily derived from code or tools
- Content already in docs or AGENTS.md
- Task-specific transient details

### Rules:

- Prefer updating existing memories over creating duplicates
- Use structured topic naming (e.g., `area/topic`)
- Remove outdated entries
- If memory conflicts with code or docs, treat code/docs as source of truth
