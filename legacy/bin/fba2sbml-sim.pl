#!/usr/bin/perl -I. -w
use strict;
use warnings;
use Tobin::IF;
my $tobin	= new Tobin::IF(1);

open(WE, $ARGV[2])||die("Cannot open reversible file.");
my @tab=<WE>;
close(WE);
my $revhash={};
foreach(@tab) {
	chomp;
	my @tab1=split(/\t/,$_);
	(defined($revhash->{$tab1[0]})||defined($revhash->{$tab1[1]}))&&
	die("Problem with reversibles.");
	$revhash->{$tab1[0]}=$tab1[1];
	$revhash->{$tab1[1]}=$tab1[0];
}
my $tfset=[];
my $limits={};
if($ARGV[0]) {
	my $fbaset=$tobin->fbasetupGet($ARGV[1]);
	foreach(@{$fbaset->{TFSET}}) {
		push(@{$tfset},$_->[0]);
		$limits->{$_->[0]}=[$_->[2],$_->[3]];
	}
}
else {
	open(WE, $ARGV[1])||die("Cannot open reaction list");
	my @tab=<WE>;
	close(WE);
	foreach(@tab) {
		chomp;
		push(@{$tfset},$_);
	}
}

open(WE, $ARGV[3])||die("Cannot open excluded file.");
@tab=<WE>;
close(WE);
my $exchash={};
foreach(@tab) {
	chomp;
	$exchash->{$_}=1;
}

open(WE, "imo1056cdata.csv")||die("cannot open cdata");
@tab=<WE>;
close(WE);
my $cdata={};
foreach(@tab) {
	chomp;
	my @tab1=split(/\t/,$_);
	$cdata->{$tab1[0]}=[$tab1[1],$tab1[2]];
}
open(WE, "mcodes-new.csv")||die("cannot open mcodes");
@tab=<WE>;
close(WE);
my $mcodes={};
foreach(@tab) {
	chomp;
	my @tab1=split(/\t/,$_);
	defined($cdata->{$tab1[0]})||next;
	defined($mcodes->{$tab1[1]})&&die("Too many mcodes for $tab1[1]");
	$mcodes->{$tab1[1]}=$tab1[0];
}
open(WE, "imo1056scodes.1.csv")||die("cannot open scodes");
@tab=<WE>;
close(WE);
my $scodes={};
foreach(@tab) {
	chomp;
	my @tab1=split(/\t/,$_);
	@tab1==3&&$revhash->{$tab1[1]}!=$tab1[2]&&
	die("Problem with reversibles for $tab1[0]");
	$scodes->{$tab1[1]}= $tab1[0];
}
open(WE, "imo1056rdata.csv")||die("cannot open rdata");
@tab=<WE>;
close(WE);
my $rdata={};
foreach(@tab) {
	chomp;
	my @tab1=split(/\t/,$_);
	$rdata->{$tab1[0]}=[$tab1[1],$tab1[2]];
	
}

my $special={9885=>"Biomass synthesis",9886=>"Growth related ATP consumption",
	8984=>"NGAM"};
my $assigned={};
my $cpdhash=[{},{}];
foreach(@{$tfset}) {
	defined($exchash->{$_})&&next;
	defined($assigned->{$_})&&next;
	defined($revhash->{$_})&&($assigned->{$revhash->{$_}}=1);
	my $tf=$tobin->transformationGet($_);
	foreach my $cpd (@{$tf->[2]}) {
		$cpdhash->[$cpd->{ext}]->{$cpd->{id}}=1; 
	}
	
}
print( "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n");
print( "<sbml xmlns=\"http://www.sbml.org/sbml/level2\"". 
" xmlns:sbml=\"http://www.sbml.org/sbml/level2\" version=\"3\" level=\"2\"\n");
print("xmlns:html=\"http://www.w3.org/1999/xhtml\">\n");
print("<model id=\"$ARGV[4]\" name=\"$ARGV[5]\" >\n");
print("<listOfUnitDefinitions>\n\t<unitDefinition id=\"mmol_per_gDW_per_hr\">\n".
"\t\t<listOfUnits>\n\t\t\t<unit kind=\"mole\" scale=\"-3\"/>\n".
"\t\t\t<unit kind=\"gram\" exponent=\"-1\"/>\n".
"\t\t\t<unit kind=\"second\" multiplier=\".00027777\" exponent=\"-1\"/>\n".
"\t\t</listOfUnits>\n\t</unitDefinition>\n</listOfUnitDefinitions>\n");

print("<listOfCompartments>\n".
"\t<compartment id=\"Periplasm\" spatialDimensions=\"3\"/>\n".
"\t<compartment id=\"Cytosol\" spatialDimensions=\"3\" outside=\"Periplasm\"/>\n". 
"</listOfCompartments>\n<listOfSpecies>\n");
foreach my $ext (1,0) {
	foreach (keys(%{$cpdhash->[$ext]})) {
		my $charge=$tobin->compoundChargeGet($_);
		defined($charge)||($charge=0);
		print("\t<species id=\"".$mcodes->{$_}.($ext?"[e]":"").
		"\" name=\"".$cdata->{$mcodes->{$_}}->[0]."\" compartment=\"".
		($ext?"Periplasm":"Cytosol")."\" charge=\"".$charge.
		"\" boundaryCondition=\"false\"/>\n");
	}
}
print( "</listOfSpecies>\n<listOfReactions>\n");
$assigned={};
my $exctf={};
foreach(@{$tfset}) {
	defined($exchash->{$_})&&next;
	defined($special->{$_})&&next;
	defined($assigned->{$_})&&next;
	defined($revhash->{$_})&&($assigned->{$revhash->{$_}}=1);
	my $tf=$tobin->transformationGet($_);
	if($tf->[3]->[0]=~/^SOURCE|^SINK/) {
		$exctf->{$_}=1;
		next;
	}
	my $rev=defined($revhash->{$_});
	my $min=$rev?(defined($limits->{$revhash->{$_}}->[1])?
	-$limits->{$revhash->{$_}}->[1]:-999999):$limits->{$_}->[0];
	my $max=defined($limits->{$_}->[1])?$limits->{$_}->[1]:999999;
	my $reac={};
	my $prod={};
	foreach my $cpd (@{$tf->[2]}) {
		$cpd->{sto}<0?($reac->{$mcodes->{$cpd->{id}}.($cpd->{ext}?"[e]":"")}=
		-$cpd->{sto}):($prod->{$mcodes->{$cpd->{id}}.($cpd->{ext}?"[e]":"")}=
		$cpd->{sto});
	}
	my $rcode=defined($scodes->{$_})?$scodes->{$_}:$scodes->{$revhash->{$_}};
	my $name= $rdata->{$rcode}->[0];
	$name=~s/>/&gt;/g;
	$name=~s/</&lt;/g;
	print("\t<reaction id=\"".$rcode."\" name=\"".
	$name."\" reversible=\"".($rev?"true":"false").
	"\">\n\t\t<notes>\n\t\t\t<html:p>GENE_ASSOCIATION: ".$rdata->{$rcode}->[1].
	"</html:p>\n\t\t</notes>\n"."\t\t<listOfReactants>\n");
	foreach my $cpd (keys(%{$reac})) {
		print("\t\t\t<speciesReference species=\"".$cpd."\" stoichiometry=\"".
		sprintf("%6f",$reac->{$cpd})."\"/>\n")
	}
	print("\t\t</listOfReactants>\n\t\t<listOfProducts>\n");
	foreach my $cpd (keys(%{$prod})) {
		print("\t\t\t<speciesReference species=\"".$cpd."\" stoichiometry=\"".
		sprintf("%6f",$prod->{$cpd})."\"/>\n")
	}
	print("\t\t</listOfProducts>\n\t\t<kineticLaw>\n".
	"\t\t<math xmlns=\"http://www.w3.org/1998/Math/MathML\">\n\t\t\t<apply>\n".
	"\t\t\t\t<ci> LOWER_BOUND </ci>\n\t\t\t\t<ci> UPPER_BOUND </ci>\n".
	"\t\t\t</apply>\n\t\t</math>\n");
	print("\t\t<listOfParameters>\n\t\t\t<parameter id=\"LOWER_BOUND\" value=\"".
	sprintf("%6f",$min)."\" units=\"mmol_per_gDW_per_hr\"/>\n");
	print("\t\t\t<parameter id=\"UPPER_BOUND\" value=\"".
	sprintf("%6f",$max)."\" units=\"mmol_per_gDW_per_hr\"/>\n");
	print("\t\t</listOfParameters>\n\t\t</kineticLaw>\n\t</reaction>\n");
}
foreach(keys(%{$special})) {
	my $rev=defined($revhash->{$_});
	my $min=$rev?(defined($limits->{$revhash->{$_}}->[1])?
	-$limits->{$revhash->{$_}}->[1]:-999999):$limits->{$_}->[0];
	my $max=defined($limits->{$_}->[1])?$limits->{$_}->[1]:999999;
	my $reac={};
	my $prod={};
	my $tf=$tobin->transformationGet($_);
	foreach my $cpd (@{$tf->[2]}) {
		$cpd->{sto}<0?($reac->{$mcodes->{$cpd->{id}}.($cpd->{ext}?"[e]":"")}=
		-$cpd->{sto}):($prod->{$mcodes->{$cpd->{id}}.($cpd->{ext}?"[e]":"")}=
		$cpd->{sto});
	}
	my $rcode=defined($scodes->{$_})?$scodes->{$_}:$scodes->{$revhash->{$_}};
	my $name= $rdata->{$rcode}->[0];
	$name=~s/>/&gt;/g;
	$name=~s/</&lt;/g;
	print("\t<reaction id=\"".$rcode."\" name=\"".
	$name."\" reversible=\"".($rev?"true":"false").
	"\">\n\t\t<notes>\n\t\t\t<html:p>GENE_ASSOCIATION: ".
	"</html:p>\n\t\t</notes>\n"."\t\t<listOfReactants>\n");
	foreach my $cpd (keys(%{$reac})) {
		print("\t\t\t<speciesReference species=\"".$cpd."\" stoichiometry=\"".
		sprintf("%6f",$reac->{$cpd})."\"/>\n")
	}
	print("\t\t</listOfReactants>\n\t\t<listOfProducts>\n");
	foreach my $cpd (keys(%{$prod})) {
		print("\t\t\t<speciesReference species=\"".$cpd."\" stoichiometry=\"".
		sprintf("%6f",$prod->{$cpd})."\"/>\n")
	}
	print("\t\t</listOfProducts>\n\t\t<kineticLaw>\n".
	"\t\t<math xmlns=\"http://www.w3.org/1998/Math/MathML\">\n\t\t\t<apply>\n".
	"\t\t\t\t<ci> LOWER_BOUND </ci>\n\t\t\t\t<ci> UPPER_BOUND </ci>\n".
	"\t\t\t</apply>\n\t\t</math>\n");
	print("\t\t<listOfParameters>\n\t\t\t<parameter id=\"LOWER_BOUND\" value=\"".
	sprintf("%6f",$min)."\" units=\"mmol_per_gDW_per_hr\"/>\n");
	print("\t\t\t<parameter id=\"UPPER_BOUND\" value=\"".
	sprintf("%6f",$max)."\" units=\"mmol_per_gDW_per_hr\"/>\n");
	print("\t\t</listOfParameters>\n\t\t</kineticLaw>\n\t</reaction>\n");
}
foreach(keys(%{$exctf})) {
	my $rev=defined($revhash->{$_});
	my $min=$rev?(defined($limits->{$revhash->{$_}}->[1])?
	-$limits->{$revhash->{$_}}->[1]:-999999):$limits->{$_}->[0];
	my $max=defined($limits->{$_}->[1])?$limits->{$_}->[1]:999999;
	my $reac={};
	my $prod={};
	my $tf=$tobin->transformationGet($_);
	foreach my $cpd (@{$tf->[2]}) {
		$cpd->{sto}<0?($reac->{$mcodes->{$cpd->{id}}.($cpd->{ext}?"[e]":"")}=
		-$cpd->{sto}):($prod->{$mcodes->{$cpd->{id}}.($cpd->{ext}?"[e]":"")}=
		$cpd->{sto});
	}
	my $rcode=defined($scodes->{$_})?$scodes->{$_}:$scodes->{$revhash->{$_}};
	my $name= $rdata->{$rcode}->[0];
	$name=~s/>/&gt;/g;
	$name=~s/</&lt;/g;
	print("\t<reaction id=\"".$rcode."\" name=\"".
	$name."\" reversible=\"".($rev?"true":"false").
	"\">\n\t\t<notes>\n\t\t\t<html:p>GENE_ASSOCIATION: ".
	"</html:p>\n\t\t</notes>\n"."\t\t<listOfReactants>\n");
	foreach my $cpd (keys(%{$reac})) {
		print("\t\t\t<speciesReference species=\"".$cpd."\" stoichiometry=\"".
		sprintf("%6f",$reac->{$cpd})."\"/>\n")
	}
	print("\t\t</listOfReactants>\n\t\t<listOfProducts>\n");
	foreach my $cpd (keys(%{$prod})) {
		print("\t\t\t<speciesReference species=\"".$cpd."\" stoichiometry=\"".
		sprintf("%6f",$prod->{$cpd})."\"/>\n")
	}
	print("\t\t</listOfProducts>\n\t\t<kineticLaw>\n".
	"\t\t<math xmlns=\"http://www.w3.org/1998/Math/MathML\">\n\t\t\t<apply>\n".
	"\t\t\t\t<ci> LOWER_BOUND </ci>\n\t\t\t\t<ci> UPPER_BOUND </ci>\n".
	"\t\t\t</apply>\n\t\t</math>\n");
	print("\t\t<listOfParameters>\n\t\t\t<parameter id=\"LOWER_BOUND\" value=\"".
	sprintf("%6f",$min)."\" units=\"mmol_per_gDW_per_hr\"/>\n");
	print("\t\t\t<parameter id=\"UPPER_BOUND\" value=\"".
	sprintf("%6f",$max)."\" units=\"mmol_per_gDW_per_hr\"/>\n");
	print("\t\t</listOfParameters>\n\t\t</kineticLaw>\n\t</reaction>\n");	
}
print("</listOfReactions>\n</model>\n</sbml>\n");
