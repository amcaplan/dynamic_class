# DynamicClass

Many developers use `OpenStruct` as a convenient way of consuming APIs through
a nifty data object. But the performance penalty is pretty awful.

`DynamicClass` offers a better solution, optimizing for the case where you
need to create objects with the same set of properties every time, but you
can't define the needed keys until runtime. `DynamicClass` works by defining
instance methods on the class every time it encounters a new propery.

Let's see it in action:

``` ruby
Animal = DynamicClass.new do
  def speak
    "The #{type} makes a #{sound} sound!"
  end
end

dog = Animal.new(type: 'dog', sound: 'woof')
# => #<Animal:0x007fdb2b818ba8 @type="dog", @sound="woof">
dog.speak
# => The dog makes a woof sound!

cat = Animal.new
# => #<Animal:0x007fdb2b83b180>
cat.to_h
# => {:type=>nil, :sound=>nil}
# The class has been changed by the dog!
```

Because methods are defined on the class (unlike `OpenStruct` which defines
methods on the object's singleton class), there is no need to define a method
more than once. This means that, past the first time a property is added,
the cost of setting a property drops.

The results are pretty astounding. Here are the results of the benchmark in
`bin/benchmark.rb` (including a few other `OpenStruct`-like solutions for
comparison):

```
Initialization benchmark

Calculating -------------------------------------
          OpenStruct    11.183k i/100ms
PersistentOpenStruct    46.448k i/100ms
      OpenFastStruct    47.295k i/100ms
        DynamicClass    47.797k i/100ms
        RegularClass   101.410k i/100ms
-------------------------------------------------
          OpenStruct    138.431k (±13.8%) i/s -    682.163k
PersistentOpenStruct    757.737k (± 5.3%) i/s -      3.809M
      OpenFastStruct    783.310k (± 6.0%) i/s -      3.925M
        DynamicClass    766.130k (± 3.6%) i/s -      3.872M
        RegularClass      3.037M (± 7.2%) i/s -     15.110M

Comparison:
        RegularClass:  3037473.6 i/s
      OpenFastStruct:   783309.5 i/s - 3.88x slower
        DynamicClass:   766129.7 i/s - 3.96x slower
PersistentOpenStruct:   757736.8 i/s - 4.01x slower
          OpenStruct:   138430.6 i/s - 21.94x slower



Assignment Benchmark

Calculating -------------------------------------
          OpenStruct   107.675k i/100ms
PersistentOpenStruct   108.952k i/100ms
      OpenFastStruct    59.163k i/100ms
        DynamicClass   133.406k i/100ms
        RegularClass   134.345k i/100ms
-------------------------------------------------
          OpenStruct      3.511M (± 4.2%) i/s -     17.551M
PersistentOpenStruct      3.491M (± 4.3%) i/s -     17.432M
      OpenFastStruct    950.760k (± 4.8%) i/s -      4.792M
        DynamicClass      8.891M (± 5.7%) i/s -     44.291M
        RegularClass      8.939M (± 5.8%) i/s -     44.603M

Comparison:
        RegularClass:  8939463.2 i/s
        DynamicClass:  8890563.0 i/s - 1.01x slower
          OpenStruct:  3511253.2 i/s - 2.55x slower
PersistentOpenStruct:  3491119.3 i/s - 2.56x slower
      OpenFastStruct:   950760.2 i/s - 9.40x slower



Access Benchmark

Calculating -------------------------------------
          OpenStruct   121.935k i/100ms
PersistentOpenStruct   122.673k i/100ms
      OpenFastStruct   111.492k i/100ms
        DynamicClass   136.066k i/100ms
        RegularClass   135.946k i/100ms
-------------------------------------------------
          OpenStruct      5.603M (± 6.1%) i/s -     27.923M
PersistentOpenStruct      5.613M (± 5.8%) i/s -     27.969M
      OpenFastStruct      3.683M (± 6.9%) i/s -     18.396M
        DynamicClass      9.674M (± 5.8%) i/s -     48.167M
        RegularClass      9.809M (± 5.5%) i/s -     48.941M

Comparison:
        RegularClass:  9808944.8 i/s
        DynamicClass:  9674457.9 i/s - 1.01x slower
PersistentOpenStruct:  5612626.6 i/s - 1.75x slower
          OpenStruct:  5603365.4 i/s - 1.75x slower
      OpenFastStruct:  3683298.4 i/s - 2.66x slower



All-Together Benchmark

Calculating -------------------------------------
          OpenStruct    11.371k i/100ms
PersistentOpenStruct    41.683k i/100ms
      OpenFastStruct    30.589k i/100ms
        DynamicClass    52.041k i/100ms
        RegularClass   100.225k i/100ms
-------------------------------------------------
          OpenStruct    136.382k (±14.6%) i/s -    659.518k
PersistentOpenStruct    647.752k (± 4.4%) i/s -      3.251M
      OpenFastStruct    416.183k (± 5.4%) i/s -      2.080M
        DynamicClass    827.546k (± 4.3%) i/s -      4.163M
        RegularClass      3.034M (± 6.6%) i/s -     15.134M

Comparison:
        RegularClass:  3033808.8 i/s
        DynamicClass:   827546.3 i/s - 3.67x slower
PersistentOpenStruct:   647751.5 i/s - 4.68x slower
      OpenFastStruct:   416183.1 i/s - 7.29x slower
          OpenStruct:   136382.0 i/s - 22.24x slower
```

`DynamicClass` is still behind plain old Ruby classes, but it's the best (or
effectively tied for best) out of the pack when it comes to `OpenStruct` and
friends.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'dynamic_class'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install dynamic_class

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`rake spec` to run the tests. You can run the benchmark using `rake benchmark`.
You can also run `bin/console` for an interactive prompt that will allow you to
experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome. This project is intended to be a
safe, welcoming space for collaboration, and contributors are expected to adhere
to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

For functionality changes or bug fixes, please include tests. For performance
enhancements, please run the benchmarks and include results in your pull
request.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

