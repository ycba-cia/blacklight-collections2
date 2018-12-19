class CreateInterfaceMapping < ActiveRecord::Migration[5.1]
  def change
    create_table :interface_mappings do |t|
      t.integer :vufind_id
      t.string :oai_id
    end
  end
end
