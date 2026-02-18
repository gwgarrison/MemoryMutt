# ModusMemori PRD

ModusMemori is a mobile flash card application designed to help users learn and memorize information efficiently through spaced repetition and interactive study sessions. The app targets students, language learners, and professionals who need to retain large amounts of information.

---

## 2. Product Overview

### 2.1 Vision
To become the go-to mobile application for efficient learning through scientifically-backed spaced repetition methods, making memorization engaging and effective.

### 2.2 Goals
- Enable users to create and study custom flash card decks
- Implement spaced repetition algorithms to optimize learning retention
- Provide an intuitive, distraction-free learning experience
- Support multiple content types (text, images, audio)
- Track learning progress and provide insights

### 2.3 Target Audience
- **Primary:** Students (high school, college, graduate)
- **Secondary:** Language learners, certification exam candidates
- **Tertiary:** Professionals learning new skills or information

---

## 3. Features & Requirements

### 3.1 Core Features (MVP)

#### 3.1.1 Deck Management
- **Create Deck**
  - User can create new flash card decks
  - Assign custom names and descriptions
  - Add tags/categories for organization
  - Set deck color/icon for visual identification

- **Import/Export Decks**
  - Import from CSV files
  - Export decks to CSV for backup
  - Share decks with other users

- **Deck Organization**
  - Browse all decks in a list/grid view
  - Search decks by name or tag
  - Sort by recently studied, creation date, or name
  - Archive/delete decks

#### 3.1.2 Card Management
- **Create Cards**
  - Front and back text fields (required)
  - Optional image attachment (front and/or back)
  - Optional audio attachment (pronunciation support)
  - Markdown support for formatting
  - Card hints/notes field

- **Edit/Delete Cards**
  - Edit existing cards
  - Bulk edit multiple cards
  - Delete individual or multiple cards
  - Duplicate cards

- **Card Types**
  - Basic (front/back)
  - Multiple choice (future enhancement)
  - Fill-in-the-blank (future enhancement)

#### 3.1.3 Study Mode
- **Study Session**
  - Select deck to study
  - Display card front, user attempts recall
  - Tap to reveal answer
  - Rate difficulty: Again, Hard, Good, Easy
  - Visual progress indicator (cards remaining)
  - Session summary at completion

- **Spaced Repetition Algorithm**
  - Implement SM-2 or Leitner system
  - Schedule card reviews based on performance
  - Prioritize cards due for review
  - Adjust intervals based on user ratings

- **Study Settings**
  - Daily card limit
  - New cards per day limit
  - Review order (random, oldest first, newest first)
  - Show/hide progress during session

#### 3.1.4 Progress Tracking
- **Statistics Dashboard**
  - Cards studied today/this week/this month
  - Current streak (consecutive days studied)
  - Total cards mastered
  - Deck-specific statistics
  - Heatmap calendar showing study activity

- **Card Status**
  - New (never studied)
  - Learning (currently reviewing)
  - Review (due for review)
  - Mastered (long interval)

### 3.2 User Experience Requirements

#### 3.2.1 Onboarding
- Welcome screen explaining key features
- Quick tutorial on creating first deck
- Sample deck included for demo
- Skip option for experienced users

#### 3.2.2 Navigation
- Tab bar navigation:
  - Home/Dashboard
  - Decks
  - Study
  - Statistics
  - Settings
- Intuitive back navigation
- Swipe gestures for common actions

#### 3.2.3 Visual Design
- Adherence to Apple Human Interface Guidelines (HIG)
- Clean, minimalist interface
- Dark mode support
- Accessible color contrast
- Consistent typography
- Smooth animations and transitions
- Loading states for all async operations

### 3.3 Technical Requirements

#### 3.3.1 Platform Support
- iOS 17.0+ (iPhone and iPad)
- Responsive layouts for different screen sizes
- Support for landscape and portrait orientations

#### 3.3.2 Performance
- App launch time < 2 seconds
- Card flip animation < 300ms
- Smooth scrolling (60 FPS minimum)
- Offline-first architecture
- Efficient memory usage for large decks (1000+ cards)

#### 3.3.3 Data Storage
- Local database (SwiftData)
- iCloud Sync
- Data encryption for sensitive content
- Export functionality for data portability

#### 3.3.4 Accessibility
- VoiceOver support
- Dynamic Type support
- High contrast mode
- Keyboard navigation support
- Accessibility labels

### 3.4 Future Enhancements (Post-MVP)

#### 3.4.1 Social Features
- Share decks publicly in marketplace
- Collaborative deck editing
- Study groups and challenges
- Leaderboards

#### 3.4.2 Advanced Learning
- AI-generated cards from text/PDFs
- Text-to-speech for audio playback
- Handwriting recognition for practice
- Gamification (points, badges, achievements)

#### 3.4.3 Content Enhancement
- Built-in image search
- Audio recording
- LaTeX support for mathematical equations
- Cloze deletion cards

#### 3.4.4 Integration
- Calendar reminders
- Widget for quick study sessions
- Apple Watch companion app
- App Clips (optional)

---

## 4. User Stories

### 4.1 As a Student
- I want to create flash cards from my class notes so I can study for exams
- I want the app to remind me which cards to review so I don't forget material
- I want to track my progress so I can see my improvement over time
- I want to import cards from a CSV file so I don't have to manually enter everything

### 4.2 As a Language Learner
- I want to add audio pronunciations so I can learn proper pronunciation
- I want to add images to cards so I can learn visually
- I want to study specific categories so I can focus on vocabulary themes
- I want to see my daily streak so I stay motivated to practice every day

### 4.3 As a Professional
- I want to create quick reference cards so I can memorize important information
- I want to export my decks so I can back them up
- I want offline access so I can study anywhere
- I want a clean interface so I can focus without distractions

---

## 5. Success Metrics

### 5.1 Engagement Metrics
- Daily Active Users (DAU)
- Monthly Active Users (MAU)
- Average session duration: target 10-15 minutes
- Cards studied per session: target 20-30 cards
- User retention rate: 40% after 30 days

### 5.2 Learning Metrics
- Average streak length: target 7+ days
- Cards mastered per user per month
- Study completion rate (sessions completed vs. started)
- Time to mastery per card

### 5.3 Quality Metrics
- App crash rate: < 0.1%
- Average app rating: > 4.5 stars
- Load time: < 2 seconds
- User-reported bugs: < 5 per 1000 users

---

## 6. Technical Architecture

### 6.1 Technology Stack
- **Language:** Swift
- **UI Framework:** SwiftUI
- **Database:** SwiftData
- **Architecture:** MVVM
- **Analytics:** TelemetryDeck or native logging

### 6.2 Data Models

#### Deck
```
- id (UUID)
- name (String)
- description (String)
- tags (Array<String>)
- color (String)
- icon (String)
- createdAt (DateTime)
- updatedAt (DateTime)
- cardsCount (Integer)
```

#### Card
```
- id (UUID)
- deckId (UUID, foreign key)
- front (String)
- back (String)
- frontImage (String, URL/path)
- backImage (String, URL/path)
- frontAudio (String, URL/path)
- backAudio (String, URL/path)
- hint (String)
- status (Enum: new, learning, review, mastered)
- easeFactor (Float)
- interval (Integer, days)
- nextReviewDate (DateTime)
- createdAt (DateTime)
- updatedAt (DateTime)
```

#### StudySession
```
- id (UUID)
- deckId (UUID, foreign key)
- startTime (DateTime)
- endTime (DateTime)
- cardsStudied (Integer)
- cardsNew (Integer)
- cardsReview (Integer)
- accuracy (Float, percentage)
```

#### Review
```
- id (UUID)
- cardId (UUID, foreign key)
- sessionId (UUID, foreign key)
- rating (Enum: again, hard, good, easy)
- reviewedAt (DateTime)
- timeSpent (Integer, seconds)
```

---

## 7. Design Specifications

### 7.1 Color Palette
- Primary: #4A90E2 (Blue)
- Success: #7ED321 (Green)
- Warning: #F5A623 (Orange)
- Error: #D0021B (Red)
- Background: #FFFFFF (Light mode), #1C1C1E (Dark mode)
- Text: #333333 (Light mode), #FFFFFF (Dark mode)

### 7.2 Typography
- Headings: SF Pro Display - Bold
- Body: SF Pro Text - Regular
- Size scale: Follows Apple Human Interface Guidelines

### 7.3 Key Screens
1. **Home/Dashboard** - Overview of study stats and due cards
2. **Deck List** - Grid/list of all decks with search
3. **Deck Detail** - Individual deck with card count and study button
4. **Card Editor** - Form for creating/editing cards
5. **Study Session** - Full-screen card display with flip animation
6. **Statistics** - Charts and graphs showing progress
7. **Settings** - App preferences and study settings

---

## 8. Constraints & Assumptions

### 8.1 Constraints
- Must work offline (no internet required for core features)
- Must support devices with 2GB RAM minimum
- Must comply with COPPA for users under 13
- Must not exceed 100MB initial download size

### 8.2 Assumptions
- Users are motivated to study regularly
- Users have basic smartphone literacy
- Users prefer simple, focused experiences over complex features
- Spaced repetition improves learning outcomes

---

## 9. Risks & Mitigation

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Poor user retention | High | Medium | Implement engaging onboarding and daily reminders |
| Performance issues with large decks | Medium | Medium | Implement pagination and virtualization |
| Data loss | High | Low | Auto-save and cloud backup features |
| Competition from established apps | Medium | High | Focus on unique UX and superior design |
| Algorithm complexity | Low | Medium | Start with simple Leitner system, iterate |

---

## 10. Timeline & Milestones

### Phase 1: MVP (8-12 weeks)
- Week 1-2: Setup, architecture, UI design
- Week 3-5: Deck and card management
- Week 6-8: Study mode and spaced repetition
- Week 9-10: Statistics and progress tracking
- Week 11-12: Testing, bug fixes, polish

### Phase 2: Beta Release (2-4 weeks)
- Beta testing with 50-100 users
- Gather feedback and iterate
- Performance optimization
- App store preparation

### Phase 3: Public Launch (1-2 weeks)
- App store submission
- Marketing materials
- Launch campaign

### Phase 4: Post-Launch (Ongoing)
- Monitor analytics and user feedback
- Bug fixes and improvements
- Feature enhancements from roadmap

---

## 11. Open Questions

1. Should we implement cloud sync in MVP or post-launch?
2. What freemium model (if any) should we use?
3. Should we support web import from popular services (Quizlet, Anki)?
4. What analytics events are most important to track?
5. Should we include pre-made decks or only user-generated content?

---

## 12. Appendix

### 12.1 Competitive Analysis
- **Anki:** Powerful but complex UI, steep learning curve
- **Quizlet:** Popular but heavy on social features, ads
- **Brainscape:** Good spaced repetition, paid model
- **Memrise:** Gamified, but limited customization
- **Flashcards Deluxe:** Feature-rich but outdated UI
