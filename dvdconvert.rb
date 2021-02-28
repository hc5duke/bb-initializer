#!/usr/bin/env ruby

if !ENV['VOLUME'].nil?
  run_dvd
elsif !ENV['DIR'].nil?
  run_mkv
else
    puts "VOLUME or DIR required"
    exit 1
end

def run_mkv
    # dir of mkv files
    dir = ENV['DIR']
end

def extract_from_dvd(dvd, track)
    file_path = "#{dir}/#{track.filename}"

    cmd = [
      "handbrakecli",
      "-t #{track.number}", # track number
      "-O", # optimize for streaming
      "-a none", # no audio
      "-i /Volumes/#{dvd}", # input source
      "-o ./#{file_path}.mp4", # output file name
      "-w 640", # nominal width
      "--display-width 640", # display width
      "--all-subtitles", # get all captions
    ].join(' ')

    system(cmd)
end

def extract_srt(file_path)
    cmd = [
      "ffmpeg",
      "-y",                    # overwrite
      "-hide_banner",          # less verbose
      "-i ./#{file_path}.mp4", # input file
      # TODO: better way to select correct subtitle stream
      "-map 0:s:3 -c:s text", # select subtitle stream
      "./#{file_path}.srt",   # output file
    ].join(' ')
    system(cmd)
end

def run_dvd
    # volume name
    vol = ENV['VOLUME']
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

    tracks.split(/\n/).each do |trk|
        track = Track.new(trk, eps, ssn)
        if track.length >= MIN_LENGTH
            puts "Processing track #{track.number}"

            # Handbrake copies a track from the image
            extract_from_dvd(dvd, track)

            # Ffmpeg extracts subtitles
            extract_srt(file_path)
        end
    end
end

class Track
    def initialize(str, ssn, eps)
        @season = ssn
        @episode = eps
        matches = str.match(/Title: (\d+), Length: ([\d:\.]+)/)
        return if matches.nil?

        @number = matches[1]
        length = matches[2]
        return if @number.nil? || length.nil?

        t, _ = length.split(/\./)
        @length = t.split(/:/).map(&:to_i).inject do |sum, n|
            60 * sum + n
        end
    end

    def length
        @length.to_i
    end

    def number
        @number.to_i
    end

    def filename
        return @filename unless @filename.nil?

        if @season > 0 && @episode > 0
            @filename = "S%02dE%02d" % [ssn, eps + track.to_i - 1]
        else
            @filename = @track
        end
    end
end