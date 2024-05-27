# gembackupdate

gembackupdate is a Linux CLI tool written in Free Pascal to help streamline timeshift system snaphots and pacman package manager updates. Then program will
* check for an internet connection using w get
* check for the existence of pacman package manager
* check for the existence of timeshift
* sync pacman repos (pacman -Sy) and query pacman for updates (pacman -Qu)
* optionally rank mirrors using reflector with a default mirror count and timeout value, or values supplied by the user
* create a timeshift system snapshot (timeshift --create --comments "gembackupdate")
* perform pacman updates (pacman -Syu)
* launch timeprune (external process found in it's own repo) to delete old or excessive timeshift snapshots
* optionally reboot the system

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
  * gemutil (located in Units repo)
  * gemclock (located in Units repo)
  * gemprogram (located in Units repo)
