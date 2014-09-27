class GemData < ActiveRecord::Base
  serialize :spec, JSON
  serialize :dependencies, JSON

  scope :fetched,   -> { where fetched: true  }
  scope :unfetched, -> { where fetched: false }
end
