#!/usr/bin/perl -w

use Chatbot::Eliza;

$chatbot = new Chatbot::Eliza 'Liz';

print "\nWelcome to your therapy session.\n";
print "Your therapist's name is ", $chatbot->name;
print ".\n\n";

$chatbot->command_interface();

