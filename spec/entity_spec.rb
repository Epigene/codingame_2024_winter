RSpec.describe Entity, instance_name: :entity do
  before do
    Entity.all = entities
  end

  describe ".available_sources" do
    subject(:available_sources) { described_class.available_sources }

    context "when there are no harvesters" do
      let(:entities) do
        {
          Point[0, 0] => {:type=>"A", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
          Point[1, 1] => {:type=>"B", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
        }
      end

      it "returns the same list as .sources" do
        expect(available_sources.keys).to eq([Point[0, 0], Point[1, 1]])
      end
    end

    context "when there are harvesters" do
      let(:entities) do
        {
          Point[0, 0] => {:type=>"A", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
          Point[1, 1] => {:type=>"B", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
          Point[1, 0] => {:type=>"HARVESTER", :owner=>1, :id=>6, :dir=>"W", :parent_id=>5, :root_id=>1},
        }
      end

      it "returns .sources without a harvester 'eating' 'em" do
        expect(available_sources.keys).to eq([Point[1, 1]])
      end
    end
  end

  describe ".harvested_sources(types = SOURCES)" do
    subject(:harvested_sources) { described_class.harvested_sources }

    context "when there are harvesters" do
      let(:entities) do
        {
          Point[0, 0] => {:type=>"A", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
          Point[1, 1] => {:type=>"B", :owner=>-1, :id=>0, :dir=>"X", :parent_id=>0, :root_id=>0},
          Point[1, 0] => {:type=>"HARVESTER", :owner=>1, :id=>6, :dir=>"W", :parent_id=>5, :root_id=>1},
        }
      end

      it "returns .sources with a harvester 'eating' 'em" do
        expect(harvested_sources.keys).to eq([Point[0, 0]])
      end
    end
  end
end
