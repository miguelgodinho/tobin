package Visual::DotGen;

use strict;
use warnings;

sub new {
	my $param	= shift;
	my $self 	= shift;
	my $class 	= ref( $param ) || $param;
	bless( $self, $class );
	$self->{TOBIN}	|| die();
	return $self;
}

sub createDot {
	
	my $self		= shift;
	my $data		= shift; #matrix
	my $filename	= shift;
	my $ExpData		= shift;
	my $flags_in	= shift;
	
	my %flags;
	
	foreach ( @{$flags_in} ) {
		( $_ eq 'SHOWFBA' ) ||
		$self->suicide( "$_ is unkown flag" );
		$flags{"$_"} = 1;
	}
#	warn $CentralTf;
#	print($ExpLevel."\n");
	if( defined($ExpData->[0])&&!defined($ExpData->[1])) {
		$self->suicide("No expansion center given.");
	}
	else {
		if($ExpData->[0] eq 'c') {
			if(!defined($ExpData->[2])) {
				$self->suicide("No compartment of compound being expansion centre given.");
			}
			else {
				if(!defined($ExpData->[3])) {
					push(@{$ExpData},0);
				}
			}
		}
		elsif($ExpData->[0] eq 't') {
			if(!defined($ExpData->[2])) {
				push(@{$ExpData},0);
			}
		}
		else {
			$self->suicide("Unknown expansion center type.");
		}
	} 

	my $tobin=$self->{TOBIN};
	my $CCode="c";
	my $RCode="r";
	my $CSep="-";
	my $RRCode="revr";
	my $RRSep="+";
	my $URLString="";
	my $URLc="t_c";
	my $URLt="t";
	my $FluxSep="";
	my $CompSep="";
	my $currentTransformation = 0;
#	foreach ( @{$data} ) {
#		if ( $currentTransformation != $_->[0] ) {
#			$currentTransformation = $_->[0];
#			print "TRANSFORMATION: " . $self->{TOBIN}->transformationNameGet( $currentTransformation ) . "\n";
#		}
#		print "@{$_}" . " : " . $self->{TOBIN}->compoundNameGet( $_->[1] ) . "\n";
#	}
	$currentTransformation=$data->[0]->[0];
	my %reabeg=($currentTransformation => 0);
	for(my $i=0;$i<@{$data};$i++) {
		if($currentTransformation!= $data->[$i]->[0]){
			$reabeg{$data->[$i]->[0]}=$i;
			$currentTransformation=$data->[$i]->[0];
		}
	}
	my $data1 = [];
	my $EdgeSubs = [{},{}];
	my $SubsMap = [{},{}];
	my $ReactMap = {};
	my $ReactMapTmp = {};
	my $ExpLevel;
	if(defined($ExpData->[0])) {
		if($ExpData->[0] eq 'c') {
#			warn "@{$ExpData}";
			foreach(@{$data}) {
				if(!defined($ReactMap->{$_->[0]})&&$_->[1]==$ExpData->[1]&&$_->[2]==$ExpData->[2]) {
					$ReactMap->{$_->[0]}=1;
					$ReactMapTmp->{$_->[0]}=1;
				}
			}
			if(!%{$ReactMap}) {
				$self->suicide("Given centrtal compound doesn't exist in the dataset");
			}
			$ExpLevel=$ExpData->[3];
		}
		else {
			if(!defined($reabeg{$ExpData->[1]})) {
				$self->suicide( "Central transformation: ".$ExpData->[1]." doesn't exist in the set! \n" );
			}
			$ReactMap->{$ExpData->[1]}=1;
			$ReactMapTmp->{$ExpData->[1]}=1;
			$ExpLevel=$ExpData->[2];
		}
		
		for(my $i=0;$i<$ExpLevel;$i++) {
			$SubsMap = [{},{}];
			foreach(keys(%{$ReactMapTmp})) {
				for(my $j=$reabeg{$_};$j<@{$data}&&$data->[$j]->[0]==$_;$j++) {
					if(!defined($SubsMap->[$data->[$j]->[2]]->{$data->[$j]->[1]}) ) {
						$SubsMap->[$data->[$j]->[2]]->{$data->[$j]->[1]}=1;
					}
				}
			}
			$ReactMapTmp={};
			for(my $j=0;$j<@{$data};$j++) {
				if(!defined($ReactMap->{$data->[$j]->[0]})&&defined($SubsMap->[$data->[$j]->[2]]->{$data->[$j]->[1]})) {
					$ReactMap->{$data->[$j]->[0]}=1;
					$ReactMapTmp->{$data->[$j]->[0]}=1;
				}
			}	
		}
		$SubsMap = [{},{}];
		foreach(keys(%{$ReactMap})) {
			for(my $i=$reabeg{$_};$i<@{$data}&&$data->[$i]->[0]==$_;$i++) {
				push(@{$data1},$data->[$i]);
				if(!defined($SubsMap->[$data->[$i]->[2]]->{$data->[$i]->[1]})){
					$SubsMap->[$data->[$i]->[2]]->{$data->[$i]->[1]}=1;
				}
			}
		}
		for(my $i=0;$i<@{$data};$i++) {
			if(!defined($EdgeSubs->[$data->[$i]->[2]]->{$data->[$i]->[1]})&&
			defined($SubsMap->[$data->[$i]->[2]]->{$data->[$i]->[1]})&&
			!defined($ReactMap->{$data->[$i]->[0]})) {
				$EdgeSubs->[$data->[$i]->[2]]->{$data->[$i]->[1]}=1;
			}
		}
		@{$data}=sort({$a->[0]<=>$b->[0]} @{$data1});
	}
	$currentTransformation=$data->[0]->[0];
	my $realist = [];
	my $reamap = {};
	my $elementlist = [];
	my $tempvec =[];
	for(my $i=0;$i<@{$data};$i++) {
		if($currentTransformation!= $data->[$i]->[0]){
			push(@{$realist},$currentTransformation);
			$reamap->{$currentTransformation}=@{$realist}-1;
			$currentTransformation=$data->[$i]->[0];
			push(@{$elementlist},[sort({$a->[0]<=>$b->[0]} @{$tempvec})]);
			$tempvec =[];
		}
		push(@{$tempvec},[$data->[$i]->[1],$data->[$i]->[2],$data->[$i]->[3]]);
	}
	push(@{$realist},$currentTransformation);
	$reamap->{$currentTransformation}=@{$realist}-1;
	push(@{$elementlist},[sort({$a->[0]<=>$b->[0]} @{$tempvec})]);
	my @tempvec;
	my $revreact=[];
	$#tempvec=@{$elementlist}-1;
	for(my $i=0;$i<@{$elementlist};$i++){
		if(!defined($tempvec[$i])) {
			$tempvec[$i]=0;
			my $tempvec1=[$realist->[$i]];
			for(my $j=$i+1;$j<@{$elementlist};$j++) {
				if(!defined($tempvec[$j])&&@{$elementlist->[$i]}==@{$elementlist->[$j]}) {
					my $test=1;
					my $k=0;
					while($test&&$k<@{$elementlist->[$i]}) {
						if($elementlist->[$i]->[$k]->[0]!=$elementlist->[$j]->[$k]->[0]||
						$elementlist->[$i]->[$k]->[1]!=$elementlist->[$j]->[$k]->[1]||
						$elementlist->[$i]->[$k]->[2]!=-$elementlist->[$j]->[$k++]->[2]) {
							$test=0;
						}
					}
					if($test) {
						push(@{$tempvec1},$realist->[$j]);
					}

				}
			}
			if(@{$tempvec1}==2) {
				push(@{$revreact},$tempvec1);
			}
			elsif(@{$tempvec1}>2) {
				print("Error: duplicate reactions\n");
			}
		}
	}
	my %revreactlist;
	for(my $i=0;$i<@{$revreact};$i++) {
		(my $tempstr=$tobin->transformationNameGet($revreact->[$i]->[0]))=~s/"/\\\"/g;
		# "
		$revreactlist{$revreact->[$i]->[0]}=[$i,$tempstr];
		($tempstr=$tobin->transformationNameGet($revreact->[$i]->[1]))=~s/"/\\\"/g;
		# "
		$revreactlist{$revreact->[$i]->[1]}=[$i,$tempstr];
	}
	my $CompoundLists=[];
	push(@{$CompoundLists},{});
	push(@{$CompoundLists},{});
	my $MultipleCompartment =[];
	my %CompoundList;
	my @CompartmentNames=("(in)","(ex)");
	for(my $i=0;$i<@{$data};$i++) {
		if(!defined($CompoundList{$data->[$i]->[1]})) {
			$CompoundList{$data->[$i]->[1]}=1;
		}
		if(!defined($CompoundLists->[$data->[$i]->[2]]->{$data->[$i]->[1]})) {
			$CompoundLists->[$data->[$i]->[2]]->{$data->[$i]->[1]}=1;
		}
	}
	foreach my $key (keys(%CompoundList)) {
		$#tempvec=-1;
		for(my $i=0;$i<@{$CompoundLists};$i++) {
			if(defined($CompoundLists->[$i]->{$key})) {
				$tempvec[@tempvec]=$i;
			}
		}
		$CompoundList{$key}=[@tempvec];
	}
	my $CompoundNodes=[];
	foreach my $key (keys(%CompoundList)) {
		for(my $i=0;$i<@{$CompoundList{$key}};$i++) {
			(my $CompName=$tobin->compoundNameGet($key))=~s/"/\\\"/g;
			# "
			if(@{$CompoundList{$key}}>1) {
				$CompName=$CompName.$CompartmentNames[$i];
			}
			push(@{$CompoundNodes},[$CCode.$key.$CSep.$i,$CompName,$key.$URLc.$CompSep.$i,defined($EdgeSubs->[$CompoundList{$key}->[$i]]->{$key})]);
			$CompoundLists->[$CompoundList{$key}->[$i]]->{$key}=@{$CompoundNodes}-1;
		}
	}
	my %ReactionSink;
	my %ReactionSource;
	my %ReactionOneSub;
	my %ReactionOneProd;
	for(my $i=0;$i<@{$elementlist};$i++) {
		my $onesub=0;
		my $oneprod=0;
		my $sink=1;
		my $source=1;
		foreach(@{$elementlist->[$i]}) {
			if($_->[2]>0) {
				$sink=0;
				$oneprod++
			}
			elsif($_->[2]<0) {
				$source=0;
				$onesub++;
			}
		} 
		if($sink) {
			$ReactionSink{$realist->[$i]}=1;
		}
		if($source) {
			$ReactionSource{$realist->[$i]}=1;
		}
		if($oneprod==1) {
			$ReactionOneProd{$realist->[$i]}=1;
		}
		if($onesub==1) {
			$ReactionOneSub{$realist->[$i]}=1;
		}
	}
	my $unireact =[];
	foreach(@{$realist}) {
		if(!defined($revreactlist{$_})) {
			push(@{$unireact},$_);
		}
	}
	my %unireactlist;
	for(my $i=0;$i<@{$unireact};$i++) {
		(my $tempstr=$tobin->transformationNameGet($unireact->[$i]))=~s/"/\\\"/g;
		$unireactlist{$unireact->[$i]}=$tempstr;
	}
	# "
	my %FBAData;
	foreach(@{$realist}) {
		$FBAData{$_}=$tobin->transformationFluxGet($_);
	}
	my $FBANorm=[];
	my $AllFluxes=[];
	if(defined($flags{'SHOWFBA'})) {
		for(my $i=0;$i<@{$elementlist};$i++) {
			for(my $j=0;$j<@{$elementlist->[$i]};$j++) {
				push(@{$AllFluxes},abs($elementlist->[$i]->[$j]->[2])*$FBAData{$realist->[$i]});
			}
		}
		$FBANorm=$self->NormalizeFBA($AllFluxes);
	}
	open(WY,">$filename");
	print(WY "digraph \"model\" {\n");
	foreach(@{$CompoundNodes}) {
		print(WY "\t\"$_->[0]\" [\n\t\tlabel = \"$_->[1]\"\n");
#		print(WY "\t\tfontname = \"Times-Roman\"\n\t\tfontcolor = \"black\"\n");
		print(WY "\t\tfontname = \"Vera\"\n\t\tfontcolor = \"black\"\n");
		print(WY "\t\tURL = \"$URLString$_->[2]\"\n\t\tshape = \"ellipse\"\n");
		if(defined($ExpData->[0])&&$_->[3]) {
			print(WY "\t\tcolor = \"yellow\"\n");
		}
		else {
			print(WY "\t\tcolor = \"black\"\n");
		}
		print(WY"\t]\n");
	}
	foreach(@{$unireact}) {
		print(WY"\t\"".$RCode.$_."\" [\n\t\tlabel = \"$unireactlist{$_}\"\n");
#		print(WY "\t\tcolor = \"black\"\n\t\tfontname = \"Times-Roman\"\n\t\tfontcolor = \"black\"\n");
		print(WY "\t\tcolor = \"black\"\n\t\tfontname = \"Vera\"\n\t\tfontcolor = \"black\"\n");
		print(WY "\t\tshape = \"box\"\n\t\tURL = \"$URLString$_$URLt");
		if(defined($flags{'SHOWFBA'})) {
			print(WY $FluxSep.$FBAData{$_});
		}
		print(WY"\"\n\t]\n");
		if(!defined($ReactionSource{$_})&&!defined($ReactionOneSub{$_})) {
			print(WY"\t\"".$RCode.$_."IN\" [\n\t\tlabel = \"\"\n");
			print(WY "\t\tcolor = \"black\"\n");
			print(WY "\t\tshape = \"point\"\n\t\twidth = \"0.03\"\n\t]\n");
			print(WY"\t\"".$RCode.$_."IN\" -> \"".$RCode.$_."\" [\n");
			print(WY"\t\tURL = \"$URLString$_$URLt");
			if(defined($flags{'SHOWFBA'})) {
				print(WY $FluxSep.$FBAData{$_}."\"\n");
				$self->PrintSumFBA($elementlist->[$reamap->{$_}],$FBAData{$_},$FBANorm,*WY,"IN");
			}
			else {
				print(WY"\"\n");
			}
			print(WY"\t\theadport = \"n\"\n\t]\n");
		}
		if(!defined($ReactionSink{$_})&&!defined($ReactionOneProd{$_})) {
			print(WY"\t\"".$RCode.$_."OUT\" [\n\t\tlabel = \"\"\n");
			print(WY "\t\tcolor = \"black\"\n");
			print(WY "\t\tshape = \"point\"\n\t\twidth = \"0.03\"\n\t]\n");
			print(WY"\t\"".$RCode.$_."\" -> \"".$RCode.$_."OUT\" [\n");
			print(WY"\t\tURL = \"$URLString$_$URLt");
			if(defined($flags{'SHOWFBA'})) {
				print(WY $FluxSep.$FBAData{$_}."\"\n");
				$self->PrintSumFBA($elementlist->[$reamap->{$_}],$FBAData{$_},$FBANorm,*WY,"OUT");
			}
			else {
				print(WY"\"\n");
			}
			print(WY"\t\ttailport = \"s\"\n\t\tarrowhead = \"none\"\n\t]\n");
		}
	}
	foreach(@{$revreact}) {
		$revreactlist{$_->[0]}->[1]=~s/</\&lt;/g;
        $revreactlist{$_->[0]}->[1]=~s/>/\&gt;/g;
        $revreactlist{$_->[1]}->[1]=~s/</\&lt;/g;
        $revreactlist{$_->[1]}->[1]=~s/>/\&gt;/g;
		print(WY"\t\"$RRCode$_->[0]$RRSep$_->[1]\" [\n");
		print(WY "\t\tshape = \"plaintext\"\n");
		print(WY "\t\tlabel=\<<TABLE BORDER=\"0\" CELLBORDER=\"1\" CELLSPACING=\"0\"><TR>".
		"<TD HREF=\"$URLString$_->[0]$URLt");
		if(defined($flags{'SHOWFBA'})) {
			print(WY $FluxSep.$FBAData{$_->[0]});
		}
		print(WY"\" PORT=\"for\">$revreactlist{$_->[0]}->[1]</TD>".
		"<TD PORT=\"rev\" HREF=\"$URLString$_->[1]$URLt");
		if(defined($flags{'SHOWFBA'})) {
			print(WY $FluxSep.$FBAData{$_->[1]});
		}
		print(WY"\">$revreactlist{$_->[1]}->[1]</TD>".
		"</TR></TABLE>>\n");
#		print(WY "\t\tcolor = \"black\"\n\t\tfontname = \"Times-Roman\"\n\t\tfontcolor = \"black\"\n\t]\n");
		print(WY "\t\tcolor = \"black\"\n\t\tfontname = \"Vera\"\n\t\tfontcolor = \"black\"\n\t]\n");
		if(!defined($ReactionSource{$_->[0]})&&!defined($ReactionOneSub{$_->[0]})) {
			print(WY"\t\"$RRCode$_->[0]$RRSep$_->[1]FOR\" [\n\t\tlabel = \"\"\n");
			print(WY "\t\tcolor = \"black\"\n");
			print(WY "\t\tshape = \"point\"\n\t\twidth = \"0.014\"\n\t]\n");
			print(WY"\t\"$RRCode$_->[0]$RRSep$_->[1]FOR\" -> \"$RRCode$_->[0]$RRSep$_->[1]\":for:n [\n");
			print(WY"\t\tURL = \"$URLString$_->[0]$URLt");
			if(defined($flags{'SHOWFBA'})) {
				print(WY $FluxSep.$FBAData{$_->[0]}."\"\n");
				$self->PrintSumFBA($elementlist->[$reamap->{$_->[0]}],$FBAData{$_->[0]},$FBANorm,*WY,0);
			}
			else {
				print(WY"\"\n");
			}
			print(WY"\t]\n");
			print(WY"\t\"$RRCode$_->[0]$RRSep$_->[1]\":rev:n -> \"$RRCode$_->[0]$RRSep$_->[1]FOR\" [\n");
			print(WY"\t\tURL = \"$URLString$_->[1]$URLt");
			if(defined($flags{'SHOWFBA'})) {
				print(WY $FluxSep.$FBAData{$_->[1]}."\"\n");
				$self->PrintSumFBA($elementlist->[$reamap->{$_->[1]}],$FBAData{$_->[1]},$FBANorm,*WY,1);
			}
			else {
				print(WY"\"\n");
			}
			print(WY"\t]\n");
		}
		if(!defined($ReactionSink{$_->[0]})&&!defined($ReactionOneProd{$_->[0]})) {
			print(WY"\t\"$RRCode$_->[0]$RRSep$_->[1]REV\" [\n\t\tlabel = \"\"\n");
			print(WY "\t\tcolor = \"black\"\n");
			print(WY "\t\tshape = \"point\"\n\t\twidth = \"0.014\"\n\t]\n");
			print(WY"\t\"$RRCode$_->[0]$RRSep$_->[1]\":for:s -> \"$RRCode$_->[0]$RRSep$_->[1]REV\" [\n");
			print(WY"\t\tURL = \"$URLString$_->[0]$URLt");
			if(defined($flags{'SHOWFBA'})) {
				print(WY $FluxSep.$FBAData{$_->[0]}."\"\n");
				$self->PrintSumFBA($elementlist->[$reamap->{$_->[0]}],$FBAData{$_->[0]},$FBANorm,*WY,1);
			}
			else {
				print(WY"\"\n");
			}
			print(WY"\t]\n");
			print(WY"\t\"$RRCode$_->[0]$RRSep$_->[1]REV\" -> \"$RRCode$_->[0]$RRSep$_->[1]\":rev:s [\n");
			print(WY"\t\tURL = \"$URLString$_->[1]$URLt");
			if(defined($flags{'SHOWFBA'})) {
				print(WY $FluxSep.$FBAData{$_->[1]}."\"\n");
				$self->PrintSumFBA($elementlist->[$reamap->{$_->[1]}],$FBAData{$_->[1]},$FBANorm,*WY,0);
			}
			else {
				print(WY"\"\n");
			}
			print(WY"\t]\n");
		}
	}
	for(my $i=0;$i<@{$elementlist};$i++) {
		if(defined($revreactlist{$realist->[$i]})) {
			if($revreact->[$revreactlist{$realist->[$i]}->[0]]->[0]==$realist->[$i]) {
				foreach(@{$elementlist->[$i]}) {
					if($_->[2]<0) {
						if(defined($ReactionOneSub{$realist->[$i]})) {
							print(WY"\"$CompoundNodes->[$CompoundLists->[$_->[1]]->{$_->[0]}]->[0]\" -> ".
							"\"$RRCode$realist->[$i]$RRSep$revreact->[$revreactlist{$realist->[$i]}->[0]]->[1]".
							"\" [\n\t\theadport=\"for:n\"\n");
							print(WY"\t\tURL = \"$URLString$realist->[$i]$URLt");
							if(defined($flags{'SHOWFBA'})) {
								print(WY $FluxSep.$FBAData{$realist->[$i]}."\"\n");
								$self->PrintFBA($_,$FBAData{$realist->[$i]},$FBANorm,*WY);
							}
							else {
								print(WY"\"\n");
							}
							print(WY"\t]\n");
							print(WY"\"$RRCode$realist->[$i]$RRSep$revreact->[$revreactlist{$realist->[$i]}->[0]]->[1]\"".
							" -> \"$CompoundNodes->[$CompoundLists->[$_->[1]]->{$_->[0]}]->[0]\" [\n"."\t\ttailport=\"rev:n\"\n");
							print(WY"\t\tURL = \"$URLString$revreact->[$revreactlist{$realist->[$i]}->[0]]->[1]$URLt");
							if(defined($flags{'SHOWFBA'})) {
								print(WY $FluxSep.$FBAData{$revreact->[$revreactlist{$realist->[$i]}->[0]]->[1]}."\"\n");
								$self->PrintFBA($_,$FBAData{$revreact->[$revreactlist{$realist->[$i]}->[0]]->[1]},$FBANorm,*WY);
							}
							else {
								print(WY"\"\n");
							}
							print(WY"\t]\n");
						}
						else {
							print(WY"\"$CompoundNodes->[$CompoundLists->[$_->[1]]->{$_->[0]}]->[0]\" -> ".
							"\"$RRCode$realist->[$i]$RRSep$revreact->[$revreactlist{$realist->[$i]}->[0]]->[1]".
							"FOR\" [\n\t\tarrowtail=\"normal\"\n\t\tURL = \"".
							"$URLString$CompoundNodes->[$CompoundLists->[$_->[1]]->{$_->[0]}]->[2]\"\n");
							if(defined($flags{'SHOWFBA'})) {
								$self->PrintFBA($_,$FBAData{$realist->[$i]},$FBANorm,*WY);
							}
							print(WY"\t]\n");
						}
					}
					else {
						if(defined($ReactionOneProd{$realist->[$i]})) {
							print(WY"\"$CompoundNodes->[$CompoundLists->[$_->[1]]->{$_->[0]}]->[0]\" -> ".
							"\"$RRCode$realist->[$i]$RRSep$revreact->[$revreactlist{$realist->[$i]}->[0]]->[1]".
							"\" [\n\t\theadport=\"rev:s\"\n");
							print(WY"\t\tURL = \"$URLString$revreact->[$revreactlist{$realist->[$i]}->[0]]->[1]$URLt");
							if(defined($flags{'SHOWFBA'})) {
								print(WY $FluxSep.$FBAData{$revreact->[$revreactlist{$realist->[$i]}->[0]]->[1]}."\"\n");
								$self->PrintFBA($_,$FBAData{$revreact->[$revreactlist{$realist->[$i]}->[0]]->[1]},$FBANorm,*WY);
							}
							else {
								print(WY"\"\n");
							}
							print(WY"\t]\n");
							print(WY"\"$RRCode$realist->[$i]$RRSep$revreact->[$revreactlist{$realist->[$i]}->[0]]->[1]\"".
							" -> \"$CompoundNodes->[$CompoundLists->[$_->[1]]->{$_->[0]}]->[0]\""." [\n\t\ttailport=\"for:s\"\n");
							print(WY"\t\tURL = \"$URLString$realist->[$i]$URLt");
							if(defined($flags{'SHOWFBA'})) {
								print(WY $FluxSep.$FBAData{$realist->[$i]}."\"\n");
								$self->PrintFBA($_,$FBAData{$realist->[$i]},$FBANorm,*WY);
							}
							else {
								print(WY"\"\n");
							}
							print(WY"\t]\n");
						}
						else {
							print(WY"\"$RRCode$realist->[$i]$RRSep$revreact->[$revreactlist{$realist->[$i]}->[0]]->[1]REV\" ->".
							" \"$CompoundNodes->[$CompoundLists->[$_->[1]]->{$_->[0]}]->[0]\" [\n".
							"\t\tarrowtail=\"normal\"\n\t\tURL = \"".
							"$URLString$CompoundNodes->[$CompoundLists->[$_->[1]]->{$_->[0]}]->[2]\"\n");
							if(defined($flags{'SHOWFBA'})) {
								$self->PrintFBA($_,$FBAData{$realist->[$i]},$FBANorm,*WY);
							}
							print(WY"\t]\n");
						}
					}
				}
			}
		#	else {
		#		foreach(@{$elementlist->[$i]}) {
		#			if($_->[2]<0) {
		#				print(WY"\"$CompoundNodes->[$CompoundLists->[$_->[1]]->{$_->[0]}]\" -> ".
		#				"\"$RRCode$revreact->[$revreactlist{$realist->[$i]}->[0]]->[0]$RRSep$realist->[$i]REV\"\n");
		#			}
		#			else {
		#				print(WY"\"$RRCode$revreact->[$revreactlist{$realist->[$i]}->[0]]->[0]$RRSep$realist->[$i]REV\" -> ".
		#				"\"$CompoundNodes->[$CompoundLists->[$_->[1]]->{$_->[0]}]\"\n");
		#			}
		#		}
		#	}
		#
		}
		else {
			foreach(@{$elementlist->[$i]}) {
				if($_->[2]<0) {
					if(defined($ReactionOneSub{$realist->[$i]})) {
						print(WY"\"$CompoundNodes->[$CompoundLists->[$_->[1]]->{$_->[0]}]->[0]\" -> ".
						"\"".$RCode.$realist->[$i]."\" [\n\t\theadport = \"n\"\n");
						print(WY"\t\tURL = \"$URLString$realist->[$i]$URLt");
						if(defined($flags{'SHOWFBA'})) {
								print(WY $FluxSep.$FBAData{$realist->[$i]}."\"\n");
								$self->PrintFBA($_,$FBAData{$realist->[$i]},$FBANorm,*WY);
						}
						else {
							print(WY"\"\n");
						}
						print(WY"\t]\n");
					}
					else {
						print(WY"\"$CompoundNodes->[$CompoundLists->[$_->[1]]->{$_->[0]}]->[0]\" -> ".
						"\"".$RCode.$realist->[$i]."IN\" [\n\t\tarrowhead = \"none\"\n\t\tURL = \"".
						"$URLString$CompoundNodes->[$CompoundLists->[$_->[1]]->{$_->[0]}]->[2]\"\n");
						if(defined($flags{'SHOWFBA'})) {
								$self->PrintFBA($_,$FBAData{$realist->[$i]},$FBANorm,*WY);
						}
						print(WY"\t]\n");
					}
				}
				else {
					if(defined($ReactionOneProd{$realist->[$i]})) {
						print(WY"\"".$RCode.$realist->[$i]."\" -> ".
						"\"$CompoundNodes->[$CompoundLists->[$_->[1]]->{$_->[0]}]->[0]\" [\n".
						"\t\ttailport = \"s\"\n");
						print(WY"\t\tURL = \"$URLString$realist->[$i]$URLt");
						if(defined($flags{'SHOWFBA'})) {
							print(WY $FluxSep.$FBAData{$realist->[$i]}."\"\n");
							$self->PrintFBA($_,$FBAData{$realist->[$i]},$FBANorm,*WY);
						}
						else {
							print(WY"\"\n");
						}
						print(WY"\t]\n");
					}
					else {
						print(WY"\"".$RCode.$realist->[$i]."OUT\" -> ".
						"\"$CompoundNodes->[$CompoundLists->[$_->[1]]->{$_->[0]}]->[0]\" [\n");
						print(WY "\t\tURL = \"$URLString".
						"$CompoundNodes->[$CompoundLists->[$_->[1]]->{$_->[0]}]->[2]\"\n");
						if(defined($flags{'SHOWFBA'})) {
								$self->PrintFBA($_,$FBAData{$realist->[$i]},$FBANorm,*WY);
						}
						print(WY"\t]\n");
					}
				}
			}
		}	
	}
	print(WY "}\n");
	close(WY); 
}

sub NormalizeFBA {
	my $self		= shift;
	my $data_in		= shift;
	
	my $data;
	@{$data}=@{$data_in};
	my $mean=0;
	my $counter=0;
	my $intervals=10;
	my $min;
	my $max;
	foreach (@{$data}) {
		if($_) {
			$mean+=$_;
			$counter++;
		}
	}
	
	if($counter) {
		$counter && ( $mean /= $counter );
		$min=$mean;
		$max=$mean;
		my $StdDev=0;
		foreach (@{$data}) {
			if($_) {
				$StdDev+=($_-$mean)*($_-$mean);
				$min=$_<$min?$_:$min;
				$max=$_>$max?$_:$max;
			}
		}
		$StdDev=$counter!=1?sqrt($StdDev/($counter-1)):0;	
		my $UpperBorder=$mean+3*$StdDev;
		my $LowerBorder=$mean-3*$StdDev>0?$mean-3*$StdDev:0.1;
		$UpperBorder = $UpperBorder< $max?$UpperBorder:$max;
		$LowerBorder=$LowerBorder>$min?$LowerBorder:$min;
		my $Base=exp(log($UpperBorder/$LowerBorder)/$intervals);
		if($Base!=1) {
			print("$LowerBorder $UpperBorder $Base"." ".log($LowerBorder)/log($Base)."\n");
			return [$Base,log($LowerBorder)/log($Base)];
		}
		else {
			return [$Base,$LowerBorder];
		}
	}
	return [0,0];
	
#	foreach my $key (keys(%{$data})) {
#		if(!$data->{$key}) {
#			$data->{$key}=-1;
#		}
#		elsif($data->{$key}<$LowerBorder) {
#			$data->{$key}=0;
#		}
#		elsif($data->{$key}>$UpperBorder) {
#			$data->{$key}=$intervals+1;
#		}
#		else {
#			$data->{$key}=ceil(($data->{$key}-$LowerBorder)*$intervals/($UpperBorder-$LowerBorder));
#			
#		}
#	}
#	return $data	
}

sub PrintFBA {
	my $self		= shift;
	my $Element		= shift;
	my $FBAData		= shift;
	my $FBANorm		= shift;
	my $file		= shift;
	
	my $LineWidth;
	if(!$FBAData) {
		$LineWidth=-1;
	}
	else {
		if($FBANorm->[0]!=1) {
			$LineWidth=1+log($FBAData*abs($Element->[2]))/log($FBANorm->[0])-$FBANorm->[1];		
		}
		else {
			$LineWidth=$FBAData*abs($Element->[2])/$FBANorm->[1];
		}
	}
	$self->PrintFBA_INT($LineWidth,$file);
}

sub PrintSumFBA {
	my $self		= shift;
	my $Elements	= shift;
	my $FBAData		= shift;
	my $FBANorm		= shift;
	my $file		= shift;
	my $Direction	= shift;
	
	my $LineWidth;
	if(!$FBAData) {
		$LineWidth=-1;
		
	}
	else {
		if($Direction) {
			foreach(@{$Elements}) {
				if($_->[2]>0) {
					$LineWidth+=$_->[2];
				}
			}
		}
		else {
			foreach(@{$Elements}) {
				if($_->[2]<0) {
					$LineWidth+=abs($_->[2]);
				}
			}
		}
		if($FBANorm->[0]!=1) {
			$LineWidth=1+log($FBAData*$LineWidth)/log($FBANorm->[0])-$FBANorm->[1];
		}
		else {
			$LineWidth=$FBAData*$LineWidth/$FBANorm->[1];
		}
	}
	$self->PrintFBA_INT($LineWidth,$file);
}

sub PrintFBA_INT {
	my $self		= shift;
	my $LineWidth	= shift;
	my $file		= shift;
	
	if($LineWidth==-1) {
		print($file "\t\tstyle=\"dashed,setlinewidth(1)\"\n\t\tcolor=\"grey\"\n");
	}
	elsif($LineWidth<1) {
		print($file "\t\tstyle=\"dashed,setlinewidth(1)\"\n");
	}
	elsif($LineWidth>11) {
		print($file "\t\tstyle=\"dashed,setlinewidth(10)\"\n\t\tarrowsize=\"3\"\n");
	}
	else {
		print($file "\t\tstyle=\"setlinewidth($LineWidth)\"\n\t\tarrowsize=\"".(1+($LineWidth-1)*2/9)."\"\n");
	}
}

sub suicide{
	my $self = shift;
	my $txt = shift;
	my $pack;
	my $file;
	my $line;
	my $i = 0;
	defined( $txt ) || ( $txt = '' );
	while(($pack, $file, $line) = caller($i++)){
		warn "Die - $pack - $file - $line\n";
	}
	die "DotGen is dead... $txt\n";
}

1;



