class Land < ActiveNode::Base
  has_many :bridges, class_name: 'Land'

  def connect! other_side, attrs={}
    ActiveNode::Neo.db.create_relationship :bridge, id, other_side.id, attrs
  end
end
