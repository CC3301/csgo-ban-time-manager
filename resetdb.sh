#!/usr/bin/env bash
function reset_db {
    echo "RESETTING DATABASE"
    rm data/db.sqlite
    touch data/db.sqlite

    sqlite3 data/db.sqlite <<END_SQL
    CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT ,
        username VARCHAR(32) NOT NULL UNIQUE,
        password VARCHAR(40) NOT NULL
    );
    CREATE TABLE roles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        role VARCHAR(32) NOT NULL
    );
    CREATE TABLE user_roles (
        user_id INTEGER NOT NULL,
        role_id INTEGER NOT NULL
    );
    INSERT INTO users (
        username,
        password
    ) VALUES (
        'admin',
        'admin'
    );
    INSERT INTO users (
        username,
        password
    ) VALUES (
        'test',
        'test'
    );
    INSERT INTO roles (
        role
    ) VALUES (
        'admin'
    );
    INSERT INTO roles (
        role
    ) VALUES (
        'user'
    );
    INSERT INTO user_roles (
        user_id,
        role_id
    ) VALUES (
        1,
        1
    );
    INSERT INTO user_roles (
        user_id,
        role_id
    ) VALUES (
        1,
        2
    );
    INSERT INTO user_roles (
        user_id,
        role_id
    ) VALUES (
        2,
        2
    );
END_SQL
    echo "DATABASE RESET COMPLETE"

    exit
}


read -r -p "WARNING: This script will delete the database of this instance of CBTM. Do you want to continue?[y/n]" response

case "$response" in
    [yY][eE][sS]|[yY])
        reset_db
        ;;
    *)
        echo "CANCELED"
        exit
        ;;
esac
