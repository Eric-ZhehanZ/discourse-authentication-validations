export function customValidationFields(userFields = []) {
  return userFields.filter((userField) => {
    const field = userField?.field || userField;

    return Boolean(
      field?.has_custom_validation ?? field?.hasCustomValidation
    );
  });
}
