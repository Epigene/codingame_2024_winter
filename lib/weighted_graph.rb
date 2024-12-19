# Implements a directionless weighted graph structure with named nodes.
# Initialization gives you an empty graph. Then call #connect_nodes for relevant
# connections with weights. This will ensure nodes implicitly.
class WeightedGraph
  # Key data storage.
  # Each key is a node (key == name),
  # and the value set represents the neighbouring nodes and their distances.

  def initialize
    @structure = Hash.new { |hash, key| hash[key] = {} }
  end

  # A shorthand access to the underlying node structure
  def [](node)
    structure[node]
  end

  def nodes
    structure.keys
  end

  # Adds a bi-directional connection between two nodes with a given distance (weight)
  def connect_nodes(node1, node2, distance)
    structure[node1][node2] = distance
    structure[node2][node1] = distance

    nil
  end

  # Severs all connections to and from this node
  # @return [nil]
  def remove_node(node)
    structure[node].each_key do |neighbor|
      structure[neighbor].delete(node)
    end

    structure.delete(node)

    nil
  end

  # @param root [String] # name of the starting node
  # @param destination [String] # name of the target node
  #
  # @return [Array, nil] # will return an array of nodes from root to destination, or nil if no path exists
  def dijkstra_shortest_path(root, destination)
    distances = Hash.new(Float::INFINITY)
    previous_nodes = {}
    distances[root] = 0
    unvisited = structure.keys.to_set

    until unvisited.empty?
      # Get the node with the smallest distance
      current_node = unvisited.min_by { |node| distances[node] }

      # If the smallest distance is infinity, the remaining nodes are unreachable
      break if distances[current_node] == Float::INFINITY

      unvisited.delete(current_node)

      # Check all neighbors of the current node
      structure[current_node].each do |neighbor, weight|
        alternative_route = distances[current_node] + weight
        if alternative_route < distances[neighbor]
          distances[neighbor] = alternative_route
          previous_nodes[neighbor] = current_node
        end
      end

      # Stop if we reached the destination
      break if current_node == destination
    end

    # Reconstruct the shortest path
    path = []
    current_node = destination

    while previous_nodes[current_node]
      path.unshift(current_node)
      current_node = previous_nodes[current_node]
    end

    return nil if distances[destination] == Float::INFINITY
    path.unshift(root)
    path
  end

  # Feed in for example shortest path found to get its distance. Useful when comparing routes
  #
  # @param path [Array<NodeName>]
  def path_length(path)
    total = 0.0

    path.each_cons(2) do |a, b|
      total += structure.dig(a, b)
    end

    total
  end

  private

  def structure
    @structure
  end

  def initialize_copy(copy)
    dupped_structure = structure.each_with_object({}) do |(k, v), mem|
      mem[k] = v.dup
    end

    copy.instance_variable_set("@structure", dupped_structure)
    super
  end
end
