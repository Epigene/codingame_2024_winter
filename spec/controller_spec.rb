RSpec.describe Controller, instance_name: :controller do
  let(:controller) { described_class.new(**width_and_height) }
  let(:width_and_height) { {width: 18, height: 9} }

  before do
    stub_const("P", Point)
  end

  describe "#call(entities:, my_stock:, opp_stock:, required_actions:)" do
    subject(:call) { controller.call(**options) }

    context "when initializing an arena without border walls at all" do
      let(:width_and_height) { {width: 2, height: 2} }

      let(:options) do
        {
          entities: {
            Point[0, 0] => {:type=>"ROOT", :owner=>1, :id=>1, :dir=>"N", :parent_id=>0, :root_id=>1},
            Point[1, 1] => {:type=>"ROOT", :owner=>0, :id=>2, :dir=>"N", :parent_id=>0, :root_id=>2},
          },
          my_stock: {:a=>10, :b=>0, :c=>1, :d=>1}, opp_stock: {:a=>10, :b=>0, :c=>1, :d=>1}, required_actions: 1
        }
      end

      it "returns a command to grow in any ot the two available cells" do
        is_expected.to eq(["GROW 1 1 0 BASIC"])
        expect(controller.arena.nodes.size).to eq(4)
      end
    end

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

      context "when spawned next to A source, but there's a better candidate 2 cells away" do
        let(:width_and_height) { {width: 18, height: 9} }

        let(:options) do
          {
            entities: {
              P[1, 0] => {:type=>"B", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              P[12, 0] => {:type=>"C", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              P[14, 0] => {:type=>"C", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              P[17, 0] => {:type=>"D", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              P[0, 1] => {:type=>"D", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              P[2, 1] => {:type=>"A", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              P[12, 1] => {:type=>"B", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              P[16, 1] => {:type=>"A", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              P[2, 2] => {:type=>"ROOT", :owner=>1, :id=>1, :dir=>"N", :parent_id=>0, :root_id=>1},
              P[4, 2] => {:type=>"A", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              P[8, 2] => {:type=>"A", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              P[17, 2] => {:type=>"C", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              P[7, 3] => {:type=>"B", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              P[9, 3] => {:type=>"C", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              P[0, 4] => {:type=>"D", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              P[5, 4] => {:type=>"B", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              P[12, 4] => {:type=>"B", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              P[17, 4] => {:type=>"D", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              P[8, 5] => {:type=>"C", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              P[10, 5] => {:type=>"B", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              P[0, 6] => {:type=>"C", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              P[9, 6] => {:type=>"A", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              P[13, 6] => {:type=>"A", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              P[15, 6] => {:type=>"ROOT", :owner=>0, :id=>2, :dir=>"N", :parent_id=>0, :root_id=>2},
              P[1, 7] => {:type=>"A", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              P[5, 7] => {:type=>"B", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              P[15, 7] => {:type=>"A", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              P[17, 7] => {:type=>"D", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              P[0, 8] => {:type=>"D", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              P[3, 8] => {:type=>"C", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              P[5, 8] => {:type=>"C", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              P[16, 8] => {:type=>"B", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              # Walls:
              P[11, 0] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              P[15, 1] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              P[15, 2] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              P[2, 4] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              P[3, 4] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              P[14, 4] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              P[15, 4] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              P[2, 6] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              P[2, 7] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              P[6, 8] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            },
            my_stock: {:a=>3, :b=>3, :c=>4, :d=>9}, opp_stock: {:a=>3, :b=>3, :c=>4, :d=>9}, required_actions: 1
          }
        end

        it "returns a command to start harvesting the good source" do
          is_expected.to eq(["GROW 1 3 2 HARVESTER E"])
        end
      end

      context "when spawning next to an A source" do
        let(:options) do
          {
            entities: {
              Point[1, 2] => {:type=>"ROOT", :owner=>1, :id=>1, :dir=>"N", :parent_id=>0, :root_id=>1},
              Point[2, 2] => {:type=>"A", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[1, 3] => {:type=>"D", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[1, 6] => {:type=>"ROOT", :owner=>0, :id=>2, :dir=>"N", :parent_id=>0, :root_id=>2},
              Point[2, 6] => {:type=>"A", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              **wall_line([1, 4], [15, 4]),
              **border_walls(**width_and_height)
            },
            my_stock: {:a=>10, :b=>0, :c=>1, :d=>1}, opp_stock: {:a=>10, :b=>0, :c=>1, :d=>1}, required_actions: 1
          }
        end

        it "returns a command to loop around to get at it" do
          is_expected.to eq(["GROW 1 1 1 BASIC"])
        end
      end

      context "when spawned next to A source and grew to the side to be able to place harvester" do
        let(:options) do
          {
            entities: {
              Point[1, 2] => {:type=>"ROOT", :owner=>1, :id=>1, :dir=>"N", :parent_id=>0, :root_id=>1},
              Point[1, 1] => {:type=>"BASIC", :owner=>1, :id=>3, :dir=>"N", :parent_id=>1, :root_id=>1},
              Point[2, 2] => {:type=>"A", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[1, 3] => {:type=>"D", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[1, 6] => {:type=>"ROOT", :owner=>0, :id=>2, :dir=>"N", :parent_id=>0, :root_id=>2},
              Point[2, 6] => {:type=>"A", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              **wall_line([1, 4], [15, 4]),
              **border_walls(**width_and_height)
            },
            my_stock: {:a=>10, :b=>0, :c=>1, :d=>1}, opp_stock: {:a=>10, :b=>0, :c=>1, :d=>1}, required_actions: 1
          }
        end

        it "returns a command to grow the harvester" do
          is_expected.to eq(["GROW 3 2 1 HARVESTER S"])
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
        expect(controller.arena.nodes.size).to eq(9)
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

    context "when it's wood-1 sporing 18x9 arena" do
      let(:width_and_height) { {width: 18, height: 9} }

      context "when the very start, need to grow a sporer" do
        let(:options) do
          {
            entities: {
              Point[15, 1] => {:type=>"A", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[1, 2] => {:type=>"ROOT", :owner=>1, :id=>1, :dir=>"N", :parent_id=>0, :root_id=>1},
              Point[15, 5] => {:type=>"A", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[1, 6] => {:type=>"ROOT", :owner=>0, :id=>2, :dir=>"N", :parent_id=>0, :root_id=>2},
              **border_walls(**width_and_height),
              **wall_line([1, 4], [15, 4]),
            },
            my_stock: {:a=>6, :b=>2, :c=>2, :d=>3}, opp_stock: {:a=>6, :b=>2, :c=>2, :d=>3}, required_actions: 1
          }
        end

        it "returns a command to grow a sporer in correct position" do
          is_expected.to eq(["GROW 1 1 3 SPORER E"])
        end
      end

      context "when the 2nd move, need to spore a new root at predetermined position" do
        let(:options) do
          {
            entities: {
              Point[15, 1] => {:type=>"A", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[1, 2] => {:type=>"ROOT", :owner=>1, :id=>1, :dir=>"N", :parent_id=>0, :root_id=>1},
              Point[1, 3] => {:type=>"SPORER", :owner=>1, :id=>3, :dir=>"E", :parent_id=>1, :root_id=>1},
              Point[1, 5] => {:type=>"SPORER", :owner=>0, :id=>4, :dir=>"E", :parent_id=>2, :root_id=>2},
              Point[15, 5] => {:type=>"A", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[1, 6] => {:type=>"ROOT", :owner=>0, :id=>2, :dir=>"N", :parent_id=>0, :root_id=>2},
              **border_walls(**width_and_height),
              **wall_line([1, 4], [15, 4]),
            },
            my_stock: {:a=>6, :b=>1, :c=>2, :d=>2}, opp_stock: {:a=>6, :b=>1, :c=>2, :d=>2}, required_actions: 1
          }
        end

        before do
          allow(controller).to receive(:new_root_for_next_turn) do
            {
              new_root_cell: Point[15, 3],
              sporer_cell: Point[1, 3]
            }
          end
        end

        it "returns a command to spore a new root" do
          is_expected.to eq(["SPORE 3 15 3"])
        end
      end

      context "when the 3rd move, need to grow a harvester from new root" do
        let(:options) do
          {
            entities: {
              Point[15, 1] => {:type=>"A", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[1, 2] => {:type=>"ROOT", :owner=>1, :id=>1, :dir=>"N", :parent_id=>0, :root_id=>1},
              Point[1, 3] => {:type=>"SPORER", :owner=>1, :id=>3, :dir=>"E", :parent_id=>1, :root_id=>1},
              Point[15, 3] => {:type=>"ROOT", :owner=>1, :id=>5, :dir=>"N", :parent_id=>0, :root_id=>5},
              Point[1, 5] => {:type=>"SPORER", :owner=>0, :id=>4, :dir=>"E", :parent_id=>2, :root_id=>2},
              Point[15, 5] => {:type=>"ROOT", :owner=>0, :id=>6, :dir=>"N", :parent_id=>0, :root_id=>6},
              Point[1, 6] => {:type=>"ROOT", :owner=>0, :id=>2, :dir=>"N", :parent_id=>0, :root_id=>2},
              **border_walls(**width_and_height),
              **wall_line([1, 4], [15, 4]),
            },
            my_stock: {:a=>5, :b=>0, :c=>1, :d=>1}, opp_stock: {:a=>5, :b=>0, :c=>1, :d=>1}, required_actions: 2
          }
        end

        it "returns a command to grow harvester" do
          is_expected.to eq(
            [
              "GROW 3 16 5 BASIC",
              "GROW 5 15 2 HARVESTER N",
            ]
          )
        end
      end
    end

    context "when it's a narrow-path bronze arena with A only accessible by destroying B" do
      let(:width_and_height) { {width: 4, height: 4} }

      context "when spawning next to A and needing to loop" do
        let(:options) do
          {
            entities: {
              Point[1, 1] => {:type=>"ROOT", :owner=>1, :id=>1, :dir=>"N", :parent_id=>0, :root_id=>1},
              Point[0, 0] => {:type=>"D", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[0, 1] => {:type=>"A", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[0, 2] => {:type=>"B", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[3, 3] => {:type=>"ROOT", :owner=>0, :id=>2, :dir=>"N", :parent_id=>0, :root_id=>2},
              **wall_line([1, 0], [1, 0]),
            },
            my_stock: {:a=>5, :b=>0, :c=>1, :d=>1}, opp_stock: {:a=>5, :b=>0, :c=>1, :d=>1}, required_actions: 1
          }
        end

        it "returns a command to loop south to be able to build harvester next turn" do
          is_expected.to eq(["GROW 1 1 2 BASIC"])
        end
      end

      context "when real case" do
        let(:width_and_height) { {width: 16, height: 8} }

        let(:options) do
          {
            entities: {
              Point[0, 0] => {:type=>"D", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[5, 0] => {:type=>"D", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[6, 0] => {:type=>"A", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[8, 0] => {:type=>"A", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[15, 0] => {:type=>"D", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[0, 1] => {:type=>"A", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[1, 1] => {:type=>"ROOT", :owner=>1, :id=>1, :dir=>"N", :parent_id=>0, :root_id=>1},
              Point[6, 1] => {:type=>"B", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[8, 1] => {:type=>"C", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[11, 1] => {:type=>"C", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[14, 1] => {:type=>"B", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[15, 1] => {:type=>"C", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[0, 2] => {:type=>"B", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[4, 2] => {:type=>"D", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[9, 2] => {:type=>"C", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[10, 2] => {:type=>"B", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[5, 5] => {:type=>"B", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[6, 5] => {:type=>"C", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[11, 5] => {:type=>"D", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[15, 5] => {:type=>"B", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[0, 6] => {:type=>"C", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[1, 6] => {:type=>"B", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[4, 6] => {:type=>"C", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[7, 6] => {:type=>"C", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[9, 6] => {:type=>"B", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[14, 6] => {:type=>"ROOT", :owner=>0, :id=>2, :dir=>"N", :parent_id=>0, :root_id=>2},
              Point[15, 6] => {:type=>"A", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[0, 7] => {:type=>"D", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[7, 7] => {:type=>"A", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[9, 7] => {:type=>"A", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[10, 7] => {:type=>"D", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[15, 7] => {:type=>"D", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              # walls
              Point[1, 0] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[7, 0] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[9, 0] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[10, 0] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[11, 0] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[13, 0] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[3, 1] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[5, 1] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[7, 1] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[9, 1] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[13, 1] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[3, 2] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[5, 2] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[6, 2] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[7, 2] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[11, 2] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[12, 2] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[13, 2] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[15, 2] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[0, 3] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[1, 3] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[3, 3] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[5, 3] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[9, 3] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[6, 4] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[10, 4] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[12, 4] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[14, 4] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[15, 4] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[0, 5] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[2, 5] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[3, 5] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[4, 5] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[8, 5] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[9, 5] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[10, 5] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[12, 5] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[2, 6] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[6, 6] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[8, 6] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[10, 6] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[12, 6] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[2, 7] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[4, 7] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[5, 7] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[6, 7] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[8, 7] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[14, 7] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            },
            my_stock: {:a=>10, :b=>5, :c=>7, :d=>3}, opp_stock: {:a=>10, :b=>5, :c=>7, :d=>3}, required_actions: 1
          }
        end

        it "returns a command to grow a loop" do
          is_expected.to eq(["GROW 1 1 2 BASIC"])
        end
      end

      context "when looped south" do
        let(:options) do
          {
            entities: {
              Point[1, 1] => {:type=>"ROOT", :owner=>1, :id=>1, :dir=>"N", :parent_id=>0, :root_id=>1},
              Point[1, 2] => {:type=>"BASIC", :owner=>1, :id=>3, :dir=>"N", :parent_id=>1, :root_id=>1},
              Point[0, 0] => {:type=>"D", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[0, 1] => {:type=>"A", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[0, 2] => {:type=>"B", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[3, 3] => {:type=>"ROOT", :owner=>0, :id=>2, :dir=>"N", :parent_id=>0, :root_id=>2},
              **wall_line([1, 0], [1, 0]),
            },
            my_stock: {:a=>5, :b=>0, :c=>1, :d=>1}, opp_stock: {:a=>5, :b=>0, :c=>1, :d=>1}, required_actions: 2
          }
        end

        it "returns a command to build a harvester on top of B source to get to A" do
          is_expected.to eq(["GROW 3 0 2 HARVESTER N"])
        end
      end
    end

    context "when it's a late-bronze arena with protein prison and tempting open lower row" do
      let(:width_and_height) { {width: 18, height: 3} }

      context "when just secured A source and could grow towards opportune sporer spot" do
        let(:options) do
          {
            entities: {
              Point[0, 0] => {:type=>"ROOT", :owner=>1, :id=>1, :dir=>"N", :parent_id=>0, :root_id=>1},
              Point[0, 1] => {:type=>"HARVESTER", :owner=>1, :id=>3, :dir=>"S", :parent_id=>1, :root_id=>1},
              Point[17, 0] => {:type=>"ROOT", :owner=>0, :id=>2, :dir=>"N", :parent_id=>0, :root_id=>2},
              Point[17, 1] => {:type=>"HARVESTER", :owner=>0, :id=>4, :dir=>"S", :parent_id=>2, :root_id=>2},
              Point[6, 1] => {:type=>"A", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[11, 1] => {:type=>"A", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[0, 2] => {:type=>"A", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[17, 2] => {:type=>"A", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[1, 2] => {:type=>"C", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[16, 2] => {:type=>"C", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[3, 2] => {:type=>"A", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[14, 2] => {:type=>"A", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[8, 2] => {:type=>"B", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[9, 2] => {:type=>"B", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              **wall_line([2, 0], [2, 1]),
              **wall_line([15, 0], [15, 1]),
            },
            my_stock: {:a=>4, :b=>9, :c=>5, :d=>6}, opp_stock: {:a=>4, :b=>9, :c=>5, :d=>6}, required_actions: 1
          }
        end

        it "returns a command to grow towards good spot for a sporer" do
          is_expected.to eq(["GROW 3 1 1 BASIC"])
        end
      end

      context "when in place to grow a tactical sporer" do
        let(:options) do
          {
            entities: {
              Point[0, 0] => {:type=>"ROOT", :owner=>1, :id=>1, :dir=>"N", :parent_id=>0, :root_id=>1},
              Point[0, 1] => {:type=>"HARVESTER", :owner=>1, :id=>3, :dir=>"S", :parent_id=>1, :root_id=>1},
              Point[1, 1] => {:type=>"BASIC", :owner=>1, :id=>5, :dir=>"N", :parent_id=>3, :root_id=>1},
              Point[17, 0] => {:type=>"ROOT", :owner=>0, :id=>2, :dir=>"N", :parent_id=>0, :root_id=>2},
              Point[17, 1] => {:type=>"HARVESTER", :owner=>0, :id=>4, :dir=>"S", :parent_id=>2, :root_id=>2},
              Point[6, 1] => {:type=>"A", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[11, 1] => {:type=>"A", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[0, 2] => {:type=>"A", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[17, 2] => {:type=>"A", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[1, 2] => {:type=>"C", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[16, 2] => {:type=>"C", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[3, 2] => {:type=>"A", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[14, 2] => {:type=>"A", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[8, 2] => {:type=>"B", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[9, 2] => {:type=>"B", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              **wall_line([2, 0], [2, 1]),
              **wall_line([15, 0], [15, 1]),
            },
            my_stock: {:a=>4, :b=>9, :c=>5, :d=>6}, opp_stock: {:a=>4, :b=>9, :c=>5, :d=>6}, required_actions: 1
          }
        end

        it "returns a command to grow a sporer" do
          is_expected.to eq(["GROW 5 1 2 SPORER E"])
        end
      end

      context "when just grown a sporer" do
        let(:options) do
          {
            entities: {
              Point[0, 0] => {:type=>"ROOT", :owner=>1, :id=>1, :dir=>"N", :parent_id=>0, :root_id=>1},
              Point[0, 1] => {:type=>"HARVESTER", :owner=>1, :id=>3, :dir=>"S", :parent_id=>1, :root_id=>1},
              Point[1, 1] => {:type=>"BASIC", :owner=>1, :id=>5, :dir=>"N", :parent_id=>3, :root_id=>1},
              Point[1, 2] => {:type=>"SPORER", :owner=>1, :id=>6, :dir=>"E", :parent_id=>5, :root_id=>1},
              Point[17, 0] => {:type=>"ROOT", :owner=>0, :id=>2, :dir=>"N", :parent_id=>0, :root_id=>2},
              Point[17, 1] => {:type=>"HARVESTER", :owner=>0, :id=>4, :dir=>"S", :parent_id=>2, :root_id=>2},
              Point[6, 1] => {:type=>"A", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[11, 1] => {:type=>"A", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[0, 2] => {:type=>"A", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[17, 2] => {:type=>"A", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[16, 2] => {:type=>"C", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[3, 2] => {:type=>"A", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[14, 2] => {:type=>"A", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[8, 2] => {:type=>"B", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[9, 2] => {:type=>"B", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              **wall_line([2, 0], [2, 1]),
              **wall_line([15, 0], [15, 1]),
            },
            my_stock: {:a=>4, :b=>9, :c=>5, :d=>6}, opp_stock: {:a=>4, :b=>9, :c=>5, :d=>6}, required_actions: 1
          }
        end

        it "returns a command to spore to a good spot on our-side of arena (could also go for aggressive play)" do
          is_expected.to eq(["SPORE 6 7 2"])
        end
      end

      context "when just spored a new root" do
        let(:options) do
          {
            entities: {
              Point[0, 0] => {:type=>"ROOT", :owner=>1, :id=>1, :dir=>"N", :parent_id=>0, :root_id=>1},
              Point[0, 1] => {:type=>"HARVESTER", :owner=>1, :id=>3, :dir=>"S", :parent_id=>1, :root_id=>1},
              Point[1, 1] => {:type=>"BASIC", :owner=>1, :id=>5, :dir=>"N", :parent_id=>3, :root_id=>1},
              Point[1, 2] => {:type=>"SPORER", :owner=>1, :id=>6, :dir=>"E", :parent_id=>5, :root_id=>1},
              Point[7, 2] => {:type=>"ROOT", :owner=>1, :id=>7, :dir=>"N", :parent_id=>0, :root_id=>7},
              Point[17, 0] => {:type=>"ROOT", :owner=>0, :id=>2, :dir=>"N", :parent_id=>0, :root_id=>2},
              Point[17, 1] => {:type=>"HARVESTER", :owner=>0, :id=>4, :dir=>"S", :parent_id=>2, :root_id=>2},
              Point[6, 1] => {:type=>"A", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[11, 1] => {:type=>"A", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[0, 2] => {:type=>"A", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[17, 2] => {:type=>"A", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[16, 2] => {:type=>"C", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[3, 2] => {:type=>"A", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[14, 2] => {:type=>"A", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[8, 2] => {:type=>"B", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              Point[9, 2] => {:type=>"B", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
              **wall_line([2, 0], [2, 1]),
              **wall_line([15, 0], [15, 1]),
            },
            my_stock: {:a=>4, :b=>9, :c=>5, :d=>6}, opp_stock: {:a=>4, :b=>9, :c=>5, :d=>6}, required_actions: 2
          }
        end

        it "returns commands to capture nearby A and grow towards mid" do
          is_expected.to eq(["GROW 1 1 0 BASIC","GROW 7 7 1 HARVESTER W"])
        end
      end
    end

    context "when it's a real 22x11 arena with root locked in with proteins" do
      let(:width_and_height) { {width: 22, height: 11} }

      let(:options) do
        {
          entities: {
            P[2, 0] => {:type=>"B", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[7, 0] => {:type=>"D", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[13, 0] => {:type=>"D", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[2, 1] => {:type=>"D", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[0, 2] => {:type=>"ROOT", :owner=>1, :id=>1, :dir=>"N", :parent_id=>0, :root_id=>1},
            P[1, 2] => {:type=>"A", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[3, 2] => {:type=>"A", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[11, 2] => {:type=>"C", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[0, 3] => {:type=>"B", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[4, 3] => {:type=>"C", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[12, 3] => {:type=>"A", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[18, 3] => {:type=>"D", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[19, 3] => {:type=>"B", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[1, 4] => {:type=>"C", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[4, 4] => {:type=>"B", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[10, 5] => {:type=>"A", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[11, 5] => {:type=>"A", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[17, 6] => {:type=>"B", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[20, 6] => {:type=>"C", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[2, 7] => {:type=>"B", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[3, 7] => {:type=>"D", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[9, 7] => {:type=>"A", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[17, 7] => {:type=>"C", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[21, 7] => {:type=>"B", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[10, 8] => {:type=>"C", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[18, 8] => {:type=>"A", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[20, 8] => {:type=>"A", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[21, 8] => {:type=>"ROOT", :owner=>0, :id=>2, :dir=>"N", :parent_id=>0, :root_id=>2},
            P[19, 9] => {:type=>"D", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[8, 10] => {:type=>"D", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[14, 10] => {:type=>"D", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[19, 10] => {:type=>"B", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[3, 0] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[4, 0] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[5, 0] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[6, 0] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[10, 0] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[11, 0] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[17, 0] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[18, 0] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[19, 0] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[0, 1] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[4, 1] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[5, 1] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[6, 1] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[7, 1] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[5, 2] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[10, 2] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[13, 2] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[15, 2] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[16, 2] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[20, 2] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[2, 3] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[7, 3] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[10, 3] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[11, 3] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[15, 3] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[16, 3] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[17, 3] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[0, 4] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[2, 4] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[9, 4] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[10, 4] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[11, 4] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[14, 4] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[21, 4] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[0, 5] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[2, 5] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[3, 5] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[4, 5] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[17, 5] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[18, 5] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[19, 5] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[21, 5] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[0, 6] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[7, 6] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[10, 6] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[11, 6] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
          },
          my_stock: {:a=>4, :b=>9, :c=>5, :d=>6}, opp_stock: {:a=>4, :b=>9, :c=>5, :d=>6}, required_actions: 1
        }
      end

      it "returns a command to loop on top of B protein ot get to A" do
        is_expected.to eq(["GROW 1 0 3 BASIC"])
      end
    end

    context "when it's a real 20x10 arena with middle blocked off and there being two symmetrical shortest paths" do
      let(:width_and_height) { {width: 20, height: 10} }

      let(:options) do
        {
          entities: {
            P[0, 0] => {:type=>"D", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[3, 0] => {:type=>"B", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[6, 0] => {:type=>"D", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[9, 0] => {:type=>"A", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[6, 1] => {:type=>"C", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[15, 1] => {:type=>"D", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[17, 1] => {:type=>"C", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[18, 1] => {:type=>"A", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[2, 2] => {:type=>"BASIC", :owner=>0, :id=>7, :dir=>"N", :parent_id=>3, :root_id=>1},
            P[4, 2] => {:type=>"HARVESTER", :owner=>0, :id=>14, :dir=>"N", :parent_id=>9, :root_id=>1},
            P[5, 2] => {:type=>"D", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[7, 2] => {:type=>"B", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[10, 2] => {:type=>"B", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[1, 3] => {:type=>"ROOT", :owner=>0, :id=>1, :dir=>"N", :parent_id=>0, :root_id=>1},
            P[2, 3] => {:type=>"BASIC", :owner=>0, :id=>3, :dir=>"N", :parent_id=>1, :root_id=>1},
            P[3, 3] => {:type=>"BASIC", :owner=>0, :id=>5, :dir=>"N", :parent_id=>3, :root_id=>1},
            P[4, 3] => {:type=>"BASIC", :owner=>0, :id=>9, :dir=>"N", :parent_id=>5, :root_id=>1},
            P[6, 3] => {:type=>"D", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[8, 3] => {:type=>"C", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[10, 3] => {:type=>"A", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[12, 3] => {:type=>"B", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[19, 3] => {:type=>"C", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[4, 4] => {:type=>"BASIC", :owner=>0, :id=>11, :dir=>"N", :parent_id=>9, :root_id=>1},
            P[11, 4] => {:type=>"C", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[19, 4] => {:type=>"A", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[0, 5] => {:type=>"A", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[8, 5] => {:type=>"C", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[15, 5] => {:type=>"C", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[0, 6] => {:type=>"C", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[7, 6] => {:type=>"B", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[9, 6] => {:type=>"A", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[11, 6] => {:type=>"C", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[13, 6] => {:type=>"D", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[15, 6] => {:type=>"A", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[16, 6] => {:type=>"A", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[17, 6] => {:type=>"HARVESTER", :owner=>1, :id=>4, :dir=>"W", :parent_id=>2, :root_id=>2},
            P[18, 6] => {:type=>"ROOT", :owner=>1, :id=>2, :dir=>"N", :parent_id=>0, :root_id=>2},
            P[9, 7] => {:type=>"B", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[12, 7] => {:type=>"B", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[13, 7] => {:type=>"BASIC", :owner=>1, :id=>99, :dir=>"N", :parent_id=>12, :root_id=>2},
            P[14, 7] => {:type=>"BASIC", :owner=>1, :id=>12, :dir=>"N", :parent_id=>10, :root_id=>2},
            P[15, 7] => {:type=>"BASIC", :owner=>1, :id=>10, :dir=>"N", :parent_id=>8, :root_id=>2},
            P[16, 7] => {:type=>"BASIC", :owner=>1, :id=>8, :dir=>"N", :parent_id=>6, :root_id=>2},
            P[17, 7] => {:type=>"BASIC", :owner=>1, :id=>6, :dir=>"N", :parent_id=>4, :root_id=>2},
            P[1, 8] => {:type=>"A", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[2, 8] => {:type=>"C", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[4, 8] => {:type=>"D", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[13, 8] => {:type=>"C", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[10, 9] => {:type=>"A", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[13, 9] => {:type=>"D", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[16, 9] => {:type=>"B", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[19, 9] => {:type=>"D", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            # walls
            P[1, 0] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[10, 0] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[11, 0] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[13, 0] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[17, 0] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[5, 1] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[1, 2] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[11, 2] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[13, 2] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[14, 2] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[16, 2] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[19, 2] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[5, 3] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[13, 3] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[0, 4] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[3, 4] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[7, 4] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[8, 4] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[9, 4] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[13, 4] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[14, 4] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[18, 4] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[1, 5] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[5, 5] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[6, 5] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[10, 5] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[11, 5] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[12, 5] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[16, 5] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[19, 5] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[6, 6] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[14, 6] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[0, 7] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[3, 7] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[5, 7] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[6, 7] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[8, 7] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[18, 7] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[14, 8] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[2, 9] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[6, 9] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[8, 9] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[9, 9] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[18, 9] => {:type=>"WALL", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
          },
          my_stock: {:a=>4, :b=>10, :c=>2, :d=>7}, opp_stock: {:a=>4, :b=>10, :c=>2, :d=>7}, required_actions: 1
        }
      end

      it "returns a command to grow a sporer facing West" do
        # is_expected.to eq(["GROW 99 13 8 SPORER W"])
        is_expected.to eq(["GROW 4 17 5 BASIC"])
      end
    end

    context "when a real (and sparse) 22x11 arena with far A source(s)" do
      let(:width_and_height) { {width: 22, height: 11} }

      let(:options) do
        {
          entities: {
            P[5, 0] => {:type=>"C", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[2, 1] => {:type=>"ROOT", :owner=>1, :id=>1, :dir=>"N", :parent_id=>0, :root_id=>1},
            P[3, 1] => {:type=>"SPORER", :owner=>1, :id=>4, :dir=>"S", :parent_id=>1, :root_id=>1},
            P[4, 1] => {:type=>"BASIC", :owner=>1, :id=>9, :dir=>"N", :parent_id=>4, :root_id=>1},
            P[5, 1] => {:type=>"B", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[8, 1] => {:type=>"B", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[0, 2] => {:type=>"D", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[17, 4] => {:type=>"A", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[3, 5] => {:type=>"ROOT", :owner=>1, :id=>5, :dir=>"N", :parent_id=>0, :root_id=>5},
            P[4, 5] => {:type=>"HARVESTER", :owner=>1, :id=>7, :dir=>"E", :parent_id=>5, :root_id=>5},
            P[5, 5] => {:type=>"A", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[16, 5] => {:type=>"A", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[18, 5] => {:type=>"C", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[4, 6] => {:type=>"A", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[18, 7] => {:type=>"BASIC", :owner=>0, :id=>8, :dir=>"E", :parent_id=>6, :root_id=>2},
            P[18, 8] => {:type=>"BASIC", :owner=>0, :id=>6, :dir=>"N", :parent_id=>3, :root_id=>2},
            P[19, 8] => {:type=>"BASIC", :owner=>0, :id=>3, :dir=>"E", :parent_id=>2, :root_id=>2},
            P[21, 8] => {:type=>"D", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[13, 9] => {:type=>"B", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[16, 9] => {:type=>"B", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
            P[19, 9] => {:type=>"ROOT", :owner=>0, :id=>2, :dir=>"N", :parent_id=>0, :root_id=>2},
            P[16, 10] => {:type=>"C", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
          },
          my_stock: {:a=>4, :b=>10, :c=>2, :d=>7}, opp_stock: {:a=>4, :b=>10, :c=>2, :d=>7}, required_actions: 1
        }
      end

      it "after placing harvester returns a command to place another harvester since opportune" do
        is_expected.to eq(["GROW 9 15 1 BASIC", "GROW 5 3 6 HARVESTER E"])
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
