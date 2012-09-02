
$: << "../../ruby_parser/3.0.0.a6/lib"
$: << "../../sexp_processor/4.0.1/lib"
$: << "../../ruby2ruby/2.0.0.b1/lib"

require "rubygems"
require "ruby_parser"
require "sexp_processor"
require "ruby2ruby"
require "siren"

class SirenSong < SexpProcessor
  VERSION = "1.0.0"

  def self.process rb
    rp  = RubyParser.new
    r2r = Ruby2Ruby.new
    ss  = self.new

    r2r.process ss.process rp.process rb
  end

  def dope type, sexp
    s(:or, s(:call, s(:const, :Siren), :play, s(:lit, type)), sexp)
  end

  def process_if exp
    _ = exp.shift # node type
    c = exp.shift
    t = exp.shift
    f = exp.shift

    s(:if,
      dope(:ifc, c),
      dope(:ift, t),
      dope(:iff, f))
  end
end
