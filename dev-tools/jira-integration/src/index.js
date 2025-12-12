#!/usr/bin/env node

import inquirer from 'inquirer';
import chalk from 'chalk';
import { exec } from 'child_process';
import { promisify } from 'util';
import fs from 'fs';

const execAsync = promisify(exec);

async function main() {
  console.log(chalk.blue.bold('🎯 JIRA-Claude Integration Tool\n'));
  
  // Check if .env exists
  const envExists = fs.existsSync('.env');
  
  if (!envExists) {
    console.log(chalk.yellow('⚠️  No configuration found. Let\'s set up your JIRA connection first.\n'));
    
    const { setupNow } = await inquirer.prompt([
      {
        type: 'confirm',
        name: 'setupNow',
        message: 'Would you like to configure JIRA connection now?',
        default: true
      }
    ]);
    
    if (setupNow) {
      try {
        await execAsync('node src/setup-config.js');
      } catch (error) {
        console.error(chalk.red('Setup failed:'), error.message);
        process.exit(1);
      }
    } else {
      console.log(chalk.blue('\n📝 Manual setup:'));
      console.log(chalk.white('1. Copy .env.example to .env'));
      console.log(chalk.white('2. Fill in your JIRA credentials'));
      console.log(chalk.white('3. Run this tool again'));
      process.exit(0);
    }
  }

  // Main menu
  while (true) {
    console.log(chalk.blue.bold('\n🚀 What would you like to do?\n'));
    
    const { action } = await inquirer.prompt([
      {
        type: 'list',
        name: 'action',
        message: 'Choose an action:',
        choices: [
          { name: '📥 Fetch Issues from JIRA', value: 'fetch' },
          { name: '⚙️  Reconfigure JIRA Connection', value: 'config' },
          { name: '📋 View Last Fetched Issues', value: 'view' },
          { name: '❓ Help & Instructions', value: 'help' },
          { name: '👋 Exit', value: 'exit' }
        ]
      }
    ]);

    switch (action) {
      case 'fetch':
        console.log(chalk.blue('\n🔄 Fetching issues from JIRA...\n'));
        try {
          await execAsync('node src/fetch-issues.js');
        } catch (error) {
          console.error(chalk.red('Fetch failed:'), error.message);
        }
        break;

      case 'config':
        console.log(chalk.blue('\n⚙️  Reconfiguring JIRA connection...\n'));
        try {
          await execAsync('node src/setup-config.js');
        } catch (error) {
          console.error(chalk.red('Configuration failed:'), error.message);
        }
        break;

      case 'view':
        await viewLastFetchedIssues();
        break;

      case 'help':
        showHelp();
        break;

      case 'exit':
        console.log(chalk.blue('\n👋 Goodbye!'));
        process.exit(0);
    }
  }
}

async function viewLastFetchedIssues() {
  console.log(chalk.blue('\n📋 Looking for previously fetched issues...\n'));
  
  if (!fs.existsSync('output')) {
    console.log(chalk.yellow('❌ No output directory found. Run "Fetch Issues" first.'));
    return;
  }

  const files = fs.readdirSync('output')
    .filter(file => file.startsWith('jira-issues-') && file.endsWith('.md'))
    .sort()
    .reverse(); // Most recent first

  if (files.length === 0) {
    console.log(chalk.yellow('❌ No issue files found. Run "Fetch Issues" first.'));
    return;
  }

  const { selectedFile } = await inquirer.prompt([
    {
      type: 'list',
      name: 'selectedFile',
      message: 'Select an issue file to view:',
      choices: files.map(file => {
        const timestamp = file.replace('jira-issues-', '').replace('.md', '');
        return {
          name: `${file} (${new Date(timestamp.replace(/-/g, ':')).toLocaleString()})`,
          value: file
        };
      })
    }
  ]);

  const content = fs.readFileSync(`output/${selectedFile}`, 'utf8');
  const lines = content.split('\n');
  
  // Show first few lines as preview
  console.log(chalk.blue('\n📄 File preview (first 20 lines):\n'));
  console.log(chalk.gray(lines.slice(0, 20).join('\n')));
  
  if (lines.length > 20) {
    console.log(chalk.gray(`\n... and ${lines.length - 20} more lines`));
  }
  
  console.log(chalk.blue(`\n📁 Full file location: output/${selectedFile}`));
  
  const { openFile } = await inquirer.prompt([
    {
      type: 'confirm',
      name: 'openFile',
      message: 'Would you like to copy the file path to clipboard?',
      default: false
    }
  ]);
  
  if (openFile) {
    const fullPath = `${process.cwd()}/output/${selectedFile}`;
    console.log(chalk.green(`\n📋 Copy this path: ${fullPath}`));
    console.log(chalk.blue('💡 Open this file and copy its contents to Claude Code'));
  }
}

function showHelp() {
  console.log(chalk.blue.bold('\n📚 JIRA-Claude Integration Help\n'));
  
  console.log(chalk.white.bold('🎯 Purpose:'));
  console.log(chalk.white('This tool fetches JIRA issues and formats them for Claude Code analysis.\n'));
  
  console.log(chalk.white.bold('🔧 Setup:'));
  console.log(chalk.white('1. Get your JIRA API token from: https://id.atlassian.com/manage-profile/security/api-tokens'));
  console.log(chalk.white('2. Run the configuration wizard (⚙️  Reconfigure option)'));
  console.log(chalk.white('3. Or manually edit the .env file\n'));
  
  console.log(chalk.white.bold('📥 Fetching Issues:'));
  console.log(chalk.white('- Issues are fetched based on your configured filters'));
  console.log(chalk.white('- Results are saved to the output/ directory'));
  console.log(chalk.white('- Both markdown (for Claude) and JSON (raw data) files are created\n'));
  
  console.log(chalk.white.bold('🤖 Using with Claude:'));
  console.log(chalk.white('1. Fetch issues using this tool'));
  console.log(chalk.white('2. Open the generated .md file from output/ directory'));
  console.log(chalk.white('3. Copy the entire content'));
  console.log(chalk.white('4. Paste into Claude Code and ask it to analyze/fix the issues\n'));
  
  console.log(chalk.white.bold('💡 Tips:'));
  console.log(chalk.white('- Start with a small number of issues (10-20) for better results'));
  console.log(chalk.white('- Filter by priority or component to focus on specific areas'));
  console.log(chalk.white('- Include clear descriptions in your JIRA issues for better analysis'));
  console.log(chalk.white('- Use labels like "code", "bug", or "refactor" to help Claude understand context\n'));
  
  console.log(chalk.white.bold('⚙️  Configuration:'));
  console.log(chalk.white('- PROJECT_KEY: Your JIRA project identifier'));
  console.log(chalk.white('- ASSIGNEE: Filter by specific person (optional)'));
  console.log(chalk.white('- STATUS_FILTER: Filter by status like "In Progress" (optional)'));
  console.log(chalk.white('- ISSUE_TYPE_FILTER: Filter by type like "Bug" (optional)'));
  console.log(chalk.white('- MAX_RESULTS: Limit number of issues fetched (default: 50)\n'));
}

// Handle process termination gracefully
process.on('SIGINT', () => {
  console.log(chalk.yellow('\n\n👋 Goodbye!'));
  process.exit(0);
});

main().catch(error => {
  console.error(chalk.red('Fatal error:'), error);
  process.exit(1);
});