class Solver
  def initialize arr
    @source_array = arr
    @working_array = deep_clone arr
    @states = []
  end

  def iter
    @next_version = deep_clone @working_array
    changed = false
    has_multiple = false
    (0..8).each do |r|
      (0..8).each do |c|
        next if @working_array[r][c] != ' '

        options = (1..9).to_a.map(&:to_s) - get_row(r) - get_column(c) - get_quadrant(r, c)
        if options.length == 1
          #puts "(#{r}, #{c}) => #{options[0]}"
          @working_array[r][c] = options[0]
          changed = true
        else
          @next_version[r][c] = options
          has_multiple = true
        end
      end
    end

    if !changed && has_multiple
      push_state
      r, c, o = pick_random_option
      if o
        @working_array[r][c] = o
      else
        if @states.length >= 5
          restore_original_state
        else
          pop_state
        end
      end
      changed = true
    end

    changed
  end


  def print_result
    arr = @next_version

    (0..8).each do |r|
      (0..8).each do |c|
        el = arr[r][c]
        if el.is_a? Array
          print el.join(',').foreground(:red)
        else
          if @source_array[r][c] != ' '
            print el.foreground(:blue)
          else
            print el.foreground(:green)
          end
        end

        print "\t"
      end
      puts ""
    end
  end

  def get_row r
    res = @working_array[r].select { |i| i != ' ' }
    #puts "row #{r}: #{res.join '|'}"
    res
  end

  def get_column c
    res = []
    (0..8).each do |r|
      el = @working_array[r][c]
      res << el if el != ' '
    end

    #puts "column #{c}: #{res.join '|'}"
    res
  end

  def get_quadrant r, c
    r1 = r / 3 * 3
    c1 = c / 3 * 3

    res = []
    (r1..r1+2).each do |r2|
      (c1..c1+2).each do |c2|
        el = @working_array[r2][c2]
        res << el if el != ' '
      end
    end

    #puts "quadrant #{r1}, #{c1}: #{res.join ','}"
    res
  end

  def pick_random_option
    begin
      r = rand(9)
      c = rand(9)
      el = @next_version[r][c]
      print "\rrandom for (#{r}, #{c}) = #{el.inspect}, stack depth = #{@states.length}                            "
      STDOUT.flush
    end while !el.is_a?(Array)

    [r, c, el.sample]
  end

  def deep_clone obj
    Marshal.load( Marshal.dump(obj) )
  end

  def push_state
    @states << deep_clone(@working_array)
    #puts "pushed, length = #{@states.length}"
  end

  def pop_state
    @working_array = deep_clone @states.pop
    #puts "popped, length = #{@states.length}"
  end

  def restore_original_state
    @working_array = deep_clone @states.first
    @states = []
    puts "restored"
    puts ""
    #puts "popped, length = #{@states.length}"
  end
end