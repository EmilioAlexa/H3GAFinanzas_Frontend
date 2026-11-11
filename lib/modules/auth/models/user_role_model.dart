enum UserRole { administrador, administradorFinanciero, asesor }

extension UserRoleName on UserRole {
  String get apiName => switch (this) {
        UserRole.administrador => 'administrador',
        UserRole.administradorFinanciero => 'administrador financiero',
        UserRole.asesor => 'asesor',
      };

  static UserRole? parse(String? value) =>
      switch (value?.toLowerCase().trim()) {
        'administrador' => UserRole.administrador,
        'administrador financiero' => UserRole.administradorFinanciero,
        'asesor' => UserRole.asesor,
        _ => null,
      };
}
