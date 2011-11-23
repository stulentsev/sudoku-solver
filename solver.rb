class Solver
  def initialize arr
    @source_array = arr
    @working_array = deep_clone arr
    @states = []
    @tried = [[]]
  end

  def pass1
    changed = false
    (0..8).each do |r|
      (0..8).each do |c|
        next if @working_array[r][c] != ' '

        options = (1..9).to_a.map(&:to_s) - get_row(r) - get_column(c) - get_quadrant(r, c)
        if options.length == 1
          #puts "(#{r}, #{c}) => #{options[0]}"
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
          #@no_options = true
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

        # TODO: adfasdfadfasdf
        #   adfasdfkad;fadsf

        if el.is_a? Array
          print el.join(',').foreground(:red)
          #print el.inspect.foreground(:red)
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
    #puts "row #{r}: #{res.join '|'}"
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

    #puts "column #{c}: #{res.join '|'}"
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

    #puts "quadrant #{r1}, #{c1}: #{res.join ','}"
    res.flatten
  end

  def pick_random_option
    begin
      r = rand(9)
      c = rand(9)
      el = @next_version[r][c]
      #print "\rrandom for (#{r}, #{c}) = #{el.inspect}, stack depth = #{@states.length}                            "
      #STDOUT.flush
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