#!/bin/bash
# Setup labels for repository
echo "Creating repository labels..."

gh label create "status:blocked"       -c "#d73a4a" -d "Work cannot proceed due to external dependencies" || true
gh label create "status:in-progress"   -c "#1d76db" -d "Actively being worked on" || true  
gh label create "status:needs-review"  -c "#fbca04" -d "Ready for review" || true
gh label create "type:frontend"        -c "#5319e7" -d "Frontend/UI related work" || true
gh label create "type:infra"           -c "#0e8a16" -d "Infrastructure and deployment" || true

echo "Labels created successfully!"
echo ""
echo "To create a project board:"
echo "1. Go to your repository on GitHub"
echo "2. Click on 'Projects' tab"  
echo "3. Create new project named 'AL Delivery'"
echo "4. Add milestone issues to the board"