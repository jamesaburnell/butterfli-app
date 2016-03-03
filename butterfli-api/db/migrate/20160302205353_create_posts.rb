class CreatePosts < ActiveRecord::Migration
  def change
    create_table :posts do |t|
      t.string :title
      t.string :og_source
      t.string :body
      t.string :image_src

      t.timestamps null: false
    end
  end
end
