import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { Input } from "@ember/component";
import { service } from "@ember/service";
import { withPluginApi } from "discourse/lib/plugin-api";
import { i18n } from "discourse-i18n";
import AdminFormRow from "admin/components/admin-form-row";
import ValueList from "admin/components/value-list";
import MultiSelect from "select-kit/components/multi-select";

export default class CustomUserFields extends Component {
  @service site;

  @tracked userFieldsMinusCurrent = this.site.user_fields.filter(
    (userField) => userField.id !== this.args.outletArgs.userField.id
  );

  constructor() {
    super(...arguments);
    withPluginApi((api) => {
      [
        "has_custom_validation",
        "show_values",
        "target_user_field_ids",
        "value_validation_regex",
      ].forEach((property) => api.includeUserFieldPropertyOnSave(property));
    });
  }

  <template>
    <AdminFormRow @wrapLabel="true" @type="checkbox">
      <Input
        @type="checkbox"
        @checked={{@outletArgs.userField.has_custom_validation}}
        class="has-custom-validation-checkbox"
      />
      <span>
        {{i18n "discourse_authentication_validations.has_custom_validation"}}
      </span>
    </AdminFormRow>

    {{#if @outletArgs.userField.has_custom_validation}}
      <@outletArgs.form.Field
        @name="value_validation_regex"
        @title={{i18n
          "discourse_authentication_validations.value_validation_regex.label"
        }}
        @format="large"
        as |field|
      >
        <field.Input />
      </@outletArgs.form.Field>

      <@outletArgs.form.Field
        @name="show_values"
        @title={{i18n "discourse_authentication_validations.show_values.label"}}
        @description={{i18n
          "discourse_authentication_validations.show_values.description"
        }}
        @format="large"
        as |field|
      >
        <field.Custom>
          <ValueList
            @values={{@outletArgs.userField.show_values}}
            @inputType="array"
            @onChange={{field.set}}
          />
        </field.Custom>
      </@outletArgs.form.Field>

      <@outletArgs.form.Field
        @name="target_user_field_ids"
        @title={{i18n
          "discourse_authentication_validations.target_user_field_ids.label"
        }}
        @format="large"
        as |field|
      >
        <field.Custom>
          <MultiSelect
            @id={{field.id}}
            @onChange={{field.set}}
            @value={{field.value}}
            @content={{this.userFieldsMinusCurrent}}
            class="target-user-field-ids-input"
          />
        </field.Custom>
      </@outletArgs.form.Field>
    {{/if}}
  </template>
}
