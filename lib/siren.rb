require 'rubygems'
require 'unimidi'

class Siren
  # include MIDIator::Notes
  # include MIDIator::Drums

  def self.siren
    Thread.current[:siren] ||= Siren.new
  end

  def self.play type
    siren.play type
  end

  @@count = 0

  attr_accessor :count, :scale

  def initialize
    @@count += 1
    @count = @@count

    # midi = MIDIator::Interface.new
    # midi.use :dls_synth

    # # blues scale
    # @scale = [ C4, Eb4, F4, Fs4, G4, Bb4,
    #            C5, Eb5, F5, Fs5, G5, Bb5,
    #            C6, Eb6, F6, Fs6, G6, Bb6 ]

    # midi.control_change 32, 10, 1 # TR-808 is Program 26 in LSB bank 1
    # midi.program_change 10, 26

    @midi = midi
  end

  def midi
    @midi ||= begin
              end
  end

  def play type
    raise "no"
    instrument = {
    }[type]

    raise "Unknown type #{type.inspect}" unless instrument

    # [ HighTom1, HighTom2, LowTom1, LowTom2 ].each do |note|
    #   midi.play note, 0.067, 10
    # end

    midi.play instrument, duration
  end
end
