# Subagent contract

Applies whenever an agent delegates work to another model invocation. The
orchestrator is the agent responsible for the user's task. A worker is an agent
performing an assignment for that orchestrator.

This contract applies alongside the other contracts. Delegation does not widen
the authorized scope or transfer responsibility for the result.

## Reasons to delegate

Delegation may improve quality, conserve resources, shorten completion time or
manage context. Any one of these benefits can justify delegation. The expected
benefit must warrant the resource use, coordination work and risk introduced by
the delegation. Apply the corresponding constraints when choosing workers,
configurations and assignments.

### Quality

Use workers for relevant expertise, independent scrutiny or distinct approaches.
A worker need not be more capable than the orchestrator to contribute useful
evidence.

Before adding a reviewer or increasing capability or reasoning effort, identify
the unresolved question it should address and why the additional work is likely
to help. Do not commission further reviews merely because another review might
find something. Stop when the required quality and supporting evidence are
established.

### Resources

Delegate to less resource-intensive configurations when they can meet the
assignment's acceptance criteria. Equal-quality results with lower resource use
are sufficient justification.

Include briefing, verification, integration and likely rework when judging the
saving. Check uncertain results more thoroughly. If repeated corrections or
extensive verification remove the expected saving, change the assignment,
configuration or execution approach before continuing.

Prefer deterministic tools for work they can perform reliably. Do not replace
one straightforward tool operation with multiple model assignments.

### Completion time

Parallelize independent work when finishing sooner benefits the task. Do not
launch dependent assignments before their prerequisites are available.

Use only as much concurrency as can make useful progress. A shorter elapsed time
does not authorize exceeding resource limits.

### Context

Delegate bounded work when keeping its detail outside the orchestrator's context
helps complete the task. Supply the constraints and source material needed for
the assignment, and require the worker to return the conclusions and evidence
needed to use its result.

Do not copy the full conversation by default. Do not omit relevant context merely
to reduce the size of the briefing.

## Worker configuration

Use the compatibility matrix to identify suitable models, supported reasoning
settings and permitted usage. Select model and reasoning together for the
assignment. Choose the least resource-intensive permitted configuration expected
to complete it reliably.

Explicitly select model and reasoning effort wherever the delegation mechanism
exposes those controls. Deliberately configure other assignment-relevant controls
while preserving applicable permission, isolation and execution constraints.
Where a control is unavailable, use the effective behavior established by the
matrix. Do not silently inherit the orchestrator's configuration or substitute
a more resource-intensive configuration.

If the matrix does not establish a suitable permitted configuration, continue
directly where feasible or ask the user to authorize a specific configuration
for a bounded assignment. Do not invent model mappings, supported settings or
equivalences between providers.

The orchestrator's own model and reasoning effort do not authorize the same
configuration for workers. A larger repository or a longer list of repetitive
items does not by itself justify a more capable model or higher reasoning effort.

## Compatibility matrix

### Models and capabilities

Catalog date: 2026-11-25.

The classes group the roles described by the manufacturers. Lightweight models
serve focused, high-volume work. General-purpose models serve everyday coding
and agent workflows. Advanced models serve demanding reasoning and complex
engineering. These classes do not imply equal capability or equal allowance
consumption across providers.

| Class | Anthropic | OpenAI |
| --- | --- | --- |
| Lightweight | Claude Haiku 5.5, `claude-haiku-5-5` | GPT-6 Luna, `gpt-6-luna` |
| General-purpose | Claude Sonnet 5.5, `claude-sonnet-5-5` | GPT-6.2 Sol, `gpt-6.2-sol` |
| Advanced | Claude Opus 5.5, `claude-opus-5-5` | GPT-6.2 Astra, `gpt-6.2-astra` |

Model identities and roles come from the
[Anthropic model catalog](https://platform.claude.com/docs/en/models/overview),
[OpenAI model catalog](https://developers.openai.com/api/docs/models) and
[OpenAI model selection guide](https://developers.openai.com/api/docs/guides/model-selection).

Claude Fable is excluded because of EU data-protection requirements. Do not
select it as a fallback.

### Reasoning settings and effective configuration

The listed Anthropic models support `low`, `medium`, `high`, `xhigh` and `max`.
Their API defaults are `medium` for Haiku and Opus, and `high` for Sonnet. See
[Anthropic's effort reference](https://platform.claude.com/docs/en/build-with-claude/effort).

The listed OpenAI models support `low`, `medium`, `high`, `xhigh` and `max`.
Luna also supports `none`. See the
[OpenAI model catalog](https://developers.openai.com/api/docs/models).

API support does not establish availability in a particular account or
delegation tool. Use only configurations supported by the active tool and
permitted by the allocation below. An exposed setting absent from this matrix
does not acquire permission merely because the tool accepts it.

In Claude Code, model aliases and omitted settings can resolve through parent
settings or defaults. Environment settings can override an explicit subagent
model or effort. Establish the effective configuration using the
[Claude Code subagent rules](https://code.claude.com/docs/en/sub-agents#choose-a-model)
before relying on a requested setting.

In Codex, omitted model and effort settings can inherit from the parent. Agent
definitions and configured defaults also affect the result. Establish the
effective configuration using the
[Codex subagent rules](https://learn.chatgpt.com/docs/agent-configuration/subagents)
and the active tool's interface. If the interface cannot select model and effort
for a conversation fork, use a bounded briefing with a configuration that can be
selected explicitly. If the effective configuration cannot be established, do
not launch the worker.

### Autonomous allocations

The following allocations authorize autonomous delegation within the task's
scope. They apply across all models and providers in each class.

| Class | Effort permitted without further approval | Concurrent workers | Execution attempts per work package |
| --- | --- | --- | --- |
| Lightweight | Supported levels through `high` | 8 | No policy cap |
| General-purpose | Supported levels through `high` | 2 | 8 |
| Advanced | None | Requires approval | Requires approval |

At most eight workers may run concurrently across all classes unless the user
approves a larger allocation. Stricter platform restrictions remain binding.
The general-purpose allocation is shared across that class. Switching models,
providers or reasoning settings does not replenish it.

Reasoning above `high`, including `xhigh`, `max` or a higher setting exposed by
the platform, requires explicit approval for every class. Advanced models
require approval at every reasoning level. An approval must identify the
permitted configurations, scope, concurrency and execution-attempt allocation.

An execution attempt is a request for a worker to begin or resume an assignment.
Count retries, replacements and corrections that start another run, including
failed attempts. A clarification sent while the worker is still running does
not add an attempt unless it expands the assignment's scope. Giving a worker
another assignment consumes another attempt even if the worker is reused.

"No policy cap" removes only the numerical attempt limit. The requirements for
justified delegation, bounded assignments, verification and stopping still apply.

## Resource limits

Apply both configuration-specific and aggregate allocation limits established
by the compatibility matrix. A reason to delegate does not override those
limits. User approval can expand a policy allocation but cannot override a
platform restriction.

Limits apply to the work package defined in *General → Task scope*. Preserve the
accounting when the same work continues after compaction or in another session.
Distinguish continuation or clarification of an existing assignment from
expanding its scope or initiating a new assignment. Account for further
execution using the allocation's units.

Only the orchestrator may delegate. Workers must not launch other workers or
arrange equivalent delegation through another mechanism.

Before exceeding a limit, obtain approval that identifies the configurations,
additional allocation and scope. Approval for one allocation does not authorize
further expansion. Do not evade limits through batching, nested sessions,
alternate tools or repeated retries.

Do not infer remaining subscription allowance, reset times or resource charges
without reliable account information. Permission to use a configuration is not
evidence that sufficient allowance remains.

## Assignments and execution

Give each worker a bounded assignment. In its brief, state the acceptance
criteria, the expected deliverable and the project rules and other constraints
that apply. Say whether the worker may edit files and, if so, which files it
owns. Keep concurrent edits from conflicting.

When a worker starts with fresh context, tell it explicitly that it is a worker
and must not delegate. Include the instructions it needs to carry out the
assignment even if the parent has already received them.

Avoid duplicate work unless independent results serve an identified verification
need. Do not perform the same assignment yourself while a worker performs it
merely to remain busy.

For repetitive work, establish the approach and verify representative results
before expanding. Assign coherent portions of work rather than creating a
worker for every trivial operation.

A worker must report its result, the evidence and checks supporting it, and
anything incomplete or uncertain. It must not reproduce extensive source
material where a concise finding and a precise reference suffice.

## Verification and accounting

The orchestrator integrates delegated work and verifies that the combined result
meets the task's acceptance criteria. A worker's confidence or completion report
is not verification.

Choose verification according to the consequences of error and the reliability
of the evidence. Do not accept weaker results to preserve a claimed resource
saving. Do not routinely repeat the entire assignment when a smaller check can
establish the required result.

Track assignments, configurations, allocations and completion states in working
context. Use an existing tracker when the work requires one under
*Writing → Trackers*. Delegation alone does not require a separate record.

At quota exhaustion or rate limiting, stop launching or retrying affected
workers. Report completed, failed and outstanding work, including results that
remain unverified. Continue independent work where feasible, but do not switch
configurations to bypass the restriction without authorization.

Do not claim completion of the overall task while required work or verification
remains incomplete. Failed or abandoned assignments may be superseded only when
their required scope has been otherwise completed or established as unnecessary.
