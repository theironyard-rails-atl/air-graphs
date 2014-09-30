# We do have a connection available as ActiveNode::Neo.db, but
#   can also connect directly using Neography
require 'neography'

$neo = Neography::Rest.new

def $neo.raw query, opts={}
  result = execute_query query.squish, opts
  result['data'].map &:first
end
