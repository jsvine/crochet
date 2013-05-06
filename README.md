### Crochet

Hook into and/or monkeypatch any Ruby class- or instance-method. Provides `before` and `after` hooks, plus their destructive evil twins.

To install via RubyGems: `gem install crochet`

.. or just place [crochet.rb](lib/crochet.rb) in your load path.

## Usage

The `Crochet` module contains only one class, `Hook`. Instantiate `Crochet::Hook` with the class you're targeting:

```ruby
file_hook = Crochet::Hook.new(File)
```

### `before` and `after`

Crochet hooks have two non-destructive methods — `before` and `after`.

Each method accepts two arguments and a block. The first argument is the symbol-ization of the method name you're targeting, and is required. 

The second argument indicates the type of method you're targeting — `:instance` by default, or `:class`. 

Finally, each hook method expects a block, which it will execute in the context of the instance or class you're targeting. `before` and `before!` blocks receive the same arguments as the method you're targeting. `after` and `after!` receive the result of the method you're targeting, followed by the arguments it received. 

Some examples, building on the example above:

```ruby
file_hook.before :open, :class do |filename|
	STDERR.write "About to open #{filename}\n"
end
```

```ruby
file_hook.after :read do |result, length|
	length ||= "all"
	STDERR.write "Just read #{length} bytes from #{self.path}. "
	STDERR.write "It says: \n#{result}\n\n"
end
```

These hooks will trigger when executing code such as:

```ruby
file = File.open("README.md")
file.read(11)
```

You can also define all your hooks within a block passed to `Crochet::Hook.new`. So the following code would have the same effect as above:

```ruby
Crochet::Hook.new(File) do
	before :open, :class do |filename|
		STDERR.write "About to open #{filename}\n"
	end
	after :read do |result, length|
		length ||= "all"
		STDERR.write "Just read #{length} bytes from #{self.path}. "
		STDERR.write "It says: \n#{result}\n\n"
	end
end
```

## `before!` and `after!`

Crochet hooks also have two destructive methods, which can be useful for monkeypatching: `before!` and `after!`. They operate identically to their non-destructive twins, __except__:

- The return value of `before!` should be an array and will override the arguments that your targeted method will receive.

- The return value of `after!` will override your targeted method's return value. 

A couple trivial examples:

``ruby
Crochet::Hook.new(File) do
	before! :mtime, :class do |filename|
		[ File.expand_path "~/.bashrc" ]
	end
end
```

The hook above would make every call to, say, File.mtime("README.md") instead evaluate the last time your `.bashrc` file was modified.

```ruby
Crochet::Hook.new(File) do
	after! :mtime, :class do |result, filename|
		STDERR.write "#{filename} was last modified at #{result}.\n
		STDERR.write "Let's push it 5 minutes into the future.\n"
		result + 5*60
	end
end
```

In the example above, calls to File.mtime("README.md") will return a timestamp 5 minutes beyond the file's true modification time.

## `destroy`

Crochet hooks also have a `destroy` method, which takes no arguments and restores all the overriden class- and instance-methods to their original state. For example:

```ruby 
hook = Crochet::Hook.new(File) do
	before! :read, :class do |filename|
		[ "papayaWhip.txt" ]
	end
	after :read, :instance do |result, length|
		STDERR.write "#{length}\n"
	end
end

hook.destroy
```

... should have no effect on your program — except for a very, very slight performance hit.

## Misc.

- There are at least several [other](https://github.com/apotonick/hooks) [hook](https://github.com/avdi/hookr) [libraries](https://github.com/kristinalim/ruby_hooks) for Ruby. This aims to be the simplest, and is more geared toward hooking into core and third-party classes than self-written code.

- *Crochet* is French for *hook*. Super clever, right?

