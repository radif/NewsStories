#!/usr/bin/env node

import { JiraService } from './jira-service.js';
import dotenv from 'dotenv';
import chalk from 'chalk';

// Load environment variables from parent directory
dotenv.config({ path: '../.env' });

async function testConnection() {
  console.log(chalk.blue.bold('🧪 Testing JIRA MCP Server Connection\n'));
  
  // Check environment variables
  const required = ['JIRA_DOMAIN', 'JIRA_EMAIL', 'JIRA_API_TOKEN'];
  const missing = required.filter(key => !process.env[key]);
  
  if (missing.length > 0) {
    console.error(chalk.red('❌ Missing required environment variables:'));
    missing.forEach(key => console.error(chalk.red(`   - ${key}`)));
    console.error(chalk.yellow('\n💡 Make sure the parent directory has a .env file with JIRA credentials'));
    process.exit(1);
  }
  
  console.log(chalk.green('✅ Environment variables found'));
  console.log(chalk.gray(`   Domain: ${process.env.JIRA_DOMAIN}`));
  console.log(chalk.gray(`   Email: ${process.env.JIRA_EMAIL}`));
  console.log(chalk.gray(`   API Token: ${'*'.repeat(process.env.JIRA_API_TOKEN.length)}\n`));
  
  try {
    const jiraService = new JiraService();
    
    console.log(chalk.blue('🔌 Testing JIRA connection...'));
    const result = await jiraService.testConnection();
    
    if (result.success) {
      console.log(chalk.green('✅ JIRA connection successful!'));
      console.log(chalk.blue(`👤 Connected as: ${result.user.displayName} (${result.user.emailAddress})`));
      
      // Test a simple query if PROJECT_KEY is available
      if (process.env.PROJECT_KEY) {
        console.log(chalk.blue(`\n🔍 Testing issue fetch for project: ${process.env.PROJECT_KEY}`));
        
        const issues = await jiraService.fetchIssues({ projectKey: process.env.PROJECT_KEY }, 5);
        console.log(chalk.green(`✅ Successfully fetched ${issues.length} issues`));
        
        if (issues.length > 0) {
          console.log(chalk.gray('\n📋 Sample issues:'));
          issues.slice(0, 3).forEach(issue => {
            console.log(chalk.gray(`   - ${issue.key}: ${issue.fields.summary}`));
          });
        }
      }
      
      console.log(chalk.green.bold('\n🎉 MCP Server is ready to use!'));
      
    } else {
      console.error(chalk.red('❌ JIRA connection failed:'));
      console.error(chalk.red(`   ${result.error}`));
      
      if (result.error.includes('401')) {
        console.error(chalk.yellow('\n💡 Authentication error - check your email and API token'));
        console.error(chalk.yellow('   Generate a new token at: https://id.atlassian.com/manage-profile/security/api-tokens'));
      }
      
      process.exit(1);
    }
    
  } catch (error) {
    console.error(chalk.red('❌ Test failed:'));
    console.error(chalk.red(error.message));
    process.exit(1);
  }
}

testConnection();