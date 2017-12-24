#use strict;
use Data::Dumper;
use POSIX;
use warnings;
$|=1;

# you will need to call this below method from code in this or another file to use it.
sub compressPatternIDXI
{
    # Description: This method takes in a pattern stored as a array, and is compressed and returned. 
    # input: input pattern that needs to be converted
    # output: modified input pattern
    
    my @outputPattern=@{$_[0]};
    my @outputPattern_back = @outputPattern;
	@outputPattern=(); #clear array
	my $c1=0;
	my $c2=0;
    
    ## NOTE:
	## Cannot specify the Instruction Name <IDXI>. Only the Instruction Name <NOP> can specify between the 
	## Instruction Name <JSC> and the Instruction Name <EXITSC>
	## => if Channel Linking, then do not compress these vectors
	
	# current vector line to compare with the unique vector line
	my $currentLine;
	my $currentVector;
	
	# first unique vector in a sequence
	my $uniqueLine;
	my $uniqueVector='FIRST';
	
	# new vector line
	my $newLine;
		
	my $repeatCount=0;
	my $idxiCount=0;
	
	printLog(executionLogFH,"START: compressPatternIDXI() ");
	
	foreach my $line(@outputPattern_back)
	{
		if (($line=~/JSC/) || ($line=~/EXITSC/) || ($line=~/STSS SC1/) || ($line=~/EXIT/) || ($line=~/INFO/))
		{
			##printLog(executionLogFH,"DEBUG: $c1: JSC/EXITSC/EXIT vector. Do not change");
			# dump the vector
			$outputPattern[$c1]=$line;
			$c1++;
			next;
		}
	
		# check if the line is a non-CL vector
		##if (($line=~/all_pins_norm/) || ($line=~/all_pins_scan/))  ##ORIG
		if ($line=~/all_pins_norm/)
		{
			$currentLine=$line;
			$currentVector=getVector($line);
			##print "vector=$current_vector \n"; <STDIN>;
			
			# first unique_vector=current_vector
			if ($uniqueVector eq 'FIRST')
			{
				$uniqueLine=$currentLine;
				$uniqueVector=$currentVector;
			}
			
			if ($currentVector eq $uniqueVector)
			{
				$repeatCount++;
			}
			else
			{
                my $newPrefixLine='';
				if ($repeatCount>1)
				{
					# REDUNDANCY FOUND, dump IDXI vector
					##printLog(executionLogFH,"DEBUG: $repeat_count: REDUNDANCY FOUND, dump IDXI vector");
									
					$uniqueLine =~ /(.+)({ V { all_pins_norm = )(.*)(; } W .*)/;  # to include special case of EXIT tag on last vector
					my $prefixLine=$1;
					my $prefixVector=$2;
					my $vector=$3;
					my $postfix=$4;		
					$idxiCount=$repeatCount-1;
					$newPrefixLine='    IDXI '.$idxiCount.' '.$prefixVector.$vector.$postfix;					
					
					# dump the vector
					$outputPattern[$c1]=$newPrefixLine;
					$c1++;
					
					# reset the unique_vector
					$uniqueLine=$currentLine;
					$uniqueVector=$currentVector;
					$newPrefixLine='';
					
					# reset the count
					$repeatCount=1;		
					$idxiCount=0;
					
				}
				else
				{
					# NO REDUNDANCY FOUND, dump original vector					
					$outputPattern[$c1]=$uniqueLine;
					$c1++;
					
					# reset the unique_vector
					$uniqueLine=$currentLine;
					$uniqueVector=$currentVector;
					$newPrefixLine='';
					
					# reset the count
					$repeatCount=1;		
					$idxiCount=0;			
				}
			}
		}
		else
		{
			# First Dump any repeating vectors if any, and then dump the line
			if ($repeatCount>1)		
			{
			
				# REDUNDANCY FOUND, dump IDXI vector
				##printLog(executionLogFH,"DEBUG: $repeat_count: REDUNDANCY FOUND, dump IDXI vector");
									
				$uniqueLine =~ /(.+)({ V { all_pins_norm = )(.*)(; } W .*)/;  # to include special case of EXIT tag on last vector
				my $prefixLine=$1;
				my $prefixVector=$2;
				my $vector=$3;
				my $postfix=$4;		
				$idxiCount=$repeatCount-1;				
				my $newPrefixLine='    IDXI '.$idxiCount.' '.$prefixVector.$vector.$postfix;
				
				# dump the vector
				$outputPattern[$c1]=$newPrefixLine;
				$c1++;
				
				# reset the vars to same as fresh start of pattern
				$uniqueVector='FIRST';
				$uniqueLine='';				
				$newPrefixLine='';
				
				# reset the count, as if start of pattern
				$repeatCount=0;
				$idxiCount=0;
				###}							
				
			}
			else
			{
				# insert the original line
				$outputPattern[$c1]=$line;
				$c1++;
			}
		}		
	}
		
	printLog(executionLogFH,"END: compressPatternIDXI() ");
    return \@outputPattern;
}
