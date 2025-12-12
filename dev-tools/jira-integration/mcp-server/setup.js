#!/usr/bin/env node

import { execSync } from 'child_process';
import fs from 'fs';
import path from 'path';
import chalk from 'chalk';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

async function setup() {
  console.log(chalk.blue.bold('🚀 JIRA MCP Server Setup\n'));
  
  try {
    // Install dependencies
    console.log(chalk.blue('📦 Installing dependencies...'));
    execSync('npm install', { stdio: 'inherit', cwd: __dirname });
    console.log(chalk.green('✅ Dependencies installed\n'));
    
    // Check parent .env file
    const parentEnvPath = path.join(__dirname, '../.env');
    if (!fs.existsSync(parentEnvPath)) {
      console.log(chalk.yellow('⚠️  No .env file found in parent directory'));
      console.log(chalk.blue('💡 You need to configure JIRA credentials first:'));
      console.log(chalk.gray('   cd ../'));
      console.log(chalk.gray('   npm run config'));
      console.log(chalk.gray('   # or manually create .env with JIRA credentials\n'));
    } else {
      console.log(chalk.green('✅ Found .env configuration file\n'));
      
      // Test connection
      console.log(chalk.blue('🧪 Testing JIRA connection...'));
      try {
        execSync('npm test', { stdio: 'inherit', cwd: __dirname });
        console.log(chalk.green('\n✅ JIRA connection test passed'));
      } catch (error) {
        console.log(chalk.yellow('\n⚠️  JIRA connection test failed'));
        console.log(chalk.gray('   You may need to update your JIRA credentials'));
      }
    }
    
    // Generate Claude Code configuration
    const configPath = path.join(__dirname, 'claude-code-config.json');
    const serverPath = path.join(__dirname, 'src/index.js');
    
    const config = {
      mcpServers: {
        jira: {
          command: "node",
          args: [serverPath],
          env: {
            NODE_ENV: "production"
          }
        }
      }
    };
    
    fs.writeFileSync(configPath, JSON.stringify(config, null, 2));
    console.log(chalk.green(`✅ Generated Claude Code configuration: ${configPath}`));
    
    // Instructions
    console.log(chalk.blue.bold('\n🎯 Next Steps:\n'));
    console.log(chalk.white('1. Add the MCP server to your Claude Code configuration:'));
    console.log(chalk.gray(`   Copy the contents of: ${configPath}`));
    console.log(chalk.gray('   Add to your Claude Code settings under "mcpServers"\n'));
    
    console.log(chalk.white('2. Restart Claude Code to load the MCP server\n'));
    
    console.log(chalk.white('3. Test the integration:'));
    console.log(chalk.gray('   "Use jira_test_connection to verify JIRA is working"'));
    console.log(chalk.gray('   "Use jira_fetch_issues with projectKey TLW to get issues"\n'));
    
    console.log(chalk.white('4. Example usage:'));
    console.log(chalk.gray('   "Analyze current sprint issues for TLW project"'));
    console.log(chalk.gray('   "Get details for issue TLW-347"'));
    console.log(chalk.gray('   "Fetch all high-priority bugs in TLW project"\n'));
    
    console.log(chalk.green.bold('🎉 Setup complete! Your JIRA MCP server is ready to use.'));
    
  } catch (error) {
    console.error(chalk.red('❌ Setup failed:'));
    console.error(chalk.red(error.message));
    process.exit(1);
  }
}

setup();