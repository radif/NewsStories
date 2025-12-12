# JIRA-Claude Integration Tool

This tool fetches JIRA issues and formats them for analysis with Claude Code, making it easy to get AI assistance with your project's issues.

## 🚀 Quick Start

### 1. Install Dependencies
```bash
cd jira-integration
npm install
```

### 2. Configure JIRA Connection
```bash
npm run config
```
This will walk you through setting up your JIRA credentials interactively.

### 3. Fetch Issues
```bash
npm run fetch
```
This will fetch issues and create formatted files in the `output/` directory.

### 4. Use with Claude Code
1. Open the generated `.md` file from the `output/` directory
2. Copy the entire content 
3. Paste into Claude Code
4. Ask Claude to analyze and fix the issues

## 📋 Prerequisites

### JIRA API Token
1. Go to [Atlassian API Tokens](https://id.atlassian.com/manage-profile/security/api-tokens)
2. Click "Create API token" 
3. Give it a name (e.g., "Claude Integration")
4. Copy the generated token

### JIRA Information Needed
- **JIRA Domain**: Your organization's JIRA URL (e.g., `yourcompany.atlassian.net`)
- **Email**: Your JIRA login email
- **API Token**: From step above
- **Project Key**: Found in your JIRA project settings (e.g., `TLW`, `PROJ`)

## 🛠️ Manual Configuration

If you prefer to configure manually, copy `.env.example` to `.env` and fill in your values:

```bash
cp .env.example .env
```

Edit the `.env` file:
```env
JIRA_DOMAIN=yourcompany.atlassian.net
JIRA_EMAIL=your-email@example.com  
JIRA_API_TOKEN=your-api-token-here
PROJECT_KEY=YOUR_PROJECT_KEY
ASSIGNEE=                           # Optional: filter by assignee
STATUS_FILTER=                      # Optional: filter by status (single status)
STATUS_FILTERS=                     # Optional: filter by multiple statuses (comma-separated)
ISSUE_TYPE_FILTER=                  # Optional: filter by type
MAX_RESULTS=50                      # Optional: limit results
```

## 📝 Available Scripts

```bash
npm start        # Interactive mode with menu
npm run fetch    # Fetch issues and save to files
npm run config   # Configure JIRA connection
npm run print    # Fetch and print issues to console (no file output)
```

## 🎯 Usage Examples

### Basic Usage
```bash
# Fetch all open issues from your project and save to files
npm run fetch

# Fetch and print issues directly to console (no files created)
npm run print
```

#### Difference between `fetch` and `print`:
- **`npm run fetch`**: Fetches issues, saves markdown and JSON files to `output/` directory, displays statistics
- **`npm run print`**: Fetches issues and displays the same markdown format directly in the console without creating any files

### With Filters (edit .env file)
```env
STATUS_FILTER=In Progress           # Single status filter
STATUS_FILTERS=Open,In Progress,To Do  # Multiple status filter (comma-separated)
ISSUE_TYPE_FILTER=Bug              # Only "Bug" type issues  
ASSIGNEE=john.doe@company.com      # Only issues assigned to specific user
MAX_RESULTS=20                     # Limit to 20 issues
```

### Interactive Mode
```bash
npm start
# Choose from menu:
# - Fetch Issues from JIRA
# - Reconfigure JIRA Connection  
# - View Last Fetched Issues
# - Help & Instructions
```

## 📁 Output Files

The tool creates two types of files in the `output/` directory:

### 1. Markdown Files (for Claude)
- **Filename**: `jira-issues-YYYY-MM-DDTHH-mm-ss.md`
- **Purpose**: Formatted for Claude Code analysis
- **Contains**: Issue summaries, descriptions, and instructions for Claude

### 2. JSON Files (raw data)
- **Filename**: `jira-issues-raw-YYYY-MM-DDTHH-mm-ss.json`  
- **Purpose**: Complete raw JIRA data for reference
- **Contains**: Full API responses and statistics

## 🤖 Using with Claude Code

### Step-by-Step Process

1. **Fetch Your Issues**
   ```bash
   npm run fetch
   ```

2. **Open the Generated File**
   - Navigate to `output/` directory
   - Open the latest `jira-issues-*.md` file

3. **Copy to Claude**
   - Copy the entire file content
   - Paste into Claude Code

4. **Ask Claude to Help**
   Example prompts:
   ```
   "Please analyze these JIRA issues and create a plan to fix them"
   
   "Which of these issues are code-related and can be fixed now?"
   
   "Prioritize these issues by complexity and help me fix the high-priority bugs"
   
   "Create a development plan for addressing these issues in The Last Word project"
   ```

### Best Practices

- **Start Small**: Fetch 10-20 issues initially for better results
- **Use Filters**: Focus on specific components, assignees, or issue types
- **Clear Descriptions**: Ensure your JIRA issues have detailed descriptions
- **Use Labels**: Add labels like "bug", "enhancement", "technical-debt" to help Claude understand context
- **Include Context**: Add information about file paths, components, or affected systems in JIRA descriptions

## 🔧 Troubleshooting

### Authentication Issues
- **401 Unauthorized**: Check your email and API token
- **403 Forbidden**: Verify you have access to the JIRA project
- **Token expired**: Generate a new API token

### Connection Issues
- **Network errors**: Check your internet connection and JIRA domain
- **Domain not found**: Ensure domain doesn't include `https://` prefix
- **Rate limiting**: Wait a few minutes if you see rate limit errors

### No Issues Found
- **Check filters**: Your status/assignee/type filters might be too restrictive
- **Verify project key**: Make sure the project key is correct
- **Check permissions**: Ensure you can access the project in JIRA web interface

### Status Filtering Options

The tool supports two ways to filter by status:

#### Single Status (STATUS_FILTER)
```env
STATUS_FILTER=In Progress
```
Generates JQL: `status = "In Progress"`

#### Multiple Statuses (STATUS_FILTERS)
```env
STATUS_FILTERS=Open,In Progress,To Do
```
Generates JQL: `status IN ("Open", "In Progress", "To Do")`

**Note:** If you set both `STATUS_FILTER` and `STATUS_FILTERS`, the tool will use `STATUS_FILTERS` (multiple statuses take precedence).

### Common JQL Examples
The tool automatically builds JQL queries, but here are examples of what gets generated:

```jql
# Basic project filter (no status specified - excludes Done/Closed)
project = "TLW" AND status != "Done" AND status != "Closed" ORDER BY priority DESC, updated DESC

# With single status filter
project = "TLW" AND status = "In Progress" ORDER BY priority DESC, updated DESC

# With multiple status filter
project = "TLW" AND status IN ("Open", "In Progress", "To Do") ORDER BY priority DESC, updated DESC

# With assignee filter  
project = "TLW" AND assignee = "john.doe@company.com" AND status != "Done" ORDER BY priority DESC

# With issue type filter
project = "TLW" AND issuetype = "Bug" AND status != "Done" ORDER BY priority DESC
```

## 📊 Output Statistics

The tool provides helpful statistics including:
- Total issues found
- Breakdown by status (To Do, In Progress, etc.)
- Breakdown by issue type (Bug, Story, Task, etc.)  
- Breakdown by priority (High, Medium, Low, etc.)
- Breakdown by assignee

## 🔒 Security Notes

- API tokens are stored in `.env` file (not committed to git)
- Never share your API token or commit it to version control
- API tokens can be revoked/regenerated at any time from Atlassian
- The tool only reads JIRA data, it doesn't modify anything

## 📚 Additional Resources

- [JIRA REST API Documentation](https://developer.atlassian.com/cloud/jira/platform/rest/v3/)
- [JQL (JIRA Query Language) Guide](https://support.atlassian.com/jira-software-cloud/docs/use-advanced-search-with-jira-query-language-jql/)
- [Atlassian API Token Management](https://id.atlassian.com/manage-profile/security/api-tokens)

---

## 🐛 Issues or Questions?

If you encounter problems:
1. Check the troubleshooting section above
2. Verify your JIRA credentials and permissions
3. Try the interactive mode: `npm start`
4. Check the generated JSON files for raw JIRA responses