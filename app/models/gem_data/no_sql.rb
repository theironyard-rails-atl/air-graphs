class GemData
  module NoSql
    # This is just an inordinately clever way of being able to call
    #   GemData::Mongo.by_name ... without having to mixin or
    #   initialize anything
    extend self

    def collection
      $mongo.db('ruby_gems').collection('gems')
    end

    def by_name name
      collection.find_one 'name' => name
    end

    def bad_by_author name
      collection.find('spec.authors' => name).to_a
      #collection.find('spec.authors' => /#{name}/).to_a
    end

    def by_author name
      collection.find('spec.authors_list' => name).to_a
    end

    def most_downloaded cutoff: 10_000, limit: 20
      collection.
        find('spec.downloads' => { '$gt' => cutoff }).
        limit(limit).
        sort('spec.downloads' => :desc).
        to_a
    end

    def with_dependency gem
      # { '$or' => [
      #   { 'spec.dependencies.development.name' => gem },
      #   { 'spec.dependencies.runtime' => gem }
      # ] }
      collection.find('spec.dependencies.runtime.name' => gem).to_a
    end
  end
end
