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

#use Net::SSH::Perl;
use Net::SSH::Expect;
use Term::ReadKey;
use Net::IP;

use vars qw/$LOGGER/;

INIT {
    use Log::Log4perl qw/:easy/;
    Log::Log4perl->easy_init($FATAL);
    $LOGGER = Log::Log4perl->get_logger($0);
}

my ($level, $ipdef, %cmdh, $outdir, $prefix, $auxfile, $user, $password, $expectpasswd);

my ($default_login_output);
Usage("Too few arguments") if $#ARGV < 0;
GetOptions( "h|?|help" => sub { &Usage(); },
            "l|level=s"=> \$level,
            "i|ip=s"=>\$ipdef,
            "c|command=s%"=>\%cmdh,
            "o|outdir=s"=>\$outdir,
            "p|prefix=s"=>\$prefix,
            "a|auxfile=s"=>\$auxfile,
            "u|user=s"=>\$user,
            "e|expectpasswd"=>\$expectpasswd,
            "n|loginout=s"=>\$default_login_output
    ) or &Usage();

$prefix||='info_';
$outdir||='.';
$default_login_output||='Welcome';

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

$LOGGER->logdie("Missing ip definition") unless ($ipdef);
$LOGGER->logdie("Missing command to execute") unless (scalar(keys %cmdh));

unless (-d $outdir) {
    $LOGGER->logdie("Wrong output directory ($outdir)") unless (-d $outdir);
}

my %AUTH;
if ($auxfile) {
    $LOGGER->logdie("Wrong auxiliary file ($auxfile)") unless (-e $auxfile);
    open(AUX, "<", $auxfile) or $LOGGER->logdie($!);
    while (<AUX>) {
        chomp;
        my ($i, $u, $p) = split(/\t/, $_);
        $AUTH{$i} = {'user'=>$u, 'password'=>$p};
    }
    close(AUX);
} 
else {
    $LOGGER->logdie("Missing user") unless ($user);
    print "Please input your password: ";                                                                                                                                                                        
    ReadMode(4); #Disable the control keys
    my $key = 0;
    $password = '';
    while(ord($key = ReadKey(0)) != 10)                                                                                     # This will continue until the Enter key is pressed (decimal value of 10)
    {
        # For all value of ord($key) see http://www.asciitable.com/
        if(ord($key) == 127 || ord($key) == 8) {
            # DEL/Backspace was pressed
            #1. Remove the last char from the password
            chop($password);
            #2 move the cursor back by one, print a blank character, move the cursor back by one
            print "\b \b";
        } elsif(ord($key) < 32) {
            # Do nothing with these control characters   
        } else {
            $password.=$key;
            print "*";
        }
    }
    ReadMode(0); #Reset the terminal once we are done
    print "\n";
    #print "\n\nYour super secret password is: $password\n";
    $AUTH{'*'} = { 'user'=>$user, 'password'=>$password };
}

$ipdef=~s/\s//g;
foreach my $ipd ( split(',', $ipdef) ) {

    my $ip = Net::IP->new($ipd) or $LOGGER->logdie("Invalid IP definition ($ipd) $!");

    do {
        $LOGGER->logdie("Not found authentication for ".$ip->ip()."\n") unless ((exists $AUTH{$ip})||(exists $AUTH{'*'}));
        print $ip->ip(), "\n";
        #my $ssh = Net::SSH::Perl->new($ip->ip());



        my ($u, $p) = ((exists $AUTH{$ip}) ? @{$AUTH{$ip}}{'user','password'} : @{$AUTH{'*'}}{'user','password'});
        
        #$ssh->login($u, $p);
        my $ssh = Net::SSH::Expect->new (
            host => $ip->ip(), 
            password=> $p, 
            user => $u, 
            raw_pty => 1,
            exp_debug=>0,
            restart_timeout_upon_receive=>1,
            timeout=>5
        );
        my $login_output = $ssh->login();
        if ($login_output !~ /$default_login_output/) {
            $LOGGER->logdie("Login has failed. Login output was $login_output");
        }
        foreach my $k (keys %cmdh) {
            my $cmd = $cmdh{$k};
            $ssh->exec("stty raw -echo");
            #my ($stdout,$stderr) = $ssh->exec("$cmd");
            my ($stdout,$stderr,$exit);

            $ssh->send("$cmd");   # using send() instead of exec()
            if ($expectpasswd) {
                my $rwait = $ssh->waitfor('password for '.$user.':\s*\z', 1);
                if ($rwait) {
                    $ssh->send($password);
                }
                else {
                    $LOGGER->logwarn("prompt 'password' not found after 1 second");
                }                
            }
            my $line;
            # returns the next line, removing it from the input stream:
            while ( defined ($line = $ssh->read_line()) ) {
                chomp($line);
                if ($line) {
                    $stdout.=$line . "\n";  
                }
            }
            #($stdout, $stderr, $exit) = $ssh->cmd($cmd);
                    
            if ($stdout) {
                open(OUT, ">", $outdir.'/'.$prefix.$ip->ip().'_'.$k.'_stdout.txt') or $LOGGER->logdie($!);
                print OUT $stdout;
                close(OUT);
            }
            if ($stderr) {    
                open(ERR, ">", $outdir.'/'.$prefix.$ip->ip().'_'.$k.'_stderr.txt') or $LOGGER->logdie($!);
                print ERR $stderr;
                close(ERR);
            }
        }            
        $ssh->close();
    } while ( ++$ip );
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

        -h      --help          Help
        -l      --level         Log level [Default: FATAL]
        -i      --ip            IP list (c.f. Net::IP - comma separated elements)
        -c      --command       Remote command
        -o      --outdir        Output directory (default: .)
        -p      --prefix        Prefix (default: info_)
        -a      --auxfile       Auxiliary file (IP<TAB>USER<TAB>PASSWORD)
        -u      --user          Common user
        -e      --expectpasswd  Command expect password
        -n      --loginout      Default login output

END_USAGE
    print STDERR "\nERR: $msg\n\n" if $msg;
    print STDERR qq[$0  ] . q[$Revision$] . qq[\n];
	print STDERR $USAGE;
    exit(1);
}

