import Component from "@glimmer/component";
import { Input } from "@ember/component";
import { action } from "@ember/object";
import { tracked } from "@glimmer/tracking";
import { service } from "@ember/service";
import AdminFormRow from "discourse/admin/components/admin-form-row";
import ValueList from "discourse/admin/components/value-list";
import { withPluginApi } from "discourse/lib/plugin-api";
import MultiSelect from "discourse/select-kit/components/multi-select";
import { i18n } from "discourse-i18n";

const RULE_TYPES = ["text", "option", "number", "date"];

export default class CustomUserFields extends Component {
  @service site;
  @tracked localRules = [];

  constructor() {
    super(...arguments);
    withPluginApi((api) => {
      [
        "has_custom_validation",
        "show_values",
        "target_user_field_ids",
        "value_validation_regex",
        "visibility_rules",
      ].forEach((property) => api.includeUserFieldPropertyOnSave(property));
    });

    this.localRules = this._normalizeRules(
      this.args.outletArgs.userField.visibility_rules
    );
  }

  get userFieldsMinusCurrent() {
    return this.site.user_fields.filter(
      (userField) => userField.id !== this.args.outletArgs.userField.id
    );
  }

  get ruleTypes() {
    return RULE_TYPES;
  }

  @action
  addRule(field) {
    this.localRules = [
      ...this.localRules,
      {
        rule_type: "option",
        operator: "equals",
        values: [],
        target_user_field_ids: [],
      },
    ];

    field.set(this.localRules);
  }

  @action
  removeRule(index, field) {
    this.localRules = this.localRules.filter((_, ruleIndex) => ruleIndex !== index);
    field.set(this.localRules);
  }

  @action
  onRuleTypeChange(index, field, event) {
    this.updateRule(index, { rule_type: event.target.value, operator: "equals", values: [] }, field);
  }

  @action
  onRuleOperatorChange(index, field, event) {
    this.updateRule(index, { operator: event.target.value }, field);
  }

  @action
  onRuleValuesChange(index, field, values) {
    this.updateRule(index, { values }, field);
  }

  @action
  onRuleTargetsChange(index, field, target_user_field_ids) {
    this.updateRule(index, { target_user_field_ids }, field);
  }

  updateRule(index, changes, field) {
    this.localRules = this.localRules.map((rule, ruleIndex) =>
      ruleIndex === index ? { ...rule, ...changes } : rule
    );

    field.set(this.localRules);
  }

  operatorOptionsFor(ruleType) {
    switch (ruleType) {
      case "text":
        return [
          "equals",
          "not_equals",
          "contains",
          "starts_with",
          "ends_with",
          "regex",
          "blank",
          "present",
        ];
      case "number":
      case "date":
        return [
          "equals",
          "not_equals",
          "gt",
          "gte",
          "lt",
          "lte",
          "between",
        ];
      default:
        return [
          "equals",
          "not_equals",
          "includes_any",
          "excludes_all",
          "blank",
          "present",
        ];
    }
  }

  _normalizeRules(rules) {
    if (!Array.isArray(rules)) {
      return [];
    }

    return rules
      .filter((rule) => rule && typeof rule === "object")
      .map((rule) => ({
        rule_type: rule.rule_type || "option",
        operator: rule.operator || "equals",
        values: Array.isArray(rule.values) ? rule.values : [],
        target_user_field_ids: Array.isArray(rule.target_user_field_ids)
          ? rule.target_user_field_ids
          : [],
      }));
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

      <@outletArgs.form.Field
        @name="visibility_rules"
        @title={{i18n "discourse_authentication_validations.visibility_rules.label"}}
        @description={{i18n
          "discourse_authentication_validations.visibility_rules.description"
        }}
        @format="large"
        as |field|
      >
        <field.Custom>
          <div class="visibility-rules">
            {{#each this.localRules as |rule index|}}
              <div class="visibility-rules__rule">
                <div class="visibility-rules__row">
                  <label>{{i18n "discourse_authentication_validations.visibility_rules.rule_type"}}</label>
                  <select
                    value={{rule.rule_type}}
                    {{on "change" (fn this.onRuleTypeChange index field)}}
                  >
                    {{#each this.ruleTypes as |ruleType|}}
                      <option value={{ruleType}} selected={{eq ruleType rule.rule_type}}>
                        {{i18n (concat "discourse_authentication_validations.visibility_rules.rule_type_options." ruleType)}}
                      </option>
                    {{/each}}
                  </select>
                </div>

                <div class="visibility-rules__row">
                  <label>{{i18n "discourse_authentication_validations.visibility_rules.operator"}}</label>
                  <select
                    value={{rule.operator}}
                    {{on "change" (fn this.onRuleOperatorChange index field)}}
                  >
                    {{#each (this.operatorOptionsFor rule.rule_type) as |operator|}}
                      <option value={{operator}} selected={{eq operator rule.operator}}>
                        {{i18n (concat "discourse_authentication_validations.visibility_rules.operators." operator)}}
                      </option>
                    {{/each}}
                  </select>
                </div>

                <div class="visibility-rules__row">
                  <label>{{i18n "discourse_authentication_validations.visibility_rules.values"}}</label>
                  <ValueList
                    @values={{rule.values}}
                    @inputType="array"
                    @onChange={{fn this.onRuleValuesChange index field}}
                  />
                </div>

                <div class="visibility-rules__row">
                  <label>{{i18n "discourse_authentication_validations.visibility_rules.visible_fields"}}</label>
                  <MultiSelect
                    @onChange={{fn this.onRuleTargetsChange index field}}
                    @value={{rule.target_user_field_ids}}
                    @content={{this.userFieldsMinusCurrent}}
                  />
                </div>

                <DButton
                  @icon="trash-can"
                  @label="discourse_authentication_validations.visibility_rules.remove"
                  @action={{fn this.removeRule index field}}
                  class="btn-danger"
                />
              </div>
            {{/each}}

            <DButton
              @icon="plus"
              @label="discourse_authentication_validations.visibility_rules.add"
              @action={{fn this.addRule field}}
            />
          </div>
        </field.Custom>
      </@outletArgs.form.Field>
    {{/if}}
  </template>
}
