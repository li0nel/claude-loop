#!/bin/bash

# Claude Code loop script
# Usage: ./claude_loop.sh -f prompt.md [-i max_iterations] [-t max_tokens] [-d max_hours] [-c max_cost] [-p pause_seconds] [--interactive]

set -e

# Default configuration
prompt_file=""
max_iterations=1000
max_output_tokens=0
max_hours=12
max_cost=100.0
pause_time=0
log_file="claude_loop.log"
interactive_mode=false

# Parse flags
while [[ $# -gt 0 ]]; do
  case $1 in
    -f|--prompt-file)
      prompt_file="$2"
      shift 2
      ;;
    -i|--iterations)
      max_iterations="$2"
      shift 2
      ;;
    -t|--tokens)
      max_output_tokens="$2"
      shift 2
      ;;
    -d|--duration)
      max_hours="$2"
      shift 2
      ;;
    -c|--max-cost)
      max_cost="$2"
      shift 2
      ;;
    -p|--pause)
      pause_time="$2"
      shift 2
      ;;
    --interactive)
      interactive_mode=true
      shift
      ;;
    -h|--help)
      echo "Usage: $0 -f PROMPT_FILE [OPTIONS]"
      echo ""
      echo "Required:"
      echo "  -f, --prompt-file FILE   Path to prompt file"
      echo ""
      echo "Optional:"
      echo "  -i, --iterations NUM     Max iterations (default: 1000)"
      echo "  -t, --tokens NUM         Max output tokens (default: 0 = unlimited)"
      echo "  -d, --duration HOURS     Max duration in hours (default: 12)"
      echo "  -c, --max-cost USD       Max cost in USD (default: 100.0)"
      echo "  -p, --pause SECONDS      Pause between iterations (default: 0)"
      echo "  --interactive            Interactive mode for refining specs (requires human input each loop)"
      echo "  -h, --help               Show this help message"
      echo ""
      echo "Notes:"
      echo "  - Interactive mode disables cost tracking and uses standard output format"
      echo "  - Interactive mode is designed for spec refinement workflows requiring human feedback"
      exit 0
      ;;
    *)
      echo "Error: Unknown option $1"
      echo "Use -h or --help for usage information"
      exit 1
      ;;
  esac
done

# Validate required parameters
if [[ -z "$prompt_file" ]]; then
  echo "Error: Prompt file is required (-f or --prompt-file)"
  echo "Use -h or --help for usage information"
  exit 1
fi

if [[ ! -f "$prompt_file" ]]; then
  echo "Error: Prompt file '$prompt_file' not found"
  exit 1
fi

# Initialize
max_duration=$((max_hours * 60 * 60))
iterations=0
start_time=$(date +%s)
total_output_tokens=0
total_cost=0.0

echo "======================================" | tee -a "$log_file"
echo "Starting Claude Code loop at $(date)" | tee -a "$log_file"
echo "Prompt file: $prompt_file" | tee -a "$log_file"
if [[ "$interactive_mode" == "true" ]]; then
  echo "Mode: Interactive (requires human input each iteration)" | tee -a "$log_file"
else
  echo "Mode: Automated" | tee -a "$log_file"
fi
echo "Max iterations: $max_iterations" | tee -a "$log_file"
if ((max_output_tokens > 0)); then
  echo "Max output tokens: $max_output_tokens" | tee -a "$log_file"
else
  echo "Max output tokens: unlimited" | tee -a "$log_file"
fi
echo "Max duration: ${max_hours}h" | tee -a "$log_file"
if [[ "$interactive_mode" == "false" ]]; then
  echo "Max cost: \$${max_cost}" | tee -a "$log_file"
else
  echo "Max cost: N/A (interactive mode)" | tee -a "$log_file"
fi
echo "======================================" | tee -a "$log_file"

while :; do
  iterations=$((iterations + 1))
  now=$(date +%s)
  elapsed=$((now - start_time))

  # Check limits
  if ((iterations > max_iterations)); then
    echo "Max iterations reached: $iterations" | tee -a "$log_file"
    break
  fi

  if ((elapsed >= max_duration)); then
    echo "Max duration reached: ${elapsed}s" | tee -a "$log_file"
    break
  fi

  if ((max_output_tokens > 0 && total_output_tokens >= max_output_tokens)); then
    echo "Max output tokens reached: $total_output_tokens" | tee -a "$log_file"
    break
  fi

  # Check cost limit (using bc for floating point comparison) - only in automated mode
  if [[ "$interactive_mode" == "false" ]]; then
    if (( $(echo "$total_cost >= $max_cost" | bc -l) )); then
      echo "Max cost reached: \$$total_cost / \$$max_cost" | tee -a "$log_file"
      break
    fi
  fi

  # Log iteration
  echo "" | tee -a "$log_file"
  if [[ "$interactive_mode" == "true" ]]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Iteration $iterations/$max_iterations" | tee -a "$log_file"
  else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Iteration $iterations/$max_iterations | Tokens: $total_output_tokens/$max_output_tokens" | tee -a "$log_file"
  fi

  # Run Claude Code - different modes for interactive vs automated
  if [[ "$interactive_mode" == "true" ]]; then
    # Interactive mode: standard output, allows human input
    echo "" | tee -a "$log_file"
    echo "Running Claude Code in interactive mode..." | tee -a "$log_file"
    claude --dangerously-skip-permissions "$(cat "$prompt_file")"

    # No cost tracking or visualization in interactive mode
    echo "" | tee -a "$log_file"
    echo "===== Iteration $iterations completed =====" | tee -a "$log_file"

    # Prompt user for next action
    echo ""
    echo "Options:"
    echo "  [Enter] - Continue to next iteration"
    echo "  [q] - Quit the loop"
    echo "  [e] - Edit prompt file and continue"
    read -p "Choose an option: " user_choice

    case "$user_choice" in
      q|Q)
        echo "Exiting loop..." | tee -a "$log_file"
        break
        ;;
      e|E)
        echo "Opening prompt file for editing..." | tee -a "$log_file"
        ${EDITOR:-vi} "$prompt_file"
        echo "Prompt file updated. Continuing to next iteration..." | tee -a "$log_file"
        ;;
      *)
        echo "Continuing to next iteration..." | tee -a "$log_file"
        ;;
    esac
  else
    # Automated mode: stream-json output with cost tracking
    output=$(cat "$prompt_file" | claude --dangerously-skip-permissions -p --output-format stream-json --verbose)

    # Visualize output
    echo "$output" | npx repomirror visualize

    # Extract the result JSON (last line with type="result")
    result_json=$(echo "$output" | grep '"type":"result"' | tail -1)

    if [[ -n "$result_json" ]]; then
      echo "" | tee -a "$log_file"
      echo "=== Model Usage ===" | tee -a "$log_file"

      # Extract iteration cost from total_cost_usd field
      iteration_cost=$(echo "$result_json" | jq -r '.total_cost_usd // 0')

      # Parse and display per-model usage
      models=$(echo "$result_json" | jq -r '.modelUsage | keys[]' 2>/dev/null || echo "")

      for model in $models; do
        input_tokens=$(echo "$result_json" | jq -r ".modelUsage[\"$model\"].inputTokens // 0")
        output_tokens=$(echo "$result_json" | jq -r ".modelUsage[\"$model\"].outputTokens // 0")
        cache_read=$(echo "$result_json" | jq -r ".modelUsage[\"$model\"].cacheReadInputTokens // 0")
        cache_creation=$(echo "$result_json" | jq -r ".modelUsage[\"$model\"].cacheCreationInputTokens // 0")
        model_cost=$(echo "$result_json" | jq -r ".modelUsage[\"$model\"].costUSD // 0")

        echo "  $model:" | tee -a "$log_file"
        echo "    Input: $input_tokens tokens" | tee -a "$log_file"
        echo "    Output: $output_tokens tokens" | tee -a "$log_file"
        if [[ "$cache_read" != "0" ]]; then
          echo "    Cache Read: $cache_read tokens" | tee -a "$log_file"
        fi
        if [[ "$cache_creation" != "0" ]]; then
          echo "    Cache Creation: $cache_creation tokens" | tee -a "$log_file"
        fi
        echo "    Cost: \$$model_cost" | tee -a "$log_file"

        # Add to total output tokens
        total_output_tokens=$((total_output_tokens + output_tokens))
      done

      # Update total cost
      total_cost=$(echo "$total_cost + $iteration_cost" | bc -l)

      echo "" | tee -a "$log_file"
      echo "Iteration cost: \$$iteration_cost" | tee -a "$log_file"
      echo "Total cost: \$$total_cost / \$$max_cost" | tee -a "$log_file"
    fi

    # Pause between iterations
    echo "" | tee -a "$log_file"
    echo "===== Iteration $iterations completed =====" | tee -a "$log_file"
    if ((pause_time > 0)); then
      echo "Press Enter to continue or wait ${pause_time}s..."
      read -t "$pause_time" -r || true
    fi
  fi
done

echo "" | tee -a "$log_file"
echo "======================================" | tee -a "$log_file"
echo "Loop completed at $(date)" | tee -a "$log_file"
echo "Total iterations: $iterations" | tee -a "$log_file"
if [[ "$interactive_mode" == "false" ]]; then
  echo "Total output tokens: $total_output_tokens" | tee -a "$log_file"
  echo "Total cost: \$$total_cost" | tee -a "$log_file"
fi
echo "Total time: $(($elapsed / 3600))h $(($elapsed % 3600 / 60))m $(($elapsed % 60))s" | tee -a "$log_file"
echo "======================================" | tee -a "$log_file"
