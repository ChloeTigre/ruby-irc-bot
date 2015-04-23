#!/usr/bin/env ruby20
# encoding: utf-8

require './ircbot.rb'
class LiensGlue
  def LiensGlue.Call(line)
    return "https://jesuislibre.seltheis.fr/ : wiki | https://etherpad.fr/p/JeSuisLibre : pad | https://etherpad.fr/p/JeSuisLibreStyle : participer au design." 
  end
end
class HelpGlue
  def HelpGlue.Call(line)
    return "!h: ce message. !liens: liste des liens." 
  end
end
  b = IRCBot.new('irc.freenode.net', 6667, '#botstest', '[B]MicheleLouis',
  { # queued messages
    /PRIVMSG [^:]+ :!h\s*/ => HelpGlue, 
  },
  { # urgent messages
    /PRIVMSG.* :!liens\s*/ => LiensGlue, 
    #/PRIVMSG ([^ :]+) +:!vpn (.+)/ => VPNGlue

  }, 'pabort')
  puts "IRCbot"
  b.startIRC
