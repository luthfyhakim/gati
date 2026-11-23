PROJECT OVERVIEW

Build a Strava-like mobile application (simplified) that allows users to:

Register and authenticate

Track outdoor sports activity just running

Record GPS routes

View activity statistics and history

FUNCTIONAL REQUIREMENTS (MVP)

Authentication

User registration

User login

Token-based authentication (JWT)

Secure token storage on the device

Activity Tracking

Start activity tracking

Stop activity tracking

Real-time GPS location tracking

Record:

Latitude & longitude

Timestamp

Calculate:

Total distance (Haversine formula)

Duration

Average speed

Activity Management

Fetch activity history per user

View activity details:

Route displayed on a map

Distance, duration, average speed

Sport Gear Recommendation (running shoes, apparel, smart watch, accessories, etc)

Use supabase for product data

NON-FUNCTIONAL REQUIREMENTS

Clean and modular Flutter architecture

Separation of concerns (UI, state management, services)

Error handling for GPS permissions and API failures

Maintainable and readable code

TECHNICAL STACK

Frontend (Mobile):

Flutter (latest stable)

State Management: GetX

GPS & Location: geolocator

Maps: flutter_map plugin using openstreetmap

No Backend Integration just using supabase as database and store data in local storage

GPS & MAP HANDLING

Request runtime location permissions

Handle permission denial gracefully

Track GPS updates at reasonable intervals

Draw polyline route on map

Center map on user location during tracking

OUTPUT EXPECTATIONS

Complete Flutter project structure

Key Dart files:

Authentication service

Activity tracking service

Activity model

Activity repository

UI pages (Login, Register, Tracking, History, Detail)

Clear code comments for academic explanation

README explaining:

How the app works

How GPS tracking is implemented

CONSTRAINTS

Do NOT implement social features (followers, likes, comments)

Keep UI simple and functional

Focus on correctness and clarity rather than UI complexity

use get cli
