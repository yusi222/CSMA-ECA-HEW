#!/usr/local/bin/perl
use warnings;
use strict;
use Switch;

die ("Getting out. You need some parameters, i.e.: --help\n") if (not exists $ARGV[0]);

chomp($ARGV[0]);

my %help = (
				help		=> 1,
				'-h'		=> 1,
				'--help'	=> 1
			);

die ("******Help\n", "ARGV. field:\n", "0. Repetitions 1. Time 2. Nmax 3. Nmin 4. Jumps 5. Bandwidth 6. Channel errors 7. EDCA share 8. ECA Code 9. numACs 10. LENGTH(Bytes)\n") 
	if (exists $help{$ARGV[0]});

my $rep = 5;
my $time = 100;
my $Nmax = 50;
my $Nmin = 2;
my $jump = 1;
my $bandwidth = 65e6;
my $errors = 0;
my $numACs = 4;
my $length = 1470;
my $batch = 1;
my $drift = 0;
my $maxAggregation = 0;
my $ECA = 1;
my $stickiness = 1;
my $fairShare = 1;
my $EDCA_share = 0;

my $saturated = 1;
my $mixed = 0;

my $scenario = $ARGV[0];
switch ($scenario){
	case "single"{
		print "single Test\n";
		$rep = 1;
		$time = 100;
		$Nmax = 50;
		$Nmin = 2;
		$ECA = 0;
		$stickiness = 0;
		$fairShare = 0;
		$errors = 0
			if ($saturated == 0);
		$EDCA_share = 0.5
			if ($mixed == 1);
	}
	case "EDCA"{
		print "EDCA\n";
		$ECA = 0;
		$stickiness = 0;
		$fairShare = 0;
		$EDCA_share = 1;
		$errors = 0.1
			if ($saturated == 0);
	}
	case "ECA"{
		print "CSMA/ECAqos: Full ECA\n";
		$stickiness = 1;
		$errors = 0.1
			if ($saturated == 0);
		$EDCA_share = 0.5
			if ($mixed == 1);
	}
	case "ECA1"{
		print "ECA1: HystOnly\n";
		$stickiness = 1;
		$fairShare = 0;
		$errors = 0.1
			if ($saturated == 0);
		$EDCA_share = 0.5
			if ($mixed == 1);
	}
}

print ("Going to simulate:\n");
print ("\tScenario: $scenario\n\n\n");

my $compile = './build_local';
my @command;
my @jumps;

system($compile);
die "Command failed\n" if ($? != 0);

#Simulating at $jump intervals
foreach ($Nmin .. $Nmax)
{
	push @jumps, $_
		if $_ % $jump == 0;
}
push @jumps, $Nmax
	if $jumps[-1] != $Nmax;


OUTTER: foreach my $i (@jumps){
	INNER: foreach my $j (1 .. $rep){
		my $seed = int(rand()*1000);
		@command = ("./ECA_exec $time $i $length $bandwidth $batch $ECA $stickiness $fairShare $errors $drift $EDCA_share $maxAggregation $numACs $seed"); 
		print ("\n\n****Node #$i of $Nmax ($?).\n");
		print ("****Iteration #$j of $rep.\n");
		print ("**** @command\n");
		system(@command);
		(print ("\n\n********Execution failed\n\tQuitting iterations\n") and die "Quit\n") if ($? != 0);
	}
}


# #Calling the parser
my $parserFile = 'process.pl';
# my $parseSlots = 'analyseSlots.pl';
my $dataFile = 'Results/output.txt';
# my $slotsFile = 'Results/slotsInTime.txt';
my @parseCommand = ("./$parserFile $dataFile");
system(@parseCommand);
(print ("\n\n********Processing failed\n") and last OUTTER) if ($? != 0);
# @parseCommand = ("./$parseSlots $slotsFile");
# system(@parseCommand);
# (print ("\n\n********Processing failed\n") and last OUTTER) if ($? != 0);

my $simulation = "$scenario";
my @mail = ("./sendMail $simulation");
system(@mail)
	if ($simulation ne "single");



