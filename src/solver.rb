require_relative "../boot"

# This is implementation of sudoku solver logic. It employs a couple of formal rules
# and a random recursive search.
# Basically, it works like this:
#   1. Take working field W. Find all empty cells for which we can determine the value
#      with certainty. Remember these choices in a future version F.
#   2. Repeat step 1, but use the knowledge gained in it (use both W and F for
#      eliminating wrong results).
#   3. If any new cell values are found, then set W = F and go to step 1. Otherwise, if
#      there are cells with multiple candidates for a value, then memorize current state,
#      pick one of those candidates and go to step 1. If state stack size exceeds N, then
#      pop the original state and do over (we must have made the wrong random choice
#      back then).
class Solver
  def initialize(board, ostream = STDOUT)
    @original_board = board
    @working_board = Board.copy_from(board)
    @states = []
    @push_tracker = {}
    @ostream = ostream
  end

  def solve
    begin
      working = iter
    end while working

    next_version
  end

  def pass1
    changed = false

    working_board.each_cell_value do |r, c, v|
      next unless working_board.empty?(r, c)

      options = (1..9).to_a - get_row(r) - get_column(c) - get_quadrant(r, c)
      case options.length
      when 0
        @no_options = true
      when 1
        working_board.set_value(r, c, options[0])
        changed = true
      else
        next_version.set_value(r, c, options)
        @has_multiple = true
      end
    end

    changed
  end

  def pass2
    changed = false

    working_board.each_cell_value do |r, c, v|
      next unless working_board.empty?(r, c)

      options = (1..9).to_a - get_row(r, :next) - get_column(c, :next) - get_quadrant(r, c, :next)
      if options.length == 1
        working_board.set_value(r, c, options[0])
        changed = true
      elsif options.length == 0
      else
        next_version.set_value(r, c, options)
        @has_multiple = true
      end
    end

    changed
  end

  def iter
    @next_version = Board.copy_from(working_board)

    @has_multiple = false
    @no_options = false

    changed = pass1 || pass2

    if no_options
      ostream.puts("popped")
      print_result
      ostream.puts("\n\n")

      pop_state
      changed = true
    else
      if !changed && has_multiple
        depth = push_state

        ostream.puts("pushed (depth: #{depth}, cnt: #{push_tracker[depth]} )")
        print_result
        ostream.puts("\n\n")

        if states.length >= 50 || push_tracker[depth] > 70
          restore_original_state
        else
          r, c, o = pick_random_option
          if o
            working_board.set_value(r, c, o)
          else
            pop_state
          end
        end
        changed = true
      end
    end

    changed
  end

  def get_row(r, version = :working)
    res = working_board.get_row(r)
    if version == :next
      res += next_version.get_row(r)
    end

    res.flatten
  end

  def get_column(c, version = :working)
    res = working_board.get_column(c)
    if version == :next
      res += next_version.get_column(c)
    end

    res.flatten
  end

  def get_quadrant(r, c, version = :working)
    r1 = r / 3 * 3
    c1 = c / 3 * 3

    res = []
    (r1..r1 + 2).each do |r2|
      (c1..c1 + 2).each do |c2|
        unless working_board.empty?(r2, c2)
          res << working_board.get_value(r2, c2)
        end
      end
    end

    if version == :next
      (r1..r1 + 2).each do |r2|
        (c1..c1 + 2).each do |c2|
          unless next_version.empty?(r2, c2)
            res << next_version.get_value(r2, c2)
          end
        end
      end
    end

    res.flatten
  end

  def pick_random_option
    begin
      r = rand(9)
      c = rand(9)
      el = next_version.get_value(r, c)
    end until el.is_a?(Array)

    els = el.sample
    ostream.puts("\rrandom for (#{r}, #{c}) = #{els}, stack depth = #{states.length}                            ")

    [r, c, els]
  end

  def push_state
    states << Board.copy_from(working_board)

    push_tracker[states.length] ||= 0
    push_tracker[states.length] += 1
    states.length
  end

  def pop_state
    @working_board = Board.copy_from(states.pop)
    states.length
  end

  def restore_original_state
    @working_board = Board.copy_from(states.first)
    @states = []
    @push_tracker = {}
    ostream.puts("restored")
    ostream.puts("")
  end

  private
  
  attr_reader :original_board, :working_board, :next_version, :states,
              :push_tracker, :has_multiple, :no_options, :ostream

  def print_result
    BoardPrinter.new(ostream).intermediate(next_version, original_board)
  end
end
