# jira_import

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

Optionally, you can copy `jira_import` into ~/bin or wherever you like.

5/6/16: You may need to force the install of JIRA::REST (cpan -f install JIRA::REST), see
        https://rt.cpan.org/Public/Bug/Display.html?id=114200

## Running

1. Create a tab-delimited file with your timesheet in it with the following
   headers:

    Day  Hours  JIRA Code  Task  Note  Producer

2. Log your time in the tab-delimited file (hint: log it in Excel, then copy/
   paste into a file - the paste will be tab-delimited)

3. `jira_import_time -f tab_delimited_filename -m MY_INSTANCE.atlassian.net`
   (where `MY_INSTANCE.atlassian.net` is the domain of your JIRA instance).

## More info

`perldoc jira_import`
