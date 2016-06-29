package Chatbot::Eliza::ScriptParser;

use Moo;

use feature 'say';
use experimental qw[
    signatures
];

has 'script_file' => (
    is => 'rw',
    default => q{},
);

my %data = (
    quit => sub { [ ] },
    initial => sub { [ ] },
    final => sub { [ ] },
    decomp => sub { { } },
    reasmb => sub { { } },
    reasmb_for_memory => sub { { } },
    pre => sub { { } },
    post => sub { { } },
    synon => sub { { } },
    key => sub { { } },
    unique_words => sub { { } },
);

while ( my( $key, $value ) = each %data ) {
    has $key => (
        is => 'rw',
        lazy => 1,
        default => $value,
    );
}

sub parse_script_data ($self) {
    my @script_lines = $self->_open_script_file($self->script_file);
    my ($thiskey, $decomp);
    # Examine each line of the script data
    for my $line (@script_lines) {
            
        # Skip comments and lines with only whitespace
        next if $line =~ /^[\s*#|\s*]$/;
        
        # mehhh may be slow who knows
        $self->_unique_words($line);

        # Split entrytype and entry, using a colon as the delimiter
        my ($entry_type, $entry) = split /:/, $line;
        # remove the whitespace
        $entry_type = _trim_string($entry_type);
        $entry = _trim_string($entry);
    
        for ($entry_type) {
            /quit|initial|final/ and do { push $self->$_->@*, $entry; last; };
            /decomp/ and do {
                die "$0: error parsing script: decomp rule with no keyword. \n"
                    unless $thiskey;
                $decomp = join($;, $thiskey, $entry);
                push $self->$_->{$thiskey}->@*, $entry;
                last;
            };
            /reasmb|reasmb_for_mempory/ and do {
                die "$0: error parsing scrip reassembly rule with no decomposition rule" 
                    unless $decomp;
                push $self->$_->{$decomp}->@*, $entry;
                last;
            };
            # everything else we have a key - split on first space
            my ($key, $value) = split(/\s/, $entry);
            /pre|post/ and do { $self->$_->{$key} = $value; last; };
            /synon/ and do { $self->$_->{$key} = [ split /\ /, $value ]; last; };
            /key/ and do { 
                $thiskey = $key;
                $decomp = "";
                $self->$_->{$key} = $value; 
                last; 
            };
        }
    }
}

sub _unique_words ($self, $line) {
    $line =~ s/[^a-zA-Z\'\s+]//g;
    my @words = split(' ', $line); 
    foreach my $word ( @words ) {
        $self->unique_words->{$word}++;
    }
    return;
};

sub _trim_string ($string) {
    $string =~ s/^\s+|\s+$//g;
    return $string;
}

sub _open_script_file ($self, $script_file) {    
    my @script_lines;
    if ($script_file) {
        # If we have an external script file, open it
        open (my $fh, "<", $script_file)
            or die "Could not read from file $script_file : $!\n";
        
        @script_lines = <$fh>;
        close ($fh);

        $self->script_file($script_file);
    }
    else {
        # Otherwise, read in the data from the bottom of this file.
        # This data might be read several times, so we save the offset pointer
        my $where = tell(DATA);
        @script_lines = <DATA>;
        
        # and reset it when we're done.
        seek(DATA, $where, 0);
        $self->script_file('none');
    }
    return @script_lines;
}

1;

=head1 Name

Chatbot::Eliza::ScriptParser

=over

=head1 Version

Version 2.0

=over

=head1 Options

=item script_file

=item quit

=item initial

=item final

=item decomp

=item reasmb

=item reasmb_for_memory

=item pre

=item post

=item synon

=item key

=item unique_words

=over

=head1 SUBROUTINES/METHODS

=head2 parse_script_data()
    
    $self->parse_script_data;
    $self->parse_script_data( $script_file );

parse_script_data() is invoked from the _initialize() method, which is called from 
the new() function.  However, you can also call this method at any time against 
an already-instantiated Eliza instance.  In that case, the new script data is I<added>
to the old script data.  The old script data is not deleted. 

You can pass a parameter to this function, which is the name of the script file, 
and it will read in and parse that file.  If you do not pass any parameter to 
this method, then it will read the data embedded at the end of the module as its
default script data.  

If you pass the name of a script file to parse_script_data(), and that file is 
not available for reading, then the module dies.  

=over 

=head1 Format of the script file

This module includes a default script file within itself, so it is not necessary 
to explicitly specify a script file when instantiating an Eliza object. Each line 
in the script file can specify a key, a decomposition rule, or a reassembly rule.

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

The number after the key specifies the rank. If a user's input contains the keyword, then
the transform() function will try to match one of the decomposition rules for that keyword.
If one matches, then it will select one of the reassembly rules at random.  The number
(2) here means "use whatever set of words matched the second asterisk in the decomposition
rule." If you specify a list of synonyms for a word, the you should use a "@" when you use that
word in a decomposition rule:
  
    decomp: * i @belief i *
        reasmb: Do you really think so ?
        reasmb: But you are not sure you (3).

Otherwise, the script will never check to see if there are any synonyms for that keyword. 
Reassembly rules should be marked with I<reasm_for_memory> rather than I<reasmb> when it is appropriate for use when a user's comment has been extracted from memory. 
  
    key: my 2
        decomp: * my *
            reasm_for_memory: Let's discuss further why your (2).
            reasm_for_memory: Earlier you said your (2).
            reasm_for_memory: But your (2).
            reasm_for_memory: Does that have anything to do with the fact that your (2) ?

=cut

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
    reasmb: goto xfremd
    reasmb: I told you before, I don't understand German.
key: francais 0
  decomp: *
    reasmb: goto xfremd
    reasmb: I told you before, I don't understand French.
key: italiano 0
  decomp: *
    reasmb: goto xfremd
    reasmb: I told you before, I don't understand Italian.
key: espanol 0
  decomp: *
    reasmb: goto xfremd
    reasmb: I told you before, I don't understand Spanish.
key: xfremd 0
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
    reasmb: Why do you say (1) ?
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
    reasm_for_memory: Let's discuss further why your (2).
    reasm_for_memory: Earlier you said your (2).
    reasm_for_memory: But your (2).
    reasm_for_memory: Does that have anything to do with the fact that your (2) ?
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

