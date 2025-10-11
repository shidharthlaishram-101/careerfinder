# User Data Storage System

## Overview
The app now stores comprehensive user information for every unique user in Firebase Firestore. This enables personalized career guidance based on individual user profiles.

## Data Structure

### 1. Users Collection (`Users`)
Stores basic user information:
- `userId`: Unique user identifier
- `email`: User's email address
- `name`: User's display name
- `signInMethod`: 'email' or 'google'
- `createdAt`: Account creation timestamp
- `lastLoginAt`: Last login timestamp
- `hasCompletedProfile`: Boolean indicating if user completed profile setup
- `lastUpdatedAt`: Last profile update timestamp

### 2. UserInfo Collection (`UserInfo`)
Stores detailed user profile information:
- `userId`: Links to Users collection
- `age`: User's age
- `stream`: Educational stream (Science, Commerce, Arts)
- `educationLevel`: High School, Undergraduate, Postgraduate, PhD
- `degree`: Specific degree (B.Tech, M.Sc, etc.)
- `specialization`: Field specialization (CSE, Physics, etc.)
- `isWorking`: Boolean indicating employment status
- `workDescription`: Current job description (if working)
- `updatedAt`: Last profile update timestamp

## UserService Class

### Key Methods:
- `saveBasicUserInfo()`: Saves user info during registration
- `saveDetailedUserInfo()`: Saves detailed profile from UserInfoPage
- `getCompleteUserProfile()`: Retrieves full user profile
- `updateLastLogin()`: Updates login timestamp
- `hasCompletedProfile()`: Checks if profile is complete
- `deleteUserData()`: Removes all user data

## User Flow

1. **Registration**: Basic info saved to `Users` collection
2. **UserInfoPage**: Detailed profile saved to `UserInfo` collection
3. **Chatbot**: Uses complete profile for personalized career advice
4. **Login**: Updates last login timestamp

## Personalized Chatbot Features

The career chatbot now provides personalized advice by:
- Using the user's name in responses
- Considering their educational background
- Tailoring advice based on work experience
- Providing age-appropriate career guidance
- Focusing on relevant specializations

## Data Privacy & Security

- User data is stored securely in Firebase Firestore
- Each user can only access their own data
- Data is linked to authenticated Firebase users
- Profile completion is tracked for better user experience

## Usage Examples

```dart
// Get complete user profile
final profile = await UserService.getCompleteUserProfile(userId);

// Save detailed user info
await UserService.saveDetailedUserInfo(
  userId: userId,
  age: 25,
  stream: 'Science',
  educationLevel: 'Undergraduate',
  degree: 'B.Tech',
  specialization: 'CSE',
  isWorking: true,
  workDescription: 'Software Engineer at XYZ Corp',
);
```

This system ensures every user gets personalized, relevant career guidance based on their unique background and goals.
