FROM ubuntu:latest

EXPOSE 3001:5000

RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install -y less wget build-essential apt-utils git
RUN apt-get install -y libdancer-perl libapache-logformat-compiler-perl libposix-strftime-compiler-perl
RUN echo "Packages installed. Installing Perl Modules"
RUN cpan -i Plack::Util
RUN cpan -i Plack::Test
RUN cpan -i Plack::Middleware
RUN cpan -i Plack::Builder
RUN cpan -i Dancer2
RUN cpan -i Dancer2::Plugin::Auth::Extensible
RUN cpan -i Dancer2::Plugin::Database
RUN cpan -i DBD::SQLite
RUN echo "Perl modules installed. Cloning most recent version of the csgo-ban-time-manager"
RUN git clone https://github.com/CC3301/csgo-ban-time-manager
RUN echo "DONE"

ENTRYPOINT cd csgo-ban-time-manager/ && plackup bin/app.psgi
