RSpec.describe Controller, instance_name: :controller do
  let(:controller) { described_class.new(**width_and_height) }
  let(:width_and_height) { {width: 18, height: 9} }

  describe "#call(entities:, my_stock:, opp_stock:, required_actions:)" do
    subject(:call) { controller.call(**options) }

    context "when it's wood-3 simple case of one close A source" do
      context "when just starting out" do
        let(:options) do
          {
            entities: {
              Point[5, 1] => {:type=>"A", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[1, 2] => {:type=>"ROOT", :owner=>1, :id=>1, :dir=>"N", :parent_id=>0, :root_id=>1},
              Point[5, 5] => {:type=>"A", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[1, 6] => {:type=>"ROOT", :owner=>0, :id=>2, :dir=>"N", :parent_id=>0, :root_id=>2},
              **wall_line([1, 4], [15, 4]),
              **border_walls(**width_and_height)
            },
            my_stock: {:a=>10, :b=>0, :c=>1, :d=>1}, opp_stock: {:a=>10, :b=>0, :c=>1, :d=>1}, required_actions: 1
          }
        end

        it "returns actions to spread Eastward to eventually start eating the A source" do
          is_expected.to eq(["GROW 1 4 2 BASIC"])
        end
      end

      context "when in a position to place harvester for A source up north" do
        let(:options) do
          {
            entities: {
              Point[5, 1] => {:type=>"A", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[1, 2] => {:type=>"ROOT", :owner=>1, :id=>1, :dir=>"N", :parent_id=>0, :root_id=>1},
              Point[2, 2] => {:type=>"BASIC", :owner=>1, :id=>3, :dir=>"N", :parent_id=>1, :root_id=>1},
              Point[3, 2] => {:type=>"BASIC", :owner=>1, :id=>4, :dir=>"N", :parent_id=>3, :root_id=>1},
              Point[4, 2] => {:type=>"BASIC", :owner=>1, :id=>5, :dir=>"N", :parent_id=>4, :root_id=>1},
              Point[5, 5] => {:type=>"A", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[1, 6] => {:type=>"ROOT", :owner=>0, :id=>2, :dir=>"N", :parent_id=>0, :root_id=>2},
              **wall_line([1, 4], [15, 4]),
              **border_walls(**width_and_height)
            },
            my_stock: {:a=>7, :b=>0, :c=>1, :d=>1}, opp_stock: {:a=>10, :b=>0, :c=>1, :d=>1}, required_actions: 1
          }
        end

        it "returns actions place harvester facing the correct way" do
          is_expected.to eq(["GROW 5 5 2 HARVESTER N"])
        end
      end

      context "when in a position to place harvester for A source to the East" do
        let(:options) do
          {
            entities: {
              Point[6, 2] => {:type=>"A", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[1, 2] => {:type=>"ROOT", :owner=>1, :id=>1, :dir=>"N", :parent_id=>0, :root_id=>1},
              Point[2, 2] => {:type=>"BASIC", :owner=>1, :id=>3, :dir=>"N", :parent_id=>1, :root_id=>1},
              Point[3, 2] => {:type=>"BASIC", :owner=>1, :id=>4, :dir=>"N", :parent_id=>3, :root_id=>1},
              Point[4, 2] => {:type=>"BASIC", :owner=>1, :id=>5, :dir=>"N", :parent_id=>4, :root_id=>1},
              Point[5, 5] => {:type=>"A", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[1, 6] => {:type=>"ROOT", :owner=>0, :id=>2, :dir=>"N", :parent_id=>0, :root_id=>2},
              **wall_line([1, 4], [15, 4]),
              **border_walls(**width_and_height)
            },
            my_stock: {:a=>7, :b=>0, :c=>1, :d=>1}, opp_stock: {:a=>10, :b=>0, :c=>1, :d=>1}, required_actions: 1
          }
        end

        it "returns actions place harvester facing the correct way" do
          is_expected.to eq(["GROW 5 5 2 HARVESTER E"])
        end
      end

      context "when harvester for A source to the East was just placed" do
        let(:options) do
          {
            entities: {
              Point[6, 2] => {:type=>"A", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[1, 2] => {:type=>"ROOT", :owner=>1, :id=>1, :dir=>"N", :parent_id=>0, :root_id=>1},
              Point[2, 2] => {:type=>"BASIC", :owner=>1, :id=>3, :dir=>"N", :parent_id=>1, :root_id=>1},
              Point[3, 2] => {:type=>"BASIC", :owner=>1, :id=>4, :dir=>"N", :parent_id=>3, :root_id=>1},
              Point[4, 2] => {:type=>"BASIC", :owner=>1, :id=>5, :dir=>"N", :parent_id=>4, :root_id=>1},
              Point[5, 2] => {:type=>"HARVESTER", :owner=>1, :id=>6, :dir=>"E", :parent_id=>5, :root_id=>1},
              Point[5, 5] => {:type=>"A", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[1, 6] => {:type=>"ROOT", :owner=>0, :id=>2, :dir=>"N", :parent_id=>0, :root_id=>2},
              **wall_line([1, 4], [15, 4]),
              **border_walls(**width_and_height)
            },
            my_stock: {:a=>7, :b=>0, :c=>0, :d=>0}, opp_stock: {:a=>10, :b=>0, :c=>1, :d=>1}, required_actions: 1
          }
        end

        it "returns actions to spread to the south not to destroy the A source" do
          is_expected.to eq(["GROW 6 16 5 BASIC"])
        end
      end
    end

    context "when it's an idealized 6x5 open arena" do
      let(:width_and_height) { {width: 6, height: 5} }

      let(:options) do
        {
          entities: {
            Point[1, 1] => {:type=>"ROOT", :owner=>1, :id=>1, :dir=>"N", :parent_id=>0, :root_id=>1},
            Point[2, 1] => {:type=>"BASIC", :owner=>1, :id=>3, :dir=>"N", :parent_id=>1, :root_id=>1},
            Point[4, 3] => {:type=>"ROOT", :owner=>0, :id=>2, :dir=>"N", :parent_id=>0, :root_id=>2},
            Point[4, 2] => {:type=>"BASIC", :owner=>0, :id=>4, :dir=>"N", :parent_id=>2, :root_id=>2},
            **border_walls(**width_and_height)
          },
          my_stock: {:a=>50, :b=>50, :c=>50, :d=>0}, opp_stock: {:a=>50, :b=>50, :c=>50, :d=>0}, required_actions: 1
        }
      end

      it "initializes correct cells of contention and grows tentacle correctly" do
        is_expected.to eq(["GROW 3 2 2 TENTACLE E"])
      end
    end

    context "when it's an idealized 5x5 open symmetrical arena" do
      let(:width_and_height) { {width: 5, height: 5} }

      let(:options) do
        {
          entities: {
            Point[1, 1] => {:type=>"ROOT", :owner=>1, :id=>1, :dir=>"N", :parent_id=>0, :root_id=>1},
            Point[3, 3] => {:type=>"ROOT", :owner=>0, :id=>2, :dir=>"N", :parent_id=>0, :root_id=>2},
            **border_walls(**width_and_height)
          },
          my_stock: {:a=>50, :b=>50, :c=>50, :d=>0}, opp_stock: {:a=>50, :b=>50, :c=>50, :d=>0}, required_actions: 1
        }
      end

      it "returns a command to grow a tentacle controlling the centre" do
        is_expected.to eq(["GROW 1 1 2 TENTACLE E"])
      end
    end

    context "when it's a real wood-2 18x8 arena" do
      let(:width_and_height) { {width: 18, height: 8} }

      let(:options) do
        {
          entities: {
            Point[1, 2] => {:type=>"ROOT", :owner=>1, :id=>1, :dir=>"N", :parent_id=>0, :root_id=>1},
            Point[2, 2] => {:type=>"BASIC", :owner=>1, :id=>3, :dir=>"N", :parent_id=>1, :root_id=>1},
            Point[3, 2] => {:type=>"BASIC", :owner=>1, :id=>5, :dir=>"N", :parent_id=>3, :root_id=>1},
            Point[4, 2] => {:type=>"BASIC", :owner=>1, :id=>8, :dir=>"N", :parent_id=>5, :root_id=>1},
            Point[5, 2] => {:type=>"BASIC", :owner=>1, :id=>10, :dir=>"N", :parent_id=>8, :root_id=>1},
            Point[6, 2] => {:type=>"BASIC", :owner=>1, :id=>12, :dir=>"N", :parent_id=>10, :root_id=>1},
            Point[7, 2] => {:type=>"BASIC", :owner=>1, :id=>14, :dir=>"N", :parent_id=>12, :root_id=>1},
            Point[13, 2] => {:type=>"BASIC", :owner=>0, :id=>19, :dir=>"N", :parent_id=>13, :root_id=>2},
            Point[7, 3] => {:type=>"BASIC", :owner=>1, :id=>16, :dir=>"N", :parent_id=>14, :root_id=>1},
            Point[13, 3] => {:type=>"BASIC", :owner=>0, :id=>13, :dir=>"N", :parent_id=>11, :root_id=>2},
            Point[14, 3] => {:type=>"BASIC", :owner=>0, :id=>11, :dir=>"N", :parent_id=>9, :root_id=>2},
            Point[15, 3] => {:type=>"BASIC", :owner=>0, :id=>15, :dir=>"N", :parent_id=>7, :root_id=>2},
            Point[7, 4] => {:type=>"TENTACLE", :owner=>1, :id=>18, :dir=>"N", :parent_id=>16, :root_id=>1},
            Point[14, 4] => {:type=>"BASIC", :owner=>0, :id=>9, :dir=>"N", :parent_id=>6, :root_id=>2},
            Point[15, 4] => {:type=>"BASIC", :owner=>0, :id=>7, :dir=>"N", :parent_id=>4, :root_id=>2},
            Point[7, 5] => {:type=>"TENTACLE", :owner=>1, :id=>20, :dir=>"E", :parent_id=>18, :root_id=>1},
            Point[13, 5] => {:type=>"BASIC", :owner=>0, :id=>17, :dir=>"N", :parent_id=>6, :root_id=>2},
            Point[14, 5] => {:type=>"BASIC", :owner=>0, :id=>6, :dir=>"N", :parent_id=>4, :root_id=>2},
            Point[15, 5] => {:type=>"BASIC", :owner=>0, :id=>4, :dir=>"N", :parent_id=>2, :root_id=>2},
            Point[16, 5] => {:type=>"ROOT", :owner=>0, :id=>2, :dir=>"N", :parent_id=>0, :root_id=>2},
            **border_walls(**width_and_height),
            **wall_line([1, 1], [16, 1]),
            **wall_line([1, 6], [16, 6]),
          },
          my_stock: {:a=>50, :b=>50, :c=>50, :d=>0}, opp_stock: {:a=>50, :b=>50, :c=>50, :d=>0}, required_actions: 1
        }
      end

      it "returns opportunistic command to take a bit more than cells of contention" do
        is_expected.to eq(["GROW 20 8 4 TENTACLE E"])
      end
    end

    context "when it's a 7x4 (odd-step) arena and I have the middle" do
      let(:width_and_height) { {width: 7, height: 4} }

      let(:options) do
        {
          entities: {
            Point[1, 1] => {:type=>"ROOT", :owner=>1, :id=>1, :dir=>"N", :parent_id=>0, :root_id=>1},
            Point[5, 2] => {:type=>"ROOT", :owner=>0, :id=>2, :dir=>"N", :parent_id=>0, :root_id=>2},
            Point[2, 1] => {:type=>"BASIC", :owner=>1, :id=>3, :dir=>"N", :parent_id=>1, :root_id=>1},
            Point[5, 1] => {:type=>"BASIC", :owner=>0, :id=>4, :dir=>"N", :parent_id=>2, :root_id=>2},
            Point[3, 1] => {:type=>"TENTACLE", :owner=>1, :id=>5, :dir=>"E", :parent_id=>3, :root_id=>1},
            Point[3, 2] => {:type=>"TENTACLE", :owner=>1, :id=>6, :dir=>"E", :parent_id=>5, :root_id=>1},
            Point[4, 1] => {:type=>"TENTACLE", :owner=>1, :id=>6, :dir=>"E", :parent_id=>5, :root_id=>1},
            Point[2, 2] => {:type=>"TENTACLE", :owner=>1, :id=>6, :dir=>"E", :parent_id=>3, :root_id=>1},
            **border_walls(**width_and_height)
          },
          my_stock: {:a=>50, :b=>50, :c=>50, :d=>0}, opp_stock: {:a=>50, :b=>50, :c=>50, :d=>0}, required_actions: 1
        }
      end

      it "returns a quiet command to grow in the secured back-area starting from closest to contention" do
        is_expected.to eq(["GROW 1 1 2 BASIC"])
      end
    end
  end

  # @return Hash
  def wall_line(a, b)
    if a.first == b.first # column line
      (a.last..b.last).each_with_object({}) do |y, mem|
        mem[Point[a.first, y]] = wall_hash
      end
    else # row line
      (a.first..b.first).each_with_object({}) do |x, mem|
        mem[Point[x, a.last]] = wall_hash
      end
    end
  end

  def border_walls(width:, height:)
    [
      roof = wall_line([0, 0], [width-1, 0]),
      floor = wall_line([0, height-1], [width-1, height-1]),
      west_wall = wall_line([0, 1], [0, height - 1]),
      east_wall = wall_line([width-1, 1], [width-1, height-1])
    ].reduce(&:merge)
  end

  def wall_hash
    @wall_hash ||= {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0}
  end
end
