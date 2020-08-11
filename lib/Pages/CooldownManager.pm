#=======================================================================================================================
# Cooldown Manager Page
#=======================================================================================================================
package Pages::CooldownManager;


#=======================================================================================================================
# Import modules
#=======================================================================================================================

# Dancer
use Dancer2 appname => 'cbtm';
use Dancer2::Plugin::Auth::Extensible;
use Dancer2::Plugin::Database;

# other
use Data::Dumper;
use Utils::SteamAPI;
use Utils;
use File::Basename qw(dirname);
use Cwd qw(abs_path);

use Pages::Admin;
use Pages::VacManager;


#=======================================================================================================================
# Global vars
#=======================================================================================================================
our $VERSION = '0.1';

my $dbfile = dirname(abs_path($0)) . '/../data/db.sqlite';
database({ driver => 'SQLite', database => $dbfile });


#=======================================================================================================================
# Cooldown manager page handler
#=======================================================================================================================

# vac manager add suspect page
get '/cd_add_cooldown' => require_role user => sub {

    # get information
    my $user   = logged_in_user();
    my $time   = localtime(time());
    my $params = request->params();

    my ($status, $statustype) = Utils::determine_status_facts($params->{status});

    # render the template
    my $toast = "";

    if(exists $params->{status}) {
        $toast = template 'toast' => {
            'layout' => 'toast',
            'alert_text'  => $status,
            'alert_time'  => qq($time),
            'alert_title' => 'Cooldown Manager',
            'alert_type'  => $statustype,
        };
    }

    template 'pages/cdmanager/add_cooldown' => {
        'title'        => 'Add Cooldown',
        'version'      => $VERSION,
        'sys_time'     => qq($time),
        'current_user' => $user->{name},
        'toast'        => $toast,
    };
};


# vac manager add suspect page
get '/cd_list_cooldowns' => require_role user => sub {

    # get information
    my $user = logged_in_user();
    my $params = request->params();
    my $time = localtime(time());
    my %suspect_data = Utils::get_suspect_data_from_db(database, 'cooldowns');
    my $toast = undef;

    if (exists $params->{status}) {

        my ($status, $statustype) = Utils::determine_status_facts($params->{status});
        $toast = template 'toast' => {
            'layout' => 'toast',
            'alert_text'  => $status,
            'alert_time'  => qq($time),
            'alert_title' => 'VAC Manager',
            'alert_type'  => $statustype,
        };
    }


    # render the template
    template 'pages/cdmanager/list_cooldowns' => {
        'title'        => 'All Cooldowns',
        'version'      => $VERSION,
        'sys_time'     => qq($time),
        'current_user' => $user->{name},
        'cooldowns'    => \%suspect_data,
        'toast'        => $toast,
    };
};

# actually save the suspect to the database after collecting data from steam API
post '/cd_save_cooldown' => require_role user => sub {

    # get information
    my $params    = request->params();
    my $steam64   = $params->{steam_id64};
    my $cd_time   = $params->{steam_cooldown_duration};
    my $cd_reason = $params->{steam_cooldown_reason};
    my $status    = 'Failed';
    my ($query, $sth);

    # grab all suspect data from steam
    my %suspect_data = Utils::get_suspect_data_from_steam(database, $steam64);
    $suspect_data{cooldown}{time}   = $cd_time;
    $suspect_data{cooldown}{reason} = $cd_reason;

    # execute query and check if data was successfully received
    if (defined $suspect_data{avatar_url}) {

        $status = "Success";
        $query = "
            INSERT INTO cooldowns (
                steam_id64,
                steam_username,
                steam_cooldown_time,
                steam_cooldown_reason,
                steam_avatar_url,
                steam_profile_visibility,
                steam_last_modified
            ) VALUES (
                '$steam64',
                '$suspect_data{profile_name}',
                '$suspect_data{cooldown}{time}',
                '$suspect_data{cooldown}{reason}',
                '$suspect_data{avatar_url}',
                '$suspect_data{profile_visi}',
                '$suspect_data{last_mod}'
            );
        ";
        $sth    = database->prepare($query);

        # check if we can execute the following query, if not try to update
        if ($sth->execute()) {
            $status = "Success";
        } else {
            $status = "Failed";
            $query = "
                UPDATE cooldowns SET
                    steam_username           = '$suspect_data{profile_name}',
                    steam_cooldown_time      = '$suspect_data{cooldown}{time}',
                    steam_cooldown_reason    = '$suspect_data{cooldown}{reason}',
                    steam_avatar_url         = '$suspect_data{avatar_url}',
                    steam_profile_visibility = '$suspect_data{profile_visi}',
                    steam_last_modified      = '$suspect_data{last_mod}'
                WHERE steam_id64 = '$steam64';
            ";
            $sth = database->prepare($query);
            if ($sth->execute()) {
                $status = "Updated";
            } else {
                $status = "Failed";
            }
        }
    } else {
        $status = "Failed";
    }

    # redirect back to the add page to show if it was successful or if it failed
    redirect '/cd_list_cooldowns?status=' . $status;
};

1;
