# To release jira_import:
# - make  (runs fatpack to make a large script)
# - https://github.com/ggruen/jira_import/releases
# - Upload jira_import
#
all: jira_import
	fatpack pack jira_import.pl > jira_import
	chmod 755 jira_import
	rm -rf fatlib fatpacker.trace
