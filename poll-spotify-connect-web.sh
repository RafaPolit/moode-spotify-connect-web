#!/bin/bash
LOOP=true

SQLDB=/var/www/db/player.db
WAS_ACTIVE=false
WAS_PLAYING=false

while $LOOP; do
  ACTIVE=$(curl -s localhost:4000/api/info/status | jq '.active')
  PLAYING=$(curl -s localhost:4000/api/info/status | jq '.playing')
  if $ACTIVE; then
    echo "Spotify Connect is active!"

    # stop playback
    if $PLAYING; then
      /usr/bin/mpc stop > /dev/null
    fi

    if $PLAYING && [ "$WAS_PLAYING" = false ]; then
      # stop current spotify play if playing until device is captured
      echo "Pausing temporarily..."
      curl -s localhost:4000/api/playback/pause

      # allow time for ui update
      sleep 1

      # start spotify playback again if playing
      echo "Resuming play!"
      curl -s localhost:4000/api/playback/play
    fi

    WAS_ACTIVE=true
    if $PLAYING; then
      WAS_PLAYING=true
    else
      WAS_PLAYING=false;
    fi

    # set spotify active flag to true
    $(sqlite3 $SQLDB "update cfg_engine set value='1' where param='spotifyactv'")

  else
    echo "Spotify Connect is dormant."
    WAS_ACTIVE=false
    WAS_PLAYING=false

    # set spotify active flag to false
    $(sqlite3 $SQLDB "update cfg_engine set value='0' where param='spotifyactv'")
  fi
  sleep 1
done