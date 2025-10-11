# Chat History & Conversation Management System

## Overview
The app now includes a comprehensive chat history and conversation management system that allows users to have multiple conversations, save chat history, and manage their conversation threads.

## Database Structure

### 1. Conversations Collection (`Conversations`)
Stores conversation metadata:
- `id`: Unique conversation identifier (auto-generated)
- `userId`: Links to the user who owns the conversation
- `title`: Conversation title (auto-generated from first message)
- `createdAt`: Conversation creation timestamp
- `lastMessageAt`: Timestamp of the last message
- `messageCount`: Total number of messages in the conversation
- `isActive`: Boolean indicating if conversation is active/not archived

### 2. Messages Collection (`Messages`)
Stores individual chat messages:
- `id`: Unique message identifier (auto-generated)
- `conversationId`: Links to the parent conversation
- `userId`: Links to the user who sent the message
- `role`: 'user' or 'bot'
- `content`: The actual message text
- `timestamp`: When the message was sent

## ChatService Class

### Key Methods:

#### Conversation Management:
- `createNewConversation()`: Creates a new conversation thread
- `getUserConversations()`: Retrieves all conversations for a user
- `getConversation()`: Gets specific conversation details
- `deleteConversation()`: Deletes conversation and all its messages
- `archiveConversation()`: Archives a conversation
- `updateConversationTitle()`: Renames a conversation

#### Message Management:
- `saveMessage()`: Saves a message to a conversation
- `getConversationMessages()`: Retrieves all messages for a conversation
- `getUserChatStats()`: Gets conversation statistics for a user

#### Utility Methods:
- `getLatestConversationId()`: Gets the most recent conversation
- `_generateTitleFromMessage()`: Auto-generates conversation titles

## User Experience Features

### 1. **Automatic Conversation Creation**
- New conversations are created automatically when users start chatting
- First bot message is saved as the conversation starter

### 2. **Conversation History Panel**
- Accessible via history icon in the app bar
- Shows all conversations with titles and message counts
- Highlights the currently active conversation
- Allows switching between conversations

### 3. **Conversation Management**
- **Rename**: Users can customize conversation titles
- **Delete**: Remove conversations and all associated messages
- **New Conversation**: Start fresh conversations anytime

### 4. **Auto-Generated Titles**
- Conversation titles are automatically generated from the first user message
- Titles are limited to 30 characters with ellipsis for longer messages

### 5. **Persistent Chat History**
- All messages are saved to Firebase Firestore
- Conversations persist across app sessions
- Users can continue previous conversations anytime

## UI Components

### App Bar Actions:
- **History Icon**: Opens conversation history panel
- **New Chat Icon**: Starts a new conversation

### Conversation History Modal:
- List of all conversations with metadata
- Current conversation highlighting
- Context menu for rename/delete actions
- "New Conversation" button

### Conversation Management:
- **Rename Dialog**: Simple text input for custom titles
- **Delete Confirmation**: Safe deletion with error handling
- **Loading States**: Visual feedback during operations

## Data Flow

1. **New User**: Automatically creates first conversation on app start
2. **Message Sending**: Each message is saved to database immediately
3. **Conversation Switching**: Loads previous messages from database
4. **History Access**: Displays all conversations with metadata
5. **Conversation Management**: Updates database and refreshes UI

## Error Handling

- **Network Errors**: Graceful fallback with user notifications
- **Database Errors**: Detailed error messages for debugging
- **Missing Data**: Safe handling of incomplete conversation data
- **Loading States**: Visual feedback during async operations

## Performance Optimizations

- **Lazy Loading**: Conversations loaded only when needed
- **Efficient Queries**: Optimized Firestore queries with proper indexing
- **Local State Management**: Minimizes database calls
- **Batch Operations**: Efficient message saving and retrieval

## Usage Examples

```dart
// Create a new conversation
final conversationId = await ChatService.createNewConversation(
  userId: currentUser.uid,
  title: 'Career Guidance Session',
);

// Save a message
await ChatService.saveMessage(
  conversationId: conversationId,
  userId: currentUser.uid,
  role: 'user',
  content: 'Tell me about software engineering careers',
);

// Get conversation history
final conversations = await ChatService.getUserConversations(currentUser.uid);

// Switch to a conversation
await _loadConversation(conversationId);
```

## Future Enhancements

- **Conversation Search**: Search through message history
- **Message Export**: Export conversations to text/PDF
- **Conversation Sharing**: Share conversations with others
- **Advanced Filtering**: Filter conversations by date, topic, etc.
- **Message Reactions**: Like/dislike bot responses
- **Conversation Categories**: Organize conversations by topics

This system provides a complete chat history solution that enhances user experience and allows for comprehensive conversation management while maintaining data persistence and user privacy.
