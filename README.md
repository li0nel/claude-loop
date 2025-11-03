# Claude Loop

Automation toolkit for running iterative Claude Code sessions with cost tracking, token monitoring, and inline visualization.

## Overview

Claude Loop enables long-running, autonomous Claude Code sessions for:
- **Codebase Analysis**: Deep, multi-perspective analysis of complex codebases
- **Implementation Automation**: Automated feature development from specifications
- **Research Tasks**: Extended research sessions with multiple iterations
- **Cost-Controlled Exploration**: Exploratory coding within defined budget constraints

## Quick Start

### Prerequisites

- [Claude CLI](https://docs.claude.com/en/docs/claude-code) installed and configured
- `jq` for JSON parsing: `brew install jq` (macOS) or `apt-get install jq` (Linux)
- `bc` for floating-point arithmetic (usually pre-installed)
- `npx` for repomirror visualization

### Basic Usage

```bash
# Download the script
curl -O https://raw.githubusercontent.com/li0nel/claude-loop/main/claude_loop.sh
chmod +x claude_loop.sh

# Run with a prompt file
./claude_loop.sh -f analysis_prompt.md

# With custom limits
./claude_loop.sh -f implementation_prompt.md -c 50.0 -d 6 -i 100
```

## Files in This Repository

### Core Files

- **`claude_loop.sh`** - Bash script for running iterative Claude sessions
- **`spec.md`** - Comprehensive technical specification
- **`analysis_prompt.md`** - Prompt for automated codebase analysis
- **`implementation_prompt.md`** - Prompt for automated feature implementation

## Usage

### Command-Line Options

```bash
./claude_loop.sh -f PROMPT_FILE [OPTIONS]

Required:
  -f, --prompt-file FILE   Path to prompt file

Optional:
  -i, --iterations NUM     Max iterations (default: 1000)
  -t, --tokens NUM         Max output tokens (default: 0 = unlimited)
  -d, --duration HOURS     Max duration in hours (default: 12)
  -c, --max-cost USD       Max cost in USD (default: 100.0)
  -p, --pause SECONDS      Pause between iterations (default: 0)
  -h, --help               Show this help message
```

### Examples

#### Automated Codebase Analysis

```bash
# Analyze a codebase with $50 budget and 4 hour limit
./claude_loop.sh -f analysis_prompt.md -c 50.0 -d 4

# Quick analysis with 10 iterations max
./claude_loop.sh -f analysis_prompt.md -i 10 -c 10.0
```

The analysis prompt will:
- Generate 8-15 analytical perspectives
- Use up to 50 research subagents
- Create structured documentation in `analysis/`
- Track progress in `ANALYSIS_PLAN.md`
- Auto-commit findings

#### Automated Implementation

```bash
# Implement features with $100 budget over 12 hours
./claude_loop.sh -f implementation_prompt.md -c 100.0 -d 12

# With pause between iterations for review
./claude_loop.sh -f implementation_prompt.md -p 30
```

The implementation prompt will:
- Read specs from `specs/` directory
- Implement from `IMPLEMENTATION_PLAN.md`
- Run tests and checks
- Auto-commit working code
- Update progress tracking

#### Research Sessions

```bash
# Create custom research prompt
cat > research_prompt.md <<EOF
Research the following topic and provide comprehensive findings:
[Your research topic here]

Create a structured report in research/ directory.
EOF

# Run research with cost limit
./claude_loop.sh -f research_prompt.md -c 25.0
```

## Features

### Cost Tracking

Per-model breakdown with real-time cost accumulation:

```
=== Model Usage ===
  claude-sonnet-4-5@20250929:
    Input: 8 tokens
    Output: 122 tokens
    Cache Read: 16107 tokens
    Cache Creation: 16223 tokens
    Cost: $0.06752235

Iteration cost: $0.07197035
Total cost: $0.14394070 / $100.00
```

### Token Monitoring

- Per-model input/output tokens
- Cache usage tracking (read + creation)
- Total output token accumulation
- Optional token limits

### Visualization

- Colored event indicators via `repomirror visualize`
- Real-time progress updates
- Tool usage display
- Debug timestamps (optional)

### Multiple Limits

The loop stops when **any** limit is reached:
1. **Cost Limit**: Max USD spend
2. **Time Limit**: Max duration in hours
3. **Iteration Limit**: Max number of iterations
4. **Token Limit**: Max output tokens (optional)

## How It Works

1. Reads prompt from markdown file
2. Pipes to Claude CLI with `--output-format stream-json --verbose`
3. Streams output to `repomirror visualize` for display
4. Parses result JSON for costs and token usage
5. Displays per-model breakdown
6. Accumulates total cost
7. Checks limits (cost, tokens, time, iterations)
8. Continues or exits based on limits

## Writing Effective Prompts

### Structure

Good loop prompts should:
1. Have clear objectives
2. Specify output locations
3. Include progress tracking
4. Auto-commit changes
5. Be idempotent (safe to re-run)

### Example Template

```markdown
# Task: [Description]

## Objectives
1. [Primary objective]
2. [Secondary objective]

## Process
1. Read [input files]
2. Perform [analysis/implementation]
3. Save results to [output location]
4. Update [progress tracker]
5. Commit changes with meaningful message

## Success Criteria
- [ ] Criterion 1
- [ ] Criterion 2

## Constraints
- Max file size: [limit]
- Focus on: [scope]
```

## Output and Logging

### Console Output

Real-time display of:
- Iteration progress
- Model usage and costs
- Tool executions
- Results

### Log File

Persistent log written to `claude_loop.log`:
- Start/end timestamps
- Configuration settings
- Per-iteration details
- Total statistics

## Cost Optimization Tips

1. **Set realistic limits**: Start with lower cost limits for testing
2. **Use specific prompts**: More specific prompts = fewer iterations
3. **Enable caching**: Claude automatically caches context (shown in cost breakdown)
4. **Monitor progress**: Check logs to see if iterations are productive
5. **Use token limits**: Set `--tokens` limit for output-heavy tasks

## Troubleshooting

### Script won't start

```bash
# Check dependencies
which claude jq bc npx

# Verify prompt file exists
ls -la analysis_prompt.md

# Check permissions
chmod +x claude_loop.sh
```

### Cost not tracking

- Ensure Claude CLI is using `--output-format stream-json --verbose`
- Check that `jq` is installed and working
- Verify JSON parsing: `echo '{"test": 1}' | jq .`

### Visualization not working

```bash
# Test repomirror
echo '{"type":"text","content":"test"}' | npx repomirror visualize

# Install if needed
npm install -g repomirror
```

### Loop exits immediately

- Check that prompt file exists and is readable
- Verify limits aren't already exceeded
- Check `claude_loop.log` for errors

## Future: Node.js Package

A TypeScript/Node.js version is planned (v2.0) with:
- Native Claude SDK integration
- Inline visualization (no external dependencies)
- Programmatic API
- Better error handling
- Cross-platform support

See `spec.md` for detailed technical specification.

## Contributing

This is a personal toolkit repository. For issues or suggestions, please open an issue.

## License

MIT

## Resources

- [Claude Code Documentation](https://docs.claude.com/en/docs/claude-code)
- [Technical Specification](spec.md)
- [Claude Agent SDK](https://www.npmjs.com/package/@anthropic-ai/claude-code)

## Version History

### v1.0.0 (Current)
- Initial bash implementation
- Cost and token tracking with per-model breakdown
- Multiple limit controls (cost, time, iterations, tokens)
- Repomirror visualization integration
- Analysis and implementation prompt templates
