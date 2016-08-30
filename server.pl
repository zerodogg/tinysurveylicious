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

=head1 TODO: POD
