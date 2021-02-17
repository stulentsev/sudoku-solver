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

  # parse input file, which should consist of 9 lines with 9 characters each.
  # missing digits must be represented as spaces.
  lines = File.readlines filename
  source = lines.map { |l| l.gsub("\n", '').split '' }

  solver = Solver.new source

  # work loop. On very hard puzzles may work for a long time (indefnitely?)
  working = solver.iter
  while working do
    working = solver.iter
  end

  # solution is found, hooray!
  solver.print_final
end
