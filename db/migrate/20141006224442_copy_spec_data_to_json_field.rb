class CopySpecDataToJsonField < ActiveRecord::Migration
  def up
    GemData.find_each do |g|
      g.json_spec = g.spec

      # convert
      #   dependencies: {
      #     runtime: [ {name: "a", v: 1}, {name: "b", v: 2} ],
      #     development: [ {name: "c", v: 1} ]
      #   }
      # to
      #   reformatted_dependencies: {
      #     a: { v: 1, type: "runtime" },
      #     b: { v: 2, type: "runtime" },
      #     c: { v: 1, type: "development" }
      #   }
      d = {}
      %w( development runtime ).each do |type|
        g.spec["dependencies"][type].each do |dep|
          name = dep["name"]

          d[ name ] = dep.clone
          d[ name ]["type"] = type
          d[ name ].delete "name"
        end
      end
      g.json_spec["reformatted_dependencies"] = d

      g.save!
    end
  end

  def down
    GemData.update_all :json_spec => nil
  end
end
