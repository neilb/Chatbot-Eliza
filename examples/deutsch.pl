#!/usr/bin/perl -w

use Chatbot::Eliza;

# This little script tests the German-language
# version of the "doctor" script.

# seed the random number generator
srand( time ^ ($$ + ($$ << 15)) );    

$chatbot = new Chatbot::Eliza "Hans", "deutsch.txt";
$chatbot->debug(1);
$chatbot->command_interface();

