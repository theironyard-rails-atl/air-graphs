class Author < ActiveRecord::Base
  has_many :author_gem_data
  has_many :gem_data, through: :author_gem_data
end
