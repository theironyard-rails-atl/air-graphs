class User::Node < ActiveNode::Base
  has_many :friends, class_name: 'User::Node'

  def self.first_or_create! attrs
    where(attrs).first || create!(attrs)
  end

  def neo
    ActiveNode::Neo.db
  end

  def get_nodes query, opts={}
    self.class.find_by_cypher query.squish, opts
  end

  def get_data query, opts
    result = ActiveNode::Neo.db.execute_query query.squish, opts
    result['data'].pop.pop
  end

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

  def shortest_path other
    get_data %{
      START self=node({id}), o=node({other_id})
      MATCH p=shortestPath((self)-[*]-(o))
      RETURN p
    }, id: id, other_id: other.id
  end

  def friendship_distance other
    shortest_path(other)['length']
  end

  def network depth
    get_nodes %{
      START self=node({id})
      MATCH (self)-[*..#{depth.to_i}]-(a)
      RETURN DISTINCT a
    }, id: id
  end
end
