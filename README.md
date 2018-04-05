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

## Running with softvol to avoid volume issues

Since the default setting modifies the PCM volume, you could end up lowering the volume on Spotify Connect and then not being able to get it back up in Moode (for instance if you have set it to hardware volume or have disabled volume all together).

For such a case, create a file in **/etc/** called asound.conf with the contents listed in the file in this repository.  In order to activate the new virtual device:

```
$ speaker-test -Dsoftvol -c2
```

After that, run the Spotify service changing the following arguments:

```
--playback_device softvol -m Master --mixer_device_index 0
```

... instead of the settings described above settings.

If this is successful, the volume from within Moode controls the system-wide volume, and the spotify-playing device (such as your phone) controls only the volume of the spotify music and does not affect the overall volume.

Moode 4.x
============================================

I was unable to successfuly implement this on Moode 4.x (beta) with the packaged release of spotify-connect-web.  For those scenarios, following the instructions on **Installation from source** worked.

```
$ cd /home/pi
$ mkdir spotify && cd spotify
$ git clone https://github.com/Fornoth/spotify-connect-web.git
$ cd spotify-connect-web
$ wget https://github.com/RafaPolit/moode-spotify-connect-web/raw/master/spotify_appkey.key
$ wget https://github.com/RafaPolit/moode-spotify-connect-web/raw/master/libspotify_embedded_shared.so
$ sudo chmod +x libspotify_embedded_shared.so
$ sudo apt-get install python-dev libffi-dev libasound2-dev
$ pip install -r requirements.txt
```

The **pip install** can take a VERY long time, let it run!

```
$ cd ..
$ vim spotify-connect.sh
```

Inside the sh file put:

```
#!/bin/sh

cd /
cd home/pi/spotify/spotify-connect-web
LD_LIBRARY_PATH=/home/pi/spotify/spotify-connect-web python main.py --playback_device softvol -m Master --mixer_device_index 0 --bitrate 320 --name "moOde Connect" --key /home/pi/spotify/spotify-connect-web/spotify_appkey.key
cd /
```

This asssumes you are using the softvol solution listed above, which is very useful.  If not, add the correct parameters as needed.

```
$ sudo chmod 755 spotify-connect.sh
```

The service spotify-connect-web.service should be a little different than the one listed above, it should be:

```
Description=Spotify Connect Web
After=network.target avahi-spotify-connect-multiuser.service

[Service]
User=pi
ExecStart=/home/pi/spotify/spotify-connect.sh
Restart=always
RestartSec=10
StartLimitInterval=30
StartLimitBurst=20

[Install]
WantedBy=multi-user.target
```

I also needed, still for unknown reasons, to 'activate' the softvol device and mixer by:

```
$ speaker-test -Dsoftvol -c2
```

Whith this, I have everything working on the BETA version of Moode 4.  I'll report any changes as Moode 4 beta stage continues evolving.

### Spotify Connect in Moode UI (alpha)
I have created a rudimentary option to show album art, track name, artist and album name into the Moode UI.
To accomplish this:

- Install Node-Red in the Rpi: https://nodered.org/docs/hardware/raspberrypi
- Add the file: https://github.com/RafaPolit/moode-spotify-connect-web/blob/master/var/www/js/spotifyLib.js
inside the **/var/www/js/** directory.
- Add the following script near the end of the FOOTER file (where the MOODE JS scripts are located): **/var/www/footer.php**
```
<!-- SPOTIFY CONNECT -->
<script src="js/spotifylib.js"></script>
```
- Add the node-red from: https://github.com/RafaPolit/moode-spotify-connect-web/blob/master/node-red/Spotify%20Connect%20Web into Node-REd
- Deploy the node

This should accomplish to render the album and song data and replace the conuter wit SPOTIFY.

** Disclamer ** This is in early alpha.
Known issues:
- This DOES NOT stop the MPD or Airplay session that may be playing.  You need to stop them manually
- This DOES NOT allow any funcionality through play or next buttons
- This DOES NOT take over from Spotify if you click on a playlist track from within Moode.  As a matter of fact, that will break the spotify access to the ALSA card and you would need to re-connect to the Spotify Connect client
- This has issues when, after stopping Spotify, you try to play the SAME song that was playing before on Moode MPD.  This would be easily solvable if the JS, instead of a standalone, would be inserted inside the **playerlib.js** file.  The issue is that I wanted to keep this as separated as possible to avoid instructions of where to store things.  If you are feeling brave, put it in, it will work better.
- Small issue: I am pointing to a fixed server for the ablum covers, which may return as slightly different version of the cover than the one shown in spotify.  I may end up using Spotify API, but that requires asking for a token, etc., so that will need to come in later.

Please note that this is at EXTREME ALPHA stages.  I'm mostly documenting this for myself, so use with caution.

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



