# Claude Loop - Technical Specification

## Overview

Claude Loop is an automation toolkit for running iterative Claude Code sessions with cost tracking, token monitoring, and inline visualization. It enables automated analysis and implementation workflows that can run unattended until specified limits are reached.

## Purpose

Enable long-running, autonomous Claude Code sessions for:
- **Codebase Analysis**: Deep, multi-perspective analysis of complex codebases
- **Implementation Automation**: Automated feature development from specifications
- **Research Tasks**: Extended research sessions with multiple iterations
- **Cost-Controlled Exploration**: Exploratory coding within defined budget constraints

## Architecture

### Current Implementation (v1.0 - Bash)

```
┌─────────────────┐
│  Prompt File    │
│  (markdown)     │
└────────┬────────┘
         │
         v
┌─────────────────┐      ┌──────────────────┐
│  claude_loop.sh │─────>│  Claude CLI      │
│                 │      │  --output-format │
│  - Cost tracking│      │  stream-json     │
│  - Token limits │      └────────┬─────────┘
│  - Time limits  │               │
│  - Iterations   │               v
└────────┬────────┘      ┌──────────────────┐
         │               │  repomirror      │
         │               │  visualize       │
         │               │                  │
         v               │  - Colored output│
┌─────────────────┐      │  - Event display │
│  Result JSON    │      └──────────────────┘
│  Parser         │
│                 │
│  - Extract costs│
│  - Per-model    │
│  - Accumulate   │
└─────────────────┘
```

**Flow:**
1. Read prompt from markdown file
2. Pipe to `claude --dangerously-skip-permissions -p --output-format stream-json --verbose`
3. Stream output to `npx repomirror visualize` for display
4. Parse final result JSON for costs and token usage
5. Display per-model breakdown
6. Accumulate total cost
7. Check limits (cost, tokens, time, iterations)
8. Continue or exit

**Limitations:**
- Subprocess overhead (spawning processes)
- JSON parsing complexity
- Fragile text processing
- Limited error handling
- Platform-dependent (bash)

### Future Implementation (v2.0 - Node.js/TypeScript)

```
┌─────────────────┐
│  Prompt File    │
│  (markdown)     │
└────────┬────────┘
         │
         v
┌──────────────────────────────────────────┐
│  claude-loop (npm package)               │
│                                          │
│  ┌────────────────────────────────┐     │
│  │  @anthropic-ai/claude-code SDK │     │
│  └────────────┬───────────────────┘     │
│               │                          │
│  ┌────────────v───────────────────┐     │
│  │  Event Stream Handler          │     │
│  │  - onUser                      │     │
│  │  - onAssistant                 │     │
│  │  - onToolUse                   │     │
│  │  - onToolResult                │     │
│  │  - onResult                    │     │
│  └────────────┬───────────────────┘     │
│               │                          │
│  ┌────────────v───────────────────┐     │
│  │  Inline Visualizer             │     │
│  │  - chalk (colors)              │     │
│  │  - ora (spinners)              │     │
│  │  - direct rendering            │     │
│  └────────────────────────────────┘     │
│                                          │
│  ┌────────────────────────────────┐     │
│  │  Cost & Token Tracker          │     │
│  │  - Native data access          │     │
│  │  - Per-model tracking          │     │
│  │  - Real-time accumulation      │     │
│  └────────────────────────────────┘     │
│                                          │
│  ┌────────────────────────────────┐     │
│  │  Limit Manager                 │     │
│  │  - Cost threshold              │     │
│  │  - Token limits                │     │
│  │  - Time limits                 │     │
│  │  - Iteration limits            │     │
│  └────────────────────────────────┘     │
└──────────────────────────────────────────┘
```

**Advantages:**
- Single process (no subprocess overhead)
- Native SDK integration
- Type-safe (TypeScript)
- Direct event handling
- Better error handling
- Cross-platform
- Programmatic API
- npm installable

## Features

### Cost Tracking

**Per-Model Breakdown:**
```
=== Model Usage ===
  claude-sonnet-4-5@20250929:
    Input: 8 tokens
    Output: 122 tokens
    Cache Read: 16107 tokens
    Cache Creation: 16223 tokens
    Cost: $0.06752235
  claude-3-5-haiku@20241022:
    Input: 5400 tokens
    Output: 32 tokens
    Cost: $0.004448

Iteration cost: $0.07197035
Total cost: $0.14394070 / $100.00
```

**Features:**
- Per-model token counts (input, output, cache)
- Per-model cost breakdown
- Iteration cost tracking
- Cumulative cost tracking
- Configurable cost threshold

### Token Monitoring

- Per-model input/output tokens
- Cache usage tracking (read + creation)
- Total output token accumulation
- Optional token limit (0 = unlimited)

### Visualization

**Current (via repomirror visualize):**
- Colored event indicators
- Tool usage display
- Debug timestamps (optional)
- Parse error detection

**Future (inline):**
- Custom color schemes
- Spinner animations
- Progress bars
- Real-time cost display
- Cleaner, integrated output

### Limit Controls

Multiple configurable limits:
1. **Cost Limit**: Max USD spend (default: $100)
2. **Time Limit**: Max duration in hours (default: 12h)
3. **Iteration Limit**: Max iterations (default: 1000)
4. **Token Limit**: Max output tokens (default: 0 = unlimited)

Loop stops when **any** limit is reached.

### Configuration

**CLI Arguments:**
```bash
claude_loop.sh -f PROMPT_FILE [OPTIONS]

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

**Future (programmatic):**
```typescript
import { ClaudeLoop } from 'claude-loop';

const loop = new ClaudeLoop({
  maxCost: 100.0,
  maxHours: 12,
  maxIterations: 1000,
  maxTokens: 0, // unlimited
  pauseSeconds: 0,
  visualize: true,
  logFile: 'claude_loop.log'
});

await loop.run('prompt.md');
```

## Use Cases

### 1. Codebase Analysis

**Prompt:** `analysis_prompt.md`

Automated multi-perspective analysis:
- Generates 8-15 analytical angles
- Uses up to 50 research subagents
- Creates structured documentation
- Updates analysis plan
- Auto-commits progress

**Example:**
```bash
./claude_loop.sh -f analysis_prompt.md -c 50.0 -d 4
```

### 2. Implementation Automation

**Prompt:** `implementation_prompt.md`

Automated feature development:
- Reads specs and source code
- Implements from IMPLEMENTATION_PLAN.md
- Runs tests and checks
- Auto-commits working code
- Updates progress tracking

**Example:**
```bash
./claude_loop.sh -f implementation_prompt.md -c 100.0 -d 12
```

### 3. Research Sessions

**Prompt:** Custom research prompts

Extended research with:
- Multi-iteration exploration
- Cost-controlled discovery
- Progress tracking
- Structured output

### 4. Continuous Development

**Prompt:** Development prompts

Unattended development:
- Feature implementation
- Bug fixing
- Refactoring
- Documentation

## API Design (v2.0)

### Core API

```typescript
interface ClaudeLoopOptions {
  maxCost?: number;           // USD, default: 100
  maxHours?: number;          // hours, default: 12
  maxIterations?: number;     // default: 1000
  maxTokens?: number;         // 0 = unlimited, default: 0
  pauseSeconds?: number;      // default: 0
  visualize?: boolean;        // default: true
  logFile?: string;           // default: 'claude_loop.log'
  onIteration?: (stats: IterationStats) => void;
  onCostUpdate?: (cost: CostStats) => void;
  onLimit?: (limit: LimitType, value: number) => void;
}

interface IterationStats {
  iteration: number;
  durationMs: number;
  outputTokens: number;
  cost: number;
  modelUsage: ModelUsage[];
}

interface CostStats {
  iterationCost: number;
  totalCost: number;
  maxCost: number;
  percentage: number;
  modelBreakdown: ModelCost[];
}

interface ModelUsage {
  model: string;
  inputTokens: number;
  outputTokens: number;
  cacheReadTokens: number;
  cacheCreationTokens: number;
  cost: number;
}

class ClaudeLoop {
  constructor(options?: ClaudeLoopOptions);

  async run(promptFile: string): Promise<LoopResult>;
  async runInteractive(promptFile: string): Promise<LoopResult>;
  async runWithPrompt(prompt: string): Promise<LoopResult>;

  stop(): void;
  pause(): void;
  resume(): void;
  getStats(): LoopStats;
}
```

### CLI API

```typescript
// As global CLI tool
npm install -g claude-loop
claude-loop -f prompt.md -c 100 -d 12

// As npx
npx claude-loop -f prompt.md -c 100 -d 12
```

### Programmatic API

```typescript
import { ClaudeLoop } from 'claude-loop';

// Simple usage
const loop = new ClaudeLoop({ maxCost: 50 });
const result = await loop.run('analysis_prompt.md');

console.log(`Completed ${result.iterations} iterations`);
console.log(`Total cost: $${result.totalCost}`);

// Advanced usage with callbacks
const loop = new ClaudeLoop({
  maxCost: 100,
  visualize: true,
  onIteration: (stats) => {
    console.log(`Iteration ${stats.iteration}: $${stats.cost}`);
  },
  onCostUpdate: (cost) => {
    console.log(`Cost: $${cost.totalCost} / $${cost.maxCost}`);
  },
  onLimit: (limit, value) => {
    console.log(`Limit reached: ${limit} = ${value}`);
  }
});

await loop.run('implementation_prompt.md');
```

## Implementation Phases

### Phase 1: Bash Script (Current - v1.0) ✅

- [x] Basic loop structure
- [x] Claude CLI integration
- [x] JSON parsing
- [x] Cost tracking
- [x] Token tracking
- [x] Per-model breakdown
- [x] Multiple limits
- [x] Visualization via repomirror
- [x] Logging

### Phase 2: Node.js Package (Future - v2.0)

#### 2.1 Core SDK Integration
- [ ] Initialize npm package
- [ ] Install @anthropic-ai/claude-code
- [ ] Create ClaudeLoop class
- [ ] Implement query loop
- [ ] Event stream handling

#### 2.2 Inline Visualization
- [ ] Install chalk, ora
- [ ] Event visualizer
- [ ] Progress indicators
- [ ] Cost display
- [ ] Token display

#### 2.3 Cost & Token Tracking
- [ ] Per-model tracking
- [ ] Accumulation logic
- [ ] Limit checking
- [ ] Callbacks

#### 2.4 CLI Interface
- [ ] Argument parsing
- [ ] Help text
- [ ] Validation
- [ ] Binary setup

#### 2.5 Programmatic API
- [ ] TypeScript types
- [ ] Options interface
- [ ] Callback system
- [ ] Control methods (pause, resume, stop)

#### 2.6 Testing & Documentation
- [ ] Unit tests
- [ ] Integration tests
- [ ] API documentation
- [ ] Usage examples
- [ ] README

### Phase 3: Enhanced Features (Future - v3.0)

- [ ] Multiple prompts in sequence
- [ ] Conditional branching
- [ ] Result aggregation
- [ ] Parallel loops
- [ ] Resume from checkpoint
- [ ] Cloud deployment
- [ ] Web UI
- [ ] Real-time collaboration

## Technical Dependencies

### Current (v1.0 - Bash)
- `bash` - Shell script runtime
- `jq` - JSON parsing
- `bc` - Floating-point arithmetic
- `claude` - Claude CLI
- `npx repomirror` - Visualization
- `git` - Version control

### Future (v2.0 - Node.js)
```json
{
  "dependencies": {
    "@anthropic-ai/claude-code": "^1.0.0",
    "chalk": "^5.3.0",
    "ora": "^8.0.1",
    "commander": "^12.0.0",
    "fs-extra": "^11.2.0"
  },
  "devDependencies": {
    "@types/node": "^20.0.0",
    "typescript": "^5.0.0",
    "vitest": "^1.0.0"
  }
}
```

## Performance Considerations

### Current Implementation
- Subprocess overhead: ~100-200ms per iteration
- JSON parsing overhead: ~10-50ms per iteration
- Memory: Stable (~50MB)

### Future Implementation
- No subprocess overhead
- Native object access (no parsing)
- Memory: ~100-150MB (Node.js + SDK)
- Estimated 10-20% performance improvement

## Security Considerations

1. **API Keys**: Uses Claude credentials from environment/config
2. **Dangerous Skip**: Uses `--dangerously-skip-permissions` flag
3. **Cost Controls**: Prevents runaway costs
4. **File Access**: Limited to specified prompt files
5. **Logging**: Sanitize sensitive data in logs

## Error Handling

### Current
- Basic error detection
- JSON parse failures logged
- Loop exits on critical errors

### Future
- Comprehensive try/catch
- Retry logic for transient failures
- Graceful degradation
- Error callbacks
- Detailed error logging

## Logging

### Log Format
```
======================================
Starting Claude Code loop at Mon Nov  3 05:48:33 UTC 2025
Prompt file: analysis_prompt.md
Max iterations: 1000
Max output tokens: unlimited
Max duration: 12h
Max cost: $100.0
======================================

[2025-11-03 05:48:33] Iteration 1/1000 | Tokens: 0/unlimited

=== Model Usage ===
  claude-sonnet-4-5@20250929:
    Input: 8 tokens
    Output: 122 tokens
    Cache Read: 16107 tokens
    Cache Creation: 16223 tokens
    Cost: $0.06752235

Iteration cost: $0.07197035
Total cost: $0.07197035 / $100.00

===== Iteration 1 completed =====

...

======================================
Loop completed at Mon Nov  3 06:12:15 UTC 2025
Total iterations: 42
Total output tokens: 12450
Total cost: $8.42
Total time: 0h 23m 42s
======================================
```

## Configuration Files

### Future Support
```yaml
# .claude-loop.yml
defaults:
  maxCost: 100.0
  maxHours: 12
  maxIterations: 1000
  maxTokens: 0
  pauseSeconds: 0
  visualize: true
  logFile: claude_loop.log

profiles:
  analysis:
    maxCost: 50.0
    maxHours: 4

  implementation:
    maxCost: 100.0
    maxHours: 12

  quick:
    maxCost: 5.0
    maxHours: 1
    maxIterations: 10
```

Usage:
```bash
claude-loop -f prompt.md --profile analysis
```

## Testing Strategy

### Unit Tests
- Cost calculation logic
- Token accumulation
- Limit checking
- Configuration parsing

### Integration Tests
- End-to-end loop execution
- SDK integration
- Visualization output
- Error handling

### Performance Tests
- Memory usage over time
- Iteration speed
- Large prompt handling

## Documentation

1. **README.md** - Quick start, installation, usage
2. **spec.md** - This document (technical specification)
3. **API.md** - Detailed API reference
4. **EXAMPLES.md** - Usage examples and patterns
5. **PROMPTS.md** - Guide to writing effective loop prompts

## Contributing

### Development Setup
```bash
git clone https://github.com/li0nel/claude-loop
cd claude-loop
npm install
npm run dev
```

### Testing
```bash
npm test
npm run test:integration
npm run test:e2e
```

### Building
```bash
npm run build
npm run package
```

## License

MIT

## Version History

### v1.0.0 (Current - Bash)
- Initial bash implementation
- Cost and token tracking
- Multiple limit controls
- Repomirror visualization integration

### v2.0.0 (Planned - Node.js)
- Node.js/TypeScript rewrite
- Claude SDK integration
- Inline visualization
- Programmatic API
- npm package

### v3.0.0 (Future)
- Advanced features
- Cloud deployment
- Web UI
- Collaboration features
