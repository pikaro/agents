# Prod phase contract

Inactive unless the project contract declares it. Extends General; overrides the
rules marked **phase-dependent** there. Mutually exclusive with Dev phase.

Premise: the component has consumers that cannot be updated in the same change.
Compatibility is a requirement.

______________________________________________________________________

## Breaking changes

- A breaking change to a public API, on-wire format, schema, persisted format or
    file layout is a blocking assumption. Ask, and name the affected consumers.
- Compatibility is required for anything a separately deployed or externally held
    consumer can observe. Internal-only code with all call sites in the repository
    may change freely, subject to *General → Ask first* on scope.

## Evolution rules

- Change formats additively. Add fields; do not repurpose, renumber, or remove
    them.
- Readers tolerate unknown fields and absent optional fields.
- Versioned formats carry an explicit version; readers handle every version still
    in the field.
- N-1 must be able to read what N writes, for as long as rollback to N-1 is
    possible.
- Deprecate before removal: mark, document the replacement, keep the old path
    working for the agreed period, then remove in a separate change.

## Migrations

- A persisted-format change ships with a migration, and the migration is
    idempotent and resumable.
- A migration that can be interrupted must leave the data readable by both the
    old and the new reader.

## Always

- State compatibility impact in the summary for any change to a public surface.
- Add a test that exercises the old format or the old call shape against the new
    code.
