# frozen_string_literal: true

RSpec.describe "Discourse Authentication Validation - Custom User Field - Confirm Field" do
  let(:custom_validation_page) { PageObjects::Pages::CustomValidation.new }

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

  fab!(:user_field_with_validation_1) do
    Fabricate(
      :user_field,
      name: "with_validation_1",
      field_type: "confirm",
      editable: true,
      required: false,
      has_custom_validation: true,
      show_values: [],
      target_user_field_ids: [],
    )
  end

  fab!(:user_field_without_validation_2) do
    Fabricate(
      :user_field,
      name: "without_validation_2",
      field_type: "confirm",
      editable: true,
      required: false,
      has_custom_validation: false,
      show_values: [],
      target_user_field_ids: [],
    )
  end

  fab!(:user_field_with_validation_3) do
    Fabricate(
      :user_field,
      name: "with_validation_3",
      field_type: "confirm",
      editable: true,
      required: false,
      has_custom_validation: true,
      show_values: ["null"],
      target_user_field_ids: [user_field_without_validation_2.id],
    )
  end

  fab!(:user_field_with_validation_2) do
    Fabricate(
      :user_field,
      name: "with_validation_2",
      field_type: "confirm",
      editable: true,
      required: false,
      has_custom_validation: true,
      show_values: ["true"],
      target_user_field_ids: [user_field_with_validation_1.id],
    )
  end

  fab!(:user_field_without_validation_3) do
    Fabricate(
      :user_field,
      name: "without_validation_3",
      field_type: "confirm",
      editable: true,
      required: false,
      has_custom_validation: false,
      show_values: [],
      target_user_field_ids: [],
    )
  end

  fab!(:user_field_with_validation_4) do
    Fabricate(
      :user_field,
      name: "with_validation_4",
      field_type: "confirm",
      editable: true,
      required: false,
      has_custom_validation: true,
      show_values: [],
      target_user_field_ids: [user_field_without_validation_3.id],
    )
  end

  before do
    SiteSetting.discourse_authentication_validations_enabled = true
    visit("/signup")
  end

  it "shows child when parent has no custom validation" do
    expect(page).to have_css(custom_validation_page.target_class(user_field_without_validation))
  end

  it "hides child when included in target_user_field_ids" do
    expect(page).to have_no_css(custom_validation_page.target_class(user_field_with_validation_1))
  end

  it "shows child when not included in target_user_field_ids" do
    expect(page).to have_css(custom_validation_page.target_class(user_field_with_validation_2))
  end

  context "when show_values is set to 'true'" do
    it "shows the child when checked" do
      custom_validation_page.click_confirmation(
        custom_validation_page.target_class(user_field_with_validation_2),
      )
      expect(page).to have_css(custom_validation_page.target_class(user_field_with_validation_1))
    end

    it "hides child when not checked" do
      expect(page).to have_no_css(custom_validation_page.target_class(user_field_with_validation_1))
    end
  end

  context "when show_values includes 'null'" do
    it "shows child" do
      expect(page).to have_css(custom_validation_page.target_class(user_field_without_validation_2))
    end

    it "toggles the display of the child after the value has changed" do
      custom_validation_page.click_confirmation(
        custom_validation_page.target_class(user_field_with_validation_3),
      )
      expect(page).to have_no_css(
        custom_validation_page.target_class(user_field_without_validation_2),
      )
    end
  end

  context "when show_values are not set" do
    it "hides the child" do
      custom_validation_page.click_confirmation(
        custom_validation_page.target_class(user_field_with_validation_4),
      )
      expect(page).to have_no_css(
        custom_validation_page.target_class(user_field_without_validation_3),
      )
    end
  end
end
