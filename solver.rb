class Solver
  def initialize arr
    @source_array = arr
    @working_array = Marshal.load( Marshal.dump(arr) )
  end

  def iter
    @next_version = Marshal.load( Marshal.dump(@working_array) )
    changed = false
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
        end
      end
    end
    changed
  end


  def print_result
    arr = @next_version

    (0..8).each do |r|
      (0..8).each do |c|
        if @source_array[r][c] != ' '
          print arr[r][c].foreground(:blue)
        else
          print arr[r][c].foreground(:green)
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
end