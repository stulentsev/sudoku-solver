# This is implementation of sudoku solver logic. It employs a couple of formal rules
# and a random recursive search.
# Basically, it works like this: 
#   1. Take working field W. Find all empty cells for which we can determine the value
#      with certainty. Remember these choices in a future version F.
#   2. Repeat step 1, but use the knowledge gained in it (use both W and F for 
#      eliminating wrong results).
#   3. If any new cell values are found, then set W = F and go to step 1. Otherwise, if 
#      there are cells with multiple candidates for a value, then remember this state, 
#      pick one of those candidates and go to step 1. If state stack size exceeds N, then
#      pop the original state and do over (we must have made the wrong random choice
#      back then).
class Solver
  def initialize arr
    @source_array = arr
    @working_array = deep_clone arr
    @states = []
  end

  def pass1
    changed = false
    (0..8).each do |r|
      (0..8).each do |c|
        next if @working_array[r][c] != ' '

        options = (1..9).to_a.map(&:to_s) - get_row(r) - get_column(c) - get_quadrant(r, c)
        if options.length == 1
          @working_array[r][c] = options[0]
          changed = true
        elsif options.length == 0
          @no_options = true
        else
          @next_version[r][c] = options
          @has_multiple = true
        end
      end
    end
    changed
  end

  def pass2
    changed = false
    (0..8).each do |r|
      (0..8).each do |c|
        next if @working_array[r][c] != ' '

        options = (1..9).to_a.map(&:to_s) - get_row(r, :next) - get_column(c, :next) - get_quadrant(r, c, :next)
        if options.length == 1
          @working_array[r][c] = options[0]
          changed = true
        elsif options.length == 0
        else
          @next_version[r][c] = options
          @has_multiple = true
        end
      end
    end
    changed
  end

  def iter
    @next_version = deep_clone @working_array

    @has_multiple = false
    @no_options = false

    changed = pass1 || pass2


    if @no_options
      puts "popped"
      print_result
      puts "\n\n"

      pop_state
      changed = true
    else
      if !changed && @has_multiple
        push_state

        puts "pushed"
        print_result
        puts "\n\n"

        if @states.length >= 5
          restore_original_state
        else
          r, c, o = pick_random_option
          if o
            @working_array[r][c] = o
          else
            pop_state
          end
        end
        changed = true
      end
    end


    changed
  end


  def print_result
    arr = @next_version

    (0..8).each do |r|
      (0..8).each do |c|
        el = arr[r][c]
        print '|'

        if el.is_a? Array
          print el.join(',').foreground(:red)
        else
          if @source_array[r][c] != ' '
            print el.foreground(:blue)
          else
            print el.foreground(:green)
          end
        end
        print '|'

        print "\t"
      end
      puts ""
    end
  end

  def get_row r, version = :working
    res = @working_array[r].select { |i| i != ' ' }

    res += @working_array[r].select { |i| i != ' ' } if version == :next
    res.flatten
  end

  def get_column c, version = :working
    res = []
    (0..8).each do |r|
      el = @working_array[r][c]
      res << el if el != ' '
    end

    if version == :next
      (0..8).each do |r|
        el = @next_version[r][c]
        res << el if el != ' '
      end
    end

    res.flatten
  end

  def get_quadrant r, c, version = :working
    r1 = r / 3 * 3
    c1 = c / 3 * 3

    res = []
    (r1..r1+2).each do |r2|
      (c1..c1+2).each do |c2|
        el = @working_array[r2][c2]
        res << el if el != ' '
      end
    end

    if version == :next
      (r1..r1+2).each do |r2|
        (c1..c1+2).each do |c2|
          el = @next_version[r2][c2]
          res << el if el != ' '
        end
      end
    end

    res.flatten
  end

  def pick_random_option
    begin
      r = rand(9)
      c = rand(9)
      el = @next_version[r][c]
    end while !el.is_a?(Array)

    els = el.sample
    puts "\rrandom for (#{r}, #{c}) = #{els}, stack depth = #{@states.length}                            "

    [r, c, els]
  end

  def deep_clone obj
    Marshal.load(Marshal.dump(obj))
  end

  def push_state
    @states << deep_clone(@working_array)
  end

  def pop_state
    @working_array = deep_clone @states.pop
  end

  def restore_original_state
    @working_array = deep_clone @states.first
    @states = []
    puts "restored"
    puts ""
  end
end