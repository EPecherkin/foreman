$:.unshift File.expand_path("../lib", __FILE__)
require "foreman/version"

Gem::Specification.new do |gem|
  gem.name     = "foremine"
  gem.license  = "MIT"
  gem.version  = Foreman::VERSION

  gem.author   = "David Dollar"
  gem.email    = "ddollar@gmail.com"
  gem.homepage = "https://github.com/ddollar/foreman"
  gem.summary  = "Process manager for applications with multiple components"

  gem.description = gem.summary

  gem.executables = "foremine"
  gem.files = Dir["**/*"].select { |d| d =~ %r{^(README|bin/|data/|ext/|lib/|spec/|test/)} }
  gem.files << "man/foreman.1"
end
