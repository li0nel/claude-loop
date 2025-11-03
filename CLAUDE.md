# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Claude Loop is an automation toolkit for running iterative Claude Code sessions with cost tracking and token monitoring. It enables autonomous, long-running workflows for codebase analysis, feature implementation, and research tasks.

The project currently exists in two versions:
- **v1.0 (Current)**: Bash-based implementation (`claude_loop.sh`)
- **v2.0 (Planned)**: Node.js/TypeScript npm package (see `spec.md`)

## Running the Loop

The core script is `claude_loop.sh` which runs Claude Code in iterative loops with cost and limit controls.

### Basic Usage

```bash
./claude_loop.sh -f PROMPT_FILE [OPTIONS]
```

### Required Arguments
- `-f, --prompt-file FILE` - Path to the prompt markdown file

### Optional Arguments
- `-i, --iterations NUM` - Max iterations (default: 1000)
- `-t, --tokens NUM` - Max output tokens (default: 0 = unlimited)
- `-d, --duration HOURS` - Max duration in hours (default: 12)
- `-c, --max-cost USD` - Max cost in USD (default: 100.0)
- `-p, --pause SECONDS` - Pause between iterations (default: 0)
- `--interactive` - Interactive mode for spec refinement (requires human input each iteration)

### Examples

```bash
# Automated analysis with cost limit
./claude_loop.sh -f prompts/analyze.md -c 20.0 -d 4

# Interactive spec refinement
./claude_loop.sh -f prompts/spec.md --interactive -i 10

# Planning workflow
./claude_loop.sh -f prompts/plan.md -c 50.0 -d 12

# Feature implementation
./claude_loop.sh -f prompts/implement.md -c 100.0 -d 12
```

## Architecture

### Loop Flow

1. Read prompt from markdown file
2. Pipe to `claude --dangerously-skip-permissions -p --output-format stream-json --verbose`
3. Stream output to `npx repomirror visualize` for inline display
4. Parse final result JSON for costs and token usage
5. Display per-model breakdown
6. Accumulate total cost
7. Check limits (cost, tokens, time, iterations)
8. Continue or exit based on limits

### Modes

**Automated Mode** (default):
- Runs until limits reached
- Tracks costs and tokens
- Uses stream-json output format
- Visualizes with repomirror

**Interactive Mode** (`--interactive`):
- Prompts user after each iteration
- Allows prompt file editing between iterations
- No cost tracking (uses standard output)
- Designed for spec refinement workflows

## Included Prompts

Located in `prompts/`:

### `analyze.md`
Deep codebase analysis workflow:
- Uses `/research_codebase` command
- Proposes 8-12 analytical perspectives
- Saves to `@ANALYSIS_PLAN.md`
- Picks highest priority item
- Uses up to 50 subagents for research
- Saves findings to `@analysis/index.md` and `@analysis/assets/`
- Auto-commits progress

### `implement.md`
Automated feature implementation:
- Reads `@spec.md` for requirements
- Uses `/research_codebase` for context
- Picks highest priority from `@IMPLEMENTATION_PLAN.md`
- Uses up to 50 subagents
- Runs tests and checks
- Updates plan and commits changes
- Syncs plan with spec if discrepancies found

### `plan.md`
Planning workflow:
- Reads `@SPEC.md` and `@analysis/index.md`
- Ultrathinks about implementation approach
- Updates `@IMPLEMENTATION_PLAN.md` with up to 20 phases
- Each phase scoped for easy review
- Commits plan updates

### `spec.md`
Interactive spec refinement (use with `--interactive`):
- Reads `@SPEC.md`
- Uses `/research_codebase` for context
- Generates 5-10 highest priority clarifying questions
- Updates spec based on human feedback
- Commits changes and quits after each iteration

## Custom Claude Commands

### `/research_codebase`

Comprehensive codebase research command (see `.claude/commands/research_codebase.md`).

**Key principles:**
- Documents what EXISTS, not what SHOULD BE
- No recommendations or improvements unless explicitly asked
- Uses parallel sub-agents for efficient exploration
- Saves findings to `thoughts/shared/research/YYYY-MM-DD-[ENG-XXXX-]description.md`

**Specialized sub-agents:**
- `codebase-locator` - Find WHERE components live
- `codebase-analyzer` - Understand HOW code works
- `codebase-pattern-finder` - Find existing patterns
- `thoughts-locator` - Discover documentation
- `thoughts-analyzer` - Extract insights from docs
- `web-search-researcher` - External documentation (if requested)

**Workflow:**
1. Read mentioned files fully (no limit/offset)
2. Decompose research question
3. Spawn parallel sub-agents
4. Wait for all agents to complete
5. Synthesize findings
6. Gather metadata via `hack/spec_metadata.sh`
7. Generate research document with YAML frontmatter
8. Add GitHub permalinks if on main branch
9. Run `humanlayer thoughts sync`

## Custom Sub-Agents

Located in `.claude/agents/`:

- `codebase-analyzer.md` - Analyzes implementation details
- `codebase-locator.md` - Locates files and components
- `codebase-pattern-finder.md` - Finds similar patterns
- `thoughts-analyzer.md` - Analyzes documentation
- `thoughts-locator.md` - Discovers relevant documents
- `web-search-researcher.md` - Web research

## Dependencies

### Runtime
- `bash` - Shell script execution
- `jq` - JSON parsing
- `bc` - Floating-point arithmetic
- `claude` - Claude CLI (with `--dangerously-skip-permissions` support)
- `npx` - For running repomirror
- `repomirror` - Visualization of stream-json output
- `git` - Version control for auto-commits

### Optional
- `humanlayer` - Thoughts directory sync (used by `/research_codebase`)
- `gh` - GitHub CLI (used by some prompts for repo info)

## Cost Tracking

The loop tracks and displays:
- Per-model token counts (input, output, cache read, cache creation)
- Per-model cost breakdown
- Iteration cost
- Cumulative total cost vs. max cost
- Progress toward limits

Example output:
```
=== Model Usage ===
  claude-sonnet-4-5@20250929:
    Input: 8 tokens
    Output: 122 tokens
    Cache Read: 16107 tokens
    Cache Creation: 16223 tokens
    Cost: $0.06752235

Iteration cost: $0.06752235
Total cost: $0.13504470 / $100.00
```

## Limit Controls

The loop stops when ANY limit is reached:
1. **Cost limit** - Max USD spend
2. **Time limit** - Max duration in hours
3. **Iteration limit** - Max number of iterations
4. **Token limit** - Max output tokens (0 = unlimited)

## Logging

All output is logged to `claude_loop.log` including:
- Start/end timestamps
- Configuration settings
- Per-iteration stats
- Model usage breakdowns
- Total statistics

## File Organization

```
.
├── claude_loop.sh           # Main loop script
├── spec.md                  # Technical specification for v2.0
├── README.md                # Project overview and usage
├── claude_loop.log          # Runtime logs
├── prompts/                 # Loop prompt files
│   ├── analyze.md          # Analysis workflow
│   ├── implement.md        # Implementation workflow
│   ├── plan.md             # Planning workflow
│   └── spec.md             # Spec refinement workflow
└── .claude/                 # Claude Code configuration
    ├── agents/             # Custom sub-agents
    ├── commands/           # Custom slash commands
    └── settings.local.json # Local settings
```

## Workflow Patterns

### Analysis Pattern
1. Create/read `@ANALYSIS_PLAN.md` with 8-12 perspectives
2. For each perspective (highest priority first):
   - Use `/research_codebase` with up to 50 subagents
   - Save to `@analysis/index.md` and `@analysis/assets/`
   - Commit progress
3. Loop continues until limits reached

### Implementation Pattern
1. Read `@spec.md` for requirements
2. Read `@IMPLEMENTATION_PLAN.md` for tasks
3. Pick highest priority item
4. Implement using subagents
5. Run tests and checks
6. Update plan and commit
7. Loop continues for next item

### Planning Pattern
1. Read `@SPEC.md` and `@analysis/index.md`
2. Ultrathink about implementation
3. Create/update `@IMPLEMENTATION_PLAN.md` (up to 20 phases)
4. Commit and quit
5. Loop runs again to refine plan

### Spec Refinement Pattern (Interactive)
1. Read `@SPEC.md`
2. Research codebase for context
3. Generate 5-10 clarifying questions
4. Present to human
5. Update spec based on feedback
6. Commit and quit
7. Loop prompts human to continue/edit/quit

## Important Notes

- The bash script uses `--dangerously-skip-permissions` for unattended operation
- All prompts are designed to auto-commit progress with clear messages
- Prompts reference files with `@` prefix (e.g., `@spec.md`, `@IMPLEMENTATION_PLAN.md`)
- The `/research_codebase` command is central to understanding the codebase
- Sub-agents are documentarians - they describe what exists, not what should be
- Interactive mode disables cost tracking but allows human intervention
- See `spec.md` for the planned v2.0 Node.js/TypeScript implementation
