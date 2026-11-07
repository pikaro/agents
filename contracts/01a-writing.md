# Writing contract

Applies to everything written for a person: documentation, project contracts,
trackers and chat. It holds alongside every contract layer and is not one of
them. Project contracts may require specific content. This contract governs how
that content is written and kept, never whether required information is left
out.

## Rules for all writing

### The reader

The reader is an engineer at the end of a long day, reading once, without your
context. They cannot re-read files after every step and cannot read diffs.
Write so the text is easy to follow for that reader, not merely correct.

### Style

- Write plain, complete sentences. Say who does what.
- Use the vocabulary the reader already has: established technical terms and
    names from the project, its tools and its contracts.
- Do not coin labels or use a term in an unusual sense where a plain
    description would do. A rare one is tolerable. When most sentences contain
    one, the text becomes unreadable. If you need a new name, define it where it
    first appears. A term that decides what the reader does, or what state
    something is in, keeps one meaning across related documents. Where two
    behaviors differ, describe each one instead of giving both the same name.
- Keep text short by leaving out what does not matter. A length target limits
    how much is covered, not how fully each point is explained. Never shorten
    what does matter by dropping connecting words, packing ideas into labels,
    combining separate decisions in one sentence or leaving gaps for the reader
    to fill. Make each rule's conditions and consequences explicit. When
    brevity and clarity conflict, clarity wins.
- Be as specific as the reader needs to act. Name the module, file or value
    when they must act on it. Leave out detail that does not change what they
    do.
- State what is known, and say plainly what is not. Do not hedge by reflex, and
    do not repeat a limitation that does not change what the reader does.
- Use a short, concrete code example only where it makes something clear that
    is hard to explain in words.

```text
Bad:  Policy fix deferred; ds migration pending SDN triage.
Good: The policy in module X is to be rebuilt with an aws_iam_policy_document
      data source. This depends on the SDN fix and is scheduled after it.
```

### Relevance

Every statement must matter to the subject of the document or to the active
task. Report an unrelated finding in chat when it concerns correctness,
security or data loss, or is likely to affect the active work. Give it one
line, once, with its location and its criticality or urgency. Do not report
findings that are only cosmetic. Do not analyze an unrelated finding, list its
risks or record it in a file unless the user asks.

### State, not history

In files, describe what is, not how it came to be. Avoid "currently", "now",
"no longer", "previously", "first attempt", "we found that" and "this
replaces". When something changes, rewrite the statement and delete what it
superseded. History belongs in git, or in a changelog or migration document
that exists for it. Chat may discuss history freely.

When rewriting or archiving a document, move every unresolved prerequisite it
holds to a current document first.

### One home per fact

Each fact has one authoritative place. Elsewhere, link to it. Do not restate
what code, configuration or another document already shows, such as resource
lists, addresses, file inventories or expected plan output.

### Changing a file

- Change only what is wrong or new. Do not rewrite, reorder or reformat text
    that is still correct.
- When a change affects the title, opening or a summary, update them so the
    document as a whole still tells the truth.
- After changing files, summarize the substantive changes in chat in a few
    plain sentences, grouping related changes across files: which facts or
    decisions were added, changed or removed, why, and what the user must act
    on. The user will not read the files or diffs to find out.

## Documentation

Documentation explains a system to the people who use, operate or change it:
READMEs, design documents, runbooks and project contracts.

- Open with what the document is for and who uses it. A design document then
    says what is decided and what is open, before any detail.
- Keep the kinds apart. Rules for agents go in project contracts, design in
    design documents, procedures in runbooks and work in progress in trackers.
    A document does not carry the other kinds.
- Requirement documents state outcomes, ownership and constraints. They do not
    list helpers, functions, tests or check layouts.
- Design documents describe the required behavior, constraints, interfaces,
    ownership and the reasons for design choices. Include implementation detail
    only where it is part of a design decision or needed to understand its
    constraints. Leave incidental choices to the code.
- A document recording an implementation choice is not evidence that the
    choice is required.
- Project contracts hold rules for future work. Findings, decisions about one
    work package and notes about one session do not belong there.
- A request for documentation alone does not authorize runtime changes.

## Trackers

A tracker is the complete workbook for one work package, such as a review and
fix cycle, a feature or a migration. It is the authoritative record of that
work and its checkpoint for handoff and compaction. The user, or several agents
started with different prompts, must be able to continue the work from it
without prior conversations. Write it without steering toward one conclusion.

The tracker holds everything specific to the work package: its items,
decisions, open questions and implementation state. For facts about the system
that are not specific to the work package, link to the code and the
authoritative documents.

### Content

- At the top: purpose and scope in a few sentences. Keep them true as the work
    progresses.
- One entry per item, with a stable identifier. Each entry describes the item's
    current state, not a history of proposals, decisions and results:
    - the situation and why it matters;
    - its criticality or urgency, where that affects the order of work;
    - while open, the options; once decided, the decision. Where real
        alternatives were considered, add a short comparison and why they lost;
    - the effect on live systems, and risks not yet verified;
    - a status. Choose status values that fit the work (for example open,
        decided, deferred, implemented, deployed) and use them consistently.
        Use separate decision and work statuses where both matter.
- An item is decided only when the user has accepted it. A recommendation
    stays a proposal until then.
- When an item is decided, rewrite its proposal as the decision.
- Open questions, most blocking first.
- Implementation and deployment order, stated once.
- What a new agent needs to continue:
    - the paths changed per item while work is uncommitted;
    - per item, the verification performed and its result, naming the test or
        command where needed to identify what was checked, or "not verified"
        with the reason;
    - known failures not caused by this work.
- Environment facts that outlast the package belong in the project contract;
    link to them.

### Not in a tracker

- A narrative of progress. Item statuses show what is done. Never write "next,
    we do X".
- Implementation detail nobody needs to decide on. Field names, test output,
    logs and reasoning about code belong in the code, its comments and its
    commits. The exception is detail that was raised with the user as a
    potential problem, a risk or an implementation option: record it with the
    exact names and values discussed, because the next person or agent needs it
    to continue.
- Findings unrelated to the work package. An item the user explicitly defers
    stays as a one-line entry with that status.
- The same effect or order stated in several places.

### Working with the user

1. Raise the most blocking open questions in chat and discuss them there. The
    user does not re-read the tracker, so the chat must carry what they need to
    decide.
2. Once a question is settled, update the tracker to match and report the
    change in chat.
3. Questions that do not block stay in the tracker. Do not repeat them in chat
    at every step.

Update the tracker whenever a decision or an item's status changes. Never
delete a tracker; the user archives it.
