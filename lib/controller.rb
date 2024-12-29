class Controller
  TYPES = %w[WALL ROOT BASIC TENTACLE HARVESTER SPORER A B C D].freeze
  SOURCES = %w[A B C D].freeze
  ROOT = "ROOT"
  BASIC = "BASIC"
  HARVESTER = "HARVESTER"
  SPORER = "SPORER"
  TENTACLE = "TENTACLE"
  WALL = "WALL"
  ORGAN_DIRECTIONS = %w[N E S W X].freeze

  COSTS = {
    BASIC => {a: 1, b: 0, c: 0, d: 0},
    HARVESTER => {a: 0, b: 0, c: 1, d: 1},
    TENTACLE=> {a: 0, b: 1, c: 1, d: 0},
    SPORER=> {a: 0, b: 1, c: 0, d: 1},
    ROOT=> {a: 1, b: 1, c: 1, d: 1},
  }

  attr_reader :width, :height
  attr_reader :entities, :my_stock, :opp_stock, :required_actions

  attr_reader :arena # Grid object
  attr_reader :my_organs, :my_roots, :my_harvesters
  attr_reader :opp_organs, :opp_roots, :opp_harvesters
  attr_reader :actions
  attr_reader :cells_of_contention, :width_of_contention
  attr_reader :new_root_for_next_turn # memo for multi-move strat

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
    @opp_roots = opp_organs.select { |coords, entity| entity[:type] == ROOT }.sort_by { |_, root| root[:id ]}
    initialize_cells_of_contention
    @actions = []

    @time_taken = 0
    time = Benchmark.realtime do
      debug_stocks
      debug_entities

      my_roots.to_a.reverse.each.with_index do |(coords, root), i|
        connect_to_a(coords, root) if i.zero?
        grow_defensive_tentacle(coords, root) if actions.size < i.next && i.zero? # only furthest grows tentacles
        expand_towards_middle(coords, root) unless actions.size >= i.next
        grow_in_closest_empty_cell(coords, root) unless actions.size >= i.next
        wait unless actions.size >= i.next
      end
    end

    debug("Took #{(time * 1000).round}ms to execute", 3)

    actions.reverse
  end

  private

  def connect_to_a(coords, root)
    if my_harvesters.any?
      debug("Source of A being harvested, moving on with the strat.")
      return
    end

    path = path_to_closest_A(from: [coords, root])

    return if path.nil?

    if new_root_for_next_turn
      sporer = Entity.my_organs[new_root_for_next_turn[:sporer_cell]]
      new_root_cell = new_root_for_next_turn[:new_root_cell]
      @actions << "SPORE #{sporer[:id]} #{new_root_cell.x} #{new_root_cell.y}"

      @new_root_for_next_turn = nil
    elsif path.size > 6 && can_afford_new_colony? # sporing good idea
      debug("Detected far A source, sporing")

      places_for_new_root = arena.cells_at_distance(path.last, 2..2)

      new_root_cell =
        (places_for_new_root & cells_on_same_row_or_column_as_i_can_reach).sort_by do |cell|
          arena.dijkstra_shortest_path(cell, coords).size
        end.last

      if new_root_cell.nil?
        debug("Hmm, A sources are far, and I can't seem to spore to any of them (diff of more than 2 in both x and y)")
        return
      end

      cell_to_grow_spore = cells_next_to_my_organs.find { |cell| cell.x == new_root_cell.x || cell.y == new_root_cell.y }

      raise("D'oh, can't seem to be able to spore to protein source right away.") if cell_to_grow_spore.nil?

      parent_cell = (arena.cells_at_distance(cell_to_grow_spore, 1..1) & Entity.my_organs.keys).first
      direction = arena.direction(cell_to_grow_spore, new_root_cell)

      @actions << "GROW #{Entity.my_organs[parent_cell][:id]} #{cell_to_grow_spore.x} #{cell_to_grow_spore.y} #{SPORER} #{direction}"
      @new_root_for_next_turn = {
        new_root_cell: new_root_cell,
        sporer_cell: cell_to_grow_spore
      }
    elsif path.size > 3
      debug("Close source of A detected at #{path.last}, growing towards it")
      @actions << "GROW #{my_latest_organ(root_id: root[:id]).last[:id]} #{path[-3].x} #{path[-3].y} BASIC"
    elsif (cells = cells_for_harvester(root, source_type: "A")).one?
      debug("Source of A already next-door detected at #{path.last}, setting up a harvester")
      direction = arena.direction(cells.first, path.last)
      @actions << "GROW #{my_latest_organ(root_id: root[:id]).last[:id]} #{cells.first.x} #{cells.first.y} #{HARVESTER} #{direction}"
    elsif path.size == 3
      debug("Close source of A detected at #{path.last}, setting up a harvester")
      @actions << "GROW #{my_latest_organ(root_id: root[:id]).last[:id]} #{path[-2].x} #{path[-2].y} #{HARVESTER} #{arena.direction(*path.last(2))}"
    else # spawned next to A looks like
      debug("Looks like spawned next to A source, looping")
      harvester_locations = arena.cells_at_distance(path.last, 1..1) - Entity.all.keys
      clean_arena = arena_without_source_cells

      paths = harvester_locations.map { clean_arena.dijkstra_shortest_path(path.first, _1) }
        .sort_by { _1.size }

      if paths.none?
        debug("No paths to nearby A without stepping on other protein sources :/")
        paths = harvester_locations.map { arena.dijkstra_shortest_path(path.first, _1) }
          .sort_by { _1.size }
      end

      shortest_path = paths.first

      if paths.first.size < 4
        @actions << "GROW #{my_latest_organ(root_id: root[:id]).last[:id]} #{shortest_path[1].x} #{shortest_path[1].y} #{BASIC}"
      else
        raise("Hmm, path to A without stepping on other sources seems very far.")
      end
    end
  end

  # Lists nearby cells where we can just place a harvester for a particular protein.
  #
  # @return Set<Point>
  def cells_for_harvester(root, source_type: "A")
    cells_next_to_my_organs(root_id: root[:id]) & cells_next_to_available_source(source_type: source_type)
  end

  # @return Set<Point>
  def cells_next_to_available_source(source_type:)
    Entity.available_sources
      .select { |k, v| v[:type] == source_type }
      .each_with_object(Set.new) do |(k, v), mem|
        mem.merge(arena.cells_at_distance(k, 1..1))
      end
  end

  # A sparser arena where cells with organs or protein sources are forbidden for pathfinding
  def arena_without_source_cells
    arena.dup.tap { _1.remove_cells(Entity.sources.keys) }
  end

  # Useful for determining where to put a sporer for a new colony
  #
  # @return Set<Point>
  def cells_on_same_row_or_column_as_i_can_reach
    x_i_can_reach = cells_next_to_my_organs.map { _1.x }.to_set
    y_i_can_reach = cells_next_to_my_organs.map { _1.y }.to_set

    arena.nodes.each_with_object(Set.new) do |cell, mem|
      next unless x_i_can_reach.include?(cell.x) || y_i_can_reach.include?(cell.y)

      mem << cell
    end
  end

  def grow_defensive_tentacle(coords, root)
    return unless can_afford?(**COSTS[TENTACLE])

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

        @actions << "GROW #{my_latest_organ(root_id: root[:id]).last[:id]} #{candidate.x} #{candidate.y} #{TENTACLE} #{direction}"
      else
        debug("D'oh, somehow all battle cells are more controlled by opp than us, how?")
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

        @actions << "GROW #{my_latest_organ(root_id: root[:id]).last[:id]} #{step_towards_candidate.x} #{step_towards_candidate.y} #{TENTACLE} #{direction}"
      else
        debug("D'oh, somehow all battle cells are more controlled by opp than us, how?")
      end
    end
  end

  # Backfilling action. Once we've established teritorrial dominance, just grow in backyard.
  def grow_in_closest_empty_cell(coords, root)
    growth_cell = cells_for_my_expansion.first
    return unless growth_cell

    debug("Peacibly growing in the backyard")

    lowest_id_neighbor = Entity.my_organs.slice(*arena.cells_at_distance(growth_cell, 1..1))
      .sort_by { |coords, entity| entity[:id] }.first

    @actions << "GROW #{lowest_id_neighbor.last[:id]} #{growth_cell.x} #{growth_cell.y} #{BASIC}"
  end

  def wait
    @actions << "WAIT"
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

  # @return Set<Point>
  def cells_next_to_my_organs(root_id: nil)
    Entity.my_organs.keys.each_with_object(Set.new) do |my_organ_coords, mem|
      mem.merge(arena.cells_at_distance(my_organ_coords, 1..1))
    end - Entity.organs.keys
  end

  # Return candidates for backfilling, sorted descending by most neighbors and closeness to root
  #
  # @return Array<Point>
  def cells_for_my_expansion
    (cells_next_to_my_organs - Entity.sources.keys).sort_by do |cell|
      [-my_neighboring_organ_count(cell), arena.dijkstra_shortest_path(cell, my_roots.first.first).size]
    end
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

  def expand_towards_middle(coords, root)
    opp_root_coords = Point[opp_roots.first.first.x, opp_roots.first.first.y]
    path = arena.dijkstra_shortest_path(my_roots.first.first, opp_root_coords)
    midpoint = (path.size / 2.0).ceil
    mid_cell = path[midpoint]

    if Entity.all[mid_cell]
      debug("Looks like midpoint is already taken, guess we reached it")
      return
    end

    @actions << "GROW #{my_latest_organ(root_id: root[:id]).last[:id]} #{mid_cell.x} #{mid_cell.y} BASIC"
  end

  def my_latest_organ(root_id:)
    my_organs.select { |k, v| v[:root_id] == root_id }.sort_by { |k, v| -v[:id] }.first
  end

  # @param from Array # [coords, root]
  # @return [Array[coords, source], nil]
  def paths_to_sources(from:, source_type: "A")
    sources = Entity.sources.select { |coords, source| source[:type] == source_type }

    sources
      .map { |coords, source| arena.dijkstra_shortest_path(from.first, coords) }
      .sort_by { arena.path_length(_1) }
  end

  # @param from Array # [coords, root]
  # @return [Array<Point>, nil]
  def path_to_closest_A(from:)
    paths_to_sources = paths_to_sources(from: from, source_type: "A")

    # dropping very last option as too far in mirror cases
    paths_to_sources = paths_to_sources[0..-2] if paths_to_sources.size > 1

    organs_in_cluster = my_organs.select { |coords, organ| organ[:root_id] == from.last[:id] }

    paths_from_source_to_organs = []

    paths_to_sources.map do |path|
      organs_in_cluster.map do |coords, organ|
        paths_from_source_to_organs << arena.dijkstra_shortest_path(path.last, coords)
      end
    end

    paths_from_source_to_organs.sort_by { arena.path_length(_1) }.first&.reverse
  end

  def can_afford_new_colony?
    colony_cost = {a: 1, b: 2, c: 2, d: 3}
    can_afford?(**colony_cost)
  end

  def can_afford?(a: 0, b: 0, c: 0, d: 0)
    my_stock[:a] >= a &&
      my_stock[:b] >= b &&
      my_stock[:c] >= c &&
      my_stock[:d] >= d
  end

  # It's very likely that the outer cells of the arena will always be walls.
  def initialize_arena
    return if defined?(@arena)

    @arena = Grid.new

    (0..(width - 1)).each do |x|
      (0..(height - 1)).each do |y|
        @arena.add_cell(Point[x, y])
      end
    end

    # remove any cells marked as walls in entities
    entities.each do |coords, entity|
      next unless entity[:type] == WALL

      @arena.remove_cell(coords)
    end

    # Remove any cells out of bounds
    @arena.nodes.each do |node|
      if node.x.negative? || node.y.negative? || node.x > (width - 1) || node.y > (height - 1)
        @arena.remove_cell(node)
      end
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
