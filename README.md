## Vertical profiling of bilogical scatterers installer
The vol2bird installer provides install scripts for building the software from various software repositories. It currently supports.
 + Ubuntu 18.04 & 18.10
 + Ubuntu 21.04

The installer atempts to install as many stock packages using the package installers apt or yum. This in turn assumes that either this script is run as root or that the user running the script has sudo-privileges.

If you by any chance are running a different linux distribution or MacOS, the scripts will perform a best effort to identify the operating system you are running.

Easiest way to get started is to just run
%> ./setup install 

and if all goes as expected, the software will be placed in /opt/vol2bird. You can also specify --prefix=<path> to the setup script to get software installed at a different place. E.g.
%> ./setup --prefix=/my/local/software install

