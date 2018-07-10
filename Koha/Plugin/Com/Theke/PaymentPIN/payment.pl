#!/usr/bin/perl

# Copyright 2018 Theke Solutions
#
# This file is part of koha-plugin-payments-pin.
#
# koha-plugin-payments-pin is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# koha-plugin-payments-pin is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with koha-plugin-payments-pin; if not, see <http://www.gnu.org/licenses>.

use Modern::Perl;

use CGI qw ( -utf8 );
use Try::Tiny;

# Add the plugin's dir to the libs path
use FindBin;
use lib "$FindBin::Bin/../../../../../";

use Koha::Plugin::Com::Theke::PaymentPIN;

my $cgi     = new CGI;
my $payments = Koha::Plugin::Com::Theke::PaymentPIN->new({ cgi => $cgi });
my $api_key = $cgi->url_param('api_key');

# Check API key is present
if ( !defined $api_key ) {
    $payments->response({
        status => '401 Unauthorized',
        response => { error => 'API key missing' }
    });
}
elsif ( !$payments->api_key_valid( $api_key ) ) {
    # Check API key is valid
    $payments->response({
        status => '401 Unauthorized',
        response => { error => 'Invalid API key.' }
    });
}
else {
    # Ok, passed, moving on!
    try {
        my $response = $payments->pay;
        $payments->response({
            status => '200 OK',
            response => $response
        });
    }
    catch {
        $payments->response({
            status => '500 Internal Server Error',
            response => $_->error
        });
    };
}

1;
