# NAME

Chatbot::Eliza - I'm so modern I only work on v5.2x

# VERSION

Version 2.0

# SYNOPSIS

    use Chatbot::Eliza

    my $bot = Chatbot::Eliza->new();
    
    $bot->command_interface;

# DESCRIPTION

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

# INSTALLATION

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

# OPTIONS

    my $bot = Chatbot::Eliza->new(name => 'WoW');

You can pass the following options into Chatbot

- name 

    Rename Eliza

- script\_file

    Pass in your own script file

- debug

    Turn debug mode on - 1.

- prompts\_on

    Turn prompts on - 1.

- memory\_on

    Turn memory off - 0.

# SUBROUTINES/METHODS

## command\_interface

    $chatterbot->command_interface;

command\_interface() opens an interactive session with the Eliza object, 
just like the original Eliza program. 

During an interactive session invoked using command\_interface(),
you can enter the word "debug" to toggle debug mode on and off.
You can also enter the keyword "memory" to invoke the \_debug\_memory()
method and print out the contents of the Eliza instance's memory.

This module is written in Moo which means it should be relatively easy
for you to design your own session format. All you need to do is extend 
[Chatbot::Eliza](https://metacpan.org/pod/Chatbot::Eliza) and maybe [Chatbot::Eliza::Brain](https://metacpan.org/pod/Chatbot::Eliza::Brain) if you're feeling ambitious.
Then you can write your own while loop and your own methods.

## instance

    $chatterbot->instace;

Return a single instance of the Eliza Object

# AUTHOR

- v2

    LNation thisusedtobeanemail@gmail.com June 2016

- V1

    John Nolan  jpnolan@sonic.net  January 2003. 
    Implements the classic Eliza algorithm by Prof. Joseph Weizenbaum. 
    Script format devised by Charles Hayden. 
