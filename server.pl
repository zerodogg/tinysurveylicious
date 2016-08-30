#!/usr/bin/perl
# tinysurveylicious - a tiny web survey application
# Copyright (C) Eskild Hustvedt 2016
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
use strict;
use warnings;
use Mojolicious::Lite;
use Mojo::SQLite;
use JSON;

# Config detection
my $confFile = 'tinysurveylicious.conf';
if (!-e $confFile)
{
    warn('WARNING: '.$confFile.' does not exist, loading '.$confFile.'.example instead'."\n");
    print 'Hint: You should copy '.$confFile.'.example to '.$confFile.' and then edit that'."\n";
    $confFile .= '.example';
}

# Helper providing access to SQLite
helper sqlite => sub {
    state $sql;
    return $sql if defined $sql;

    $sql = Mojo::SQLite->new('sqlite:database.db');
    $sql->migrations->from_file('migrations.sql');
    $sql->auto_migrate(1);
    return $sql;
};
# Helper providing access to the config file
my $config = plugin JSONConfig => {file =>  $confFile };

# Helper used to verify authentication tokens
helper verifyAuthToken => sub
{
    my $c = shift;
    my $token = shift;
    my $valid = 0;
    if (!defined($token) || !length($token))
    {
        return 0;
    }
    $c->stash->{token} = $token;
    my $data = $c->sqlite->db->query('SELECT valid FROM authtokens WHERE token=?',$token);
    while(my $entry = $data->hash)
    {
        if ($entry->{valid})
        {
            $valid++;
        }
    }
    # More than one valid entry is not suppose to be possible
    if ($valid > 1)
    {
        warn('WARNING: Multiple valid entries for auth token '.$token);
    }
    return $valid;
};

# Root function that initializes the stash.
under sub {
    my $c = shift;
    # Stash default values
    $c->stash(
        textcontent      => $config->{text},
        config           => $config->{config},
        form             => $config->{fields},
        subpage          => undef,
        authOK           => 1,
        message          => undef,
        title            => undef,
        token            => undef,
    );
    # Handle auth tokens if needed
    if ($config->{config}->{requireAuthToken})
    {
        # Redirect if our auth token is invalid
        if (!$c->verifyAuthToken($c->req->param('token')))
        {
            $c->stash->{authOK} = 0;
            if ($c->req->url ne '/')
            {
                $c->redirect_to('/');
            }
        }
    }
    return 1;
};

# Renders an empty form
get '/' => sub {
    my $c = shift;
    if ($c->stash->{authOK})
    {
        $c->stash( subpage => 'form' );
        $c->render(template => 'template');
    }
    else
    {
        # FIXME: This should be from the text section of the config
        $c->stash( title => $c->stash->{textcontent}->{access}->{deniedHeader} );
        $c->stash( message => $c->stash->{textcontent}->{access}->{deniedDescription} );
        $c->render(template => 'template');
    }
};

# Redirects to / when someone attempts to GET from /data
get '/data' => sub {
    my $c = shift;
    $c->redirect_to('/');
};

# Handles input validation (responding with an error message if neccessary),
# and stores data in the database.
post '/data' => sub {
    my $c = shift;
    return if !$c->stash->{authOK};

    my $validation = $c->validation;
    # If no data exists (empty POST) we just redirect to /
    return $c->redirect_to('/') unless $validation->has_data;

    # Validate that all required fields have values
    foreach my $entry (@{$config->{fields}})
    {
        if ($entry->{required})
        {
            $validation->required($entry->{shortname});
        }
    }

    # If an error occurred during validation, display a friendly message to the
    # user and return to the form.  The form will be pre-filled with any values
    # the user submitted.
    if ($validation->has_error)
    {
        $c->stash(
            message => $config->{text}->{error},
            subpage => 'form',
        );
    }
    else
    {
        # The data has been validated, display a message saying so
        $c->stash(
            message => $config->{text}->{done},
        );
        # Generate a datastructure that can be serialized into the database
        my $result = {};
        foreach my $entry (@{$config->{fields}})
        {
            $result->{ $entry->{shortname} } = $c->param($entry->{shortname});
        }
        # Store the serialized data in the DB
        if ($config->{config}->{requireAuthToken})
        {
            $result->{__token} = $c->req->param('token');
            # Invalidate the token so that subsequent requests fail
            $c->sqlite->db->query('UPDATE authtokens SET valid=0 WHERE token=?',$c->req->param('token'));
        }
        $c->sqlite->db->query('INSERT INTO responses (content) VALUES (?)',to_json($result));
    }
    $c->render( template => 'template');
};

app->start;

__END__
=encoding utf8

=head1 NAME

tinysurveylicious - a tiny web survey application using the Mojolicious framework

=head1 DESCRIPTION

tinysurveylicious is a tiny web survey applications written in perl, using the
L<Mojolicious|http://mojolicious.org/> framework. It's built to be very easy to
set up and run. It requires a few perl libraries (which can be auto-installed
by using the Makefile) and no external daemons (using SQLite for permanent
storage). It can run standalone, or behind a web server proxy.

The configuration format is JSON extended to allow comments. It supports both
unathenticated and authenticated use.

=head1 INSTALLATION

tinysurveylicious requires the following perl modules: L<Mojolicious>,
L<Mojo::SQLite> and L<JSON>. The base distribution includes a small Makefile
helper that can auto-install these into ./local-lib if you have cpanm
installed.  The database is SQLite and tinysurveylicious will auto-crete it
upon first startup, and automatically migrate it to newer versions if you
upgrade tinysurveylicious.

=head1 CONFIGURATION

The configuration file format for tinysurveylicious is JSON with comment
support (in reality it is JSON filtered through L<Mojo::Template>). Included with
the application is an example/stub config named F<tinysurveylicious.conf.example>.
Copy this file to F<tinysurveylicious.conf> and then edit it to fit your liking.
Below is a quick rundown of the various sections.

=head2 The «text» section

The «text» section of the config contains all the non-survey text that is
displayed in tinysurveylicious. You can customize all of that text by editing
this section.

=head2 The «config» section

The «config» section is the configuration of the application itself.

=over

=item B<requireAuthToken>

If this is set to true then tinysurveylicious will deny access to the form unless
a valid token is supplied as the token= parameter in the URL. It defaults to false.

=item B<descriptionHTMLAllowed>

If this is set to true, tinysurveylicious will allow the
config->text->description field to contain HTML that will be included as-is on
the website. It defaults to false.

=back

=head2 The «fields» section (survey configuration)

The «fields» section is the actual survey you want to run. It is an array of
survey fields. The fields will appear on the website in the order they are
listed here. Each entry in this array is an object («hash»), that configures
that specific field. The following settings are available:

=over

=item B<shortname> [REQUIRED]

This is a short identifier for this field. It is never displayed, but is used
internally to store values and to identify the submitted values for this field.
It MUST be unique and must not include any whitespace.

=item B<name> [REQUIRED]

This is the name of the field that is displayed on the web. This can be any string.

=item B<type> [REQUIRED]

This defines what kind of field it is. The following fields are available:

=over

=item textarea

A textarea for entery arbitrary-length text.

=item radio

A simple list of radiobuttons, where the user can select one. REQUIRES the
setting "choices" (see below).

=item select

A simple pulldown list, where the user can select one entry. REQUIRES the
setting "choices" (see below).

=item select-custom

A simple pulldown list, where the user can select one entry, or select a
«custom» entry. When selecting the custom entry they can enter their answer in
a simple text input box. REQUIRES the setting "choices" (see below).

=back

=item B<choices> [required for certain types]

An array of strings, where each string is an entry in the radio or select lists.

=item B<required>

This defaults to false. If this is true, this field must be filled in before the
user is able to submit the form.

=back

=head1 RUNNING

Since tinysurveylicious is a Mojolicious application, it can run in several
modes, including PSGI, CGI, a preforking web server, hypnotoad and more. See
L<Mojolicious::Guides::Deployment> for instructions, including how to run it
behind nginx. If you just want to start a server now run C<make devserver>,
C<make production> or C<./server.pl> (depending upon how you installed the
tinysurveylicious dependencies).

=head1 EXAMPLE

A complete example is included in F<tinysurveylicious.conf.example>. To quickstart
it, run: C<make deps && make devserver>

=head1 LICENSE AND COPYRIGHT

Copyright (C) Eskild Hustvedt 2016

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
