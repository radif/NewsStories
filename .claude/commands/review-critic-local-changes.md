Analyze uncommitted git changes using the code-reviewer-critic agent:

1. Run `./.claude/scripts/review-critic.sh` to get the git diff and file list
2. Abort if "✅ No uncommitted changes found"
3. Abort if "❌ Error: Not in a git repository"
2. Use the code-reviewer-critic agent to analyze the changes
3. Provide a comprehensive code review focusing on:
   - Code quality and best practices
   - Architecture and design patterns
   - Potential bugs or issues  
   - Performance considerations
   - Integration with existing codebase
   - Risk assessment and recommendations
