# To release jira_import:
# - make  (runs fatpack to make a large script)
# - https://github.com/ggruen/jira_import/releases
# - Upload jira_import
#
all: jira_import

jira_import:
	fatpack pack jira_import.pl > jira_import
	chmod 755 jira_import
	rm -rf fatlib fatpacker.trace

install: jira_import
	mkdir -p ~/bin
	mv jira_import ~/bin

clean:
	rm -rf fatlib fatpacker.trace jira_import
