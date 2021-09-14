FROM ubuntu:latest

EXPOSE 3001:5000

RUN apt-get update -y && apt-get dist-upgrade -y
RUN apt-get install -y less wget build-essential apt-utils git libdancer-perl libapache-logformat-compiler-perl libposix-strftime-compiler-perl

RUN perl -MCPAN -e'install($_) for qw( Plack::Util Plack::Test Plack::Middleware Plack::Builder Dancer2 Dancer2::Plugin::Auth::Extensible Dancer2::Plugin::Database DBD::SQLite JSON Dancer2::Plugin::Auth::Extensible::Provider::Database )'

RUN git clone https://github.com/CC3301/csgo-ban-time-manager

ENTRYPOINT cd csgo-ban-time-manager/ && plackup bin/app.psgi
