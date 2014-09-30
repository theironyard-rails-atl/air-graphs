namespace :users do
  desc 'Generate a random social network'
  task :generate do
    # Generate a small-world graph using the Watts-Strogatz model
    user_count       = n = 250
    avg_friend_count = k = 4
    rewire_prob      = b = 0.1

    # Clear pre-existing links
    [User::Record, Friendship].each &:delete_all

    # Create enough user nodes
    n.times { User::Record.create! name: Faker::Name.name }

    puts "Generating a uniform friend lattice"
    graph, popularity = {}, {}
    ids = User::Record.pluck :id
    ids.each_with_index do |id, index|
      graph[id] = Set.new
      popularity[id] = 0

      (-k/2).upto(k/2) do |i|
        graph[id].add ids[(index + i) % n] unless i.zero?
      end
    end

    puts 'Rewiring edges'
    graph.each do |node, neighbors|
      available = Set.new(ids) - neighbors
      available.delete node

      neighbors.clone.each do |neighbor|
        if rand < b
          neighbors.delete neighbor
          available.add neighbor

          replacement = available.to_a.sample

          available.delete replacement
          neighbors.add replacement
        end
      end
    end

    puts 'Creating friendship objects'
    graph.each do |node, neighbors|
      neighbors.each do |neighbor|
        popularity[neighbor] += 1
        Friendship.create! from_id: node, to_id: neighbor
        Friendship.create! from_id: neighbor, to_id: node
      end
    end

    # Vanity, thy name is ...
    me = popularity.max_by { |k,v| v }.first
    User::Record.find(me).update_attribute :name, 'James Dabbs'
  end


  desc 'Export the SQL User data to Neo4j'
  task :export do
    puts 'Generating graph nodes for each user'
    User::Record.where(node_id: nil).find_each do |rec|
      node = User::Node.first_or_create! name: rec.name
      rec.update_attribute :node_id, node.id
    end

    puts 'Linking friends'
    total = User::Record.count
    User::Record.find_each.each_with_index do |rec,i|
      print "\r#{i} / #{total}"
      next if rec.node.friends.any?
      rec.node.friends = rec.friends.map(&:node)
      rec.node.save
    end
    puts
  end
end
