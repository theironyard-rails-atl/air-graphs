class GemData
  module Sql
    extend self

    def by_name name
      GemData.where name: name
    end

    def by_author name
      Author.find_by_name(name).gem_data
    end

    def by_platform name
      GemData.where "json_spec->>'platform' = ?", name
    end

    def with_dependency gem
      # This still isn't ideal, but is closer
      #GemData.where "json_spec#>>'{dependencies,runtime}' LIKE ?", "%#{gem}%"

      # This works if we pre-process the data slightly (though is
      #   vulnerable to SQL injection if we're not careful)
      GemData.where "json_spec#>>'{reformatted_dependencies,#{gem}}' = runtime"
    end

    def most_downloaded cutoff: 10_000, limit: 20
      # NOTE:
      #   -> returns a JSON object (which isn't comparable to an int)
      #   ->> returns a string (which can be cast)
      GemData.where("(json_spec->>'downloads')::int > ?", cutoff).
        order("(json_spec->>'downloads')::int").
        limit(limit)
    end
  end
end
