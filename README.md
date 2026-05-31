✈️ Airport Management System
A database-driven system for efficiently managing flights, bookings, passengers, and airport staff — built as part of a DBMS coursework project.

📌 Overview
The Airport Management System models the core operations of an airport using a relational database. It demonstrates real-world application of database design, SQL querying, and PL/SQL automation through stored procedures, triggers, and functions.

🛠️ Tech Stack
LayerTechnologyDatabaseMySQLQuery LanguageSQLProcedural LanguagePL/SQLDesign ConceptsER/EER Diagrams, Normalization (up to 3NF)

⚙️ Features

Flight Management — Add, update, and retrieve flight schedules and details
Passenger Records — Store and manage passenger profiles and travel history
Booking System — Handle reservations with automated validation and conflict checks
Staff Management — Maintain staff roles, shift schedules, and flight assignments
Triggers & Procedures — Automate workflows and enforce data integrity rules
Cursors & Functions — Support complex data traversal and reusable logic


🗂️ Project Structure
airport-management-system/
│
├── schema/
│   ├── create_tables.sql        # DDL — table definitions and constraints
│   └── insert_data.sql          # Sample/seed data
│
├── procedures/
│   ├── booking_procedures.sql   # Booking management logic
│   ├── flight_procedures.sql    # Flight operations
│   └── staff_procedures.sql     # Staff assignment logic
│
├── triggers/
│   └── triggers.sql             # Data integrity and automation triggers
│
├── functions/
│   └── functions.sql            # Reusable PL/SQL functions
│
├── cursors/
│   └── cursors.sql              # Cursor-based data traversal
│
├── diagrams/
│   ├── er_diagram.png           # Entity-Relationship diagram
│   └── eer_diagram.png          # Enhanced ER diagram
│
└── README.md

Adjust the structure above to match your actual files.


🗃️ Database Design
Entities

Flight — Flight number, origin, destination, schedule, status
Passenger — Personal details, contact info, booking history
Booking — Reservation ID, seat, class, payment status
Staff — Employee ID, role, department, shift assignments
Gate / Terminal — Gate assignments and terminal mapping

Normalization
The schema is normalized up to Third Normal Form (3NF) to eliminate redundancy and ensure data integrity.

🚀 Getting Started
Prerequisites

MySQL 8.0 or higher
A SQL client (MySQL Workbench, DBeaver, or CLI)

Setup

Clone the repository:

bash   git clone https://github.com/your-username/airport-management-system.git
   cd airport-management-system

Create the database and run the schema:

sql   CREATE DATABASE airport_db;
   USE airport_db;
   SOURCE schema/create_tables.sql;

Load sample data:

sql   SOURCE schema/insert_data.sql;

Load procedures, triggers, and functions:

sql   SOURCE procedures/booking_procedures.sql;
   SOURCE triggers/triggers.sql;
   SOURCE functions/functions.sql;

📖 Usage Examples
sql-- View all upcoming flights
SELECT * FROM flights WHERE departure_time > NOW();

-- Book a seat for a passenger
CALL book_seat(passenger_id, flight_id, seat_class);

-- Get all bookings for a specific flight
SELECT * FROM bookings WHERE flight_id = 101;

-- Check staff schedule
SELECT * FROM staff_schedules WHERE staff_id = 42;

📐 ER Diagram

(Add your ER/EER diagram image here)

diagrams/er_diagram.png
diagrams/eer_diagram.png

🎓 Academic Context
This project was developed as part of a Database Management Systems (DBMS) course. It covers:

Conceptual and logical database design (ER/EER modeling)
Relational schema creation and normalization
Advanced SQL querying
PL/SQL programming — stored procedures, functions, triggers, and cursors


📄 License
This project is for educational purposes. Feel free to reference or adapt it for learning.
