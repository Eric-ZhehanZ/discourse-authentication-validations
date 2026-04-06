export function customValidationFields(userFields = []) {
  return userFields.filter((userField) => userField?.field?.has_custom_validation);
}
