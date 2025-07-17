---
allowed_tools: Bash(gh label list), mcp__github__get_issue,mcp__github__get_issue_comments, mcp__github__update_issue,mcp__github__search_issues, mcp__github__list_issues
description: Work on a feature
---

## Context
- Current issue: !`mcp__github__get_issue`

## Your task
- read the issue and its task list in github format
- for each task in the issue:
  - complete the task
  - update the issue with the checkmark for the completed task
- after completing all the tasks create a meaningful commit message
- finally create a pull request