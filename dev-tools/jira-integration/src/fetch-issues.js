#!/usr/bin/env node

import dotenv from 'dotenv';
import { JiraClient } from './jira-client.js';
import { IssueFormatter } from './issue-formatter.js';
import chalk from 'chalk';
import fs from 'fs';
import path from 'path';

// Load environment variables
dotenv.config();

async function main() {
  console.log(chalk.blue.bold('🎯 JIRA Issues Fetcher for Claude Code\n'));

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

    // Build JQL query
    const jql = jiraClient.buildJQL(filters);
    const maxResults = parseInt(process.env.MAX_RESULTS) || 50;

    console.log(chalk.blue(`\n🔍 Searching for issues...`));
    console.log(chalk.gray(`JQL: ${jql}`));
    console.log(chalk.gray(`Max Results: ${maxResults}\n`));

    // Search for issues
    const searchResults = await jiraClient.searchIssues(jql, maxResults);
    const issues = searchResults.issues;

    if (issues.length === 0) {
      console.log(chalk.yellow('⚠️  No issues found matching the criteria'));
      process.exit(0);
    }

    // Display summary in console
    IssueFormatter.formatForConsole(issues);

    // Create statistics
    const stats = IssueFormatter.createSummary(issues);
    console.log(chalk.blue.bold('📊 Issue Statistics:'));
    console.log(chalk.white(`Total Issues: ${stats.total}`));
    
    console.log(chalk.white('\nBy Status:'));
    Object.entries(stats.byStatus).forEach(([status, count]) => {
      console.log(chalk.gray(`  ${status}: ${count}`));
    });
    
    console.log(chalk.white('\nBy Type:'));
    Object.entries(stats.byType).forEach(([type, count]) => {
      console.log(chalk.gray(`  ${type}: ${count}`));
    });
    
    console.log(chalk.white('\nBy Priority:'));
    Object.entries(stats.byPriority).forEach(([priority, count]) => {
      const color = IssueFormatter.getPriorityColor(priority);
      console.log(color(`  ${priority}: ${count}`));
    });

    // Format for Claude and save to file
    console.log(chalk.blue('\n📝 Formatting issues for Claude Code...'));
    const claudeFormatted = IssueFormatter.formatForClaude(issues);
    
    // Create output directory if it doesn't exist
    const outputDir = 'output';
    if (!fs.existsSync(outputDir)) {
      fs.mkdirSync(outputDir);
    }
    
    // Save formatted output
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, -5);
    const filename = `jira-issues-${timestamp}.md`;
    const filepath = path.join(outputDir, filename);
    
    fs.writeFileSync(filepath, claudeFormatted);
    
    console.log(chalk.green(`✅ Issues saved to: ${filepath}`));
    console.log(chalk.blue('\n🤖 Next steps:'));
    console.log(chalk.white('1. Open the generated markdown file'));
    console.log(chalk.white('2. Copy the content to Claude Code'));
    console.log(chalk.white('3. Ask Claude to analyze and fix the issues'));
    
    // Also save raw JSON for reference
    const jsonFilename = `jira-issues-raw-${timestamp}.json`;
    const jsonFilepath = path.join(outputDir, jsonFilename);
    fs.writeFileSync(jsonFilepath, JSON.stringify({ searchResults, stats }, null, 2));
    
    console.log(chalk.gray(`\n📄 Raw data saved to: ${jsonFilepath}`));

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
  console.log(chalk.yellow('\n\n👋 Fetch cancelled by user'));
  process.exit(0);
});

// Run the main function
main().catch(error => {
  console.error(chalk.red('Fatal error:'), error);
  process.exit(1);
});