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

## License
Copyright &copy; Eskild Hustvedt 2016

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
