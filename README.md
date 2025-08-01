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
