require_relative "../boot"

RSpec.describe Solver do
  let(:board) { Board.from_string(File.read("spec/fixtures/easy01.txt")) }
  let(:solver) { Solver.new(board, ostream) }
  let(:ostream) { StringIO.new }

  describe "#solve" do
    it "returns a board with all numbers filled in" do
      res = solver.solve
      expect(res).to be_a Board

      expect(res.get_row(0)).to eq [9, 5, 4, 8, 2, 6, 1, 3, 7]
      expect(res.get_row(1)).to eq [6, 3, 2, 7, 1, 5, 8, 9, 4]
      expect(res.get_row(2)).to eq [8, 7, 1, 4, 9, 3, 5, 2, 6]
      expect(res.get_row(3)).to eq [1, 8, 9, 2, 5, 4, 6, 7, 3]
      expect(res.get_row(4)).to eq [2, 6, 5, 3, 7, 8, 4, 1, 9]
      expect(res.get_row(5)).to eq [7, 4, 3, 9, 6, 1, 2, 5, 8]
      expect(res.get_row(6)).to eq [4, 1, 8, 5, 3, 7, 9, 6, 2]
      expect(res.get_row(7)).to eq [5, 9, 7, 6, 8, 2, 3, 4, 1]
      expect(res.get_row(8)).to eq [3, 2, 6, 1, 4, 9, 7, 8, 5]
    end

    context "it's a harder puzzle" do
      let(:board) { Board.from_string(File.read("spec/fixtures/medium01.txt")) }

      it "returns a board with all numbers filled in" do
        res = solver.solve
        expect(res).to be_a Board

        expect(res.get_row(0)).to eq [4, 3, 5, 8, 9, 6, 7, 2, 1]
        expect(res.get_row(1)).to eq [8, 9, 1, 5, 7, 2, 4, 6, 3]
        expect(res.get_row(2)).to eq [7, 6, 2, 4, 1, 3, 5, 8, 9]
        expect(res.get_row(3)).to eq [2, 5, 3, 9, 6, 8, 1, 4, 7]
        expect(res.get_row(4)).to eq [1, 8, 4, 3, 2, 7, 6, 9, 5]
        expect(res.get_row(5)).to eq [6, 7, 9, 1, 4, 5, 8, 3, 2]
        expect(res.get_row(6)).to eq [5, 2, 7, 6, 8, 9, 3, 1, 4]
        expect(res.get_row(7)).to eq [9, 4, 6, 7, 3, 1, 2, 5, 8]
        expect(res.get_row(8)).to eq [3, 1, 8, 2, 5, 4, 9, 7, 6]
      end

    end
  end
end
