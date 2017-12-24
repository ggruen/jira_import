# jira_import

## Overview

`jira_import` is a Perl script that, using the JIRA::REST CPAN module,
reads rows from a tab-delimited file and makes entries into your worklog
in JIRA.

## Installation/Upgrade

Download from the [download page](https://github.com/ggruen/jira_import/releases/latest).

    cd /where/you/downloaded
    mkdir -p ~/bin
    mv ~/Downloads/jira_import.dms ~/bin/jira_import
    chmod 755 ~/bin/jira_import

## Setup

Set these variables in your shell:

    my_jira=MY_INSTANCE        # e.g. "mycompany.atlassian.net"
    username=MY_JIRA_USERNAME  # Enter your profile *username* (see below)
    password=MY_JIRA_PASSWORD  # Your JIRA password

Copy/paste this to set up your `.netrc` (you can also just edit the file):

    # Store login info in .netrc (only do this once)
    echo "machine $my_jira_ login $username password $password" >> \
        ~/.netrc ; chmod 600 ~/.netrc

To get your JIRA username, log into
JIRA in a browser, click your profile picture, and select Profile.  Your
username is on the left side under your profile picture.  The API username
is *not* the same username you use to log into the web site.

### Optional - to do a test entry

Set these variables in your shell.

    hours=1                       # Hours to log
    issue=ABC-1234                # JIRA issue in which to add a test worklog
    description="Did some stuff"  # Description of work done

Copy/paste to make a test timesheet and submit it.

    # Make a 1-line timesheet
    printf "\t$hours\t$issue\t\t$description\t\n" > \
            /tmp/timesheet.tsv

    # Enter the timesheet
    jira_import -f /tmp/timesheet.tsv -m $my_jira

Go look in JIRA!

## Running

1. Create a tab-delimited file with your timesheet in it with the following
   headers:

        Day  Hours  JIRA Code  Task  Note  Producer

2. Log your time in the tab-delimited file (hint: log it in Excel, then copy/
   paste into a file - the paste will be tab-delimited)

3. `jira_import -f tab_delimited_filename -m MY_INSTANCE.atlassian.net`
   (where `MY_INSTANCE.atlassian.net` is the domain of your JIRA instance).

You'll probably want to put that command in a cron job to run at the end
of the day.

## More info

    perldoc jira_import

## Development

`jira_import` relies on `JIRA::REST`, which is packed into a single script
using [fatpack](http://search.cpan.org/~mstrout/App-FatPacker/).

To set up for development:


    git clone https://github.com/ggruen/jira_import.git
    cpanm JIRA::REST
    cpanm App:FatPacker

If you don't have `cpanm` you can
[install it](https://github.com/miyagawa/cpanminus) or use `cpan install`
instead. (To install cpanm on Mac you can `brew cpanm`).

Make changes

    vi jira_import.pl

Make a new release copy of the script

    make

Install your release copy

    mv jira_import ~/bin/jira_import

Or, since you have `JIRA::REST` installed, you can install just the script:

    mv jira_import.pl ~/bin/jira_import && chmod 755 ~/bin/jira_import
