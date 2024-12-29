class Controller
  TYPES = %w[WALL ROOT BASIC TENTACLE HARVESTER SPORER A B C D].freeze
  SOURCES = %w[A B C D].freeze
  ROOT = "ROOT"
  BASIC = "BASIC"
  HARVESTER = "HARVESTER"
  TENTACLE = "TENTACLE"
  WALL = "WALL"
  ORGAN_DIRECTIONS = %w[N E S W X].freeze

  attr_reader :width, :height
  attr_reader :entities, :my_stock, :opp_stock, :required_actions

  attr_reader :arena # Grid object
  attr_reader :my_organs, :my_roots, :my_harvesters
  attr_reader :opp_organs, :opp_roots, :opp_harvesters
  attr_reader :actions
  attr_reader :cells_of_contention, :width_of_contention

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
    Entity.all = entities
    @entities = Entity.all
    @my_stock = my_stock
    @opp_stock = opp_stock
    @required_actions = required_actions; debug "Required actions: #{required_actions}"
    initialize_arena

    @my_organs = entities.select { |coords, entity| entity[:owner] == 1 }
    @my_roots = Entity.my_roots # my_organs.select { |coords, entity| entity[:type] == ROOT }
    @my_harvesters = entities.select { |coords, entity| entity[:type] == HARVESTER }
    @opp_organs = entities.select { |coords, entity| entity[:owner] == 0 }
    @opp_roots = opp_organs.select { |coords, entity| entity[:type] == ROOT }
    initialize_cells_of_contention
    @actions = []

    @time_taken = 0
    time = Benchmark.realtime do
      debug_stocks
      debug_entities

      connect_to_a
      grow_defensive_tentacle unless actions.any?
      expand_towards_middle unless actions.any?
      grow_in_closest_empty_cell unless actions.any?
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

    path = path_to_closest_A(from: my_roots.first)

    return if path.nil?

    if path.size > 3
      debug("Close source of A detected at #{path.last}, growing towards it")
      @actions << "GROW #{my_latest_organ.last[:id]} #{path[-3].x} #{path[-3].y} BASIC"
    elsif path.size == 3
      debug("Close source of A detected at #{path.last}, setting up a harvester")
      @actions << "GROW #{my_latest_organ.last[:id]} #{path[-2].x} #{path[-2].y} #{HARVESTER} #{arena.direction(*path.last(2))}"
    else
      raise "D'oh, source already next to organs"
    end
  end

  def grow_defensive_tentacle
    if width_of_contention == 2
      battle_cells = contentious_cells_at_distance(1..1) # as in direct neighbor
      return if battle_cells.none?
      return if (battle_cells - Entity.organs.keys).none?

      # cells here can have varying "stability", those diagonally away from opponent are poor
      # candidates for capture since they have more control of them than we do.
      best_candidates = battle_cells - cells_under_opp_control - Entity.organs.keys

      if best_candidates.any?
        candidate = best_candidates.first
        path_to_opp = closest_path_to_opp_organs(from: candidate)
        direction = arena.direction(*path_to_opp.first(2))

        @actions << "GROW #{my_latest_organ.last[:id]} #{candidate.x} #{candidate.y} #{TENTACLE} #{direction}"
      else
        raise "D'oh, somehow all battle cells are more controlled by opp than us, how?"
      end
    else
      battle_cells = contentious_cells_at_distance(1..2) # as in diagonally away
      return if battle_cells.none?
      return if (battle_cells - Entity.organs.keys).none?

      best_candidates = battle_cells - cells_under_opp_control - Entity.organs.keys

      if best_candidates.any?
        candidate = best_candidates.first
        path_to_candidate = closest_path_to_my_organs(from: candidate).reverse
        step_towards_candidate = path_to_candidate[1]
        path_to_opp = closest_path_to_opp_organs(from: step_towards_candidate)
        direction = arena.direction(*path_to_opp.first(2))

        @actions << "GROW #{my_latest_organ.last[:id]} #{step_towards_candidate.x} #{step_towards_candidate.y} #{TENTACLE} #{direction}"
      else
        raise "D'oh, somehow all battle cells are more controlled by opp than us, how?"
      end
    end
  end

  # Backfilling action. Once we've established teritorrial dominance, just grow in backyard.
  def grow_in_closest_empty_cell
    growth_cell = cells_for_my_expansion.first
    return unless growth_cell

    lowest_id_neighbor = Entity.my_organs.slice(*arena.cells_at_distance(growth_cell, 1..1))
      .sort_by { |coords, entity| entity[:id] }.first

    @actions << "GROW #{lowest_id_neighbor.last[:id]} #{growth_cell.x} #{growth_cell.y} #{BASIC}"
  end

  def closest_path_to_my_organs(from:)
    my_organs.keys.filter_map do |my_organ_coords|
      arena.dijkstra_shortest_path(from, my_organ_coords)
    end.sort_by(&:size).first
  end

  def closest_path_to_opp_organs(from:)
    opp_organs.keys.filter_map do |opp_organ_coords|
      arena.dijkstra_shortest_path(from, opp_organ_coords)
    end.sort_by(&:size).first
  end

  # @return Set<Point>
  def contentious_cells_at_distance(range)
    cells_at_distance = Set.new

    my_organs.keys.each do |organ_coord|
      cells_at_distance += arena.cells_at_distance(organ_coord, range)
    end

    cells_at_distance & cells_of_contention
  end

  # Return candidates for backfilling, sorted descending by most neighbors and closeness to root
  #
  # @return Array<Point>
  def cells_for_my_expansion
    cells = Set.new

    Entity.my_organs.keys.each do |my_organ_coords|
      cells += arena.cells_at_distance(my_organ_coords, 1..1)
    end

    (cells - Entity.organs.keys)
      .sort_by { |cell| [-my_neighboring_organ_count(cell), arena.dijkstra_shortest_path(cell, my_roots.first.first).size] }
  end

  # @return Integer
  def my_neighboring_organ_count(cell)
    (arena.cells_at_distance(cell, 1..1) & Entity.my_organs.keys).size
  end

  # For now all cells 1 and diagonally 1 away from any opp organ are in their control
  #
  # @return Set<Point>
  def cells_under_opp_control
    cells = Set.new

    opp_organs.keys.each do |opp_organ_coords|
      cells += arena.cells_at_distance(opp_organ_coords, 1..1)
      cells += arena.cells_at_diagonal_distance(opp_organ_coords, 1..1)
    end

    cells
  end

  def expand_towards_middle
    opp_root_coords = Point[opp_roots.first.first.x, opp_roots.first.first.y]
    path = arena.dijkstra_shortest_path(my_roots.first.first, opp_root_coords)
    midpoint = (path.size / 2.0).ceil
    mid_cell = path[midpoint]

    if Entity.all[mid_cell]
      debug("Looks like midpoint is already taken, guess we reached it")
      return
    end

    @actions << "GROW #{my_latest_organ.last[:id]} #{mid_cell.x} #{mid_cell.y} BASIC"
  end

  def my_latest_organ
    my_organs.sort_by { |k, v| -v[:id] }.first
  end

  # @param from Array # [coords, root]
  # @return [Array[coords, source], nil]
  def path_to_closest_A(from:)
    a_sources = Entity.sources.select { |coords, source| source[:type] == "A" }

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

  def initialize_cells_of_contention
    return if defined?(@cells_of_contention)

    path = arena.dijkstra_shortest_path(my_roots.first.first, opp_roots.first.first)

    midpoint_low = (arena.path_length(path) / 2.0).floor
    midpoint_high = (arena.path_length(path) / 2.0).ceil
    range = midpoint_low..midpoint_high

    @cells_of_contention =
      arena.cells_at_distance(my_roots.first.first, range) &
      arena.cells_at_distance(opp_roots.first.first, range)

    @width_of_contention = path.size.even? ? 2 : 1

    nil
  end

  def debug_entities
    debug "Entities:"
    @entities.each_pair do |coords, entity|
      debug("#{coords} => #{entity},") if entity[:type] != WALL
    end
  end

  def debug_stocks
    debug "Protein stocks:"
    debug "  #{my_stock}"
    debug "  #{opp_stock}"
  end
end
