# Claude Loop

Automation toolkit for running iterative Claude Code sessions with cost tracking and token monitoring.

## Background

This repository is inspired by Dex Horthy's talk on [advanced context engineering for coding agents](https://www.youtube.com/watch?v=VvkhYWFWaKI). From the very first time I saw this video, the ideas stuck hard.

After that, about a dozen Spec Driven Development workflows were tried. While they all made sense, many felt a bit too opinionated in ways that didn't add much value. Shifting the core of the work to spec definition, however, clearly made sense.

The real game changer became obvious: write specs by day, let the agent rip through implementation at night.

Then I came across Geoffrey Huntley's technique of [running Claude Code in continuous loops](https://lnkd.in/gzd8DH8d), further detailed in [this interview with Dex Horthy](https://github.com/ai-that-works/ai-that-works/tree/main/2025-10-28-ralph-wiggum-coding-agent-power-tools). The promise? A simple prompt asking the model to pick the highest priority item, implement, test, commit, then quit—run in an endless loop with fresh context every time—actually delivers. Similar conclusions were reached by Dex's team at this YC Agents hackathon.

I then applied the same principles to spec writing, but with a human in the loop this time. Starting from a one-line spec, the model would ultrathink and generate a top 10 list of clarifying questions, repeatedly.

The quality of those questions was staggering. It felt like a mid-level dev firing off exactly what would've come days later, compressed into a fast two-hour session.

Experimentation followed to make analysis recursive across many context windows, saving results to support progressive disclosure—much like how Claude Skills are designed. I later found that the idea of also concurrently running analysis from different perspectives wasn't novel ([see here](https://nmn.gl/blog/ai-understand-senior-developer)).

Here you have it: a set of unscrupulous prompts, some slash commands (from [HumanLayer](https://github.com/humanlayer/humanlayer) - still needs cleaning), subagents, and a bash file. It may look ridiculous—but it works surprisingly well.

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
./claude_loop.sh -f prompts/analyze.md -c 20.0 -d 4
```

**Interactive spec refinement:**
```bash
./claude_loop.sh -f prompts/spec.md --interactive -i 10
```

**Plan:**
```bash
./claude_loop.sh -f prompts/plan.md -c 50.0 -d 12
```

**Feature implementation:**
```bash
./claude_loop.sh -f prompts/implement.md -c 100.0 -d 12
```

## Features

- **Cost Tracking**: Per-model breakdown with real-time accumulation
- **Token Monitoring**: Input/output tokens plus cache usage
- **Visualization**: Inline progress via `repomirror visualize`
- **Multiple Limits**: Stops when any limit reached (cost, time, iterations, tokens)
- **Interactive Mode**: Human-in-the-loop for spec refinement workflows

## Included Prompts

Located in `prompts/`:

- **`analyze.md`**: Deep codebase analysis with multiple perspectives
- **`implement.md`**: Automated feature implementation from specs
- **`plan.md`**: Planning workflow for complex tasks
- **`spec.md`**: Interactive specification refinement

## How It Works (for now)

1. Reads prompt from markdown file
2. Pipes to Claude CLI with `--output-format stream-json`
3. Visualizes output via `npx repomirror`
4. Parses JSON for costs and tokens
5. Checks limits (cost, tokens, time, iterations)
6. Continues or exits based on limits

See [`specs/npm-migration.md`](specs/npm-migration.md) for NPM package migration specification.

## License

MIT
