class AuthorGemDatum < ActiveRecord::Base
  belongs_to :author
  belongs_to :gem_data
end
