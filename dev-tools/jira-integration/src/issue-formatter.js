import chalk from 'chalk';

export class IssueFormatter {
  
  /**
   * Format issues for Claude Code analysis
   */
  static formatForClaude(issues) {
    let output = '';
    
    output += '# JIRA Issues for Claude Code Analysis\n\n';
    output += `Found ${issues.length} issues to analyze:\n\n`;
    
    issues.forEach((issue, index) => {
      output += this.formatSingleIssue(issue, index + 1);
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
  static formatSingleIssue(issue, index) {
    const fields = issue.fields;
    let output = '';
    
    output += `## ${index}. ${issue.key}: ${fields.summary}\n\n`;
    
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
      // Convert Atlassian Document Format to readable text
      output += this.convertDescription(fields.description);
      output += '\n\n';
    }
    
    // Issue URL
    output += `**JIRA URL:** https://${process.env.JIRA_DOMAIN}/browse/${issue.key}\n`;
    
    return output;
  }

  /**
   * Convert Atlassian Document Format to readable text
   */
  static convertDescription(description) {
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

  /**
   * Format issues for console display
   */
  static formatForConsole(issues) {
    console.log(chalk.blue.bold(`\n📋 Found ${issues.length} JIRA Issues:\n`));
    
    issues.forEach((issue, index) => {
      const fields = issue.fields;
      const priority = fields.priority?.name || 'None';
      const priorityColor = this.getPriorityColor(priority);
      
      console.log(chalk.white.bold(`${index + 1}. ${issue.key}: ${fields.summary}`));
      console.log(chalk.gray(`   Type: ${fields.issuetype.name} | Status: ${fields.status.name}`));
      console.log(priorityColor(`   Priority: ${priority} | Assignee: ${fields.assignee?.displayName || 'Unassigned'}`));
      console.log(chalk.gray(`   Updated: ${new Date(fields.updated).toLocaleDateString()}`));
      console.log('');
    });
  }

  /**
   * Get color for priority display
   */
  static getPriorityColor(priority) {
    switch (priority.toLowerCase()) {
      case 'highest':
      case 'critical':
        return chalk.red.bold;
      case 'high':
        return chalk.red;
      case 'medium':
        return chalk.yellow;
      case 'low':
        return chalk.green;
      case 'lowest':
        return chalk.gray;
      default:
        return chalk.white;
    }
  }

  /**
   * Create summary statistics
   */
  static createSummary(issues) {
    const stats = {
      total: issues.length,
      byStatus: {},
      byType: {},
      byPriority: {},
      byAssignee: {}
    };
    
    issues.forEach(issue => {
      const fields = issue.fields;
      
      // Count by status
      const status = fields.status.name;
      stats.byStatus[status] = (stats.byStatus[status] || 0) + 1;
      
      // Count by type
      const type = fields.issuetype.name;
      stats.byType[type] = (stats.byType[type] || 0) + 1;
      
      // Count by priority
      const priority = fields.priority?.name || 'None';
      stats.byPriority[priority] = (stats.byPriority[priority] || 0) + 1;
      
      // Count by assignee
      const assignee = fields.assignee?.displayName || 'Unassigned';
      stats.byAssignee[assignee] = (stats.byAssignee[assignee] || 0) + 1;
    });
    
    return stats;
  }
}