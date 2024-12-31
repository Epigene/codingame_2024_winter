debug "Game starts!"
# game loop
loop do
  entity_count = gets.to_i
  # debug("There's #{entity_count} entities:")

  entities = {}

  entity_count.times do
    # type: WALL, ROOT, BASIC, TENTACLE, HARVESTER, SPORER, A, B, C, D
    # owner: 1 if your organ, 0 if enemy organ, -1 if neither
    # organ_id: id of this entity if it's an organ, 0 otherwise
    # organ_dir: N,E,S,W or X if not an organ
    x, y, type, owner, organ_id, organ_dir, organ_parent_id, organ_root_id = gets.split

    entities[Point[x.to_i, y.to_i]] = {
      type: type,
      owner: owner.to_i,
      id: organ_id.to_i,
      dir: organ_dir,
      parent_id: organ_parent_id.to_i,
      root_id: organ_root_id.to_i,
    }
  end

  my_a, my_b, my_c, my_d = gets.split.map { |x| x.to_i }
  my_stock = {
    a: my_a,
    b: my_b,
    c: my_c,
    d: my_d,
  }

  opp_a, opp_b, opp_c, opp_d = gets.split.map { |x| x.to_i }
  opp_stock = {
    a: opp_a,
    b: opp_b,
    c: opp_c,
    d: opp_d,
  }

  required_actions = gets.to_i # your number of organisms, output an action for each one in any order

  controller.call(
    entities: entities, my_stock: my_stock, opp_stock: opp_stock, required_actions: required_actions
  ).each do |action|
    puts action
  end
end
