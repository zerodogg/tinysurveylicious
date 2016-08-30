# tinysurveylicious - a tiny web survey application using the mojolicious framework

tinysurveylicious is a tiny web survey applications written in perl, using the
Mojolicious framework. It's built to be very easy to set up and run. It
requires a few perl libraries (which can be auto-installed by using the
Makefile) and no external daemons (using SQLite for permanent storage). It can
run standalone, or behind a web server proxy.

The configuration format is JSON extended to allow comments. It supports both
unathenticated and authenticated use.

## Quickstart

- Run `make prepare` to install the dependencies (into ./local-lib). This step
  requires [cpanm](https://github.com/miyagawa/cpanminus) installed.
- Edit `tinysurveylicious.conf` to your liking
- Start `tinysurveylicious` by running `make devserver` (for development mode)
  or `make production` (for production mode)

For more advanced means of running the server see `perl -Ilocal-lib/lib/perl5/
./server.pl`. You may also run the server directly (`./server.pl`) if you have
all of the dependencies installed already.

## Complete documentation

See the POD contained in server.pl: `perldoc ./server.pl`
