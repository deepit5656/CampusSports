# 🔐 Firestore Security Rules - Public Access Mode

## Overview

The app now supports **public browsing** - users can view all sports data without authentication. Only admins need to login to manage data.

## Required Firestore Rules

Copy and paste these rules into your Firebase Console → Firestore Database → Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper function to check if user is authenticated
    function isAuthenticated() {
      return request.auth != null;
    }
    
    // Helper function to check if user is admin
    function isAdmin() {
      return isAuthenticated() && 
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    // Users collection - only authenticated users can read/write their own data
    match /users/{userId} {
      allow read: if isAuthenticated() && request.auth.uid == userId;
      allow create: if isAuthenticated() && request.auth.uid == userId;
      allow update: if isAuthenticated() && request.auth.uid == userId;
      allow delete: if false; // Users cannot delete their own accounts
    }
    
    // Sports collection - Public read, admin write
    match /sports/{sportId} {
      allow read: if true; // Public read access
      allow create, update, delete: if isAdmin();
    }
    
    // Teams collection - Public read, admin write
    match /teams/{teamId} {
      allow read: if true; // Public read access
      allow create, update, delete: if isAdmin();
    }
    
    // Matches collection - Public read, admin write
    match /matches/{matchId} {
      allow read: if true; // Public read access
      allow create, update, delete: if isAdmin();
    }
    
    // Standings collection - Public read, admin write
    match /standings/{standingId} {
      allow read: if true; // Public read access
      allow create, update, delete: if isAdmin();
    }
    
    // Tournaments collection - Public read, admin write
    match /tournaments/{tournamentId} {
      allow read: if true; // Public read access
      allow create, update, delete: if isAdmin();
      
      // Tournament matches subcollection
      match /matches/{matchId} {
        allow read: if true;
        allow create, update, delete: if isAdmin();
      }
    }
  }
}
```

## How to Apply Rules

### Method 1: Firebase Console (Recommended)

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Navigate to **Firestore Database** → **Rules**
4. Copy the rules above
5. Paste into the rules editor
6. Click **Publish**

### Method 2: Firebase CLI

If you have Firebase CLI installed:

```bash
# Create firestore.rules file in your project root
# Copy the rules above into it

# Deploy rules
firebase deploy --only firestore:rules
```

## Rules Explanation

### 🌍 Public Access (`allow read: if true`)
- **Sports**: Anyone can view sports categories
- **Teams**: Anyone can view team information
- **Matches**: Anyone can view match schedules and results
- **Standings**: Anyone can view tournament standings
- No authentication required for viewing

### 🔐 Admin-Only Write Access
- **Create/Update/Delete**: Only authenticated admins can modify data
- Verified through `isAdmin()` function
- Checks user's role in Firestore users collection

### 👤 User Data Protection
- Users can only access their own user document
- Users cannot delete their accounts (set to `false`)
- New users can create their document during signup

## Security Best Practices

### ✅ What These Rules Protect

1. **Data Integrity**: Only admins can modify sports data
2. **User Privacy**: Users can only see their own profile data
3. **Public Information**: Sports data is public (as intended)
4. **Authentication**: Admin actions require valid authentication

### ⚠️ Important Notes

1. **First Admin Creation**
   - Create your first admin account through signup
   - Manually set `role: "admin"` in Firestore Console
   - After that, only admins can create data

2. **Testing Rules**
   - Use Firestore Rules Playground in Firebase Console
   - Test both authenticated and unauthenticated access
   - Verify admin privileges work correctly

3. **Production Considerations**
   - These rules are suitable for production
   - Consider rate limiting in Firebase Console
   - Monitor usage in Firebase Analytics

## Testing the Rules

### Test Public Read Access
```javascript
// In Rules Playground
// Set: Unauthenticated
match /databases/{database}/documents/sports/{sportId}
// Operation: get
// Result: Should ALLOW ✅
```

### Test Admin Write Access
```javascript
// In Rules Playground
// Set: Authenticated with admin role
match /databases/{database}/documents/sports/{sportId}
// Operation: create/update/delete
// Result: Should ALLOW ✅
```

### Test Non-Admin Write Access
```javascript
// In Rules Playground
// Set: Authenticated without admin role
match /databases/{database}/documents/sports/{sportId}
// Operation: create/update/delete
// Result: Should DENY ❌
```

## Common Issues

### Issue: "Permission Denied" when viewing data
**Solution**: 
- Ensure rules are published
- Check collection names match exactly
- Clear app cache and restart

### Issue: Admin cannot create/update data
**Solution**:
1. Verify user is logged in
2. Check Firebase Console → Users collection
3. Ensure user document has `role: "admin"` (lowercase)
4. Logout and login again

### Issue: Rules not taking effect
**Solution**:
- Click **Publish** in Firebase Console
- Wait 1-2 minutes for propagation
- Restart your app
- Check for syntax errors in rules

## Migration from Old Rules

If you had previous rules requiring authentication for reads:

1. **Backup current rules** (copy to a file)
2. Apply new rules with public read access
3. Test thoroughly
4. Monitor Firebase Console for unauthorized access attempts

## Advanced Customization

### Limit Public Read to Specific Fields

```javascript
match /users/{userId} {
  allow read: if true; // Public profiles
  allow get: if request.auth.uid == userId; // Full profile only for owner
}
```

### Rate Limiting (Recommended)

Consider adding in Firebase Console:
- **Cloud Firestore** → **Usage** → Set quotas
- Limit reads/writes per user
- Prevent abuse

### Add Validation

```javascript
match /sports/{sportId} {
  allow create: if isAdmin() && 
                request.resource.data.name is string &&
                request.resource.data.name.size() > 0;
}
```

## Support

If you encounter issues:
1. Check Firebase Console → Firestore → Rules tab
2. Look for red error indicators
3. Use Rules Playground to test specific operations
4. Check app logs for permission errors

---

**Remember**: After updating rules, always test both public access and admin functionality! 🔒
