#!/usr/bin/perl
#Anthony G. Persaud

use strict;
use Nmap::Parser 1.00;
use Getopt::Long;
use File::Spec;
use Pod::Usage;
use vars qw(%G);


$G{nmap_exe} = find_exe();

my $np = new Nmap::Parser;

print "\nscan.pl - ( http://nmapparser.wordpress.com )\n",
	('-'x80),"\n\n";
        
        
GetOptions(
		'help|h|?'		=> \$G{helpme},
                'nmap=s'                => \$G{nmap},
                'xml=s'			=> \$G{file}
) or (pod2usage(-exitstatus => 0, -verbose => 2));


$np->callback(\&host_handler);

if(-e $G{file}){
	print "Parsing file: ".$G{file}."\n\n";
	$np->parsefile($G{file});
} elsif($G{nmap} && scalar @ARGV)
{	
	print "Using nmap exe: ".$G{nmap}."\n\n";
	$np->parsescan($G{nmap},'-sVU -O -F --randomize_hosts',@ARGV);
} else 
	{pod2usage(-exitstatus => 0, -verbose => 2)}

sub host_handler {
    my $host = shift;
    print ' > '.$host->ipv4_addr."\n";
    print "\t[+] Status: (".uc($host->status).")\n";
    if($host->status eq 'up'){

        tab_print("Hostname(s)",$host->all_hostnames());
	tab_print("Uptime",($host->uptime_seconds())." seconds") if($host->uptime_seconds());
	tab_print("Last Rebooted",$host->uptime_lastboot()) if($host->uptime_lastboot);
        os_sig_print($host);
        port_service_print($host);
    }
    
print "\n\n";
	
}

sub os_sig_print {
	my $host = shift;	
	my $os = $host->os_sig();
	print "\t[+] OS Names :\n" if($os->name_count > 0);
	for my $name ($os->all_names()){print "\t\t$name\n";}
	
	if($os->class_count > 0){
	print "\t[+] OS Classes :\n"; 
	printf("\t\t%-16s %10s (%8s) [%3s] {%2s}\n", 'TYPE','VENDOR','OSFAMILY','VERSION','ACCURACY');
	print "\t\t".('-'x60)."\n";
	
	for (my $i = 0; $i < $os->class_count() ; $i++)
	{printf("\t\t%-16s %10s (%8s) [%7s] %4s%%\n", $os->type($i),$os->vendor($i),$os->osfamily($i),$os->osgen($i),$os->class_accuracy($i));}
	}
}


sub port_service_print {
        my $host = shift;
	print "\t[+] TCP Ports :\n" if($host->tcp_port_count);
	printf("\t\t%-6s %-10s (%-14s) [%-8s] %s\n", 'PORT','SERVICE','PRODUCT','VERSION','EXTRA');
	print "\t\t".('-'x60)."\n";
        
	for my $port ($host->tcp_open_ports){
            my $svc = $host->tcp_service($port);
            
	printf("\t\t%-6s %-10s (%-14s) [%-8s] %s\n",
			$port,
			$svc->name,
			$svc->product,
			$svc->version,
			$svc->extrainfo);
	}

	print "\t[+] UDP Ports :\n" if($host->udp_port_count);
	for my $port ($host->udp_open_ports){
	    my $svc = $host->udp_service($port);
            
        printf("\t\t%-6s %-10s (%-14s) [%-8s] %s\n", 'PORT','SERVICE','PRODUCT','VERSION','EXTRA');
	print "\t\t".('-'x60)."\n";
	
	printf("\t\t%-6s %-10s (%-14s) [%-8s] %s\n",
			$port,
			$svc->name,
			$svc->product,
			$svc->version,
			$svc->extrainfo);
	}
}

sub tab_print {
    my $title = shift;
    print "\t[+] $title :\n";
    for my $a (@_)
    {print "\t\t$a\n";}
    
}

sub find_exe {


    my $exe_to_find = 'nmap';
    $exe_to_find =~ s/\.exe//;
    local($_);
    local(*DIR);

    for my $dir (File::Spec->path()) {
        opendir(DIR,$dir) || next;
        my @files = (readdir(DIR));
        closedir(DIR);

        my $path;
        for my $file (@files) {
            $file =~ s/\.exe$//;
            next unless($file eq $exe_to_find);

            $path = File::Spec->catfile($dir,$file);
            next unless -r $path && (-x _ || -l _);

            return $path;
            last DIR;
        }
    }

}

__END__
=pod

=head1 NAME

scan - a scanning script to gather port and OS information from hosts

=head1 SYNOPSIS

 scan.pl [--nmap <NMAP_EXE>] <IP_ADDR> [<IP.ADDR> ...]
 scan.pl --xml <SCAN.XML>


=head1 DESCRIPTION

This script uses the nmap security scanner with the Nmap::Parser module
in order to run quick scans against specific hosts, and gather all the
information that is required to know about that specific host which nmap can
figure out. This script can be used for quick audits against machines on the
network and an educational use for learning how to write scripts using the
Nmap::Parser module. B<This script uses the -sV output to get version
information of the services running on a machine. This requires nmap version
3.49+>

=head1 OPTIONS

These options are passed as command line parameters.

=over 4

=item B<--nmap>

The path to the nmap executable. This should be used if nmap is not on your path.

=item B<-h,--help,-?>

Shows this help information.

=item B<--xml>

Processes the given nmap xml scan file. This file is usually generated by using the '-oX filename.xml'
command line parameter with nmap.

=back 4

=head1 TARGET SPECIFICATION

This documentation was taken from the nmap man page. The IP address inputs
to this scripts should be in the nmap target specification format.

The  simplest  case is listing single hostnames or IP addresses onthe command
line. If you want to scan a subnet of  IP addresses, you can append '/mask' to
the hostname or IP address. mask must be between 0 (scan the whole internet) and
 32 (scan the single host specified). Use /24 to scan a class 'C' address and
 /16 for a class 'B'.

You can use a more powerful notation which lets you specify an IP address
using lists/ranges for each element. Thus you can scan the whole class 'B'
network 128.210.*.* by specifying '128.210.*.*' or '128.210.0-255.0-255' or
even use the mask notation: '128.210.0.0/16'. These are all equivalent.
If you use asterisks ('*'), remember that most shells require you to escape
them with  back  slashes or protect them with quotes.

Another interesting thing to do is slice the Internet the other way.

Examples:

 scan.pl 127.0.0.1
 scan.pl target.example.com
 scan.pl target.example.com/24
 scan.pl 10.210.*.1-127
 scan.pl *.*.2.3-5
 scan.pl 10.[10-15].10.[2-254]


=head1 OUTPUT EXAMPLE

These are ONLY examples of how the output would look like. Not the specs to my machine

 Scan Host
 --------------------------------------------------
 [>] 127.0.0.1
        [+] Status: (UP)
        [+] Hostname(s) :
                host1
                host1_2
        [+] Uptime :
                1973 seconds
        [+] Last Rebooted :
                Tue Jul  1 14:15:27 2003
        [+] OS Names :
                Linux Kernel 2.4.0 - 2.5.20
                Solaris 9
        [+] OS Classes :
                TYPE                 VENDOR (OSFAMILY) [VERSION] {ACCURACY}
                ------------------------------------------------------------
                router              Redback (     AOS) [       ]   97%
                broadband router    Thomson (embedded) [       ]   97%
                switch                 Fore (embedded) [       ]   92%
                printer               Xerox (embedded) [       ]   91%
                broadband router    Redback (embedded) [       ]   90%
                firewall          SonicWall (embedded) [       ]   90%
                switch            Enterasys (embedded) [       ]   90%
                WAP                   Cisco (embedded) [       ]   90%
                broadband router    Alcatel (embedded) [       ]   90%
                general purpose         Sun (   SunOS) [       ]   90%
                general purpose       Linux (   Linux) [  2.4.x]   50%
        [+] TCP Ports :
                PORT   SERVICE    (PRODUCT       ) [VERSION ] EXTRA
                ------------------------------------------------------------
                21     ftp        (ProFTPD       ) [1.2.5rc1]
                22     ssh        (OpenSSH       ) [3.4p1   ] protocol 1.99
                25     smtp       (Exim smtpd    ) [3.35    ]
                26     ssh        (OpenSSH       ) [3.6.1p1 ] protocol 1.99
                112    rpcbind    (              ) [2       ]
                113    ident      (OpenBSD identd) [        ]
                953    rndc       (              ) [        ]
        [+] UDP Ports :
                PORT   SERVICE    (PRODUCT       ) [VERSION ] EXTRA
                ------------------------------------------------------------
                80     http       (Apache httpd  ) [1.3.26  ] (Unix) Debian GNU/Linux


=head1 SUPPORT

=head2 Discussion Forum

If you have questions about how to use the module, or any of its features, you
can post messages to the Nmap::Parser module forum on CPAN::Forum.
L<http://www.cpanforum.com/dist/Nmap-Parser>

=head2 Bug Reports

Please submit any bugs to:
L<http://sourceforge.net/tracker/?group_id=97509&atid=618345>

B<Please make sure that you submit the xml-output file of the scan which you are having
trouble.> This can be done by running your scan with the I<-oX filename.xml> nmap switch.
Please remove any important IP addresses for security reasons.

=head2 Feature Requests

Please submit any requests to:
L<http://sourceforge.net/tracker/?atid=618348&group_id=97509&func=browse>

=head1 SEE ALSO

L<Nmap::Parser>

The Nmap::Parser page can be found at: L<http://nmapparser.wordpress.com> or L<http://npx.sourceforge.net>.
It contains the latest developments on the module. The nmap security scanner
homepage can be found at: L<http://www.insecure.org/nmap/>.

=head1 AUTHOR

Anthony G Persaud L<http://www.anthonypersaud.com>

=head1 COPYRIGHT

MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

=cut
