# Implements a cell-based Grid - a special sub-type of a directionless and weightless graph structure.
# Node IDs are [X, Y] Point objects.
# [0, 0] origin is assumed to be in the upper left, [1, 1] is to the lower right of it.
# Allows special concepts like "row", "column", "straight line along a row/column", and "diagonally".
#
# Initialization gives you an empty grid. Use #add_cell to populate the grid. By default the new
# cell will be connected to all four neighbour cells. Use kwargs to :except or :only needed connections.
class Grid
  # Key data storage.
  # Each key is a node (key == name),
  # and the value set represents the neighbouring nodes.
  # private attr_reader :structure

  NEIGHBORS = [
    N = [0, -1].freeze, # North
    E = [1, 0].freeze, # East
    S = [0, 1].freeze, # South
    W = [-1, 0].freeze, # West
  ].freeze

  def initialize
    @structure =
      Hash.new do |hash, key|
        hash[key] = Set.new
      end
  end

  # Returns a new
  # @return Grid
  def dup
    duplicate = self.class.new
    new_structure = {}
    nodes.each { new_structure[_1] = self[_1].dup }
    duplicate.instance_variable_set("@structure", new_structure)
    duplicate
  end

  # A shorthand access to underlying has node structure
  def [](node)
    structure[node]
  end

  def nodes
    structure.keys
  end

  # adds a new cell node. By default all 4 neighbors, but kwars allow tweaking that.
  #
  # @param point Point
  # @param except Array<neighbor>
  # @param only Array<neighbor>
  def add_cell(point, except: nil, only: nil)
    raise ArgumentError.new("Only one of :except or :only kwards is supported") if !except.nil? && !only.nil?

    neighbors = NEIGHBORS.dup

    if !except.nil?
      neighbors -= except
    elsif !only.nil?
      neighbors &= only
    end

    raise ArgumentError.new(":except/:only use made a cell have no neighbors") if neighbors.none?

    neighbors.each do |neighbor|
      neighbor = Point[point.x + neighbor.first, point.y + neighbor.last]

      structure[point] << neighbor
      structure[neighbor] << point
    end

    nil
  end

  # Removes a list of cells and any connections to it from the neighbors
  # @return [nil]
  def remove_cells(cells)
    cells.each do |cell|
      remove_cell(cell)
    end

    nil
  end

  # Removes the cell and any connections to it from the neighbors
  # @return [nil]
  def remove_cell(cell)
    return if structure[cell].nil?

    structure[cell].each do |other_cell|
      structure[other_cell] -= [cell]
      structure.delete(other_cell) if structure[other_cell].none?
    end

    structure.delete(cell)

    nil
  end

  # @param root/@destination [String] # names of the nodes for which to find path
  #
  # @return [Array, nil] # will return an array of nodes from root to destination, or nil if no path exists
  def dijkstra_shortest_path(root, destination)
    # When we choose the arbitrary starting parent node we mark it as visited by changing its state in the 'visited' structure.
    visited = [root].to_set

    parent_node_list = {root => nil}

    # Then, after changing its value from FALSE to TRUE in the "visited" hash, we’d enqueue it.
    queue = [root]

    # Next, when dequeing the vertex, we need to examine its neighboring nodes, and iterate (loop) through its adjacent linked list.
    loop do
      dequeued_node = queue.shift
      # debug "dequed '#{ dequeued_node }', remaining queue: '#{ queue }'"

      if dequeued_node.nil?
        return
        # raise("Queue is empty, but destination not reached!")
      end

      neighboring_nodes = structure[dequeued_node].sort_by { -structure[_1].size }
      # debug "neighboring_nodes for #{ dequeued_node }: '#{ neighboring_nodes }'"

      neighboring_nodes.each do |node|
        # If either of those neighboring nodes hasn’t been visited (doesn’t have a state of TRUE in the “visited” array),
        # we mark it as visited, and enqueue it.
        next if visited.include?(node)

        visited << node
        parent_node_list[node] = dequeued_node

        # debug "parents: #{ parent_node_list }"

        if node == destination
          # destination reached
          path = [node]

          loop do
            parent_node = parent_node_list[path.first]

            return path if parent_node.nil?

            path.unshift(parent_node)
            # debug "path after update: #{ path }"
          end
        else
          queue << node
        end
      end
    end
  end

  # Feed in for example shortest path found to get its distance. Useful when comparing routes
  #
  # @param path [Array<cell>]
  # @return Integer
  def path_length(path)
    path.size - 1
  end

  # Returns cells that are specified distance away from a given cell. Useful for telling
  # which cells are covered by a bombard attack 2-3 cells away etc.
  #
  # @param range Range
  # @return Set
  def cells_at_distance(point, range)
    visited = Set.new
    queue = [[point, 0]] # Each element is [current_cell, current_distance]
    result = Set.new

    while queue.any?
      current_cell, current_distance = queue.shift

      # Skip if already visited
      next if visited.include?(current_cell)

      visited.add(current_cell)

      # Add to result if within the range
      if range.include?(current_distance)
        result << current_cell
      end

      # Stop exploring if the current distance exceeds the maximum range
      next if current_distance > range.max

      # Enqueue all neighbors with incremented distance
      structure[current_cell].each do |neighbor|
        queue << [neighbor, current_distance.next]
      end
    end

    result
  end

  def cells_at_diagonal_distance(point, range)
    diagonal_as_direct_ranges = range.map { (_1 * 2)..(_1 * 2) }

    cells_at_distances = diagonal_as_direct_ranges.map do |range|
      cells_at_distance(point, range)
    end.flatten.reduce { |a, b| a += b }

    cells_at_distances.reject do |cell|
      cell.x == point.x || cell.y == point.y
    end.to_set
  end

  # Assumes points on at least same row/column. Tells the cardinal direction of the pair.
  # @return String # one of %w[N E S W]
  def direction(point_a, point_b)
    if point_a.x == point_b.x && point_a.y > point_b.y
      return "N"
    elsif point_a.x == point_b.x && point_a.y < point_b.y
      return "S"
    elsif point_a.y == point_b.y && point_a.x > point_b.x
      return "W"
    elsif point_a.y == point_b.y && point_a.x < point_b.x
      return "E"
    end

    raise "Hmm, same points?"
  end

  private

    def structure
      @structure
    end
end
