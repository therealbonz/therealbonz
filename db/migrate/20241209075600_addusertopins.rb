class Addusertopins < ActiveRecord::Migration[8.0]
  def change
    add_reference :pins, :user, null: false, foreign_key: true
  end
end
