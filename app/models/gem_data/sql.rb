class GemData
  module Sql
    extend self

    def by_name name
      GemData.where name: name
    end

    def by_author name
      Author.find_by_name(name).gem_data
    end

    def with_dependency gem
      # NOTE: please don't do this
      GemData.where 'spec LIKE ?', %{%"name":"#{gem}"%}
    end

    def most_downloaded cutoff: 10_000, limit: 20
      GemData.find_each.
        select  { |g| g.spec['downloads'] > cutoff }.
        sort_by { |g| - g.spec['downloads'] }.
        first limit
    end
  end
end
