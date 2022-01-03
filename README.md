## Vertical profiling of bilogical scatterers installer
The vol2bird installer provides install scripts for building the software from various software repositories. It currently supports.
 + Ubuntu 18.04 & 18.10
 + Ubuntu 21.04
 + CentOS 8
 + RedHat 8 (see RedHat Prerequisities below)

The installer atempts to install as many stock packages using the package installers apt or yum. This in turn assumes that either this script is run as root or that the user running the script has sudo-privileges.

If you by any chance are running a different linux distribution or MacOS, the scripts will perform a best effort to identify the operating system you are running.

Easiest way to get started is to just run
%> ./setup install 

and if all goes as expected, the software will be placed in /opt/vol2bird. You can also specify --prefix=<path> to the setup script to get software installed at a different place. E.g.
%> ./setup --prefix=/my/local/software install




=== RedHat Prerequisities ===
When building the system on RedHat the subscription must be enabled so that it is possible to install all required dependencies. 
During the setup, libraries belonging to extra repos will also be installed. In order for this to work you must run the following
command before setting up the system:

%> sudo subscription-manager repos --enable "codeready-builder-for-rhel-8-x86_64-rpms"


