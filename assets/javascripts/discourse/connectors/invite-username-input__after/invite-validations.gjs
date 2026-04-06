import Component from "@glimmer/component";
import { hash } from "@ember/helper";
import { getOwner } from "@ember/owner";
import { service } from "@ember/service";
import setupUserFieldValidation from "../../helpers/setup-user-field-validation";
import { customValidationFields } from "../../lib/user-field-validation-fields";

export default class InviteValidations extends Component {
  @service userFieldValidations;

  get userFields() {
    const controller = getOwner(this).lookup("controller:invites/show");
    return customValidationFields(controller?.userFields || []);
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
