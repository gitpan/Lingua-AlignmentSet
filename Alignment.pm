
########################################################################
# Author:  Patrik Lambert (lambert@talp.ucp.es)
#          Contributions from Adria de Gispert (agispert@gps.tsc.upc.es)
#						 and Josep Maria Crego (jmcrego@gps.tsc.upc.es)
# Description: Library of tools to process a set of links between the
#   words of two sentences.
#
#-----------------------------------------------------------------------
#
#  Copyright 2004 by Patrik Lambert
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
########################################################################

package Lingua::Alignment;

use strict;
use Lingua::AlignmentSlice;

#an alignment is a hash with 4 components:
#   {sourceAl} ref to source position array, each position containing the array of aligned target positions.
#              Each linked target token is indicated with the array: (position,S(sure)/P(possible),confidence score)
#   {targetAl} same as sourceAl but reversed
#	{sourceWords} and {targetWords}: array of corresponding words
#   {sourceLinks}: hash (indexed by the source token position $j and target $i in the link: {$j $i} of arrays giving
#	{targetLinks}: same as sourceLinks, for target alignment
#				  more information about the link: ( S(sure) or P(possible) , confidence )
sub new {
	my $pkg = shift;
    my $al = {};
    
	$al->{sourceAl}=[];
	$al->{targetAl}=[];
	$al->{sourceWords} = [];
	$al->{targetWords} = [];
	$al->{sourceLinks} = {};
	$al->{targetLinks} = {};
    return bless $al,$pkg;
}

sub loadFromGiza {
    my ($al,$alignmentString,$targetString,$reverseAlignmentString) = @_;   
    my ($i,$elem,$positionsString);

    #TARGET
	$targetString =~ s/^\s+|\s+$//g;	#trim
	$targetString =~ s/\s{2,}/ /g;	#remove multiple spaces

	if ($targetString !~ /^NULL/i){
	    $al->{targetWords}=["NULL"]; #we keep a place for the NULL word of the other direction
	}
    push @{$al->{targetWords}},split(/ /,$targetString);

    #SOURCE
    #array (source word,aligned target word positions-ex: (hola,'1 3',me,'2')):
    #  here you can't use a hash because you would loose the order
    my @correspondances = split /\(\{\s|\}\)\s/, $alignmentString;
    if (@correspondances % 2 == 1) {  #remove the posible useless last entry
		pop @correspondances;
    }
	
    $al->{sourceWords}=[];
    for ($i=0;$i<@correspondances;$i+=2) { 
		$elem = $correspondances[$i];
		$elem =~ s/^\s+|\s+$//g;
		$positionsString = $correspondances[$i+1];
		$positionsString =~ s/^\s+|\s+$//g; #trim
		$positionsString =~ s/\s{2,}/ /g;	#remove multiple spaces
		push @{$al->{sourceWords}},$elem;
		push @{$al->{sourceAl}}, [split / /,$positionsString];
    }

    #REVERSE ALIGNMENT
    if (length($reverseAlignmentString)>0){
		@correspondances = split /\(\{\s|\}\)\s/, $reverseAlignmentString;
		if (@correspondances % 2 == 1) {  #remove the posible useless last entry
	    	pop @correspondances;
		}
		for ($i=0;$i<@correspondances;$i+=2) { 
		    $positionsString = $correspondances[$i+1];
		   	$positionsString =~ s/^\s+|\s+$//g; #trim
			$positionsString =~ s/\s{2,}/ /g;	#remove multiple spaces
		    push @{$al->{targetAl}}, [split / /,$positionsString];
		}
    }
}

#input: $refToAlignedPairs_ts (target to source),$sourceSentence and $targetSentence are optional
sub loadFromBlinker{
	my ($al,$refToAlignedPairs_st,$refToAlignedPairs_ts,$sourceSentence,$targetSentence)=@_;
	my $i;
	my $pairStr;
	my @pair;
    my @pairs;

#LOAD SENTENCES (if applicable)
	if (defined($sourceSentence)){
		$sourceSentence =~ s/^\s+|\s+$//g; 	#trim
		$sourceSentence =~ s/\s{2,}/ /g;	#remove multiple space
				
		if ($sourceSentence !~ /^NULL/i){
			$al->{sourceWords}=["NULL"];
		}
		push @{$al->{sourceWords}},split(/ /,$sourceSentence);
	}
	if (defined($targetSentence)){
		$targetSentence =~ s/^\s+|\s+$//g;
		$targetSentence =~ s/\s{2,}/ /g;
		
		if ($targetSentence !~ /^NULL/i){
			$al->{targetWords}=["NULL"];
		}
		push @{$al->{targetWords}},split(/ /,$targetSentence);
	}
		
#LOAD SOURCE TO TARGET ALIGNMENT:
	#read alignment data
	foreach $pairStr (@$refToAlignedPairs_st){
		$pairStr =~ s/^\s+|\s+$//g;	#trim
		$pairStr =~ s/\s{2,}/ /g;	#remove multiple space		
		@pair = split / /,$pairStr;
		push @{$pairs[$pair[0]]},$pair[1];
		#load extra information (like S/P, confidence)
		if (@pair > 2){
			$al->{sourceLinks}->{$pair[0]." ".$pair[1]}=[splice(@pair,2)] ; 
		}
	}
	# take into account unaligned words to have no undef entry in array:
	# Since we really want to think in terms of alignment and not words, we don't base ourself on the number of words
	for ($i=0;$i<@pairs;$i++){
		if (defined($pairs[$i])){
			push @{$al->{sourceAl}},$pairs[$i];
		}else{
			push @{$al->{sourceAl}},[];	
		}
	}
#	print main::Dumper($refToAlignedPairs_st,$al->{sourceAl});

#LOAD TARGET TO SOURCE ALIGNMENT:
	if (defined($refToAlignedPairs_ts)){
		if (@$refToAlignedPairs_ts>0){
			@pairs=();
			#read alignment data
			foreach $pairStr (@$refToAlignedPairs_ts){
				$pairStr =~ s/^\s+|\s+$//g;	#trim
				$pairStr =~ s/\s{2,}/ /g;	#remove multiple space		
				@pair = split / /,$pairStr;
				push @{$pairs[$pair[0]]},$pair[1];
				#load extra information (like S/P, confidence)
				if (@pair > 2){
					$al->{targetLinks}->{$pair[0]." ".$pair[1]}=[splice(@pair,2)] ; 
				}
			}
			# take into account unaligned words to have no undef entry in array:
			for ($i=0;$i<@pairs;$i++){
				if (defined($pairs[$i])){
					push @{$al->{targetAl}},$pairs[$i];
				}else{
					push @{$al->{targetAl}},[];	
				}
			}
		}
	}
#	print main::Dumper($refToAlignedPairs_ts,$al->{targetAl});
}

# Remove links to NULL. 
# Note: to do this we need the alignment to be loaded so we do it in a separate function 
sub forceNoNullAlign {
	my $al = shift;
	my ($j,$i);
	my $continue;
	my $source;
	my @sides=("source","target");
	
	foreach $source (@sides){
		$al->{$source."Al"}[0]=[];
		for ($j=1;$j<@{$al->{$source."Al"}};$j++){
			if ($al->isIn($source."Al",$j,0)){
				$continue=1;
				for ($i=0;$i<@{$al->{$source."Al"}[$j]} && $continue;$i++){
					if ($al->{$source."Al"}[$j][$i]==0){
						splice(@{$al->{$source."Al"}[$j]}, $i, 1);
						$continue=0;
					}
				}
			}
		}
	}#foreach
}

# Link to NULL with a P (Possible) alignment all words that are not linked to anything
sub forceNullAlign {
	my $al = shift;
	my ($j,$i);
	my @reverseAl;
	my $source;
	my @sides=("source","target");

	foreach $source (@sides){
		@reverseAl = ();
		for ($j=1;$j<@{$al->{$source."Al"}};$j++){
			if (@{$al->{$source."Al"}[$j]}==0){
				push @{$al->{$source."Al"}[$j]},0;
				$al->{$source."Links"}->{"$j 0"}= ["P"];
			}else{
				foreach $i (@{$al->{$source."Al"}[$j]}){
					push @{$reverseAl[$i]},$j; 	
				}
			}
		}
		for ($i=1;$i<@reverseAl;$i++){
			if (!defined($reverseAl[$i]) || @{$reverseAl[$i]}==0){
				if (!$al->isIn($source."Al",0,$i)){
					push @{$al->{$source."Al"}[0]},$i;
					$al->{$source."Links"}->{"0 $i"}= ["P"];
				}
			}	
		}
	}#foreach
}

sub writeToBlinker{
	my $al = shift;
	my $side = shift; #optional; default:"source";
	if (!defined($side)){$side="source"}
	my @lines = ();
	my ($i,$j);

	for ($j=0;$j<@{$al->{$side."Al"}};$j++){
		foreach $i (@{$al->{$side."Al"}[$j]}){
			if (${$al->{$side."Links"}}{"$j $i"}){
				push @lines,"$j $i ".join(" ",@{$al->{$side."Links"}{"$j $i"}});
			}else{
				push @lines,"$j $i";	
			}
		}
	}		
	return \@lines;
}

sub displayAsLinkEnumeration{
	my ($al,$format,$latex) = @_;
	my $lines="";
	
	
	if ($format eq "text"){
		my ($correspPosition,$wordPosition);
	
		$lines.= join(" ",@{$al->{sourceWords}})."\n"; 
		$lines.= join(" ",@{$al->{targetWords}})."\n\n"; 

		for ($wordPosition=0;$wordPosition<@{$al->{sourceWords}};$wordPosition++){
			$lines.= @{$al->{sourceWords}}[$wordPosition]." <- ";
			foreach $correspPosition (@{$al->{sourceAl}[$wordPosition]}){
				$lines.= $al->{targetWords}[$correspPosition]." ";
			}
			$lines.= "\n";
		}
		$lines.="\n\n";			
	}elsif ($format eq "latex"){
	    my $numRowTokens = @{$al->{sourceWords}};
	    my $numColTokens = @{$al->{targetWords}};
	    my ($i,$j,$elt);
	    my ($j_partOf_Bi,$i_partOf_Bj);
		my ($targetWord,$sourceWord);
	
		$lines.= $latex->fromText("\n".join(" ",@{$al->{sourceWords}})."\n"); 
		$lines.= $latex->fromText(join(" ",@{$al->{targetWords}})."\n\n").'\vspace{5mm}'."\n"; 
		
		for ($j=0; $j<$numRowTokens;$j++){
		    for ($i=0;$i<$numColTokens;$i++){
				$targetWord = $latex->fromText($al->{targetWords}[$i]);
				$sourceWord = $latex->fromText($al->{sourceWords}[$j]);
				$i_partOf_Bj = $al->isIn("sourceAl",$j,$i);
				$j_partOf_Bi = $al->isIn("targetAl",$i,$j);
				if ($i_partOf_Bj > 0) {    #ie i=aj
				    if ($j_partOf_Bi > 0){ 
						$lines.= $sourceWord.' \boldmath $\leftrightarrow$ '.$targetWord." \n\n";
				    }else{		  
						$lines.= $sourceWord.' \boldmath $\leftarrow$ '.$targetWord." \n\n";
				    }
				}else{
				    if ($j_partOf_Bi > 0){
						$lines.= $sourceWord.' \boldmath $\rightarrow$ '.$targetWord." \n\n";
				    }else{
				    }
				} 
		    }
		}
		$lines.= "\n\n".'\vspace{7mm}';
	} #elsif $format eq latex	
	return $lines;
}

sub displayAsMatrix {
    my ($al,$latex,$mark,$maxRows,$maxCols)= @_;
    my $matrix = "";
	my ($mark_ji,$mark_ij);
	my $mark_ji_cross='\boldmath $-$';
    my $numRowTokens = @{$al->{sourceWords}};
    my $numColTokens = @{$al->{targetWords}};
    my ($i,$j,$elt);
    my ($j_partOf_Bi,$i_partOf_Bj);
    my $offset;

	if ($numRowTokens>$maxRows){return $al->displayAsLinkEnumeration("latex",$latex)}

	$matrix.= $latex->fromText("\n".join(" ",@{$al->{sourceWords}})."\n"); 
	$matrix.= $latex->fromText(join(" ",@{$al->{targetWords}})."\n\n").'\vspace{5mm}'; 	

    for ($offset=0;$offset<$numColTokens;$offset+=$maxCols){
	$matrix.= "\n".'\begin{tabular}{l'."c" x $numColTokens.'}';
	for ($j=$numRowTokens-1;$j>=0;$j--){
	    $matrix.= "\n".$latex->fromText($al->{sourceWords}[$j]);
	    for ($i=$offset;$i<$numColTokens && $i<($offset+$maxCols);$i++){
			$i_partOf_Bj = $al->isIn("sourceAl",$j,$i);
			$j_partOf_Bi = $al->isIn("targetAl",$i,$j);
			if ($mark eq "cross"){$mark_ji=$mark_ji_cross}
			elsif ($mark eq "ambiguity"){
				if (length($al->{sourceLinks}->{"$j $i"}[0])>0){$mark_ji=$al->{sourceLinks}->{"$j $i"}[0]}
				else {$mark_ji = $mark_ji_cross}
			}	
			elsif ($mark eq "confidence"){
				if (length($al->{sourceLinks}->{"$j $i"}[1])>0){$mark_ji=$al->{sourceLinks}->{"$j $i"}[1]}
				else {$mark_ji = $mark_ji_cross}
			}
			else {$mark_ji = $mark}
			if ($mark eq "ambiguity"){
				if (length($al->{targetLinks}->{"$i $j"}[0])>0){$mark_ij='\ver{'.$al->{targetLinks}->{"$i $j"}[0].'}'}
				else {$mark_ij = '\ver{'.$mark_ji_cross.'}'}
			}elsif ($mark eq "confidence"){
				if (length($al->{targetLinks}->{"$i $j"}[1])>0){$mark_ij='\ver{'.$al->{targetLinks}->{"$i $j"}[1].'}'}
				else {$mark_ij = '\ver{'.$mark_ji_cross.'}'}
			}else{$mark_ij = '\ver{'.$mark_ji.'}'}
			
			$matrix.= "&";
			if ($i_partOf_Bj > 0) {    #ie i=aj
			    if ($j_partOf_Bi > 0){ 
			    	if ($mark_ji eq '\boldmath $-$' && $mark_ij eq '\ver{\boldmath $-$}'){
						$matrix.= ' \boldmath ${+}$ ';
			    	}else{
			    		$matrix.= " $mark_ji$mark_ij ";
			    	}
				}else{		  
					$matrix.= " $mark_ji ";
				}
			}else{
			    if ($j_partOf_Bi > 0){
					$matrix.= " $mark_ij ";
				}else{
					$matrix.= ' . ';					
			    }
			}
	    } #for j=...
	    $matrix.= ' \\\\';
	}	#for i=...
	# last line
	$matrix.= "\n ";
	for ($i=$offset;$i<$numColTokens && $i<($offset+$maxCols);$i++){
	    $matrix.= ' & '.'\ver{'.$latex->fromText($al->{targetWords}[$i]).'}';
	}
	$matrix.= ' \\\\';
	$matrix.= "\n".'\end{tabular}'."\n\n".'\vspace{7mm}';
    } # loop on number of matrices
    
    return $matrix;
}

# prohibits situations of the type: if linked(e,f) and linked(e',f) and linked(e',f') but not linked(e,f')
# in this case the function links e and f'.
sub forceGroupConsistency {
	my $al = shift;
	my ($i,$j);
	my %groupi=();
	my %groupj=();
	my $currentGroup;
	my @groups=();
	my $source;	
	my @sides=("source","target");

	foreach $source (@sides){
		#first we divide the alignment in clusters of positions linked between each other
		for ($j=1;$j<@{$al->{$source."Al"}};$j++){
			if (defined($al->{$source."Al"}[$j])){
				foreach $i (@{$al->{$source."Al"}[$j]}){
					if ($i>0){
						if ($groupj{$j} && $groupi{$i}){
							if ($groupi{$i}!= $groupj{$j}){
								#merge groups						
								my ($mergedGroup,$deletedGroup) = ($groupj{$j},$groupi{$i});
								push @{$groups[$mergedGroup][0]},@{$groups[$deletedGroup][0]};
								push @{$groups[$mergedGroup][1]},@{$groups[$deletedGroup][1]};
								my $k;
								foreach $k (@{$groups[$deletedGroup][0]}){
									$groupj{$k}=$mergedGroup;	
								}
								foreach $k (@{$groups[$deletedGroup][1]}){
									$groupi{$k}=$mergedGroup;	
								}
								$groups[$deletedGroup]=[];
							}
						}else{
							if ($groupj{$j}){
								$currentGroup = $groupj{$j};
								if (!$groupi{$i}){
									push @{$groups[$currentGroup][1]},$i;
									$groupi{$i}=$currentGroup;	
								}				
							}elsif ($groupi{$i}){
								$currentGroup = $groupi{$i};					
								if (!$groupj{$j}){
									push @{$groups[$currentGroup][0]},$j;	
									$groupj{$j}=$currentGroup;	
								}				
							}else{
								#create a new group	
								$currentGroup = scalar(@groups);
								push @{$groups[$currentGroup][0]},$j;	
								$groupj{$j}=$currentGroup;	
								push @{$groups[$currentGroup][1]},$i;	
								$groupi{$i}=$currentGroup;	
							}
						}
					} # $i>0
				}# foreach
			} 	
		}
		#then we check that all the links within each cluster exist, and create them if they don't
		my $g;
		for ($g=0;$g<@groups;$g++){
			foreach $j (@{$groups[$g]->[0]}){
				foreach $i (@{$groups[$g]->[1]}){
					if (!$al->isIn($source."Al",$j,$i)){
						push @{$al->{$source."Al"}[$j]},$i;	
					}	
				}	
			}
		}
	} #foreach $side
}

#####################################################
### SYMMETRIZATION SUBS                           ###
#####################################################                        
# input: alignment object
# output: intersection of source and target alignments of this object
sub intersect {
	my $al = shift;
	my $intersectSourceAl=[];
	my $intersectTargetAl=[];
	my ($i,$j,$ind);

	if (@{$al->{targetAl}}>0 && @{$al->{sourceAl}}>0){
		#for each link in sourceAl, look if it's present in targetAl
		for ($j=0;$j<@{$al->{sourceAl}};$j++){
			if (defined($al->{sourceAl}[$j])){
				foreach $i (@{$al->{sourceAl}[$j]}){
					if ($al->isIn("targetAl",$i,$j)){
						push @{$intersectSourceAl->[$j]},$i;
						push @{$intersectTargetAl->[$i]},$j;
					}	
				}	
			} #if defined
		}
	} #if targetAl is an empty array, then from the intersection sourceAl remains empty
	@{$al->{sourceAl}}=@{$intersectSourceAl};
	@{$al->{targetAl}}=@{$intersectTargetAl};
}

# input: alignment object
# output: union of source and target alignments of this object
sub getUnion {
	my $al=shift;
	my %union;
	$union{sourceAl}=[];
	$union{targetAl}=[];
	my ($j,$i,$ind);
	my %side=("source"=>"target","target"=>"source");
	my ($source,$target);
	
	if (@{$al->{targetAl}}>0 && @{$al->{sourceAl}}>0){
		while (($source,$target)= each(%side)){
			for ($j=0;$j<@{$al->{$source."Al"}};$j++){
				if (defined($al->{$source."Al"}[$j])){
					foreach $i (@{$al->{$source."Al"}[$j]}){
							push @{$union{$source."Al"}->[$j]},$i;
							if (!$al->isIn($target."Al",$i,$j)){
								push @{$union{$target."Al"}->[$i]},$j;
							}	
					} #foreach
				} 			
			} #for
		}
	}elsif (@{$al->{sourceAl}}>0){
		@{$union{sourceAl}}=@{$al->{sourceAl}};	
	}else{
		@{$union{targetAl}}=@{$al->{targetAl}};	
	}
	@{$al->{sourceAl}}=@{$union{sourceAl}};
	@{$al->{targetAl}}=@{$union{targetAl}};
}

# input: alignment object
# output: this object where only the links of the side (source or target) with most links are selected
sub selectSideWithLinks{
	my ($al,$criterion,$dontCountNull)=@_;
	#defaults
	if (!defined($criterion)){$criterion="most"}
	if (!defined($dontCountNull)){$dontCountNull=1}
	my ($j,$i,$firstInd);
	my ($numSource,$numTarget)=(0,0);
	my $sourceAl=[];
	my $targetAl=[];
	
	if ($dontCountNull){$firstInd=1}
	else {$firstInd=0}
	#count links
	for ($j=$firstInd;$j<@{$al->{sourceAl}};$j++){
		if (defined($al->{sourceAl}[$j])){
			if (!$dontCountNull){
				$numSource+=@{$al->{sourceAl}[$j]};
			}else{
				foreach $i (@{$al->{sourceAl}[$j]}){
					if ($i!=0){$numSource++}	
				}
			}
		} 			
	} 
	for ($i=$firstInd;$i<@{$al->{targetAl}};$i++){
		if (defined($al->{targetAl}[$i])){
			if (!$dontCountNull){
				$numTarget+=@{$al->{targetAl}[$i]};
			}else{
				foreach $j (@{$al->{targetAl}[$i]}){
					if ($j!=0){$numTarget++}	
				}
			}
		} 			
	}
	#select side with (most,least) links
	if ( ($numSource>=$numTarget && $criterion eq "most") || ($numSource<$numTarget && $criterion ne "most")){ #select sourceAl
		for ($j=0;$j<@{$al->{sourceAl}};$j++){
			if (defined($al->{sourceAl}[$j])){
				foreach $i (@{$al->{sourceAl}[$j]}){
					push @{$sourceAl->[$j]},$i;
					push @{$targetAl->[$i]},$j;
				}
			} 			
		} 		
	}else{	#select targetAl
		for ($i=0;$i<@{$al->{targetAl}};$i++){
			if (defined($al->{targetAl}[$i])){
				foreach $j (@{$al->{targetAl}[$i]}){
					push @{$sourceAl->[$j]},$i;
					push @{$targetAl->[$i]},$j;
				}
			} 			
		}
	}
	@{$al->{sourceAl}}=@$sourceAl;
	@{$al->{targetAl}}=@$targetAl;
}

sub selectSideWithMostLinks{
	my $al=shift;
	return $al->selectSideWithLinks("most");	
}
sub selectSideWithLeastLinks{
	my $al=shift;
	return $al->selectSideWithLinks("least");	
}

# input: alignment object
# output: alignment object where source and target have been swapped
sub swapSourceTarget{
	my $al=shift;
	my ($link,$ref,$j,$i,$source);
	my @st;
	my @sides=("source","target");
	my $swappedAl={ "sourceAl"=>[],
					"targetAl"=>[],
					"sourceWords"=>$al->{targetWords},
					"targetWords"=>$al->{sourceWords},
					"sourceLinks"=>{},
					"targetLinks"=>{}};
	
	foreach $source (@sides){
		for ($j=0;$j<@{$al->{$source."Al"}};$j++){
			foreach $i (@{$al->{$source."Al"}[$j]}){
				push @{$swappedAl->{$source."Al"}[$i]},$j;	
			}
		}
		#insert ref to empty array instead of undef entries
		for ($j=0;$j<@{$swappedAl->{$source."Al"}};$j++){
			if (!defined($swappedAl->{$source."Al"}[$j])){
				$swappedAl->{$source."Al"}[$j]=[];
			}	
		}
		# and now the sourceLinks
		while (($link,$ref)=each(%{$al->{$source."Links"}})){
			@st=split(" ",$link);
			$swappedAl->{$source."Links"}{"$st[1] $st[0]"}=$ref;	
		}
	}
	%$al=%$swappedAl;
}

# eliminates any given WORD from the source or target file corpus and updates the alignment
# input: $al (current Alignment object),$word (word RegExp to eliminate), $wordSide (from which side: source or target)
#
# This is the adaptation of code from Adria de Gispert (agispert@gps.tsc.upc.es) and Josep Maria Crego (jmcrego@gps.tsc.upc.es)
sub eliminateWord {
	my ($al,$word,$wordSide)= @_;
	#my $word = escapeRegExp($word);
	$wordSide = lc $wordSide;
	my ($j,$i,$k,$line);
	my $source;
	my @sides=("source","target");
	my @links;
	my @src;
	my @trg;
	my @p;
	my @pairs;
	my @pair;
	my @words;
	if ( grep(/^$word$/, @{$al->{$wordSide."Words"}}) ){	# the word is in the sentence
		foreach $source (@sides){
			@words = @{$al->{$wordSide."Words"}};
			#read alignment in blinker format
	 		@links = $al->writeToBlinker($source);
			$#src=-1;
			$#trg=-1;
			$#p=-1;
			foreach $line (@{$links[0]}){
				    ($src[$#src+1],$trg[$#trg+1],@{$p[$#p+1]}) = split(" ",$line);
			}
			#update alignment
			if ($wordSide ne $source){## target
			    for ($j=0;$j<=$#words;$j++){
					if ($words[$j] =~ /^$word$/){ ### must eliminate link $j
					    for ($k=0;$k<=$#trg;$k++){
							$trg[$k]=-1 if ($trg[$k]==$j);
							$trg[$k]-- if ($trg[$k]>$j);
					    }
					    splice @words,$j,1;
					    $j--;
					}
			    }
			}else{## source
			    for ($j=0;$j<=$#words;$j++){
					if ($words[$j] =~ /^$word$/){ ### must eliminate link $j
					    for ($k=0;$k<=$#src;$k++){
							$src[$k]=-1 if ($src[$k]==$j);
							$src[$k]-- if ($src[$k]>$j);
					    }
					    splice (@words,$j,1);
					    $j--
					}
			    }
			}
			################## load updated alignment
			@{$al->{$source."Al"}}=();
			%{$al->{$source."Links"}}=();			
			@pairs =();
			for ($j=0;$j<=$#trg;$j++){
				if ($trg[$j]!=-1 && $src[$j]!=-1){
					@pair = ($src[$j],$trg[$j]);
					push @{$pairs[$pair[0]]},$pair[1];
					#load extra information (like S/P, confidence)
					if( @{$p[$j]} > 0){
						$al->{$source."Links"}->{$pair[0]." ".$pair[1]}=$p[$j]; 
					}
				}
			}
			# take into account unaligned words to have no undef entry in array:
			for ($j=0;$j<@pairs;$j++){
				if (defined($pairs[$j])){
					push @{$al->{$source."Al"}},$pairs[$j];
				}else{
					push @{$al->{$source."Al"}},[];	
				}
			}
		} # foreach side
		@{$al->{$wordSide."Words"}}=@words;
		
	} #if word in the sentence	
}

#input: (source,target) link
#output: true if the link is reciprocal (or "cross link"), false otherwise
sub isCrossLink {
	my ($al,$j,$i)=@_;
#	print "s $j $i:",$al->isIn("sourceAl",$j,$i)," t $i $j:",$al->isIn("targetAl",$i,$j),"\n";
	return ( $al->isIn("sourceAl",$j,$i) && $al->isIn("targetAl",$i,$j) );	
}

sub isAnchor{
	my ($al,$j,$side)=@_;
	my ($reverseSide,$i);

	if ($side eq "source"){$reverseSide="target"}
	else {$reverseSide = "source"}
	if (defined($al->{$side."Al"}[$j])){
		if (@{$al->{$side."Al"}[$j]}==1){
			$i = $al->{$side."Al"}[$j][0];
			if (defined($al->{$reverseSide."Al"}[$i])){
				if (@{$al->{$reverseSide."Al"}[$i]}==1 && $al->{$reverseSide."Al"}[$i][0]==$j){
					return 1;
				}
			}
		}
	}
	return 0;
}

#mode: 	"noAnchors" cuts zones between 2 anchors and cannot include an anchor point
#		"anchors" cuts zone established by coordinates and doesn't look more
sub cut {
	my ($al,$startPointSource,$startPointTarget,$endPointSource,$endPointTarget,$mode)=@_;
	if (!defined($mode)){$mode="noAnchors"} 
	my ($j,$i,$ind);
	my %sourceInGap=();
	my %targetInGap=();
	my @sortedSourceInGap=();
	my @sortedTargetInGap=();
	my %sourceToNull=();
	my %targetToNull=();
	my $gap = Lingua::AlignmentSlice->new($al);
	my @linked=();
	my ($zeroSource,$zeroTarget,$numSource,$numTarget);
	my ($oldNumInGap,$newNumInGap);
	for ($j=$startPointSource+1;$j<$endPointSource;$j++){
		$sourceInGap{$j}=1;
	}
	for ($i=$startPointTarget+1;$i<$endPointTarget;$i++){
		if ($mode eq "noAnchors"){
			if (!$al->isAnchor($i,"target")){
				$targetInGap{$i}=1;	
			}
		}else{
			$targetInGap{$i}=1;	
		}
	}
#	print "\n($startPointSource,$startPointTarget,$endPointSource,$endPointTarget)\n";
#	print "source in gap 1:".join(" ",keys %sourceInGap)."\n";
#	print "target in gap 1:".join(" ",keys %targetInGap)."\n";
	
	#look at linked words situated outside the gap square:	
	$oldNumInGap=0;
	$newNumInGap=scalar(keys %sourceInGap)+scalar(keys %targetInGap);
	while ($oldNumInGap != $newNumInGap){
		foreach $i (keys %targetInGap){
			foreach $j (@{$al->{targetAl}[$i]}){
				if ($j!=0){
					$sourceInGap{$j}=1;
				}
				else {$targetToNull{$i}=1};	
			}
			for ($j=1;$j<@{$al->{sourceAl}};$j++){
				if 	($al->isIn("sourceAl",$j,$i)){
					$sourceInGap{$j}=1;
				}
			}
		}
		foreach $j (keys %sourceInGap){
			foreach $i (@{$al->{sourceAl}[$j]}){
				if ($i!=0){
					$targetInGap{$i}=1;
				}
				else {$sourceToNull{$j}=1};	
			}
			for ($i=1;$i<@{$al->{targetAl}};$i++){
				if 	($al->isIn("targetAl",$i,$j)){
					$targetInGap{$i}=1;
				}
			}
		}
		$oldNumInGap=$newNumInGap;
		$newNumInGap=scalar(keys %sourceInGap)+scalar(keys %targetInGap);
	}
	foreach $i (@{$al->{sourceAl}[0]}){
		if ($targetInGap{$i}){$targetToNull{$i}=1}
	}
	foreach $j (@{$al->{targetAl}[0]}){
		if ($sourceInGap{$j}){$sourceToNull{$j}=1}
	}

	@sortedSourceInGap = sort { $a <=> $b; } keys %sourceInGap;
	@sortedTargetInGap = sort { $a <=> $b; } keys %targetInGap;

#	print "source in gap 2:",join(" ",keys %sourceInGap)."\n";
#	print "target in gap 2:",join(" ",keys %targetInGap)."\n";
#	print "source sorted:",join(" ",@sortedSourceInGap)."\n";
#	print "target sorted:",join(" ",@sortedTargetInGap)."\n";
#	print "target to null:",join(" ",keys %targetToNull)."\n";
#	print "source to null:",join(" ",keys %sourceToNull)."\n";

	if (@sortedSourceInGap==0){
		$zeroSource=0;
		$numSource=0;
	}else{
		$zeroSource=$sortedSourceInGap[0]-1;
		$numSource=$sortedSourceInGap[@sortedSourceInGap-1]-$sortedSourceInGap[0]+1;
	}
	if (@sortedTargetInGap==0){
		$zeroTarget=0;
		$numTarget=0;
	}else{
		$zeroTarget=$sortedTargetInGap[0]-1;
		$numTarget=$sortedTargetInGap[@sortedTargetInGap-1]-$sortedTargetInGap[0]+1;
	}
	
	#Actualize AlignmentSlice attributes
	$gap->setZero($zeroSource,$zeroTarget);
	foreach $j (keys %sourceInGap){
		$gap->{sourceIndices}{$j-$zeroSource}=1;
	}
	if (scalar (keys %targetToNull)>0){$gap->{sourceIndices}{0}=1};	
	foreach $i (keys %targetInGap){
		$gap->{targetIndices}{$i-$zeroTarget}=1;	
	}
	if (scalar (keys %sourceToNull)>0){$gap->{targetIndices}{0}=1};	
	
#	print "zero s t:",$zeroSource," ",$zeroTarget,"\n";
#	print "num s t:",$numSource," ",$numTarget,"\n";

	## LOAD GAP
	# 1. insert NULL word and select only words linked to NULL that belong to the gap
	push @{$gap->{sourceWords}},'NULL';
	foreach $i (keys %targetToNull){push @linked,$i-$gap->{zeroTarget}}
	push @{$gap->{sourceAl}},[@linked];
	push @{$gap->{targetWords}},'NULL';
	@linked=();
	foreach $j (keys %sourceToNull){push @linked,$j-$gap->{zeroSource}}
	push @{$gap->{targetAl}},[@linked];
	# 2. Add non-NULL words and alignments
	for ($ind=1;$ind<=$numSource;$ind++){
		$j=$ind+$gap->{zeroSource};
		$gap->{sourceWords}[$ind]=$al->{sourceWords}[$j];
		if ($sourceInGap{$j}){
			@linked=();
			foreach $i (@{$al->{sourceAl}[$j]}){
				#if ($targetInGap{$i}){		#useless:de facto included in the zone
					push @linked,$i-$gap->{zeroTarget}
				#}
			}
			$gap->{sourceAl}[$ind]=[@linked];
		}
	}
	for ($ind=1;$ind<=$numTarget;$ind++){
		$i = $ind+$gap->{zeroTarget};
		$gap->{targetWords}[$ind]=$al->{targetWords}[$i];
		if ($targetInGap{$i}){
			@linked=();
			foreach $j (@{$al->{targetAl}[$i]}){
				#if ($sourceInGap{$j}) {	#useless:de facto included in the zone
					push @linked,$j-$gap->{zeroSource}
				#}
			}
			$gap->{targetAl}[$ind]=[@linked];
		}
	}
	return $gap;		
}

#####################################################
### PRIVATE SUBS                                  ###
#####################################################

# TargetSentence: returns the target sentence tokens (separated by " "), by parsing the alignment object
sub targetSentence {
	my $al = shift;

	return join " ",@{$al->{targetWords}};
}

# Returns the number of times the link ($ind1,$ind2) is present in the $side alignment
sub isIn {
	my ($al,$side,$ind1,$ind2) = @_;
	if ($side eq "sourceAl"){
		# returns >0 if the link (j,i) is present in sourceAl (ie if i_partOf_Bj), 0 otherwise
		my ($j,$i) = ($ind1,$ind2);
		my $i_partOf_Bj=grep /^$i$/, @{$al->{sourceAl}[$j]};
		return $i_partOf_Bj;
	}else{
		# returns >0 if the link (i,j) is present in targetAl (ie if j_partOf_Bi), 0 otherwise
		my ($i,$j)=($ind1,$ind2);
		my $j_partOf_Bi = grep /^$j$/, @{$al->{targetAl}[$i]};
		return $j_partOf_Bi;	
	}
}

# returns an object with same content as the input object
sub clone {
	my $al = shift;
	my $clone = Lingua::Alignment->new;	
	my ($i,$j);
	@{$clone->{sourceWords}}=@{$al->{sourceWords}};
	@{$clone->{targetWords}}=@{$al->{targetWords}};
	for ($j=0;$j<@{$al->{sourceAl}};$j++){
		if (defined($al->{sourceAl}[$j])){
			push @{$clone->{sourceAl}},[@{$al->{sourceAl}[$j]}];
		}
	}
	for ($i=0;$i<@{$al->{targetAl}};$i++){
		if (defined($al->{targetAl}[$i])){
			push @{$clone->{targetAl}},[@{$al->{targetAl}[$i]}];
		}
	}
	%{$clone->{sourceLinks}}=%{$al->{sourceLinks}};
	%{$clone->{targetLinks}}=%{$al->{targetLinks}};

	return $clone;
}
sub clear {
	my $al = shift;
	my ($i,$j);
	for ($j=0;$j<@{$al->{sourceAl}};$j++){
		if (defined($al->{sourceAl}[$j])){
			@{$al->{sourceAl}[$j]} = ();
		}
	}
	for ($i=0;$i<@{$al->{targetAl}};$i++){
		if (defined($al->{targetAl}[$i])){
			@{$al->{targetAl}[$i]} = ();
		}
	}
	%{$al->{sourceLinks}} = ();
	%{$al->{targetLinks}} = ();
}

sub escapeRegExp {
	my $line = shift;
	# regExp characters to escape: \ | ( ) [  {  ^ $ * + ? .
    $line =~ s/\\/\\\\/g;
    $line =~ s/\|/\\\|/g;
    $line =~ s/\(/\\\(/g;
    $line =~ s/\)/\\\)/g;
    $line =~ s/\[/\\\[/g;
    $line =~ s/\{/\\\}/g;
    $line =~ s/\^/\\\^/g;
    $line =~ s/\$/\\\$/g;
    $line =~ s/\*/\\\*/g;
    $line =~ s/\+/\\\+/g;
    $line =~ s/\?/\\\?/g;
    $line =~ s/\./\\\./g;
    return $line;
}

1;
