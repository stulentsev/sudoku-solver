require "bundler"
Bundler.require

Dir.glob("src/*.rb").each { |f| require_relative(f) }
