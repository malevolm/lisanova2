#!/usr/bin/perl 
use IO::Socket::INET;

my $line;
my $connected = 0;
my @triggers, my @buffer, my @parts;

my $fsck = IO::Socket::INET->new(PeerAddr => $ARGV[0],
                                 PeerPort => 6667,
                                 Proto    => 'tcp') or die("couldn't connect");

print $fsck "PASS LiSaNoVATwo\r\n";
print $fsck "NICK $ARGV[1]\r\n";                                 
print $fsck "USER wat 8 * :wat\r\n";
      
while(my $line = <$fsck>)
{
  $line =~ s/\r\n$//;
  print ">>> $line\n";
  @parts = ($line =~ m/^:(.+?)!(.+?)@(.+?) (.+?) :*(.+?)( :|$)(.*?)$/g); 
  print "}}} @parts\n";
  
  print $fsck "PONG :$1\n"
    if($line =~ m/^PING :(.+?)$/);
  
  if($connected == 1)
  {
    for(my $x=0;$x<scalar(@triggers);$x++)
    {
      my $trigger = $triggers[$x]->{"trigger"};
      if($line =~ m/$trigger/)
      {
        my $response = $triggers[$x]->{"response"};
        for(my $i=1; $i < 16; $i++)
        {
          my $value = $$i;
          $response =~ s/\$$i/$value/g;
          $response =~ s/\\n/\n/g;
        }

        print $fsck "$response\n";        
      }
    }

    if($parts[3] eq "PRIVMSG")
    {
      if($parts[6] =~ m/^\.\. \+t (.+?) \=\> (.+?)$/g)
      {
        push (@triggers, {"trigger" => $1, "response" => $2});
        print "&&& added trigger: $1 \nand response: $2\narray: @triggers\n";
      }
      elsif($parts[6] =~ m/^\.\. update (\d+?) (.+?) \=\> (.+?)$/g)
      {
        $triggers[$1] = {"trigger" => $2, "response" => $3};
        listTriggers($parts[4]);
      }
      elsif($parts[6] =~ m/^\.\. list/g)
      {
        listTriggers($parts[4]);
      }
      elsif($parts[6] =~ m/^\.\. save/g)
      {
        saveTriggers();
      }
      elsif($parts[6] =~ m/^\.\. load/g)
      {
        loadTriggers();
        listTriggers($parts[4]);
      }
      elsif($parts[6] =~ m/^\.\. delete (\d+?)/g)
      {
        deleteTriggers($1);
        listTriggers($parts[4]);
      }
    }
  } else {
    if($line =~ m/^:.+? 376 /)
    {
      $connected = 1;
      loadTriggers();
      print $fsck "JOIN $ARGV[2]\n";
    }
  }
}

sub listTriggers
{
  for(my $x=0; $x < scalar(@triggers);$x++)
  {
    print $fsck "PRIVMSG $_[0] :\x02#$x)\x02 trigger: " . $triggers[$x]->{"trigger"} . " => " . $triggers[$x]->{"response"} . "\n";
  }
}

sub saveTriggers
{
  my $data;
  
  $data .= $_->{"trigger"} . "\n" . $_->{"response"} . "\n\n"
    foreach(@triggers);
    
  open(TRIG, '>triggers');
  print TRIG $data;
  close TRIG;
}

sub loadTriggers
{
  @triggers = ();
  my $data = `cat /home/malcolm/dev/ircbot/triggers`;
  my @trig = split(/\n\n/, $data);

  foreach(@trig)
  {
    my @pair = split(/\n/, $_);
    push (@triggers, {"trigger" => $pair[0], "response" => $pair[1]});
  }
}

sub deleteTriggers
{
  splice(@triggers, ($_[0]), 1); 
}
