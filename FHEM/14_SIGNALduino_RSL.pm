###########################################
# SIGNALduini RSL Modul. Modified version of FHEMduino Modul by Wzut
#  
# $Id: $
# Supports following devices:
# - Conrad RSL Funk-Jalousieaktor Unterputz RSL 1-Kanal Bestell-Nr.: 640579 - 62 
#####################################

package main;

use strict;
use warnings;

my %sets = ( "on:noArg"  => "", "off:noArg"  => "");

my @RSLCodes;

    # Tastenpaar [1 - 3] , Schiebeschalter/Kanal [I - IV] , an-aus [1 - 0] 
    $RSLCodes[0][0][0] =  62;   # ? / ?    off  
    $RSLCodes[0][0][1] =  54;   # ? / ?    on   
    $RSLCodes[1][1][0] =   1;   # 1 / I    off
    $RSLCodes[1][1][1] =  14;   # 1 / I    on
    $RSLCodes[1][2][0] =  46;   # 2 / I    off   
    $RSLCodes[1][2][1] =  38;   # 2 / I    on
    $RSLCodes[1][3][0] =  30;   # 3 / I    off
    $RSLCodes[1][3][1] =  22;   # 3 / I    on 
    $RSLCodes[1][4][0] =  53;   # 4 / I    off  - nicht auf 12 Kanal FB 
    $RSLCodes[1][4][1] =  57;   # 4 / I    on   - nicht auf 12 Kanal FB
    $RSLCodes[2][1][0] =  13;   # 1 / II   off
    $RSLCodes[2][1][1] =   5;   # 1 / II   on
    $RSLCodes[2][2][0] =  37;   # 2 / II   off
    $RSLCodes[2][2][1] =  41;   # 2 / II   on
    $RSLCodes[2][3][0] =  21;   # 3 / II   off
    $RSLCodes[2][3][1] =  25;   # 3 / II   on  
    $RSLCodes[2][4][0] =  56;   # 4 / II   off - nicht auf 12 Kanal FB
    $RSLCodes[2][4][1] =  48;   # 4 / II   on  - nicht auf 12 Kanal FB
    $RSLCodes[3][1][0] =   4;   # 1 / III  off
    $RSLCodes[3][1][1] =   8;   # 1 / III  on
    $RSLCodes[3][2][0] =  40;   # 2 / III  off
    $RSLCodes[3][2][1] =  32;   # 2 / III  on
    $RSLCodes[3][3][0] =  24;   # 3 / III  off
    $RSLCodes[3][3][1] =  16;   # 3 / III  on
    $RSLCodes[3][4][0] =  50;   # 4 / III  off - nicht auf 12 Kanal FB
    $RSLCodes[3][4][1] =  60;   # 4 / III  on  - nicht auf 12 Kanal FB
    $RSLCodes[4][1][0] =  10;   # 1 / IV   off
    $RSLCodes[4][1][1] =   2;   # 1 / IV   on
    $RSLCodes[4][2][0] =  34;   # 2 / IV   off
    $RSLCodes[4][2][1] =  44;   # 2 / IV   on
    $RSLCodes[4][3][0] =  18;   # 3 / IV   off
    $RSLCodes[4][3][1] =  28;   # 3 / IV   on
    $RSLCodes[4][4][0] =  35;   # 4 / IV   off - nicht auf 12 Kanal FB
    $RSLCodes[4][4][1] =  19;   # 4 / IV   on  - nicht auf 12 Kanal FB

sub SIGNALduino_RSL_Initialize($)
{ 
  my ($hash) = @_;

  $hash->{Match}     = "^r[A-Fa-f0-9]+";
  $hash->{SetFn}     = "SIGNALduino_RSL_Set";
  $hash->{DefFn}     = "SIGNALduino_RSL_Define";
  $hash->{UndefFn}   = "SIGNALduino_RSL_Undef";
  $hash->{AttrFn}    = "SIGNALduino_RSL_Attr";
  $hash->{ParseFn}   = "SIGNALduino_RSL_Parse";
  $hash->{AttrList}  = "IODev RSLrepetition ignore:0,1 ".$readingFnAttributes;
}

#####################################

sub SIGNALduino_RSL_Define($$)
{ 

  my ($hash, $def) = @_;

  my @a = split("[ \t][ \t]*", $def);

  return "wrong syntax: define <name> SIGNALduino_RSL <code (00000-FFFFFF)_channel (1-4)_button (1-4)>"  if(int(@a) != 3);

  my $name = $a[0];
  my ($device,$channel,$button) = split("_",$a[2]);
  return "wrong syntax: use channel 1 - 4"  if(($channel > 4) || ($channel < 1 ));
  return "wrong syntax: use button 1 - 4"  if(($button > 4) || ($button < 1));
  return "wrong syntax: use code 000000 - FFFFFF" if (length($device) != 6);
  return "wrong Device Code $device , please use 000000 - FFFFFF" if ((hex($device) < 0) || (hex($device) > 16777215));

  my $code = uc($a[2]);
  $hash->{DEF}   = $code;

  $modules{SIGNALduino_RSL}{defptr}{$code} = $hash;
  $modules{SIGNALduino_RSL}{defptr}{$code}{$name} = $hash;
  # code auf 32Bit umrechnen  int 16777216 = 0x1000000
  $hash->{OnCode}  = ($RSLCodes[$channel][$button][1]*16777216) + hex($device);
  $hash->{OffCode} = ($RSLCodes[$channel][$button][0]*16777216) + hex($device);

   AssignIoPort($hash);

   return undef;
}

##########################################################
sub SIGNALduino_RSL_Set($@)
{ 
  my ($hash, @a) = @_;
  my $name = $hash->{NAME};
  my $cmd  = $a[1];
  my $c;

  return join(" ", sort keys %sets) if((@a < 2) || ($cmd eq "?"));

  $c = $hash->{OnCode}  if  ($cmd eq "on") ;
  $c = $hash->{OffCode} if  ($cmd eq "off");

  return "Unknown argument $cmd, choose  on or off" if(!$c);

  my $ret = IOWrite($hash, "ss", $c."_".AttrVal($name, "RSLrepetition", 6));
  Log3 $hash, 5, "$name Set return : $ret";

  if (($cmd eq "on")  && ($hash->{STATE} eq "off")){$cmd = "stop";}
  if (($cmd eq "off") && ($hash->{STATE} eq "on")) {$cmd = "stop";}

  $hash->{CHANGED}[0] = $cmd;
  $hash->{STATE} = $cmd;
  readingsSingleUpdate($hash,"state",$cmd,1); 
  return undef;
}

###################################################################
sub RSL_getButtonCode($$)
{ 

  my ($hash,$msg) = @_;

  my $DeviceCode         = "undef";
  my $receivedButtonCode = "undef";
  my $receivedActionCode = "undef";
  my $parsedButtonCode   = "undef";
  my $action             = "undef";
  my $button             = -1;
  my $channel            = -1;

  ## Groupcode
  $DeviceCode  = substr($msg,4,6);
  $receivedButtonCode  = substr($msg,2,2);
  Log3 $hash, 5, "SIGNALduino_RSL Message Devicecode: $DeviceCode Buttoncode: $receivedButtonCode";

  $parsedButtonCode  = hex($receivedButtonCode) & 63; # nur 6 Bit bitte
  Log3 $hash, 5, "SIGNALduino_RSL Message parsed Devicecode: $DeviceCode Buttoncode: $parsedButtonCode";

  for (my $i=1; $i<5; $i++)
  {
    for (my $j=1; $j<5; $j++)
    {
      if ($RSLCodes[$i][$j][0] == $parsedButtonCode) 
        {$action ="off"; $button = $j; $channel = $i;}
      if ($RSLCodes[$i][$j][1] == $parsedButtonCode) 
        {$action ="on";  $button = $j; $channel = $i;}
    }
  }

  if (($button >-1) && ($channel > -1)) 
  {
    Log3 $hash, 4, "RSL button return/result: ID: $DeviceCode $receivedButtonCode DEVICE: $DeviceCode $channel $button ACTION: $action";
    return $DeviceCode."_".$channel."_".$button." ".$action;
  }

  return "";
}

########################################################
sub SIGNALduino_RSL_Parse($$)
{ 

  my ($hash,$msg) = @_;
  Log3 $hash, 4, "RSL Message: $msg";

  my $result = RSL_getButtonCode($hash,$msg);

  if ($result ne "") 
  {
    my ($deviceCode,$action) = split m/ /, $result, 2;

    Log3 $hash, 4, "Parse: Device: $deviceCode  Action: $action";

    my $def = $modules{SIGNALduino_RSL}{defptr}{$hash->{NAME} . "." . $deviceCode};
    $def = $modules{SIGNALduino_RSL}{defptr}{$deviceCode} if(!$def);

    if(!$def) 
    {
      Log3 $hash, 5, "UNDEFINED Remotebutton send to define: $deviceCode";
      return "UNDEFINED RSL_$deviceCode SIGNALduino_RSL $deviceCode";
    }

    $hash = $def;

    my $name = $hash->{NAME};
    return "" if(IsIgnored($name));

    if(!$action) 
    {
      Log3 $name, 5, "SIGNALduino_RSL can't decode $msg";
      return "";
    }

    Log3 $name, 5, "SIGNALduino_RSL actioncode: $action";

    if (($action eq "on")  && ($hash->{STATE} eq "off")){$action = "stop";}
    if (($action eq "off") && ($hash->{STATE} eq "on")) {$action = "stop";}

   $hash->{CHANGED}[0] = $action;
   $hash->{STATE} = $action;
   readingsSingleUpdate($hash,"state",$action,1); 

    return $name;
  }
  return "";
}

########################################################
sub SIGNALduino_RSL_Undef($$)
{ 
  my ($hash, $name) = @_;
  delete($modules{SIGNALduino_RSL}{defptr}{$hash->{DEF}}) if($hash && $hash->{DEF});
  return undef;
}

sub SIGNALduino_RSL_Attr(@)
{
  my @a = @_;

  # Make possible to use the same code for different logical devices when they
  # are received through different physical devices.
  return if($a[0] ne "set" || $a[2] ne "IODev");
  my $hash = $defs{$a[1]};
  my $iohash = $defs{$a[3]};
  my $cde = $hash->{DEF};
  delete($modules{SIGNALduino_FA20RF}{defptr}{$cde});
  $modules{SIGNALduino_FA20RF}{defptr}{$iohash->{NAME} . "." . $cde} = $hash;
  return undef;
}

1;
