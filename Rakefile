# -*- ruby -*-

require "rubygems"
require "hoe"

Hoe.plugin :isolate
Hoe.plugin :seattlerb

Hoe.spec "siren_song" do
  developer "Ryan Davis", "ryand-ruby@zenspider.com"

  dependency "unimidi", "> 0"
  dependency "ruby_parser", "> 0"
  dependency "ruby2ruby", "> 0"
end

task :wtf => :isolate do
  require 'unimidi'

  sysex_msg = [0xF0, 0x41, 0x10, 0x42, 0x12, 0x40, 0x00, 0x7F, 0x00, 0x41, 0xF7]

  UniMIDI::Output.gets do |output|
    output.open { |output| output.puts(sysex_msg) }
  end
end

task :wtf2 => :isolate do
  require 'unimidi'

  duration = 0.5
  UniMIDI::Output.open(:first).open do |output|
    output.puts(0x90, 36, 100) # note on message
    sleep(duration) # wait
    output.puts(0x80, 36, 100) # note off message
  end
end

# vim: syntax=ruby
