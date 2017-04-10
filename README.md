# jira_import

## Overview

jira_import is a perl script that, using the JIRA::REST CPAN module,
reads rows from a tab-delimited file and makes entries into your worklog
in JIRA.

## Installation

    git clone https://github.com/ggruen/jira_import.git
    cpan install JIRA::REST

    echo "machine MY_INSTANCE.atlassian.net login USERNAME password PASSWORD" >> \
        ~/.netrc ; chmod 600 ~/.netrc

Replace MY_INSTANCE.atlassian.net with the domain of your JIRA instance.

Replace USERNAME with your JIRA username.  To get your JIRA username, log into
JIRA in a browser, click your profile picture, and select Profile.  Your
username is on the left side under your profile picture.  The API username
is *not* the same username you use to log into the web site.

Replace PASSWORD with the password you use to log into JIRA.

## Running

1. Create a tab-delimited file with your timesheet in it with the following
   headers:

        Day  Hours  JIRA Code  Task  Note  Producer

2. Log your time in the tab-delimited file (hint: log it in Excel, then copy/
   paste into a file - the paste will be tab-delimited)

3. `jira_import -f tab_delimited_filename -m MY_INSTANCE.atlassian.net`
   (where `MY_INSTANCE.atlassian.net` is the domain of your JIRA instance).

## More info

`perldoc jira_import`

## Upgrading

You can copy `jira_import` into `~/bin` or wherever you like.

The repo includes an `install` script that will do a `git pull` and copy
`jira_import` to `~/bin`.  You can run that via a crontab if you want to keep
the script updated automatically.  If you'd like an option to install
somewhere like /usr/local/bin, submit an issue or a pull request and I'll add
it.  Or, just write a crontab entry like:

    # Check for jira_import updates Sunday at midnight
    0 0 * * 0 cd /path_to_repo && git pull && cp jira_import /usr/local/bin/ && chmod 555 /usr/local/bin/jira_import

