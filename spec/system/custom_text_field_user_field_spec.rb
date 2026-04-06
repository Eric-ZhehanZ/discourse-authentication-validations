# frozen_string_literal: true

RSpec.describe "Discourse Authentication Validation - Custom User Field - Text Field" do
  let(:custom_validation_page) { PageObjects::Pages::CustomValidation.new }

  fab!(:user_field_without_validation) do
    Fabricate(
      :user_field,
      name: "without_validation",
      field_type: "text",
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
      field_type: "text",
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
      field_type: "text",
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
      field_type: "text",
      editable: true,
      required: false,
      has_custom_validation: true,
      show_values: ["show_validation"],
      target_user_field_ids: [user_field_without_validation_2.id],
    )
  end

  fab!(:user_field_with_validation_2) do
    Fabricate(
      :user_field,
      name: "with_validation_2",
      field_type: "text",
      editable: true,
      required: false,
      has_custom_validation: true,
      show_values: ["show_validation"],
      target_user_field_ids: [user_field_with_validation_1.id, user_field_with_validation_3.id],
    )
  end


  fab!(:user_field_visible_for_contains) do
    Fabricate(
      :user_field,
      name: "visible_for_contains",
      field_type: "text",
      editable: true,
      required: false,
      has_custom_validation: false,
      show_values: [],
      target_user_field_ids: [],
    )
  end

  fab!(:user_field_visible_for_exact_match) do
    Fabricate(
      :user_field,
      name: "visible_for_exact_match",
      field_type: "text",
      editable: true,
      required: false,
      has_custom_validation: false,
      show_values: [],
      target_user_field_ids: [],
    )
  end

  fab!(:user_field_with_advanced_rules) do
    Fabricate(
      :user_field,
      name: "with_advanced_rules",
      field_type: "text",
      editable: true,
      required: false,
      has_custom_validation: true,
      show_values: [],
      target_user_field_ids: [],
      visibility_rules: [
        {
          rule_type: "text",
          operator: "contains",
          values: ["foo"],
          target_user_field_ids: [user_field_visible_for_contains.id],
        },
        {
          rule_type: "text",
          operator: "equals",
          values: ["bar"],
          target_user_field_ids: [user_field_visible_for_exact_match.id],
        },
      ],
    )
  end

  before do
    SiteSetting.discourse_authentication_validations_enabled = true
    visit("/signup")
  end

  it "hides child when included in target_user_field_ids" do
    expect(page).to have_no_css(custom_validation_page.target_class(user_field_with_validation_1))
  end

  it "displays child when not included in target_user_field_ids" do
    expect(page).to have_css(custom_validation_page.target_class(user_field_with_validation_2))
  end

  it "shows child when parent has no custom validation" do
    expect(page).to have_css(custom_validation_page.target_class(user_field_without_validation))
  end

  context "when updating input value with a custom validation" do
    it "hides child when show_values not set on parent" do
      page.find(custom_validation_page.target_class(user_field_with_validation_2)).fill_in(
        with: "not a show value",
      )
      expect(page).to have_no_css(custom_validation_page.target_class(user_field_with_validation_1))
    end

    it "shows the child when the input matches a show_values value on parent" do
      page.find(custom_validation_page.target_class(user_field_with_validation_2)).fill_in(
        with: "show_validation",
      )
      expect(page).to have_css(custom_validation_page.target_class(user_field_with_validation_3))
    end

    it "hides the child when the input does not match a show_values value on parent" do
      page.find(custom_validation_page.target_class(user_field_with_validation_2)).fill_in(
        with: "not a show value",
      )
      expect(page).to have_no_css(custom_validation_page.target_class(user_field_with_validation_1))
    end

    it "shows the nested child when the input matches a show_values value on nested parent" do
      page.find(custom_validation_page.target_class(user_field_with_validation_2)).fill_in(
        with: "show_validation",
      )
      page.find(custom_validation_page.target_class(user_field_with_validation_3)).fill_in(
        with: "show_validation",
      )
      expect(page).to have_css(custom_validation_page.target_class(user_field_without_validation_2))
    end

    it "clears the nested child when the input does not match a show_values value on grandparent" do
      page.find(custom_validation_page.target_class(user_field_with_validation_2)).fill_in(
        with: "show_validation",
      )
      page.find(custom_validation_page.target_class(user_field_with_validation_3)).fill_in(
        with: "show_validation",
      )
      # Add a value to the nested child, so we can check that it is cleared after the grandparent is changed
      page.find(custom_validation_page.target_class(user_field_without_validation_2)).fill_in(
        with: "should_be_cleared",
      )

      # Update grandparent
      page.find(custom_validation_page.target_class(user_field_with_validation_2)).fill_in(
        with: "not a show validation",
      )
      # Since the grandparent was updated, we expect that the nested child is also hidden, and the parent should be cleared
      expect(page).to have_no_css(
        custom_validation_page.target_class(user_field_without_validation_2),
      )

      # Update grandparent and parent to show the nested child again
      page
        .find(custom_validation_page.target_class(user_field_with_validation_2))
        .fill_in(with: "")
        .send_keys("show_validation")
      page
        .find(custom_validation_page.target_class(user_field_with_validation_3))
        .fill_in(with: "")
        .send_keys("show_validation")

      expect(page).to have_css(custom_validation_page.target_class(user_field_without_validation_2))
      # Check that the nested child is cleared
      expect(
        page.find(custom_validation_page.target_class(user_field_without_validation_2)),
      ).to have_text("")
    end
  end

  context "when advanced visibility rules are configured" do
    it "shows different target fields based on different text rule matches" do
      page.find(custom_validation_page.target_class(user_field_with_advanced_rules)).fill_in(
        with: "foo content",
      )

      expect(page).to have_css(custom_validation_page.target_class(user_field_visible_for_contains))
      expect(page).to have_no_css(
        custom_validation_page.target_class(user_field_visible_for_exact_match),
      )

      page.find(custom_validation_page.target_class(user_field_with_advanced_rules)).fill_in(with: "bar")

      expect(page).to have_no_css(custom_validation_page.target_class(user_field_visible_for_contains))
      expect(page).to have_css(
        custom_validation_page.target_class(user_field_visible_for_exact_match),
      )
    end
  end

end
