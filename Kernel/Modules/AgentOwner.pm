# --
# Kernel/Modules/AgentOwner.pm - to set the ticket owner
# Copyright (C) 2002 Martin Edenhofer <martin+code@otrs.org>
# --
# $Id: AgentOwner.pm,v 1.6 2002-08-01 02:37:36 martin Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see http://www.gnu.org/licenses/gpl.txt.
# --

package Kernel::Modules::AgentOwner;

use strict;
use Kernel::System::Group;

use vars qw($VERSION);
$VERSION = '$Revision: 1.6 $';
$VERSION =~ s/^.*:\s(\d+\.\d+)\s.*$/$1/;

# --
sub new {
    my $Type = shift;
    my %Param = @_;
   
    # allocate new hash for object 
    my $Self = {}; 
    bless ($Self, $Type);
    
    foreach (keys %Param) {
        $Self->{$_} = $Param{$_};
    }

    # check needed Opjects
    foreach (
      'ParamObject', 
      'DBObject', 
      'TicketObject', 
      'LayoutObject', 
      'LogObject', 
      'ConfigObject',
      'UserObject',
    ) {
        die "Got no $_!" if (!$Self->{$_});
    }
   
    # get  NewUserID
    $Self->{NewUserID} = $Self->{ParamObject}->GetParam(Param => 'NewUserID') || '';

    $Self->{GroupObject} = Kernel::System::Group->new(%Param);

    return $Self;
}
# --
sub Run {
    my $Self = shift;
    my %Param = @_;
    my $Output;
    my $TicketID = $Self->{TicketID};
    my $QueueID = $Self->{QueueID};
    my $Subaction = $Self->{Subaction};
    my $NextScreen = $Self->{NextScreen} || '';
    my $BackScreen = $Self->{BackScreen};
    my $UserID    = $Self->{UserID};

    if ($Subaction eq 'Update') {
        # --
		# set user id
        # --
        if ($Self->{TicketObject}->SetOwner(
			TicketID => $TicketID,
			UserID => $Self->{UserID},
            NewUserID => $Self->{NewUserID},
		)) {
          # --
          # redirect
          # --
          return $Self->{LayoutObject}->Redirect(OP => $Self->{LastScreen});
        }
        else {
          $Output = $Self->{LayoutObject}->Header(Title => "Error");
          $Output .= $Self->{LayoutObject}->Error();
          $Output .= $Self->{LayoutObject}->Footer();
          return $Output;
        }
    }
    else {
        # --
        # print form
        # --
        my $Tn = $Self->{TicketObject}->GetTNOfId(ID => $TicketID);
        my $OwnerID = $Self->{TicketObject}->CheckOwner(TicketID => $TicketID);
        $Output .= $Self->{LayoutObject}->Header(Title => 'Set Owner');
        my %LockedData = $Self->{UserObject}->GetLockedCount(UserID => $UserID);
        $Output .= $Self->{LayoutObject}->NavigationBar(LockData => \%LockedData);
        # --
        # get user of own groups
        # --
        my %AllGroupsMembers = ();
        if ($Self->{ConfigObject}->Get('ChangeOwnerToEveryone')) {
            %AllGroupsMembers = $Self->{UserObject}->UserList();
        }
        else {
            my %Groups = $Self->{UserObject}->GetGroups(UserID => $Self->{UserID});
            foreach (keys %Groups) {
                my %MemberList = $Self->{GroupObject}->MemberList(GroupID => $_);
                foreach (keys %MemberList) {
                    $AllGroupsMembers{$_} = $MemberList{$_};
                }
            }
        }
        # --
        # print change form
        # --
	    $Output .= $Self->{LayoutObject}->AgentOwner(
            OptionStrg => \%AllGroupsMembers,
 			TicketID => $TicketID,
            OwnerID => $OwnerID,
            BackScreen => $Self->{BackScreen},
            NextScreen => $Self->{NextScreen},
            TicketNumber => $Tn,
            QueueID => $QueueID,
        );
        $Output .= $Self->{LayoutObject}->Footer();
    }
    return $Output;
}
# --

1;
