# Represents the 3 types of entities in game - walls, protein sources, and player organs.
# Provides AR-like domain querying like `Entity.organs.tentacles`
class Entity
  TYPES = %w[WALL ROOT BASIC TENTACLE HARVESTER SPORER A B C D].freeze
  SOURCES = %w[A B C D].freeze
  ROOT = "ROOT"
  BASIC = "BASIC"
  HARVESTER = "HARVESTER"
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
    binding.pry
  end

  def self.sources
    all.select { |coords, entity| SOURCES.include?(entity[:type]) }
  end

  def self.organs
    all.select { |coords, entity| entity[:owner] >= 0 }
  end

  def self.my_organs
    all.select { |coords, entity| entity[:owner] == 1 }
  end

  def self.my_roots
    my_organs.select { |coords, entity| entity[:type] == ROOT }
  end
end
