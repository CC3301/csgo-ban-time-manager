#=======================================================================================================================
# Admin Page
#=======================================================================================================================
package Pages::Admin;


#=======================================================================================================================
# Import modules, extend the cbtm package
#=======================================================================================================================
use Dancer2 appname => 'cbtm';
use Dancer2::Plugin::Auth::Extensible;
use Dancer2::Plugin::Database;

# other
use Data::Dumper;
use Utils::SteamAPI;
use Utils;
use File::Basename qw(dirname);
use Cwd qw(abs_path);

#=======================================================================================================================
# Global vars
#=======================================================================================================================
our $VERSION = '0.1';

my $dbfile = dirname(abs_path($0)) . '/../data/db.sqlite';
database({ driver => 'SQLite', database => $dbfile });


get '/admin' => require_role admin => sub {

    # get information
    my $user = logged_in_user();
    my $time = localtime(time());
    my $dbh  = database();
    my ($sth, $query, %database_data, $state);

    my $dbpath = Cwd::getcwd() . '/data/db.sqlite';

    # check if we need to initialize the database and if yes then render a different template
    if (Utils::check_db_uninitialized(database)) {
        template 'pages/admin/setupdb' => {
            'title' => "Set up Database",
            'sys_time'     => qq($time),
            'current_user' => $user->{name},
        };
    } else {

        $database_data{old_steam_api_key} = Utils::get_steam_api_key(database);

        # render template
        template 'pages/admin/admin' => {
            'title'        => 'VAC Manager',
            'version'      => $VERSION,
            'sys_time'     => qq($time),
            'current_user' => $user->{name},
            'old_steam_api_key' => $database_data{old_steam_api_key},
        };
    }
};

# save the new steam api key
post '/admin_save_steam_api_key' => require_role admin => sub {

    # get information
    my $params = request->params();
    my $steam_api_key = $params->{steam_api_key};
    my $sth;

    # save the steam api Key

    # try to read the steam api key from the database
    my $steam_apk = Utils::get_steam_api_key(database);
    my $query     = undef;
    if (!$steam_apk eq '') {
        $query = "UPDATE config SET steam_api_key = '$steam_api_key';";
    } else {
        $query = "INSERT INTO config (steam_api_key) VALUES ('$steam_api_key');";
    }
    Utils::log("Running SQL query: $query");
    $sth = database->prepare($query);

    # internal server error if database query didnt work
    if ($sth->execute()) {
        redirect '/admin';
    } else {
        redirect '/500';
    }
};

# export the Database
get  '/admin_export_db' => require_role admin => sub {
    my $dbfile = setting('dbfile');
    Utils::log($dbfile);
    return(send_file('/home/fink/Projects/csgo-ban-time-manager/data/db.sqlite', system_path => 1, filename => "dbexport_" . time() . ".sqlite"));
};

# setup db should only be called if there is no database yet
post '/admin_setupdb' => require_role admin => sub {

    my $sth;

    # create the vacs table
    my $vacsquery = "
        CREATE TABLE vacs (
            steam_id64 INTEGER,
            steam_username VARCHAR,
            steam_ban_vac BOOLEAN,
            steam_ban_game BOOLEAN,
            steam_ban_trade BOOLEAN,
            steam_ban_community BOOLEAN,
            steam_avatar_url VARCHAR,
            steam_profile_visibility INTEGER,
            steam_last_modified VARCHAR,
            steam_first_added VARCHAR,
            steam_first_bannend VARCHAR,
            UNIQUE(steam_id64)
        );
    ";

    # create the cooldown table
    my $cdquery = "
        CREATE TABLE cooldowns (
            steam_id64 INTEGER,
            steam_username VARCHAR,
            steam_cooldown_time INTEGER,
            steam_cooldown_reason VARCHAR,
            steam_avatar_url VARCHAR,
            steam_profile_visibility INTEGER,
            steam_last_modified VARCHAR,
            steam_first_added VARCHAR,
            UNIQUE(steam_id64)
        );
    ";

    # create statistics talbe
    my $statsquery = "
        CREATE TABLE statistics (
            cooldown_reason_team_kills_at_round_start INTEGER,
            cooldown_reason_team_kills INTEGER,
            cooldown_reason_team_damage INTEGER,
            cooldown_reason_rage_quit INTEGER,
            cooldown_reason_team_afk_timeout INTEGER,
            cooldown_type_30 INTEGER,
            cooldown_type_120 INTEGER,
            cooldown_type_1500 INTEGER,
            cooldown_type_10500 INTEGER,
            ban_vac INTEGER,
            ban_game INTEGER,
            ban_trade INTEGER,
            ban_community INTEGER,
            cooldown_time_total INTEGER,
            cooldown_users_total INTEGER,
            total_strats_generated INTEGER
        );
    ";

    # create users table
    my $usersquery = "
        CREATE TABLE users (
            username VARCHAR,
            password VARCHAR,
            roles VARCHAR,
            UNIQUE(username)
        );
    ";

    # create the config table
    my $cfgquery = "
        CREATE TABLE config (
            id INTEGER PRIMARY KEY,
            steam_api_key VARCHAR
        );
    ";

    # execute all querys
    Utils::log("Running SQL query: $vacsquery");
    $sth = database->prepare($vacsquery);
    $sth->execute();

    Utils::log("Running SQL query: $cdquery");
    $sth = database->prepare($cdquery);
    $sth->execute();

    Utils::log("Running SQL query: $statsquery");
    $sth = database->prepare($statsquery);
    $sth->execute();

    Utils::log("Running SQL query: $cfgquery");
    $sth = database->prepare($cfgquery);
    $sth->execute();

    redirect '/admin';

};
1;
