Analyze and fix the Jira issue: $ARGUMENTS.

**ULTRA-THINK DIRECTIVE**: Apply maximum analytical rigor throughout this process. Consider all possible edge cases, downstream effects, performance implications, and architectural impacts. Question every assumption and explore multiple solution approaches before implementing.

Follow these steps:

1. Run `./.claude/scripts/bugs.sh` to get the list of open and reopened issues
2. Find the issue in the output of the tool above
3. Understand the problem described in the issue - analyze root causes, consider why this issue exists, examine related systems that might be affected
4. Assess complexity: categorize as simple, medium, or complex based on required changes:
   - **Simple**: Single file changes, configuration updates, obvious bug fixes
   - **Medium**: Multi-file changes, UI modifications, logic updates
   - **Complex**: Architecture changes, new feature implementations, cross-system modifications
5. Search the codebase for relevant files and map to specific Unity project structure
6. Implement the necessary changes, ultra-think, follow these guidelines:
   - Prioritize smaller edits with fewer lines affecting less source files
   - Follow existing architecture and coding standards
   - Ensure fixes align with project patterns
   - Consider alternative implementation approaches and choose the most robust solution
   - Analyze potential performance implications and memory usage
   - Evaluate thread safety and concurrency concerns where applicable
   - Test edge cases and boundary conditions in your mind before implementing
7. Act as a harsh critic - launch a peer review process
8. Present the code reviewer with the context of what had been done
9. Offer an independent PR opinion highlighting potential issues with the suggested edits
10. Suggest on the screen a descriptive commit message
