# Sample Data for Testing

Use this guide to populate your app with sample data for testing.

## Sports Categories

Add these sports through Admin Panel → Manage Sports:

1. **Football**
   - Description: "Association football, also known as soccer"

2. **Cricket**
   - Description: "Bat-and-ball game played between two teams"

3. **Basketball**
   - Description: "Team sport played with a ball on a rectangular court"

4. **Volleyball**
   - Description: "Team sport where players hit a ball over a net"

5. **Tennis**
   - Description: "Racket sport played individually or in pairs"

6. **Badminton**
   - Description: "Racquet sport played with a shuttlecock"

## Teams

Add these teams through Admin Panel → Manage Teams:

### Football Teams
1. Name: "Eagles FC", Department: "Computer Science"
2. Name: "Lions United", Department: "Business Administration"
3. Name: "Tigers FC", Department: "Engineering"
4. Name: "Wolves FC", Department: "Arts & Sciences"

### Cricket Teams
1. Name: "Royal Challengers", Department: "Computer Science"
2. Name: "Mumbai Warriors", Department: "Business Administration"
3. Name: "Chennai Super Squad", Department: "Engineering"
4. Name: "Delhi Capitals", Department: "Arts & Sciences"

### Basketball Teams
1. Name: "Dunkers", Department: "Computer Science"
2. Name: "Hoopsters", Department: "Business Administration"
3. Name: "Slam Squad", Department: "Engineering"
4. Name: "Net Blazers", Department: "Arts & Sciences"

## Sample Matches

Schedule these matches through Admin Panel → Manage Matches:

### Upcoming Matches
1. Football: Eagles FC vs Lions United
   - Date: Tomorrow
   - Time: 3:00 PM
   - Venue: University Sports Complex

2. Cricket: Royal Challengers vs Mumbai Warriors
   - Date: Day after tomorrow
   - Time: 10:00 AM
   - Venue: Cricket Ground A

### Completed Matches (with scores)
1. Basketball: Dunkers vs Hoopsters
   - Score: 78-72
   - Status: Completed
   - Winner: Dunkers

2. Football: Tigers FC vs Wolves FC
   - Score: 3-1
   - Status: Completed
   - Winner: Tigers FC

## Sample Standings

Manually add standings through Firestore Console:

### Football Standings
Collection: `standings`

```json
{
  "sportId": "[your-football-sport-id]",
  "teamId": "[eagles-fc-id]",
  "played": 5,
  "won": 4,
  "lost": 1,
  "drawn": 0,
  "points": 12,
  "goalsFor": 15,
  "goalsAgainst": 6,
  "updatedAt": [current-timestamp]
}
```

Repeat for other teams with different stats.

## Quick Firebase Console Setup

1. Go to Firestore Database
2. Add data manually or use Firebase CLI
3. Structure should match models defined in the app

## Testing Scenarios

### As Admin:
1. Login with admin account
2. Add all sports, teams
3. Schedule 10+ matches
4. Update 3-4 match results
5. Check if standings update

### As User:
1. Login with user account
2. Browse sports categories
3. View match details
4. Check standings
5. Verify can't access admin features

## Pro Tips

- Add at least 3-4 teams per sport for better visualization
- Schedule matches across different dates
- Mix upcoming, live, and completed statuses
- Use realistic scores based on sport type
- Test with different screen sizes

---

**Note:** You can also use Firebase Admin SDK or scripts to bulk import this data, but manual entry through the app is recommended for first-time setup to understand the flow.
