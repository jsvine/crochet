#!/usr/bin/env ruby
# Note: Run this from the repo's base directory

lib = File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require "crochet"
require "test/unit"

class TestBefore < Test::Unit::TestCase
	def test_class_method
		$result = nil
		hook = Crochet::Hook.new(File) do
			before :open, :class do |filename|
				$result = filename
			end
		end
		File.open("README.md")
		hook.destroy
		assert $result == "README.md"
	end
	def test_instance_method
		$result = nil
		hook = Crochet::Hook.new(File) do
			before :read do |length|
				$result = length
			end
		end
		f = File.open("README.md")
		f.read(11)
		f.close
		hook.destroy
		assert $result == 11
	end
end

class TestAfter < Test::Unit::TestCase
	def test_class_method
		$result = nil
		$filename = nil
		hook = Crochet::Hook.new(File) do
			after :open, :class do |result, filename|
				$result = result
				$filename = filename
			end
		end
		File.open("README.md")
		hook.destroy
		assert $result.instance_of? File
		assert $filename == "README.md"
	end
	def test_instance_method
		$result = nil
		$length = nil
		hook = Crochet::Hook.new(File) do
			after :read do |result, length|
				$result = result
				$length = length
			end
		end
		f = File.open("README.md")
		f.read(11)
		f.close
		hook.destroy
		assert $result == "### Crochet"
		assert $filename == "README.md"
	end
end

class TestBeforeDestructive < Test::Unit::TestCase
	def test_class_method
		r = "README.md"
		pre_hook = File.open(r)
		hook = Crochet::Hook.new(File) do
			before! :open, :class do |filename|
				"lib/crochet.rb"
			end
		end
		post_hook = File.open(r)
		hook.destroy
		post_destroy = File.open(r)
		assert pre_hook.path != post_hook.path
		assert pre_hook.path == post_destroy.path
	end
	def test_instance_method
		r = "README.md"
		pre_hook = File.open(r).read(3)
		hook = Crochet::Hook.new(File) do
			before! :read do |length|
				[ 11 ]
			end
		end
		post_hook = File.open(r).read(3)
		hook.destroy
		post_destroy = File.open(r).read(3)
		assert pre_hook == "###"
		assert post_hook == "### Crochet"
		assert post_destroy == "###"
	end
end

class TestAfterDestructive < Test::Unit::TestCase
	def test_class_method
		r = "README.md"
		pre_hook = File.mtime r
		hook = Crochet::Hook.new(File) do
			after! :mtime, :class do |result|
				result + 5*60
			end
		end
		post_hook = File.mtime r
		hook.destroy
		post_destroy = File.mtime r
		assert pre_hook != post_hook
		assert pre_hook == post_destroy
	end
	def test_instance_method
		f = File.open("README.md")
		pre_hook = f.mtime
		hook = Crochet::Hook.new(File) do
			after! :mtime do |result|
				result + 5*60
			end
		end
		post_hook = f.mtime
		hook.destroy
		post_destroy = f.mtime
		assert pre_hook != post_hook
		assert pre_hook == post_destroy
	end
end
