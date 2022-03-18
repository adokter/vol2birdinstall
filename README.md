## Vertical profiling of biological scatterers installer
The vol2bird installer provides install scripts for building the software from various software repositories. It currently supports.
 + Ubuntu 18.04 & 18.10
 + Ubuntu 21.04
 + CentOS 8
 + RedHat 8 (see RedHat Prerequisities below)
 + Mac OS Intel

The installer attempts to install as many stock packages using the package installers apt or yum. This in turn assumes that either this script is run as root or that the user running the script has sudo-privileges.

If you by any chance are running a different linux distribution or MacOS, the scripts will perform a best effort to identify the operating system you are running.

### installation

The default installation directory is `/opt/vol2bird`. This might not be writable by the user that installs the system and therefor it might be necessary to
run:
```
sudo mkdir -p /opt/vol2bird
sudo chown <usr> /opt/vol2bird
```

After that, it should hopefully be possible to run.
```
./setup install 
```
and if all goes as expected, the software will be placed in `/opt/vol2bird`. 

You can also specify `--prefix=<path>` to the setup script to get software installed at a different place. E.g.
```
 ./setup --prefix=/my/local/software install
```

### upgrading an existing installation
To upgrade an existing installation, run
```
./setup distclean
./setup install
```

### RedHat Prerequisites
When building the system on RedHat the subscription must be enabled so that it is possible to install all required dependencies. 
During the setup, libraries belonging to extra repos will also be installed. In order for this to work you must run the following
command before setting up the system:

```
sudo subscription-manager repos --enable "codeready-builder-for-rhel-8-x86_64-rpms"
```

### Mac OS
There are a few tools required when installing the software on a Mac that can't be installed by the setup script. First and foremost, the command line developer tools has to be installed. Start the terminal (Go->Utilities & Click on Terminal).
```
~ % xcode-select --install
```

If you haven't got Homebrew installed, then you will have to install that as well. For further information about this, check https://brew.sh. If you just want it done, first type 'brew' in the terminal. If command can't be found, install it by executing the following command.
```
~ % /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

After homebrew has been installed it will print some help text. One of the things that is written is that brew might have to be added to the PATH and it can look something like:
```
-----------------------------------
.......
==> Next steps:
- Run these two commands in your terminal to add Homebrew to your PATH:
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> /Users/<user>/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
- Run brew help to get started
-----------------------------------
```

Follow these steps so that you have got the brew available when running the setup.
