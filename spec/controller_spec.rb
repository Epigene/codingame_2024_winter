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
          is_expected.to eq(["GROW 1 5 2 HARVESTER N"])
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
          is_expected.to eq(["GROW 1 5 2 HARVESTER E"])
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
          is_expected.to eq(["GROW 1 16 5 BASIC"])
        end
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
      roof = wall_line([0, 0], [width, 0]),
      floor = wall_line([0, height], [width, height]),
      west_wall = wall_line([0, 1], [0, height - 1]),
      east_wall = wall_line([width, 1], [width, height - 1])
    ].reduce(&:merge)
  end

  def wall_hash
    @wall_hash ||= {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0}
  end
end
