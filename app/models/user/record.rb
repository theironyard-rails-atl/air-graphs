class User::Record < ActiveRecord::Base
  self.table_name = :users


  # -- Utility functions ----

  def get_records query
    self.class.joins(query.squish).uniq.to_a
  end

  def node
    return @_node if @_node

    unless node_id
      @_node = User::Node.create! attributes
      update_attribute! :node_id, @_node.id
    end

    @_node ||= User::Node.find node_id
  end


  # -- Friend methods ----

  def friends
    get_records %{
      INNER JOIN friendships AS f1 ON users.id = f1.to_id
      WHERE f1.from_id = #{id}
    }
  end

  def friends_of_friends
    get_records %{
      INNER JOIN friendships AS f1 ON f1.to_id = users.id
      INNER JOIN friendships AS f2 ON f2.to_id = f1.from_id
      WHERE f2.from_id = #{id}
    }
  end

  def friends_in_common_with other
    get_records %{
      INNER JOIN friendships AS f1 ON f1.to_id = users.id
      INNER JOIN friendships AS f2 ON f2.from_id = users.id
      WHERE f1.from_id = #{id} AND f2.to_id = #{other.id}
    }
  end

  def friends_of_friends_of_friends
    get_records %{
      INNER JOIN friendships AS f1 ON f1.to_id = users.id
      INNER JOIN friendships AS f2 ON f2.to_id = f1.from_id
      INNER JOIN friendships AS f3 ON f3.to_id = f2.from_id
      WHERE f3.from_id = #{id}
    }
  end

  # Find the number of links necessary to connect this user to `other`.
  # A similar method could be adapted to find the path, or to find all friends
  #   up to a particular distance
  def friendship_distance other
    visited, boundary, distance = Set.new, Set.new([id]), 0

    loop do
      adjacents  = Friendship.where("from_id IN (?) OR to_id IN (?)",
                                    boundary, boundary)
      froms, tos = adjacents.map(&:from_id), adjacents.map(&:to_id)
      visited    = visited.union boundary
      boundary   = Set.new(froms).union(tos) - visited
      distance += 1

      return distance if boundary.include? other.id
      return Float::INFINITY if boundary.empty?
    end
  end
end
