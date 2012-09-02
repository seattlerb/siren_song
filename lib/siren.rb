
class Siren
  def self.siren
    Thread.current[:siren] ||= Siren.new
  end

  def self.play type
    siren.play type
  end

  @@count = 0

  attr_accessor :count

  def initialize
    @@count += 1
    @count = @@count
  end

  def play type
    puts "Siren.play #{count}, :#{type}"
  end
end
