# Claude Loop

Automation toolkit for running iterative Claude Code sessions with cost tracking and token monitoring.

## Quick Start

```bash
# Prerequisites: Claude CLI, jq, bc, npx
brew install jq  # macOS
# apt-get install jq bc  # Linux

# Download and run
curl -O https://raw.githubusercontent.com/li0nel/claude-loop/main/claude_loop.sh
chmod +x claude_loop.sh
./claude_loop.sh -f prompts/analyze.md -c 50.0 -d 4
```

## Usage

```bash
./claude_loop.sh -f PROMPT_FILE [OPTIONS]

Required:
  -f, --prompt-file FILE   Path to prompt file

Optional:
  -i, --iterations NUM     Max iterations (default: 1000)
  -t, --tokens NUM         Max output tokens (default: unlimited)
  -d, --duration HOURS     Max duration in hours (default: 12)
  -c, --max-cost USD       Max cost in USD (default: 100.0)
  -p, --pause SECONDS      Pause between iterations (default: 0)
  --interactive            Interactive mode for spec refinement
```

## Examples

**Automated analysis:**
```bash
./claude_loop.sh -f prompts/analyze.md -c 50.0 -d 4
```

**Feature implementation:**
```bash
./claude_loop.sh -f prompts/implement.md -c 100.0 -d 12
```

**Interactive spec refinement:**
```bash
./claude_loop.sh -f prompts/spec.md --interactive
```

## Features

- **Cost Tracking**: Per-model breakdown with real-time accumulation
- **Token Monitoring**: Input/output tokens plus cache usage
- **Visualization**: Inline progress via `repomirror visualize`
- **Multiple Limits**: Stops when any limit reached (cost, time, iterations, tokens)
- **Interactive Mode**: Human-in-the-loop for spec refinement workflows

### Example Output

```
=== Model Usage ===
  claude-sonnet-4-5@20250929:
    Input: 8 tokens
    Output: 122 tokens
    Cache Read: 16107 tokens
    Cost: $0.067

Total cost: $0.14 / $100.00
```

## Included Prompts

Located in `prompts/`:

- **`analyze.md`**: Deep codebase analysis with multiple perspectives
- **`implement.md`**: Automated feature implementation from specs
- **`plan.md`**: Planning workflow for complex tasks
- **`spec.md`**: Interactive specification refinement

## How It Works

1. Reads prompt from markdown file
2. Pipes to Claude CLI with `--output-format stream-json`
3. Visualizes output via `repomirror`
4. Parses JSON for costs and tokens
5. Checks limits (cost, tokens, time, iterations)
6. Continues or exits based on limits

See [`specs/npm-migration.md`](specs/npm-migration.md) for NPM package migration specification.

## Writing Effective Prompts

Good loop prompts should:
1. Have clear objectives
2. Specify output locations
3. Include progress tracking
4. Auto-commit changes
5. Be idempotent (safe to re-run)

```markdown
# Task: [Description]

## Objectives
1. [Primary objective]

## Process
1. Read [input files]
2. Perform [work]
3. Save to [output location]
4. Commit changes

## Success Criteria
- [ ] Criterion 1
```

## Troubleshooting

**Script won't start:**
```bash
which claude jq bc npx  # Check dependencies
chmod +x claude_loop.sh  # Fix permissions
```

**Cost not tracking:**
- Verify `jq` is installed: `echo '{"test": 1}' | jq .`

**Visualization not working:**
```bash
npx repomirror visualize  # Test installation
```

Check `claude_loop.log` for detailed error messages.

## Resources

- [Claude Code Documentation](https://docs.claude.com/en/docs/claude-code)
- [NPM Migration Spec](specs/npm-migration.md)
- [Claude SDK](https://www.npmjs.com/package/@anthropic-ai/claude-code)

## License

MIT
