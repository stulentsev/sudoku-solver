#! /usr/bin/env ruby

require 'rainbow'
require_relative 'solver'

if ARGV.length == 0
  puts "Usage: ./solve file.txt"
else
  filename = ARGV[0]
  unless File.exists? filename
    puts "#{filename} not found."
    exit(0)
  end

  lines = File.readlines filename
  source = lines.map{|l| l.gsub("\n", '').split ''}

  solver = Solver.new source

  loop while solver.iter
  solver.print_result :current
end