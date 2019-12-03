# Copyright © 2009-2013 Bernhard M. Wiedemann
# Copyright © 2012-2015 SUSE LLC
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, see <http://www.gnu.org/licenses/>.

package consoles::sshXtermVt;

use strict;
use warnings;
use autodie ':all';

use base 'consoles::localXvnc';

use testapi 'get_var';
require IPC::System::Simple;
use Net::Ping;

sub activate {
    my ($self) = @_;

    # start Xvnc
    $self->SUPER::activate;

    my $testapi_console = $self->{testapi_console};
    my $ssh_args        = $self->{args};
    my $gui             = $self->{args}->{gui};

    # Wait that SUT is live on network (for generalhw/ssh)
    my $p       = Net::Ping->new();
    my $counter = get_var('SSH_XTERM_WAIT_SUT_ALIVE_TIMEOUT') // 120;
    while ($counter > 0) {
        last if ($p->ping($ssh_args->{hostname}));
        sleep(1);
        $counter--;
    }
    $p->close();
    bmwqemu::diag("$ssh_args->{hostname} does not seems to be alive. Continuing anyway.\n") if ($counter == 0);

    my $hostname = $ssh_args->{hostname} || die('we need a hostname to ssh to');
    my $password = $ssh_args->{password} || $testapi::password;
    my $username = $ssh_args->{username} || 'root';
    my $sshcommand = $self->sshCommand($username, $hostname, $gui);
    my $serial     = $self->{args}->{serial};

    $self->callxterm($sshcommand, "ssh:$testapi_console");

    if ($serial) {

        # ssh connection to SUT for iucvconn
        my ($ssh, $serialchan) = $self->backend->start_ssh_serial(
            hostname => $hostname,
            password => $password,
            username => 'root'
        );

        # start iucvconn
        bmwqemu::diag('ssh xterm vt: grabbing serial console');
        $ssh->blocking(1);
        if (!$serialchan->exec($serial)) {
            bmwqemu::diag('ssh xterm vt: unable to grab serial console at this point: ' . ($ssh->error // 'unknown SSH error'));
        }
        $ssh->blocking(0);
    }
}

# to be called on reconnect
sub kill_ssh {
    my ($self) = @_;

    $self->backend->stop_ssh_serial;
}

1;
