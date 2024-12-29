# Represents the 3 types of entities in game - walls, protein sources, and player organs.
# Provides AR-like domain querying like `Entity.organs.tentacles`
class Entity
  TYPES = %w[WALL ROOT BASIC TENTACLE HARVESTER SPORER A B C D].freeze
  SOURCES = %w[A B C D].freeze
  ROOT = "ROOT"
  BASIC = "BASIC"
  HARVESTER = "HARVESTER"
  SPORER = "SPORER"
  TENTACLE = "TENTACLE"
  WALL = "WALL"
  ORGAN_DIRECTIONS = %w[N E S W X].freeze

  def self.all=(entities)
    @all = entities
  end

  def self.all
    @all
  end

  def self.walls
    all.select { |coords, entity| entity[:type] == WALL }
  end

  def self.sources
    all.select { |coords, entity| SOURCES.include?(entity[:type]) }
  end

  # Differs from .sources in that sources already harvested by me are omitted
  def self.available_sources
    cells_harvested = my_harvesters.map { |k, v| new(k, v).harvested_cell }

    sources.except(*cells_harvested)
  end

  def self.organs
    all.select { |coords, entity| entity[:owner] >= 0 }
  end

  def self.my_organs
    all.select { |coords, entity| entity[:owner] == 1 }
  end

  def self.my_roots
    my_organs.select { |coords, entity| entity[:type] == ROOT }.sort_by { |_, root| root[:id ]}
  end

  def self.my_harvesters
    my_organs.select { |coords, entity| entity[:type] == HARVESTER }.sort_by { |_, root| root[:id ]}
  end

  #== instance methods ==

  def self.new(coords, data)
    return super unless self == Entity

    if data[:type] == HARVESTER
      Harvester.new(coords, data)
    else
      super
    end
  end

  attr_reader :coords, :data

  def initialize(coords, data)
    @coords = coords
    @data = data
  end
end

class Organ < Entity
end

class Harvester < Organ
  def harvested_cell
    coords.send(data[:dir].downcase)
  end
end
