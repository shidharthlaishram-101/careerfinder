# Gemini API Setup Instructions

The chatbot is currently showing a 404 error because the Gemini API key is not configured. Follow these steps to fix it:

## Step 1: Get a Gemini API Key

1. Go to [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Sign in with your Google account
3. Click "Create API Key" 
4. Copy the generated API key

## Step 2: Create the .env file

Create a file named `.env` in the root of your project (`c:\ai-powered\aipowered\.env`) with the following content:

```
GEMINI_API_KEY=your_actual_api_key_here
```

Replace `your_actual_api_key_here` with the API key you copied from Google AI Studio.

## Step 3: Restart the app

After creating the `.env` file with your API key:

1. Stop your Flutter app if it's running
2. Run `flutter clean` to clear the build cache
3. Run `flutter pub get` to refresh dependencies
4. Restart your app

## What was fixed

The chatbot code has been updated with:

- Better API key validation
- Updated Gemini API endpoint (gemini-2.0-flash-exp - the latest supported model)
- Improved error handling with more detailed error messages
- Better response parsing with null checks

The chatbot should now work properly once you add your API key!
