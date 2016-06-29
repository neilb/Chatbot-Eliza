package Chatbot::Eliza;

use strict;
use warnings;

use Chatbot::Eliza::Option;
use Chatbot::Eliza::Brain;

use Moo;

use experimental qw[
    signatures
];

my @user_options = qw(name script_file debug prompts_on memory_on);
foreach my $field (@user_options) {
    has $field => (
        is => 'rw',
        default => undef,
    );
}

has 'brain' => (
    is => 'rw',
    lazy => 1,
    builder => '_build_brain',
);

sub _build_brain ($self) {
    my $options = Chatbot::Eliza::Option->new();
    foreach my $field (@user_options) {
        if (my $val = $self->$field) {
            $options->$field($val);
        }
    }
    return Chatbot::Eliza::Brain->new(options => $options);
}

sub command_interface ($self) {
    my ($reply, $previous_user_input, $user_input) = "";
    
    my $options = $self->brain->options;
    $options->botprompt($options->name . ":\t");
    $options->userprompt("you:\t");

    # Seed the rand number generator.
    srand( time() ^ ($$ + ($$ << 15)) );

    # print the Eliza prompt
    print $options->botprompt if $options->prompts_on;

    # print an initial greeting
    print $options->welcome_message . "\n";

    while (1) {

        print $options->userprompt if $options->prompts_on;
    
        $previous_user_input = $user_input;
        chomp( $user_input = <STDIN> );

        # If the user enters the work "debug",
        # the toggle on/off Eliza's debug output.
        if ($user_input eq "debug") {
            $options->debug( ! $options->debug );
            $user_input = $previous_user_input;
        }

        # If the user enters the word "memory"
        # then use the _debug_memory method to dump out
        # the current contents of Eliza's memory
        if ($user_input =~ m{memory|debug memory}xms) {
            print $self->brain->_debug_memory();
            redo;
        }

        # If the user enters the word "debug that" 
        # the dump out the debugging of the most recent 
        # call to transform
        if ($user_input eq "debug that") {
            print $options->debug_text;
            redo;
        }

        # Invoke the transform method to generate a reply
        $reply = $self->brain->transform($user_input, '');

        # Print out the debugging text if debugging is set to on.
        # This variable should have been set by the transform method
        print $options->debug_text if $self->debug;

        # print the actual reply
        print $options->botprompt if $options->prompts_on;
        print sprintf("%s\n", $reply);

        last if $self->brain->last;
   }
}

sub instance ($self, $user_input) {
    return $self->brain->transform($user_input, '');
}

1; 

__END__

=head1 NAME

Chatbot::Eliza - I'm so modern I only work on v5.2x

=over

=back

=head1 VERSION

Version 2.0

=over

=back

=head1 SYNOPSIS

    use Chatbot::Eliza

    my $bot = Chatbot::Eliza->new();
    
    $bot->command_interface;

=over

=back

=head1 DESCRIPTION

This module implements the classic Eliza algorithm. The original Eliza program was 
written by Joseph Weizenbaum and described in the Communications of the ACM in 1966.  
Eliza is a mock Rogerian psychotherapist.  It prompts for user input, and uses a simple 
transformation algorithm to change user input into a follow-up question.  The program 
is designed to give the appearance of understanding.

This program is a faithful implementation of the program described by Weizenbaum.  
It uses a simplified script language (devised by Charles Hayden). The content of the 
script is the same as Weizenbaum's. This module encapsulates the Eliza algorithm 
in the form of an object.  This should make the functionality easy to incorporate in 
larger programs.

=over

=back

=head1 INSTALLATION

The current version of Chatbot::Eliza.pm is available on CPAN:
  
    http://www.perl.com/CPAN/modules/by-module/Chatbot/

To install this package, just change to the directory which you created by untarring 
the package, and type the following:
   
    perl Makefile.PL
    make test
    make
    make install

This will copy Eliza.pm to your perl library directory for use by all perl scripts.  
You probably must be root to do this, unless you have installed a personal copy of perl.  

=over

=back

=head1 OPTIONS

    my $bot = Chatbot::Eliza->new(name => 'WoW');

You can pass the following options into Chatbot

=over 

=item name 

Rename Eliza

=item script_file

Pass in your own script file

=item debug

Turn debug mode on - 1.

=item prompts_on

Turn prompts on - 1.

=item memory_on

Turn memory off - 0.

=back

=head1 SUBROUTINES/METHODS

=head2 command_interface

    $chatterbot->command_interface;

command_interface() opens an interactive session with the Eliza object, 
just like the original Eliza program. 

During an interactive session invoked using command_interface(),
you can enter the word "debug" to toggle debug mode on and off.
You can also enter the keyword "memory" to invoke the _debug_memory()
method and print out the contents of the Eliza instance's memory.

This module is written in Moo which means it should be relatively easy
for you to design your own session format. All you need to do is extend 
L<Chatbot::Eliza> and maybe L<Chatbot::Eliza::Brain> if you're feeling ambitious.
Then you can write your own while loop and your own methods.

=over

=back

=head2 instance

    $chatterbot->instace;

Return a single instance of the Eliza Object

=over

=back

=head1 AUTHOR

=over

=item v2

LNation thisusedtobeanemail@gmail.com June 2016

=item V1

John Nolan  jpnolan@sonic.net  January 2003. 
Implements the classic Eliza algorithm by Prof. Joseph Weizenbaum. 
Script format devised by Charles Hayden. 

=back
