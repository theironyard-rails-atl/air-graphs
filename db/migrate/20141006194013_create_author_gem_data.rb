class CreateAuthorGemData < ActiveRecord::Migration
  def change
    create_table :author_gem_data do |t|
      t.integer :author_id
      t.integer :gem_data_id

      t.timestamps
    end
  end
end
