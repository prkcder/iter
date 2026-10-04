-- 01_schema.sql
-- Creates the two tables.
-- The DROPs make this re-runnable so the database can be reset before a demo.
 
DROP TABLE IF EXISTS page_views;
DROP TABLE IF EXISTS customers;
 
CREATE TABLE customers (
    id          INTEGER PRIMARY KEY,
    email       TEXT    NOT NULL UNIQUE,   -- Iterable identifies users by email
    first_name  TEXT,
    last_name   TEXT,
    plan_type   TEXT    NOT NULL CHECK (plan_type IN ('free', 'basic', 'pro', 'enterprise')),
    candidate   TEXT
);
 
CREATE TABLE page_views (
    id          INTEGER   PRIMARY KEY,
    user_id     INTEGER   NOT NULL REFERENCES customers(id),
    page        TEXT      NOT NULL,
    device      TEXT,
    browser     TEXT,
    location    TEXT,
    event_time  TIMESTAMPTZ NOT NULL
);
 