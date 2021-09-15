
#=======================================================================================================================
# VacManager Page
#=======================================================================================================================
package Pages::VacManager;


#=======================================================================================================================
# Import modules and extend the cbtm app
#=======================================================================================================================

# Dancer
use Dancer2 appname => 'cbtm';
use Dancer2::Plugin::Auth::Extensible;
use Dancer2::Plugin::Database;

# other
use Data::Dumper;
use Utils::SteamAPI;
use Utils;


#=======================================================================================================================
# Database settings
#=======================================================================================================================
database({ driver => 'SQLite', database => setting('dbfile') });


#=======================================================================================================================
# VAC manager page handler
#=======================================================================================================================

# vac manager add suspect page
get '/vac_add_suspect' => require_role user => sub {

    # get information
    my $user   = logged_in_user();
    my $time   = localtime(time());
    my $params = request->params();

    # check if we need to initialize the database and if yes then render a different template
    if (Utils::check_db_uninitialized(database)) {
        template setting('frontend') . '/pages/setupdb' => {
            'title' => "Set up Database",
            'sys_time'     => qq($time),
            'current_user' => $user->{username},
        };
    } else {

        my ($status, $statustype) = Utils::determine_status_facts($params->{status});

        # render the template
        my $toast = "";

        if (exists $params->{status}) {
            $toast = template setting('frontend') . '/toast' => {
                'layout'      => 'toast',
                'alert_text'  => $status,
                'alert_time'  => qq($time),
                'alert_title' => 'VAC Manager',
                'alert_type'  => $statustype,
            };
        }

        # draw main template for the add suspect page
        template setting('frontend') . '/pages/vacmanager/add_suspect' => {
            'title'        => 'Add VAC Suspect',
            'version'      => setting('version'),
            'sys_time'     => qq($time),
            'current_user' => $user->{username},
            'toast'        => $toast,
        };
    }
};

# actually save the suspect to the database after collecting data from steam API
post '/vac_save_suspect' => require_role user => sub {

    # get information
    my $params  = request->params();
    my $steam64 = $params->{steam_id64};
    my $status  = 'Failed';
    my ($query, $sth);

    # try to receive data from steam
    my %suspect_data = Utils::get_suspect_data_from_steam(database, $steam64);

    # check if there is valid data
    if (defined $suspect_data{avatar_url}) {
        $status = "Success";
        $query = "INSERT INTO vacs (steam_id64, steam_username, steam_ban_vac, steam_ban_game, steam_ban_trade,
                                    steam_ban_community, steam_avatar_url, steam_profile_visibility, steam_last_modified)
                                    VALUES ( '$steam64', '$suspect_data{profile_name}', '$suspect_data{ban_state}{vac}',
                                    '$suspect_data{ban_state}{game}', '$suspect_data{ban_state}{trade}',
                                    '$suspect_data{ban_state}{community}', '$suspect_data{avatar_url}',
                                    '$suspect_data{profile_visi}', '$suspect_data{last_mod}'
                                    );";
        $sth    = database->prepare($query);

        # check if we can execute the following query, if not try to update
        eval {
            $sth->execute();
        };
        if (defined $@) {
            Utils::log("Updating VAC Suspect Entry");
            $status = "Failed";
            $query = "
              UPDATE vacs SET
                steam_username = '$suspect_data{profile_name}',
                steam_ban_vac = '$suspect_data{ban_state}{vac}',
                steam_ban_game = '$suspect_data{ban_state}{game}',
                steam_ban_trade = '$suspect_data{ban_state}{trade}',
                steam_ban_community = '$suspect_data{ban_state}{community}',
                steam_avatar_url = '$suspect_data{avatar_url}',
                steam_profile_visibility = '$suspect_data{profile_visi}',
                steam_last_modified = '$suspect_data{last_mod}'
              WHERE steam_id64 = '$steam64';
            ";
            $sth = database->prepare($query);

            if ($sth->execute()) {
                $status = "Updated";
            } else {
                $status = "Failed";
            }
        } else {
            $status = "Success";
        }
    } else {
        $status = "Failed";
    }

    # redirect back to the add page to show if it was successful or if it failed
    redirect '/vac_list_suspects?status=' . $status;
};


# vac manager add suspect page
get '/vac_list_suspects' => require_role user => sub {

    # get information
    my $user = logged_in_user();
    my $params = request->params();
    my $time = localtime(time());
    my $toast  = undef;

    # check if we need to initialize the database and if yes then render a different template
    if (Utils::check_db_uninitialized(database)) {
        template setting('frontend') . '/pages/setupdb' => {
            'title' => "Set up Database",
            'sys_time'     => qq($time),
            'current_user' => $user->{username},
        };
    } else {

        if (exists $params->{status}) {

            my ($status, $statustype) = Utils::determine_status_facts($params->{status});
            $toast = template setting('frontend') . '/toast' => {
                'layout'      => 'toast',
                'alert_text'  => $status,
                'alert_time'  => qq($time),
                'alert_title' => 'VAC Manager',
                'alert_type'  => $statustype,
            };
        }

        # render the template
        my %suspect_data = Utils::get_suspect_data_from_db(database, 'vacs');
        template setting('frontend') . '/pages/vacmanager/list_suspects' => {
            'title'        => 'All VAC Suspects',
            'version'      => setting('version'),
            'sys_time'     => qq($time),
            'current_user' => $user->{username},
            'suspects'     => \%suspect_data,
            'toast'        => $toast,
        };
    }
};

# delete a suspect from the database
post '/vac_delete_suspect' => require_role user => sub {

    # get information
    my $params  = request->params();
    my $steam64 = $params->{steam_id64};
    my $status  = 'Failed';
    my ($query, $sth);


    # check if there is valid data
    if (defined $steam64) {
        $status = "Success";
        $query = "DELETE FROM vacs WHERE steam_id64 = '$steam64'";
        $sth    = database->prepare($query);

        # check if we can execute the following query, if not try to update
        eval {
            $sth->execute();
        };
        if (defined $@) {
            Utils::log("Tried deleting non-existent suspect");
            $status = "Failed";
        }
    } else {
        $status = "Failed";
    }

    # redirect back to the add page to show if it was successful or if it failed
    redirect '/vac_list_suspects?status=' . $status;
};

1;
