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

  attr_reader :width, :height, :turn, :turn_storage, :time_taken
  attr_reader :entities, :my_stock, :opp_stock, :required_actions

  attr_reader :arena # Grid object
  attr_reader :my_roots
  attr_reader :opp_organs, :opp_roots, :opp_harvesters
  attr_reader :actions
  attr_reader :cells_of_contention, :width_of_contention
  attr_reader :deactivated_roots

  def initialize(width:, height:, turn: 0)
    @width = width
    @height = height
    @turn = turn
    @turn_storage = Hash.new { |hash, key| hash[key] = {} }

    @deactivated_roots = []
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
    @required_actions = required_actions # ; debug "Required actions: #{required_actions}"
    refresh_arena

    promising_rows # this may be left for lazyload, but early probably better
    @turn += 1

    @my_roots = Entity.my_roots # my_organs.select { |coords, entity| entity[:type] == ROOT }
    @opp_organs = entities.select { |coords, entity| entity[:owner] == 0 }
    @opp_roots = opp_organs.select { |coords, entity| entity[:type] == ROOT }.sort_by { |_, root| root[:id ]}
    initialize_cells_of_contention
    @actions = []

    @time_taken = 0
    time = Benchmark.realtime do
      # debug_stocks
      # debug_entities
      # debug_walls

      my_roots.to_a.reverse.each.with_index do |(coords, root), i|
        act_with_time_report(coords, root, i, "A lookup") { connect_to_a(coords, root) if active?(coords) && i.zero? } # only latest root can search As, for time
        act_with_time_report(coords, root, i, "Tentacle") { grow_tentacle(coords, root) if active?(coords) && actions.size < i.next && i.zero? }
        act_with_time_report(coords, root, i, "Colonizing") { spore_and_colonize(coords, root) if active?(coords) && actions.size < i.next && i.zero? && can_afford_new_colony? }
        act_with_time_report(coords, root, i, "Expansion") { expand(coords, root) if active?(coords) && actions.size < i.next }
        # act_with_time_report(coords, root, i, "Backfilling") { grow_in_closest_empty_cell(coords, root) if active?(coords) && actions.size < i.next }
      end
    end

    debug("Took #{(time * 1000).round}ms to execute", 3)
    raise("Took too long!") if (time * 1000).round > 60 # 50ms per turn, very thight

    actions.reverse
  end

  def act_with_time_report(coords, root, i, message, &block)
    @time_taken += t = Benchmark.realtime do
      block.call
    end * 1000; debug("Took #{t.round}, total Time: #{time_taken.round} | #{message}")

    wait(coords, root) if actions.size < i.next && time_taken >= 50
  end

  # require "stackprof"
  # require "json"
  # def call(**options)
  #   profile =
  #     StackProf.run(ignore_gc: true, interval: 1000, mode: :wall, raw: true) do
  #       @value = orig_call(**options)
  #     end

  #   output_file = "#{File.dirname(__FILE__)}/../log/stackprof.json"
  #   File.write(output_file, JSON.generate(profile))
  #   @value
  # end

  private

  def connect_to_a(coords, root)
    if action = @actions.find { _1[HARVESTER] }
      debug("Looks like another root is going for a harvester via '#{action}'")
      return
    end

    if Entity.my_harvesters.size >= Entity.my_roots.size
      debug("A source of A for each root is being harvested, moving on with the strat.")
      return
    end

    if turn_storage.dig(turn, :new_root_cell)
      sporer = Entity[turn_storage.dig(turn, :sporer_cell)]
      new_root_cell = turn_storage.dig(turn, :new_root_cell)
      @actions << "SPORE #{sporer[:id]} #{new_root_cell.x} #{new_root_cell.y}"

      turn_storage[turn].merge!(new_root_cell: nil, sporer_cell: nil)
      return
    end

    paths = paths_to_As(from: [coords, root])
    return if paths.none?

    if Entity.my_harvesters.size > 0 && paths.first.size > 4
      debug("Root at #{coords} quite far from A sources, skipping")
      return
    end

    # Trying to deal with sources of A right next to my organs and needing to loop
    path =
      if paths.first.size == 2
        paths.select { _1.size > 2 }.first || paths.first
      else
        paths.first
      end

    if path.size == 3
      debug("Close source of A detected at #{path.last}, setting up a harvester")
      @actions << "GROW #{Entity[path.first][:id]} #{path[1].x} #{path[1].y} #{HARVESTER} #{arena.direction(*path.last(2))}"
    elsif (path.size > 6 || path.size > my_stock[:a]) && can_afford_new_colony? # sporing good idea
      debug("Detected far A source, will try sporing")

      new_root_cell = nil
      cells_i_can_reach = cells_on_same_row_or_column_as_i_can_reach
      path_index = paths.index(path)

      paths[path_index..].each do |path|
        break if new_root_cell
        places_for_new_root = arena.cells_at_distance(path.last, 2..2)

        new_root_cell =
          (places_for_new_root & cells_i_can_reach).sort_by do |cell|
            arena.shortest_path(cell, coords).size
          end.last

        if new_root_cell
          debug("Yay, far A source at #{path.last} can be reached by placing a new root at #{new_root_cell}")
        else
          debug("Hmm, A source at #{path.last} is far, and I can't seem to spore to it comfortably (diff of more than 2 in both x and y)")
        end
      end

      cell_to_grow_spore = cells_next_to_my_organs.find { |cell| cell.x == new_root_cell.x || cell.y == new_root_cell.y }

      if cell_to_grow_spore.nil?
        debug("D'oh, can't seem to be able to spore to protein source right away.")
        return
      end

      parent_cell = (arena.neighbors(cell_to_grow_spore) & Entity.my_organs.keys).first
      direction = arena.direction(cell_to_grow_spore, new_root_cell)

      debug("Growing a SPORER to reach a far A source at #{}")
      @actions << "GROW #{Entity[parent_cell][:id]} #{cell_to_grow_spore.x} #{cell_to_grow_spore.y} #{SPORER} #{direction}"

      turn_storage[turn.next] = {
        new_root_cell: new_root_cell,
        sporer_cell: cell_to_grow_spore
      }
    elsif path.size > 3
      debug("Reachable source of A detected at #{path.last}, growing towards it")
      @actions << "GROW #{Entity[path.first][:id]} #{path[1].x} #{path[1].y} BASIC"
    elsif (cells = cells_for_harvester(root, source_type: "A")).one?
      debug("Source of A already next-door detected at #{path.last}, setting up a harvester")
      direction = arena.direction(cells.first, path.last)
      @actions << "GROW #{my_latest_organ(root_id: root[:id]).last[:id]} #{cells.first.x} #{cells.first.y} #{HARVESTER} #{direction}"
    else # spawned next to A looks like
      debug("Looks like spawned next to A source, comparing looping to other options..")
      harvester_locations = arena.cells_at_distance(path.last, 1..1) - Entity.all.keys

      if harvester_locations.none?
        debug("No place for harvester but on top of other protein source, oh, well..")
        harvester_locations = arena.cells_at_distance(path.last, 1..1) - Entity.organs.keys
      end

      debug("Harvester locations are: #{harvester_locations}")
      paths = harvester_locations.filter_map { arena.shortest_path(coords, _1, excluding: Entity.sources.keys) }

      if paths.none?
        debug("No paths to nearby A without stepping on other protein sources :/")
        paths = harvester_locations.filter_map { arena.shortest_path(coords, _1, excluding: [path.last]) }
      end

      debug("Paths to harvester locations are: #{paths}")

      shortest_path = paths.sort_by { _1.size }.first

      path_to_other_source = path_to_closest_A(from: [coords, root], at_distance: 2..)

      shortest_path = path_to_other_source if path_to_other_source && shortest_path.size > path_to_other_source.size

      @actions << "GROW #{Entity[shortest_path.first][:id]} #{shortest_path[1].x} #{shortest_path[1].y} #{BASIC}"
    end
  end

  def grow_tentacle(coords, root)
    return unless can_afford?(**COSTS[TENTACLE])

    opp_start = path_from_me_to_opp.last

    excludes = turn < 90 ? Entity.harvested_sources.keys : []
    nearby_cells = (cells_next_to_my_organs(root_id: root[:id]) - excludes)

    cells_next_to_opp = (cells_next_to_opp_organs)

    conflict_cells = (nearby_cells & cells_next_to_opp)

    return if conflict_cells.none?

    growth_cell = conflict_cells.sort_by { arena.mahattan_distance(_1, opp_start) }.first

    if growth_cell
      debug("Found #{growth_cell} to grow tentacle")

      lowest_id_neighbor = Entity.my_organs.slice(*arena.neighbors(growth_cell))
        .sort_by { |coords, entity| entity[:id] }.first

      lowest_id_opp_neighbor = Entity.opp_organs.slice(*arena.neighbors(growth_cell))
        .sort_by { |coords, entity| entity[:id] }.first

      direction = arena.direction(growth_cell, lowest_id_opp_neighbor.first)
      @actions << "GROW #{lowest_id_neighbor.last[:id]} #{growth_cell.x} #{growth_cell.y} #{TENTACLE} #{direction}"
    else
      debug("No cells need batlling over, yay!")
    end
  end

  def spore_and_colonize(coords, root)
    return if promising_rows.none?

    best_row = promising_rows.sort_by { -(_1 & path_from_me_to_opp).size }.first

    return if best_row.nil?

    if spore_on_row = (Entity.my_sporers.select { |k, v| %w[W E].include?(v[:dir]) }.to_h.keys & best_row).first # sporer on best row?
      target = (
        (
          best_row.to_set &
          Entity.sources("A").flat_map { |k, v| arena.cells_at_distance(k, 2..2) }.reduce(&:merge)
        ) - Entity.organs.keys
      )
        .sort_by do |t|
          distance_from_mid = path_from_me_to_opp.mid.filter_map { arena.shortest_path(t, _1).size }.sort.first
          distance_from_me = arena.shortest_path(t, my_roots.first.first).size

          [distance_from_mid, distance_from_me]
        end.first

      if target.nil?
        debug("Have sporer on longest row, but no good spots to spore. Sporing far.")

        target =
          if best_row.index(spore_on_row) <= (best_row.size / 2)
            best_row.last
          else
            best_row.first
          end
      end

      if Entity[target] && Entity.organs[target]
        debug("Oops, there's an organ at sporing target, trying a closer target")
        target = best_row[best_row.size / 2]
      end

      if Entity[target] && Entity.organs[target]
        debug("Oops, there's an organ at middle sporing target, giving up")
        return
      end

      @actions << "SPORE #{Entity[spore_on_row][:id]} #{target.x} #{target.y}"
      return
    end

    # Looking for exactly shortest path is very expensive (organs * cells on best row),
    # so instead growing randomly and building spore on row is happen to reach it.
    # closest_path_to_open_cell_on_row = (best_row - Entity.sources("A").keys)
    #   .map { closest_path_to_my_organs(from: _1, excluding: Entity.sources("A").keys) }
    #   .sort_by { _1.size }.first

    # return if closest_path_to_open_cell_on_row.nil?

    # path = closest_path_to_open_cell_on_row.reverse

    # debug("Growing colony spores")
    # if path.size >= 3
    #   @actions << "GROW #{Entity[path.first][:id]} #{path[1].x} #{path[1].y} #{BASIC}"
    # elsif path.size == 2 # yay, nearby
    #   # facing the direction where there are more cells of this best row
    #   direction =
    #     if best_row.index(closest_open_cell_on_row) <= (best_row.size / 2)
    #       "E"
    #     else
    #       "W"
    #     end

    #   @actions << "GROW #{Entity[path.first][:id]} #{path.last.x} #{path.last.y} #{SPORER} #{direction}"
    # end
    #
    open_cells_on_best_row = (best_row - Entity.sources("A").keys)
    nearby_cell_on_row = (cells_next_to_my_organs(root_id: root[:id]) & open_cells_on_best_row).first
    return if nearby_cell_on_row.nil?


    parent = Entity[(arena.neighbors(nearby_cell_on_row) & Entity.my_organs(root_id: root[:id]).keys).first]

    # facing the direction where there are more cells of this best row
    direction =
      if best_row.index(nearby_cell_on_row) <= (best_row.size / 2)
        "E"
      else
        "W"
      end

    @actions << "GROW #{parent[:id]} #{nearby_cell_on_row.x} #{nearby_cell_on_row.y} #{SPORER} #{direction}"
  end

  # Aggressive growth action, growing towards opponent root spawn
  def expand(coords, root)
    opp_start = path_from_me_to_opp.last

    excludes = turn < 90 ? Entity.harvested_sources.keys : []
    nearby_cells = (cells_next_to_my_organs(root_id: root[:id]) - excludes)
      .sort_by { arena.mahattan_distance(_1, opp_start) }

    growth_cell = nearby_cells.first

    if growth_cell
      debug("Found #{growth_cell} to exand into")

      lowest_id_neighbor = Entity.my_organs.slice(*arena.neighbors(growth_cell))
        .sort_by { |coords, entity| entity[:id] }.first

      @actions << "GROW #{lowest_id_neighbor.last[:id]} #{growth_cell.x} #{growth_cell.y} #{BASIC}"
    else
      debug("No free cells for root #{coords} to expand to!")
    end
  end

  def wait(coords, root)
    debug("Root #{coords} waiting. Deactivating further actions.")
    @deactivated_roots << coords
    @actions << "WAIT"
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
  # def arena_without_source_cells
  #   arena.dup.tap { _1.remove_cells(Entity.sources.keys) }
  # end

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

  def closest_path_to_my_organs(from:, excluding: nil)
    Entity.my_organs.keys.filter_map do |my_organ_coords|
      next if excluding && excluding.include?(my_organ_coords)

      arena.shortest_path(from, my_organ_coords, excluding: excluding)
    end.sort_by(&:size).first
  end

  def closest_path_to_opp_organs(from:)
    opp_organs.keys.filter_map do |opp_organ_coords|
      arena.shortest_path(from, opp_organ_coords)
    end.sort_by(&:size).first
  end

  # @return Set<Point>
  def contentious_cells_at_distance(range)
    cells_at_distance = Set.new

    Entity.my_organs.keys.each do |organ_coord|
      cells_at_distance += arena.cells_at_distance(organ_coord, range)
    end

    cells_at_distance & cells_of_contention
  end

  # @return Set<Point>
  def cells_next_to_my_organs(root_id: nil)
    Entity.my_organs(root_id: root_id).keys.each_with_object(Set.new) do |my_organ_coords, mem|
      mem.merge(arena.neighbors(my_organ_coords))
    end - Entity.organs.keys
  end

  def cells_2_away_from_my_organs(root_id: nil)
    Entity.my_organs(root_id: root_id).keys.each_with_object(Set.new) do |my_organ_coords, mem|
      mem.merge(arena.cells_at_distance(my_organ_coords, 2..2))
    end - Entity.organs.keys
  end

  # @return Set<Point>
  def cells_next_to_opp_organs(root_id: nil)
    Entity.opp_organs(root_id: root_id).keys.each_with_object(Set.new) do |opp_organ_coords, mem|
      mem.merge(arena.neighbors(opp_organ_coords))
    end - Entity.organs.keys
  end

  # @return Integer
  def my_neighboring_organ_count(cell)
    (arena.neighbors(cell) & Entity.my_organs.keys).size
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

  def path_from_me_to_opp
    return @path_from_me_to_opp if defined?(@path_from_me_to_opp)

    opp_root_coords = Point[opp_roots.first.first.x, opp_roots.first.first.y]
    path = arena.shortest_path(my_roots.first.first, opp_root_coords, excluding: Entity.sources("A").keys)

    if path.nil?
      debug("No path to opponent if we spare A sources, falling back to non-sparing path")
      path = arena.shortest_path(my_roots.first.first, opp_root_coords)
    end

    @path_from_me_to_opp = path
  end

  def my_latest_organ(root_id:)
    Entity.my_organs.select { |k, v| v[:root_id] == root_id }.sort_by { |k, v| -v[:id] }.first
  end

  # Paradoxically, sources 2 away are better than ones next to organs
  #
  # @param from Array # [coords, root]
  # @param at_distance Range
  # @return Array<Array<Point>,nil>
  def paths_to_As(from:, at_distance: 1..)
    paths_to_sources = paths_to_sources(from: from, source_type: "A")

    # dropping further half since arenas are mirrored
    half = (Entity.sources("A").size / 2.0).ceil
    paths_to_sources = paths_to_sources[0..half]

    paths_to_sources.select! { at_distance.include?(arena.path_length(_1)) }

    organs_in_cluster = Entity.my_organs(root_id: from.last[:id])

    paths_from_source_to_organs = []

    paths_to_sources.each do |path|
      organs_in_cluster.each do |coords, organ|
        short_path = arena.shortest_path(path.last, coords, excluding: Entity.sources("A").keys + Entity.organs.keys)

        next if short_path.nil? || !at_distance.include?(arena.path_length(short_path))

        paths_from_source_to_organs << short_path if short_path
      end
    end

    if paths_from_source_to_organs.none?
      debug("Looks like there's no way to get to A sources without stepping on other A sources, lol")

      paths_to_sources.each do |path|
        organs_in_cluster.each do |coords, organ|
          short_path = arena.shortest_path(path.last, coords, excluding: Entity.organs.keys)

          next if short_path.nil? || !at_distance.include?(arena.path_length(short_path))

          paths_from_source_to_organs << short_path if short_path
        end
      end
    end

    paths_from_source_to_organs.sort_by { arena.path_length(_1) }.map(&:reverse)
  end

  # @param from Array # [coords, root]
  # @return [Array[coords, source], nil]
  def paths_to_sources(from:, source_type: "A")
    # debug("Available sources: #{Entity.available_sources(source_type)}")
    # debug("Harvested sources: #{Entity.harvested_sources(source_type)}")

    sources = Entity.available_sources(source_type)

    sources
      .map { |coords, source| arena.shortest_path(from.first, coords, excluding: Entity.harvested_sources("A").keys) }
      .sort_by { arena.path_length(_1) }
  end

  # Paradoxically, sources 2 away are better than ones next to organs
  #
  # @param from Array # [coords, root]
  # @param at_distance Range
  # @return [Array<Point>, nil]
  def path_to_closest_A(from:, at_distance: 1..)
    paths_to_As(from: from, at_distance: at_distance).first
  end

  # looking at two longest rows only because it can be a diagonal mirror
  #
  # @return Array<Array>
  def promising_rows
    return @promising_rows if defined?(@promising_rows)

    row_segments = arena.row_segments.values.flat_map { _1 }.sort_by { -_1.size }.first(2)

    @promising_rows =
      if row_segments.first.size >= 4
        row_segments
      else
        []
      end
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
  def refresh_arena
    @arena ||=
      begin
        a = Grid.new

        (0..(width - 1)).each do |x|
          (0..(height - 1)).each do |y|
            a.add_cell(Point[x, y])
          end
        end

        # Remove any cells out of bounds
        a.nodes.each do |node|
          if node.x.negative? || node.y.negative? || node.x > (width - 1) || node.y > (height - 1)
            a.remove_cell(node)
          end
        end

        a
      end

    # remove any cells marked as walls in entities
    entities.each do |coords, entity|
      next unless entity[:type] == WALL
      next if @arena[coords].nil?

      @arena.remove_cell(coords)
    end

    nil
  end

  def initialize_cells_of_contention
    return if defined?(@cells_of_contention)

    path = arena.shortest_path(my_roots.first.first, opp_roots.first.first)

    midpoint_low = (arena.path_length(path) / 2.0).floor
    midpoint_high = (arena.path_length(path) / 2.0).ceil
    range = midpoint_low..midpoint_high

    @cells_of_contention =
      arena.cells_at_distance(my_roots.first.first, range) &
      arena.cells_at_distance(opp_roots.first.first, range)

    @width_of_contention = path.size.even? ? 2 : 1

    nil
  end

  def active?(coords)
    !@deactivated_roots.include?(coords)
  end

  def debug_entities
    debug "Entities:"
    # @entities.to_a.last(25).each do |coords, entity|
    @entities.each do |coords, entity|
      debug("#{coords} => #{entity},") if entity[:type] != WALL
    end
  end

  def debug_walls
    return @debug_walls if defined?(@debug_walls)

    debug "Walls IDs:"
    wall_cells = []
    @entities.each do |coords, entity|
      # debug("#{coords} => #{entity},") if entity[:type] == WALL
      wall_cells << coords if entity[:type] == WALL
    end

    debug(wall_cells.to_s)

    @debug_walls = true
  end

  def debug_stocks
    debug "Protein stocks:"
    debug "  #{my_stock}"
    debug "  #{opp_stock}"
  end
end
