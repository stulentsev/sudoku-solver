# frozen_string_literal: true

require_relative "../boot"

class Board
  Error = Class.new(StandardError)
  UnsupportedValueError = Class.new(Error)
  OutOfRangeError = Class.new(Error)

  WIDTH = 9
  HEIGHT = 9
  EMPTY = " "

  def self.from_string(str)
    board = new
    str.lines[0..WIDTH - 1].each_with_index do |line, r|
      line[0..HEIGHT - 1].each_char.with_index do |char, c|
        v = case char
            when /\A[0-9]\z/
              char.to_i
            else
              EMPTY
            end
        board.set_value(r, c, v)
      end
    end
    board
  end

  def self.copy_from(board)
    new(board)
  end

  def initialize(source_board = nil)
    @storage = Array.new(WIDTH * HEIGHT) { EMPTY }

    if source_board
      source_board.each_cell_value do |r, c, v|
        set_value(r, c, v.dup)
      end
    end
  end

  def each_cell_value(&block)
    storage.each_with_index do |v, idx|
      r = idx / WIDTH
      c = idx % WIDTH
      block.call(r, c, v)
    end
  end

  def get_row(r)
    storage[r * WIDTH, HEIGHT]
  end

  def get_column(c)
    (0...HEIGHT).map { |r| get_value(r, c) }
  end

  def get_value(r, c)
    if r < 0 || r >= WIDTH || c < 0 || c >= HEIGHT
      raise OutOfRangeError, "r = #{r}, c = #{c}"
    end
    storage[r * WIDTH + c]
  end

  def set_value(r, c, v)
    if r < 0 || r >= WIDTH || c < 0 || c >= HEIGHT
      raise OutOfRangeError, "r = #{r}, c = #{c}"
    end

    case v
    when Integer, String, Array
      storage[r * WIDTH + c] = v
    else
      raise UnsupportedValueError, "value was #{v.inspect}"
    end
  end

  def empty?(r, c)
    get_value(r, c) == EMPTY
  end

  private

  attr_reader :storage
end
