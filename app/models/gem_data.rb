class GemData < ActiveRecord::Base
  serialize :spec, JSON

  has_many :author_gem_data
  has_many :authors, through: :author_gem_data

  # Neo4J queries -----

  def self.node_names query, opts
    results = $neo.raw query, opts
    results.map { |r| r['data']['name'] }
  end

  def dependencies limit=25
    self.class.node_names %{
      MATCH (:Gem {name:{name}})-[:depends*]->(a:Gem)
      RETURN DISTINCT a
      LIMIT {limit}
    }, name: name, limit: limit
  end

  def dependants limit=25
    self.class.node_names %{
      MATCH (a:Gem)-[:depends*]->(:Gem {name: {name}})
      RETURN DISTINCT a
      LIMIT {limit}
    }, name: name, limit: limit
  end

  def self.most_important limit=25
    node_names %{
      MATCH (c:Gem)-[:depends*]->(n:Gem)
      RETURN n, count(DISTINCT c) as connections
      ORDER BY connections DESC
      LIMIT {limit}
    }, limit: limit
  end

  def self.people_to_ask_for_money author, limit=25
    node_names %{
      MATCH (:Author {name:{name}})-[:wrote]->()<-[:depends]-()<-[:wrote]-(a:Author)
      RETURN DISTINCT a
      LIMIT {limit}
    }, name: author, limit: limit
  end
end
