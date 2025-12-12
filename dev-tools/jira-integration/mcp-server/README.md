# JIRA MCP Server

A Model Context Protocol (MCP) server that provides JIRA integration capabilities for Claude Code. This server wraps the existing `replay-dev-tools/jira-integration` functionality and exposes it as MCP tools.

## Features

- **Fetch JIRA Issues**: Query issues with flexible filtering options
- **Get Specific Issue**: Retrieve detailed information about individual issues  
- **Test Connection**: Validate JIRA credentials and connectivity
- **Analyze Issues**: Structured analysis of issues for code fixing prioritization

## Prerequisites

- Node.js 18.0.0 or higher
- Valid JIRA credentials configured in parent directory
- Access to JIRA instance with appropriate permissions

## Installation

```bash
cd replay-dev-tools/jira-integration/mcp-server
npm install
```

## Configuration

The MCP server uses the same configuration as the parent JIRA integration tool. Ensure you have a `.env` file in the `replay-dev-tools/jira-integration/` directory with:

```env
JIRA_DOMAIN=your-domain.atlassian.net
JIRA_EMAIL=your-email@company.com
JIRA_API_TOKEN=your-api-token
PROJECT_KEY=TLW
```

### Getting JIRA API Token

1. Go to [Atlassian Account Security](https://id.atlassian.com/manage-profile/security/api-tokens)
2. Create a new API token
3. Copy the token to your `.env` file

## Testing

Test the connection and configuration:

```bash
npm test
```

This will verify:
- Environment variables are present
- JIRA connection works
- Basic issue fetching functionality

## Usage with Claude Code

### Method 1: CLI Connection

Add to your Claude Code MCP configuration:

```json
{
  "mcpServers": {
    "jira": {
      "command": "node",
      "args": ["/path/to/replay-dev-tools/jira-integration/mcp-server/src/index.js"],
      "env": {
        "NODE_ENV": "production"
      }
    }
  }
}
```

### Method 2: npm global install (optional)

```bash
npm install -g .
```

Then reference in Claude Code config:

```json
{
  "mcpServers": {
    "jira": {
      "command": "jira-mcp-server"
    }
  }
}
```

## Available MCP Tools

### `jira_fetch_issues`

Fetch JIRA issues with filtering options.

**Parameters:**
- `projectKey` (required): JIRA project key (e.g., "TLW")
- `maxResults` (optional): Maximum number of issues (default: 50)
- `assignee` (optional): Filter by assignee email/username
- `status` (optional): Filter by status (defaults to open issues)
- `issueType` (optional): Filter by issue type ("Bug", "Task", etc.)
- `priority` (optional): Filter by priority level

**Example:**
```
Use the jira_fetch_issues tool to get all high-priority bugs in project TLW
```

### `jira_get_issue`

Get detailed information about a specific issue.

**Parameters:**
- `issueKey` (required): JIRA issue key (e.g., "TLW-123")

**Example:**
```
Use jira_get_issue to get details for issue TLW-347
```

### `jira_test_connection`

Test JIRA connection with current credentials.

**Parameters:** None

**Example:**
```
Use jira_test_connection to verify the JIRA connection is working
```

### `jira_analyze_issues`

Analyze issues and provide structured output for code fixes.

**Parameters:**
- `projectKey` (required): JIRA project key to analyze
- `focusAreas` (optional): Array of focus areas (e.g., ["bugs", "performance", "ui"])
- `maxResults` (optional): Maximum issues to analyze (default: 25)

**Example:**
```
Use jira_analyze_issues with projectKey "TLW" and focusAreas ["bugs", "unity"] to get a prioritized list of code issues to fix
```

## Development

### Project Structure

```
mcp-server/
├── src/
│   ├── index.js           # Main MCP server
│   ├── jira-service.js    # JIRA API wrapper
│   └── test-connection.js # Connection test utility
├── package.json
└── README.md
```

### Running in Development

```bash
npm run dev
```

This starts the server with file watching for development.

### Key Components

1. **MCP Server (`index.js`)**: Implements the MCP protocol and tool definitions
2. **JIRA Service (`jira-service.js`)**: Wraps JIRA API calls and formatting logic  
3. **Test Utility (`test-connection.js`)**: Validates configuration and connectivity

## Integration with Claude Code Workflow

This MCP server integrates seamlessly with the established Claude Code workflow for JIRA analysis:

1. **Fetch Issues**: Use `jira_fetch_issues` or `jira_analyze_issues` to get structured issue data
2. **Analyze**: Claude Code processes the formatted issues and identifies actionable items
3. **Implement**: Claude Code can directly implement fixes based on the analysis
4. **Track**: Reference specific JIRA issue keys in commits and pull requests

### Example Claude Code Usage

```
Analyze the current sprint issues for The Last Word project and create a prioritized implementation plan for code-related bugs.
```

Claude Code will:
1. Use `jira_analyze_issues` to fetch and categorize issues
2. Identify which issues can be fixed through code changes
3. Create an implementation plan with specific file paths and changes
4. Prioritize by impact and complexity

## Error Handling

The MCP server includes comprehensive error handling for:

- Missing or invalid JIRA credentials
- Network connectivity issues
- Invalid JIRA queries
- Permission errors
- API rate limiting

All errors are returned as structured MCP error responses with helpful diagnostic information.

## Security

- API tokens are read from environment variables only
- No credentials are logged or transmitted except for authentication
- Uses secure HTTPS connections to JIRA APIs
- Follows JIRA API authentication best practices

## Troubleshooting

### Common Issues

1. **Connection Failed (401)**
   - Verify JIRA_EMAIL and JIRA_API_TOKEN are correct
   - Generate a new API token if needed

2. **Connection Failed (403)**
   - Check project permissions for your JIRA user
   - Verify PROJECT_KEY is accessible

3. **No Issues Found**
   - Check project key spelling
   - Verify issue filters aren't too restrictive
   - Ensure issues exist matching the criteria

4. **MCP Server Won't Start**
   - Verify Node.js version (18+ required)  
   - Check that all dependencies are installed
   - Ensure .env file exists in parent directory

### Debug Mode

Set environment variable for additional logging:

```bash
DEBUG=true npm start
```

## Contributing

1. Follow existing code style and patterns
2. Add tests for new functionality
3. Update documentation for API changes
4. Ensure backward compatibility with existing tools