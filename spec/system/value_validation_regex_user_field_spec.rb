# frozen_string_literal: true

RSpec.describe "Discourse Authentication Validation - Value Validation Regex - User Field" do
  let(:signup_page) { PageObjects::Pages::Signup.new }
  fab!(:user_field_with_value_validation_regex) do
    Fabricate(
      :user_field,
      name: "phone number",
      field_type: "text",
      editable: true,
      required: true,
      has_custom_validation: true,
      show_values: [],
      target_user_field_ids: [],
      value_validation_regex: "^\\d{2} \\d{4} \\d{4}$", # 00 0000 0000
    )
  end

  fab!(:user_field_without_value_validation_regex) do
    Fabricate(
      :user_field,
      name: "unvalidated phone number",
      field_type: "text",
      editable: true,
      required: true,
      has_custom_validation: true,
      show_values: [],
      target_user_field_ids: [],
      value_validation_regex: nil,
    )
  end

  before { SiteSetting.discourse_authentication_validations_enabled = true }

  context "when a user field has a value_validation_regex" do
    it "displays a validation error message when the target user field input is incorrect" do
      signup_page.open
      signup_page.fill_custom_field("phone-number", "NAN")
      signup_page.click_create_account

      expect(signup_page).to have_text(
        I18n.t(
          "js.discourse_authentication_validations.value_validation_error_message",
          { user_field_name: user_field_with_value_validation_regex.name },
        ),
      )
    end

    it "displays the default error message for no value" do
      signup_page.open
      signup_page.click_create_account

      expect(signup_page).not_to have_text(
        I18n.t(
          "js.discourse_authentication_validations.value_validation_error_message",
          { user_field_name: user_field_with_value_validation_regex.name },
        ),
      )
      expect(signup_page).to have_text(
        I18n.t("js.user_fields.required", { name: user_field_with_value_validation_regex.name }),
      )
    end

    it "clears the validation error message when the target user field input is correct" do
      signup_page.open
      signup_page.fill_custom_field("phone-number", "not a phone number")
      signup_page.click_create_account

      signup_page.fill_custom_field("phone-number", "11 2222 3333")
      signup_page.click_create_account

      expect(signup_page).not_to have_text(
        I18n.t(
          "js.discourse_authentication_validations.value_validation_error_message",
          { user_field_name: user_field_with_value_validation_regex.name },
        ),
      )
    end
  end

  context "when a user field does not have a value_validation_regex" do
    it "does not display a validation error message" do
      signup_page.open
      signup_page.fill_custom_field("unvalidated-phone-number", "not a phone number")
      signup_page.click_create_account

      expect(signup_page).not_to have_text(
        I18n.t(
          "js.discourse_authentication_validations.value_validation_error_message",
          { user_field_name: user_field_without_value_validation_regex.name },
        ),
      )
    end
  end

  context "when a user field has a value_validation_regex and has_custom_validation is false" do
    it "does not display a validation error message" do
      user_field_with_value_validation_regex.update!(has_custom_validation: false)
      signup_page.open
      signup_page.fill_custom_field("phone-number", "not a phone number")
      signup_page.click_create_account

      expect(signup_page).not_to have_text(
        I18n.t(
          "js.discourse_authentication_validations.value_validation_error_message",
          { user_field_name: user_field_with_value_validation_regex.name },
        ),
      )
    end
  end
end
