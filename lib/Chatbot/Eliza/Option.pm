package Chatbot::Eliza::Option;

use Moo;
use Chatbot::Eliza::ScriptParser;

use experimental qw[
    signatures
];

my %fields = (
    name => 'Eliza',
    script_file => '',
    debug => 0,
    debug_text => '',
    transform_text => '',
    prompts_on => 1,
    memory_on => 1,
    botprompt => '',
    userprompt => '',
    max_memory_size => 5,
    likelihood_of_using_memory => 1,
    memory => sub { [ ] },
);

while ( my( $key, $value ) = each %fields ) {
    has $key => (
        is => 'rw',
        lazy => 1,
        default => $value,
    );
}

has 'data' => (
    is => 'ro',
    lazy => 1,
    builder => 'build_data'
);

sub build_data ($self) {
    my $parser = Chatbot::Eliza::ScriptParser->new(script_file => $self->script_file);
    $parser->parse_script_data;
    return $parser;
}

sub myrand ($self, $max) {
    my $n = defined $max ? $max : 1;
    return rand($n);
}

sub welcome_message ($self) {
    my $initial = $self->data->initial;
    return $initial->[ $self->myrand( scalar $initial->@* ) ];
}

1;

__END__

=head1 NAME

Chatbot::Eliza::Options 

=head1 VERSION

Version 2.0

=head1 Options

=item name 

=item script_file

=item debug

=item debug_text

=item transform_text

=item prompts_on

=item memory_on

=item botprompt

=item userprompt

=item max_memory_size

=item likelihood_of_using_memory

=item memory

=item data

=over

=head1 SUBROUTINES/METHODS

=head2 myrand

    $bot->options->myrand(10)

Generates a random number between 0 and the integer passed in.

=over

=head2 welcome_message

    $bot->options->welcome_message

Returns a greeting message.

=over

=over 

=cut
