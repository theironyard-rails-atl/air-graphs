class AddJsonSpecToGemData < ActiveRecord::Migration
  def change
    add_column :gem_data, :json_spec, :json
  end
end
