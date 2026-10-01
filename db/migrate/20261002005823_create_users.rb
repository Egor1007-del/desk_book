class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :last_name, null: false
      t.string :first_name, null: false
      t.string :middle_name
      t.references :position, null: false, foreign_key: true
      t.date :hired_on, null: false
      t.string :phone
      t.string :email
      t.string :login, null: false
      t.string :encrypted_password, null: false

      t.timestamps
    end

    add_index :users, "LOWER(login)", unique: true, name: "index_users_on_lower_login"
  end
end
