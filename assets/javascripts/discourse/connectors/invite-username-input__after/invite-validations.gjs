import Component from "@glimmer/component";
import { hash } from "@ember/helper";
import { getOwner } from "@ember/owner";
import { service } from "@ember/service";
import setupUserFieldValidation from "../../helpers/setup-user-field-validation";

export default class InviteValidations extends Component {
  @service userFieldValidations;

  get userFields() {
    const controller = getOwner(this).lookup("controller:invites/show");
    return controller?.userFields || [];
  }

  constructor() {
    super(...arguments);

    this.userFieldValidations.totalCustomValidationFields =
      this.userFields.filter(
        (f) => f.field.has_custom_validation
      ).length;
  }

  <template>
    {{#each this.userFields as |field|}}
      {{#if field.field.has_custom_validation}}
        {{setupUserFieldValidation (hash field=field.field value=field.value)}}
      {{/if}}
    {{/each}}
  </template>
}
