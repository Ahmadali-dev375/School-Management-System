# School Management & Examination System

A Flutter and Firebase-based school records and examination management system, designed and delivered as a complete client solution for managing student enrollment, teacher assignments, academic class structures, examination marks entry, automated grade computation, and PDF report-card generation.

> **Portfolio Notice**
>
> This repository documents the architecture and selected frontend portions of a client-delivered school records and examination-management application. Sensitive backend configuration, client assets, Firebase configuration, and private operational logic are intentionally excluded from the public portfolio repository.

---

## Overview

Educational institutions managing hundreds of students across multiple classes, sections, and subjects face a significant operational burden in maintaining accurate records, tracking examination performance, and producing timely academic reports. Manual or spreadsheet-driven systems are error-prone, difficult to scale, and slow to produce consolidated results.

This system was built to address those challenges by providing:

- **Centralized student and teacher record management** with structured class, section, and subject hierarchies
- **Teacher-scoped examination workflows** where teachers enter marks only for their assigned classes and sections
- **Automated result computation** including percentage calculation, 14-tier grade classification, and pass/fail determination
- **PDF report-card generation** with in-memory rendering and instant preview/print/share capabilities

The application is a focused records and examination management solution. It is **not** a full-scale school ERP — it does not include modules for attendance, fee collection, timetabling, homework, parent portals, messaging, or transport management.

---

## Core Features

### Teacher Authentication

Teachers authenticate using their national identity number (CNIC) and password. The system resolves the teacher's identity from Firestore, maps it to a corresponding Firebase Authentication account, and establishes an authorized session. Existing sessions are restored automatically on subsequent launches.

### Teacher Records

Complete teacher profiles are maintained including personal identity information, contact details, subject specialization, and assigned class-section combinations. Teacher records serve as the foundation for scoped access to marking workflows.

### Student Registration & Records

Students are registered with identity details (name, guardian information, CNIC/B-form number), roll number, class, section, gender, contact information, and address. The system validates for duplicate roll numbers within a class before creating records. Full CRUD operations (create, read, update, delete) are available for student management.

### Class, Section & Subject Management

Administrators configure the academic structure by creating classes, defining subject lists per class, and adding sections. This hierarchical setup drives the downstream workflows for student placement, teacher assignment, and examination mark recording.

### Teacher Assignment

Teachers are mapped to specific class-section combinations. These assignments determine which students a teacher can access for marks entry, enforcing a scoped examination workflow where each teacher operates only within their designated academic assignments.

### Marks Entry

A controlled dialog-based interface allows teachers to enter obtained and total marks for each subject, for each student, under either the Midterm or Final examination term. The system performs numeric validation, tracks which subjects have already been filled for a given term, and warns when overwriting existing marks data.

### Result Search & Aggregation

Results can be searched by selecting a class, section, and student. The system retrieves stored Midterm and Final marks, aggregates them by subject, and presents a comprehensive academic result view.

### Result Calculation

The system automates the complete result computation pipeline:

- Per-subject percentage: `(obtained / total) × 100`
- Grade classification using a 14-tier scale (detailed below)
- Overall percentage across all subjects
- Final pass/fail determination

### PDF Report Generation

Formatted PDF report cards are generated in-memory using the `pdf` package and rendered for preview, printing, and sharing via the `printing` package. Reports include student identity, class/section details, subject-wise marks tables, term breakdowns (where applicable), percentages, grades, and overall pass/fail status.

---

## System Architecture

```
┌──────────────────────────────┐
│       Flutter Client         │
│ StatefulWidget / setState    │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│ Authentication Workflow      │
│ Teacher Identity / Session   │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│ Academic Workflow            │
│ Classes / Sections / Subjects│
│ Students / Assignments       │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│ Examination Workflow         │
│ Midterm / Final / Subjects   │
│ Marks / Percentage / Grade   │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│ Reporting                    │
│ Result View → PDF Generation │
└──────────────────────────────┘
```

The application follows a **screen-centric architecture** where each screen manages its own state using `StatefulWidget` and `setState`. Asynchronous data operations are rendered through `FutureBuilder` and `StreamBuilder` widgets. Navigation uses standard `MaterialPageRoute` with `Navigator`. Shared UI elements (form fields, selection widgets, result cards, PDF builders) are extracted into reusable component and widget modules.

Firestore operations are performed directly within screens and widgets — there is no separate repository, service, or state management layer. This is a pragmatic design choice for the project's scope, not an oversight.

**This project does not use**: BLoC, Provider architecture, Clean Architecture, MVVM, repository pattern, or microservice decomposition.

---

## System Workflow

### Teacher Workflow

```
Application Launch
    ↓
Firebase Initialization
    ↓
Splash Screen
    ↓
Check Existing Authentication Session
    ↓
┌─── No Session ───────────────────────┐
│   Teacher Login                      │
│   → Enter CNIC + Password           │
│   → Resolve teacher record           │
│   → Firebase Authentication          │
└──────────────┬───────────────────────┘
               ↓
Existing Session / Successful Login
    ↓
Teacher Navigation (Bottom Navigation Bar)
    ├── Home      → Teacher information and dashboard
    ├── Adding    → Student registration
    ├── Records   → View / edit / delete student records
    ├── Marking   → Assigned class → section → student → term → subject → marks entry
    └── Results   → Class → section → student search → result calculation → PDF preview
```

### Administrative Workflow

```
Administrative Access
    ↓
Admin Dashboard
    ↓
Academic Management
    ├── Add Student
    ├── Add Teacher
    ├── Student Records
    ├── Teacher Records
    ├── Results
    ├── Create Classes
    ├── Manage Classes
    └── Teacher Permissions
```

Administrative workflows provide privileged management capabilities for teachers, students, classes, assignments, and academic records. The client-specific authorization implementation is intentionally excluded from this public portfolio repository.

---

## Verified Data Flows

### Teacher Authentication

| Stage | Detail |
|---|---|
| **Input** | CNIC + Password |
| **Processing** | Teacher identity lookup → corresponding authentication identity → Firebase Authentication |
| **Output** | Authorized teacher session |

### Teacher Registration

| Stage | Detail |
|---|---|
| **Input** | Identity, contact details, subject specialization, class-section assignments |
| **Processing** | Authentication account creation + teacher profile creation in Firestore |
| **Output** | Teacher record with scoped class assignments |

### Class Configuration

| Stage | Detail |
|---|---|
| **Input** | Class name, subjects list, section names |
| **Processing** | Structured class hierarchy creation in Firestore |
| **Output** | Available academic structure (class → subjects, class → sections) |

### Student Registration

| Stage | Detail |
|---|---|
| **Input** | Student identity, roll number, guardian details, class, section, contact data |
| **Processing** | Validation, duplicate roll-number checking, record creation |
| **Output** | Student record nested under class/section hierarchy |

### Teacher Assignment

| Stage | Detail |
|---|---|
| **Input** | Teacher identity, class, section |
| **Processing** | Class-section assignment mapping stored on teacher record |
| **Output** | Teacher marking scope (determines accessible students for marks entry) |

### Marks Entry

| Stage | Detail |
|---|---|
| **Input** | Student, examination term (Midterm/Final), subject, obtained marks, total marks |
| **Processing** | Numeric validation, term/subject result storage in Firestore |
| **Output** | Stored examination result under student → Results → term → subject |

### Result Processing

| Stage | Detail |
|---|---|
| **Input** | Stored Midterm and Final marks for all subjects |
| **Processing** | Aggregate marks, percentage calculation, grade classification, pass/fail determination |
| **Output** | Complete student academic result |

### PDF Generation

| Stage | Detail |
|---|---|
| **Input** | Student identity, calculated result data |
| **Processing** | Generate PDF bytes in-memory, apply report-card layout |
| **Output** | PDF preview with print/share capability |

---

## Conceptual Academic Data Model

The following represents the sanitized conceptual Firestore document hierarchy used in the active implementation. No real document IDs, student records, or personal information are included.

```
Classes
  └── {ClassId}
        ├── subjects: [String]
        └── Sections (subcollection)
              └── {SectionId}
                    └── Students (subcollection)
                          └── {StudentId}
                                ├── name
                                ├── rollNumber
                                ├── fatherName
                                ├── cnic
                                ├── phone
                                ├── Address
                                ├── Gender
                                ├── class
                                ├── section
                                ├── createdAt
                                └── Results (subcollection)
                                      ├── Midterm (document)
                                      │     └── {SubjectName}: { obtained: num, total: num }
                                      └── Final (document)
                                            └── {SubjectName}: { obtained: num, total: num }

Teachers
  └── Teacher{CNIC} (document)
        ├── uid
        ├── name
        ├── Father
        ├── cnic
        ├── email
        ├── gender
        ├── subject
        ├── contact
        ├── address
        └── assignedClasses: [ { class: String, section: String } ]
```

---

## Academic Term & Session Design

### Active Implementation

The system supports two examination terms:

- **Midterm** — mid-session assessment
- **Final** — end-of-session assessment

Each subject stores `obtained` and `total` marks independently under the corresponding term document. Reports can aggregate results across both terms, computing combined percentages and grades from the Midterm + Final data.

### Academic Year Limitation

The active result storage model does **not** namespace results by academic year or session. Results are stored directly under:

```
Students/{studentId}/Results/Midterm
Students/{studentId}/Results/Final
```

This means that if the same student document structure were reused across multiple academic years, the corresponding Midterm and Final records would be overwritten rather than preserved as historical data.

### Exploratory Design (Not Active)

An older implementation exists in `lib/Screens/CopyData.dart` containing commented-out code that explored concepts related to:

- Academic year handling (`AcademicYears` collection)
- Copying student data between academic year hierarchies
- Class promotion / history workflows

This prototype is **not part of the active delivered workflow**. It represents an explored but unfinished design direction.

### Month Handling

No month-based academic handling exists in the active codebase. The system operates exclusively on the Midterm/Final term model.

---

## Marks & Result Processing

### Marks Entry Workflow

1. Teacher selects their assigned class and section
2. Student list loads for the selected class-section combination
3. Teacher opens the marks entry dialog for a specific student
4. Subjects are loaded from the class configuration
5. Teacher selects term (Midterm or Final) and subject
6. Teacher enters obtained marks and total marks
7. Numeric validation is performed
8. Marks are saved to Firestore under the student's Results subcollection
9. Already-filled subjects are tracked and indicated visually

### Result Calculation Pipeline

```
Subject Result
  → obtained marks / total marks

Term Result
  → aggregate all subjects for a given term

Combined Result (where applicable)
  → combine Midterm + Final obtained and total marks

Percentage
  = (total obtained / total possible) × 100

Grade Classification
  → 14-tier scale lookup

Pass / Fail
  → grade != "F"
```

### Implemented Grading Scale

The following grading thresholds are verified from the active source code:

| Percentage Range | Grade |
|---|---|
| 96% – 100% | A+ |
| 91% – 95% | A |
| 86% – 90% | A- |
| 81% – 85% | B+ |
| 76% – 80% | B |
| 71% – 75% | B- |
| 66% – 70% | C+ |
| 61% – 65% | C |
| 56% – 60% | C- |
| 51% – 55% | D+ |
| 46% – 50% | D |
| 41% – 45% | D- |
| 31% – 40% | E |
| Below 31% | F |

**Pass/Fail Rule**: A student passes if and only if their final grade is not `"F"`.

---

## PDF Report Generation

The reporting pipeline operates entirely in-memory without writing intermediate files to disk:

1. **Data Collection**: Student identity fields and calculated result data are assembled
2. **Layout Construction**: The `pdf` package (`pw.Document`) constructs a structured report-card layout including:
   - Student header (name, class, section, roll number)
   - Subject-wise marks table with columns for subject name, obtained marks, total marks, percentage, and grade
   - Term breakdown (Midterm vs Final) where applicable
   - Overall percentage, overall grade, and pass/fail status
3. **Asset Integration**: School branding assets are loaded from bundled application assets for the delivered client version
4. **Rendering**: The document is rendered to PDF bytes (`Uint8List`)
5. **Preview & Output**: The `printing` package's `PdfPreview` widget provides immediate on-device preview with options to print or share the generated report

---

## Technology Stack

| Category | Technology |
|---|---|
| Framework | Flutter |
| Language | Dart |
| Authentication | Firebase Authentication (`firebase_auth`) |
| Database | Cloud Firestore (`cloud_firestore`) |
| PDF Generation | `pdf` |
| PDF Preview & Printing | `printing` |
| Navigation UI | `curved_navigation_bar` |
| User Feedback | `fluttertoast` |

---

## Privacy & Repository Scope

This project was delivered to a client educational institution. The public repository intentionally excludes:

- **Firebase configuration** — project identity, API keys, and all platform-specific service files
- **Client branding assets** — logos, institutional images, and proprietary visual material
- **Backend security implementation** — administrative authorization logic and access-control mechanisms
- **Real data** — no actual student, teacher, or institutional records are included
- **Signing credentials** — keystores, certificates, and environment secrets

The repository exists to demonstrate:

- Flutter application architecture and engineering
- Firebase-backed academic data modeling
- Examination workflow design
- Result computation and automated reporting
- System-design thinking for real-world institutional software

---

## Known Design Limitations

- **Academic year isolation**: The active result model stores Midterm and Final results without session/year namespacing. Multi-year historical preservation would require structural changes to the data model.
- **Academic year promotion**: Year-to-year class promotion and historical data migration were explored in an early prototype but are not part of the active delivered system.
- **Direct Firestore access**: Business logic and database operations are embedded directly in screen widgets rather than abstracted into separate service or repository layers.
- **Mobile-first design**: The UI layout targets mobile devices and was not optimized for responsive desktop or web viewports.
- **Administrative authorization**: Some administrative access-control logic belongs to the private client implementation and is excluded from this repository.
- **Public repository scope**: This repository is a portfolio documentation version, not a deployable copy of the complete delivered backend system.

---

## Project Status

**Client-delivered project** — portfolio documentation version.

This repository presents the architectural design, Flutter engineering patterns, and academic workflow implementation of a delivered client system. It is not intended as a standalone deployable application.

---

## Author

**Ahmad Ali**
