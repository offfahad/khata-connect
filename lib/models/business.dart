class Business {
  int? id;
  String? name;
  String? phone;
  String? email;
  String? address;
  String? logo;
  String? website;
  String? role;
  String? companyName;

  Business(
      {this.id,
      this.name,
      this.phone,
      this.address,
      this.logo,
      this.email,
      this.website,
      this.role,
      this.companyName});

  factory Business.fromDatabaseJson(Map<String, dynamic> data) => Business(
        id: data['id'],
        name: data['name'],
        phone: data['phone'],
        address: data['address'],
        logo: data['logo'],
        email: data['email'],
        website: data['website'],
        role: data['role'],
        companyName: data['companyName'],
      );

  Map<String, dynamic> toDatabaseJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'address': address,
        'logo': logo,
        'email': email,
        'website': website,
        'role': role,
        'companyName': companyName
      };
}
