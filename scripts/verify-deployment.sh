#!/bin/bash
# "Is anything actually deployed?" script
# replace once live
BASE="https://al-domain.vercel.app"  # replace with actual domain

echo "🔍 Testing deployment at $BASE..."

# Test landing page
echo "Testing landing page..."
curl -sf "$BASE/" > /dev/null && echo "✅ Landing page accessible" || echo "❌ Landing page failed"

# Test apply page  
echo "Testing apply page..."
curl -sf "$BASE/apply" > /dev/null && echo "✅ Apply page accessible" || echo "❌ Apply page failed"

# Test API endpoint exists (should return 405 for GET)
echo "Testing API endpoint..."
status=$(curl -s -o /dev/null -w "%{http_code}" "$BASE/api/apply")
if [[ "$status" == "405" ]]; then
    echo "✅ API endpoint exists (returns 405 for GET as expected)"
else
    echo "❌ API endpoint issue (status: $status)"
fi

# Test form submission (mock data)
echo "Testing form submission..."
response=$(curl -sf -X POST "$BASE/api/apply" \
  -H "Content-Type: application/json" \
  -d '{
    "fullName": "Test User",
    "email": "test@example.com", 
    "role": "Developer",
    "location": "Remote",
    "experienceYears": 5,
    "skills": "JavaScript",
    "motivation": "Testing the form submission",
    "availability": "10 hrs/week",
    "consent": true
  }')

if [[ $? -eq 0 ]]; then
    echo "✅ Form submission successful"
else
    echo "❌ Form submission failed"
fi

echo "Deployment verification complete."