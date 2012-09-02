---
title: "Making Siren Song"
date: 2012-08-28T12:00:00-07:00
...

I'm documenting every step it takes me to make a new project, named "Siren Song".

To start, I'm in emacs, fullscreen, split vertically, with a shell
running in emacs.

+ Use `sow -d siren_song` to generate the project template. The option
  is only necessary to create the directory structure I use in
  perforce.

+ `cd siren_song/dev`

+ `M-x autotest` to fire up autotest with emacs integration. There is
  a dummy test that fails. I rename it to `test_usecase` and change
  the flunk message to "Not done yet". This will let me run a
  continously failing test case until the top level design is flushed
  out and I'm happy with it. This is how I spike with TDD.

+ So, now I'm looking at the test code on the left and autotest on the
  right with a single failure saying I'm not done writing this usecase.

Now would be a good time to talk about what I want Siren Song to do. I
want it to "sing" my code as I run it. I don't entirely know what that
means at this point, but it's a good enough starting point to get my
first test case written. That's the whole point of a spike, right?

So, at this point all I know what I want to do is to be able to dope
some code with extra calls, let's start with if statements only just
to get everything in place.

+ Start by filling out the test with the basic structure of the
top-level code. Leave the flunk in so that once I get the test
actually passing, I'm still failing and can judge if I have more to do
for this usecase. To start, I have a basic `if` statement and no real
expected output (because I don't know what I actually want yet). It
looks like:

``` ruby
  def test_usecase
    rb = "if 1 then 2 else 3 end"
    pt = 42

    actual = SirenSong.process rb

    assert_equal pt, actual

    flunk "Not done yet"
  end
```

and my first real error is that `process` doesn't exist on SirenSong
yet. That's easy enough to add:

``` ruby
  def self.process rb
  end
```

Now my failure is a bogus "expected 42, actual nil". OK. So to start,
let's get the raw sexp back. That involves adding ruby_parser and
getting it parsing the input.

First, because I'm lazy and on an airplane, I cheat and point straight
at my ruby_parser:

``` ruby
$: << "../../ruby_parser/3.0.0.a6/lib"
$: << "../../sexp_processor/4.0.1/lib"

require "rubygems"
require "ruby_parser"
```

I'm going to test against my latest alpha releases because they have
changes that make my expected output cleaner and I don't want to have
to modify them later when the alpha goes beta and then final.

Then I change my implementation:

``` ruby
  def self.process rb
    RubyParser.new.process rb
  end
```

Now my failure at least makes sense. I take the actual output and
merge it into my test to get it to pass... I'm back to my "not done
yet" flunk:

``` ruby
    pt = s(:if,
           s(:lit, 1),
           s(:lit, 2),
           s(:lit, 3))
```

(Why did I use 1-3? Because they're stupid and short)

At this point, I need to think about what sort of code-doping I want
to do. It seems easiest for me to replace all `X` that I want to dope
with `(or Y, X)` where `Y` is my doping code and always returns false.

In the case of my if statement, I want to dope all 3 parts, the
conditional, the truthy side, and the falsey side. It should look
something like:

``` ruby
    pt = s(:if,
           s(:or, s(:xxx), s(:lit, 1)),
           s(:or, s(:xxx), s(:lit, 2)),
           s(:or, s(:xxx), s(:lit, 3)))
```

and we'll figure out what `xxx` should be later...

So, pop that into the test, and our failure will change back to
assert_equal. Switch back te the impl and let's do something with it.
The first thing I want to do is to change the class to subclass from
SexpProcessor:

``` ruby
require "sexp_processor"

class SirenSong < SexpProcessor
  # ...
end
```

No change. Next, instantiate a SexpProcessor and add a call to its process method:

``` ruby
  def self.process rb
    pt = RubyParser.new.process rb
    self.new.process pt
  end
```

Still no change. This is great. I'm now plugged into a very powerful
framework and its working just like the start of my spike. Now to
really play! To see that I'm fully plugged in, I add the following:

``` ruby
  def process_if exp
    raise "No"
  end
```

My test switches from a failing `assert_equal` over to a RuntimeError.
BOOM! It's taken me about 5 minutes from creating the project to
having the spike to a real failure worth writing real implementation
for. Not bad.

It's time to put some meat in:

``` ruby
  def process_if exp
    _ = exp.shift # node type
    c = exp.shift
    t = exp.shift
    f = exp.shift

    s(:if, c, t, f)
  end
```

This deconstructs the `if` node and reassembles it. My `assert_equal`
is back again and looks exactly the same as before. Perfect.

To get the test to pass is trivial at this point:

``` ruby
    s(:if,
      s(:or, s(:xxx), c),
      s(:or, s(:xxx), t),
      s(:or, s(:xxx), f))
```

I have doped code! Well. I have doped sexps. That's close enough for
now. Let's figure out what `xxx` should be. I want my code to sing. I
want to be able to hear my code run in such a way that I should know
what sounds right and be able to pattern match when it starts to do
something differently. To start, I'm going to create a new class
`Siren` and put it in a different file.

``` ruby
require "siren"
```

``` ruby
# siren.rb
class Siren
end
```

Now I want `xxx` to be a call on Siren. So I change the test to be:

``` ruby
    pt = s(:if,
           s(:or, s(:call, s(:const, :Siren), :play, s(:lit, :ifc)), s(:lit, 1)),
           s(:or, s(:call, s(:const, :Siren), :play, s(:lit, :ift)), s(:lit, 2)),
           s(:or, s(:call, s(:const, :Siren), :play, s(:lit, :iff)), s(:lit, 3)))
```

and make exactly the same type of change over in the implementation:

``` ruby
  def process_if exp
    _ = exp.shift # node type
    c = exp.shift
    t = exp.shift
    f = exp.shift

    s(:if,
      s(:or, s(:call, s(:const, :Siren), :play, s(:lit, :ifc)), c),
      s(:or, s(:call, s(:const, :Siren), :play, s(:lit, :ift)), t),
      s(:or, s(:call, s(:const, :Siren), :play, s(:lit, :iff)), f))
  end
```

and I'm back to "Not done yet". Good. Time to refactor by extracting
the doping structure into it's own method:

``` ruby
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
```

Because the tests are getting wide and ugly, I do the same there
slightly differently:

``` ruby
  def dope type
    s(:call, s(:const, :Siren), :play, s(:lit, type))
  end

  # and:

    pt = s(:if,
           s(:or, dope(:ifc), s(:lit, 1)),
           s(:or, dope(:ift), s(:lit, 2)),
           s(:or, dope(:iff), s(:lit, 3)))
```

Now let's make this real. It's time to have the top level test provide
us with actual code. Let's start by making the test fail with the
expected ruby code that should come out. Since I don't know what that
looks like exactly, I just add it to the test:

``` ruby
    assert_equal 42, Ruby2Ruby.new.process(pt)
```

and then the failure shows me that it should be:

``` ruby
if (Siren.play(:ifc) or 1) then
  (Siren.play(:ift) or 2)
else
  (Siren.play(:iff) or 3)
end
```

which, after visually checking it, I agree with. So now I can change the test:

``` ruby
  def cleanup s
    s.gsub(/^ {6}/, '').chomp
  end

  # added to the test:

    rb2 = cleanup <<-RUBY
      if (Siren.play(:ifc) or 1) then
        (Siren.play(:ift) or 2)
      else
        (Siren.play(:iff) or 3)
      end
    RUBY

    assert_equal rb2, Ruby2Ruby.new.process(pt)
```

(cleanup + indented heredoc is a common pattern in my parsing tests...
much more readable... pretty much the only heredocs I use)

and we're back to "Not done yet". Good. Since that code doesn't belong
in the test, let's push that back into SirenSong. I pull the middle of
the test out and rearrange it so it expects ruby code output:

``` ruby
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

    flunk "Not done yet"
  end
```

which brings me to a lovely failure where it is expecting the ruby
output but is still getting the sexp. Let's push the old test code
into the implementation. **This is exactly how I prototype new
implementations within a TDD process**. Here's my implementation that
causes the test to pass:

``` ruby
  def self.process rb
    rp  = RubyParser.new
    r2r = Ruby2Ruby.new
    ss  = self.new

    r2r.process ss.process rp.process rb
  end
```

Look at that gorgeous pipeline. Ruby in, generate a sexp, dope the
sexp, generate ruby from that. _Drool_.

OK. So, we've got doped code. But no implementation behind that. Let's
take a look at what that should look like by making it fail:

``` ruby
    # added to the end of the test:
    eval actual
```

Ouch! No method `play` on `Siren`. Let's fix that:

``` ruby
class Siren
  def self.siren
    Thread.current[:siren] ||= Siren.new
  end

  def self.play type
    siren.play type
  end

  def play type
    raise "not yet"
  end
end
```

So all I've really done is push the error down to an instance of
Siren. This skips a few steps but I had it in the back of my head the
entire time so I don't mind. So now I've got a Siren instance per
thread and I want to verify that they play _something_ for the if
statement. Time to stub:

``` ruby
    siren = []
    def siren.play type
      self << type
      nil
    end
    Thread.current[:siren] = siren

    assert_equal 2, eval(actual)

    assert_equal [:ifc, :ift], siren
```

This ensures the Siren instance is hooked in and being triggered via
the class method properly.

Since I'm on a plane, I can't hook in the midi code. First, I don't
have the midiator gem. I could start hacking the code in from my
rubygems-sing code, but that would derail my test. I'd rather add a BS
implementation and test that I'm getting the right input only. So for
now, I comment out my test stub code so I can address the raise.

To start, I change the test to assert that the play method prints out
a phony "note":

``` ruby
    out = cleanup <<-OUT
      Siren.play 1, :ifc
      Siren.play 1, :ift

    OUT

    assert_output out do
      assert_equal 2, eval(actual)
    end
```

and to get that to pass, I extend siren to know its instance count and
then to print count, play type, and how deep we are when called:

``` ruby
  @@count = 0

  attr_accessor :count

  def initialize
    @@count += 1
    @count = @@count
  end

  def play type
    puts "Siren.play #{count}, :#{type}"
  end
```

At this point, I'm as done as I'm going to be on a plane. I remove the
flunk line and strip the dead code out of the test.

Things I still need to do:

+ Figure out what it should sound like
+ Dope while/until, call, and/or, and other node types.
+ Figure out how to make threads sound different enough you can tell them apart.
+ Write more tests, obviously. 
