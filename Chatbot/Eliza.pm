####################################################################

package Chatbot::Eliza;
 
# Copyright (c) 1997 John Nolan. All rights reserved. 
# This program is free software.  You may modify and/or 
# distribute it under the same terms as Perl itself.  
# This copyright notice must remain attached to the file.  
#

use strict;

require 5.003; 
use Carp;

use vars qw($VERSION @ISA $AUTOLOAD); 

$VERSION = '0.32';
sub Version { $VERSION; }

=head1  NAME

B<Chatbot::Eliza> - A clone of the classic Eliza program

=head1 SYNOPSIS

use Chatbot::Eliza;

=head1 DESCRIPTION

This module implements the classic Eliza algorithm. 
The original Eliza program was written by Joseph 
Weizenbaum and described in the Communications 
of the ACM in 1967.  Eliza is a mock Rogerian 
psychotherapist.  It prompts for user input, 
and uses a simple transformation algorithm
to change user input into a follow-up question.  
The program is desigend to give the appearance 
of understanding.  

This program is a faithful implementation of the program 
described by Weizenbaum.  It uses a simplified script 
language (devised by Charles Hayden).  The content 
of the script is the same as Weizenbaum's. 

This module encapsulates the Eliza algorithm 
in the form of an object.  This should make 
the functionality easy to use in larger programs.  


=head1 USAGE

This is all you need to do to launch a simple
Eliza session:

	use Chatbot::Eliza;

	$mybot = new Chatbot::Eliza;
	$mybot->command_interface;

You can also customize certain features of the 
session:

	$myotherbot = new Chatbot::Eliza;

	$myotherbot->name( "Hortense" );
	$myotherbot->debug( 1 );

	$myotherbot->command_interface;

These lines set the name of the bot to be
"Hortense" and turn on the debugging output.

When creating an Eliza object, you can specify
a name and an alternative scriptfile:

	$bot = new Chatbot::Eliza "Brian", "myscript.txt";

If you don't specify a script file, then the
Eliza module will initialize the new Eliza
object with a default script that the module
contains within itself. 

You can use any of the internal functions in
a calling program.  The code below takes an 
arbitrary string and retrieves the reply from 
the Eliza object:

	my $string = "I have too many problems.";
	my $reply  = $mybot->transform( $string );

You can easily create two bots, each with a different
script, and see how they interact:

	use Chatbot::Eliza

	my ($harry, $sally, $he_says, $she_says);

	$sally = new Chatbot::Eliza "Sally", "histext.txt";
	$harry = new Chatbot::Eliza "Harry", "hertext.txt";

	$he_says  = "I am sad.";

	# Seed the random number generator.
	srand( time ^ ($$ + ($$ << 15)) );      

	while (1) {
		$she_says = $sally->transform( $he_says );
		print $sally->name, ": $she_says \n";
	
		$he_says  = $harry->transform( $she_says );
		print $harry->name, ": $he_says \n";
	}

Of course, as with the original Eliza program,
the magic of the algorithm is really in the script.


=head1 MAIN DATA MEMBERS

Each Eliza object uses the following data structures 
to hold the script data in memory:

=head2 %decomplist 

B<hash:> the set of keywords; B<values:> strings containing 
the decomposition rules. 

=head2 %reasmblist 

B<hash:> a set of values which are each the join 
of a keyword and a corresponding decomposition rule;  
B<values:>  the set of possible reassembly statements 
for that keyword and decomposition rule.  

=head2 %keyranks

B<hash:> the set of keywords; B<values:> the ranks for each keyword

=head2 @quit

"quit" words -- that is, words the user might use 
to try to exit the program.  

=head2 @initial

Possible greetings for the beginning of the program.

=head2 @final

Possible farewells for the end of the program.

=head2 %pre

B<hash:> words which are replaced before any transformations;
B<values:> the respective replacement words.

=head2 %post

B<hash:> words which are replaced after the transformations 
and after the reply is constructed; B<values>: the respective 
replacement words.
 
=head2 %synon	

B<hash:> words which are found in decomposition rules;
B<values:> words which are treated just like their 
corresponding synonyms during matching of decomposition
rules. 

=cut


my %fields = (
	name 		=> 'Eliza',
	scriptfile	=> '',

	debug 		=> 0,
	prompts_on	=> 1,
	botprompt	=> '',
	userprompt	=> '',

	keyranks	=> undef,
	decomplist	=> undef,
	reasmblist	=> undef,

	pre		=> undef,
	post		=> undef,
	synon		=> undef,
	initial		=> undef,
	final		=> undef,
	quit		=> undef, 
);


####################################################################
# ---{ B E G I N   M E T H O D S }----------------------------------
#

=head1 METHODS

=head2 	my $chatterbot = new Chatbot::Eliza;

B<new> creates a new Eliza object.  This method
also calls the internal B< _initialize> method, which in turn
calls the B<parse_script_data> method, which initializes
the script data.  

=head2 	my $chatterbot = new Chatbot::Eliza 'Ahmad', 'myfile.txt';

The eliza object defaults to the name "Eliza", and it
contains default script data within itself.  However,
using the syntax above, you can specify an alternative
name and an alternative script file. 

See the method B<parse_script_data>. for a description
of the format of the script file. 

=cut

sub new {
	my ($that,$name,$scriptfile) = @_;
	my $class = ref($that) || $that;
	my $self = {
		_permitted => \%fields,
		%fields,
	};
	bless $self, $class;
	$self->_initialize($name,$scriptfile);
	return $self;
} # end method new

sub _initialize {
	my ($self,$name,$scriptfile) = @_;
	$self->name($name) if $name;
#	$self->scriptfile($scriptfile) if $scriptfile;
	$self->parse_script_data($scriptfile);
}

sub AUTOLOAD {
	my $self = shift;
	my $class = ref($self) || croak "$self is not an object : $!\n";
	my $field = $AUTOLOAD;
	$field =~ s/.*://; # Strip fully-qualified portion

	unless (exists $self->{"_permitted"}->{$field} ) {
		croak "Can't access `$field' field in object of class $class : $!\n";
	}

	if (@_) {
		return $self->{$field} = shift;
	} else {
		return $self->{$field};
	}
} # end method AUTOLOAD


####################################################################
# --- command_interface ---

=head2 	$chatterbot->command_interface;

B<command_interface> opens an interactive session with 
the Eliza object, just like the original Eliza program.

If you want to design your own session format, then 
you can write your own while loop and your own functions
for prompting for and reading user input, and use the 
B<transform> method to generate Eliza's responses. 

But if you're lazy and you want to skip all that,
then just use B<command_interface>.  It's all done for you. 

=cut

sub command_interface {
	my $self = shift;
	my ($user_input, $previous_user_input, $reply);

	$self->botprompt($self->name . ":\t");	# Eliza's prompt 
	$self->userprompt("you:\t");     	# User's prompt

	# Seed the random number generator.
	srand( time() ^ ($$ + ($$ << 15)) );  

	# Print the Eliza prompt
	print $self->botprompt if $self->prompts_on;

	# Print an initial greeting
	print "$self->{initial}->[ int rand $#{ $self->{initial} } ]\n";


	####################################################################
	# command loop.  This loop should go on forever,
	# until we explicity break out of it. 
	#
	while (1) {

		print $self->userprompt if $self->prompts_on;

		$previous_user_input = $user_input;
		chomp( $user_input = <STDIN> ); 


		# If the user wants to quit,
		# print out a farewell and quit.
		if ($self->_testquit($user_input) ) {
			$reply = "$self->{final}->[ int rand $#{ $self->{final} } ]";
			print $self->botprompt if $self->prompts_on;
			print "$reply\n";
			last;
		} 

		# If the user enters the word "debug",
		# then turn on this Eliza's debug output.
		if ($user_input eq "debug") {
			$self->debug( ! $self->debug );
			$user_input = $previous_user_input;
		}

		# Invoke the transform method
		# to generate a reply.
		$reply = $self->transform( $user_input );

		print $self->botprompt if $self->prompts_on;

		print "$reply\n";

	} # End UI command loop.  


} # End method command_interface


####################################################################
# --- preprocess ---

=head2 	$string = preprocess($string);

B<preprocess> applies simple substitution rules to the input string.
Mostly this is to catch varieties in spelling, misspellings,
contractions and the like.  

B<preprocess> is called from within the B<transform> method.  
It is applied to user-input text, BEFORE any processing,
and before a reassebly statement has been selected. 

It uses the array B<%pre>, which is created 
during the parse of the script.

=cut

sub preprocess {
	my ($self,$string) = @_;

	my ($i, @wordsout, @wordsin, $keyword);
	@wordsout = @wordsin = split / /, $string;

	WORD: for ($i = 0; $i < @wordsin; $i++) {
		foreach $keyword (keys %{ $self->{pre} }) {
			if ($wordsin[$i] =~ /\b$keyword\b/i ) {
				($wordsout[$i] = $wordsin[$i]) =~ s/$keyword/$self->{pre}->{$keyword}/ig;
				next WORD;
			}
		}
	}
	return join ' ', @wordsout;
}


####################################################################
# --- postprocess ---

=head2 	$string = postprocess($string);

B<postprocess> applies simple substitution rules to the 
reassembly rule.  This is where all the "I"'s and "you"'s 
are exchanged.  B<postprocess> is called from within the
B<transform> function.

It uses the array B<%post>, created during the parse of the script.

=cut

sub postprocess {
	my ($self,$string) = @_;

	my ($i, @wordsout, @wordsin, $keyword);

	@wordsin = @wordsout = split (/ /, $string);

	WORD: for ($i = 0; $i < @wordsin; $i++) {
		foreach $keyword (keys %{ $self->{post} }) {
			if ($wordsin[$i] =~ /\b$keyword\b/i ) {
				($wordsout[$i] = $wordsin[$i]) =~ s/$keyword/$self->{post}->{$keyword}/ig;
				next WORD;
			}
		}
	}
	return join ' ', @wordsout;
}

####################################################################
# --- _testquit ---

=head2 if ($self->_testquit($user_input) ) { ... }

B< _testquit> detects words like "bye" and "quit" and returns
true if it finds one of them as the first word in the sentence. 

These words are listed in the script, under the keyword "quit". 

=cut

sub _testquit {
	my ($self,$string) = @_;

	my ($quitword, @wordsin);

	foreach $quitword (@{ $self->{quit} }) {
		return 1 if ($string =~ /\b$quitword\b/i ) ;
	}
}


####################################################################
# --- transform ---

=head2  $reply = $chatterbot->transform( $string );

B<transform> applies transformation rules to the user input
string.  It invokes B<preprocess>, does transformations, 
then invokes B<postprocess>.  It returns the tranformed 
output string, called B<$reasmb>.  

=cut

sub transform{
	my ($self,$string) = @_;

	my ($i, @string_parts, $string_part,
		$rank, $goto, $reasmb, $keyword, 
		$decomp, $this_decomp, 
		$reasmbkey, @these_reasmbs,
		@details, $synonyms, $synonym_index);

	$rank   = -2;
	$reasmb = "";
	$goto   = "";

	# First run the string through the preprocessor.  
	$string = $self->preprocess( $string );

	# Convert punctuation to periods.  We will assume that commas
	# separate distinct thoughts/sentences.  
	$string =~ s/[\?\!\,]/./g;

	# Split the string by periods into an array
	@string_parts = split /\./, $string ;

	# Examine each part of the input string in turn.
	STRING_PARTS: foreach $string_part (@string_parts) {

	# Run through the whole list of keywords.  
	KEYWORD: foreach $keyword (keys %{ $self->{decomplist} }) {

		# Check to see if the input string contains a keyword
		# which outranks any we have found previously
		# (On first loop, rank is set to -2.)
		if ( ($string_part =~ /\b$keyword\b/i or $keyword eq $goto) 
		     and 
		     $rank < $self->{keyranks}->{$keyword}  
		   ) 
		{
			# If we find one, then set $rank to equal the rank 
			# of that keyword. 
			$rank = $self->{keyranks}->{$keyword};
			print "\t$rank> $keyword" if ($self->debug);

			# Now lets check all the decomposition rules for that keyword. 
			DECOMP: foreach $decomp (@{ $self->{decomplist}->{$keyword} }) {

				# Change '*' to '\b(.*)\b' in this decomposition rule,
				# so we can use it for regular expressions.  Later, 
				# we will want to isolate individual matches to each wildcard. 
				($this_decomp = $decomp) =~ s/\s*\*\s*/\\b\(\.\*\)\\b/g;

				# If this docomposition rule contains a word which begins with'@', 
				# then the script also contained some synonyms for that word.  
				# Find them all using %synon and generate a regular expression 
				# containing all of them. 
				if ($this_decomp =~ /\@/ ) {
					($synonym_index = $this_decomp) =~ s/.*\@(\w*).*/$1/i ;
					$synonyms = join ('|', @{ $self->{synon}->{$synonym_index} });
					$this_decomp =~ s/(.*)\@$synonym_index(.*)/$1($synonym_index\|$synonyms)$2/g;
				}

				# Remove any stray '$'.  (Not sure why this is here....)
				$this_decomp =~ tr/$//d;
				print "\n\t\t: $decomp" if ($self->debug);

				# Using the regular expression we just generated, 
				# match against the input string.  Use empty "()"'s to 
				# eliminate warnings about uninitialized variables. 
				if ($string_part =~ /$this_decomp()()()()()()()()()()/i) {

					# Create an array, so that we can refer to matches to
					# individual wildcards within the regex. 
					@details = ("0", $1, $2, $3, $4, $5, $6, $7, $8, $9); 
					print " : @details\n" if ($self->debug);

					# Using the keyword and the decomposition rule,
					# reconstruct a key for the list of reassamble rules.
					$reasmbkey = join ($;,$keyword,$decomp);

					# Get the list of possible reassembly rules for this key. 
					@these_reasmbs = @{ $self->{reasmblist}->{$reasmbkey} };

					# Pick out a reassembly rule at random. 
					$reasmb = $these_reasmbs[ int rand $#these_reasmbs ];
					print "\t\t-->  $reasmb\n" if ($self->debug);

					# If the reassembly rule we picked contains the word "goto",
					# then we start over with a new keyword.  Set $keyword to equal
					# that word, and start the whole loop over. 
					if ($reasmb =~ m/^goto\s(\w*).*/i) {
						print "\$1 = $1\n" if ($self->debug);
						$goto = $keyword = $1;
						$rank = -2;
						redo KEYWORD;
					}

					# Otherwise, using the matches to wildcards which we stored above,
					# insert words from the input string back into the reassembly rule. 
					for ($i=1; $i< $#details; $i++) {
						$details[$i] = $self->postprocess( $details[$i] );
						$details[$i] =~ s/([,;?!]|\.*)$//;
						$reasmb =~ s/\($i\)/$details[$i]/;
					}

					# Move on to the next keyword.  If no other keywords match,
					# then we'll end up actually using the $reasmb string 
					# we just generated above.
					next KEYWORD ;

				}  # End if ($string_part =~ /$this_decomp/i) 

				print "\n" if $self->debug == 1;

			} # End DECOMP: foreach $decomp (@{ $self->{decomplist}->{$keyword} }) 

		} # End if ( ($string_part =~ /\b$keyword\b/i or $keyword eq $goto) 

	} # End KEYWORD: foreach $keyword (keys %{ $self->{decomplist})
	
	} # End STRING_PARTS: foreach $string_part (@string_parts) {

	# If all else fails, call this method recursively 
	# and make sure that it has something to parse. 
	$reasmb =  $self->transform("xnone") if $reasmb eq "";

	$reasmb =~ tr/ / /s;       # Eliminate any duplicate space characters. 
	$reasmb =~ s/[ ][?]$/?/;   # Eliminate any spaces before the question mark. 

	return $reasmb ;
}


####################################################################
# --- parse_script_data ---

=head2  $self->parse_script_data;

B<parse_script_data> is invoked from the B< _initialize> method.
It opens the scriptfile, if any, and reads in the script data.  

=head1  FORMAT OF THE SCRIPT FILE

This module includes a default script file within itself, 
so it is not necessary to explicitly specify a script file 
when instantiating an Eliza object.  

Each line in the script file can specify a key,
a decomposition rule, or a reassembly rule.

key: remember 5
  decomp: * i remember *
    reasmb: Do you often think of (2) ?
    reasmb: Does thinking of (2) bring anything else to mind ?
  decomp: * do you remember *
    reasmb: Did you think I would forget (2) ?
    reasmb: What about (2) ?
    reasmb: goto what
pre: equivalent alike
synon: belief feel think believe wish

The number after the key specifies the rank.
If a user's input contains the keyword, then
the "transform" function will try to match
one of the decomposition rules for that keyword.
If one matches, then it will select one of
the reassembly rules at random.  The number
(2) here means "use whatever set of words
matched the second asterisk in the decomposition
rule." 

If you specify a list of synonyms for a word,
the you should use a @ when you use that
word in a decomposition rule:

  decomp: * i @belief i *
    reasmb: Do you really think so ?
    reasmb: But you are not sure you (3).

Otherwise, the script will never check to see
if there are any synonyms for that keyword. 

=head1 HOW THE SCRIPTFILE IS PARSED

Each line in the script file contains an "entrytype"
(key, decomp, synon) and an "entry", separated by
a colon.  In turn, each "entry" can itself be 
composed of a "key" and a "value", separated by
a space.  The B<parse_script_data> function
parses each line out, and splits the "entry" and
"entrytype" portion of each line into two variables,
"$entry" and "$entrytype". 

Next, it uses the string "$entrytype" to determine 
what sort of stuff to expect in the "$entry" variable,  
if anything, and parses it accordingly.  In some cases,
there is no second level of key-value pair, so the function
does not even bother to isolate or create "$key" and "$value". 

"$key" is always a single word.  "$value" can be null, 
or one single word, or a string composed of several words, 
or an array of words.  

Based on all these entries and keys and values,
the function creates two giant hashes:
B<%decomplist>, which holds the decomposition rules for
each keyword, and B<%reasmblist>, which holds the 
reassembly phrases for each decomposition rule. 
It also creates %keyranks, which holds the ranks for
each key.  

Five other arrays are created: B<%pre, %post, 
%synon, @initial,> and B<@final>. 


=cut

sub parse_script_data {

	my ($self,$scriptfile) = @_;
	my @scriptlines;

	if ($scriptfile) {

		# If we have an external script file, open it 
		# and read it in (the whole thing, all at once). 
		open  (SCRIPTFILE, "<$scriptfile") 
			or die "Could not read from file $scriptfile : $!\n";
		@scriptlines = <SCRIPTFILE>; # read in script data 
		$self->scriptfile($scriptfile);
		close (SCRIPTFILE);

	} else {

		# Otherwise, read in the data from the bottom 
		# of this file.  This data might be read several
		# times, so we save the offset pointer and
		# reset it when we're done.
		my $where= tell(DATA);
		@scriptlines = <DATA>;  # read in script data 
		seek(DATA, $where, 0);
		$self->scriptfile('');
	}

	my ($entrytype, $entry, $key, $value) ;
	my $thiskey    = ""; 
	my $thisdecomp = "";

	############################################################
	# Examine each line of script data.  
	for (@scriptlines) { 

		# Skip comments and lines with only whitespace.
		next if (/^\s*#/ || /^\s*$/);  

		# Split entrytype and entry, using a colon as the delimiter.
		($entrytype, $entry) = $_ =~ m/^\s*(\S*)\s*:\s*(.*)\s*$/;

		# Case loop, based on the entrytype.
		for ($entrytype) {   

			/quit/		and do { push @{ $self->{quit}    }, $entry; last; };
			/initial/	and do { push @{ $self->{initial} }, $entry; last; };
			/final/		and do { push @{ $self->{final}   }, $entry; last; };

			/decomp/	and do { 
						die "$0: error parsing script:  decomposition rule with no keyword.\n" 
							if $thiskey eq "";
						$thisdecomp = join($;,$thiskey,$entry);
						push @{ $self->{decomplist}->{$thiskey} }, $entry ; 
						last; 
					};

			/reasmb/	and do { 
						die "$0: error parsing script:  reassembly rule with no decomposition rule.\n" 
							if $thisdecomp eq "";
						push @{ $self->{reasmblist}->{$thisdecomp} }, $entry ;  
						last; 
					};

			# The entrytypes below actually expect to see a key and value
			# pair in the entry, so we split them out.  The first word, 
			# separated by a space, is the key, and everything else is 
			# an array of values.

			($key,$value) = $entry =~ m/^\s*(\S*)\s*(.*)/;

			/pre/		and do { $self->{pre}->{$key}   = $value; last; };
			/post/		and do { $self->{post}->{$key}  = $value; last; };

			# synon expects an array, so we split $value into an array, using " " as delimiter.  
			/synon/		and do { $self->{synon}->{$key} = [ split /\ /, $value ]; last; };

			/key/		and do { 
						$thiskey = $key; 
						$thisdecomp = "";
						$self->{keyranks}->{$thiskey} = $value ; 
						last;
					};
	
		}  # End for ($entrytype) (case loop) 

	}  # End for (@scriptlines)

}  # End of method parse_script_data

# ---{ E N D   M E T H O D S }----------------------------------
####################################################################

1;  	# Return a true value.  


=head2

John Nolan (jnolan@n2k.com) November 1997

=cut


####################################################################
# ---{ B E G I N   D E F A U L T   S C R I P T   D A T A }----------
#
#  This script was prepared by Chris Hayden.  Hayden's Eliza 
#  program was written in Java, however, it attempted to match 
#  the functionality of Weizenbaum's original program as closely 
#  as possible.  
#
#  Hayden's script format was quite different from Weizenbaum's, 
#  but it maintained the same content.  I have adapted Hayden's 
#  script format, since it was simple and convenient enough 
#  for my purposes.  
#
#  I've made small modifications here and there.  
#

# Sample script data.

# We use the token __DATA__ rather than __END__, 
# so that all this data is visible within the current package.

__DATA__
initial: How do you do.  Please tell me your problem.
initial: Hello, I am a computer program. 
initial: Please tell me what's been bothering you. 
initial: Is something troubling you?
final: Goodbye.  It was nice talking to you.
final: Goodbye.  I hope you found this session helpful.
final: I think you should talk to a REAL analyst.  Ciao! 
final: Life is tough.  Hang in there!
quit: bye
quit: goodbye
quit: done
quit: exit
quit: quit
pre: dont don't
pre: cant can't
pre: wont won't
pre: recollect remember
pre: recall remember
pre: dreamt dreamed
pre: dreams dream
pre: maybe perhaps
pre: certainly yes
pre: machine computer
pre: machines computer
pre: computers computer
post: am are
post: your my
post: yours mine
pre: were was
post: me you
pre: you're you are
pre: i'm i am
post: myself yourself
post: yourself myself
post: i you
post: you me
post: my your
post: me you
post: i'm you are
pre: same alike
pre: identical alike
pre: equivalent alike
synon: belief feel think believe wish
synon: family mother mom father dad sister brother wife children child
synon: desire want need
synon: sad unhappy depressed sick
synon: happy elated glad better
synon: cannot can't
synon: everyone everybody nobody noone
synon: be am is are was
key: xnone -1
  decomp: *
    reasmb: I'm not sure I understand you fully.
    reasmb: Please go on.
	reasmb: That is interesting.  Please continue.
	reasmb: Tell me more about that.
	reasmb: Does talking about this bother you ?
key: sorry 0
  decomp: *
    reasmb: Please don't apologise.
    reasmb: Apologies are not necessary.
    reasmb: I've told you that apologies are not required.
	reasmb: It did not bother me.  Please continue.
key: apologise 0
  decomp: *
    reasmb: goto sorry
key: remember 5
  decomp: * i remember *
    reasmb: Do you often think of (2) ?
    reasmb: Does thinking of (2) bring anything else to mind ?
    reasmb: What else do you recollect ?
    reasmb: Why do you remember (2) just now ?
    reasmb: What in the present situation reminds you of (2) ?
    reasmb: What is the connection between me and (2) ?
	reasmb: What else does (2) remind you of ?
  decomp: * do you remember *
    reasmb: Did you think I would forget (2) ?
    reasmb: Why do you think I should recall (2) now ?
    reasmb: What about (2) ?
    reasmb: goto what
    reasmb: You mentioned (2) ?
   decomp: * you remember *
	reasmb: How could I forget (2) ?
	reasmb: What about (2) should I remember ?
	reasmb: goto you
key: forget 5
   decomp: * i forget *
	reasmb: Can you think of why you might forget (2) ?
	reasmb: Why can't you remember (2) ?
	reasmb: How often do you think of (2) ?
	reasmb: Does it bother you to forget that ?
	reasmb: Could it be a mental block ?
	reasmb: Are you generally forgetful ?
	reasmb: Do you think you are suppressing (2) ?
   decomp: * did you forget *
	reasmb: Why do you ask ?
	reasmb: Are you sure you told me ?
	reasmb: Would it bother you if I forgot (2) ?
	reasmb: Why should I recall (2) just now ?
	reasmb: goto what
	reasmb: Tell me more about (2).
key: if 3
  decomp: * if *
    reasmb: Do you think its likely that (2) ?
    reasmb: Do you wish that (2) ?
    reasmb: What do you know about (2) ?
    reasmb: Really, if (2) ?
	reasmb: What would you do if (2) ?
	reasmb: But what are the chances that (2) ?
	reasmb: What does this speculation lead to ?
key: dreamed 4
  decomp: * i dreamed *
    reasmb: Really, (2) ?
    reasmb: Have you ever fantasized (2) while you were awake ?
    reasmb: Have you ever dreamed (2) before ?
    reasmb: goto dream
key: dream 3
  decomp: *
    reasmb: What does that dream suggest to you ?
    reasmb: Do you dream often ?
    reasmb: What persons appear in your dreams ?
    reasmb: Do you believe that dreams have something to do with your problem ?
key: perhaps 0
  decomp: *
    reasmb: You don't seem quite certain.
    reasmb: Why the uncertain tone ?
    reasmb: Can't you be more positive ?
    reasmb: You aren't sure ?
    reasmb: Don't you know ?
	reasmb: How likely, would you estimate ?
key: name 15
  decomp: *
    reasmb: I am not interested in names.
    reasmb: I've told you before, I don't care about names -- please continue.
key: deutsch 0
  decomp: *
    reasmb: goto xforeign
    reasmb: I told you before, I don't understand German.
key: francais 0
  decomp: *
    reasmb: goto xforeign
    reasmb: I told you before, I don't understand French.
key: italiano 0
  decomp: *
    reasmb: goto xforeign
    reasmb: I told you before, I don't understand Italian.
key: espanol 0
  decomp: *
    reasmb: goto xforeign
    reasmb: I told you before, I don't understand Spanish.
key: xforeign 0
  decomp: *
    reasmb: I speak only English.
key: hello 0
  decomp: *
    reasmb: How do you do.  Please state your problem.
    reasmb: Hi.  What seems to be your problem ?
key: computer 50
  decomp: *
    reasmb: Do computers worry you ?
    reasmb: Why do you mention computers ?
    reasmb: What do you think machines have to do with your problem ?
    reasmb: Don't you think computers can help people ?
    reasmb: What about machines worries you ?
    reasmb: What do you think about machines ?
	reasmb: You don't think I am a computer program, do you ?
key: am 0
  decomp: * am i *
    reasmb: Do you believe you are (2) ?
    reasmb: Would you want to be (2) ?
    reasmb: Do you wish I would tell you you are (2) ?
    reasmb: What would it mean if you were (2) ?
    reasmb: goto what
  decomp: * i am *
	reasmb: goto i
  decomp: *
    reasmb: Why do you say 'am' ?
    reasmb: I don't understand that.
key: are 0
  decomp: * are you *
    reasmb: Why are you interested in whether I am (2) or not ?
    reasmb: Would you prefer if I weren't (2) ?
    reasmb: Perhaps I am (2) in your fantasies.
    reasmb: Do you sometimes think I am (2) ?
    reasmb: goto what
	reasmb: Would it matter to you ?
	reasmb: What if I were (2) ?
  decomp: * you are *
	reasmb: goto you
  decomp: * are *
    reasmb: Did you think they might not be (2) ?
    reasmb: Would you like it if they were not (2) ?
    reasmb: What if they were not (2) ?
	reasmb: Are they always (2) ?
    reasmb: Possibly they are (2).
	reasmb: Are you positive they are (2) ?
key: your 0
  decomp: * your *
    reasmb: Why are you concerned over my (2) ?
    reasmb: What about your own (2) ?
    reasmb: Are you worried about someone else's (2) ?
    reasmb: Really, my (2) ?
	reasmb: What makes you think of my (2) ?
	reasmb: Do you want my (2) ?
key: was 2
  decomp: * was i *
    reasmb: What if you were (2) ?
    reasmb: Do you think you were (2) ?
    reasmb: Were you (2) ?
    reasmb: What would it mean if you were (2) ?
    reasmb: What does ' (2) ' suggest to you ?
    reasmb: goto what
  decomp: * i was *
    reasmb: Were you really ?
    reasmb: Why do you tell me you were (2) now ?
    reasmb: Perhaps I already know you were (2).
  decomp: * was you *
    reasmb: Would you like to believe I was (2) ?
    reasmb: What suggests that I was (2) ?
    reasmb: What do you think ?
    reasmb: Perhaps I was (2).
    reasmb: What if I had been (2) ?
key: i 0
  decomp: * i @desire *
    reasmb: What would it mean to you if you got (3) ?
    reasmb: Why do you want (3) ?
    reasmb: Suppose you got (3) soon.
    reasmb: What if you never got (3) ?
    reasmb: What would getting (3) mean to you ?
    reasmb: What does wanting (3) have to do with this discussion ?
  decomp: * i am* @sad *
    reasmb: I am sorry to hear that you are (3).
    reasmb: Do you think coming here will help you not to be (3) ?
    reasmb: I'm sure it's not pleasant to be (3).
    reasmb: Can you explain what made you (3) ?
  decomp: * i am* @happy *
    reasmb: How have I helped you to be (3) ?
    reasmb: Has your treatment made you (3) ?
    reasmb: What makes you (3) just now ?
    reasmb: Can you explain why you are suddenly (3) ?
  decomp: * i was *
    reasmb: goto was
  decomp: * i @belief i *
    reasmb: Do you really think so ?
    reasmb: But you are not sure you (3).
    reasmb: Do you really doubt you (3) ?
  decomp: * i* @belief *you *
    reasmb: goto you
  decomp: * i am *
    reasmb: Is it because you are (2) that you came to me ?
    reasmb: How long have you been (2) ?
    reasmb: Do you believe it is normal to be (2) ?
    reasmb: Do you enjoy being (2) ?
	reasmb: Do you know anyone else who is (2) ?
  decomp: * i @cannot *
    reasmb: How do you know that you can't (3) ?
    reasmb: Have you tried ?
    reasmb: Perhaps you could (3) now.
    reasmb: Do you really want to be able to (3) ?
	reasmb: What if you could (3) ?
  decomp: * i don't *
    reasmb: Don't you really (2) ?
    reasmb: Why don't you (2) ?
    reasmb: Do you wish to be able to (2) ?
    reasmb: Does that trouble you ?
  decomp: * i feel *
    reasmb: Tell me more about such feelings.
    reasmb: Do you often feel (2) ?
    reasmb: Do you enjoy feeling (2) ?
    reasmb: Of what does feeling (2) remind you ?
  decomp: * i * you *
    reasmb: Perhaps in your fantasies we (2) each other.
    reasmb: Do you wish to (2) me ?
    reasmb: You seem to need to (2) me.
    reasmb: Do you (2) anyone else ?
  decomp: *
    reasmb: You say (1) ?
    reasmb: Can you elaborate on that ?
    reasmb: Do you say (1) for some special reason ?
    reasmb: That's quite interesting.
key: you 0
  decomp: * you remind me of *
    reasmb: goto alike
  decomp: * you are *
    reasmb: What makes you think I am (2) ?
    reasmb: Does it please you to believe I am (2) ?
    reasmb: Do you sometimes wish you were (2) ?
    reasmb: Perhaps you would like to be (2).
  decomp: * you* me *
    reasmb: Why do you think I (2) you ?
    reasmb: You like to think I (2) you -- don't you ?
    reasmb: What makes you think I (2) you ?
    reasmb: Really, I (2) you ?
    reasmb: Do you wish to believe I (2) you ?
    reasmb: Suppose I did (2) you -- what would that mean ?
    reasmb: Does someone else believe I (2) you ?
  decomp: * you *
    reasmb: We were discussing you -- not me.
    reasmb: Oh, I (2) ?
    reasmb: You're not really talking about me -- are you ?
    reasmb: What are your feelings now ?
key: yes 0
  decomp: *
    reasmb: Please go on.
    reasmb: Please tell me some more about this.
    reasmb: Why don't you tell me a little more about this.
    reasmb: I see.
    reasmb: I understand.
key: no 0
   decomp: * no one *
	reasmb: Are you sure, no one (2) ?
	reasmb: Surely someone (2) .
	reasmb: Can you think of anyone at all ?
	reasmb: Are you thinking of a very special person ?
	reasmb: Who, may I ask ?
	reasmb: You have a particular person in mind, don't you ?
	reasmb: Who do you think you are talking about ?
  decomp: *
    reasmb: Are you saying no just to be negative?
    reasmb: Does this make you feel unhappy? 
    reasmb: Why not ?
    reasmb: Why 'no' ?
key: my 2
#  decomp: $ * my *
#    reasmb: Lets discuss further why your (2).
#    reasmb: Earlier you said your (2).
#    reasmb: But your (2).
#    reasmb: Does that have anything to do with the fact that your (2) ?
  decomp: * my* @family *
    reasmb: Tell me more about your family.
    reasmb: Who else in your family (4) ?
    reasmb: Your (3) ?
    reasmb: What else comes to mind when you think of your (3) ?
  decomp: * my *
    reasmb: Your (2) ?
    reasmb: Why do you say your (2) ?
    reasmb: Does that suggest anything else which belongs to you ?
    reasmb: Is it important to you that your (2) ?
key: can 0
  decomp: * can you *
    reasmb: You believe I can (2) don't you ?
    reasmb: goto what
    reasmb: You want me to be able to (2).
    reasmb: Perhaps you would like to be able to (2) yourself.
  decomp: * can i *
    reasmb: Whether or not you can (2) depends on you more than on me.
    reasmb: Do you want to be able to (2) ?
    reasmb: Perhaps you don't want to (2).
    reasmb: goto what
key: what 0
  decomp: *
    reasmb: Why do you ask ?
    reasmb: Does that question interest you ?
    reasmb: What is it you really want to know ?
    reasmb: Are such questions much on your mind ?
    reasmb: What answer would please you most ?
    reasmb: What do you think ?
    reasmb: What comes to mind when you ask that ?
    reasmb: Have you asked such questions before ?
    reasmb: Have you asked anyone else ?
key: who 0
   decomp:  who *
	reasmb: goto what
key: when 0
   decomp:  when *
	reasmb: goto what
key: where 0
   decomp:  where *
	reasmb: goto what
key: how 0
   decomp:  how *
	reasmb: goto what
key: because 0
  decomp: *
    reasmb: Is that the real reason ?
    reasmb: Don't any other reasons come to mind ?
    reasmb: Does that reason seem to explain anything else ?
    reasmb: What other reasons might there be ?
key: why 0
  decomp: * why don't you *
    reasmb: Do you believe I don't (2) ?
    reasmb: Perhaps I will (2) in good time.
    reasmb: Should you (2) yourself ?
    reasmb: You want me to (2) ?
    reasmb: goto what
  decomp: * why can't i *
    reasmb: Do you think you should be able to (2) ?
    reasmb: Do you want to be able to (2) ?
    reasmb: Do you believe this will help you to (2) ?
    reasmb: Have you any idea why you can't (2) ?
    reasmb: goto what
  decomp: *
    reasmb: goto what
key: everyone 2
  decomp: * @everyone *
    reasmb: Really, (2) ?
    reasmb: Surely not (2).
    reasmb: Can you think of anyone in particular ?
    reasmb: Who, for example?
    reasmb: Are you thinking of a very special person ?
    reasmb: Who, may I ask ?
    reasmb: Someone special perhaps ?
    reasmb: You have a particular person in mind, don't you ?
    reasmb: Who do you think you're talking about ?
key: everybody 2
  decomp: *
    reasmb: goto everyone
key: nobody 2
  decomp: *
    reasmb: goto everyone
key: noone 2
  decomp: *
    reasmb: goto everyone
key: always 1
  decomp: *
    reasmb: Can you think of a specific example ?
    reasmb: When ?
    reasmb: What incident are you thinking of ?
    reasmb: Really, always ?
key: alike 10
  decomp: *
    reasmb: In what way ?
    reasmb: What resemblence do you see ?
    reasmb: What does that similarity suggest to you ?
    reasmb: What other connections do you see ?
    reasmb: What do you suppose that resemblence means ?
    reasmb: What is the connection, do you suppose ?
    reasmb: Could there really be some connection ?
    reasmb: How ?
key: like 10
  decomp: * @be *like *
    reasmb: goto alike
key: different 0
   decomp: *
	reasmb: How is it different ?
	reasmb: What differences do you see ?
	reasmb: What does that difference suggest to you ?
	reasmb: What other distinctions do you see ?
	reasmb: What do you suppose that disparity means ?
	reasmb: Could there be some connection, do you suppose ?
	reasmb: How ?
key: fuck 10
  decomp: * 
	reasmb: goto xswear
key: fucker 10
  decomp: * 
	reasmb: goto xswear
key: shit 10
  decomp: * 
	reasmb: goto xswear
key: damn 10
  decomp: * 
	reasmb: goto xswear
key: shut 10
  decomp: * shut up *
	reasmb: goto xswear
key: xswear 10
  decomp: * 
	reasmb: Does it make you feel strong to use that kind of language ?
	reasmb: Are you venting your feelings now ?
	reasmb: Are you angry ?
	reasmb: Does this topic make you feel angry ? 
	reasmb: Is something making you feel angry ? 
	reasmb: Does using that kind of language make you feel better ? 
