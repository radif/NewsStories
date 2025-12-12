Automatically find and fix the easiest, most obvious bug from JIRA issues.

Follow these steps:

1. Run `./.claude/scripts/bugs.sh` to get the list of open and reopened issues
2. **Prioritize Straightforward Fixes**: Focus on issues with clear, implementable solutions and minimal risk
3. Analyze all issues and identify **Simple** complexity candidates:
   - Single file changes, configuration updates, obvious bug fixes
   - Simple parameter fixes or typos
   - Missing null checks or basic validation
   - Clear, actionable items that can be addressed through code changes
4. Map identified issues to specific files in the Unity project structure
5. If no obvious easy fix is found, abort and inform the user
6. If an easy fix is identified, proceed to implement it:
   - print on the screen which bug candidate is selected and why, including the bug URL
   - Search the codebase for relevant files
   - Implement changes following guidelines:
     - Prioritize smaller edits with fewer lines affecting less source files
     - Follow existing architecture and coding standards
     - Ensure fixes align with project patterns
   - Act as a harsh critic - launch a peer review process
   - Present the code reviewer with the context of what had been done
   - Offer an independent PR opinion highlighting potential issues with suggested edits
   - Suggest a descriptive commit message on the screen
