class User::Node < ActiveNode::Base
  has_many :friends, class_name: 'User::Node'


  # -- Utility functions ----

  def self.first_or_create! attrs
    where(attrs).first || create!(attrs)
  end

  def self.get_nodes query, opts={}
    find_by_cypher query.squish, opts
  end
  def get_nodes *args
    self.class.get_nodes *args
  end

  def get_one query, opts={}
    result = ActiveNode::Neo.db.execute_query query.squish, opts
    result['data'].pop.pop
  end


  # -- Friend methods ----

  def friends_of_friends
    get_nodes %{
      START self=node({id})
      MATCH (self)--()--(a)
      RETURN DISTINCT a
    }, id: id
  end

  def friends_in_common_with other
    get_nodes %{
      START self=node({id}), o=node({other_id})
      MATCH (self)--(a)--(other_id)
      RETURN DISTINCT a
    }, id: id, other_id: other.id
  end

  def friends_of_friends_of_friends
    get_nodes %{
      START self=node({id})
      MATCH (self)-[*3]-(a)
      RETURN DISTINCT a
    }, id: id
  end

  def shortest_path_to other
    result = get_one %{
      START self=node({id}), o=node({other_id})
      MATCH p=shortestPath((self)-[*]-(o))
      RETURN p
    }, id: id, other_id: other.id
    ids = result['nodes'].map { |n| n.split('/').last }
    User::Node.find(ids).map { |n| n[:name] }
  end

  def friendship_distance other
    shortest_path(other).length
  end


  # -- A few extras ----

  def network depth
    get_nodes %{
      START self=node({id})
      MATCH (self)-[*..#{depth.to_i}]-(a)
      RETURN DISTINCT a
    }, id: id
  end

  def self.most_popular limit=5
    get_nodes %{
      MATCH (n:`User::Node`)--(c)
      RETURN n, count(*) as connections
      ORDER BY connections DESC
      LIMIT {limit}
    }, limit: limit
  end
  def self.least_popular limit=5
    get_nodes %{
      MATCH (n:`User::Node`)--(c)
      RETURN n, count(*) as connections
      ORDER BY connections ASC
      LIMIT {limit}
    }, limit: limit
  end
end
