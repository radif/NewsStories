# Claude Code Integration Guide

This guide explains how to integrate the JIRA MCP Server with Claude Code for seamless JIRA issue management.

## Quick Start

1. **Setup the MCP Server**
   ```bash
   cd replay-dev-tools/jira-integration/mcp-server
   npm run setup
   ```

2. **Configure Claude Code**
   Add to your Claude Code MCP settings:
   ```json
   {
     "mcpServers": {
       "jira": {
         "command": "node",
         "args": ["/path/to/replay-dev-tools/jira-integration/mcp-server/src/index.js"]
       }
     }
   }
   ```

3. **Test Integration**
   In Claude Code, try: `"Use jira_test_connection to verify everything is working"`

## Common Workflows

### Analyzing Sprint Issues

**Prompt:** "Use jira_analyze_issues to get a prioritized list of code issues for project TLW that need fixing"

**What happens:**
1. Claude Code calls `jira_analyze_issues` with projectKey "TLW"
2. MCP server fetches and categorizes issues by type and priority
3. Returns structured analysis with:
   - Critical bugs first
   - Code-related issues identified  
   - Implementation recommendations
   - File paths and fix suggestions

### Getting Specific Issue Details

**Prompt:** "Use jira_get_issue to get full details for TLW-347"

**What happens:**
1. Claude Code calls `jira_get_issue` with issueKey "TLW-347"
2. Returns complete issue information including:
   - Description and comments
   - Status and priority
   - Assignee and dates
   - Components and labels

### Fetching Filtered Issues

**Prompt:** "Use jira_fetch_issues to get all high-priority bugs assigned to john@example.com in project TLW"

**What happens:**
1. Claude Code calls `jira_fetch_issues` with filters:
   - projectKey: "TLW"
   - priority: "High"
   - assignee: "john@example.com"
   - issueType: "Bug"
2. Returns formatted issues ready for analysis

## Advanced Usage Patterns

### Issue-Driven Development

1. **Fetch Issues:** Get current sprint issues
   ```
   Use jira_analyze_issues for TLW project focusing on "bugs" and "unity" issues
   ```

2. **Analyze:** Claude Code identifies fixable issues and creates implementation plan

3. **Implement:** Claude Code can directly modify files based on issue requirements

4. **Reference:** Include JIRA keys in commit messages automatically

### Batch Issue Processing

**Prompt:** "Get all issues in TLW project with 'ui' and 'performance' labels, then create a comprehensive fix plan"

**Workflow:**
1. Uses `jira_fetch_issues` with label filters
2. Groups related issues by component/area
3. Creates implementation plan with:
   - Shared file modifications
   - Testing strategies
   - Dependency considerations

### Code Review Integration

**Prompt:** "Check if there are any JIRA issues related to the PlayerProfileManager class"

**Workflow:**
1. Searches issues for mentions of "PlayerProfileManager"
2. Identifies related bugs or improvements
3. Suggests code changes that address multiple issues

## Tool Reference

### jira_fetch_issues
- **Use for:** Getting lists of issues with filtering
- **Best for:** Sprint planning, bulk analysis, filtered queries
- **Returns:** Formatted issue list ready for Claude analysis

### jira_get_issue  
- **Use for:** Detailed information about specific issues
- **Best for:** Understanding requirements, checking status, getting context
- **Returns:** Complete issue details with comments and history

### jira_test_connection
- **Use for:** Verifying connectivity and credentials
- **Best for:** Troubleshooting, initial setup validation
- **Returns:** Connection status and user information

### jira_analyze_issues
- **Use for:** Structured analysis prioritized for development
- **Best for:** Sprint planning, identifying actionable items, code fix prioritization
- **Returns:** Categorized issues with implementation recommendations

## Integration with Existing Workflow

The MCP server integrates with the existing `replay-dev-tools/jira-integration` workflow:

**Before (Manual Process):**
1. Run `npm run fetch` to get issues
2. Open markdown file
3. Copy to Claude Code
4. Ask for analysis

**After (MCP Integration):**
1. Direct integration: `"Analyze current TLW issues"`
2. Immediate results and implementation
3. No file copying or manual steps

## Configuration Tips

### Project-Specific Shortcuts

Add environment variables for common queries:
```env
DEFAULT_PROJECT_KEY=TLW
DEFAULT_ASSIGNEE=your-email@company.com
DEFAULT_MAX_RESULTS=25
```

### Claude Code Aliases

Create common prompts as saved conversations:
- "Sprint Analysis" → Use jira_analyze_issues for current sprint
- "Bug Triage" → Fetch high-priority bugs for analysis  
- "My Issues" → Get issues assigned to current user

### Performance Optimization

- Use `maxResults` parameter to limit large queries
- Focus on specific issue types when possible
- Combine related requests in single conversations

## Troubleshooting

### Common Issues

1. **"Tool not found"**
   - MCP server not properly configured in Claude Code
   - Check server path in configuration
   - Verify server is running with `npm test`

2. **"Authentication failed"**
   - JIRA credentials incorrect or expired
   - Generate new API token
   - Check .env file in parent directory

3. **"No issues found"**
   - Verify project key spelling
   - Check issue filters aren't too restrictive
   - Ensure you have read permissions

### Debug Steps

1. Test MCP server directly:
   ```bash
   npm test
   ```

2. Check Claude Code logs for MCP errors

3. Verify .env configuration:
   ```bash
   cd ../  # parent directory
   cat .env  # should show JIRA credentials
   ```

### Getting Help

- Check server logs in Claude Code
- Run connection test: `npm test`
- Verify configuration with: `npm run setup`
- Review README.md for detailed documentation