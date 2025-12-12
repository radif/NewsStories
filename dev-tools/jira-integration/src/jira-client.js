import axios from 'axios';
import chalk from 'chalk';

export class JiraClient {
  constructor(domain, email, apiToken) {
    this.domain = domain;
    this.email = email;
    this.apiToken = apiToken;
    this.baseUrl = `https://${domain}/rest/api/3`;
    
    // Create axios instance with authentication
    this.client = axios.create({
      baseURL: this.baseUrl,
      auth: {
        username: email,
        password: apiToken
      },
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json'
      }
    });
  }

  /**
   * Test connection to JIRA
   */
  async testConnection() {
    try {
      const response = await this.client.get('/myself');
      console.log(chalk.green('✓ JIRA connection successful!'));
      console.log(chalk.blue(`Connected as: ${response.data.displayName} (${response.data.emailAddress})`));
      return true;
    } catch (error) {
      console.error(chalk.red('✗ JIRA connection failed:'));
      console.error(chalk.red(error.response?.data?.message || error.message));
      return false;
    }
  }

  /**
   * Search for issues using JQL (updated to use v3 search/jql endpoint)
   */
  async searchIssues(jql, maxResults = 50) {
    try {
      console.log(chalk.blue(`Searching issues with JQL: ${jql}`));

      // Use the new /search/jql endpoint with POST method
      const response = await this.client.post('/search/jql', {
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
          'fixVersions'
        ]
      });

      console.log(chalk.green(`✓ Found ${response.data.total} issues (showing ${response.data.issues.length})`));
      return response.data;

    } catch (error) {
      console.error(chalk.red('✗ Failed to search issues:'));
      console.error(chalk.red(error.response?.data?.errorMessages?.[0] || error.message));
      throw error;
    }
  }

  /**
   * Get a specific issue by key
   */
  async getIssue(issueKey) {
    try {
      const response = await this.client.get(`/issue/${issueKey}`);
      return response.data;
    } catch (error) {
      console.error(chalk.red(`✗ Failed to get issue ${issueKey}:`));
      console.error(chalk.red(error.response?.data?.errorMessages?.[0] || error.message));
      throw error;
    }
  }

  /**
   * Get projects accessible to the user
   */
  async getProjects() {
    try {
      const response = await this.client.get('/project');
      return response.data;
    } catch (error) {
      console.error(chalk.red('✗ Failed to get projects:'));
      console.error(chalk.red(error.response?.data?.message || error.message));
      throw error;
    }
  }

  /**
   * Build JQL query based on filters
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
      // Handle comma-separated status filters
      const statuses = filters.status.split(',').map(s => s.trim()).filter(s => s.length > 0);
      if (statuses.length === 1) {
        conditions.push(`status = "${statuses[0]}"`);
      } else if (statuses.length > 1) {
        const statusConditions = statuses.map(status => `"${status}"`).join(', ');
        conditions.push(`status IN (${statusConditions})`);
      }
    }
    
    if (filters.issueType) {
      conditions.push(`issuetype = "${filters.issueType}"`);
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
}