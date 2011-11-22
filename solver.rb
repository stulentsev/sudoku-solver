class Solver
  def initialize arr
    @source_array = arr
  end

  def print
    @source_array.each do |line|
      puts line.join('').foreground(:blue)
    end
  end
end