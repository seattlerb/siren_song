require "minitest/autorun"
require "siren_song"

class TestSirenSong < MiniTest::Unit::TestCase
  def dope type
    s(:call, s(:const, :Siren), :play, s(:lit, type))
  end

  def cleanup s
    s.gsub(/^ {6}/, '').chomp
  end

  def test_usecase
    rb = "if 1 then 2 else 3 end"
    exp = cleanup <<-RUBY
      if (Siren.play(:ifc) or 1) then
        (Siren.play(:ift) or 2)
      else
        (Siren.play(:iff) or 3)
      end
    RUBY

    actual = SirenSong.process rb

    assert_equal exp, actual

    # siren = []
    # pusher = lambda { |x| siren << x; nil }
    # Siren.stub :play, pusher do
    assert_equal 2, eval(actual)
    #   assert_equal [:ifc, :ift], siren
    # end
  end
end
