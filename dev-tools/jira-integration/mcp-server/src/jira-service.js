import axios from 'axios';

export class JiraService {
  constructor() {
    this.domain = process.env.JIRA_DOMAIN;
    this.email = process.env.JIRA_EMAIL;
    this.apiToken = process.env.JIRA_API_TOKEN;
    this.baseUrl = `https://${this.domain}/rest/api/3`;
    
    if (this.domain && this.email && this.apiToken) {
      this.client = axios.create({
        baseURL: this.baseUrl,
        auth: {
          username: this.email,
          password: this.apiToken
        },
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json'
        }
      });
    }
  }

  /**
   * Test connection to JIRA
   */
  async testConnection() {
    try {
      if (!this.client) {
        return { success: false, error: 'JIRA client not configured' };
      }
      
      const response = await this.client.get('/myself');
      return { 
        success: true, 
        user: {
          displayName: response.data.displayName,
          emailAddress: response.data.emailAddress
        }
      };
    } catch (error) {
      return { 
        success: false, 
        error: error.response?.data?.message || error.message 
      };
    }
  }

  /**
   * Fetch issues with filters
   */
  async fetchIssues(filters, maxResults = 50) {
    const jql = this.buildJQL(filters);
    
    const response = await this.client.get('/search', {
      params: {
        jql: jql,
        maxResults: maxResults,
        fields: [
          'key',
          'summary', 
          'description',
          'status',
          'priority',
          'issuetype',
          'assignee',
          'reporter',
          'created',
          'updated',
          'components',
          'labels',
          'fixVersions',
          'comment'
        ].join(',')
      }
    });

    return response.data.issues;
  }

  /**
   * Get a specific issue
   */
  async getIssue(issueKey) {
    const response = await this.client.get(`/issue/${issueKey}`, {
      params: {
        fields: [
          'key',
          'summary', 
          'description',
          'status',
          'priority',
          'issuetype',
          'assignee',
          'reporter',
          'created',
          'updated',
          'components',
          'labels',
          'fixVersions',
          'comment'
        ].join(',')
      }
    });
    
    return response.data;
  }

  /**
   * Build JQL query from filters
   */
  buildJQL(filters) {
    const conditions = [];
    
    if (filters.projectKey) {
      conditions.push(`project = "${filters.projectKey}"`);
    }
    
    if (filters.assignee) {
      conditions.push(`assignee = "${filters.assignee}"`);
    }
    
    if (filters.status) {
      conditions.push(`status = "${filters.status}"`);
    }
    
    if (filters.issueType) {
      conditions.push(`issuetype = "${filters.issueType}"`);
    }
    
    if (filters.priority) {
      conditions.push(`priority = "${filters.priority}"`);
    }
    
    // Default to open issues if no status specified
    if (!filters.status) {
      conditions.push('status != "Done" AND status != "Closed"');
    }
    
    let jql = conditions.join(' AND ');
    
    // Add ordering
    jql += ' ORDER BY priority DESC, updated DESC';
    
    return jql;
  }

  /**
   * Format issues for Claude Code analysis
   */
  formatIssuesForClaude(issues) {
    let output = '';
    
    output += '# JIRA Issues for Claude Code Analysis\n\n';
    output += `Found ${issues.length} issues to analyze:\n\n`;
    
    issues.forEach((issue, index) => {
      output += this.formatSingleIssueForClaude(issue, index + 1);
      output += '\n---\n\n';
    });
    
    output += '## Instructions for Claude\n\n';
    output += 'Please analyze these JIRA issues and:\n';
    output += '1. Identify which issues are code-related and can be fixed\n';
    output += '2. Prioritize them by complexity and impact\n';
    output += '3. For each fixable issue, provide the file paths and changes needed\n';
    output += '4. Create a plan for addressing multiple related issues together\n\n';
    output += 'Focus on issues related to "The Last Word" Unity project structure.\n';
    
    return output;
  }

  /**
   * Format a single issue for Claude
   */
  formatSingleIssueForClaude(issue, index = null) {
    const fields = issue.fields;
    let output = '';
    
    const title = index ? `## ${index}. ${issue.key}: ${fields.summary}` : `## ${issue.key}: ${fields.summary}`;
    output += `${title}\n\n`;
    
    // Basic info
    output += `**Type:** ${fields.issuetype.name}\n`;
    output += `**Status:** ${fields.status.name}\n`;
    output += `**Priority:** ${fields.priority?.name || 'None'}\n`;
    output += `**Assignee:** ${fields.assignee?.displayName || 'Unassigned'}\n`;
    output += `**Reporter:** ${fields.reporter?.displayName || 'Unknown'}\n`;
    output += `**Created:** ${new Date(fields.created).toLocaleDateString()}\n`;
    output += `**Updated:** ${new Date(fields.updated).toLocaleDateString()}\n\n`;
    
    // Components and labels
    if (fields.components && fields.components.length > 0) {
      output += `**Components:** ${fields.components.map(c => c.name).join(', ')}\n`;
    }
    
    if (fields.labels && fields.labels.length > 0) {
      output += `**Labels:** ${fields.labels.join(', ')}\n`;
    }
    
    if (fields.fixVersions && fields.fixVersions.length > 0) {
      output += `**Fix Versions:** ${fields.fixVersions.map(v => v.name).join(', ')}\n`;
    }
    
    output += '\n';
    
    // Description
    if (fields.description) {
      output += '**Description:**\n';
      output += this.convertDescription(fields.description);
      output += '\n\n';
    }
    
    // Comments (latest few)
    if (fields.comment && fields.comment.comments && fields.comment.comments.length > 0) {
      output += '**Recent Comments:**\n';
      const recentComments = fields.comment.comments.slice(-3); // Last 3 comments
      recentComments.forEach(comment => {
        const author = comment.author?.displayName || 'Unknown';
        const date = new Date(comment.created).toLocaleDateString();
        output += `- **${author}** (${date}): ${this.convertDescription(comment.body)}\n`;
      });
      output += '\n';
    }
    
    // Issue URL
    output += `**JIRA URL:** https://${this.domain}/browse/${issue.key}\n`;
    
    return output;
  }

  /**
   * Analyze issues and provide structured output for Claude
   */
  analyzeIssuesForClaude(issues, focusAreas = []) {
    let output = '';
    
    output += '# JIRA Issues Analysis for Code Fixes\n\n';
    
    // Create categories
    const categories = {
      bugs: [],
      tasks: [],
      improvements: [],
      critical: [],
      codeRelated: []
    };
    
    // Categorize issues
    issues.forEach(issue => {
      const fields = issue.fields;
      const priority = fields.priority?.name?.toLowerCase() || '';
      const type = fields.issuetype.name.toLowerCase();
      const labels = fields.labels?.map(l => l.toLowerCase()) || [];
      const summary = fields.summary.toLowerCase();
      const description = this.convertDescription(fields.description).toLowerCase();
      
      // Check if issue is code-related
      const codeKeywords = ['bug', 'error', 'exception', 'crash', 'performance', 'ui', 'unity', 'code', 'script', 'method', 'class', 'function'];
      const isCodeRelated = codeKeywords.some(keyword => 
        summary.includes(keyword) || 
        description.includes(keyword) || 
        labels.includes(keyword)
      );
      
      if (isCodeRelated) categories.codeRelated.push(issue);
      if (priority.includes('critical') || priority.includes('highest')) categories.critical.push(issue);
      if (type.includes('bug')) categories.bugs.push(issue);
      if (type.includes('task') || type.includes('story')) categories.tasks.push(issue);
      if (type.includes('improvement') || type.includes('enhancement')) categories.improvements.push(issue);
    });
    
    // Summary
    output += `## Analysis Summary\n\n`;
    output += `- **Total Issues:** ${issues.length}\n`;
    output += `- **Code-Related Issues:** ${categories.codeRelated.length}\n`;
    output += `- **Critical Issues:** ${categories.critical.length}\n`;
    output += `- **Bugs:** ${categories.bugs.length}\n`;
    output += `- **Tasks:** ${categories.tasks.length}\n`;
    output += `- **Improvements:** ${categories.improvements.length}\n\n`;
    
    if (focusAreas.length > 0) {
      output += `**Focus Areas:** ${focusAreas.join(', ')}\n\n`;
    }
    
    // Prioritized recommendations
    output += `## Recommended Fix Priority\n\n`;
    
    // Critical code-related issues first
    const criticalCode = categories.critical.filter(issue => categories.codeRelated.includes(issue));
    if (criticalCode.length > 0) {
      output += `### 🔥 Critical Code Issues (Fix First)\n\n`;
      criticalCode.forEach((issue, index) => {
        output += this.formatSingleIssueForClaude(issue, index + 1);
        output += '\n---\n\n';
      });
    }
    
    // Then bugs
    const nonCriticalBugs = categories.bugs.filter(issue => !categories.critical.includes(issue));
    if (nonCriticalBugs.length > 0) {
      output += `### 🐛 Bug Fixes\n\n`;
      nonCriticalBugs.slice(0, 10).forEach((issue, index) => { // Limit to 10
        output += this.formatSingleIssueForClaude(issue, index + 1);
        output += '\n---\n\n';
      });
    }
    
    // Then improvements
    if (categories.improvements.length > 0) {
      output += `### ✨ Improvements & Enhancements\n\n`;
      categories.improvements.slice(0, 5).forEach((issue, index) => { // Limit to 5
        output += this.formatSingleIssueForClaude(issue, index + 1);
        output += '\n---\n\n';
      });
    }
    
    output += `## Claude Instructions\n\n`;
    output += `Please analyze the issues above and:\n`;
    output += `1. **Identify Actionable Items**: Focus on issues that can be resolved through code changes\n`;
    output += `2. **Prioritize by Impact**: Consider user experience and system stability\n`;
    output += `3. **Group Related Issues**: Find issues that can be fixed together\n`;
    output += `4. **Provide Implementation Plan**: For each fixable issue, specify:\n`;
    output += `   - Affected file paths in the Unity project\n`;
    output += `   - Specific code changes needed\n`;
    output += `   - Testing approach\n`;
    output += `5. **Estimate Complexity**: Categorize as Simple/Medium/Complex based on required changes\n\n`;
    output += `Focus on "The Last Word" Unity project structure and existing patterns.\n`;
    
    return output;
  }

  /**
   * Convert Atlassian Document Format to readable text
   */
  convertDescription(description) {
    if (typeof description === 'string') {
      return description;
    }
    
    if (!description || !description.content) {
      return 'No description provided.';
    }
    
    let text = '';
    
    const processContent = (content) => {
      content.forEach(node => {
        switch (node.type) {
          case 'paragraph':
            if (node.content) {
              node.content.forEach(inline => {
                if (inline.type === 'text') {
                  text += inline.text;
                }
              });
            }
            text += '\n\n';
            break;
            
          case 'codeBlock':
            text += '```\n';
            if (node.content) {
              node.content.forEach(inline => {
                if (inline.type === 'text') {
                  text += inline.text;
                }
              });
            }
            text += '\n```\n\n';
            break;
            
          case 'bulletList':
          case 'orderedList':
            if (node.content) {
              node.content.forEach(listItem => {
                text += '- ';
                if (listItem.content) {
                  listItem.content.forEach(paragraph => {
                    if (paragraph.content) {
                      paragraph.content.forEach(inline => {
                        if (inline.type === 'text') {
                          text += inline.text;
                        }
                      });
                    }
                  });
                }
                text += '\n';
              });
            }
            text += '\n';
            break;
            
          case 'heading':
            const level = node.attrs?.level || 1;
            text += '#'.repeat(level) + ' ';
            if (node.content) {
              node.content.forEach(inline => {
                if (inline.type === 'text') {
                  text += inline.text;
                }
              });
            }
            text += '\n\n';
            break;
            
          default:
            // Handle other node types generically
            if (node.content) {
              processContent(node.content);
            } else if (node.text) {
              text += node.text;
            }
        }
      });
    };
    
    processContent(description.content);
    return text.trim() || 'No description content found.';
  }
}