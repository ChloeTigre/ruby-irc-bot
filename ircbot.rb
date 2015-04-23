#!/usr/bin/env ruby1.9.1
# encoding: utf-8
# by Chloé Tigre Rouge

require 'socket'
require './utils.rb' 
class IRCBot
  attr_reader :server, :port, :channel

  def IRCBot.getLineInfo(line)
    m, sender, inst, target, command = *line.match(/:([^!]*)![^ ].* +(PRIVMSG|QUIT|JOIN) ([^ :]+) +:(.+)/)
    return m, sender, target, command
  end

  def IRCBot.getSender(line)
    m, sender = *line.match(/:([^!]*)![^ ].*/)
    return sender
  end
  def ponged
    @ponged
  end


  def setPonged(val)
    if (val != @ponged)
      @ponged = val
      if (@ponged)
        puts "Ponged first time. Now joining"
        doJoin
      end
    end
  end
  
  def doJoin
    join(@channel)
  end

  def sendSrv(*args)
    mesg = args.join(" ")
    mesg << "\r\n"
    puts "Writing |#{colorize(mesg.chomp, 'green')}"
    @socket.write mesg 
  end

  def sendPM(dest, message)
    dest = [dest] unless dest.kind_of?Array
    dest.each do |destination|
      message.split("\n").each do |msg|
        msg << (" "*(250-(msg.length % 250)))
        msg.scan(/.{250}/).each do |m|
          sendSrv("PRIVMSG #{destination} :#{m}")
        end
      end
    end
  end

  def initialize(server, port, channel, nick, callbacks, urgents, abortTrigger='pabort')
    @callbacks = callbacks
    @urgents = urgents
    @executionQueue = []
    @channel = channel
    @ponged = false
    @server = server
    @port = port
    @nick = nick
    @abortTrigger = abortTrigger
  end

  def startIRC
    doConnect(@server,@port,@nick)
    startExecutionQueue()
    startReadingThread()
    startConnector()
    @t3.join
    @t.join
    @t2.join
  end

  def startExecutionQueue
    @t = Thread.new do 
      puts "Execution Queue"
      executeQueue
      puts "Done Execution Queue"
    end
    @t.priority = 0
  end
  def startConnector
    @t3 = Thread.new do 
      while !@ponged
      	if Time.now - @timeStarted > 15
          puts "More than 30 seconds. Time to wake up and get onchan!"
	  setPonged(true)
      	#else
	  #puts "Time passed: #{Time.now - @timeStarted}" 
      	end
	sleep(1)
      end
    end
  end
  def startReadingThread
    @t2= Thread.new do
      doRun
      raise "Should never exit doRun"
    end
    @t2.priority = 5
  end

  def cancelQueue
    puts "Cancelling queue"
    sendSrv("PRIVMSG #{channel} :ABORTING THE CURRENT TASKS")
    @executionQueue = []
    @t.kill
#    TheCache.ResetPB
    startExecutionQueue
  end

  def doRun
    #while(true)
    #  puts "doRun"
    #  Thread.pass
      while line = @socket.gets.strip
        puts "Received|#{colorize(line.chomp,'red')}"
        if line =~ /PING :(.+)/
          doPong(line)
	#elsif line =~ /MODE(.*):\+i/
        #  puts "Mode line"
	#  setPonged(true)
        elsif line =~ /PRIVMSG ([^ :]+) +:!#{@abortTrigger}(.?)/
          cancelQueue
        else
          # extra hooks
          parseLine(line)
        end
#        Thread.pass
      end
      sleep(3)
    # end
  end

  def doPong(line)
    puts "doPong"
    pong = *line.match(/PING :(.+)/)
    sendSrv "PONG :#{pong[1].strip}"
    setPonged(true)
    puts "doPong done"
  end

  def doConnect(server, port, nick)
    @socket = TCPSocket.new server, port
    @timeStarted = Time.now
# connecting
    ["NICK #{nick}", "USER #{nick} 0 * :IRCBot user"].each do |command|
      sendSrv command
      sleep 1
    end
    puts "done doConnect"
  end

  def join(channel)
    @channel = channel
    sendSrv("JOIN #{channel}")
    sendSrv("PRIVMSG #{channel} :Hello guys.")
  end

  def pushToQueue(command, callback, directMessage = false)
    @executionQueue << [command, callback, directMessage]
    #sendPM(@channel, "Queue is now #{@executionQueue.length} ops long")
  end

  def parseLine(line)
    puts "parsing line #{line}"
    @callbacks.each do |regex, function|
      if (line =~ regex)
        puts "Matches #{function}"
        pushToQueue(line, function)
      end

    end
    @urgents.each do |regex, function|
      if (line =~ regex)
        puts "Matches urgent #{function}"
        t = Thread.new do
          res = function.Call(line)
          if (res)
            res.split("\n").each do |line|
              sendPM(@channel, line.strip)
            end
          end
        end
        t.priority = -1
        t.join
      end
    end
  end

  def executeQueue
    while (true)
      sleep(1)
      while (ex = @executionQueue.shift)
        puts "Execution #{ex}"
        l,chan,command = *ex[0].match(/PRIVMSG (.+):(.+)/)
        #sendPM(@channel,"Now starting execution of #{command} (#{ex[1]}.Call)")
        res = execute(ex)
        #sendPM(@channel,"Done execution of #{command} (#{ex[1]}.Call)")
        #Thread.pass
        if (res)
          res.split("\n").each do |line|
            sendPM(@channel, line)
          end
        else
          sendPM(@channel, "Hook #{ex[1].to_s}.Call did not return anything. Please check it")
        end
      end
    end
  end

  def execute(item)
    return item[1].Call(item[0])
  end
end
