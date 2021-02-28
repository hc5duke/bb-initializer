#!/usr/bin/env ruby

# volume name
vol = ENV['VOLUME']
if vol.nil?
    puts "VOLUME required"
    exit 1
end

# min length of tracks to keep
min_length = ENV['MINLEN'].to_i
min_length = 600 if min_length == 0
puts min_length

# figure out dvd volume
dvd = (ENV['DVD'] || `ls /Volumes/ | grep -i -E "#{vol}"`).split(/\n/)[0]

# figure out directory name
dir = (ENV['DIR'] || `date +%s`).strip
ssn = ENV['SEASON'].to_i
eps = ENV['EPISODE'].to_i
dir = "S%02dE%02d.%s.%s" % [ssn, eps, dvd, dir] if ssn > 0 && eps > 0

puts dvd
puts dir

system("mkdir #{dir}")
tracks = `lsdvd /Volumes/#{dvd}`

tracks.split(/\n/).each do |track|
    matches = track.match(/Title: (\d+), Length: ([\d:\.]+)/)
    next if matches.nil?

    track = matches[1]
    length = matches[2]
    next if track.nil? || length.nil?

    t, mil = length.split(/\./)
    sec = t.split(/:/).map(&:to_i).inject do |sum, n|
        sum = 60 * sum + n
    end

    if sec >= min_length
        puts "Processing track #{track}"
        filename = track
        filename = "S%02dE%02d" % [ssn, eps + track.to_i - 1] if ssn > 0 && eps > 0
        puts "Filename: #{filename}"

        # Handbrake copies a track from the image
        cmd = [
            "handbrakecli",
                 "-t #{track}",                 # track number
                 "-O",                          # optimize for streaming
                 "-a none",                     # no audio
                 "-i /Volumes/#{dvd}",          # input source
                 "-o ./#{dir}/#{filename}.mp4", # output file name
                 "-w 640",                      # nominal width
                 "--display-width 640",         # display width
                 "--all-subtitles",             # get all captions
        ].join(' ')
        system(cmd)

        # Ffmpeg extracts subtitles
        cmd = [
            "ffmpeg",
                "-y",                           # overwrite
                "-hide_banner",                 # less verbose
                "-i ./#{dir}/#{filename}.mp4",  # input file
                # TODO: better way to select correct subtitle stream
                "-map 0:s:3 -c:s text",         # select subtitle stream
                "./#{dir}/#{filename}.srt",     # output file
        ].join(' ')
        system(cmd)
    end
end