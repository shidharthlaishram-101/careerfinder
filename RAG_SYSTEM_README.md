# RAG-Powered Career Chatbot System

## Overview

This project implements a Retrieval-Augmented Generation (RAG) system for a career guidance chatbot using Flutter and Google's Gemini API. The system combines a comprehensive career knowledge base with AI-powered responses to provide accurate, context-aware career guidance.

## Key Features

### 🎯 RAG Implementation
- **Knowledge Base Integration**: 50+ career paths across Arts, Science, and Commerce streams
- **Contextual Retrieval**: Intelligent matching of user queries to relevant career information
- **Personalized Responses**: User profile-aware career recommendations
- **Gemini API Integration**: Advanced language model for natural conversation

### 📚 Career Knowledge Base
- **Comprehensive Coverage**: 50 detailed career profiles
- **Structured Information**: Primary degrees, key exams, advanced studies
- **Stream Organization**: Arts, Science, Commerce & Finance categories
- **Search & Filter**: Advanced search capabilities by keywords, stream, or specific careers

### 🤖 Enhanced Chat Experience
- **Context-Aware Responses**: Responses based on retrieved career information
- **Conversation History**: Persistent chat history with Firebase
- **User Profile Integration**: Personalized advice based on user background
- **Real-time Processing**: Fast response generation with loading indicators

## Architecture

### Core Components

1. **KnowledgeBaseService** (`lib/services/knowledge_base_service.dart`)
   - Parses and structures career data from `knowledge_base.txt`
   - Provides search, filter, and retrieval functionality
   - Manages career information and statistics

2. **RAGService** (`lib/services/rag_service.dart`)
   - Implements RAG pipeline: Retrieve → Augment → Generate
   - Integrates with Gemini API for response generation
   - Manages context building and prompt engineering

3. **CareerChatbotPage** (`lib/careerchatbot.dart`)
   - Updated UI to use RAG system
   - Enhanced welcome message highlighting capabilities
   - Seamless integration with existing chat infrastructure

### RAG Pipeline Flow

```
User Query → Knowledge Retrieval → Context Building → Gemini API → Response
     ↓              ↓                    ↓              ↓           ↓
"Tell me about     Relevant Careers    Structured     Enhanced    Contextual
being a doctor"    from Knowledge      Context        Prompt      Response
                   Base                               with API
```

## Knowledge Base Structure

The `knowledge_base.txt` file contains structured career information:

```
1. Lawyer
Primary Degree: A 5-year integrated course like B.A. L.L.B. or B.B.A. L.L.B. after Class 12.
Key Exams/Certifications: CLAT, AILET, LSAT for entry into law schools.
Advanced Studies: Master of Laws (L.L.M.) for specialization.

🔬 Science Stream
18. Doctor (MBBS)
Primary Degree: MBBS (Bachelor of Medicine, Bachelor of Surgery), a 5.5-year course.
Key Exams/Certifications: NEET-UG is the single entrance exam for admission.
Advanced Studies: NEET-PG exam is required for admission into MD or MS.
```

## Usage Examples

### Basic Career Query
```
User: "Tell me about becoming a software engineer"
RAG System: 
1. Retrieves Software Engineer career information
2. Builds context with degree requirements, exams, advanced studies
3. Generates personalized response using Gemini API
```

### Stream-Based Search
```
User: "What careers are available in science stream?"
RAG System:
1. Retrieves all Science stream careers
2. Provides comprehensive list with key details
3. Offers specific guidance based on user profile
```

### Personalized Recommendations
```
User Profile: {stream: "Science", educationLevel: "12th", isWorking: false}
Query: "What should I study after 12th?"
RAG System:
1. Filters Science careers suitable for 12th pass students
2. Prioritizes undergraduate programs
3. Provides specific exam and admission guidance
```

## Technical Implementation

### Knowledge Retrieval
- **Keyword Matching**: Advanced text matching with scoring
- **Stream Filtering**: Category-based career filtering
- **Relevance Scoring**: Weighted scoring for result ranking
- **Fallback Mechanisms**: Broader search when specific matches not found

### Context Building
- **Structured Context**: Organized presentation of retrieved information
- **User Profile Integration**: Personalized context based on user background
- **Query Relevance**: Context tailored to specific user questions

### Prompt Engineering
- **Role Definition**: Clear career advisor persona
- **Scope Limitation**: Strict career-focused responses only
- **Instruction Set**: Detailed guidelines for response generation
- **Context Integration**: Seamless incorporation of retrieved knowledge

## Configuration

### Environment Setup
1. Add Gemini API key to `.env` file:
```
GEMINI_API_KEY=your_api_key_here
```

2. Ensure `knowledge_base.txt` is included in `pubspec.yaml` assets:
```yaml
assets:
  - assets/knowledge_base.txt
```

### Dependencies
Key dependencies for RAG functionality:
- `flutter_dotenv`: Environment variable management
- `http`: API communication
- `cloud_firestore`: Chat history persistence
- `firebase_auth`: User authentication

## Performance Optimizations

### Caching Strategy
- Knowledge base loaded once during app initialization
- In-memory career data for fast retrieval
- Efficient search algorithms with early termination

### Response Optimization
- Limited context size (3 careers max) for optimal API performance
- Structured prompts to reduce token usage
- Error handling with graceful fallbacks

### Memory Management
- Lazy loading of knowledge base
- Efficient data structures for career storage
- Minimal memory footprint for mobile devices

## Error Handling

### Graceful Degradation
- Fallback to general career advice if specific information unavailable
- Error messages for API failures
- Validation of knowledge base integrity

### User Experience
- Clear error messages for users
- Loading indicators during processing
- Retry mechanisms for failed requests

## Testing

### Knowledge Base Testing
Run the test file to verify knowledge base functionality:
```dart
import 'services/test_knowledge_base.dart';
testKnowledgeBase();
```

### RAG System Testing
Test the complete RAG pipeline:
```dart
final response = await RAGService.generateRAGResponse(
  userQuery: "Tell me about becoming a doctor",
  userProfile: userProfile,
);
```

## Future Enhancements

### Advanced Features
- **Vector Embeddings**: Semantic search using embeddings
- **Conversation Memory**: Long-term conversation context
- **Multi-language Support**: Career guidance in multiple languages
- **Visual Career Maps**: Interactive career pathway visualization

### Knowledge Base Expansion
- **Industry Trends**: Real-time career market information
- **Salary Information**: Compensation data integration
- **Skill Requirements**: Detailed skill mapping for careers
- **Success Stories**: Career progression examples

### AI Improvements
- **Fine-tuned Models**: Specialized career guidance models
- **Sentiment Analysis**: Emotion-aware responses
- **Proactive Suggestions**: Intelligent career recommendations
- **Learning Analytics**: User interaction pattern analysis

## Conclusion

The RAG-powered career chatbot provides a sophisticated, context-aware career guidance system that combines comprehensive career knowledge with advanced AI capabilities. The system offers personalized, accurate, and actionable career advice while maintaining a natural conversational experience.

The modular architecture allows for easy expansion and maintenance, while the robust error handling ensures reliable performance across different user scenarios and network conditions.
