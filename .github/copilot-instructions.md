# GitHub Copilot Instructions

## File Editing Rules

- **NEVER remove license headers** from files when making edits.
- Always preserve the Apache 2.0 license header at the top of all source files (`.tf`, `.go`, `.sh`, etc.).
- When editing files, include the full license header in replacements if modifying code near the top of files.

## Terminal Command Rules

- **DO NOT use timeout flags** with terminal commands (e.g., avoid `-timeout` with go test)
- Let commands run to completion naturally. Do not use `less`, `more`, `head`, `tail` or similar pagers to truncate output as these will interrupt the execution of the command and potentially lead to corruption of the terraform state files.
- If a command needs to be stopped, the user will cancel it manually.
- For long-running tests, rely on the default behavior rather than imposing artificial time limits.

## Terraform Best Practices

- Follow the module structure defined in the repository.
- Maintain consistency with existing patterns.
- Use dynamic blocks appropriately for optional nested configurations.
- Always validate configurations with `terraform validate` before planning or applying.

## Testing Guidelines

- Write comprehensive tests that verify actual AWS resource creation.
- Use the AWS SDK to verify resource properties match Terraform outputs.
- Test both required and optional parameters.
- Include validation for resource naming, encryption, and other critical settings.

## Documentation Standards

- Focus on "why" and not "how" in documentation.
- Ensure clarity and conciseness in documentation.
- Use examples to illustrate complex concepts.
- Keep documentation up to date with code changes.
- Track changes in a CHANGELOG.md file instead of individual change documentation files.

## Terraform Primitive Module Development

- Primitive modules should be designed for reuse across multiple projects.
- Primitive modules should not contain any configuration or opinionated settings.
- Primitive modules should only wrap a single resource type. The only exception is when a resource requires a data source to function properly.
- The terraform code should exist in the root of the repository.
- The agent will modify the test files found in `/tests/testimpl/test_impl.go` to add test coverage for the primitive module.
- The agent should not modify any files outside of the root directory, the example implementations found in `/examples/`, and `/tests/testimpl/test_impl.go`.
