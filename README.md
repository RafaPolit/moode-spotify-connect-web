# moode-spotify-connect-web

moOde OS - spotify-web-connect install instructions and required files.

The fantastic moOde OS and moOde Audio Player by Tim Curtis (audiophile-quality playback for the RPi3) can be found at:
http://moodeaudio.org/

The great spotify-connect-web (a Spotify Connect server to be run inside Linux OSs) can be found at:
https://github.com/Fornoth/spotify-connect-web

Dependencies:
=============

- For zero-conf multiuser (this will prevent the need of user and password, but it is yet another service that needs to be run!)

```
$ sudo apt-get install avahi-utils
```

- The spotify-connect-web binaries and dependencies

```
$ cd /PATH/TO/INSTALL
$ wget https://github.com/Fornoth/spotify-connect-web/releases/download/0.0.3-alpha/spotify-connect-web_0.0.3-alpha.tar.gz
$ tar zxvf spotify-connect-web_0.0.3-alpha.tar.gz
```

- The spotify authentication key.  There is one provided in this repo, but it's better if you first try the proper chanel to get one from Spotify directly.

```
$ cd spotify-connect-web
$ wget https://github.com/RafaPolit/moode-spotify-connect-web/raw/master/spotify_appkey.key
```
Instalation instructions assume you put the key in the same folder where you installed spotify-connect-web.  If not, change the parameter accordingly.

Running
=======

## Zero conf avahi service
The zero-conf service is run with:

```
$ avahi-publish-service TestConnect _spotify-connect._tcp 4000 VERSION=1.0 CPath=/login/_zeroconf
```

In order to run them as a daemon (and prevent having to keep the console open) I have been running them with:

```
$ setsid avahi-publish-service TestConnect _spotify-connect._tcp 4000 VERSION=1.0 CPath=/login/_zeroconf >/dev/null 2>&1
```

This can be improved configuring them as services at startup (instructions just below!), or, if integrated into moOde Player, run by the Player itself upon demand.

## Spotify Connect Web

The binary can be run with

```
$ /PATH/TO/INSTALL/spotify-connect-web/spotify-connect-web --playback_device hw:1 -m PCM --mixer_device_index 1 --bitrate 320 --name "moOde Connect" --key /PATH/TO/INSTALL/spotify-connect-web/spotify_appkey.key
```

Replace the [hw:1] in --playback_device with the ALSA device you want to use.  Available options can be obtained with:

```
$ aplay -L
```

Replace [PCM] in -m for "Digital" if you have an i2s audio device (thanks Tim for the tip), leave PCM if you have are using a USB audio device (external DAC).

Replace the [1] in --mixer_device_index with the correct index for your mixer device.  You can get the index by inspecting the output of:

```
$ amixer controls
```

Find something that resembles 'Playback Volume'.

-------------
*Note:*

Inside moOde Player libs, the same parameter passed to **shairport sync -d** in /var/www/inc/playerlib.php works perfectly for --playback_device!

--------------

Again, should you wish to run it as a daemon:

```
$ setsid /PATH/TO/INSTALL/spotify-connect-web/spotify-connect-web --playback_device hw:1 --bitrate 320 --name "moOde Connect" --key /PATH/TO/INSTALL/spotify-connect-web/spotify_appkey.key >/dev/null 2>&1
```

If you want to configure it a service at startup, instructions are just below.

That's it, you should now have a working Spotify Connect inside moOde.  This basic setup requires moOde Player to be stopped manually in order for Spotify Connect to get access to the ALSA device.  It also requires Spotify Connect to be stopped for the moOde Player to gain access back to the device.  Once this service is integrated into moOde, all this will happen automatically, just as is the case with AirPlay.

## Configuring as service

Inside the **startup-services** folder of this respository, you can find two files for configuring both scripts as startup services.

Place both files insde the **/lib/systemd/system/** folder, and change BOTH PATHS in the *spotify-connect-web.service* service to reflect your current installation path.

You need to change both files ownership to root:root.

Now, to test that they are working correctly:

```
$ sudo systemctl start avahi-spotify-connect-multiuser.service
$ sudo systemctl start spotify-connect-web.service
```

Test that spotify-connect-web is working with:

```
$ sudo systemctl status spotify-connect-web.service
```

If everything looks OK and you can connect with your phone, tablet or PC, you can ENABLE both service to run at startup:

```
$ sudo systemctl enable avahi-spotify-connect-multiuser.service
$ sudo systemctl enable spotify-connect-web.service
```

That should do it!


Status Monitoring (further development info)
============================================

To monitor the status of the Spotify Connect server, there is a RESTfull web api implemented on port 4000.

The most useful routes are:

- http://localhost:4000/api/info/status
- http://localhost:4000/api/info/metadata

The status route returns a JSON object.  One of the keys is an "active" boolean key.  False means that no client is connected to the Connect host, True means a client is connected to the host.  (**Tim**, this is probably the ON/OFF switch if this is to be integrated into moOde?)

The metadata route returns a JSON that holds the name, artist, etc., as well as an url for the album art.  (**Tim**, this could also be integrated into the moode play section to show current track?, not neccessary but could be useful)

-------------------------

Hope this helps someone!

Happy listening.

Rafa.



