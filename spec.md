# Claude Loop - Technical Specification

## Overview

Claude Loop is an automation toolkit for running iterative Claude Code sessions with cost tracking, token monitoring, and inline visualization. It enables automated analysis and implementation workflows that can run unattended until specified limits are reached.

### v2.0 Key Design Decisions

**Architecture Decisions (finalized):**
1. **Session Management**: Use streaming input mode with session persistence via `/clear` between iterations (single long-lived process)
2. **Interactive Mode**: Unified mode with `onHumanInput` callback (no separate interactive mode)
3. **UI Framework**: Ink (React-based terminal UI) for rich visualization
4. **Error Handling**: Auto-retry with exponential backoff on rate limits and network errors
5. **Cost Tracking**: Trust SDK's built-in pricing (no custom pricing table)
6. **Configuration**: JSON format (`.claude-loop.json`)
7. **Prompts**: Static (read once per iteration, no dynamic modification)
8. **Workflow**: Single prompt only, stateless between iterations
9. **State Management**: Stateless - agents write outputs to files (markdown, code)
10. **Testing**: Full spec implementation with basic feedback loop tests

## Purpose

Enable long-running, autonomous Claude Code sessions for:
- **Codebase Analysis**: Deep, multi-perspective analysis of complex codebases
- **Implementation Automation**: Automated feature development from specifications
- **Research Tasks**: Extended research sessions with multiple iterations
- **Cost-Controlled Exploration**: Exploratory coding within defined budget constraints

**Session Management Strategy (v2.0):**
Use streaming input mode (--input-stream-mode) with session persistence via /clear between iterations.

**Rationale:**
- Faster iteration times (no process spawning overhead)
- Maintains agent context and state management
- Full SDK feature support (interruptions, permissions, hooks)
- Single message mode lacks: image attachments, message queueing, interruptions, hooks, multi-turn conversations

**Implementation:**
- Single long-lived agent process
- Issue /clear command between iterations to reset context
- Stateless design: agents write outputs to files (md, code)
- Use TypeScript SDK (@anthropic-ai/claude-code)

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
┌──────────────────────────────────────────────────┐
│  claude-loop (npm package)                       │
│                                                  │
│  ┌────────────────────────────────────────┐     │
│  │  @anthropic-ai/claude-code SDK         │     │
│  │  (streaming input mode)                │     │
│  │  - Long-lived agent session            │     │
│  │  - /clear between iterations           │     │
│  └────────────┬───────────────────────────┘     │
│               │                                  │
│  ┌────────────v───────────────────────────┐     │
│  │  Unified Event Handler                 │     │
│  │  - onUser (supports human input)       │     │
│  │  - onAssistant                         │     │
│  │  - onToolUse                           │     │
│  │  - onToolResult                        │     │
│  │  - onResult                            │     │
│  │  - onHumanInput (interactive callback) │     │
│  └────────────┬───────────────────────────┘     │
│               │                                  │
│  ┌────────────v───────────────────────────┐     │
│  │  Ink UI Framework                      │     │
│  │  - React-based terminal UI             │     │
│  │  - Real-time updates                   │     │
│  │  - Spinners, progress bars             │     │
│  │  - Cost/token display                  │     │
│  │  - Error visualization                 │     │
│  └──────────────────────────────────────────┘     │
│                                                  │
│  ┌────────────────────────────────────────┐     │
│  │  Cost & Token Tracker                  │     │
│  │  - SDK built-in pricing (trusted)      │     │
│  │  - Per-model tracking                  │     │
│  │  - Real-time accumulation              │     │
│  └────────────────────────────────────────┘     │
│                                                  │
│  ┌────────────────────────────────────────┐     │
│  │  Retry & Error Handler                 │     │
│  │  - Exponential backoff                 │     │
│  │  - Rate limit detection                │     │
│  │  - Network error recovery              │     │
│  │  - Detailed error logging              │     │
│  └────────────────────────────────────────┘     │
│                                                  │
│  ┌────────────────────────────────────────┐     │
│  │  Limit Manager                         │     │
│  │  - Cost threshold                      │     │
│  │  - Token limits                        │     │
│  │  - Time limits                         │     │
│  │  - Iteration limits                    │     │
│  └────────────────────────────────────────┘     │
└──────────────────────────────────────────────────┘
```

**Key Design Decisions:**
- **Session Persistence**: Single agent process with /clear between iterations
- **Interactive Mode**: Unified mode with `onHumanInput` callback (no separate mode)
- **UI Framework**: Ink (React-based terminal UI) for rich visualization
- **Error Handling**: Auto-retry with exponential backoff on rate limits/network errors
- **Cost Tracking**: Trust SDK's built-in pricing
- **Configuration**: JSON format (`.claude-loop.json`)
- **Prompts**: Static (read once per iteration)
- **Workflow**: Single prompt only, stateless between iterations
- **Testing**: Full spec implementation + basic tests for feedback

**Advantages:**
- Single long-lived process (minimal overhead)
- Native SDK integration with full feature support
- Type-safe (TypeScript)
- Direct event handling
- Automatic retry logic for resilience
- Rich terminal UI with Ink
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

**Future (Ink UI):**
- React-based terminal UI components
- Real-time updates with state management
- Custom spinner animations
- Progress bars for long operations
- Live cost/token dashboard
- Error visualization with stack traces
- Interactive elements (when onHumanInput provided)
- Responsive layouts
- Cleaner, more integrated output

### Limit Controls

Multiple configurable limits:
1. **Cost Limit**: Max USD spend (default: $100)
2. **Time Limit**: Max duration in hours (default: 12h)
3. **Iteration Limit**: Max iterations (default: 1000)
4. **Token Limit**: Max output tokens (default: 0 = unlimited)

Loop stops when **any** limit is reached.

### Configuration

**CLI Arguments (v1.0 - current):**
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
  --interactive            Interactive mode (human-in-loop)
  -h, --help               Show this help message
```

**CLI Arguments (v2.0 - future):**
```bash
claude-loop -f PROMPT_FILE [OPTIONS]

Required:
  -f, --prompt-file FILE   Path to prompt file

Optional:
  -i, --iterations NUM     Max iterations (default: 1000)
  -t, --tokens NUM         Max output tokens (default: 0 = unlimited)
  -d, --duration HOURS     Max duration in hours (default: 12)
  -c, --max-cost USD       Max cost in USD (default: 100.0)
  -p, --pause SECONDS      Pause between iterations (default: 0)
  --config FILE            Path to config file (default: .claude-loop.json)
  --no-ui                  Disable Ink UI (plain text output)
  -h, --help               Show this help message
```

**Configuration File (v2.0 - JSON format):**
```json
{
  "defaults": {
    "maxCost": 100.0,
    "maxHours": 12,
    "maxIterations": 1000,
    "maxTokens": 0,
    "pauseSeconds": 0,
    "visualize": true,
    "logFile": "claude_loop.log"
  },
  "profiles": {
    "analysis": {
      "maxCost": 50.0,
      "maxHours": 4
    },
    "implementation": {
      "maxCost": 100.0,
      "maxHours": 12
    },
    "quick": {
      "maxCost": 5.0,
      "maxHours": 1,
      "maxIterations": 10
    }
  }
}
```

**Programmatic API (v2.0):**
```typescript
import { ClaudeLoop } from 'claude-loop';

// Simple usage
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

// With callbacks for interactive mode
const loopInteractive = new ClaudeLoop({
  maxCost: 50.0,
  onHumanInput: async (prompt) => {
    // Custom logic to get human input
    return await getUserInput(prompt);
  },
  onIteration: (stats) => {
    console.log(`Iteration ${stats.iteration}: $${stats.cost}`);
  }
});

await loopInteractive.run('spec.md');
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
  visualize?: boolean;        // default: true (Ink UI)
  logFile?: string;           // default: 'claude_loop.log'
  configFile?: string;        // default: '.claude-loop.json'

  // Callbacks
  onIteration?: (stats: IterationStats) => void;
  onCostUpdate?: (cost: CostStats) => void;
  onLimit?: (limit: LimitType, value: number) => void;
  onHumanInput?: (prompt: string) => Promise<string>; // For interactive mode
  onError?: (error: LoopError, retry: RetryInfo) => void;
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

interface LoopError extends Error {
  type: 'rate_limit' | 'network' | 'api_error' | 'unknown';
  retryable: boolean;
  originalError?: Error;
}

interface RetryInfo {
  attempt: number;
  maxAttempts: number;
  backoffMs: number;
  nextRetryAt: Date;
}

class ClaudeLoop {
  constructor(options?: ClaudeLoopOptions);

  // Main execution methods
  async run(promptFile: string): Promise<LoopResult>;
  async runWithPrompt(prompt: string): Promise<LoopResult>;

  // Control methods
  stop(): void;
  pause(): void;
  resume(): void;
  getStats(): LoopStats;

  // Session management (internal)
  private async clearSession(): Promise<void>;
  private async handleRetry(error: LoopError): Promise<boolean>;
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

// Advanced usage with callbacks and error handling
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
  },
  onError: (error, retry) => {
    console.log(`Error: ${error.message}`);
    if (retry.attempt < retry.maxAttempts) {
      console.log(`Retrying in ${retry.backoffMs}ms (attempt ${retry.attempt}/${retry.maxAttempts})`);
    }
  }
});

await loop.run('implementation_prompt.md');

// Interactive mode with human input
const interactiveLoop = new ClaudeLoop({
  maxCost: 50,
  onHumanInput: async (prompt) => {
    // Custom human input handler
    const readline = require('readline').createInterface({
      input: process.stdin,
      output: process.stdout
    });
    return new Promise((resolve) => {
      readline.question(prompt, (answer) => {
        readline.close();
        resolve(answer);
      });
    });
  }
});

await interactiveLoop.run('spec_prompt.md');
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

#### 2.2 Ink UI Visualization
- [ ] Install Ink and dependencies (ink, react)
- [ ] Create main UI component (App)
- [ ] Event stream visualizer component
- [ ] Progress spinner component
- [ ] Cost/token dashboard component
- [ ] Error visualization component
- [ ] Interactive input component (for onHumanInput)
- [ ] Status bar component
- [ ] Real-time updates with React state

#### 2.3 Cost & Token Tracking
- [ ] Extract cost data from SDK responses
- [ ] Trust SDK built-in pricing (no custom pricing table)
- [ ] Per-model accumulation
- [ ] Real-time cost updates
- [ ] Limit threshold checking
- [ ] Cost callbacks (onCostUpdate)

#### 2.4 Retry & Error Handling
- [ ] Detect error types (rate_limit, network, api_error)
- [ ] Exponential backoff algorithm
- [ ] Rate limit detection and handling
- [ ] Network error recovery
- [ ] Max retry attempts configuration
- [ ] Error callbacks (onError)
- [ ] Detailed error logging

#### 2.5 CLI Interface
- [ ] Argument parsing (commander)
- [ ] Help text and examples
- [ ] Config file loading (JSON)
- [ ] Profile support
- [ ] Validation
- [ ] Binary setup (package.json bin field)

#### 2.6 Programmatic API
- [ ] TypeScript types and interfaces
- [ ] ClaudeLoopOptions interface
- [ ] Callback system (onIteration, onCostUpdate, onLimit, onHumanInput, onError)
- [ ] Control methods (pause, resume, stop)
- [ ] Session management (/clear between iterations)
- [ ] Stateless iteration design

#### 2.7 Testing & Documentation
- [ ] Unit tests (cost tracking, limits, retry logic)
- [ ] Integration tests (end-to-end loop execution)
- [ ] Basic feedback loop tests
- [ ] API documentation (types, interfaces)
- [ ] Usage examples (simple, advanced, interactive)
- [ ] README update for v2.0
- [ ] Migration guide from v1.0

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
    "ink": "^4.4.1",
    "react": "^18.2.0",
    "commander": "^12.0.0",
    "fs-extra": "^11.2.0"
  },
  "devDependencies": {
    "@types/node": "^20.0.0",
    "@types/react": "^18.2.0",
    "typescript": "^5.0.0",
    "vitest": "^1.0.0",
    "tsx": "^4.7.0"
  }
}
```

**Key Dependencies:**
- `@anthropic-ai/claude-code` - Official Claude SDK
- `ink` - React-based terminal UI framework
- `react` - Required by Ink for component rendering
- `commander` - CLI argument parsing
- `fs-extra` - Enhanced file system operations
- `typescript` - Type safety and compilation
- `vitest` - Fast unit testing
- `tsx` - TypeScript execution for development

## Performance Considerations

### Current Implementation
- Subprocess overhead: ~100-200ms per iteration
- JSON parsing overhead: ~10-50ms per iteration
- Memory: Stable (~50MB)

### Future Implementation (v2.0)
- No subprocess overhead (single long-lived process)
- Session persistence with /clear (faster than respawning)
- Native object access from SDK (no JSON parsing)
- Ink UI rendering overhead: ~5-10ms per update
- Memory: ~100-200MB (Node.js + SDK + Ink + React)
- Estimated 20-30% performance improvement over v1.0
- Retry logic may add latency during failures (acceptable trade-off)

## Security Considerations

1. **API Keys**: Uses Claude credentials from environment/config
2. **Dangerous Skip**: Uses `--dangerously-skip-permissions` flag
3. **Cost Controls**: Prevents runaway costs
4. **File Access**: Limited to specified prompt files
5. **Logging**: Sanitize sensitive data in logs

## Error Handling

### Current (v1.0)
- Basic error detection
- JSON parse failures logged
- Loop exits on critical errors
- No retry logic

### Future (v2.0)
**Retry Strategy with Exponential Backoff:**
- Detect error types: `rate_limit`, `network`, `api_error`, `unknown`
- Retryable errors: rate limits, network failures
- Non-retryable errors: authentication, invalid requests
- Exponential backoff: 1s, 2s, 4s, 8s, 16s (configurable)
- Max retry attempts: 5 (configurable)
- `onError` callback for custom handling

**Implementation:**
```typescript
async function handleRetry(error: LoopError, attempt: number): Promise<boolean> {
  if (!error.retryable || attempt >= MAX_RETRIES) {
    return false;
  }

  const backoffMs = Math.min(1000 * Math.pow(2, attempt), 32000);
  const nextRetryAt = new Date(Date.now() + backoffMs);

  if (options.onError) {
    options.onError(error, {
      attempt: attempt + 1,
      maxAttempts: MAX_RETRIES,
      backoffMs,
      nextRetryAt
    });
  }

  await sleep(backoffMs);
  return true;
}
```

**Error Recovery:**
- Rate limit errors: Wait and retry with backoff
- Network errors: Retry with exponential backoff
- API errors: Log details, may retry depending on type
- Session errors: Attempt to restart session
- All errors: Detailed logging with stack traces

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

### v2.0 Configuration Format (JSON)
```json
{
  "defaults": {
    "maxCost": 100.0,
    "maxHours": 12,
    "maxIterations": 1000,
    "maxTokens": 0,
    "pauseSeconds": 0,
    "visualize": true,
    "logFile": "claude_loop.log",
    "retry": {
      "maxAttempts": 5,
      "initialBackoffMs": 1000,
      "maxBackoffMs": 32000
    }
  },
  "profiles": {
    "analysis": {
      "maxCost": 50.0,
      "maxHours": 4
    },
    "implementation": {
      "maxCost": 100.0,
      "maxHours": 12
    },
    "quick": {
      "maxCost": 5.0,
      "maxHours": 1,
      "maxIterations": 10
    }
  }
}
```

**File Location:** `.claude-loop.json` in project root or `~/.config/claude-loop/config.json`

**Usage:**
```bash
# Use default profile
claude-loop -f prompt.md

# Use specific profile
claude-loop -f prompt.md --profile analysis

# Use custom config file
claude-loop -f prompt.md --config ./my-config.json
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
