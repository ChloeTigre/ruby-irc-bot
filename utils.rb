#!/usr/bin/env ruby1.9.1
require 'digest'
ColorCodes = {
"reset"=>0,
"italic"=>3,
"bold"=>1,
"black"=>30,
"red"=>31,
"green"=>32,
"yellow"=>33,
"blue"=>34,
"magenta"=>35,
"cyan"=>36,
"white"=>3
}

def colorize(text, color_code)
  "\e[#{ColorCodes[color_code].to_s}m#{text}\e[#{ColorCodes['reset'].to_s}m"
end

def setscreentitle(text)
  "\ek#{text}\e\\"
end
def Digest.hexdecode(str)
  str.scan( /../ ).map { |n| n.to_i( 16 ) }.pack( "U*" )
end

module Kernel
  def print_stacktrace
    raise
  rescue
    puts $!.backtrace[1..-1].join("\n")
  end
end

def irc_get_line_info(line)
  m, sender, inst, target, command = *line.match(/:([^!]*)![^ ].* +(PRIVMSG|QUIT|JOIN) ([^ :]+) +:(.+)/)
  return m, sender, target, command
end
