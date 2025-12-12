Analyze the last git commit using the code-reviewer-critic agent:

1. Run `./.claude/scripts/review-critic-last-commit.sh` to get the git diff and file list for the last commit
2. Abort if "❌ Error: Not in a git repository"
3. Abort if "❌ Error: No commits found in repository"
4. Use the code-reviewer-critic agent to analyze the changes in the last commit
5. Provide a comprehensive code review focusing on:
   - Code quality and best practices
   - Architecture and design patterns
   - Potential bugs or issues  
   - Performance considerations
   - Integration with existing codebase
   - Risk assessment and recommendations