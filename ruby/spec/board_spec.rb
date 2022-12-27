require_relative "../boot"

RSpec.describe Board do
  let(:board) { described_class.new(source_board) }
  let(:source_board) { nil }

  describe "get and set values" do
    it "sets and gets integer values" do
      r = rand(9)
      c = rand(9)
      expect(board.get_value(r, c)).to eq Board::EMPTY

      board.set_value(r, c, 8)
      expect(board.get_value(r, c)).to eq 8
    end

    it "sets and gets string values" do
      r = rand(9)
      c = rand(9)
      expect(board.get_value(r, c)).to eq " "

      board.set_value(r, c, "-")
      expect(board.get_value(r, c)).to eq "-"
    end

    it "sets and gets array values" do
      r = rand(9)
      c = rand(9)

      expect(board.get_value(r, c)).to eq Board::EMPTY

      board.set_value(r, c, [1, 2, 3])
      expect(board.get_value(r, c)).to eq [1, 2, 3]
    end

    context "when value is not supported" do
      it "does not set it (raises error)" do
        expect {
          board.set_value(1, 2, Object.new)
        }.to raise_error(Board::UnsupportedValueError)
      end
    end

    context "when location is out of range" do
      it "does not get value (raises error)" do
        expect {
          board.get_value(10, 10)
        }.to raise_error(Board::OutOfRangeError)
      end
      it "does not set value (raises error)" do
        expect {
          board.set_value(10, 10, 1)
        }.to raise_error(Board::OutOfRangeError)
      end
    end
  end

  describe "cloned board" do
    let(:source_board) {
      board = described_class.new
      board.set_value(0, 0, 1)
      board.set_value(0, 1, [2, 3])
      board
    }

    it "preserves content" do
      expect(board.get_value(0, 0)).to eq 1
      expect(board.get_value(0, 1)).to eq [2, 3]
    end

    it "clones values (so arrays are copied)" do
      expect(source_board.get_value(0, 1)).to eq [2, 3]
      expect(board.get_value(0, 1)).to eq [2, 3]

      source_board.get_value(0, 1) << 4

      # maybe freeze the arrays
      expect(source_board.get_value(0, 1)).to eq [2, 3, 4]
      expect(board.get_value(0, 1)).to eq [2, 3]
    end
  end

  describe ".from_string" do
    let(:board_str) { File.read("spec/fixtures/easy01.txt")}
    let(:board) { described_class.from_string(board_str)}

    it "loads board" do
      e = described_class::EMPTY

      expect(board.get_row(0)).to eq [e, e, e, e, 2, 6, 1, 3, 7]
      expect(board.get_row(1)).to eq [6, e, e, 7, 1, 5, e, e, 4]
      expect(board.get_row(2)).to eq [8, e, e, e, 9, e, 5, e, e]
      expect(board.get_row(3)).to eq [e, e, e, 2, e, 4, 6, e, e]
      expect(board.get_row(4)).to eq [2, e, e, 3, e, 8, 4, 1, 9]
      expect(board.get_row(5)).to eq [e, e, e, e, e, 1, e, e, e]
      expect(board.get_row(6)).to eq [4, e, 8, e, e, 7, 9, 6, e]
      expect(board.get_row(7)).to eq [5, 9, e, e, 8, e, 3, e, e]
      expect(board.get_row(8)).to eq [3, 2, 6, 1, e, e, 7, e, 5]

      expect(board.get_column(0)).to eq [e, 6, 8, e, 2, e, 4, 5, 3]
      expect(board.get_column(1)).to eq [e, e, e, e, e, e, e, 9, 2]
      expect(board.get_column(2)).to eq [e, e, e, e, e, e, 8, e, 6]
      expect(board.get_column(3)).to eq [e, 7, e, 2, 3, e, e, e, 1]
      expect(board.get_column(4)).to eq [2, 1, 9, e, e, e, e, 8, e]
      expect(board.get_column(5)).to eq [6, 5, e, 4, 8, 1, 7, e, e]
      expect(board.get_column(6)).to eq [1, e, 5, 6, 4, e, 9, 3, 7]
      expect(board.get_column(7)).to eq [3, e, e, e, 1, e, 6, e, e]
      expect(board.get_column(8)).to eq [7, 4, e, e, 9, e, e, e, 5]
    end
  end

  describe "#empty?" do
    it "doesn't consider array empty" do
      board.set_value(0, 1, 1)
      board.set_value(0, 2, [2, 3])
      board.set_value(0, 3, [])

      expect(board.empty?(0, 0)).to eq true
      expect(board.empty?(0, 1)).to eq false
      expect(board.empty?(0, 2)).to eq false
      expect(board.empty?(0, 3)).to eq false
    end
  end
end
