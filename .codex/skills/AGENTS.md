# Salesforce DX project instructions

## Scope and layout

- Treat this as a Salesforce DX source repository.
- Place Salesforce metadata under `force-app/main/default`.
- Preserve the existing metadata structure and naming patterns before adding new artifacts.
- Do not deploy, retrieve, authorize an org, or change an org's data unless the user explicitly asks.

## Development standards

### Apex

- Write bulk-safe code. Do not run SOQL or DML inside loops.
- Use `with sharing` or `inherited sharing` unless a documented requirement requires another sharing mode.
- Enforce object- and field-level access at user-facing entry points. Prefer the security mechanism appropriate to the operation, such as user-mode database operations or `WITH USER_MODE` queries.
- Keep trigger logic thin; delegate business logic to handlers or services.
- Name controllers `*Ctrl`, services `*Service`, trigger handlers `*Handler`, and tests `*Test`.

### Tests

- Add or update an `@isTest` class whenever Apex behavior changes.
- Include meaningful assertions; cover success, error, and bulk scenarios when applicable.
- Use `@TestSetup` only when shared setup improves readability. Wrap the code under test in `Test.startTest()` and `Test.stopTest()` when it exercises asynchronous code or limit-sensitive logic.
- Do not optimize solely for a coverage percentage.

### LWC and metadata

- Keep LWC changes scoped to the component and its tests.
- Follow the repository's ESLint and Prettier configuration; do not introduce a second formatter or linter.

## Validation

Run the checks relevant to changed files before concluding:

- LWC JavaScript: `npm run lint`
- LWC unit tests: `npm test`
- Formatting check: `npm run prettier:verify`
- Apex tests or deployment validation: use Salesforce CLI only when an authorized target org and the requested scope are available.

If a required validation cannot run, state the command, why it was skipped, and what remains unverified.

## Working style

- Inspect relevant metadata before editing; do not invent SObjects, fields, permissions, or business rules.
- Keep changes minimal and avoid unrelated refactors.
- In the final response, list changed files and validation results.