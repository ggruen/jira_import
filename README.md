# jira_import

`jira_import` is a Perl script that, using the JIRA::REST CPAN module,
reads rows from a tab-delimited file and makes entries into your worklog
in JIRA.

# Install/Upgrade

Download from the [download
page](https://github.com/ggruen/jira_import/releases/latest).

    cd /where/you/downloaded
    mkdir -p ~/bin
    mv ~/Downloads/jira_import.dms ~/bin/jira_import
    chmod 755 ~/bin/jira_import

# Set up .netrc

Add a line like this to `~/.netrc`, replacing words in all caps with
appropriate values:

    machine JIRA_INSTANCE login USERNAME password PASSWORD

Example:

    machine something.atlassian.net login joe password mypass

To get your JIRA username, log into
JIRA in a browser, click your profile picture, and select Profile.  Your
username is on the left side under your profile picture.  The API username
is *not* the same username you use to log into the web site.

# Run

Make a *tab-delimited* file like this, saved as "timesheet.txt":

    Day   Hours   JIRA Code   Task   Note            Producer
    1     1.5     ABC-123            Broke stuff.
    1     2       ABC-234            Fixed stuff.

Import the timesheet (replace JIRA_INSTANCE with your jira domain)

    jira_import -f timesheet.txt -m JIRA_INSTANCE

Go look in JIRA!

You'll probably want to put that command in a cron job to run at the end
of the day.

# More info

    perldoc jira_import

# Development

`jira_import` relies on `JIRA::REST`, which is packed into a single script
using [fatpack](http://search.cpan.org/~mstrout/App-FatPacker/).

To set up for development:

    git clone https://github.com/ggruen/jira_import.git
    cd jira_import
    cpanm --sudo --installdeps . # Drop --sudo if you install locally

If you don't have `cpanm` you can
[install it](https://github.com/miyagawa/cpanminus#installation) or use
`cpan install` instead and install the modules in "cpanfile" yourself.

Make changes

    vi jira_import.pl

Make a new release copy of the script

    make  # Creates fatpacked "jira_import" script

## Installing the release copy
Install your release copy in `~/bin/jira_import`

    cp jira_import ~/bin/jira_import

or

    make install

## Installing a light copy

Since you have the dependencies installed, you can install just the script:

    cp jira_import.pl ~/bin/jira_import && chmod 755 ~/bin/jira_import

or

    install

# Release

- `make`
- Go to `https://github.com/ggruen/jira_import/releases`
- Click "Draft a new release"
- Fill in the blanks and upload the `jira_import` that `make` made
- Set the tag in the github interface (it'll be pulled down - won't go the
  other way)
- `make clean`
