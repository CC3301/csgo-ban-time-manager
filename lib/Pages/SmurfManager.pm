#=======================================================================================================================
# Smurf Manager Page
#=======================================================================================================================
package Pages::SmurfManager;


#=======================================================================================================================
# Import modules and extend the cbtm app
#=======================================================================================================================

# Dancer
use Dancer2 appname => 'cbtm';
use Dancer2::Plugin::Auth::Extensible;
use Dancer2::Plugin::Database;

# other
use Data::Dumper;
#use Utils::SteamAPI;
use Utils;


#=======================================================================================================================
# Database settings
#=======================================================================================================================
database({ driver => 'SQLite', database => setting('dbfile') });


1;
