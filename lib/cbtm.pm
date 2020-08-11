#=======================================================================================================================
# cbtm package
#=======================================================================================================================
package cbtm;


#=======================================================================================================================
# Import modules
#=======================================================================================================================

# Dancer
use Dancer2;
use Dancer2::Plugin::Auth::Extensible;
use Dancer2::Plugin::Database;

# other
use Data::Dumper;
use File::Basename qw(dirname);
use Cwd qw(abs_path);

use Utils;
use Utils::SteamAPI;

use Pages::Admin;
use Pages::VacManager;
use Pages::CooldownManager;


#=======================================================================================================================
# Global vars
#=======================================================================================================================
our $VERSION = '0.1';

my $dbfile = dirname(abs_path($0)) . '/../data/db.sqlite';
database({ driver => 'SQLite', database => $dbfile });
set dbfile => $dbfile;

#=======================================================================================================================
# Index Page handler
#=======================================================================================================================
get '/' => require_role user => sub {

    # get information
    my $user = logged_in_user();
    my $time = localtime(time());

    # render the template
    template 'pages/index' => {
         'title'        => 'CSGO Ban Time Manager',
         'version'      => $VERSION,
         'sys_time'     => qq($time),
         'current_user' => $user->{name},
    };
};


#=======================================================================================================================
# Strategy generator page handler
#=======================================================================================================================

# stratgen manager default page
get '/stratgen' => require_role user => sub {

    # get information
    my $user = logged_in_user();
    my $time = localtime(time());

    # render the template
    template 'pages/stratgen/stratgen' => {
        'title'        => 'VAC Manager',
        'version'      => $VERSION,
        'sys_time'     => qq($time),
        'current_user' => $user->{name},
        'alert'        => 'hidden',
    };
};


#=======================================================================================================================
# do the perl thing
#=======================================================================================================================
true;
