# বেতাগী ই সেবা — User App

> **Upazila Information & Service Application** for citizens of Betagi Upazila, Barishal, Bangladesh.

This is the **citizen-facing Android app** of the Betagi E-Sheva platform. It connects to a PHP + MySQL backend (REST API) and lets citizens browse upazila services, directory listings, notices, blood donors, clinics, doctors, government services, file complaints, and manage their own profile.

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Build Configuration](#2-build-configuration)
3. [Design System](#3-design-system)
4. [Architecture & Navigation](#4-architecture--navigation)
5. [Screen Inventory](#5-screen-inventory)
6. [Backend API Integration](#6-backend-api-integration)
7. [Authentication & Session](#7-authentication--session)
8. [File Structure](#8-file-structure)
9. [Key Conventions](#9-key-conventions)
10. [How to Build & Run](#10-how-to-build--run)
11. [Developer](#11-developer)

---

## 1. Project Overview

| Field | Value |
|---|---|
| **App Name** | বেতাগী ই সেবা |
| **Package** | `com.example.betagiesheva` |
| **Application ID** | `com.example.betagiesheva` |
| **Min SDK** | 26 (Android 8.0 Oreo) |
| **Target SDK** | 36 |
| **Compile SDK** | 36 |
| **Java Version** | 11 |
| **AGP Version** | 8.13.2 |
| **Backend** | PHP + MySQL REST API at `https://nagoriksheba.com/betagi_backend/api/` |
| **Language** | Bengali (বাংলা) — UI is entirely in Bengali |

### What the app does

Citizens can:
- Register / Login (phone + password, Google Sign-In, Forgot Password OTP)
- View upazila notices (with filter by type)
- Browse a 42-item service grid (hospitals, clinics, doctors, blood donors, schools, shops, bus, tourist spots, emergency numbers, etc.)
- Search and call blood donors
- View clinic/doctor/govt-officer/govt-item/business/person directories
- File complaints to the UNO
- View upazila budget details
- Access government online services (birth/death certificate, e-passport, etc.) via embedded WebView
- Manage profile (name, phone, email, address, photo, password)
- View app info and developer info

---

## 2. Build Configuration

### `app/build.gradle.kts`

```kotlin
plugins {
    alias(libs.plugins.android.application)
}

android {
    namespace = "com.example.betagiesheva"
    compileSdk { version = release(36) }

    defaultConfig {
        applicationId = "com.example.betagiesheva"
        minSdk = 26
        targetSdk = 36
        versionCode = 1
        versionName = "1.0"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
}
```

### Dependencies

| Library | Version | Purpose |
|---|---|---|
| `androidx.appcompat:appcompat` | 1.7.1 | AppCompat backward compatibility |
| `com.google.android.material:material` | 1.13.0 | Material Design 3 components |
| `androidx.activity:activity` | 1.12.2 | Activity Result API |
| `androidx.constraintlayout:constraintlayout` | 2.2.1 | ConstraintLayout |
| `androidx.swiperefreshlayout:swiperefreshlayout` | 1.1.0 | Pull-to-refresh |
| `androidx.recyclerview:recyclerview` | (transitive) | List/grid rendering |
| `androidx.cardview:cardview` | (transitive) | CardView UI |
| `com.android.volley:volley` | 1.2.1 | HTTP networking |
| `com.github.bumptech.glide:glide` | 4.16.0 / 5.0.5 | Image loading |
| `de.hdodenhof:circleimageview` | 3.1.0 | Circular profile images |
| `com.airbnb.android:lottie` | 6.6.7 | Lottie animations |
| `com.github.denzcoskun:ImageSlideshow` | 0.1.2 | Home image slider |
| `com.google.android.gms:play-services-maps` | 18.0.2 | Google Maps |
| `com.google.android.gms:play-services-location` | 21.3.0 | Location services |

### Version Catalog (`gradle/libs.versions.toml`)

AGP, Material, AppCompat, Activity, ConstraintLayout, JUnit, Espresso versions are managed via the version catalog.

---

## 3. Design System

### 3.1 Theme

**File:** `res/values/themes.xml`

The app uses **Material 3** with a **Light, No Action Bar** base theme:

```xml
<style name="Theme.WebviewPro" parent="Theme.Material3.Light.NoActionBar">
    <item name="colorPrimary">@color/purple_500</item>       <!-- #6200EE -->
    <item name="colorPrimaryVariant">@color/purple_700</item> <!-- #3700B3 -->
    <item name="colorOnPrimary">@color/white</item>
    <item name="colorSecondary">@color/teal_200</item>        <!-- #03DAC5 -->
    <item name="colorSecondaryVariant">@color/teal_700</item> <!-- #018786 -->
    <item name="colorOnSecondary">@color/black</item>
    <item name="android:windowLightStatusBar">true</item>
    <item name="android:statusBarColor">@color/bar</item>     <!-- #03DAC5 teal -->
    <item name="android:windowIsTranslucent">true</item>
</style>
```

- **Dark mode:** `res/values-night/themes.xml` and `res/values-v23/themes.xml` exist (edge-to-edge transparent system bars on API 23+).
- **AlertDialog theme:** `Theme.AppCompat.Light.Dialog.Alert`
- **Secondary theme:** `Theme.BetagiESeva` (MaterialComponents DayNight) and `Theme.Splash` (gradient background, fullscreen) are defined in `styles.xml`.

### 3.2 Color Palette

**File:** `res/values/colors.xml`

| Color | Hex | Usage |
|---|---|---|
| `purple_500` / `colorPrimary` | `#6200EE` | Primary brand color |
| `purple_700` / `colorPrimaryDark` | `#3700B3` | Dark variant (status bar in some themes) |
| `teal_200` / `colorAccent` / `bar` | `#03DAC5` | Accent + status bar color |
| `teal_700` | `#018786` | Secondary dark |
| `black` | `#000000` | Text on light backgrounds |
| `white` | `#FFFFFF` | Text on dark backgrounds, card backgrounds |
| `text_primary` | `#212121` | Primary text |
| `text_secondary` | `#757575` | Secondary text |
| `text_light` | `#BDBDBD` | Hint text |
| `back_color` | `#F5F5F5` | Screen background |
| `userMessageBackground` | `#E3F2FD` | Chat-style message background |
| `#2196F3` | (inline) | Blue accent on Login/Registration screens |
| `#FF6B35` | (inline) | Orange accent for home notice marquee bar |

> **Note:** The login/registration screens use `#2196F3` (blue) for hints/strokes, NOT the purple primary. This is an intentional design choice for the auth flow.

### 3.3 Typography (Fonts)

**Folder:** `res/font/` — 17 Bengali + English fonts

| Font File | Usage |
|---|---|
| `btxf.ttf` | **Headings** — titles, section headers, login/registration titles |
| `kalpurush.ttf` | **Body text** — home marquee, grid item labels |
| `bnlatxf.ttf` | **Bengali UI text** — most labels, buttons, toasts, form hints |
| `bnlatx.ttf` | Bengali text (alternate) |
| `elcias.otf` | **Numbers** — weather temperature display |
| `banglanm.ttf`, `siligurimedium.ttf` | Bengali text (various) |
| `english.otf`, `digit.ttf` | English/numeric |
| `srg.ttf`, `mt.ttf`, `mtg.ttf`, `fgg.ttf`, `fdg.ttf`, `duowg.ttf`, `btxf.ttf`, `ott.otf`, `ots.otf` | Various display/decorative fonts |

**Usage pattern in layouts:**
```xml
android:fontFamily="@font/bnlatxf"
```

### 3.4 Card Styles

**File:** `res/values/styles.xml`

The app uses `CardView` extensively with these consistent patterns:

| Pattern | Values |
|---|---|
| Corner radius | `8dp` (small cards), `12dp` (medium), `15dp` (profile menu), `20dp` (login/registration cards) |
| Elevation | `4dp` (flat cards), `10dp` (raised cards), `15dp` max |
| Background | `@color/white` for cards, `#F5F5F5` for screen background |

**Defined styles in `styles.xml`:**
- `SpecialtyCard` — match-parent card with `card_background` drawable, 4dp elevation
- `SpecialtyCardContent` — 16dp padding, vertical orientation
- `SpecialtyIcon` — 48dp centered icon
- `SpecialtyText` — 14sp centered black text
- `RoundedImageView` — 80dp rounded image
- `ProfileMenuItem` / `ProfileMenuItemContent` / `ProfileMenuIcon` / `ProfileMenuText` / `ProfileMenuArrow` — profile screen menu row styles
- `Widget.MaterialComponents.TextInputLayout.ExposedDropdownMenu` — white dropdown with black stroke

### 3.5 Lottie Animations

**Folder:** `res/raw/` — 12 Lottie JSON files

| File | Usage |
|---|---|
| `loading.json` | Login/registration loading spinner |
| `loginss.json` | Login success animation |
| `logsinn.json` | Sign-in animation |
| `notification.json` | Notification bell animation (top bar) |
| `call.json`, `callanim.json` | Call button animations |
| `frpass.json` | Forgot password animation |
| `no_net.json` | No internet screen |
| `empty_notice.json` | Empty notice list state |
| `verified.json` | Verification success |
| `pdf.json` | PDF viewer |
| `tracking_animation.json` | Tracking/loading |

### 3.6 Animations

**Folder:** `res/anim/`
- `top_anim.xml` — slide in from top
- `bottom_anim.xml` — slide in from bottom

---

## 4. Architecture & Navigation

### 4.1 Pattern: Single Host Activity + Fragments

The app follows a **single-host-activity + fragment** pattern:

```
LoginActivity (launcher)
    ↓ (on successful login)
HomeActivity (host)
    ├── DrawerLayout (left navigation drawer)
    ├── Top bar (logo + notification bell)
    ├── FrameLayout#fragment_container (fragment host)
    └── Custom bottom navigation (5 tabs)
```

**`HomeActivity`** (`activity_home.xml`) is the main host. It contains:
1. A **DrawerLayout** with a `NavigationView` (left drawer, menu: `drawer_menu.xml`, header: `nav_header.xml`)
2. A **top ConstraintLayout bar** (`@id/bar`) with teal background, hamburger icon, logo image, and a Lottie notification bell
3. A **FrameLayout** (`@id/fragment_container`) that hosts fragments
4. A **custom bottom navigation** (`bottom_nav.xml`) — a horizontal `LinearLayout` with 5 weighted tab items (NOT `BottomNavigationView`)

### 4.2 Bottom Navigation (5 Tabs)

**File:** `res/layout/bottom_nav.xml`

This is a **custom** bottom nav built with `LinearLayout` (not the Material `BottomNavigationView`). Each tab is a vertical `LinearLayout` with an `ImageView` + `TextView`:

| Tab ID | Icon | Label | Fragment |
|---|---|---|---|
| `nav_home` | `homes` | হোম | `HomeFragment` |
| `nav_notice` | `bell` | নোটিশ | `NoticeFragment` |
| `nav_promote` | `govtlogo` | সরকারি সেবা | `GovtServiceFragment` |
| `nav_post` | `serviccis` | সকল সেবা | `ServiceFragment` |
| `nav_profile` | `profile` | প্রোফাইল | `ProfileFragment` |

**Tab selection animation:** When a tab is selected, `HomeActivity.pushUpView()` uses `ObjectAnimator` to translate the tab up by 7% of its height and changes its background to `@drawable/red`. The previously selected tab is reset to its original position with `@drawable/gr`.

### 4.3 Drawer Navigation

**File:** `res/menu/drawer_menu.xml`

The left drawer has 4 groups:

| Group | Items |
|---|---|
| Main | Home, Promote, Service, Profile |
| সম্পর্কে (About) | About App, About Ads |
| যোগাযোগ করুন (Contact) | Support Call, Support Developer |
| অন্যান্য (Other) | Privacy Policy, Share, Exit |

**Drawer header** (`nav_header.xml`): 150dp horizontal layout with a 75dp rounded `CardView` containing the app icon, plus the Betagi logo image and tagline.

### 4.4 Fragment Switching

`HomeActivity.loadFragment(Fragment)` uses `FragmentManager.beginTransaction().replace().commit()`. It skips the transaction if the current fragment is the same class (prevents redundant reloads).

### 4.5 Service Grid Navigation

`ServiceFragment` displays a 3-column grid of 42 service items. `RecyclerAdapter` routes taps to specific activities via a `switch(title)` statement. Some items open directory activities (`UnifiedGovtOfficerActivity`, `UnifiedUserItemActivity`, `UnifiedBusinessItemActivity`, etc.), others open dedicated activities (`HospitalActivity`, `ClinicActivity`, `SpecialistsActivity`, `BloodDonationActivity`, `EmergencyNumbersActivity`, `BusActivity`, `ShopActivity`, `TouristActivity`, `NewspaperActivity`, `EduActivity`, `PostActivity`, `FreedomActivity`, `JulyActivity`, `CoupsActivity`, `SimActivity`, `UpazilaInfoActivity`, etc.).

---

## 5. Screen Inventory

### 5.1 Auth Screens

| Screen | Layout | Activity | Description |
|---|---|---|---|
| Login | `activity_login.xml` | `LoginActivity` | Phone + password, Remember Me, Forgot Password link, Google Sign-In button, Lottie loading. Background: `bgcityap` image at 0.4 alpha. Card with 20dp corners. Blue (#2196F3) accent. |
| Registration | `activity_registration.xml` | `RegistrationActivity` | Name, phone, password, address, union dropdown (AutoCompleteTextView), profile image picker. Same background pattern as login. |

### 5.2 Main Screens (Fragments inside HomeActivity)

| Fragment | Layout | Description |
|---|---|---|
| `HomeFragment` | `fragment_home.xml` → `home.xml` | Notice marquee (orange #FF6B35), weather (temp/feels-like/description/day/sunrise/sunset/refresh), image slider (ImageSlideshow, auto-cycle 2s), emergency hotlines (999/109/16263 horizontal scroll), city info cards (About App/About City/Facebook Page/Facebook Group). Fetches weather from OpenWeatherMap API + notices from server. |
| `NoticeFragment` | `fragment_notice.xml` | RecyclerView of notices with search bar, type filter chips (All/Important/General/Event/Holiday), union filter popup, SwipeRefreshLayout, empty state, admin FAB (only for admin users). |
| `GovtServiceFragment` | `fragment_govt_service.xml` | Government service cards: UNO info, Union info, ICT info, certificates (citizenship/character/death/birth/disability/unmarried/landless), e-passport, fee calculator, govt projects, govt websites, citizen services (complaint filing). |
| `ServiceFragment` | `fragment_service.xml` | 3-column grid of 42 service items via `RecyclerAdapter`. |
| `ProfileFragment` | `fragment_profile.xml` | Profile header (image, name, phone, union) + menu cards: Update Profile, Change Password, Ads, Facebook Page, Facebook Group, App Details, Developer Info, Logout. Change password opens a dialog. |

### 5.3 Directory & Service Activities

| Activity | Purpose |
|---|---|
| `BloodDonationActivity` | List blood donors, search by name, filter by union, call button, admin edit/delete |
| `AddBloodDonationActivity` | Add/edit donor form (name, blood group, phone, address, image) |
| `ClinicActivity` | List clinics, search, tap for detail |
| `ClinicOverviewActivity` | Single clinic detail (services, hours, phone, complaint phone) |
| `AddClinicActivity` | Add/edit clinic form |
| `SpecialistsActivity` | List specialist doctors |
| `AddUnifiedSpecialistDoctorActivity` | Add/edit doctor form |
| `UnifiedGovtOfficerActivity` | List govt officers (UNO, ICT, etc.) |
| `AddUnifiedGovtOfficerActivity` | Add/edit officer form |
| `UnifiedGovtItemActivity` | List govt items/institutions |
| `AddUnifiedGovtItemActivity` | Add/edit govt item form |
| `UnifiedBusinessItemActivity` | List businesses/shops |
| `AddUnifiedBusinessItemActivity` | Add/edit business form |
| `UnifiedUserItemActivity` | List important persons (teachers, journalists, etc.) |
| `AddUnifiedPersonActivity` | Add/edit person form |
| `PersonActivity` | Person directory (alternate) |

### 5.4 Info & Content Activities

| Activity | Purpose |
|---|---|
| `NoticeDetailsFragment` | Single notice detail (title, description, image, attachments) |
| `BudgetDetailsActivity` | Upazila budget breakdown by category (allocated/spent/remaining) |
| `EmergencyNumbersActivity` | List of emergency phone numbers (police, fire, hospital, ambulance) |
| `NotifiationActivity` | Notification list |
| `UpazilaInfoActivity` | Upazila information |
| `UnoActivity` | UNO (Upazila Nirbahi Officer) information |
| `UnionActivity` | Union Parishad information |
| `IctinfoActivity` | ICT Officer information |
| `AppsDetailsActivity` | About the app |
| `HospitalActivity` | Hospital list |
| `AnimalHospitalInformationActivity` | Animal hospital info |
| `TouristActivity` | Tourist spots |
| `NewspaperActivity` | Newspaper list |
| `BusActivity` | Bus services |
| `ShopActivity` | Shop/showroom directory |
| `PostActivity` | Post office info |
| `EduActivity` | Education institutions hub |
| `PrimaryActivity` | Primary schools |
| `HighActivity` | High schools |
| `CollegeActivity` | Colleges |
| `MadrasaActivity` | Madrasas |
| `TuitionActivity` | Coaching centers |
| `FreedomActivity` | Liberation War history |
| `JulyActivity` | July Revolution history |
| `CoupsActivity` | Military coups history |
| `SimActivity` | SIM card codes |
| `SimDetailActivity` | SIM detail |
| `InformationSubmitActivity` | Information submission form |
| `WebActivity` | Generic WebView host (for govt online services) |
| `MainActivity` | WebView host for external web content |
| `NothingActivity` | Placeholder/coming-soon screen |

### 5.5 Profile & Account Activities

| Activity | Purpose |
|---|---|
| `UpdateProfileActivity` | Update name, phone, address, profile image |
| `ProfileUpdateActivity` | Alternate profile update (older) |
| `ChangePasswordActivity` | Change password (old, new, confirm) |

---

## 6. Backend API Integration

### 6.1 Configuration

**File:** `Config.java`

```java
public static final String BASE_URL  = "https://nagoriksheba.com/betagi_backend/api/";
public static final String IMAGE_URL = "https://nagoriksheba.com/betagi_backend/uploads/profiles/";
public static final String UPLOADS_BASE_URL = "https://nagoriksheba.com/betagi_backend/uploads/";
public static final String PREF_NAME = "user_pref";
```

All API endpoint URLs are defined as `public static final String` constants in `Config.java`, grouped by entity:
- Auth: `LOGIN`, `REGISTER`, `PROFILE_URL`, `UPDATE_PROFILE_URL`, `CHANGE_PASSWORD_URL`, `ADMIN_LOGIN_URL`
- Notice: `NOTICE_LIST_URL`, `ADD_NOTICE_URL`, `UPDATE_NOTICE_URL`, `DELETE_NOTICE_URL`
- Budget: `BUDGET_DETAILS_URL`
- Business: `BUSINESS_ITEMS_URL`, `Add_BUSINESS_ITEMS_URL`, `UPDATE_UNIFIED_BUSINESS_ITEM`, `DELETE_UNIFIED_BUSINESS_ITEM`
- Blood Donor: `GET_DONOR`, `ADD_DONOR`, `UPDATE_DONOR`, `DELETE_DONOR`
- Clinic: `Get_Clinic`, `ADD_CLINIC`, `UPDATE_CLINIC`, `DELETE_CLINIC`
- Doctor: `DOCTOR_LIST_URL`, `GET_SPECIALIST_DOCTOR`, `ADD_SPECIALIST_DOCTOR`, `UPDATE_SPECIALIST_DOCTOR`, `DELETE_SPECIALIST_DOCTOR`
- Govt Item: `GET_UNIFIED_GOVT_ITEM`, `ADD_UNIFIED_GOVT_ITEM`, `UPDATE_UNIFIED_GOVT_ITEM`, `DELETE_UNIFIED_GOVT_ITEM`
- Govt Officer: `GET_UNIFIED_GOVT_OFFICER`, `ADD_UNIFIED_GOVT_OFFICER`, `UPDATE_UNIFIED_GOVT_OFFICER`, `DELETE_UNIFIED_GOVT_OFFICER`
- Person: `ADD_UNIFIED_PERSON_URL`, `GET_UNIFIED_PERSON_URL`, `UPDATE_UNIFIED_PERSON`, `DELETE_UNIFIED_PERSON`
- Complaints/Emergency/Notifications: `SUBMIT_COMPLAINT_URL`, `GET_EMERGENCY_NUMBERS_URL`, `GET_NOTIFICATIONS_URL`

### 6.2 Volley Singleton

`Config` also implements the Volley singleton pattern:
```java
public static synchronized Config getInstance(Context context)
public RequestQueue getRequestQueue()
public <T> void addToRequestQueue(Request<T> req)
```

### 6.3 Response Shapes

The server uses two response shapes — the app MUST handle both correctly:

| Endpoint Type | Response Shape | App Request Type |
|---|---|---|
| **List endpoints** (GET lists) | Raw JSON array `[...]` | `JsonArrayRequest` |
| **Single / Auth / Write** (GET single, POST, PUT, DELETE) | `{"success":true,"message":"...","data":{...}}` | `StringRequest` → parse `JSONObject` |
| **`profile.php`** (special) | `{"status":"success","data":{...}}` | `StringRequest` → check `optString("status")` |

### 6.4 Image URL Handling

**File:** `helper/ImageUtil.java`

The server returns image paths inconsistently:
- `login.php` / `register.php`: returns just the **filename** (basename) → prepend `Config.IMAGE_URL`
- All list/detail endpoints: returns the **full URL** via the server's `imageUrl()` helper → use directly

`ImageUtil.resolve(String image)` detects which shape was returned and produces a loadable URL:
```java
public static String resolve(String image) {
    if (TextUtils.isEmpty(image) || "default.png".equalsIgnoreCase(image)) return "";
    if (image.startsWith("http://") || image.startsWith("https://")) return image;
    return Config.IMAGE_URL + image;  // bare filename → prepend profiles/ URL
}
```

### 6.5 Networking Helpers

| Helper | Purpose |
|---|---|
| `AuthRequest` | `StringRequest` subclass that auto-attaches `Authorization: Bearer <token>` header from `SessionManager`. Used for all add/update/delete calls (server requires JWT). |
| `ImageUtil` | Image URL resolver (see above). |
| `SharedPreferencesHelper` | SharedPreferences wrapper. |

---

## 7. Authentication & Session

### 7.1 SessionManager

**File:** `SessionManager.java`

Uses `SharedPreferences` (`Config.PREF_NAME = "user_pref"`) to store:

| Key | Type | Purpose |
|---|---|---|
| `isLogin` | boolean | Login state |
| `id` | String | User ID |
| `name` | String | User name |
| `phone` | String | Phone number |
| `address` | String | Address |
| `union` | String | Union name |
| `imageUrl` | String | Profile image filename |
| `userType` | String | "user" or "admin" |
| `token` | String | JWT token (for Authorization header) |

**Key methods:**
- `saveUser(...)` — saves all fields + token
- `saveUser(...)` (overload) — backward-compat without token
- `isLogin()`, `logout()`, `hasToken()`
- `getToken()`, `getId()`, `getName()`, `getPhone()`, `getAddress()`, `getUnion()`, `getImageUrl()`, `getUserType()`
- `isAdmin()` — returns true if userType == "admin"

### 7.2 Login Flow

1. `LoginActivity` → user enters phone + password
2. POST to `Config.LOGIN` → server returns `{success, message, token, user:{id, name, phone, address, union_name, image, user_type}}`
3. `SessionManager.saveUser(...)` saves all fields + token
4. Navigate to `HomeActivity`

### 7.3 JWT Authorization

All write operations (add/update/delete) require the `Authorization: Bearer <token>` header. The app uses `AuthRequest` (extends `StringRequest`) which automatically attaches the header from `SessionManager.getToken()`. Without this, the server returns HTTP 401.

---

## 8. File Structure

```
user app/AndroidStudioProjects/
├── build.gradle.kts                      (top-level)
├── settings.gradle.kts
├── gradle.properties
├── gradle/
│   ├── libs.versions.toml                (version catalog)
│   └── wrapper/
├── gradlew, gradlew.bat
└── app/
    ├── build.gradle.kts                  (module config)
    ├── proguard-rules.pro
    └── src/main/
        ├── AndroidManifest.xml           (54 activities registered)
        ├── java/com/example/betagiesheva/
        │   ├── Config.java               (URL constants + Volley singleton)
        │   ├── SessionManager.java       (SharedPreferences auth/session)
        │   ├── LoginActivity.java        (launcher — phone+password login)
        │   ├── RegistrationActivity.java (register new user)
        │   ├── HomeActivity.java         (main host — drawer + bottom nav + fragments)
        │   ├── MainActivity.java         (WebView host for external content)
        │   ├── InformationSubmitActivity.java
        │   ├── UnifiedBusinessItem.java  (model helper)
        │   │
        │   ├── Fragment/                 (11 fragments)
        │   │   ├── HomeFragment.java
        │   │   ├── NoticeFragment.java
        │   │   ├── NoticeDetailsFragment.java
        │   │   ├── GovtServiceFragment.java
        │   │   ├── ServiceFragment.java
        │   │   ├── ProfileFragment.java
        │   │   ├── ComplaintFilingFragment.java
        │   │   ├── FreedomFragment.java
        │   │   ├── JulyhFragment.java
        │   │   ├── JulyheroFragment.java
        │   │   └── PdfFragment.java
        │   │
        │   ├── Adapter/                  (14 adapters)
        │   │   ├── RecyclerAdapter.java          (service grid → activity routing)
        │   │   ├── NoticeAdapter.java
        │   │   ├── DonorAdapter.java
        │   │   ├── ClinicAdapter.java
        │   │   ├── UnifiedBusinessAdapter.java
        │   │   ├── UnifiedGovtItemAdapter.java
        │   │   ├── UnifiedGovtOfficerAdapter.java
        │   │   ├── UnifiedSpecialistDoctorAdapter.java
        │   │   ├── UnifiedUserItemAdapter.java
        │   │   ├── PersonAdapter.java
        │   │   ├── EmergencyAdapter.java
        │   │   ├── BudgetCategoryAdapter.java
        │   │   ├── FreedomAdapter.java
        │   │   └── JulyAdapter.java
        │   │
        │   ├── Model/                    (14 models)
        │   │   ├── Item.java                     (service grid item)
        │   │   ├── NoticeModel.java
        │   │   ├── Donor.java
        │   │   ├── Clinic.java
        │   │   ├── UnifiedBusinessItem.java
        │   │   ├── UnifiedGovtItem.java
        │   │   ├── UnifiedGovtOfficer.java
        │   │   ├── UnifiedSpecialistDoctor.java
        │   │   ├── UnifiedPerson.java
        │   │   ├── Person.java
        │   │   ├── GovtOfficer.java
        │   │   ├── Complaint.java
        │   │   ├── EmergencyNumber.java
        │   │   └── BudgetCategoryModel.java
        │   │
        │   ├── helper/                    (7 helpers)
        │   │   ├── AuthRequest.java              (JWT StringRequest)
        │   │   ├── ImageUtil.java                (image URL resolver)
        │   │   ├── SharedPreferencesHelper.java
        │   │   ├── MyHelper.java                 (WebView helper interface)
        │   │   ├── ChromeClient.java             (WebChromeClient)
        │   │   ├── HelloWebViewClient.java       (WebViewClient)
        │   │   └── MyWebDownloader.java           (download manager)
        │   │
        │   └── [40+ Activity files]              (see Screen Inventory above)
        │
        └── res/
            ├── values/
            │   ├── themes.xml              (Theme.WebviewPro — Material3 Light NoActionBar)
            │   ├── styles.xml              (AppTheme, Theme.BetagiESeva, SpecialtyCard, ProfileMenuItem styles)
            │   ├── colors.xml              (purple/teal/black/white + text colors)
            │   ├── strings.xml             (Bengali strings + empty URL placeholders)
            │   ├── dimens.xml
            │   └── ic_launcher_background.xml
            ├── values-night/themes.xml     (dark mode theme)
            ├── values-v23/themes.xml       (edge-to-edge transparent system bars)
            ├── values-land/dimens.xml
            ├── values-w600dp/dimens.xml
            ├── values-w1240dp/dimens.xml
            ├── font/                       (17 Bengali + English fonts)
            ├── layout/                     (94 layouts — see full list below)
            ├── drawable/                   (404 vector + PNG drawables)
            ├── drawable-v24/               (87 PNG/JPG images for services/icons)
            ├── raw/                        (12 Lottie JSON animations)
            ├── anim/                       (top_anim.xml, bottom_anim.xml)
            ├── menu/
            │   └── drawer_menu.xml         (drawer navigation menu)
            ├── mipmap-*/                   (launcher icons in 5 densities)
            ├── mipmap-anydpi-v26/          (adaptive launcher icon)
            └── xml/
                ├── backup_rules.xml
                └── data_extraction_rules.xml
```

### Layout Files (94 total)

**Activity layouts (54):** `activity_login`, `activity_registration`, `activity_home`, `activity_main`, `activity_add_blood_donation`, `activity_add_clinic`, `activity_add_notice`, `activity_add_unified_business_item`, `activity_add_unified_govt_item`, `activity_add_unified_govt_officer`, `activity_add_unified_person`, `activity_add_unified_specialist_doctor`, `activity_animal_hospital_information`, `activity_apps_details`, `activity_blood_donation`, `activity_blood_donation2`, `activity_budget_details`, `activity_bus`, `activity_change_password`, `activity_clinic`, `activity_clinic_overview`, `activity_college`, `activity_coups`, `activity_edu`, `activity_emergency_numbers`, `activity_freedom`, `activity_high`, `activity_hospital`, `activity_ictinfo`, `activity_information_submit`, `activity_july`, `activity_madrasa`, `activity_newspaper`, `activity_nothing`, `activity_notifiation`, `activity_person`, `activity_post`, `activity_primary`, `activity_profile_update`, `activity_shop`, `activity_sim`, `activity_sim_detail`, `activity_specialists`, `activity_tourist`, `activity_tuition`, `activity_unified_business_item`, `activity_unified_govt_item`, `activity_unified_govt_officer`, `activity_unified_specialist_doctor`, `activity_unified_user_item`, `activity_union`, `activity_uno`, `activity_upazila_info`, `activity_update_profile`, `activity_web`

**Fragment layouts (11):** `fragment_home`, `fragment_notice`, `fragment_notice_details`, `fragment_govt_service`, `fragment_service`, `fragment_profile`, `fragment_complaint_filing`, `fragment_freedom`, `fragment_julyh`, `fragment_julyhero`, `fragment_pdf`

**Item layouts (13):** `item_notice`, `item_donor`, `item_clinic`, `item_unified_business_item`, `item_unified_govt`, `item_unified_govt_officer`, `item_unified_specialist_doctor`, `item_unified_user_item`, `item_person`, `item_emergency_number`, `item_attachment`, `grid_item`, `row_budget_category`

**Component layouts (16):** `home` (home screen content), `bottom_nav` (custom bottom navigation), `nav_header` (drawer header), `actionbar`, `dropdown_item`, `no_internet`, `dialog_change_password`, `dialog_developer_info`, `dialog_market_rate`, `custom_dialog_clinic_service`, `custom_dialog_doctor`, `custom_dialog_test_fee`, `custom_dialog_unified_specialist_doctor`, `custom_dialog_union`, `custom_dialog_uno`

---

## 9. Key Conventions

### 9.1 Naming

- **Activities:** `PascalCase` + `Activity` suffix (e.g., `BloodDonationActivity`)
- **Fragments:** `PascalCase` + `Fragment` suffix (e.g., `NoticeFragment`)
- **Adapters:** `PascalCase` + `Adapter` suffix (e.g., `DonorAdapter`)
- **Models:** `PascalCase` nouns (e.g., `Donor`, `NoticeModel`)
- **Layouts:** `snake_case` prefixed by type (`activity_`, `fragment_`, `item_`, `dialog_`)
- **Drawables:** `snake_case` (e.g., `baseline_phone_24`, `blood_donar`)
- **Java package:** `com.example.betagiesheva` (root) + `.Fragment`, `.Adapter`, `.Model`, `.helper` sub-packages

### 9.2 Bengali Text

- All user-facing text is in **Bengali** (বাংলা)
- Bengali fonts: `@font/bnlatxf` (UI), `@font/btxf` (headings), `@font/kalpurush` (body)
- String resources in `strings.xml` where applicable; many strings are inline in layouts
- Bengali digits (০-৯) used in some display text (e.g., hotline numbers "৯৯৯", "১০৯", "১৬২৬৩")

### 9.3 Networking Pattern

```java
// List endpoint (raw array)
JsonArrayRequest req = new JsonArrayRequest(Request.Method.GET, url, null,
        response -> { /* parse array */ },
        error -> { /* show error */ });
Config.getInstance(context).addToRequestQueue(req);

// Write endpoint (needs JWT)
AuthRequest req = new AuthRequest(Request.Method.POST, url,
        response -> { /* parse {success, message, data} */ },
        error -> { /* show error */ },
        context) {
    @Override protected Map<String, String> getParams() {
        Map<String, String> p = new HashMap<>();
        p.put("field", value);
        return p;
    }
};
Config.getInstance(context).addToRequestQueue(req);
```

### 9.4 Image Loading

```java
Glide.with(context)
     .load(ImageUtil.resolve(imageUrl))   // handles both basename and full URL
     .placeholder(R.drawable.profile)
     .error(R.drawable.profile)
     .into(imageView);
```

### 9.5 Admin-Only Features

The app checks `SessionManager.isAdmin()` (userType == "admin") to show/hide:
- Notice add FAB in `NoticeFragment`
- Edit/delete buttons in `DonorAdapter`, `NoticeAdapter`, and other adapters

---

## 10. How to Build & Run

### Prerequisites

- Android Studio (Ladybug or newer)
- JDK 11
- Android SDK with compileSdk 36

### Build

```bash
cd "user app/AndroidStudioProjects"
./gradlew assembleDebug
# Output: app/build/outputs/apk/debug/app-debug.apk
```

### Run

1. Open the `AndroidStudioProjects` folder in Android Studio
2. Wait for Gradle sync to complete
3. Connect an Android device (API 26+) or start an emulator
4. Click Run (▶)

### Backend Setup

The app requires the Betagi backend server running at `https://nagoriksheba.com/betagi_backend/api/`. See the server documentation for setup instructions.

---

## 11. Developer

**Md. Abdullah Al Hossain**
**App Developer**

বেতাগী ই-সেবা অ্যাপটি মো. আব্দুল্লাহ আল হোসেন কর্তৃক ডেভেলপ করা হয়েছে।

> আপনার সার্বিক সেবাই আমাদের লক্ষ্য।

---

*This README documents the user app as it exists in the original project. Any modifications should follow the established design system, naming conventions, and architecture documented above.*
