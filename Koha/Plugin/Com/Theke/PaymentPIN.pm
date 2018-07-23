package Koha::Plugin::Com::Theke::PaymentPIN;

use Modern::Perl;

use base qw(Koha::Plugins::Base);

use Koha::Patrons;
use Koha::Patron::Attribute::Types;
use Koha::Patron::Attributes;

use JSON;
use List::MoreUtils qw(any);

use Exception::Class (
    'PaymentPIN::Exception' => {
        fields => [ 'response' ]
    }
);

our $VERSION = "{VERSION}";

our $metadata = {
    name            => 'Payment+PIN plugin',
    author          => 'Tomas Cohen Arazi',
    description     => 'Provides a way to validate PIN (as an extended patron attribute) and make payments',
    date_authored   => '2018-07-05',
    date_updated    => '2018-07-05',
    minimum_version => '17.11',
    maximum_version => undef,
    version         => $VERSION,
};

sub new {
    my ( $class, $args ) = @_;

    $args->{'metadata'} = $metadata;
    $args->{'metadata'}->{'class'} = $class;

    my $self = $class->SUPER::new($args);

    return $self;
}

sub validate {
    my ( $self, $args ) = @_;
    my $cgi = $self->{cgi};

    my $validation_data = decode_json $cgi->param('POSTDATA');
    my $cardnumber      = $validation_data->{cardnumber};
    my $pin             = $validation_data->{pin};

    return try {
        my $attribute_type = $self->retrieve_data('attribute_type');
        unless ($attribute_type) {
            PaymentPIN::Exception->throw(
                {   response => {
                        authorized => JSON::false,
                        error      => 'Configuration error: missing pin attribute type'
                    }
                }
            );
        }

        my $att_object = Koha::Patron::Attribute::Types->find($attribute_type);
        unless ($att_object) {
            PaymentPIN::Exception->throw(
                {   response => {
                        authorized => JSON::false,
                        error      => 'Configuration error: non-existent attribute type'
                    }
                }
            );
        }

        unless ($pin) {
            return { authorized => JSON::false, error => 'PIN parameter missing' };
        }

        my $patron = Koha::Patrons->find( { cardnumber => $cardnumber } );
        unless ($patron) {
            return { authorized => JSON::false, error => 'Invalid cardnumber' };
        }

        my $attributes = Koha::Patron::Attributes->search(
            { code => $attribute_type, borrowernumber => $patron->id } );

        unless ( $attributes->count > 0 ) {
            return { authorized => JSON::false };
        }

        if ( any { $_->attribute eq $pin } @{ $attributes->as_list } ) {

            # PIN matches
            return { authorized => JSON::true };
        }
        else {
            return { authorized => JSON::false };
        }
    }
    catch {
        if ( $_->isa('PaymentPIN::Exception') ) {
            $_->rethrow();
        }
    };



}

sub pay {
    my ( $self, $args ) = @_;

    my $cgi          = $self->{cgi};
    my $payment_data = decode_json $cgi->param('POSTDATA');
    my $cardnumber   = $payment_data->{cardnumber};

    my $patron;
    if ( $cardnumber ) {
        $patron =  Koha::Patrons->find( { cardnumber => $cardnumber } );
    }

    unless ($patron) {
       PaymentPIN::Exception->throw( { response =>
           { error => "Invalid cardnumber" }
       } );
    }

    my $amount = $payment_data->{amount} // 0;
    unless ($amount > 0) {
       PaymentPIN::Exception->throw( { response =>
           { error => "Amounts can only be positive" }
       } );
    }

    $patron->account->pay(
        {
            amount => $amount
        }
    );

    return { success => JSON::true };
}

sub balance {
    my ( $self, $args ) = @_;

    my $cgi        = $self->{cgi};
    my $cardnumber = $cgi->param('cardnumber');

    my $patron;
    if ( $cardnumber ) {
        $patron =  Koha::Patrons->find( { cardnumber => $cardnumber } );
    }

    unless ($patron) {
       PaymentPIN::Exception->throw( { response =>
           { error => "Invalid cardnumber" }
       } );
    }

    my $balance = $patron->account->balance;

    return { balance => $balance };
}

sub configure {
    my ( $self, $args ) = @_;
    my $cgi = $self->{cgi};

    my $template = $self->get_template({ file => 'configure.tt' });

    my $api_key;
    my $attribute_type;

    if ( $cgi->param('save') ) {

        $api_key        = $cgi->param('api_key');
        $attribute_type = $cgi->param('attribute_type');

        # Store new API key
        $self->store_data({ 'api_key'        => $api_key });
        $self->store_data({ 'attribute_type' => $attribute_type });
    }
    else {

        $api_key        = $self->retrieve_data( 'api_key' );
        $attribute_type = $self->retrieve_data( 'attribute_type' );
    }

    $template->param(
        api_key        => $api_key,
        attribute_type => $attribute_type
    );

    print $cgi->header( -charset => 'utf-8' );
    print $template->output();
}

sub response {
    my ( $self, $args ) = @_;

    print $self->{cgi}->header(
        -status  => $args->{status},
        -charset => 'UTF-8',
        -type    => 'application/json'
    ), encode_json($args->{response});
    return 1;
}

sub api_key_valid {
    my ( $self, $api_key ) = @_;

    my $ret;

    if ( defined $api_key ) {
        my $stored_api_key = $self->retrieve_data( 'api_key' );

        if ( $stored_api_key and $api_key eq $stored_api_key ) {
            $ret = 1;
        }
    }

    return $ret;
}

sub uninstall {
    my ( $self, $args ) = @_;

    return 1;
}

1;
