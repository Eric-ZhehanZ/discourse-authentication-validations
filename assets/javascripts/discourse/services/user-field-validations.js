import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { next } from "@ember/runloop";
import Service, { service } from "@ember/service";

export default class UserFieldValidations extends Service {
  @service site;

  @tracked totalCustomValidationFields = 0;
  currentCustomValidationFieldCount = 0;

  @action
  setupCustomValidationFields(userFields) {
    this.totalCustomValidationFields = userFields.length;
    this.currentCustomValidationFieldCount = 0;
  }

  @action
  setValidation(userField, value) {
    this._bumpTotalCustomValidationFields();

    if (
      this.currentCustomValidationFieldCount ===
      this.totalCustomValidationFields
    ) {
      next(() => {
        const targetVisibilityMap = this._targetVisibilityMap(userField, value);

        this._updateTargets(targetVisibilityMap);
        this.hideNestedCustomValidations(targetVisibilityMap);
      });
    }
  }

  @action
  hideNestedCustomValidations(targetVisibilityMap) {
    const hiddenTargetIds = Object.entries(targetVisibilityMap)
      .filter(([, visible]) => !visible)
      .map(([id]) => Number(id));

    if (!hiddenTargetIds.length) {
      return;
    }

    const nestedTargetIds = this._collectDescendantTargetIds(hiddenTargetIds);
    const nestedUserFields = this.site.user_fields.filter((field) =>
      nestedTargetIds.includes(field.id)
    );

    nestedUserFields.forEach((field) => this._clearUserField(field));
    this._updateTargets(
      Object.fromEntries(nestedUserFields.map((field) => [field.id, false]))
    );
  }

  _collectDescendantTargetIds(startFieldIds) {
    const visited = new Set();
    const queue = [...startFieldIds];
    const descendants = new Set();

    while (queue.length) {
      const currentId = queue.shift();

      if (visited.has(currentId)) {
        continue;
      }

      visited.add(currentId);
      const field = this.site.user_fields.find((item) => item.id === currentId);

      if (!field) {
        continue;
      }

      this._allTargetIdsForField(field).forEach((targetId) => {
        descendants.add(targetId);

        if (!visited.has(targetId)) {
          queue.push(targetId);
        }
      });
    }

    return [...descendants];
  }

  _allTargetIdsForField(userField) {
    const legacyTargetIds = userField.target_user_field_ids || [];
    const ruleTargetIds = (userField.visibility_rules || []).flatMap(
      (rule) => rule.target_user_field_ids || []
    );

    return [...new Set([...legacyTargetIds, ...ruleTargetIds])];
  }

  _targetVisibilityMap(userField, value) {
    const visibilityRules = userField.visibility_rules || [];

    if (visibilityRules.length) {
      return this._targetVisibilityMapFromRules(visibilityRules, value);
    }

    const shouldShow = this._legacyShouldShow(userField, value);
    return Object.fromEntries(
      userField.target_user_field_ids.map((id) => [id, shouldShow])
    );
  }

  _targetVisibilityMapFromRules(rules, value) {
    const targets = Object.fromEntries(
      rules.flatMap((rule) =>
        (rule.target_user_field_ids || []).map((id) => [id, false])
      )
    );

    rules.forEach((rule) => {
      const shouldShow = this._ruleMatches(rule, value);

      (rule.target_user_field_ids || []).forEach((id) => {
        if (shouldShow) {
          targets[id] = true;
        }
      });
    });

    return targets;
  }

  _updateTargets(targetVisibilityMap) {
    Object.entries(targetVisibilityMap).forEach(([id, shouldShow]) => {
      const userField = this.site.user_fields.find((field) => field.id === Number(id));

      if (!userField) {
        return;
      }

      const className = `user-field-${userField.name
        .toLowerCase()
        .replace(/\s+/g, "-")}`;
      const userFieldElement = document.querySelector(`.${className}`);

      if (!userFieldElement) {
        return;
      }

      if (!shouldShow) {
        userFieldElement.style.display = "none";
        this._clearUserField(userField);
      } else {
        userFieldElement.style.display = "";
      }
    });
  }

  _ruleMatches(rule, value) {
    const operator = rule.operator || "equals";
    const values = (rule.values || []).map((item) => item?.toString() || "");

    switch (rule.rule_type) {
      case "text":
        return this._textMatch(operator, value?.toString() || "", values);
      case "number":
        return this._numberMatch(operator, value, values);
      case "date":
        return this._dateMatch(operator, value, values);
      default:
        return this._optionMatch(operator, value, values);
    }
  }

  _optionMatch(operator, value, values) {
    if (operator === "blank") {
      return this._isBlankValue(value);
    }

    if (operator === "present") {
      return this._isPresentValue(value);
    }

    const normalizedValues = Array.isArray(value)
      ? value.map((item) => item?.toString())
      : [value?.toString()];

    switch (operator) {
      case "includes_any":
      case "equals":
        return normalizedValues.some((item) => values.includes(item));
      case "excludes_all":
      case "not_equals":
        return normalizedValues.every((item) => !values.includes(item));
      default:
        return false;
    }
  }

  _textMatch(operator, value, values) {
    const firstValue = values[0] || "";

    switch (operator) {
      case "blank":
        return !value;
      case "present":
        return !!value;
      case "contains":
        return value.includes(firstValue);
      case "starts_with":
        return value.startsWith(firstValue);
      case "ends_with":
        return value.endsWith(firstValue);
      case "regex":
        if (!firstValue) {
          return false;
        }

        try {
          return new RegExp(firstValue).test(value);
        } catch {
          return false;
        }
      case "not_equals":
        return !values.includes(value);
      case "equals":
      default:
        return values.includes(value);
    }
  }

  _numberMatch(operator, value, values) {
    if (operator === "blank") {
      return this._isBlankValue(value);
    }

    if (operator === "present") {
      return this._isPresentValue(value);
    }

    const numericValue = Number(value);

    if (Number.isNaN(numericValue)) {
      return false;
    }

    const [left, right] = values.map((item) => Number(item));
    const hasValidLeft = !Number.isNaN(left);
    const hasValidRight = !Number.isNaN(right);

    switch (operator) {
      case "not_equals":
        if (!hasValidLeft) {
          return false;
        }
        return numericValue !== left;
      case "gt":
        if (!hasValidLeft) {
          return false;
        }
        return numericValue > left;
      case "gte":
        if (!hasValidLeft) {
          return false;
        }
        return numericValue >= left;
      case "lt":
        if (!hasValidLeft) {
          return false;
        }
        return numericValue < left;
      case "lte":
        if (!hasValidLeft) {
          return false;
        }
        return numericValue <= left;
      case "between":
        return hasValidLeft && hasValidRight && numericValue >= left && numericValue <= right;
      case "equals":
      default:
        if (!hasValidLeft) {
          return false;
        }
        return numericValue === left;
    }
  }

  _dateMatch(operator, value, values) {
    if (operator === "blank") {
      return this._isBlankValue(value);
    }

    if (operator === "present") {
      return this._isPresentValue(value);
    }

    const currentDate = new Date(value);

    if (Number.isNaN(currentDate.getTime())) {
      return false;
    }

    const [left, right] = values.map((item) => new Date(item));
    const leftTime = left?.getTime();
    const rightTime = right?.getTime();
    const currentTime = currentDate.getTime();
    const hasValidLeft = !Number.isNaN(leftTime);
    const hasValidRight = !Number.isNaN(rightTime);

    switch (operator) {
      case "not_equals":
        if (!hasValidLeft) {
          return false;
        }
        return currentTime !== leftTime;
      case "gt":
        if (!hasValidLeft) {
          return false;
        }
        return currentTime > leftTime;
      case "gte":
        if (!hasValidLeft) {
          return false;
        }
        return currentTime >= leftTime;
      case "lt":
        if (!hasValidLeft) {
          return false;
        }
        return currentTime < leftTime;
      case "lte":
        if (!hasValidLeft) {
          return false;
        }
        return currentTime <= leftTime;
      case "between":
        return hasValidLeft && hasValidRight && currentTime >= leftTime && currentTime <= rightTime;
      case "equals":
      default:
        if (!hasValidLeft) {
          return false;
        }
        return currentTime === leftTime;
    }
  }

  _isBlankValue(value) {
    if (Array.isArray(value)) {
      return value.length === 0;
    }

    return value === null || value === undefined || value === "";
  }

  _isPresentValue(value) {
    return !this._isBlankValue(value);
  }

  _legacyShouldShow(userField, value) {
    let stringValue = value?.toString();
    let shouldShow = userField.show_values.includes(stringValue);

    if (value === null && userField.show_values.includes("null")) {
      shouldShow = true;
    }

    return shouldShow;
  }

  _clearUserField(userField) {
    switch (userField.field_type) {
      case "confirm":
        userField.element.checked = false;
        break;
      case "dropdown":
        userField.element.selectedIndex = 0;
        break;
      default:
        userField.element.value = "";
        break;
    }
  }

  _bumpTotalCustomValidationFields() {
    if (
      this.totalCustomValidationFields !==
      this.currentCustomValidationFieldCount
    ) {
      this.currentCustomValidationFieldCount += 1;
    }
  }
}
