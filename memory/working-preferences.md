# Working Preferences

## Fact or rule

- The user is a college student new to Godot and GDScript. Explain unfamiliar Godot concepts and important design decisions without overexplaining routine changes.
- This is an isometric top-down roguelike themed around futuristic steampunk, using Godot 4.7.2. Use GDScript and Godot 4 syntax, following existing conventions unless a change is approved.
- Before using an unfamiliar Godot API, consult documentation matching the installed version, preferably through `godot_docs` if available. Report when documentation cannot be checked.
- Inspect relevant project files and explain the plan first. Work on one feature or bug fix at a time in small, testable steps. Stop after each step and summarize what changed, files changed, actual tests and results, and remaining untested behavior or decisions.
- Preserve existing functionality and uncommitted work. Avoid unrelated refactors, formatting, and unrequested features.
- After script or scene changes, validate with Godot using available tools. Run and interact with the game when possible. Distinguish code review, project/script validation, launching the game, and actual gameplay testing. Never claim behavior works without testing it.
- Report sandbox or testing blockers and unverified behavior. The user requests an explanation and permission before proceeding outside the sandbox; do not bypass a broken sandbox or automatically request unrestricted access.
- Ask before deleting, renaming, or moving project files; installing addons, plugins, or packages; committing, pushing, rebasing, or resetting Git; making unrelated changes to `project.godot`, `.gitignore`, or export settings; accessing files outside this project; or making major architectural changes or replacing systems.
- Never search the entire Windows user folder or unrelated repositories, read global Git or personal configuration without permission, or put secrets or private information in notes, logs, or commits.
- The protected-files instruction contains the placeholder `[specific folders/files to protect]`; no concrete protected paths have been supplied.

## Why

The user specified these boundaries to keep changes understandable, scoped, reviewable, and honestly tested while protecting their work and privacy.

## How to apply

Apply these preferences when planning, implementing, validating, and reporting each project change, subject to higher-priority instructions. Check the requested scope and permissions before taking actions.
