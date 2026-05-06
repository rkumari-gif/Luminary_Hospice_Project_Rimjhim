# Luminary_Hospice_Project_Rimjhim
Luminary_Hospice_Project_Rimjhim

-- Switch to a role that can create integrations
USE ROLE ACCOUNTADMIN;

-- Create a secret with your GitHub PAT
CREATE OR REPLACE SECRET LUMINARY_HOSPICE_DEV.PUBLIC.GITHUB_PAT_SECRET
  TYPE = PASSWORD
  USERNAME = 'rkumari-gif'
  PASSWORD = '<paste_your_personal_access_token_here>';

-- Create the API integration for GitHub
CREATE OR REPLACE API INTEGRATION GITHUB_API_INTEGRATION
  API_PROVIDER = git_https_api
  API_ALLOWED_PREFIXES = ('https://github.com/rkumari-gif')
  ALLOWED_AUTHENTICATION_SECRETS = (LUMINARY_HOSPICE_DEV.PUBLIC.GITHUB_PAT_SECRET)
  ENABLED = TRUE;

-- Grant usage to your role
GRANT USAGE ON INTEGRATION GITHUB_API_INTEGRATION TO ROLE SYSADMIN;
GRANT USAGE ON SECRET LUMINARY_HOSPICE_DEV.PUBLIC.GITHUB_PAT_SECRET TO ROLE SYSADMIN;


GitHub: Create README (initial commit)
    ↓
Snowflake: Create Secret (PAT) + API Integration
    ↓
Snowsight: Create Workspace "From Git repository"
    ↓
Copy files from DEFAULT workspace → Git workspace
    ↓
Changes tab → Commit → Push
    ↓
✅ Code is on GitHub!

ls  luminary_hospice_dbt;

