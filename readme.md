# gembackupdate

gembackupdate is a Arch Linux CLI tool written in Free Pascal to help streamline timeshift system snaphots and pacman package manager updates. Then program will
* check for an internet connection using w get
* check for the existence of pacman package manager
* check for the existence of timeshift
* sync pacman repos (pacman -Sy) and query pacman for updates (pacman -Qu)
* optionally rank mirrors using reflector with a default mirror count and timeout value, or values supplied by the user
* create a timeshift system snapshot (timeshift --create --comments "gembackupdate")
* perform pacman updates (pacman -Syu)
* launch timeprune (external process found in it's own repo) to delete old or excessive timeshift snapshots
* optionally reboot the system

## Notes
  Currently, only timeshift and pacman are supported. The code checks for "yay", but at the moment, it uses only pacman anyway. I'll be adding support for btrfs snapshots, other snapshot utilites and other package managers soon-ish. I have like 6 different distros installed to an external SSD for testing with aptitude, snap, DNF and others.

## Dependencies

- Binaries
  * bash
  * wget
  * timeshift
  * reflector
  * pacman
  * timeprune (located here in it's own repo)

- Source (for compilation)
  * Classes.pp (FPC)
  * SysUtils.pp (FPC)
  * Process.pp (FPC)
  * Unix.pp (FPC)
  * FileInfo.pp (FPC)
  * gemutil (located in Units repo)
  * gemclock (located in Units repo)
  * gemprogram (located in Units repo)
