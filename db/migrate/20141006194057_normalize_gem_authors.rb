class NormalizeGemAuthors < ActiveRecord::Migration
  def up
    GemData.find_each do |g|
      authors = g.spec["authors"].split(",").map &:strip
      authors.each do |name|
        author = Author.where(name: name).first_or_create!
        g.authors << author
      end
    end
  end

  def down
    AuthorGemDatum.delete_all
    Author.delete_all
  end
end
