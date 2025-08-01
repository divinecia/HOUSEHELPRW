# HOUSEHELP

A modern house helper management application built with Flutter, Supabase, and Paypack integration.

## Overview

HOUSEHELP is a comprehensive platform that connects house holders with house helpers, featuring real-time chat, hire request management, and secure payment processing through Paypack.

## Features

- **User Authentication**: Secure authentication using Supabase Auth
- **Real-time Chat**: Chat functionality between house holders and helpers
- **Hire Request Management**: Create, manage, and track hire requests
- **Payment Integration**: Secure payments using Paypack API
- **Role-based Access**: Different interfaces for house holders, helpers, and administrators
- **Modern UI**: Material Design 3 with dark/light theme support
- **File Upload**: Profile pictures and document uploads via Supabase Storage

## Tech Stack

- **Frontend**: Flutter with Material Design 3
- **Backend**: Supabase (PostgreSQL database, Auth, Storage, Real-time)
- **Payment Gateway**: Paypack API
- **State Management**: Provider
- **Charts**: FL Chart

## Prerequisites

- Flutter SDK (>=3.10.0)
- Dart SDK (>=3.0.0)
- Supabase account
- Paypack merchant account

## Setup Instructions

### 1. Clone and Setup Flutter Project

```bash
git clone <repository-url>
cd houseHelpApp/employement_management_app
flutter pub get
```

### 2. Supabase Setup

1. Create a new project at [Supabase](https://supabase.com)
2. Get your project URL and anon key from Settings > API
3. Update `lib/config/supabase_config.dart`:

```dart
static const String supabaseUrl = 'YOUR_SUPABASE_PROJECT_URL';
static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```

### 3. Database Schema

Create the following tables in your Supabase database:

#### Users Table
```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT UNIQUE NOT NULL,
    full_name TEXT,
    phone_number TEXT,
    role TEXT DEFAULT 'house_holder', -- 'house_holder', 'house_helper', 'admin'
    profile_image_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### House Helper Profiles Table
```sql
CREATE TABLE house_helper_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    experience_years INTEGER,
    hourly_rate DECIMAL(10,2),
    skills TEXT[],
    availability TEXT,
    location TEXT,
    bio TEXT,
    verification_status TEXT DEFAULT 'pending',
    rating DECIMAL(3,2) DEFAULT 0.00,
    total_jobs INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### Hire Requests Table
```sql
CREATE TABLE hire_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    house_holder_id UUID REFERENCES users(id),
    house_helper_id UUID REFERENCES users(id),
    title TEXT NOT NULL,
    description TEXT,
    hourly_rate DECIMAL(10,2),
    total_hours INTEGER,
    total_amount DECIMAL(10,2),
    start_date DATE,
    status TEXT DEFAULT 'pending', -- 'pending', 'accepted', 'rejected', 'completed'
    location TEXT,
    requirements TEXT[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### Payments Table
```sql
CREATE TABLE payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_id TEXT,
    amount DECIMAL(10,2) NOT NULL,
    currency TEXT DEFAULT 'RWF',
    phone_number TEXT NOT NULL,
    description TEXT,
    status TEXT DEFAULT 'pending', -- 'pending', 'completed', 'failed', 'cancelled'
    payment_method TEXT DEFAULT 'mobile_money',
    hire_request_id UUID REFERENCES hire_requests(id),
    house_helper_id UUID REFERENCES users(id),
    house_holder_id UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    metadata JSONB
);
```

#### Chats Table
```sql
CREATE TABLE chats (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    participants UUID[] NOT NULL,
    hire_request_id UUID REFERENCES hire_requests(id),
    last_message TEXT,
    last_message_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### Messages Table
```sql
CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    chat_id UUID REFERENCES chats(id) ON DELETE CASCADE,
    sender_id UUID REFERENCES users(id),
    content TEXT NOT NULL,
    message_type TEXT DEFAULT 'text', -- 'text', 'image', 'file'
    file_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### 4. Storage Setup

Create the following storage buckets in Supabase:

- `profile-images` - For user profile pictures
- `chat-files` - For chat attachments
- `documents` - For verification documents

### 5. Paypack Setup

1. Create a Paypack merchant account at [Paypack](https://paypack.rw)
2. Get your client ID and client secret from your dashboard
3. Update `lib/services/paypack_service.dart`:

```dart
static const String _clientId = 'YOUR_PAYPACK_CLIENT_ID';
static const String _clientSecret = 'YOUR_PAYPACK_CLIENT_SECRET';
```

### 6. Environment Configuration

Create a `.env` file in the root directory (optional):

```env
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
PAYPACK_CLIENT_ID=your_paypack_client_id
PAYPACK_CLIENT_SECRET=your_paypack_client_secret
```

## Running the Application

```bash
flutter pub get
flutter run
```

## Project Structure

```
lib/
├── config/
│   └── supabase_config.dart        # Supabase configuration
├── models/
│   ├── chat_modal.dart             # Chat and message models
│   ├── hire_request.dart           # Hire request model
│   ├── house_helper_profile.dart   # House helper profile model
│   ├── payment.dart                # Payment model
│   └── user_role.dart              # User role model
├── pages/
│   ├── auth_service.dart           # Authentication pages
│   ├── login.dart
│   ├── admin/                      # Admin interface
│   ├── house_helper/               # House helper interface
│   └── house_holder/               # House holder interface
├── services/
│   ├── supabase_auth_service.dart  # Authentication service
│   ├── supabase_service.dart       # Database operations
│   ├── paypack_service.dart        # Payment gateway integration
│   ├── payment_service.dart        # Payment management
│   ├── chat_service.dart           # Chat functionality
│   ├── hire_request_services.dart  # Hire request management
│   └── house_helper_service.dart   # House helper operations
└── main.dart                       # App entry point
```

## Key Features Implementation

### Authentication
- Uses Supabase Auth for user management
- Role-based access control
- Profile management

### Real-time Chat
- Real-time messaging using Supabase real-time subscriptions
- File sharing capabilities
- Chat history persistence

### Payment Processing
- Paypack integration for mobile money payments
- Payment status tracking
- Transaction history

### Material Design
- Modern Material Design 3 implementation
- Dark/light theme support
- Responsive UI components

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support, please contact [your-email@example.com] or create an issue in the repository.
# HOUSEHELPRW

# HOUSEHELP - House Helper Management App

A comprehensive Flutter application for managing house helper services in Rwanda, featuring role-based access control, training management, payment processing, and administrative oversight.

## 🏗️ Architecture

- **Frontend**: Flutter with Material Design 3
- **Backend**: Supabase (PostgreSQL + Real-time + Edge Functions)
- **State Management**: Provider
- **Authentication**: Supabase Auth with RLS (Row Level Security)
- **Payments**: Paypack API integration (MTN Mobile Money, Airtel Money)
- **Charts**: FL Chart for analytics visualization

## 👥 User Roles

### 🧑‍💼 Admin Panel
Comprehensive administrative control with role-based access:

#### 🧩 Access Control
- Supabase role check: only admin users can access full system controls
- Flutter route guard + Supabase RLS for role-based navigation
- Secure session management with automatic token refresh

#### 🧾 Admin Functionalities

##### 📚 1. Training Management (CRUD)
- **Create, Update, Delete Training Sessions**: Full lifecycle management
- **Scheduling**: Date, time, location, and instructor assignment
- **Participant Management**: View workers who requested to join via Supabase relations
- **Training Types**: 
  - Mandatory training (required for all workers)
  - Paid training (workers pay to attend)
  - Free training (company-sponsored)
- **Payment Integration**: Differentiate training payments from service payments using Supabase field flags
- **Training History**: Complete participation history stored in Supabase
- **Certificates**: Automatic certificate issuance for passing scores
- **Analytics**: Training completion rates, popular courses, attendance tracking

##### 👥 2. User Management
- **Comprehensive User Overview**: View and filter all workers and households
- **Advanced Filtering**: By name, district, status, registration date, service type
- **Worker Profile Management**:
  - Verified National ID status (manual verification, OCR/API ready for future)
  - Rating and review system
  - Services offered and specializations
  - Complete training history and certifications
- **Account Actions**: Delete or suspend users with behavior issues
- **Data Export**: User lists and statistics
- **Flutter Data Table**: Sortable, paginated user interface powered by Supabase

##### 🧼 3. Worker Oversight & Behavior Management
- **Behavior Report System**: Households can submit detailed worker behavior reports
- **Report Categories**: Professional conduct, punctuality, quality of work, safety issues
- **Severity Levels**: Low, Medium, High, Critical
- **Automated Escalation**: 
  - Use Supabase Edge Functions to send reports to Isange One Stop Center
  - CC company admin with detailed report information
  - Email templates with incident details and evidence
- **Report Archive**: Complete history with timestamps and involved parties
- **Investigation Tracking**: Status updates, admin notes, resolution outcomes
- **Evidence Management**: Photo/video upload and storage via Supabase Storage

##### 🛠️ 4. System Maintenance (FixMessages)
- **Issue Reporting**: Households and workers can submit system issues
- **Category Types**: Bug reports, feature requests, improvements, questions
- **Priority Levels**: Low, Medium, High, Urgent
- **Admin Dashboard**: Centralized "System Maintenance" panel
- **Status Tracking**: Pending → In Progress → Resolved workflow
- **Assignment System**: Assign issues to specific admin team members
- **Resolution Documentation**: Detailed solutions and fix notes
- **User Feedback**: Automatic notification to reporters when issues are resolved

##### 📊 5. Analytics Dashboard
Comprehensive metrics powered by Supabase aggregated queries:

**User Analytics**:
- Total registered users (households vs workers)
- Registration trends and growth patterns
- User activity and engagement metrics
- Geographic distribution by district

**Business Analytics**:
- Active hiring requests and completion rates
- Revenue and earnings via Paypack API integration
- Most requested services and seasonal trends
- Customer satisfaction scores (based on household reviews)
- Worker performance ratings and improvement trends

**Training Analytics**:
- Worker attendance to training sessions
- Completion rates and certification statistics
- Popular training categories and demand forecasting
- Training ROI and effectiveness metrics

**Visual Reporting**:
- Material Design charts and graphs (FL Chart)
- Interactive dashboards with drill-down capabilities
- Exportable reports (PDF/CSV)
- Real-time data updates

##### 💳 6. Payment Management
- **Unified Payment Dashboard**: All transactions via Supabase + Paypack API sync
- **Payment Categories**:
  - **Service Payments**: Job request payments from households to workers
  - **Training Payments**: Worker purchases for paid training sessions
  - **Platform Fees**: Service charges and commission tracking
- **Payment Analytics**:
  - Revenue breakdown by category and time period
  - Payment method distribution (MTN Money, Airtel Money)
  - Failed payment tracking and retry mechanisms
  - Tax calculation and reporting (18% VAT)
- **Financial Reports**:
  - Export payment reports (CSV/PDF format)
  - Filter by amount range, date, user role, payment provider
  - Monthly/quarterly financial summaries
  - Reconciliation tools for accounting

##### 📬 7. Notification Management
- **Multi-Channel Notifications**:
  - Push notifications via Flutter FCM
  - Email notifications via Supabase Edge Functions
  - SMS notifications (future integration)
- **Notification Types**:
  - New training announcements
  - Upcoming job notifications
  - Payment confirmations and reminders
  - System maintenance updates
  - Behavior report alerts
- **Targeted Messaging**:
  - Send to specific user groups (workers, households, all)
  - Role-based notification preferences
  - Scheduling and automation
- **Delivery Tracking**: Read receipts and engagement metrics

##### ⚙️ 8. System Settings
**Application Configuration**:
- Default language settings (Kinyarwanda, English, French)
- Tax rate configuration (currently 18% VAT)
- Service fee percentage for platform commission
- Payment limits (minimum/maximum transaction amounts)

**Benefits & Welfare Management**:
- **Ejo Heza Integration**: Enable/configure government savings program
- **Insurance Options**: Worker health and accident insurance programs
- **Welfare Programs**: Additional benefits and support systems

**Notification Preferences**:
- Global notification settings (email, push, SMS)
- User preference management
- Notification frequency controls

**Payment Provider Configuration**:
- MTN Mobile Money settings
- Airtel Money integration
- Payment gateway failover options
- Transaction fee management

### 🏠 House Holder Features
- **Service Requests**: Post detailed job requirements with location, timing, and budget
- **Worker Discovery**: Browse and filter available house helpers by services, ratings, and proximity
- **Secure Payments**: Integrated mobile money payments (MTN, Airtel) via Paypack
- **Real-time Chat**: Direct communication with hired workers
- **Rating System**: Review and rate worker performance
- **Behavior Reporting**: Submit detailed reports for problematic behavior
- **Service History**: Track all past hiring requests and payments

### 🧹 House Helper Features
- **Profile Management**: Showcase skills, experience, and availability
- **Job Applications**: Apply for posted house holder requests
- **Training Enrollment**: Request to join available training sessions
- **Payment Tracking**: View earnings and payment history
- **Chat System**: Communicate with employers
- **Training History**: Track completed courses and certifications
- **Rating Dashboard**: Monitor performance feedback

## 🔒 Security Features

### Supabase Row Level Security (RLS)
- **Role-based Data Access**: Users only see data relevant to their role
- **Admin-only Queries**: Sensitive operations restricted to admin accounts
- **Automatic Session Management**: Secure token handling with refresh

### Data Protection
- **Encrypted Storage**: All sensitive data encrypted at rest
- **Secure API Calls**: HTTPS-only communication
- **Input Validation**: Comprehensive form validation and sanitization
- **File Upload Security**: Secure image/document handling via Supabase Storage

## 🚀 Technical Implementation

### Database Schema (Supabase)
```sql
-- Core Tables
profiles (user management with roles)
trainings (training session management)
training_participations (enrollment tracking)
hire_requests (job postings and applications)
payments (transaction records)
behavior_reports (worker oversight)
fix_messages (system issue tracking)
system_settings (application configuration)

-- Relations and Indexes
- Foreign key relationships between all entities
- Optimized indexes for common queries
- RLS policies for data security
```

### State Management
- **Provider Pattern**: Centralized state management
- **Service Layer**: Abstracted business logic
- **Repository Pattern**: Clean data access layer

### Real-time Features
- **Live Chat**: Supabase real-time subscriptions
- **Notification Updates**: Instant admin panel updates
- **Payment Status**: Real-time payment confirmation

## 📱 Mobile-First Design

### Material Design 3
- **Adaptive UI**: Responsive design for all screen sizes
- **Theme Support**: Light/dark mode with system preference
- **Accessibility**: Screen reader support and high contrast options
- **Modern Components**: Latest Material Design guidelines

### Performance Optimization
- **Lazy Loading**: Efficient data pagination
- **Image Caching**: Cached network images for better performance
- **Background Sync**: Offline capability for core features

## 🌍 Rwanda-Specific Features

### Local Integration
- **Kinyarwanda Language**: Full localization support
- **District Management**: Rwanda's administrative divisions
- **Mobile Money**: MTN and Airtel Money integration via Paypack
- **Government Services**: Isange One Stop Center integration for reports

### Compliance
- **Tax Integration**: 18% VAT calculation and reporting
- **Legal Framework**: Compliance with Rwanda's labor laws
- **Data Residency**: Data stored within African data centers

## 🔄 Future Enhancements

### Planned Features
- **AI-Powered Matching**: Smart worker-household pairing
- **OCR Integration**: Automatic ID verification
- **Advanced Analytics**: Machine learning insights
- **IoT Integration**: Smart home device connectivity
- **Blockchain Payments**: Cryptocurrency payment options
- **Voice Commands**: Voice-activated job posting
- **Geofencing**: Location-based automatic check-ins

### Scalability
- **Microservices Architecture**: Future backend modularization
- **CDN Integration**: Global content delivery
- **Load Balancing**: High availability infrastructure
- **Multi-tenant Support**: Enterprise customer management

## 📞 Support & Maintenance

### Issue Resolution
- **In-app Reporting**: FixMessage system for user issues
- **Admin Dashboard**: Centralized issue tracking and resolution
- **Knowledge Base**: Self-service help documentation
- **24/7 Support**: Emergency contact system

### Continuous Improvement
- **User Feedback**: Regular feature request collection
- **Performance Monitoring**: Application health tracking
- **Security Audits**: Regular security assessments
- **Version Control**: Systematic update deployment

---

**HOUSEHELP** - Connecting Rwanda's households with skilled, trained, and reliable house helpers through technology, training, and trust.
