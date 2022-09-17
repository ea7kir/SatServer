# INSTALLING the Raspberry Pi

## Install the latest 64bit Lite version of the Debian Bullseye operating system.

(A desktop environment is not required, but could be used for editing,  I use Xcode on the Mac)

-----

### First, download, install and run Raspberry Pi Imager from...

<https://www.raspberrypi.com/software/> currently at v1.7.1

Click `CHOOSE OS` and select `Raspberry Pi OS (other)`, then `Raspberry Pi OS Lite (64-bit)`.

Click the wheel icon (bottom right) and...

Select `Set hostname` to: `satserver`.

Select `Enable SSH` with `Use password authentication`.

Select `Username` to: `pisat` and enter your `Password`. This is so we can use a different Username for the receiver's Pi. Otherwise, if both were mounted on the Mac at the same time, we wouldn't know which was which.

Select `Set locale settings` to your time zone and keyboard layout and select `Skip first run Wizard`.

Select `Eject media when finished`.

Leave all other options unselected.

Click `SAVE`.

Insert a 32GB fast Micro SD card, `CHOOSE STORAGE` and then `WRITE`.

With the Pi connected to the LAN, insert the SD Card into the Pi and switch on.

NOTE: If you mess up the hostname or username you can always edit `~/.ssh/known_hosts` on the Mac.

-----

## Login for the first time

With Terminal, log in as `ssh pisat@satserver.local`, enter your password and accept the security alert.

### Update and upgrade

`sudo apt update && sudo apt full-upgrade -y`

Reboot for good measure.

`sudo reboot`

### Configure a few things

Login again and...

`sudo raspi-config`

Enable I2C.

Enable 1-Wire

Expand the Filesystem.

Select Finish and Reboot.

----

## Moving on.

### Get rid of those annoying login messages about Wifi and Country.

Disable WiFi and Bluetooth.  They're not needed, so disable them both.

`sudo nano /boot/config.txt` and add these lines to the end...

```
# Disable WiFi
dtoverlay=disable-wifi
# Disbale Bluetooth
dtoverlay=disable-bt
```

Save with Control-O and exit with Control-X and after the next reboot, they'll be gone.

-----

## Install I2C-Tools

These will be useful during development.

`sudo apt-get install i2c-tools`

More info at https://www.waveshare.com/wiki/Raspberry_Pi_Tutorial_Series:_I2C

-----

## Install SAMBA

SAMBA allows the RPi to appear as an external drive within the Mac Finder.  This makes it easy to edit with Xcode.

`sudo apt install samba -y`

Set a password for SAMBA, (probably with the same password for the pi)...

`sudo smbpasswd -a pisat`

Edit the config file...

`sudo nano /etc/samba/smb.conf`

Delete the contents by holding down Control-K (I normally keep the introductory text) and copy & paste with this...

```
[global]
client min protocol = SMB3
client max protocol = SMB3
vfs objects = catia fruit streams_xattr
fruit:metadata = stream
fruit:model = RackMac
fruit:posix_rename = yes
fruit:veto_appledouble = no
fruit:wipe_intentionally_left_blank_rfork = yes
fruit:delete_empty_adfiles = yes
security = user
encrypt passwords = yes
workgroup = WORKGROUP
server role = standalone server
obey pam restrictions = no
map to guest = never
[pisat]
comment = Pi Directories
browseable = yes
path = /home/pisat
read only = no
create mask = 0775
directory mask = 0775
```

Save with Control-O and exit with Control-X.

Test the file with `testparm /etc/samba/smb.conf`

NOTE: It will say "WARNING: The "encrypt passwords" option is deprecated" and I've no idea how to deal with that.

### Reboot again and the SAMBA Service will automatically start.

SatServer should now be mountable on the Mac, but all you see is an empty folder for now.

NOTE: I use Xcode to directly edit the files on the Pi.  Obviously, it's not possible to Run the code on the Mac, but it is possible to Build and flag any compile errors, before building and running on the the Pi.  I haven't investigated better ways of working, but they do exist.

-----

## Install Swift

The repository for Debian Swift is at https://www.swiftlang.xyz

### Step 1 - System Update

First run a system update and upgrade.

`sudo apt update && sudo apt upgrade`

### Step 2 - Run the quick install script

`curl -s https://archive.swiftlang.xyz/install.sh | sudo bash`

The installer script will automatically detect whether your system is compatible with the repository.

### Step 3 -Choose which version of Swift to install
If your system is compatible you will be presented with a menu which will allow you to choose which versions of swift are available.

```
1) latest/main - This will update to the latest/stable release of Swift available
2) developer - Swift developer builds - this will update to the latest developer build available
3) Swift version 5.4.* - this will update to the latest point/patch release of Swift 5.4
4) Swift version 5.5.* - this will update to the latest point/patch release of Swift 5.5
```

I normally go with option 1.


### Step 4 - Install Swift

`sudo apt install swiftlang`

### Step 5 - Check Swift version

`swift -version`

### Test with a new executable package (optional).

```
mkdir CommandLineTool
cd CommandLineTool
swift package init --type executable
swift build
swift run
```

NOTE: `swift run` will also build the package when needed.

This simple command line app will print 'Hello, world!' And you can delete it from your home folder by...

```
cd
rm -rf CommandLineTool
```

There's lots more to Swift Package Manager, so read the Usage Documentation at...

https://github.com/apple/swift-package-manager/tree/main/Documentation

This concludes the basic preparation, so do yet another reboot for extra measure.

-----

## Download the SatServer Code to the Mac.

From https://github.com/ea7kir/SatServer

Rename SatServer-main to SatServer and copy it to the Pi's home folder.

Using Terminal, execute the following...

```
ssh pisat@satserver.local
cp SatServer/Resources/shutdownSatServer.sh ~/
chmod +x shutdownSatServer.sh
cp SatReceiver/Resources/rebootSatServer.sh ~/
chmod +x rebootSatServer.sh
```

## To edit the source using Xcode

Mount SATSERVER using the Finder and navigate to the SatServer folder and double click on Package.swift.

NOTE: You can Build in Xcode to check the sytax, but you can't run it.  It must be built on the Pi using `swift build` or `swift run` from the Terminal app on the Mac.

```
ssh pisat@satserver.local
cd SatServer
swift run
```

and quit with Control-C

## Starting & Stopping

We need SatServer to always start when the Raspberry Pi boots...

Copy `SatServer.service` to `/etc/systemd/system/` and enable, or just reboot.

```
ssh pisat@satserver.local
sudo cp /home/pisat/SatServer/Resources/SatServer.service /etc/systemd/system/SatServer.service
sudo chmod 644 /etc/systemd/system/SatServer.service
sudo systemctl daemon-reload
sudo systemctl enable SatServer
sudo systemctl start SatServer
```

To stop SatServer

`sudo systemctl stop SatServer`

To start SatServer

`sudo systemctl start SatServer`

To check the status of SatServer

`sudo systemctl status SatServer`

To disable SatServer on every reboot

`sudo systemctl disable SatServer`

To enable SatServer on every reboot

`sudo systemctl enable SatServer`

For more information `man systemctl`

To edit (if needed)

```
sudo nano /etc/systemd/system/SatServer.service
```

