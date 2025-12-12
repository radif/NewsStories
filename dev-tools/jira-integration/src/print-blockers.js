#!/usr/bin/env node

import dotenv from 'dotenv';
import { JiraClient } from './jira-client.js';
import { IssueFormatter } from './issue-formatter.js';
import chalk from 'chalk';

// Load environment variables
dotenv.config();

/**
 * Custom priority sorting function
 * Priority order: Blocker > High > Medium > Low
 */
function sortIssuesByPriority(issues) {
  const priorityOrder = {
    'Blocker': 1,
    'High': 2,
    'Medium': 3,
    'Low': 4
  };
  
  return issues.sort((a, b) => {
    const aPriority = a.fields.priority?.name || 'Low';
    const bPriority = b.fields.priority?.name || 'Low';
    
    const aOrder = priorityOrder[aPriority] || 5;
    const bOrder = priorityOrder[bPriority] || 5;
    
    // If priorities are the same, sort by updated date (most recent first)
    if (aOrder === bOrder) {
      return new Date(b.fields.updated) - new Date(a.fields.updated);
    }
    
    return aOrder - bOrder;
  });
}

async function printBlockers() {
  console.log(chalk.blue.bold('🚫 JIRA Issues (Priority Sorted)\n'));

  // Validate configuration
  const requiredEnvVars = ['JIRA_DOMAIN', 'JIRA_EMAIL', 'JIRA_API_TOKEN', 'PROJECT_KEY'];
  const missingVars = requiredEnvVars.filter(varName => !process.env[varName]);
  
  if (missingVars.length > 0) {
    console.error(chalk.red('❌ Missing required environment variables:'));
    missingVars.forEach(varName => {
      console.error(chalk.red(`   - ${varName}`));
    });
    console.error(chalk.yellow('\n💡 Copy .env.example to .env and fill in your values'));
    process.exit(1);
  }

  try {
    // Initialize JIRA client
    console.log(chalk.blue('🔌 Connecting to JIRA...'));
    const jiraClient = new JiraClient(
      process.env.JIRA_DOMAIN,
      process.env.JIRA_EMAIL,
      process.env.JIRA_API_TOKEN
    );

    // Test connection
    const connected = await jiraClient.testConnection();
    if (!connected) {
      process.exit(1);
    }

    // Build search filters
    const filters = {
      projectKey: process.env.PROJECT_KEY,
      assignee: process.env.ASSIGNEE || null,
      status: process.env.STATUS_FILTER || process.env.STATUS_FILTERS || null,
      issueType: process.env.ISSUE_TYPE_FILTER || null
    };

    // Build JQL query WITHOUT priority sorting (we'll sort manually)
    const jql = jiraClient.buildJQL(filters).replace(' ORDER BY priority DESC, updated DESC', ' ORDER BY updated DESC');
    const maxResults = parseInt(process.env.MAX_RESULTS) || 50;

    console.log(chalk.blue(`\n🔍 Searching for issues...`));
    console.log(chalk.gray(`JQL: ${jql}`));
    console.log(chalk.gray(`Max Results: ${maxResults}\n`));

    // Search for issues
    const searchResults = await jiraClient.searchIssues(jql, maxResults);
    let issues = searchResults.issues;

    if (issues.length === 0) {
      console.log(chalk.yellow('⚠️  No issues found matching the criteria'));
      process.exit(0);
    }

    // Sort issues by custom priority order
    issues = sortIssuesByPriority(issues);

    // Format for Claude and display on screen (same format as the .md files)
    console.log(chalk.blue('─'.repeat(80)));
    const claudeFormatted = IssueFormatter.formatForClaude(issues);
    console.log(claudeFormatted);

  } catch (error) {
    console.error(chalk.red('❌ Error fetching issues:'));
    console.error(chalk.red(error.message));
    
    if (error.response?.status === 401) {
      console.error(chalk.yellow('\n💡 Authentication failed. Check your email and API token.'));
      console.error(chalk.yellow('   Generate a new API token at: https://id.atlassian.com/manage-profile/security/api-tokens'));
    } else if (error.response?.status === 403) {
      console.error(chalk.yellow('\n💡 Access denied. Check your project permissions.'));
    }
    
    process.exit(1);
  }
}

// Handle process termination
process.on('SIGINT', () => {
  console.log(chalk.yellow('\n\n👋 Print cancelled by user'));
  process.exit(0);
});

// Run the main function
printBlockers().catch(error => {
  console.error(chalk.red('Fatal error:'), error);
  process.exit(1);
});