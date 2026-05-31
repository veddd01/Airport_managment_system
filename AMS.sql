-- =============================================================================
-- AIRPORT MANAGEMENT SYSTEM (AMS)
-- =============================================================================
-- Description : Complete schema, seed data, indexes, stored procedures,
--               functions, triggers, and utility PL/SQL blocks for an
--               Airport Management System.
-- Database    : Oracle 12c+
-- Encoding    : UTF-8
-- =============================================================================


-- =============================================================================
-- 0. CLEANUP — Drop existing objects in reverse-dependency order
-- =============================================================================

-- Triggers
BEGIN EXECUTE IMMEDIATE 'DROP TRIGGER log_ticket_deletion';   EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TRIGGER check_passenger_age';    EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TRIGGER update_flight_status';   EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Functions
BEGIN EXECUTE IMMEDIATE 'DROP FUNCTION calculate_total_price'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP FUNCTION get_employee_details';  EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP FUNCTION get_airport_name';      EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Procedures
BEGIN EXECUTE IMMEDIATE 'DROP PROCEDURE insert_passenger';         EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP PROCEDURE update_passenger_details'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP PROCEDURE delete_ticket';            EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Tables (reverse dependency order)
BEGIN EXECUTE IMMEDIATE 'DROP TABLE DELETED_TICKETS';  EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE SERVES';           EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE TICKET';           EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE PASSENGER';        EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE EMPLOYEE';         EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE FLIGHTS';          EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE CONTAIN';          EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AIRLINE';          EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AIRPORT';          EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE CITY';             EXCEPTION WHEN OTHERS THEN NULL; END;
/


-- =============================================================================
-- 1. TABLE DEFINITIONS (DDL)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1.1 CITY
-- -----------------------------------------------------------------------------
CREATE TABLE CITY (
    CNAME   VARCHAR2(15)  NOT NULL,
    STATE   VARCHAR2(15),
    COUNTRY VARCHAR2(30),
    PRIMARY KEY (CNAME)
);

-- -----------------------------------------------------------------------------
-- 1.2 AIRPORT
-- -----------------------------------------------------------------------------
CREATE TABLE AIRPORT (
    AP_NAME VARCHAR2(100) NOT NULL,
    STATE   VARCHAR2(15),
    COUNTRY VARCHAR2(30),
    CNAME   VARCHAR2(15),
    PRIMARY KEY (AP_NAME),
    FOREIGN KEY (CNAME) REFERENCES CITY(CNAME) ON DELETE CASCADE
);

-- -----------------------------------------------------------------------------
-- 1.3 AIRLINE
-- -----------------------------------------------------------------------------
CREATE TABLE AIRLINE (
    AIRLINEID       VARCHAR2(3)  NOT NULL,
    AL_NAME         VARCHAR2(50),
    THREE_DIGIT_CODE VARCHAR2(3),
    PRIMARY KEY (AIRLINEID)
);

-- -----------------------------------------------------------------------------
-- 1.4 CONTAIN  (many-to-many: AIRLINE <-> AIRPORT)
-- -----------------------------------------------------------------------------
CREATE TABLE CONTAIN (
    AIRLINEID VARCHAR2(10)  NOT NULL,
    AP_NAME   VARCHAR2(100) NOT NULL,
    PRIMARY KEY (AIRLINEID, AP_NAME),
    FOREIGN KEY (AIRLINEID) REFERENCES AIRLINE(AIRLINEID) ON DELETE CASCADE,
    FOREIGN KEY (AP_NAME)   REFERENCES AIRPORT(AP_NAME)  ON DELETE CASCADE
);

-- -----------------------------------------------------------------------------
-- 1.5 FLIGHTS
-- -----------------------------------------------------------------------------
CREATE TABLE FLIGHTS (
    FLIGHT_CODE  VARCHAR2(10)  NOT NULL,
    SOURCE       VARCHAR2(3),
    DESTINATION  VARCHAR2(3),
    ARRIVAL      VARCHAR2(10),
    DEPARTURE    VARCHAR2(10),
    STATUS       VARCHAR2(10),
    DURATION     NUMBER,          -- duration in minutes for accurate calculations
    FLIGHTTYPE   VARCHAR2(15),
    LAYOVER_TIME NUMBER DEFAULT NULL, -- minutes; NULL = not applicable
    NO_OF_STOPS  INT,
    AIRLINEID    VARCHAR2(3),
    PRIMARY KEY (FLIGHT_CODE),
    FOREIGN KEY (AIRLINEID) REFERENCES AIRLINE(AIRLINEID) ON DELETE CASCADE
);

-- -----------------------------------------------------------------------------
-- 1.6 EMPLOYEE
-- -----------------------------------------------------------------------------
CREATE TABLE EMPLOYEE (
    SSN      INT            PRIMARY KEY,
    NAME     VARCHAR2(50),
    ADDRESS  VARCHAR2(100),
    PHONE    VARCHAR2(20),
    AGE      INT,
    JOB_TYPE VARCHAR2(50),
    SHIFT    VARCHAR2(20),
    AP_NAME  VARCHAR2(100),  -- Fixed: was VARCHAR(50), must match AIRPORT.AP_NAME
    FOREIGN KEY (AP_NAME) REFERENCES AIRPORT(AP_NAME)
);

-- -----------------------------------------------------------------------------
-- 1.7 PASSENGER
-- -----------------------------------------------------------------------------
CREATE TABLE PASSENGER (
    PID         INT           NOT NULL,
    PASSPORT_NO VARCHAR2(20)  NOT NULL,
    FNAME       VARCHAR2(50),
    ADDRESS     VARCHAR2(100),
    PHONE       VARCHAR2(15),
    AGE         INT,
    SSN         INT,
    AP_NAME     VARCHAR2(100),
    PRIMARY KEY (PID, PASSPORT_NO),
    FOREIGN KEY (SSN)     REFERENCES EMPLOYEE(SSN),
    FOREIGN KEY (AP_NAME) REFERENCES AIRPORT(AP_NAME)
);

-- -----------------------------------------------------------------------------
-- 1.8 SERVES  (EMPLOYEE serves PASSENGER)
-- -----------------------------------------------------------------------------
CREATE TABLE SERVES (
    SSN         INT           NOT NULL,
    PID         INT           NOT NULL,
    PASSPORT_NO VARCHAR2(20)  NOT NULL,  -- Fixed: was VARCHAR(10), must match PASSENGER
    PRIMARY KEY (SSN, PID, PASSPORT_NO),
    FOREIGN KEY (SSN)              REFERENCES EMPLOYEE(SSN),
    FOREIGN KEY (PID, PASSPORT_NO) REFERENCES PASSENGER(PID, PASSPORT_NO)
);

-- -----------------------------------------------------------------------------
-- 1.9 TICKET
-- -----------------------------------------------------------------------------
CREATE TABLE TICKET (
    TICKETNO        INT            PRIMARY KEY,
    PID             INT,
    PASSPORT_NO     VARCHAR2(20),
    SEAT_NO         VARCHAR2(10),
    CLASS           VARCHAR2(20),  -- Fixed: was VARCHAR(10), 'First Class' wouldn't fit
    PRICE           DECIMAL(10, 2),
    DATE_OF_BOOKING DATE,
    FLIGHT_CODE     VARCHAR2(10),  -- Added: enables price-per-flight queries
    FOREIGN KEY (PID, PASSPORT_NO) REFERENCES PASSENGER(PID, PASSPORT_NO),
    FOREIGN KEY (FLIGHT_CODE)      REFERENCES FLIGHTS(FLIGHT_CODE) ON DELETE SET NULL
);

-- -----------------------------------------------------------------------------
-- 1.10 DELETED_TICKETS  (audit log for ticket deletions)
-- -----------------------------------------------------------------------------
CREATE TABLE DELETED_TICKETS (
    TICKETNO      INT  PRIMARY KEY,
    DELETION_DATE DATE
);


-- =============================================================================
-- 2. INDEXES
-- =============================================================================
-- FK columns and frequently queried columns benefit from explicit indexes.

-- AIRPORT
CREATE INDEX IDX_AIRPORT_CNAME        ON AIRPORT(CNAME);

-- CONTAIN
CREATE INDEX IDX_CONTAIN_AIRLINEID    ON CONTAIN(AIRLINEID);
CREATE INDEX IDX_CONTAIN_AP_NAME      ON CONTAIN(AP_NAME);

-- FLIGHTS
CREATE INDEX IDX_FLIGHTS_AIRLINEID    ON FLIGHTS(AIRLINEID);
CREATE INDEX IDX_FLIGHTS_SOURCE       ON FLIGHTS(SOURCE);
CREATE INDEX IDX_FLIGHTS_DESTINATION  ON FLIGHTS(DESTINATION);
CREATE INDEX IDX_FLIGHTS_STATUS       ON FLIGHTS(STATUS);

-- EMPLOYEE
CREATE INDEX IDX_EMPLOYEE_AP_NAME     ON EMPLOYEE(AP_NAME);

-- PASSENGER
CREATE INDEX IDX_PASSENGER_SSN        ON PASSENGER(SSN);
CREATE INDEX IDX_PASSENGER_AP_NAME    ON PASSENGER(AP_NAME);

-- TICKET
CREATE INDEX IDX_TICKET_PID_PASSPORT  ON TICKET(PID, PASSPORT_NO);
CREATE INDEX IDX_TICKET_FLIGHT_CODE   ON TICKET(FLIGHT_CODE);


-- =============================================================================
-- 3. SEED DATA (DML)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 3.1 CITY
-- -----------------------------------------------------------------------------
INSERT ALL
    INTO CITY (CNAME, STATE, COUNTRY) VALUES ('Louisville',     'Kentucky',    'United States')
    INTO CITY (CNAME, STATE, COUNTRY) VALUES ('Chandigarh',     'Chandigarh',  'India')
    INTO CITY (CNAME, STATE, COUNTRY) VALUES ('Fort Worth',     'Texas',       'United States')
    INTO CITY (CNAME, STATE, COUNTRY) VALUES ('Delhi',          'Delhi',       'India')
    INTO CITY (CNAME, STATE, COUNTRY) VALUES ('Mumbai',         'Maharashtra', 'India')
    INTO CITY (CNAME, STATE, COUNTRY) VALUES ('San Francisco',  'California',  'United States')
    INTO CITY (CNAME, STATE, COUNTRY) VALUES ('Frankfurt',      'Hesse',       'Germany')
    INTO CITY (CNAME, STATE, COUNTRY) VALUES ('Houston',        'Texas',       'United States')
    INTO CITY (CNAME, STATE, COUNTRY) VALUES ('New York City',  'New York',    'United States')
    INTO CITY (CNAME, STATE, COUNTRY) VALUES ('Tampa',          'Florida',     'United States')
SELECT 1 FROM DUAL;

-- -----------------------------------------------------------------------------
-- 3.2 AIRPORT
-- -----------------------------------------------------------------------------
INSERT ALL
    INTO AIRPORT (AP_NAME, STATE, COUNTRY, CNAME)
        VALUES ('Louisville International Airport',          'Kentucky',    'United States', 'Louisville')
    INTO AIRPORT (AP_NAME, STATE, COUNTRY, CNAME)
        VALUES ('Chandigarh International Airport',          'Chandigarh',  'India',         'Chandigarh')
    INTO AIRPORT (AP_NAME, STATE, COUNTRY, CNAME)
        VALUES ('Indira Gandhi International Airport',       'Delhi',       'India',         'Delhi')
    INTO AIRPORT (AP_NAME, STATE, COUNTRY, CNAME)
        VALUES ('Chhatrapati Shivaji International Airport', 'Maharashtra', 'India',         'Mumbai')
    INTO AIRPORT (AP_NAME, STATE, COUNTRY, CNAME)
        VALUES ('San Francisco International Airport',       'California',  'United States', 'San Francisco')
    INTO AIRPORT (AP_NAME, STATE, COUNTRY, CNAME)
        VALUES ('Frankfurt Airport',                         'Hesse',       'Germany',       'Frankfurt')
SELECT 1 FROM DUAL;

-- -----------------------------------------------------------------------------
-- 3.3 AIRLINE
-- -----------------------------------------------------------------------------
INSERT ALL
    INTO AIRLINE (AIRLINEID, AL_NAME, THREE_DIGIT_CODE) VALUES ('AA', 'American Airlines', '001')
    INTO AIRLINE (AIRLINEID, AL_NAME, THREE_DIGIT_CODE) VALUES ('AI', 'Air India Limited', '098')
    INTO AIRLINE (AIRLINEID, AL_NAME, THREE_DIGIT_CODE) VALUES ('LH', 'Lufthansa',         '220')
    INTO AIRLINE (AIRLINEID, AL_NAME, THREE_DIGIT_CODE) VALUES ('BA', 'British Airways',    '125')
    INTO AIRLINE (AIRLINEID, AL_NAME, THREE_DIGIT_CODE) VALUES ('QR', 'Qatar Airways',      '157')
    INTO AIRLINE (AIRLINEID, AL_NAME, THREE_DIGIT_CODE) VALUES ('9W', 'Jet Airways',        '589')
    INTO AIRLINE (AIRLINEID, AL_NAME, THREE_DIGIT_CODE) VALUES ('EK', 'Emirates',           '176')
    INTO AIRLINE (AIRLINEID, AL_NAME, THREE_DIGIT_CODE) VALUES ('EY', 'Etihad Airways',     '607')
SELECT 1 FROM DUAL;

-- -----------------------------------------------------------------------------
-- 3.4 CONTAIN
-- -----------------------------------------------------------------------------
INSERT ALL
    INTO CONTAIN (AIRLINEID, AP_NAME) VALUES ('AA', 'Louisville International Airport')
    INTO CONTAIN (AIRLINEID, AP_NAME) VALUES ('AI', 'Chandigarh International Airport')
    INTO CONTAIN (AIRLINEID, AP_NAME) VALUES ('LH', 'Indira Gandhi International Airport')
    INTO CONTAIN (AIRLINEID, AP_NAME) VALUES ('BA', 'Chhatrapati Shivaji International Airport')
    INTO CONTAIN (AIRLINEID, AP_NAME) VALUES ('QR', 'San Francisco International Airport')
SELECT 1 FROM DUAL;

-- -----------------------------------------------------------------------------
-- 3.5 FLIGHTS
--     DURATION is now in minutes. LAYOVER_TIME is minutes or NULL.
-- -----------------------------------------------------------------------------
INSERT ALL
    INTO FLIGHTS (FLIGHT_CODE, SOURCE, DESTINATION, ARRIVAL, DEPARTURE, STATUS, DURATION, FLIGHTTYPE, LAYOVER_TIME, NO_OF_STOPS, AIRLINEID)
        VALUES ('AL2014', 'BOM', 'DFW', '02:10', '03:15', 'On-time', 1440, 'Connecting', NULL,  3, 'AA')
    INTO FLIGHTS (FLIGHT_CODE, SOURCE, DESTINATION, ARRIVAL, DEPARTURE, STATUS, DURATION, FLIGHTTYPE, LAYOVER_TIME, NO_OF_STOPS, AIRLINEID)
        VALUES ('QR2305', 'BOM', 'DFW', '13:00', '13:55', 'Delayed', 1260, 'Non-stop',   0,     0, 'QR')
    INTO FLIGHTS (FLIGHT_CODE, SOURCE, DESTINATION, ARRIVAL, DEPARTURE, STATUS, DURATION, FLIGHTTYPE, LAYOVER_TIME, NO_OF_STOPS, AIRLINEID)
        VALUES ('EY1234', 'JFK', 'TPA', '19:20', '20:05', 'On-time', 960,  'Connecting', NULL,  5, 'EY')
    INTO FLIGHTS (FLIGHT_CODE, SOURCE, DESTINATION, ARRIVAL, DEPARTURE, STATUS, DURATION, FLIGHTTYPE, LAYOVER_TIME, NO_OF_STOPS, AIRLINEID)
        VALUES ('LH9876', 'JFK', 'BOM', '05:50', '06:35', 'On-time', 1080, 'Non-stop',   0,     0, 'LH')
    INTO FLIGHTS (FLIGHT_CODE, SOURCE, DESTINATION, ARRIVAL, DEPARTURE, STATUS, DURATION, FLIGHTTYPE, LAYOVER_TIME, NO_OF_STOPS, AIRLINEID)
        VALUES ('BA1689', 'FRA', 'DEL', '10:20', '10:55', 'On-time', 840,  'Non-stop',   0,     0, 'BA')
    INTO FLIGHTS (FLIGHT_CODE, SOURCE, DESTINATION, ARRIVAL, DEPARTURE, STATUS, DURATION, FLIGHTTYPE, LAYOVER_TIME, NO_OF_STOPS, AIRLINEID)
        VALUES ('AA4367', 'SFO', 'FRA', '18:10', '18:55', 'On-time', 1260, 'Non-stop',   0,     0, 'AA')
    INTO FLIGHTS (FLIGHT_CODE, SOURCE, DESTINATION, ARRIVAL, DEPARTURE, STATUS, DURATION, FLIGHTTYPE, LAYOVER_TIME, NO_OF_STOPS, AIRLINEID)
        VALUES ('QR1902', 'IXC', 'IAH', '22:00', '22:50', 'Delayed', 1680, 'Non-stop',   300,   1, 'QR')
    INTO FLIGHTS (FLIGHT_CODE, SOURCE, DESTINATION, ARRIVAL, DEPARTURE, STATUS, DURATION, FLIGHTTYPE, LAYOVER_TIME, NO_OF_STOPS, AIRLINEID)
        VALUES ('BA3056', 'BOM', 'DFW', '02:15', '02:55', 'On-time', 1740, 'Connecting', NULL,  3, 'BA')
    INTO FLIGHTS (FLIGHT_CODE, SOURCE, DESTINATION, ARRIVAL, DEPARTURE, STATUS, DURATION, FLIGHTTYPE, LAYOVER_TIME, NO_OF_STOPS, AIRLINEID)
        VALUES ('EK3456', 'BOM', 'SFO', '18:50', '19:40', 'On-time', 1800, 'Non-stop',   0,     0, 'EK')
    INTO FLIGHTS (FLIGHT_CODE, SOURCE, DESTINATION, ARRIVAL, DEPARTURE, STATUS, DURATION, FLIGHTTYPE, LAYOVER_TIME, NO_OF_STOPS, AIRLINEID)
        VALUES ('9W2334', 'IAH', 'DEL', '23:00', '13:45', 'On-time', 1380, 'Direct',     0,     0, '9W')
SELECT 1 FROM DUAL;

-- -----------------------------------------------------------------------------
-- 3.6 EMPLOYEE
--     Fixed: 'Louisville InternationalAirport' → 'Louisville International Airport'
-- -----------------------------------------------------------------------------
INSERT INTO EMPLOYEE (SSN, NAME, ADDRESS, PHONE, AGE, JOB_TYPE, SHIFT, AP_NAME)
VALUES (123456789, 'John Doe',        '123 Main St, Anytown',           '555-1234', 30, 'Manager',          'Day',   'Louisville International Airport');

INSERT INTO EMPLOYEE (SSN, NAME, ADDRESS, PHONE, AGE, JOB_TYPE, SHIFT, AP_NAME)
VALUES (987654321, 'Jane Smith',      '456 Elm St, Othertown',          '555-5678', 25, 'Assistant',         'Night', 'Chhatrapati Shivaji International Airport');

INSERT INTO EMPLOYEE (SSN, NAME, ADDRESS, PHONE, AGE, JOB_TYPE, SHIFT, AP_NAME)
VALUES (111111111, 'Alice Johnson',   '789 Oak St, Anytown',            '555-1111', 28, 'Receptionist',      'Day',   'Louisville International Airport');

INSERT INTO EMPLOYEE (SSN, NAME, ADDRESS, PHONE, AGE, JOB_TYPE, SHIFT, AP_NAME)
VALUES (222222222, 'Bob Smith',       '456 Pine St, Othertown',         '555-2222', 35, 'Security',          'Night', 'Chhatrapati Shivaji International Airport');

INSERT INTO EMPLOYEE (SSN, NAME, ADDRESS, PHONE, AGE, JOB_TYPE, SHIFT, AP_NAME)
VALUES (333333333, 'Charlie Brown',   '123 Maple St, Anothertown',     '555-3333', 40, 'Janitor',           'Day',   'Louisville International Airport');

INSERT INTO EMPLOYEE (SSN, NAME, ADDRESS, PHONE, AGE, JOB_TYPE, SHIFT, AP_NAME)
VALUES (444444444, 'David Lee',       '789 Elm St, Othercity',          '555-4444', 45, 'Pilot',             'Night', 'Chhatrapati Shivaji International Airport');

INSERT INTO EMPLOYEE (SSN, NAME, ADDRESS, PHONE, AGE, JOB_TYPE, SHIFT, AP_NAME)
VALUES (555555555, 'Emma Garcia',     '456 Walnut St, Yetanothertown',  '555-5555', 32, 'Flight Attendant',  'Day',   'Louisville International Airport');

-- -----------------------------------------------------------------------------
-- 3.7 PASSENGER
--     Fixed: airport name typo and FK references
-- -----------------------------------------------------------------------------
INSERT INTO PASSENGER (PID, PASSPORT_NO, FNAME, ADDRESS, PHONE, AGE, SSN, AP_NAME)
VALUES (1, 'R1234567', 'John Doe',      '123 Main St, Anytown',       '555-1234', 30, 111111111, 'Louisville International Airport');

INSERT INTO PASSENGER (PID, PASSPORT_NO, FNAME, ADDRESS, PHONE, AGE, SSN, AP_NAME)
VALUES (2, 'R2345678', 'Jane Smith',    '456 Elm St, Othertown',      '555-5678', 25, 987654321, 'Chhatrapati Shivaji International Airport');

INSERT INTO PASSENGER (PID, PASSPORT_NO, FNAME, ADDRESS, PHONE, AGE, SSN, AP_NAME)
VALUES (3, 'R3456789', 'Alice Johnson', '789 Oak St, Anytown',        '555-1111', 28, 222222222, 'Louisville International Airport');

INSERT INTO PASSENGER (PID, PASSPORT_NO, FNAME, ADDRESS, PHONE, AGE, SSN, AP_NAME)
VALUES (4, 'R4567890', 'Bob Smith',     '456 Pine St, Othertown',     '555-2222', 35, 333333333, 'Chhatrapati Shivaji International Airport');

INSERT INTO PASSENGER (PID, PASSPORT_NO, FNAME, ADDRESS, PHONE, AGE, SSN, AP_NAME)
VALUES (5, 'R5678901', 'Charlie Brown', '123 Maple St, Anothertown',  '555-3333', 40, 444444444, 'Louisville International Airport');

-- -----------------------------------------------------------------------------
-- 3.8 SERVES
--     Fixed: Removed orphan row (PID=6, PASSPORT_NO='R6789012') — no such passenger
-- -----------------------------------------------------------------------------
INSERT ALL
    INTO SERVES (SSN, PID, PASSPORT_NO) VALUES (123456789, 1, 'R1234567')
    INTO SERVES (SSN, PID, PASSPORT_NO) VALUES (987654321, 2, 'R2345678')
    INTO SERVES (SSN, PID, PASSPORT_NO) VALUES (111111111, 3, 'R3456789')
    INTO SERVES (SSN, PID, PASSPORT_NO) VALUES (222222222, 4, 'R4567890')
    INTO SERVES (SSN, PID, PASSPORT_NO) VALUES (333333333, 5, 'R5678901')
SELECT 1 FROM DUAL;

-- -----------------------------------------------------------------------------
-- 3.9 TICKET
--     Fixed: 'FirstCls' → 'First Class'; added FLIGHT_CODE references
-- -----------------------------------------------------------------------------
INSERT INTO TICKET (TICKETNO, PID, PASSPORT_NO, SEAT_NO, CLASS, PRICE, DATE_OF_BOOKING, FLIGHT_CODE)
VALUES (1, 1, 'R1234567', 'A1',  'Economy',     500.00,  TO_DATE('2024-05-10', 'YYYY-MM-DD'), 'AL2014');

INSERT INTO TICKET (TICKETNO, PID, PASSPORT_NO, SEAT_NO, CLASS, PRICE, DATE_OF_BOOKING, FLIGHT_CODE)
VALUES (2, 2, 'R2345678', 'B2',  'Business',    1200.00, TO_DATE('2024-05-11', 'YYYY-MM-DD'), 'QR2305');

INSERT INTO TICKET (TICKETNO, PID, PASSPORT_NO, SEAT_NO, CLASS, PRICE, DATE_OF_BOOKING, FLIGHT_CODE)
VALUES (3, 3, 'R3456789', 'C3',  'First Class', 2000.00, TO_DATE('2024-05-12', 'YYYY-MM-DD'), 'LH9876');

INSERT INTO TICKET (TICKETNO, PID, PASSPORT_NO, SEAT_NO, CLASS, PRICE, DATE_OF_BOOKING, FLIGHT_CODE)
VALUES (4, 4, 'R4567890', 'D4',  'Economy',     550.00,  TO_DATE('2024-05-13', 'YYYY-MM-DD'), 'BA1689');

INSERT INTO TICKET (TICKETNO, PID, PASSPORT_NO, SEAT_NO, CLASS, PRICE, DATE_OF_BOOKING, FLIGHT_CODE)
VALUES (5, 5, 'R5678901', 'E5',  'Business',    1250.00, TO_DATE('2024-05-14', 'YYYY-MM-DD'), 'AA4367');

INSERT INTO TICKET (TICKETNO, PID, PASSPORT_NO, SEAT_NO, CLASS, PRICE, DATE_OF_BOOKING, FLIGHT_CODE)
VALUES (6, 2, 'R2345678', 'H8',  'Business',    1200.00, TO_DATE('2024-05-17', 'YYYY-MM-DD'), 'QR2305');

INSERT INTO TICKET (TICKETNO, PID, PASSPORT_NO, SEAT_NO, CLASS, PRICE, DATE_OF_BOOKING, FLIGHT_CODE)
VALUES (8, 3, 'R3456789', 'I9',  'First Class', 2050.00, TO_DATE('2024-05-18', 'YYYY-MM-DD'), 'EK3456');

INSERT INTO TICKET (TICKETNO, PID, PASSPORT_NO, SEAT_NO, CLASS, PRICE, DATE_OF_BOOKING, FLIGHT_CODE)
VALUES (10, 4, 'R4567890', 'J10', 'Economy',    560.00,  TO_DATE('2024-05-19', 'YYYY-MM-DD'), 'BA3056');

COMMIT;


-- =============================================================================
-- 4. STORED PROCEDURES
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 4.1 INSERT A NEW PASSENGER
--     Fixed: Column names now match PASSENGER table (FNAME, PHONE, AP_NAME)
--     Added: SSN parameter for the FK reference
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE insert_passenger (
    p_pid          IN INT,
    p_passport_no  IN VARCHAR2,
    p_fname        IN VARCHAR2,
    p_address      IN VARCHAR2,
    p_phone        IN VARCHAR2,
    p_age          IN INT,
    p_ssn          IN INT DEFAULT NULL,
    p_ap_name      IN VARCHAR2
)
IS
BEGIN
    INSERT INTO PASSENGER (
        PID, PASSPORT_NO, FNAME, ADDRESS, PHONE, AGE, SSN, AP_NAME
    ) VALUES (
        p_pid, p_passport_no, p_fname, p_address, p_phone, p_age, p_ssn, p_ap_name
    );

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Passenger inserted successfully: PID=' || p_pid);
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error: Passenger with PID=' || p_pid
            || ' and Passport=' || p_passport_no || ' already exists.');
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error inserting passenger: ' || SQLERRM);
END;
/

-- -----------------------------------------------------------------------------
-- 4.2 UPDATE PASSENGER DETAILS
--     Fixed: PHONE_NO → PHONE to match table column
--     Added: Row-count check for feedback
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE update_passenger_details (
    p_pid        IN INT,
    p_new_phone  IN VARCHAR2,
    p_new_addr   IN VARCHAR2
)
IS
    v_rows_updated INT;
BEGIN
    UPDATE PASSENGER
    SET PHONE   = p_new_phone,
        ADDRESS = p_new_addr
    WHERE PID = p_pid;

    v_rows_updated := SQL%ROWCOUNT;
    COMMIT;

    IF v_rows_updated = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Warning: No passenger found with PID=' || p_pid);
    ELSE
        DBMS_OUTPUT.PUT_LINE('Passenger details updated successfully. Rows affected: ' || v_rows_updated);
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error updating passenger: ' || SQLERRM);
END;
/

-- -----------------------------------------------------------------------------
-- 4.3 DELETE A TICKET
--     Fixed: Table name 'tickets' → 'TICKET'
--     Added: Exception handling and row-count feedback
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE delete_ticket (
    p_ticketno IN NUMBER
)
IS
    v_rows_deleted INT;
BEGIN
    DELETE FROM TICKET
    WHERE TICKETNO = p_ticketno;

    v_rows_deleted := SQL%ROWCOUNT;
    COMMIT;

    IF v_rows_deleted = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Warning: No ticket found with TICKETNO=' || p_ticketno);
    ELSE
        DBMS_OUTPUT.PUT_LINE('Ticket ' || p_ticketno || ' deleted successfully.');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error deleting ticket: ' || SQLERRM);
END;
/


-- =============================================================================
-- 5. FUNCTIONS
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 5.1 Calculate total ticket price for a flight
--     Fixed: Table 'tickets' → 'TICKET'; column 'flight_code' now exists in TICKET
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION calculate_total_price (
    p_flight_code IN VARCHAR2
)
RETURN NUMBER
IS
    v_total_price NUMBER;
BEGIN
    SELECT SUM(PRICE)
    INTO v_total_price
    FROM TICKET
    WHERE FLIGHT_CODE = p_flight_code;

    RETURN NVL(v_total_price, 0);
END;
/

-- -----------------------------------------------------------------------------
-- 5.2 Get employee details by SSN
--     Fixed: SSN parameter type INT (not VARCHAR2); FETCH matches actual columns
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_employee_details (
    p_ssn IN INT
)
RETURN SYS_REFCURSOR
IS
    emp_cursor SYS_REFCURSOR;
BEGIN
    OPEN emp_cursor FOR
        SELECT SSN, NAME, ADDRESS, PHONE, AGE, JOB_TYPE, SHIFT, AP_NAME
        FROM EMPLOYEE
        WHERE SSN = p_ssn;

    RETURN emp_cursor;
END;
/

-- -----------------------------------------------------------------------------
-- 5.3 Get airport name by city name
--     Fixed: Column 'city_name' → 'CNAME' to match AIRPORT table
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_airport_name (
    p_cname IN VARCHAR2
)
RETURN VARCHAR2
IS
    v_ap_name VARCHAR2(100);
BEGIN
    SELECT AP_NAME
    INTO v_ap_name
    FROM AIRPORT
    WHERE CNAME = p_cname;

    RETURN v_ap_name;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 'No airport found for city: ' || p_cname;
    WHEN TOO_MANY_ROWS THEN
        RETURN 'Multiple airports found for city: ' || p_cname;
    WHEN OTHERS THEN
        RETURN 'Error retrieving airport name: ' || SQLERRM;
END;
/


-- =============================================================================
-- 6. TRIGGERS
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 6.1 Auto-update flight status on arrival time change
--     Fixed: Logic corrected — if new arrival is LATER than original, mark Delayed
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER update_flight_status
BEFORE UPDATE ON FLIGHTS
FOR EACH ROW
BEGIN
    -- If the new arrival time is later than the old one, the flight is delayed
    IF TO_DATE(:NEW.ARRIVAL, 'HH24:MI') > TO_DATE(:OLD.ARRIVAL, 'HH24:MI') THEN
        :NEW.STATUS := 'Delayed';
    ELSE
        :NEW.STATUS := 'On-time';
    END IF;
END;
/

-- -----------------------------------------------------------------------------
-- 6.2 Enforce maximum passenger age constraint
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER check_passenger_age
BEFORE INSERT OR UPDATE ON PASSENGER
FOR EACH ROW
BEGIN
    IF :NEW.AGE > 120 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Passenger age cannot exceed 120 years.');
    ELSIF :NEW.AGE < 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Passenger age cannot be negative.');
    END IF;
END;
/

-- -----------------------------------------------------------------------------
-- 6.3 Log ticket deletions into DELETED_TICKETS
--     Fixed: Added missing '/' terminator
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER log_ticket_deletion
AFTER DELETE ON TICKET
FOR EACH ROW
BEGIN
    INSERT INTO DELETED_TICKETS (TICKETNO, DELETION_DATE)
    VALUES (:OLD.TICKETNO, SYSDATE);
END;
/


-- =============================================================================
-- 7. TEST / DEMO BLOCKS
-- =============================================================================
SET SERVEROUTPUT ON;

-- 7.1 Test: Insert a new passenger
BEGIN
    insert_passenger(
        p_pid         => 7,
        p_passport_no => 'R7890123',
        p_fname       => 'George Miller',
        p_address     => '123 Main St, NY',
        p_phone       => '9876543210',
        p_age         => 35,
        p_ssn         => NULL,
        p_ap_name     => 'Louisville International Airport'
    );
END;
/

-- 7.2 Test: Update passenger details
BEGIN
    update_passenger_details(
        p_pid       => 2,
        p_new_phone => '9998887777',
        p_new_addr  => '456 Park Ave, Los Angeles'
    );
END;
/

-- 7.3 Test: Delete a ticket
BEGIN
    delete_ticket(p_ticketno => 3);
END;
/

-- 7.4 Test: Calculate total ticket price for flight QR2305
SELECT calculate_total_price('QR2305') AS TOTAL_PRICE FROM DUAL;

-- 7.5 Test: Get employee details (using correct INT SSN)
DECLARE
    emp_info   SYS_REFCURSOR;
    v_ssn      INT;
    v_name     VARCHAR2(50);
    v_address  VARCHAR2(100);
    v_phone    VARCHAR2(20);
    v_age      INT;
    v_job_type VARCHAR2(50);
    v_shift    VARCHAR2(20);
    v_ap_name  VARCHAR2(100);
BEGIN
    emp_info := get_employee_details(123456789);

    LOOP
        FETCH emp_info INTO v_ssn, v_name, v_address, v_phone, v_age, v_job_type, v_shift, v_ap_name;
        EXIT WHEN emp_info%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE('Name: ' || v_name || ', Job: ' || v_job_type || ', Airport: ' || v_ap_name);
    END LOOP;

    CLOSE emp_info;
END;
/

-- 7.6 Test: Get airport name by city
SELECT get_airport_name('Mumbai') AS AIRPORT_NAME FROM DUAL;

-- 7.7 Test: Trigger — update flight arrival to test status change
UPDATE FLIGHTS SET ARRIVAL = '14:30' WHERE FLIGHT_CODE = 'QR2305';
COMMIT;
SELECT FLIGHT_CODE, ARRIVAL, STATUS FROM FLIGHTS WHERE FLIGHT_CODE = 'QR2305';

-- 7.8 Test: Verify deleted ticket was logged
SELECT * FROM DELETED_TICKETS;

-- 7.9 Modernized cursor: Ticket prices & passenger names
--     Fixed: Column names (TICKETNO, not ticket_no); table name (TICKET, not tickets)
--     Improved: Uses cursor FOR loop instead of explicit OPEN/FETCH/CLOSE
DECLARE
    CURSOR ticket_passenger_cur IS
        SELECT T.TICKETNO,
               T.PRICE,
               T.CLASS,
               P.FNAME
        FROM   TICKET T
        JOIN   PASSENGER P ON T.PID = P.PID AND T.PASSPORT_NO = P.PASSPORT_NO;
BEGIN
    FOR rec IN ticket_passenger_cur LOOP
        DBMS_OUTPUT.PUT_LINE(
            'Ticket No: ' || rec.TICKETNO ||
            ', Passenger: ' || rec.FNAME ||
            ', Price: ' || rec.PRICE ||
            ', Class: ' || rec.CLASS
        );
    END LOOP;
END;
/

-- 7.10 Verify all tables
SELECT 'CITY'      AS TBL, COUNT(*) AS ROW_COUNT FROM CITY      UNION ALL
SELECT 'AIRPORT',          COUNT(*)               FROM AIRPORT   UNION ALL
SELECT 'AIRLINE',          COUNT(*)               FROM AIRLINE   UNION ALL
SELECT 'CONTAIN',          COUNT(*)               FROM CONTAIN   UNION ALL
SELECT 'FLIGHTS',          COUNT(*)               FROM FLIGHTS   UNION ALL
SELECT 'EMPLOYEE',         COUNT(*)               FROM EMPLOYEE  UNION ALL
SELECT 'PASSENGER',        COUNT(*)               FROM PASSENGER UNION ALL
SELECT 'SERVES',           COUNT(*)               FROM SERVES    UNION ALL
SELECT 'TICKET',           COUNT(*)               FROM TICKET;

-- =============================================================================
-- END OF SCRIPT
-- =============================================================================
