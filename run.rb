#!/usr/bin/env ruby

# frozen_string_literal: true

require 'cgi'

dbus_status = `#{<<~BASH}`
  dbus-send --print-reply \
            --dest=org.mpris.MediaPlayer2.spotify \
            /org/mpris/MediaPlayer2 \
            org.freedesktop.DBus.Properties.Get \
            string:org.mpris.MediaPlayer2.Player \
            string:PlaybackStatus
BASH

if dbus_status.empty?
  puts <<~XML
    <img>/usr/share/spotify/icons/spotify-linux-16.png</img>
    <click>spotify %U</click>
  XML
  exit 0
end

status = dbus_status.match(/variant\s+string\s+"(?<status>.*?)"/)

if status.nil?
  puts <<~XML
    <img>/usr/share/spotify/icons/spotify-linux-16.png</img>
    <click>spotify %U</click>
  XML
  exit 0
elsif status[:status] == 'Paused'
  puts <<~XML
    <txt>[Paused]</txt>
    <txtclick>
      dbus-send --print-reply
                --dest=org.mpris.MediaPlayer2.spotify
                /org/mpris/MediaPlayer2
                org.mpris.MediaPlayer2.Player.PlayPause
    </txtclick>
  XML
  exit 0
end

metadata = `#{<<~BASH}`
  dbus-send --print-reply \
            --dest=org.mpris.MediaPlayer2.spotify \
            /org/mpris/MediaPlayer2 \
            org.freedesktop.DBus.Properties.Get \
            string:org.mpris.MediaPlayer2.Player \
            string:Metadata
BASH

if metadata.empty?
  puts '<txt></txt>'
  exit 0
end

artist_regex = /
  \s+dict
  \s+entry
  \(
    \s+string
    \s+"xesam:artist"
    \s+variant
    \s+array
    \s+\[
      \s+string
      \s+"(?<artist>.*?)"
      \s+
    \]
    \s+
  \)
  /mx

title_regex = /
  \s+dict
  \s+entry
  \(
    \s+string
    \s+"xesam:title"
    \s+variant
    \s+string
    \s+"(?<title>.*?)"
    \s+
  \)
  /mx

artist = metadata.match(artist_regex)[:artist]
title = metadata.match(title_regex)[:title]

puts <<~XML
  <txt>#{CGI.escapeHTML(artist)} - #{CGI.escapeHTML(title)}</txt>
  <txtclick>
    dbus-send --print-reply
              --dest=org.mpris.MediaPlayer2.spotify
              /org/mpris/MediaPlayer2
              org.mpris.MediaPlayer2.Player.PlayPause
  </txtclick>
XML
