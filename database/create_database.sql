\set ON_ERROR_STOP on
-- Run against the maintenance database: psql -U postgres -d postgres -f database/create_database.sql
SELECT 'CREATE DATABASE "e-commerce"'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'e-commerce')\gexec
