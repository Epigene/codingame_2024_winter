RSpec.describe Grid, instance_name: :grid do
  let(:grid) do
    g = described_class.new

    g.add_cell(Point[0, 0], only: [Grid::S, Grid::E])
    g.add_cell(Point[1, 0], except: [Grid::N])
    g.add_cell(Point[2, 0], only: [Grid::S, Grid::W])
    g.add_cell(Point[0, 1], except: [Grid::W])
    g.add_cell(Point[1, 1])
    g.add_cell(Point[2, 1], except: [Grid::E])
    g.add_cell(Point[0, 2], only: [Grid::N, Grid::E])
    g.add_cell(Point[1, 2], except: [Grid::S])
    g.add_cell(Point[2, 2], only: [Grid::N, Grid::W])

    g
  end

  describe "#dup" do
    subject(:dup) { grid.dup }

    it "returns an instance with data completely separate from original's" do
      expect(dup).to be_a(described_class)

      expect{ grid.remove_cell(Point[0, 0]) }.to(
        not_change{ dup[Point[0, 0]] }
      )
    end
  end

  describe "#dijkstra_shortest_path(root, destination)" do
    subject(:dijkstra_shortest_path) { grid.dijkstra_shortest_path(root, destination) }

    context "when the grid is 3x3 cell square and novigating from corner to corner" do
      let(:root) { Point[0, 0] }
      let(:destination) { Point[2, 2] }

      it "returns a path that goes through the center cell as having more connections" do
        expect(dijkstra_shortest_path).to eq(
          [Point[0, 0], Point[1, 0], Point[1, 1], Point[2, 1], Point[2, 2]]
        )
      end
    end

    context "when the 3x3 grid has middle row almost eliminated and navigating from upper left to lower left" do
      let(:root) { Point[0, 0] }
      let(:destination) { Point[0, 2] }

      let(:grid) do
        g = super()

        g.remove_cell(Point[0, 1])
        g.remove_cell(Point[1, 1])

        g
      end

      it "returns the only path, looping around the 'wall'" do
        is_expected.to eq(
          [Point[0, 0], Point[1, 0], Point[2, 0], Point[2, 1], Point[2, 2], Point[1, 2], Point[0, 2]]
        )
      end
    end
  end

  describe "#path_length(path)" do
    subject(:path_length) { grid.path_length(path) }

    let(:path) { grid.dijkstra_shortest_path(Point[1, 1], Point[2, 0]) }

    it "returns the number of steps it would take to traverse the path" do
      is_expected.to eq(2)
    end
  end

  describe "#cells_at_distance(point, range)" do
    subject(:cells_at_distance) { grid.cells_at_distance(Point[0, 0], range) }

    context "when asking for neighbours" do
      let(:range) { 1..1 }

      it "returns neighbouring cells" do
        is_expected.to eq([Point[1, 0], Point[0, 1]].to_set)
      end
    end

    context "when asking for further cells" do
      let(:range) { 2..3 }

      it "returns further cells" do
        is_expected.to eq([Point[2, 0], Point[1, 1], Point[2, 1], Point[0, 2], Point[1, 2]].to_set)
      end
    end

    context "when asking for far cells" do
      let(:range) { 4..5 }

      it "returns far cell(s)" do
        is_expected.to eq([Point[2, 2]].to_set)
      end
    end

    context "when asking for cells way beyond what's in the grid" do
      let(:range) { 10..11 }

      it "returns nothing" do
        is_expected.to eq([].to_set)
      end
    end
  end

  describe "#cells_at_diagonal_distance(point, range)" do
    subject(:cells_at_diagonal_distance) { grid.cells_at_diagonal_distance(Point[0, 0], range) }

    context "when asking for direct diagonal neighbour" do
      let(:range) { 1..1 }

      it "returns them" do
        is_expected.to eq([Point[1, 1]].to_set)
      end
    end

    context "when asking for moar diagonal neighbours" do
      let(:range) { 1..3 }

      it "returns them" do
        is_expected.to eq([Point[1, 1], Point[2, 2]].to_set)
      end
    end
  end
end
