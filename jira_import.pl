#!/usr/bin/env perl

=head1 NAME

jira_import - Import timesheet to JIRA

=head1 SYNOPSIS

    jira_import -f my_timesheet.tsv -e my_timesheet_errors.tsv \
        -m MY_INSTANCE.atlassian.net [-u username -p password]

    # Create timesheet file
    perl -e 'print "2\t1.25\tABC-1234\tDO-123-MP\tDid some work.\tJoe Producer\n"' > \
        /tmp/timesheet.tsv
    jira_import -f /tmp/timesheet.tsv -m MY_INSTANCE.atlassian.net

    # Store your username and password for convenience
    # Note: to get your JIRA username, log into JIRA in a browser, click
    # your profile picture, and select Profile.  Your username is on the
    # left side. The API username is *not* the same username you use to
    # log into the web site.
    echo "MY_INSTANCE.atlassian.net login USERNAME password PASSWORD" > \
        ~/.netrc ; chmod 600 ~/.netrc

Really, you'll copy from Excel, Google Sheets, etc, paste into a file,
then jira_import -f filename -m MY_INSTANCE.atlassian.net

=head1 DESCRIPTION

jira_import reads a tab-delimited file containing timesheet entries and submits
"worklog" entries using the JIRA API for each row that contains a
JIRA issue code.

If an error is encountered while writing a line (e.g. a task isn't found),
the line will be written to error_file.  This file can then be re-run
through jira_import later to import the missing entries.

=head1 OPTIONS

=over

=item -f <filename>, --file=<filename>

The input file from which to read entries.  Must be in the following format
(but not all fields are required):

  Day  Hours  JIRA Code  Task  Note  Producer

Task and Producer are *ignored* by jira_import.  They exist to be
compatible with another system.  You can ignore them, or you can submit
a pull request with a version that allows you to not provide these
fields. :)

Day is optional and defaults to today if not provided.  If it is provided, it
must be either an integer between 1 and 7, inclusive, where 1 is Sunday, 2 is
Monday, ... and 7 is Saturday, or a date in any format that Date::Manip's
ParseDate function can handle.  The odd 1-7 day numbering is for compatibility
with the aforementioned "other system".

ParseDate can handle many date formats (which are not well documented),
including "today", "yesterday", "Dec 10, 1997", and "10/23/17".

Stick with mm/dd/yy or mm/dd/yyyy or yyyy-mm-dd and you'll be fine.

=item -m <machine_name>, --machine=<machine_name>, --instance=<machine_name>

The domain name of the JIRA instance you're connecting to.  This is used both
to look up your username and password in .netrc and to connect to the
JIRA instance.  jira_import will connect to https://machine_name/.

Example:

    jira_import -f ~/timesheet.tsv -m myjira.atlassian.net

    # In ~/.netrc
    machine myjira.atlassian.net login myusername password mypassword

=item -e <filename>, --error_file=<filename>

If specified, for any lines in the input file that an exception is thrown while
processing, the line will be written to filename.  Any error text from
the exception will be sent to STDERR, so you should see it clearly.

Note that this script will exit with a 0 exit code even if an exception
was thrown while processing.  The error file is your only indication that
an entry failed, and you can (and should) attempt to re-run jira_import
on the error file after fixing any errors.

If not specified, the error file will be the input filename with "_failed"
appended.  This can produce odd filenames, e.g. "my_timesheet.txt_failed".
Specify an error file explicitly to avoid that.

=item -u <username>, --username=<username>

The username that shows up in your user profile in JIRA.  This is *not*
the username with which you log in via the web interface.

This is here for testing and completeness.  You should use C<~/.netrc> instead,
if for no other reason than because you'll need to include your password
on the command line if you use C<-u>.

If you use this option, you must pass your password with the C<-p/--password>
option.  If you don't include a password, your username will be ignored and
C<jira_import> will fall back to using C<~/.netrc>.

=item -p <password>, --password=<password>

The password you use to log into JIRA.  This is the same password with which
you log into the web interface.

This is here for testing and completeness.  You should use C<~/.netrc> instead,
because by using this option your password will appear on the command line,
in your shell's history, and probably other places (e.g. terminal window
scrollback, key logging software, etc).

If you don't specify both a username and a password, C<jira_import> will
ignore both options and use C<~/.netrc>.

=back

=cut

use strict;
use 5.006;
use Try::Tiny;

use Getopt::Long;
use Pod::Usage;
use JIRA::REST;
use Date::Manip::Date; # qw(ParseDate UnixDate);

# Debugging aids
#use Smart::Comments qw{### }; # Progress level
#use Smart::Comments qw{### ####}; # Debugging level - adds checks and requires
#use Smart::Comments qw{### #### #####}; # Verbose debugging level
use JSON;

# Performance
use Memoize;

# Only fetch billing codes once per issue
memoize 'fetch_billing_code';

# Only convert a date or day into DateTime once
memoize 'convert_day_to_date';

my $USAGE_ARGS = { -verbose => 0, -exitval => 1 };

# --tempo is (currently) an undocumented option that is only useful for me and
# a few people I work with. It logs time in Tempo and fills in a couple custom
# fields, that, due to their tendancy to change, isn't worth making into a
# full-fledged customizable option.

my (
    $import_file, $error_file, $machine_name, $username,
    $password,    $tempo,      $use_dates
);
GetOptions(
    'file|f=s'             => \$import_file,
    'error_file|e:s'       => \$error_file,
    'machine|m|instance=s' => \$machine_name,
    'username|u:s'         => \$username,
    'password|p:s'         => \$password,
    'tempo|t'              => \$tempo,
    'use_dates|d'          => \$use_dates,
) or pod2usage($USAGE_ARGS);

die pod2usage($USAGE_ARGS) unless ( $import_file && $machine_name );
die "username required with --tempo to set its 'author' field, sorry."
  if ( $tempo && !$username );

$error_file = "${import_file}_failed" unless $error_file;

######################################################################
# Main Program

open my $import_file_handle, "<", $import_file
  or die "Couldn't open $import_file for reading";

open my $error_file_handle, ">", $error_file
  or die "Couldn't open $error_file for writing";

# Remove domain name in case people can't read directions.
$machine_name =~ s/http(s)?:\/\///;
$machine_name =~ s/\/$//;

my $jira_instance = "https://$machine_name/";

# Get a JIRA::REST object (logged-in or able to log in)
my $jira;
if ( $username && $password ) {
    $jira = JIRA::REST->new( $jira_instance, $username, $password );
}
else {
    # Username and password will be read from ~/.netrc.
    $jira = JIRA::REST->new($jira_instance);
}

my $row = 0;
foreach my $line (<$import_file_handle>) {  ### Importing--->      done
    $row++;
    try {
        # Don't change the original in case we need to write it out.
        my $mutated_line = $line;
        chomp $mutated_line;

        # Skip blank lines
        # "return" returns from the "try" block
        return unless $mutated_line;

        # We have a very strict format
        my ( $day, $hours, $jira_code, $billing_code, $note, $producer ) =
          split( /\s*?\t\s*?/, $mutated_line );

        # Skip header row
        # "return" returns from the try block (i.e. it's "next").
        return if $day eq 'Day';

        # Clean up the code, mostly to remove whitespace, but also to make it
        # URL-safe.
        $jira_code =~ s/^A-Za-z0-9\-//g if $jira_code;

        # It's ok for the row not to have a code - means it's not for us.
        return unless $jira_code;

#  curl -H "Content-Type: application/json" -b "$_JIRA_COOKIE" -X POST -d "{ \"comment\": \"`_jira.quote ${comment}`\", \"timeSpentSeconds\": ${time_spent}, \"started\": ${start_string} }" ${_JIRA_API}/api/2/issue/${ticket}/worklog
# https://docs.atlassian.com/jira/REST/latest/#api/2/issue-addWorklog
        my $args;
        my $url;
        if ($tempo) {
            ( $url, $args ) = prepare_tempo_args(
                $jira,
                {
                    username     => $username,
                    day          => $day,
                    hours        => $hours,
                    jira_code    => $jira_code,
                    billing_code => $billing_code,
                    note         => $note,
                }
            );
        }
        else {
            $url  = "/issue/$jira_code/worklog";
            $args = {
                comment   => "$note",
                timeSpent => "${hours}h",
                started   => convert_day_to_date($day),
            };
        }

        # Handy to see exactly what'll get posted when Smart::Comments is on
        my $json = encode_json( $args );
        ##### $args
        ##### $json
        $jira->POST( $url, undef, $args );

    }
    catch {
        warn "Caught error in row $row: $_";

        # Write out what we read in - this will have a newline at the end
        # so we don't add one.
        print $error_file_handle "$line";
    };

}

######################################################################
# Subroutines

# convert_day_to_date($day_int_or_date)
#
# Given an integer from 1-7 inclusive that represents a day of the week,
# where Sunday is 1, Monday is 2, etc, returns the date formatted in the
# format that JIRA wants for the "started" (and possibly other) field(s).
#
# If $day_int_or_date is not an integer, it's parsed as a date, which can
# be in any format that Date::Manip::Date->parse can parse. If no time
# is specified, it defaults to noon, local time. If $day_int_or_time includes
# time and/or time zone information, that will be used instead.
#
# If $day is not a true value (e.g. 0 or undefined), today's date is returned.
#
sub convert_day_to_date {
    my ($day_number) = @_;

    # Find the end of the previous week, so we can assign the correct date
    # based on the day-of-week input if Day is provided in the input file.
    # We store these in global variables at the top of the script so we're not
    # recalculating them every time this subroutine is called.
    my $start_date = new Date::Manip::Date;
    my @days       = qw/sun mon tue wed thu fri sat/;
    if ($day_number) {
        if ( $day_number =~ /[^1-7\s]/imso ) {
            $start_date->parse($day_number);
        }
        else {
            $start_date->parse( $days[ $day_number - 1 ] );
        }
    }
    else {
        $start_date->parse("today");
    }

    # Unless they provided an explicit time, set time to noon to compensate for
    # the messed up way Tempo messes up Jira dates.
    my ( $year, $month, $mday, $hour, $min, $sec ) = $start_date->value();
    if ( !$hour && !$min && !$sec ) { $start_date->parse_time("noon") }

    my $start_string = $start_date->printf('%O.000%z');

    return $start_string;
}

# prepare_tempo_args( $jira,
#                {
#                    username     => $username,
#                    day          => $day,
#                    hours        => $hours,
#                    jira_code    => $jira_code,
#                    billing_code => $billing_code,
#                    note         => $note,
#                }
#            )
#
# Returns a URL endpoint and hashref ready to post to Tempo
sub prepare_tempo_args {
    my ( $jira, $timelog ) = @_;
    my ( $username, $day, $hours, $jira_code, $billing_code, $note )
        = @$timelog{ qw{ username day hours jira_code billing_code note } };
    #### require: $jira_code
    #### require: $username
    $billing_code =
      $billing_code || fetch_billing_code( $jira, $jira_code );

    my $url = q{/rest/tempo-timesheets/3/worklogs/};
    my $author = $username; # Because I hope to add || $jira->username.
    my $seconds = $hours * 3600;
    my $args = {
        comment          => $note,
        timeSpentSeconds => $seconds,
        billedSeconds    => $seconds,
        dateStarted      => convert_day_to_date($day),
        issue            => {
            key => $jira_code,
        },
        author          => {
            name => $author,
        },
        worklogAttributes => [
            {
                key   => "_nonbillable_",
                value => JSON::true,
            },
            {
                key   => "_BUDGETCode_",
                value => "$billing_code",
            },
        ],
    };

    return ( $url, $args );
}

# fetch_billing_code( $jira_obj, $issue_code )
#
# Given a JIRA::REST object and an issue code, returns the value of the billing
# code field for the issue.
# See "use Memoize" at the top of this script - API call is only made once per
# issue.
sub fetch_billing_code {
    my ( $jira, $issue_code ) = @_;

    my $issue_fields = $jira->GET("/issue/$issue_code");

    my $fields = $issue_fields->{'fields'}
      or die "Couldn't get fields from issue $issue_code";

    ##### $fields
    my $billing_code = $fields->{'customfield_23600'}->{'key'};
    #### check: $fields->{'customfield_23600'}
    #### check: $billing_code

    return $billing_code;
}

=head1 SEE ALSO

JIRA::REST, which is the module that handles the bulk of the work.

=head1 AUTHOR

Grant Grueninger

=cut

1;
