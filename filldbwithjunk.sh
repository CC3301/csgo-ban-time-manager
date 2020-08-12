#!/usr/bin/env bash
# Fills the database with a bunch of junk entries to test performance

function filldb {

    for i in $(seq $1); do
        execquery $i
        echo $i
    done

}
function execquery {

    steam_id64=$1 

    query="INSERT INTO cooldowns (steam_id64, steam_username, steam_cooldown_time, steam_cooldown_reason, steam_avatar_url, steam_profile_visibility, steam_last_modified, steam_first_added ) VALUES ($steam_id64, 'JUNK DATA', 'JUNK DATA', 'JUNK DATA', 'https://steamcdn-a.akamaihd.net/steamcommunity/public/images/avatars/fb/fb10dcce65239cd69331e8bd7c08e84f78e96ced_medium.jpg', 'JUNK DATA', 'JUNK DATA', 'JUNK DATA' );"

    echo $query | sqlite3 data/db.sqlite

}

read -r -p "WARNING: This script will fill the database of this instance of CBTM with junk data. Do you want to continue?[y/n]" response

case "$response" in
    [yY][eE][sS]|[yY])
        filldb $1
        ;;
    *)
        echo "CANCELED"
        exit
        ;;
esac
