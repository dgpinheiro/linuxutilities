#!/usr/bin/perl
#
#              INGLÊS/ENGLISH
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#  http://www.gnu.org/copyleft/gpl.html
#
#
#             PORTUGUÊS/PORTUGUESE
#  Este programa é distribuído na expectativa de ser útil aos seus
#  usuários, porém NÃO TEM NENHUMA GARANTIA, EXPLÍCITAS OU IMPLÍCITAS,
#  COMERCIAIS OU DE ATENDIMENTO A UMA DETERMINADA FINALIDADE.  Consulte
#  a Licença Pública Geral GNU para maiores detalhes.
#  http://www.gnu.org/copyleft/gpl.html
#
#  Copyright (C) 2012  Universidade de São Paulo
#
#  Universidade de São Paulo
#  Laboratório de Biologia do Desenvolvimento de Abelhas
#  Núcleo de Bioinformática (LBDA-BioInfo)
#
#  Daniel Guariz Pinheiro
#  dgpinheiro@gmail.com
#  http://zulu.fmrp.usp.br/bioinfo
#
# $Id$

=head1 NAME

=head1 SYNOPSIS

=head1 ABSTRACT

=head1 DESCRIPTION
    
    Arguments:

        -h/--help   Help
        -l/--level  Log level [Default: FATAL] 
            OFF
            FATAL
            ERROR
            WARN
            INFO
            DEBUG
            TRACE
            ALL

=head1 AUTHOR

Daniel Guariz Pinheiro E<lt>dgpinheiro@gmail.comE<gt>

Copyright (c) 2012 Universidade de São Paulo

=head1 LICENSE

GNU General Public License

http://www.gnu.org/copyleft/gpl.html


=cut

use strict;
use warnings;
use Readonly;
use Getopt::Long;

use vars qw/$LOGGER/;

INIT {
    use Log::Log4perl qw/:easy/;
    Log::Log4perl->easy_init($FATAL);
    $LOGGER = Log::Log4perl->get_logger($0);
}

my ($level,$hostnamefile,$systemfile,$ipfile,$chassisfile,$procfile,$cachefile,$osfile,$archfile,$memoryfile,$dffile,$freefile,$partedfile,$gangliafile);

Usage("Too few arguments") if $#ARGV < 0;
GetOptions( "h|?|help" => sub { &Usage(); },
            "l|level=s"=> \$level,
            "o|os=s"=>\$osfile,
            "a|arch=s"=>\$archfile,
            "t|hostname=s"=>\$hostnamefile,
            "s|system=s"=>\$systemfile,
            "i|ip=s"=>\$ipfile,
            "c|chassis=s"=>\$chassisfile,
            "p|processor=s"=>\$procfile,
            "e|cache=s"=>\$cachefile,
            "m|memory=s"=>\$memoryfile,
            "d|df=s"=>\$dffile,
            "f|free=s"=>\$freefile,
            "r|parted=s"=>\$partedfile,
            "g|ganglia=s"=>\$gangliafile
    ) or &Usage();


if ($level) {
    my %LEVEL = (   
    'OFF'   =>$OFF,
    'FATAL' =>$FATAL,
    'ERROR' =>$ERROR,
    'WARN'  =>$WARN,
    'INFO'  =>$INFO,
    'DEBUG' =>$DEBUG,
    'TRACE' =>$TRACE,
    'ALL'   =>$ALL);
    $LOGGER->logdie("Wrong log level ($level). Choose one of: ".join(', ', keys %LEVEL)) unless (exists $LEVEL{$level});
    Log::Log4perl->easy_init($LEVEL{$level});
}

my %info;
open(OS, "<", $osfile) or $LOGGER->logdie("$! ($osfile)");
while(<OS>) {
    chomp;
    $info{'OS'}->{''} = $_;
}
close(OS);

open(ARCH, "<", $archfile) or $LOGGER->logdie("$! ($archfile)");
while(<ARCH>) {
    chomp;
    $info{'HP'}->{''} = $_;
}
close(ARCH);

open(HN, "<", $hostnamefile) or $LOGGER->logdie("$! ($hostnamefile)");
while(<HN>) {
    chomp;
    $info{'Hostname'}->{''} = $_;
}
close(HN);

open(IP, "<", $ipfile) or $LOGGER->logdie("$! ($ipfile)");
while(<IP>) {
    chomp;
    my (@IP)=split(/\s+/, $_);
    my @selIP;
    foreach my $ip (@IP) {
        next if ($ip eq '127.0.0.1');
        push(@selIP, $ip);
    }        
    $info{'IP'}->{''} = join(' ', @selIP);
}
close(IP);

open(SYS, "<", $systemfile) or $LOGGER->logdie("$! ($systemfile)");
while(<SYS>) {
    chomp;
    if ($_=~/Manufacturer: (\S+.*\S?)/) {
        $info{'System'}->{'Manufacturer'} = $1;
    }
    elsif ($_=~/Product Name: (\S+.*\S?)/) {
        $info{'System'}->{'Product Name'} = $1;
    }
}
close(SYS);

{
    open(PARTED, "<", $partedfile) or $LOGGER->logdie("$! ($partedfile)");
    my $disk;
    my $model;
    while(<PARTED>) {
        chomp;
        if ($_=~/^Model: (\S+.*\S?)/) {
            $model=$1;
        }
        elsif ($_=~/Disk ([^:]+): (\S+.*\S?)/) {
            $disk=$1;
            my $size=$2;  
            $info{'Storage'}->{$disk}->{'model'} = $model;
            $info{'Storage'}->{$disk}->{'disk'} = $disk;
            $info{'Storage'}->{$disk}->{'size'} = $size;
        }
        elsif ($_=~/Sector size \(logical\/physical\): (\S+.*\S?)/) {
            $info{'Storage'}->{$disk}->{'Sector Size'} = $1;
        }
        elsif ($_=~/Partition Table: (\S+.*\S?)/) {
            $info{'Storage'}->{$disk}->{'Partition Table'} = $1;
        }
        elsif ($_=~/^\s*(\d+)/) {
            if ($info{'Storage'}->{$disk}->{'Partition Table'} eq 'msdos') {
                if ($_=~/^\s*(\d+)\s+\S+\s+\S+\s+(\S+)\s+\S+\s+(\S+)/) {
#                    print STDERR $disk,"\t",$1,"\t",$2,"\n";
                    $info{'Storage'}->{$disk}->{'partition'}->{$1}->{'size'} = $2;
                    $info{'Storage'}->{$disk}->{'partition'}->{$1}->{'fstype'} = $3;
                }
            }
            elsif ($info{'Storage'}->{$disk}->{'Partition Table'} eq 'gpt') {
                if ($_=~/^\s*(\d+)\s+\S+\s+\S+\s+(\S+)\s+(\S+)/) {
                    $info{'Storage'}->{$disk}->{'partition'}->{$1}->{'size'} = $2;
                    $info{'Storage'}->{$disk}->{'partition'}->{$1}->{'fstype'} = $3;
                }
            }
            else {
                $LOGGER->logdie("Cannot recognize Partition Table: $info{'Storage'}->{$disk}->{'Partition Table'}");
            }
        }
    }
    close(PARTED);
}


open(DF, "<", $dffile) or $LOGGER->logdie("$! ($dffile)");
my $dfheader=<DF>;
my $disk;
while(<DF>) {
    chomp;
    my ($fs,$fstype,$size,$used,$avail,$usep,$mounted)=split(/\s+/, $_);
    if ($fs=~/dev/) {
        foreach my $disk (keys %{ $info{'Storage'} }) {
            my $redisk=quotemeta($disk);
#            print STDERR ">>>>$redisk\n";
            if ($fs=~/^$redisk.*(\d+)$/) {
                my ($partition) = $1;
#                print STDERR $disk."\t".$partition."\t".$mounted."\n";
                $info{'Storage'}->{$disk}->{'partition'}->{$partition}->{'mounted'} = $mounted;
            }
        }
    }        
}
close(DF);

my $memoryusab=0;
open(FREE, "<", $freefile) or $LOGGER->logdie("$! ($freefile)");
while(<FREE>) {
    chomp;
    if ($_=~/^Mem:\s+(\d+)/) {
        my $m = $1;
        $memoryusab=$m; # Bytes
    }
}
close(FREE);


open(CHASSIS, "<", $chassisfile) or $LOGGER->logdie("$! ($chassisfile)");
while(<CHASSIS>) {
    chomp;
    if ($_=~/Manufacturer: (\S+.*\S?)/) {
        $info{'Chassis'}->{'Manufacturer'} = $1;
    }
    elsif ($_=~/\s+Type: (\S+.*\S?)/) {
        $info{'Chassis'}->{'Type'} = $1;
    }
    elsif ($_=~/Number Of Power Cords: (\S+.*\S?)/) {
        $info{'Chassis'}->{'Number Of Power Cords'} = $1;
    }
}
close(CHASSIS);

open(PROC, "<", $procfile) or $LOGGER->logdie($!);
my $sock;
while(<PROC>) {
    chomp;
    if ($_=~/Socket Designation: (\S+.*\S?)/) {
        $sock = $1;
        $info{'Processor'}->{$sock}->{'Socket Designation'} = $1;
    }
    elsif ($_=~/\s+Type: (\S+.*\S?)/) {
        $info{'Processor'}->{$sock}->{'Type'} = $1;
    }
    elsif ($_=~/Family: (\S+.*\S?)/) {
        $info{'Processor'}->{$sock}->{'Family'} = $1;
    }
    elsif ($_=~/Manufacturer: (\S+.*\S?)/) {
        $info{'Processor'}->{$sock}->{'Manufacturer'} = $1;
    }
    elsif ($_=~/Version: (\S+.*\S?)/) {
        $info{'Processor'}->{$sock}->{'Version'} = $1;
    }
    elsif ($_=~/Current Speed: (\S+.*\S?)/) {
        $info{'Processor'}->{$sock}->{'Current Speed'} = $1;
    }
    elsif ($_=~/Core Count: (\S+.*\S?)/) {
        $info{'Processor'}->{$sock}->{'Core Count'} = $1;
    }
    elsif ($_=~/Core Enabled: (\S+.*\S?)/) {
        $info{'Processor'}->{$sock}->{'Core Enabled'} = $1;
    }
    elsif ($_=~/Thread Count: (\S+.*\S?)/) {
        $info{'Processor'}->{$sock}->{'Thread Count'} = $1;
    }
}
close(PROC);


open(CACHE, "<", $cachefile) or $LOGGER->logdie($!);
my $cachehandle;
while(<CACHE>) {
    chomp;
    if ($_=~/^Handle (\S+.*\S?)/) {
        $cachehandle = $1;
        $info{'Cache'}->{$cachehandle}->{'Handle'} = $1;
    }        
    elsif ($_=~/Socket Designation: (\S+.*\S?)/) {
        $info{'Cache'}->{$cachehandle}->{'Socket Designation'} = $1;
    }
    elsif ($_=~/Configuration: (\S+.*\S?)/) {
        $info{'Cache'}->{$cachehandle}->{'Configuration'} = $1;
    }
    elsif ($_=~/Installed Size: (\S+.*\S?)/) {
        $info{'Cache'}->{$cachehandle}->{'Installed Size'} = $1;
    }
    elsif ($_=~/Manufacturer: (\S+.*\S?)/) {
        $info{'Cache'}->{$cachehandle}->{'Manufacturer'} = $1;
    }
    elsif ($_=~/Installed SRAM Type: (\S+.*\S?)/) {
        $info{'Cache'}->{$cachehandle}->{'Installed SRAM Type'} = $1;
    }
}
close(CACHE);

open(MEMORY, "<", $memoryfile) or $LOGGER->logdie("$! ($memoryfile)");
my $handle;
my $array;
my $memorytotal=0;
my $memoryaval=0;

while(<MEMORY>) {
    chomp;
    if ($_=~/^Physical/) {
        ($array) = $handle=~/^([^,]+)/;
        $info{'Memory'}->{$array}->{$array}->{'Handle'} = $handle;
    }

    if ($_=~/^Handle (\S+.*\S?)/) {
        $handle=$1;
    }
    elsif ($_=~/Maximum Capacity: (\S+.*\S?)/) {
        $info{'Memory'}->{$array}->{$array}->{'Maximum Capacity'} = $1;
        my ($m,$t) = split(/ /, $info{'Memory'}->{$array}->{$array}->{'Maximum Capacity'});
        $memorytotal+=($m*(($t eq 'GB') ? 1024 : (($t eq 'MB') ? 1 : 'NA')));
    }
    elsif ($_=~/Array Handle: (\S+.*\S?)/) {
        $array=$1;
        $info{'Memory'}->{$array}->{$handle}->{'Handle'} = $handle;
        $info{'Memory'}->{$array}->{$handle}->{'Array Handle'} = $array;
    }
    elsif ($_=~/Size: (\S+.*\S?)/) {
        $info{'Memory'}->{$array}->{$handle}->{'Size'} = $1;
        if ($info{'Memory'}->{$array}->{$handle}->{'Size'}=~/^\d+/) {
            my ($m,$t) = split(/ /, $info{'Memory'}->{$array}->{$handle}->{'Size'});
            $memoryaval+=($m*(($t eq 'GB') ? 1024 : (($t eq 'MB') ? 1 : 'NA')));
        }            
    }
    elsif ($_=~/Form Factor: (\S+.*\S?)/) {
        $info{'Memory'}->{$array}->{$handle}->{'Form Factor'} = $1;
    }
    elsif ($_=~/^\s+Type: (\S+.*\S?)/) {
        $info{'Memory'}->{$array}->{$handle}->{'Type'} = $1;
    }
    elsif ($_=~/Speed: (\S+.*\S?)/) {
        $info{'Memory'}->{$array}->{$handle}->{'Speed'} = $1;
    }
}
close(MEMORY);

if ($gangliafile) {
    open(GANGLIA, "<", $gangliafile) or $LOGGER->logdie("$! ($gangliafile)");

    my $RAMSize=0;
    my $SMPSize=0;


    my $HostUniqueID;
    while(<GANGLIA>) {
        chomp;

        if ($_=~/^GlueClusterUniqueID: (\S+.*\S?)/) {
            $info{'Cluster'}->{'UniqueID'} = $1;
        }
        elsif ($_=~/^GlueHostUniqueID: (\S+.*\S?)/) {
            $info{'Cluster'}->{'Node'}->{$1}->{'HostUniqueID'} = $1;
            $HostUniqueID=$1;
        }
        elsif ($_=~/^GlueHostArchitecturePlatformType: (\S+.*\S?)/) {
            $info{'Cluster'}->{'Node'}->{$HostUniqueID}->{'HostArchitecturePlatformType'} = $1;
        }
        elsif ($_=~/^GlueHostArchitectureSMPSize: (\S+.*\S?)/) {
            $info{'Cluster'}->{'Node'}->{$HostUniqueID}->{'HostArchitectureSMPSize'} = $1;
            $SMPSize+=$1;
        }
        elsif ($_=~/^GlueHostProcessorClockSpeed: (\S+.*\S?)/) {
            $info{'Cluster'}->{'Node'}->{$HostUniqueID}->{'HostProcessorClockSpeed'} = $1." Mhz"; # Mhz
        }
        elsif ($_=~/^GlueHostMainMemoryRAMSize: (\S+.*\S?)/) {
            $info{'Cluster'}->{'Node'}->{$HostUniqueID}->{'HostMainMemoryRAMSize'}=sprintf("%.2f",$1*2**-20); # GB
            $RAMSize+=$1
        }
        elsif ($_=~/^GlueHostNetworkAdapterName: (\S+.*\S?)/) {
            $info{'Cluster'}->{'Node'}->{$HostUniqueID}->{'HostNetworkAdapterName'} = $1;
        }
        elsif ($_=~/^GlueHostNetworkAdapterIPAddress: (\S+.*\S?)/) {
            $info{'Cluster'}->{'Node'}->{$HostUniqueID}->{'HostNetworkAdapterIPAddress'} = $1;
        }
    }
    close(GANGLIA);

    $info{'Cluster'}->{'SMPSize'} = $SMPSize;
    $info{'Cluster'}->{'RAMSize'} = sprintf("%.2f",$RAMSize*2**-20); # GB

}

my $spacer='';
if ($info{'Cluster'}) {
print $spacer."Cluster Unique ID......................: ".($info{'Cluster'}->{'UniqueID'}||'NA')."\n";
print $spacer."Total Symmetric Multi-Processing Size..: ".($info{'Cluster'}->{'SMPSize'}||'NA')."\n";
print $spacer."Total Main Memory (RAM) Size...........: ".($info{'Cluster'}->{'RAMSize'}||'NA')."\n";
print $spacer."Front-end\n";
$spacer=' ';
}
print $spacer."Host..................................: ".($info{'Hostname'}->{''}||'NA')."\n";
print $spacer."IP....................................: ".($info{'IP'}->{''}||'NA')."\n";
print $spacer."Operational System....................: ".($info{'OS'}->{''}||'NA')."\n";
print $spacer."Architecture Platform Type............: ".($info{'HP'}->{''}||'NA')."\n";
print $spacer."System\n";
print $spacer." Manufacturer.........................: ".($info{'System'}->{'Manufacturer'}||'NA')."\n";
print $spacer." Product Name.........................: ".($info{'System'}->{'Product Name'}||'NA')."\n";
print $spacer."Chassis\n";
print $spacer." Manufacturer.........................: ".($info{'Chassis'}->{'Manufacturer'}||'NA')."\n";
print $spacer." Type.................................: ".($info{'Chassis'}->{'Type'}||'NA')."\n";
print $spacer." Number Of Power Cords................: ".($info{'Chassis'}->{'Number Of Power Cords'}||'NA')."\n";
print $spacer."Processor(s)"." (".scalar(keys %{ $info{'Processor'} }).")\n";
foreach my $k (keys %{ $info{'Processor'} }) {
print $spacer." Socket Designation...................: ".($info{'Processor'}->{$k}->{'Socket Designation'}||'NA')."\n";
print $spacer."  Type................................: ".($info{'Processor'}->{$k}->{'Type'}||'NA')."\n";
print $spacer."  Family..............................: ".($info{'Processor'}->{$k}->{'Family'}||'NA')."\n";
print $spacer."  Family..............................: ".($info{'Processor'}->{$k}->{'Manufacturer'}||'NA')."\n";
print $spacer."  Version.............................: ".($info{'Processor'}->{$k}->{'Version'}||'NA')."\n";
print $spacer."  Current Speed.......................: ".($info{'Processor'}->{$k}->{'Current Speed'}||'NA')."\n";
print $spacer."  Core Count..........................: ".($info{'Processor'}->{$k}->{'Core Count'}||'NA')."\n";
print $spacer."  Core Enabled........................: ".($info{'Processor'}->{$k}->{'Core Enabled'}||'NA')."\n";
print $spacer."  Thread Count........................: ".($info{'Processor'}->{$k}->{'Thread Count'}||'NA')."\n";
}
print $spacer."Processor(s) Cache(s)"." (".scalar(keys %{ $info{'Cache'} }).")\n";
foreach my $k (keys %{ $info{'Cache'} }) {
print $spacer." Handle...............................: ".($info{'Cache'}->{$k}->{'Handle'}||'NA')."\n";
print $spacer."  Socket Designation..................: ".($info{'Cache'}->{$k}->{'Socket Designation'}||'NA')."\n";
print $spacer."  Configuration.......................: ".($info{'Cache'}->{$k}->{'Configuration'}||'NA')."\n";
print $spacer."  Installed Size......................: ".($info{'Cache'}->{$k}->{'Installed Size'}||'NA')."\n";
print $spacer."  Installed SRAM Type.................: ".($info{'Cache'}->{$k}->{'Installed SRAM Type'}||'NA')."\n";
}
print $spacer."Memory\n";
print $spacer." Maximum Capacity.....................: ".(($memorytotal) ? ($memorytotal/1024)." G" : 'NA')."\n";
print $spacer." Memory Available.....................: ".(($memoryaval) ? ($memoryaval/1024)." G" : 'NA')."\n";
print $spacer." Memory Usable........................: ".(($memoryusab) ? sprintf("%.2f", ($memoryusab*2**-30))." G" : 'NA')."\n";
print $spacer." Physical Memory Array(s)"." (".scalar(keys %{ $info{'Memory'} }).")\n";
foreach my $arr (keys %{ $info{'Memory'} }) {
print $spacer."  Handle..............................: ".($info{'Memory'}->{$arr}->{$arr}->{'Handle'}||'NA')."\n";
print $spacer."  Maximum Capacity....................: ".($info{'Memory'}->{$arr}->{$arr}->{'Maximum Capacity'}||'NA')."\n";
print $spacer."  Memory Device(s)"." (".(scalar(keys %{ $info{'Memory'}->{$arr} })-1).")\n";
foreach my $k (keys %{ $info{'Memory'}->{$arr} }) {
    next if ($arr eq $k);
print $spacer."   Handle.............................: ".($info{'Memory'}->{$arr}->{$k}->{'Handle'}||'NA')."\n";
print $spacer."    Size..............................: ".($info{'Memory'}->{$arr}->{$k}->{'Size'}||'NA')."\n";
print $spacer."    Form Factor.......................: ".($info{'Memory'}->{$arr}->{$k}->{'Form Factor'}||'NA')."\n";
print $spacer."    Type..............................: ".($info{'Memory'}->{$arr}->{$k}->{'Type'}||'NA')."\n";
print $spacer."    Speed.............................: ".($info{'Memory'}->{$arr}->{$k}->{'Speed'}||'NA')."\n";
}
}
print $spacer."Data storage"." (".scalar(keys %{$info{'Storage'}}).")\n";
foreach my $d (keys %{$info{'Storage'}}) {
print $spacer." Disk.................................: ".($info{'Storage'}->{$d}->{'disk'}||'NA')."\n";
print $spacer." Model................................: ".($info{'Storage'}->{$d}->{'model'}||'NA')."\n";
print $spacer." Size.................................: ".($info{'Storage'}->{$d}->{'size'}||'NA')."\n";
print $spacer." Sector Size (logical/physical).......: ".($info{'Storage'}->{$d}->{'Sector Size'}||'NA')."\n";
print $spacer." Partition Table......................: ".($info{'Storage'}->{$d}->{'Partition Table'}||'NA')."\n";
foreach my $p (sort { $a <=> $b } keys %{$info{'Storage'}->{$d}->{'partition'}}) {
print $spacer."  Partition...........................: ".($p||'NA')."\n";
print $spacer."   Size...............................: ".($info{'Storage'}->{$d}->{'partition'}->{$p}->{'size'}||'NA')."\n";
print $spacer."   File System........................: ".($info{'Storage'}->{$d}->{'partition'}->{$p}->{'fstype'}||'NA')."\n";
print $spacer."   Mount Point........................: ".($info{'Storage'}->{$d}->{'partition'}->{$p}->{'mounted'}||'NA')."\n";
}
}
if ($info{'Cluster'}) {
print $spacer."Cluster Node(s)"." (".scalar(keys %{$info{'Cluster'}->{'Node'}}).")\n";
foreach my $d (keys %{$info{'Cluster'}->{'Node'}}) {
print $spacer." Host Unique ID.......................: ".($info{'Cluster'}->{'Node'}->{$d}->{'HostUniqueID'}||'NA')."\n";
print $spacer."  Architecture Platform Type..........: ".($info{'Cluster'}->{'Node'}->{$d}->{'HostArchitecturePlatformType'}||'NA')."\n";
print $spacer."  Symmetric Multi-Processing Size.....: ".($info{'Cluster'}->{'Node'}->{$d}->{'HostArchitectureSMPSize'}||'NA')."\n";
print $spacer."  Current Speed.......................: ".($info{'Cluster'}->{'Node'}->{$d}->{'HostProcessorClockSpeed'}||'NA')."\n";
print $spacer."  Main Memory (RAM) Size..............: ".($info{'Cluster'}->{'Node'}->{$d}->{'HostMainMemoryRAMSize'}||'NA')."\n";
print $spacer."  Network Adapter Name................: ".($info{'Cluster'}->{'Node'}->{$d}->{'HostNetworkAdapterName'}||'NA')."\n";
print $spacer."  Network Adapter IP Address..........: ".($info{'Cluster'}->{'Node'}->{$d}->{'HostNetworkAdapterIPAddress'}||'NA')."\n";
}
}


# Subroutines

sub Usage {
    my ($msg) = @_;
	Readonly my $USAGE => <<"END_USAGE";
Daniel Guariz Pinheiro (dgpinheiro\@gmail.com)
(c)2012 Universidade de São Paulo

Usage

        $0	[-h/--help] [-l/--level <LEVEL>]

Argument(s)

        -h      --help      Help
        -l      --level     Log level [Default: FATAL]
        -t      --hostname  Hostname file
        -a      --arch      Archtecture file
        -o      --os        OS file
        -i      --ip        IP file
        -s      --system    "dmidecode --type system" file
        -c      --chassis   "dmidecode --type chassis" file 
        -p      --processor "dmidecode --type processor" file 
        -e      --cache     "dmidecode --type cache" file 
        -m      --memory    "dmidecode --type memory" file
        -d      --df        "df -vh" file
        -f      --free      "free -m" file
        -r      --parted    "parted -l -s" file
        -g      --ganglia   "ganglia --format=MDS --select=All" file

END_USAGE
    print STDERR "\nERR: $msg\n\n" if $msg;
    print STDERR qq[$0  ] . q[$Revision$] . qq[\n];
	print STDERR $USAGE;
    exit(1);
}

