#!/usr/bin/env node

import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ErrorCode,
  ListToolsRequestSchema,
  McpError,
} from "@modelcontextprotocol/sdk/types.js";
import { JiraService } from './jira-service.js';
import dotenv from 'dotenv';

// Load environment variables from parent directory
dotenv.config({ path: '../.env' });

class JiraMcpServer {
  constructor() {
    this.server = new Server(
      {
        name: "@replay/jira-mcp-server",
        version: "1.0.0",
      },
      {
        capabilities: {
          tools: {},
        },
      }
    );

    this.jiraService = new JiraService();
    this.setupToolHandlers();
  }

  setupToolHandlers() {
    // List available tools
    this.server.setRequestHandler(ListToolsRequestSchema, async () => {
      return {
        tools: [
          {
            name: "jira_fetch_issues",
            description: "Fetch JIRA issues based on filters and return them formatted for analysis",
            inputSchema: {
              type: "object",
              properties: {
                projectKey: {
                  type: "string",
                  description: "JIRA project key (e.g., 'TLW')"
                },
                maxResults: {
                  type: "number",
                  description: "Maximum number of issues to fetch (default: 50)",
                  default: 50
                },
                assignee: {
                  type: "string",
                  description: "Filter by assignee email or username (optional)"
                },
                status: {
                  type: "string", 
                  description: "Filter by status (optional, defaults to open issues)"
                },
                issueType: {
                  type: "string",
                  description: "Filter by issue type like 'Bug', 'Task', etc (optional)"
                },
                priority: {
                  type: "string",
                  description: "Filter by priority level (optional)"
                }
              },
              required: ["projectKey"]
            }
          },
          {
            name: "jira_get_issue", 
            description: "Get detailed information about a specific JIRA issue",
            inputSchema: {
              type: "object",
              properties: {
                issueKey: {
                  type: "string",
                  description: "JIRA issue key (e.g., 'TLW-123')"
                }
              },
              required: ["issueKey"]
            }
          },
          {
            name: "jira_test_connection",
            description: "Test the connection to JIRA with current credentials",
            inputSchema: {
              type: "object",
              properties: {},
              additionalProperties: false
            }
          },
          {
            name: "jira_analyze_issues",
            description: "Analyze a set of JIRA issues and provide structured analysis for code fixes",
            inputSchema: {
              type: "object", 
              properties: {
                projectKey: {
                  type: "string",
                  description: "JIRA project key to analyze"
                },
                focusAreas: {
                  type: "array",
                  items: {
                    type: "string"
                  },
                  description: "Specific areas to focus on (e.g., ['bugs', 'performance', 'ui'])"
                },
                maxResults: {
                  type: "number",
                  description: "Maximum number of issues to analyze (default: 25)",
                  default: 25
                }
              },
              required: ["projectKey"]
            }
          }
        ],
      };
    });

    // Handle tool calls
    this.server.setRequestHandler(CallToolRequestSchema, async (request) => {
      const { name, arguments: args } = request.params;

      try {
        switch (name) {
          case "jira_fetch_issues":
            return await this.handleFetchIssues(args);
          
          case "jira_get_issue":
            return await this.handleGetIssue(args);
            
          case "jira_test_connection":
            return await this.handleTestConnection(args);
            
          case "jira_analyze_issues":
            return await this.handleAnalyzeIssues(args);

          default:
            throw new McpError(
              ErrorCode.MethodNotFound,
              `Unknown tool: ${name}`
            );
        }
      } catch (error) {
        throw new McpError(
          ErrorCode.InternalError,
          `Error executing ${name}: ${error.message}`
        );
      }
    });
  }

  async handleFetchIssues(args) {
    const { projectKey, maxResults = 50, assignee, status, issueType, priority } = args;
    
    // Validate required environment variables
    this.validateConfiguration();
    
    const filters = {
      projectKey,
      assignee: assignee || null,
      status: status || null,
      issueType: issueType || null,
      priority: priority || null
    };

    const issues = await this.jiraService.fetchIssues(filters, maxResults);
    const formatted = this.jiraService.formatIssuesForClaude(issues);
    
    return {
      content: [
        {
          type: "text",
          text: formatted
        }
      ]
    };
  }

  async handleGetIssue(args) {
    const { issueKey } = args;
    
    this.validateConfiguration();
    
    const issue = await this.jiraService.getIssue(issueKey);
    const formatted = this.jiraService.formatSingleIssueForClaude(issue);
    
    return {
      content: [
        {
          type: "text", 
          text: formatted
        }
      ]
    };
  }

  async handleTestConnection(args) {
    try {
      this.validateConfiguration();
      
      const result = await this.jiraService.testConnection();
      
      return {
        content: [
          {
            type: "text",
            text: result.success 
              ? `✅ JIRA connection successful!\nConnected as: ${result.user.displayName} (${result.user.emailAddress})`
              : `❌ JIRA connection failed: ${result.error}`
          }
        ]
      };
    } catch (error) {
      return {
        content: [
          {
            type: "text",
            text: `❌ Connection test failed: ${error.message}`
          }
        ]
      };
    }
  }

  async handleAnalyzeIssues(args) {
    const { projectKey, focusAreas = [], maxResults = 25 } = args;
    
    this.validateConfiguration();
    
    const filters = { projectKey };
    const issues = await this.jiraService.fetchIssues(filters, maxResults);
    const analysis = this.jiraService.analyzeIssuesForClaude(issues, focusAreas);
    
    return {
      content: [
        {
          type: "text",
          text: analysis
        }
      ]
    };
  }

  validateConfiguration() {
    const required = ['JIRA_DOMAIN', 'JIRA_EMAIL', 'JIRA_API_TOKEN'];
    const missing = required.filter(key => !process.env[key]);
    
    if (missing.length > 0) {
      throw new Error(
        `Missing required environment variables: ${missing.join(', ')}. ` +
        'Please configure JIRA credentials in the parent directory .env file.'
      );
    }
  }

  async run() {
    const transport = new StdioServerTransport();
    await this.server.connect(transport);
    
    // Log server start to stderr so it doesn't interfere with MCP protocol
    console.error("JIRA MCP Server running on stdio");
  }
}

const server = new JiraMcpServer();
server.run().catch((error) => {
  console.error("Server failed to start:", error);
  process.exit(1);
});