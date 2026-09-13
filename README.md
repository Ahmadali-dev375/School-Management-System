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

Teachers authenticate using their national identity number (CNIC) and password.

### Teacher Records

Complete teacher profiles are maintained, including personal identity information, contact details, subject specialization, and assigned class-section combinations.
### Student Registration & Records

Students are registered with identity details (name, guardian information, CNIC/B-form number), roll number, class, section, gender, contact information, and address.

### Class, Section & Subject Management

Administrators configure the academic structure by creating classes, defining subject lists per class, and adding sections.

### Teacher Assignment

Teachers are mapped to specific class-section combinations. 

### Marks Entry

A controlled dialog-based interface allows teachers to enter obtained and total marks for each subject, for each student, either the Midterm or Final examination term.

### Result Search & Aggregation

Results can be searched by selecting a class, section, and student.

### Result Calculation

The system automates the entire result computation process.

### PDF Report Generation

The system generates formatted PDF report cards in memory for preview, printing, and sharing.

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
## Firebase Database Architecture

The following represents the sanitized conceptual Firestore document hierarchy used in the active implementation.

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

Each subject stores `obtained` and `total` marks independently under the corresponding term document.

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

---

## Technology Stack

| Category | Technology |
|---|---|
| Framework | Flutter |
| Language | Dart |
| Authentication | Firebase Authentication (`firebase_auth`) |
| Database | Cloud Firestore (`cloud_firestore`) |
| PDF Generation | `pdf` |
| Navigation UI | `curved_navigation_bar` |
| User Feedback | `fluttertoast` |

---

## Known Design Limitations

- **Academic year isolation**: The active result model stores Midterm and Final results without session/year namespacing.
- **Direct Firestore access**: Business logic and database operations are embedded directly in screen widgets rather than abstracted into a separate service.
- **Mobile-first design**: The UI layout targets mobile devices and was not optimized for responsive desktop or web viewports.
- **Administrative authorization**: Some administrative access-control logic belongs to the private client implementation and is excluded from this repository.


---

## Project Status

**Client-delivered project**

This repository presents the architectural design, Flutter engineering patterns, and academic workflow implementation of a delivered client system.

---

## Author

**Ahmad Ali**
