# frozen_string_literal: true

class AddVisibilityRulesToUserFields < ActiveRecord::Migration[7.0]
  def change
    add_column :user_fields, :visibility_rules, :jsonb, default: [], null: false
  end
end
