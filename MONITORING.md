# AL Monitoring Kit

This directory contains automation and monitoring tools for the AL project.

## Files Added

### GitHub Workflows
- **`.github/workflows/progress-heartbeat.yml`** - Daily cron job (10 AM ET) that checks for repository activity and posts reminder comments on issue #1 if no PRs or issues have been updated in 24 hours.

### Issue & PR Templates  
- **`.github/ISSUE_TEMPLATE/task.yml`** - Structured issue form for creating concrete, shippable tasks with required fields for goal, plan, and links.
- **`.github/pull_request_template.md`** - Standard PR template requiring What/How/Test/Links sections.

### Scripts
- **`scripts/verify-deployment.sh`** - Deployment verification script that tests landing page, apply page, API endpoint, and form submission. Update the `BASE` URL when deployed.
- **`scripts/setup-labels.sh`** - Script to create standard repository labels for status tracking and work categorization.

## Setup Instructions

1. **Run label setup** (requires GitHub CLI):
   ```bash
   ./scripts/setup-labels.sh
   ```

2. **Update deployment verification** when live:
   ```bash
   # Edit scripts/verify-deployment.sh and replace:
   BASE="https://al-domain.vercel.app"  # with your actual domain
   ```

3. **Create project board** (manual):
   - Go to repository → Projects → Create "AL Delivery" 
   - Add milestone issues to track progress

## How It Works

- **Progress heartbeat** automatically monitors for stalled work and nudges team
- **Issue templates** ensure consistent task creation with required information  
- **PR template** enforces documentation of changes and testing evidence
- **Verification script** validates deployment functionality end-to-end
- **Labels** provide clear status and categorization for work items

The monitoring kit provides "signal instead of mystery" by automating progress tracking and enforcing consistent documentation standards.