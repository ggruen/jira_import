# jira_import

## Overview

`jira_import` is a Perl script that, using the JIRA::REST CPAN module,
reads rows from a tab-delimited file and makes entries into your worklog
in JIRA.

## Installation/Upgrade

    mkdir -p ~/bin
    curl https://github.com/ggruen/jira_import/releases/latest -o ~/bin/jira_import
    chmod 755 ~/bin/jira_import

## Setup


`jira_import` reads your JIRA username and password from `.netrc`. Set
it up like so:

    echo "machine MY_INSTANCE.atlassian.net login USERNAME password PASSWORD" >> \
        ~/.netrc ; chmod 600 ~/.netrc

Replace `MY_INSTANCE.atlassian.net` with the domain of your JIRA
instance (yes, it works with JIRA Server as well as JIRA Cloud, just use
the JIRA instance's domain like you would put in your web browser).

Replace `USERNAME` with your JIRA username.  To get your JIRA username, log into
JIRA in a browser, click your profile picture, and select Profile.  Your
username is on the left side under your profile picture.  The API username
is *not* the same username you use to log into the web site.

Replace `PASSWORD` with the password you use to log into JIRA.

## Running

1. Create a tab-delimited file with your timesheet in it with the following
   headers:

        Day  Hours  JIRA Code  Task  Note  Producer

2. Log your time in the tab-delimited file (hint: log it in Excel, then copy/
   paste into a file - the paste will be tab-delimited)

3. `jira_import -f tab_delimited_filename -m MY_INSTANCE.atlassian.net`
   (where `MY_INSTANCE.atlassian.net` is the domain of your JIRA instance).

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
[install it]((https://github.com/miyagawa/cpanminus)) or use `cpan install`
instead. (To install cpanm on Mac you can `brew cpanm`).

Make changes

    vi jira_import.pl

Make a new release copy of the script

    make

Install your release copy

    mv jira_import ~/bin/jira_import

Or, since you have `JIRA::REST` installed, you can install just the script:

    mv jira_import.pl ~/bin/jira_import && chmod 755 ~/bin/jira_import