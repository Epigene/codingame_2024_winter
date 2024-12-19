class Controller
  TYPES = %w[WALL ROOT BASIC TENTACLE HARVESTER SPORER A B C D].freeze
  SOURCES = %w[A B C D].freeze
  ROOT = "ROOT"
  HARVESTER = "HARVESTER"
  WALL = "WALL"
  ORGAN_DIRECTIONS = %w[N E S W X].freeze

  attr_reader :width, :height
  attr_reader :entities, :my_stock, :opp_stock, :required_actions

  attr_reader :arena # Grid object
  attr_reader :sources # Hash
  attr_reader :my_organs, :my_roots, :my_harvesters
  attr_reader :opp_organs, :opp_roots, :opp_harvesters
  attr_reader :actions

  def initialize(width:, height:)
    @width = width
    @height = height
  end

  # @param entities Hash
  # @param my_stock Hash
  # @param opp_stock Hash
  # @param required_actions Integer
  #
  # @return Array<String> growth action(s) to perform
  def call(entities:, my_stock:, opp_stock:, required_actions:)
    @entities = entities
    @my_stock = my_stock
    @opp_stock = opp_stock
    @required_actions = required_actions
    initialize_arena

    @sources = entities.select { |coords, entity| SOURCES.include?(entity[:type]) }
    @my_organs = entities.select { |coords, entity| entity[:owner] == 1 }
    @my_roots = my_organs.select { |coords, entity| entity[:type] == ROOT }
    @my_harvesters = entities.select { |coords, entity| entity[:type] == HARVESTER }
    @opp_organs = entities.select { |coords, entity| entity[:owner] == 0 }
    @opp_roots = opp_organs.select { |coords, entity| entity[:type] == ROOT }
    @actions = []

    @time_taken = 0
    time = Benchmark.realtime do
      debug_stocks
      debug_entities
      connect_to_a
      expand_towards_opp_root unless actions.any?
    end

    debug("Took #{(time * 1000).round}ms to execute", 3)

    actions
  end

  private

  def connect_to_a
    if my_harvesters.any?
      debug("Source of A being harvested, moving on with the strat.")
      return
    end

    path = path_to_closest_A(from: @my_roots.first)

    return if path.nil?

    if path.size > 3
      debug("Close source of A detected at #{path.last}, growing towards it")
      @actions << "GROW #{my_roots.first.last[:id]} #{path[-3].x} #{path[-3].y} BASIC"
    elsif path.size == 3
      debug("Close source of A detected at #{path.last}, setting up a harvester")
      @actions << "GROW #{my_roots.first.last[:id]} #{path[-2].x} #{path[-2].y} HARVESTER #{arena.direction(*path.last(2))}"
    else
      raise "D'oh, source already next to organs"
    end
  end

  def expand_towards_opp_root
    opp_root_coords = Point[opp_roots.first.first.x, opp_roots.first.first.y]
    path = arena.dijkstra_shortest_path(my_roots.first.first, opp_root_coords)
    midpoint = (path.size / 2.0).ceil

    @actions << "GROW #{my_roots.first.last[:id]} #{path[midpoint].x} #{path[midpoint].y} BASIC"
  end

  # @param from Array # [coords, root]
  # @return [Array[coords, source], nil]
  def path_to_closest_A(from:)
    a_sources = sources.select { |coords, source| source[:type] == "A" }

    paths_to_sources = a_sources
      .map { |coords, source| arena.dijkstra_shortest_path(from.first, coords) }
      .sort_by { arena.path_length(_1) }[0..-2] # dropping very last option as too far in mirror cases

    organs_in_cluster = my_organs.select { |coords, organ| organ[:root_id] == from.last[:id] }

    paths_from_source_to_organs = []

    paths_to_sources.map do |path|
      organs_in_cluster.map do |coords, organ|
        paths_from_source_to_organs << arena.dijkstra_shortest_path(path.last, coords)
      end
    end

    paths_from_source_to_organs.sort_by { arena.path_length(_1) }.first&.reverse
  end

  # It's very likely that the outer cells of the arena will always be walls.
  def initialize_arena
    return if defined?(@arena)

    @arena = Grid.new

    (1..(width - 1)).each do |x|
      (1..(height - 1)).each do |y|
        @arena.add_cell(Point[x, y])
      end
    end

    # remove any cells marked as walls in entities
    entities.each do |coords, entity|
      next unless entity[:type] == WALL

      @arena.remove_cell(coords)
    end

    nil
  end

  def debug_entities
    debug "Entities:"
    @entities.each_pair do |coords, entity|
      debug("#{coords} => #{entity}") if entity[:type] != WALL
    end
  end

  def debug_stocks
    debug "Protein stocks:"
    debug "  #{my_stock}"
    debug "  #{opp_stock}"
  end
end
