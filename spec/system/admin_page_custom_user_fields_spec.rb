# frozen_string_literal: true

RSpec.describe "Discourse Authentication Validations - Admin Page - Custom User Fields" do
  fab!(:admin)
  fab!(:user_field_without_validation) do
    Fabricate(
      :user_field,
      name: "without_validation",
      field_type: "confirm",
      editable: true,
      required: false,
      has_custom_validation: false,
      show_values: [],
      target_user_field_ids: [],
    )
  end

  before do
    SiteSetting.discourse_authentication_validations_enabled = true
    sign_in(admin)
  end

  it "shows `has_custom_validation` checkbox" do
    visit "/admin/config/user-fields"
    find(".admin-user_field-item__edit").click
    expect(page).to have_selector(".has-custom-validation-checkbox")
  end

  it "hides additional custom validation fields until `has_custom_validation` checkbox is active" do
    visit "/admin/config/user-fields"
    find(".admin-user_field-item__edit").click

    expect(find(".has-custom-validation-checkbox")).not_to be_checked
    expect(page).to have_no_css(".user-field .show-values-input")
    expect(page).to have_no_css(".user-field .target-classes-input")
  end
end
