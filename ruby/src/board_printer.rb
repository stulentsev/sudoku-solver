require_relative "../boot"
class BoardPrinter

  def initialize(ostream = STDOUT)
    @ostream = ostream
  end

  def clean(board)
    board.each_cell_value do |r, c, v|
      ostream.print(v)
      ostream.print(" ") if c % 3 == 2
      ostream.puts("") if c == Board::HEIGHT - 1
      ostream.puts("") if r % 3 == 2 && c == Board::HEIGHT - 1
    end
  end

  def intermediate(board, source_board)
    board.each_cell_value do |r, c, el|
      ostream.print("|")

      if el.is_a?(Array)
        ostream.print(Rainbow(el.join(",")).foreground(:red))
      else
        if source_board.empty?(r, c)
          ostream.print(Rainbow(el).foreground(:blue))
        else
          ostream.print(Rainbow(el).foreground(:green))
        end
      end
      ostream.print "|"
      ostream.print "\t"
      ostream.puts "" if c == Board::HEIGHT - 1
    end
  end


  # @param board [ Board ]
  def self.clean(board)
    new.clean(board)
  end

  def self.intermediate(board, source_board)
    new.intermediate(board, source_board)
  end

  private

  attr_reader :ostream
end
