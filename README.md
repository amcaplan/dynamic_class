[![Gem Version](https://badge.fury.io/rb/dynamic_class.svg)](https://badge.fury.io/rb/dynamic_class)
[![Build Status](https://travis-ci.org/amcaplan/dynamic_class.svg?branch=master)](https://travis-ci.org/amcaplan/dynamic_class)
[![Code Climate](https://codeclimate.com/github/amcaplan/dynamic_class.png)](https://codeclimate.com/github/amcaplan/dynamic_class)

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
dog.ears = 'droopy'
dog[:nose] = ['cold', 'wet']
dog['tail'] = 'waggable'
dog
# => #<Animal:0x007fc26b1841d0 @type="dog", @sound="woof", @ears="droopy", @nose=["cold", "wet"], @tail="waggable">
dog.type
# => "dog"
dog.tail
# => "waggable"

cat = Animal.new
# => #<Animal:0x007fdb2b83b180>
cat.to_h
# => {:type=>nil, :sound=>nil, :ears=>nil, :nose=>nil, :tail=>nil}
# The class has been changed by the dog!
```

Because methods are defined on the class (unlike `OpenStruct` which defines
methods on the object's singleton class), there is no need to define a method
more than once. This means that, past the first time a property is added,
the cost of setting a property drops.

The results are pretty astounding. Here are the results of the benchmark in
`bin/benchmark.rb` (including a few other `OpenStruct`-like solutions for
comparison), run on Ruby 2.3.1; the final benchmark is most representative of
the average case:

```
Initialization benchmark

Warming up --------------------------------------
          OpenStruct    84.801k i/100ms
PersistentOpenStruct    74.901k i/100ms
      OpenFastStruct    81.303k i/100ms
        DynamicClass    97.024k i/100ms
        RegularClass   211.767k i/100ms
Calculating -------------------------------------
          OpenStruct      1.104M (± 5.8%) i/s -      5.512M in   5.011886s
PersistentOpenStruct    941.181k (± 5.2%) i/s -      4.719M in   5.027485s
      OpenFastStruct      1.020M (± 6.0%) i/s -      5.122M in   5.040500s
        DynamicClass      1.309M (± 4.0%) i/s -      6.598M in   5.049905s
        RegularClass      4.170M (± 4.0%) i/s -     20.965M in   5.036315s

Comparison:
        RegularClass:  4169602.6 i/s
        DynamicClass:  1308644.3 i/s - 3.19x slower
          OpenStruct:  1103594.3 i/s - 3.78x slower
      OpenFastStruct:  1019939.5 i/s - 4.09x slower
PersistentOpenStruct:   941180.6 i/s - 4.43x slower



Assignment Benchmark

Warming up --------------------------------------
          OpenStruct   216.147k i/100ms
PersistentOpenStruct   210.657k i/100ms
      OpenFastStruct   101.072k i/100ms
        DynamicClass   311.870k i/100ms
        RegularClass   312.066k i/100ms
Calculating -------------------------------------
          OpenStruct      4.505M (± 5.0%) i/s -     22.479M in   5.003206s
PersistentOpenStruct      4.515M (± 5.0%) i/s -     22.540M in   5.005895s
      OpenFastStruct      1.383M (± 3.5%) i/s -      6.974M in   5.048792s
        DynamicClass     11.138M (± 5.0%) i/s -     55.825M in   5.026293s
        RegularClass     11.069M (± 5.8%) i/s -     55.236M in   5.009156s

Comparison:
        DynamicClass: 11137717.4 i/s
        RegularClass: 11068826.7 i/s - same-ish: difference falls within error
PersistentOpenStruct:  4514966.3 i/s - 2.47x slower
          OpenStruct:  4505071.4 i/s - 2.47x slower
      OpenFastStruct:  1383122.4 i/s - 8.05x slower



Access Benchmark

Warming up --------------------------------------
          OpenStruct   259.543k i/100ms
PersistentOpenStruct   255.894k i/100ms
      OpenFastStruct   225.799k i/100ms
        DynamicClass   313.455k i/100ms
        RegularClass   313.982k i/100ms
Calculating -------------------------------------
          OpenStruct      6.744M (± 5.0%) i/s -     33.741M in   5.016060s
PersistentOpenStruct      6.863M (± 5.2%) i/s -     34.290M in   5.011129s
      OpenFastStruct      4.717M (± 4.5%) i/s -     23.709M in   5.036478s
        DynamicClass     11.467M (± 5.9%) i/s -     57.362M in   5.021761s
        RegularClass     11.395M (± 6.6%) i/s -     56.831M in   5.011823s

Comparison:
        DynamicClass: 11467320.5 i/s
        RegularClass: 11395421.4 i/s - same-ish: difference falls within error
PersistentOpenStruct:  6862609.3 i/s - 1.67x slower
          OpenStruct:  6744325.9 i/s - 1.70x slower
      OpenFastStruct:  4717334.0 i/s - 2.43x slower



All-Together Benchmark

Warming up --------------------------------------
          OpenStruct    13.929k i/100ms
PersistentOpenStruct    64.546k i/100ms
      OpenFastStruct    45.014k i/100ms
        DynamicClass    96.783k i/100ms
        RegularClass   197.149k i/100ms
Calculating -------------------------------------
          OpenStruct    147.361k (± 4.8%) i/s -    738.237k in   5.021813s
PersistentOpenStruct    766.793k (± 5.8%) i/s -      3.873M in   5.069128s
      OpenFastStruct    525.565k (± 4.1%) i/s -      2.656M in   5.062072s
        DynamicClass      1.251M (± 4.0%) i/s -      6.291M in   5.038697s
        RegularClass      3.758M (± 4.1%) i/s -     18.926M in   5.046044s

Comparison:
        RegularClass:  3757567.8 i/s
        DynamicClass:  1250634.2 i/s - 3.00x slower
PersistentOpenStruct:   766792.7 i/s - 4.90x slower
      OpenFastStruct:   525565.1 i/s - 7.15x slower
          OpenStruct:   147361.4 i/s - 25.50x slower
```

`DynamicClass` is still behind plain old Ruby classes, but it's the best out of
the pack when it comes to `OpenStruct` and friends.

## WARNING!

This class should only be used to consume trusted APIs, or for similar purposes.
It should never be used to take in user input. This will open you up to a memory
leak DoS attack, since every new key becomes a new method defined on the class,
and is never erased.

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

