#!/bin/sh

# Checking for required commands tar xz wget and curl
echo -n "Checking for commands..."
requires=''
if ! type "tar" >/dev/null 2>&1; then
        requires="tar:$requires";
fi
if ! type "xz" >/dev/null 2>&1; then
        requires="xz:$requires";
fi
if ! type "wget" >/dev/null 2>&1; then
        requires="wget:$requires";
fi
if ! type "curl" >/dev/null 2>&1; then
        requires="curl:$requires"
fi
if [ ! -z $requires ]; then
        echo "FAIL!"
        echo -e "The following commands are not installed and this script will fail:\n$(echo -n $requires | sed 's/:/\n/g')\nInstall the required commands then try again. Exiting."
        exit 0
else
        echo "OK"
fi

# Clear the RPM DEB and OTHER variables
RPM=0
DEB=0
OTHER=0

# Set the user's home directory
USRHOME=`eval echo ~$USER`

# Find out if machine is deb rpm or any other based
# Distro Arch test
# Arch tests first
if [[ `uname -a | egrep "amd64|x86_64"` ]]; then
        # 64 bit, now we need the OS
        # testing for rpm
        if [ ! -x "$(which rpm)" ]; then
                # RPM does not exist
                # Test for dpkg
                if [ ! -x "$(which dpkg)" ]; then
                        # DEB does not exist
                        # Setting as other 64-bit
                        OTHER=1
                        EXT='tar.xz'
                        ARCH='amd64'
                else
                        DEB=1
                        EXT='deb'
                        ARCH='amd64'
                fi
        else
                RPM=1
                EXT='rpm'
                ARCH='x86_64'
        fi
elif [[ `uname -a | egrep "i386|i686"` ]]; then
        # 32 bit, now we need the OS
        # testing for rpm
        if [ ! -x "$(which rpm)" ]; then
                # RPM does not exist
                # Test for dpkg
                if [ ! -x "$(which dpkg)" ]; then
                        # DEB does not exist
                        # Setting as other 32 bit
                        OTHER=1
                        EXT='tar.xz'
                        ARCH='i386'
                else
                        DEB=1
                        EXT='deb'
                        ARCH='i386'
                fi
        else
                RPM=1
                EXT='rpm'
                ARCH='i686'
        fi
else
        # Probably ARM, testing for the OS
        # testing for rpm
        if [ ! -x "$(which rpm)" ]; then
                # RPM does not exist
                # Test for dpkg
                if [ ! -x "$(which dpkg)" ]; then
                        # DEB does not exist
                        # Setting as other 64-bit
                        OTHER=1
                        EXT='tar.xz'
                        ARCH='armhf'
                else
                        DEB=1
                        EXT='deb'
                        ARCH='armhf'
                fi
        else
                RPM=1
                EXT='rpm'
                ARCH='armv7hl'
        fi
fi

# Check the most up-to-date version from teamviewer.com and set variable
# Check ARM version
#if [[ "$ARCH" == "arm" ]]; then
#        NEWESTVERSION=$(curl -s https://www.teamviewer.com/en/download/linux/ | grep -14 $ARCH | head -n 1 | cut -dv -f2 | cut -d'<' -f1 | cut -d' ' -f1)
#else
#        NEWESTVERSION=$(curl -s https://www.teamviewer.com/en/download/linux/ | grep -8 "*\." | grep $EXT | head -n 1 | cut -dv -f2 | cut -d'<' -f1 | cut -d' ' -f1)
#fi

#LOGVER=$(echo $NEWESTVERSION | cut -d. -f1)
LOGVER=teamviewer

# Check currently installed version and set variable
#CURRENTVERSION=$(teamviewer -version 2>/dev/null | grep TeamViewer | awk '{ print $4 }')

#echo -e "Current Version:\t$CURRENTVERSION"
#echo -e "Newest Version: \t$NEWESTVERSION"

#if [ "$CURRENTVERSION" \< "$NEWESTVERSION" ]; then
#        echo "There is an updated version."
#       exit 0   ###This line is for debugging purposes--uncomment to test version check
#else
#        echo "You already have the most updated version."
#        exit 0
#fi
#echo ''

# Setting the Teamviewer Filename we will use to download and install
if [[ "$ARCH" =~ ^(arm) ]]; then
        TV_FILENAME="teamviewer_$ARCH.$EXT"
elif [[ `uname -a | grep void` ]]; then
        TV_FILENAME="teamviewer_$ARCH.$EXT"
elif [[ "$EXT" = rpm  ]]; then
        TV_FILENAME="teamviewer.$ARCH.$EXT"
else
        TV_FILENAME="teamviewer_$ARCH.$EXT"
fi

# Remove comment for debugging
#echo -e "TV_FILENAME=$TV_FILENAME\nNEWESTVERSION=$NEWESTVERSION\nUSRHOME=$USRHOME" && exit

wget --no-check-certificate https://download.teamviewer.com/download/linux/$TV_FILENAME -O /tmp/$TV_FILENAME

# Install the package
if [ $EXT == 'deb' ]; then
        sudo apt install -y /tmp/$TV_FILENAME
elif [ $EXT == 'rpm' ]; then
        sudo yum install -y /tmp/$TV_FILENAME
        ### Not tested yet.  If you test it, and it doesn't work, please give me some feedback with corrections
        ### if you have any.
else
        tar xvJf /tmp/$TV_FILENAME
        sudo mkdir -p /var/log/teamviewer$LOGVER
        sudo /tmp/teamviewer/tv-setup checklibs
        if [[ -z `sudo $USRHOME/Downloads/teamviewer/tv-setup checklibs | grep "All dependencies seem to be satisfied!"` ]]; then
                echo -e "Repo names for the required dependencies may have a different name than that given here."
                exit
        else
                sudo /tmp/teamviewer/tv-setup install
                sudo teamviewer daemon enable
                sudo teamviewer daemon start
                sudo /tmp/teamviewer/tv_bin/teamviewer-config
        fi
fi

echo ''
echo "Teamviewer has been updated.  If you are still unable to open the GUI, try fixing any broken dependencies."
exit 0