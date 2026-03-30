#!/usr/bin/env python3
"""
Agent Teams Cost Calculator

Estimates token usage and cost for Claude Agent Teams configurations.

Usage:
    python cost-calculator.py --preset review
    python cost-calculator.py --preset debug
    python cost-calculator.py --preset build
    python cost-calculator.py --teammates 3 --tasks-per-teammate 5
    python cost-calculator.py --preset review --model opus --json
    python cost-calculator.py --preset review --compare
"""

import argparse
import json
import sys

# Cost per 1K tokens (USD)
MODEL_COSTS = {
    "opus": {"input": 0.015, "output": 0.075},
    "sonnet": {"input": 0.003, "output": 0.015},
    "haiku": {"input": 0.00025, "output": 0.00125},
}

# Presets: (teammates, tasks_per_teammate)
PRESETS = {
    "review": {"teammates": 3, "tasks_per_teammate": 5, "label": "Parallel Code Review"},
    "debug": {"teammates": 5, "tasks_per_teammate": 5, "label": "Competing Hypotheses Debug"},
    "build": {"teammates": 3, "tasks_per_teammate": 5, "label": "Cross-Layer Feature Build"},
}

# Token assumptions
BASE_CONTEXT_PER_TEAMMATE = 50_000   # CLAUDE.md + project context
TASK_OVERHEAD_PER_TASK = 5_000       # task prompt + response + coordination
MESSAGE_OVERHEAD_PER_MSG = 1_000     # per message between teammates


def estimate_cost(teammates, tasks_per_teammate, model):
    """Calculate estimated token usage and costs."""
    costs = MODEL_COSTS[model]

    # Base context: each teammate loads project context
    base_context_tokens = teammates * BASE_CONTEXT_PER_TEAMMATE
    base_context_cost = base_context_tokens / 1000 * costs["input"]

    # Task execution: input (prompts) + output (responses)
    task_tokens_total = teammates * tasks_per_teammate * TASK_OVERHEAD_PER_TASK
    # Assume ~40% input, ~60% output split for task execution
    task_input_tokens = int(task_tokens_total * 0.4)
    task_output_tokens = int(task_tokens_total * 0.6)
    task_input_cost = task_input_tokens / 1000 * costs["input"]
    task_output_cost = task_output_tokens / 1000 * costs["output"]
    task_cost = task_input_cost + task_output_cost

    # Coordination: messages between teammates
    estimated_messages = teammates * (teammates - 1)
    coordination_tokens = estimated_messages * MESSAGE_OVERHEAD_PER_MSG
    # Coordination is roughly even input/output
    coord_input_tokens = coordination_tokens // 2
    coord_output_tokens = coordination_tokens // 2
    coordination_cost = (
        coord_input_tokens / 1000 * costs["input"]
        + coord_output_tokens / 1000 * costs["output"]
    )

    total_tokens = base_context_tokens + task_tokens_total + coordination_tokens
    total_cost = base_context_cost + task_cost + coordination_cost

    return {
        "teammates": teammates,
        "tasks_per_teammate": tasks_per_teammate,
        "model": model,
        "base_context": {
            "tokens": base_context_tokens,
            "cost": base_context_cost,
        },
        "task_execution": {
            "tokens": task_tokens_total,
            "input_tokens": task_input_tokens,
            "output_tokens": task_output_tokens,
            "input_cost": task_input_cost,
            "output_cost": task_output_cost,
            "cost": task_cost,
        },
        "coordination": {
            "messages": estimated_messages,
            "tokens": coordination_tokens,
            "cost": coordination_cost,
        },
        "total": {
            "tokens": total_tokens,
            "cost": total_cost,
        },
    }


def format_tokens(n):
    """Format token count with commas."""
    return f"{n:,}"


def format_cost(c):
    """Format cost as dollar amount."""
    return f"${c:.2f}"


def print_table(result):
    """Print a formatted cost estimate table."""
    sep = "\u2500" * 35

    print()
    print("  Agent Teams Cost Estimate")
    print(f"  {sep}")
    print(f"  Teammates:          {result['teammates']}")
    print(f"  Tasks/teammate:     {result['tasks_per_teammate']}")
    print(f"  Model:              {result['model']}")
    print()
    print(
        f"  Base context:       {format_tokens(result['base_context']['tokens'])} tokens "
        f"({format_cost(result['base_context']['cost'])} input)"
    )
    print(
        f"  Task execution:     {format_tokens(result['task_execution']['tokens'])} tokens "
        f"({format_cost(result['task_execution']['input_cost'])} input + "
        f"{format_cost(result['task_execution']['output_cost'])} output)"
    )
    print(
        f"  Coordination:       {format_tokens(result['coordination']['tokens'])} tokens "
        f"({format_cost(result['coordination']['cost'])})"
    )
    print(f"  {sep}")
    print(f"  Estimated total:    {format_cost(result['total']['cost'])}")
    print()


def print_comparison(teammates, tasks_per_teammate):
    """Print cost comparison across all models."""
    costs = {}
    for model in ("opus", "sonnet", "haiku"):
        r = estimate_cost(teammates, tasks_per_teammate, model)
        costs[model] = r["total"]["cost"]

    parts = " | ".join(f"{m}={format_cost(c)}" for m, c in costs.items())
    print(f"  Compare: {parts}")
    print()


def main():
    parser = argparse.ArgumentParser(
        description="Estimate token usage and cost for Agent Teams configurations.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""Examples:
  python cost-calculator.py --preset review
  python cost-calculator.py --preset debug --model opus
  python cost-calculator.py --teammates 4 --tasks-per-teammate 8 --compare
  python cost-calculator.py --preset build --json""",
    )
    parser.add_argument(
        "--preset",
        choices=list(PRESETS.keys()),
        help="Use a preset configuration (review, debug, build)",
    )
    parser.add_argument(
        "--teammates",
        type=int,
        help="Number of teammate agents",
    )
    parser.add_argument(
        "--tasks-per-teammate",
        type=int,
        help="Number of tasks each teammate handles",
    )
    parser.add_argument(
        "--model",
        choices=list(MODEL_COSTS.keys()),
        default="sonnet",
        help="Model to estimate costs for (default: sonnet)",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        dest="json_output",
        help="Output results as JSON",
    )
    parser.add_argument(
        "--compare",
        action="store_true",
        help="Show cost comparison across all models",
    )

    args = parser.parse_args()

    # Determine teammates and tasks
    if args.preset:
        preset = PRESETS[args.preset]
        teammates = preset["teammates"]
        tasks_per_teammate = preset["tasks_per_teammate"]
    elif args.teammates and args.tasks_per_teammate:
        teammates = args.teammates
        tasks_per_teammate = args.tasks_per_teammate
    else:
        parser.error("Provide either --preset or both --teammates and --tasks-per-teammate")

    if teammates < 1:
        parser.error("--teammates must be at least 1")
    if tasks_per_teammate < 1:
        parser.error("--tasks-per-teammate must be at least 1")

    result = estimate_cost(teammates, tasks_per_teammate, args.model)

    # Add preset label if applicable
    if args.preset:
        result["preset"] = args.preset
        result["preset_label"] = PRESETS[args.preset]["label"]

    if args.json_output:
        if args.compare:
            output = {}
            for model in ("opus", "sonnet", "haiku"):
                output[model] = estimate_cost(teammates, tasks_per_teammate, model)
            print(json.dumps(output, indent=2))
        else:
            print(json.dumps(result, indent=2))
    else:
        if args.preset:
            print(f"\n  Preset: {PRESETS[args.preset]['label']}")
        print_table(result)
        if args.compare:
            print_comparison(teammates, tasks_per_teammate)


if __name__ == "__main__":
    main()
