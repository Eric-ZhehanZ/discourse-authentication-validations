import Component from "@glimmer/component";
import { hash } from "@ember/helper";
import { service } from "@ember/service";
import setupUserFieldValidation from "../../helpers/setup-user-field-validation";
import { customValidationFields } from "../../lib/user-field-validation-fields";

export default class Validations extends Component {
  @service userFieldValidations;

  get userFields() {
    return customValidationFields(this.args.outletArgs.userFields);
  }

  constructor() {
    super(...arguments);

    this.userFieldValidations.setupCustomValidationFields(this.userFields);
  }

  <template>
    {{#each this.userFields as |field|}}
      {{setupUserFieldValidation (hash field=field.field value=field.value)}}
    {{/each}}
  </template>
}
