# Contract repository

This repository holds the agent contracts and the hook that assembles them.

- The files under `contracts/` are the material of the work, not
    instructions for it. The contract injected at session start may predate
    the files. When a task concerns a contract, read the file and judge
    proposed wording by the behavior it should produce, not by its agreement
    with the injected text.
- Write or edit a contract only after the user has approved the exact
    wording in chat. A request to investigate or propose is not approval.
    Conformance cleanup does not apply to contract files.
- Contracts reference each other's sections, such as *General → Conformance
    cleanup*. The rule against citing contracts applies to the hook, not to
    contract text.
- Choose words deliberately. Agents work around contracts creatively, and
    naming a mechanism, such as a directory or a document type, nudges them
    to create it. Brevity is not a goal. Remove words only where that
    improves clarity.
- Contracts never name contract files or tell the agent to load files. The
    agent sees only the injected text.
