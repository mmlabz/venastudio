// ignore_for_file: non_constant_identifier_names, constant_identifier_names

const EMPLOYEE_TYPE_NAME = 'Employee';
const SUPERADMIN_TYPE_NAME = 'SuperAdmin';
const FRONTOFFICE_TYPE_NAME = 'FrontOffice';
const USER_TYPE_NAME = 'user';

String normalizeUserType(String? value) {
  final type = (value ?? '').trim();

  if (type.toLowerCase() == USER_TYPE_NAME.toLowerCase()) {
    return EMPLOYEE_TYPE_NAME;
  }

  return type;
}

bool isSuperAdminType(String? value) {
  return normalizeUserType(value).toLowerCase() ==
      SUPERADMIN_TYPE_NAME.toLowerCase();
}

bool isFrontOfficeType(String? value) {
  return normalizeUserType(value).toLowerCase() ==
      FRONTOFFICE_TYPE_NAME.toLowerCase();
}

bool isEmployeeType(String? value) {
  return normalizeUserType(value).toLowerCase() ==
      EMPLOYEE_TYPE_NAME.toLowerCase();
}

bool isAdminOrFrontOfficeType(String? value) {
  return isSuperAdminType(value) || isFrontOfficeType(value);
}

bool isOperationalUserType(String? value) {
  return isSuperAdminType(value) ||
      isFrontOfficeType(value) ||
      isEmployeeType(value);
}
