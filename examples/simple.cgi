#!/usr/bin/perl

# This simple script implements a Chatbot::Eliza
# object in a cgi program.  It uses the CGI.pm module
# written by Lincoln Stein.
#
# Needless to say, you must have the CGI.pm module
# installed and working properly with CGI scripts on
# your Web server before you can try to run this script.
# CGI.pm is not included with Eliza.pm.
#
# Information about CGI.pm is here:
# http://www.genome.wi.mit.edu/ftp/pub/software/WWW/cgi_docs.html
# Richard Kapuaala added some 'improvements' Dec, 2023
# I can't find documentation on mod CGI, so it's not real pretty
# but it does funtion.
#
# Thanks to  ChatGPT via OpenAI 12/03/23 for providing me with CGI method for
# input fields and a well organized list of available CGI methods so
# I didn't have to wade through all the documents available to make my own list:)
#
#NOTE I HAVE NOT FINISHED WORKING ON THE ELIZA Dude.pm
#modify this to use Eliza and use your own rules file. 
#I'm leaving as using Chatbot::dude because I intend to share that and the dude rules 
# text file.
use CGI;
use Chatbot::dude;
my $myscript="/var/www/cgi-bin/ChatBots/Eliza/doc.txt";
my $cgi         = new CGI;
my $chatbot     = new Chatbot::dude "The Dude", $myscript;
my $comments ="";
#Not randomizing. Possibly due to the fact that each submit starts a new instance.
#srand( time() ^ ($$ + ($$ << 4)) );    # seed the random number generator

print $cgi->header;
print $cgi->title('The Dude Chats');
print $cgi->start_html(-bgcolor=>'#ccaacc');
print $cgi->start_multipart_form;
print $cgi->h2('The Dude');

#
print $cgi->p;
#Here I may not need to go through these gy
# calling Eliza tranform method for a response to user's input
if ( $cgi->param() ) {
                $prompt = $chatbot->transform( $cgi->param('input') );
                #adding users input to the comment area of textarea
$comments = "INPUT>  ".$cgi->param('input'). $cgi->param('Comment')."\n".$comments;
} else { #calling Eliza's initialization for a welcome message if there is not user input.
$prompt = "$chatbot->{initial}->[ int &{$chatbot->{myrand}}( scalar @{ $chatbot->{initial} } ) ]\n";
}
my $tatext="\n\nDude\> $prompt\n$comments"; #formatting the new input for inclussion with
old
$cgi->param('input','');#clearing the input field
$cgi->param('Comment', $tatext);#placing the new comments in the text area

 $chatbot->parse_script_data;
 $chatbot->parse_script_data($myscript);
print   $cgi->br,
                $cgi->textarea(
                        -name => 'Comment',
                        -wrap => 'yes',
                        -rows => 30,
                        -columns => 170,
                );


print   $cgi->p,
$cgi->textfield(
        -name      => 'input',
        -size      => 170,
        -autofocus => 0,
        -value =>' ',
    ),
$cgi->submit('Action','Send to The Dude'),
        $cgi->submit('Reset');

print $cgi->endform;
print $cgi->end_html;

                                           

