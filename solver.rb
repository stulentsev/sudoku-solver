class Solver
  def initialize arr
    @source_array = arr
    @working_array = @source_array.dup
    @next_version = @working_array.dup

  end

  def iter
    (0..8).each do |r|
      (0..8).each do |c|
        next if @working_array[r][c] != ' '

        options = (1..9).to_a.map(&:to_s) - get_row(r) - get_column(c) - get_quadrant(r, c)
        if options.length == 1
          @working_array[r][c] = options[0]
          return true
        else
          @next_version[r][c] = options
        end
      end
    end
    false
  end


  def print_result what = :current
    arr = case what
            when :current
              @working_array
            when :original
              @source_array
            when :next
              @next_version
            else
              []
          end

    arr.each do |line|
      line.each do |el|
        if el.is_a? String
          print el.foreground(:blue)
        else
          print el.join(',').foreground(:green)
        end
        print "\t"
      end
      puts ""
    end
  end

  def get_row r
    @working_array[r].select { |i| i != ' ' }
  end

  def get_column c
    res = []
    (0..8).each do |r|
      el = @working_array[r][c]
      res << el if el != ' '
    end

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

    res
  end
end