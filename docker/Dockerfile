FROM ubuntu:latest
RUN apt-get update > /dev/null && \
    apt-get upgrade -y > /dev/null && \
    apt-get install -y less wget build-essential apt-utils git > /dev/null && \
    apt-get install -y libdancer-perl libapache-logformat-compiler-perl libposix-strftime-compiler-perl > /dev/null && \
    echo "Packages installed. Installing Perl Modules" && \
    cpan -i Plack::Util > /dev/null && \
    cpan -i Plack::Test > /dev/null && \
    cpan -i Plack::Middleware > /dev/null && \
    cpan -i Plack::Builder> /dev/null  && \
    cpan -i Dancer2 > /dev/null && \
    cpan -i Dancer2::Plugin::Auth::Extensible > /dev/null && \
    cpan -i Dancer2::Plugin::Database > /dev/null && \
    cpan -i DBD::SQLite > /dev/null && \
    echo "Perl modules installed. Cloning most recent version of the csgo-ban-time-manager" && \
    git clone https://github.com/CC3301/csgo-ban-time-manager > /dev/null && \
    echo "DONE"

ENTRYPOINT plackup csgo-ban-time-manager/bin/app.psgi
