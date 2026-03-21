class Employee {
  final int? id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String? address;
  final DateTime? birthDate;
  final String? gender;
  final String? maritalStatus;
  final String? nationality;
  final String? idNumber;
  final String? socialSecurityNumber;
  final String? position;
  final String? department;
  final String? manager;
  final DateTime? hireDate;
  final DateTime? contractStartDate;
  final DateTime? contractEndDate;
  final String? contractType;
  final double? salary;
  final String? currency;
  final String? workSchedule;
  final String? status; // active, inactive, terminated, on_leave
  final String? profilePicture;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<EmployeeDocument>? documents;
  final List<EmployeeLeave>? leaves;
  final List<EmployeePerformance>? performances;

  const Employee({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    this.address,
    this.birthDate,
    this.gender,
    this.maritalStatus,
    this.nationality,
    this.idNumber,
    this.socialSecurityNumber,
    this.position,
    this.department,
    this.manager,
    this.hireDate,
    this.contractStartDate,
    this.contractEndDate,
    this.contractType,
    this.salary,
    this.currency,
    this.workSchedule,
    this.status = 'active',
    this.profilePicture,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.documents,
    this.leaves,
    this.performances,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'],
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      address: json['address'],
      birthDate:
          json['birth_date'] != null
              ? DateTime.parse(json['birth_date'])
              : null,
      gender: json['gender'],
      maritalStatus: json['marital_status'],
      nationality: json['nationality'],
      idNumber: json['id_number'],
      socialSecurityNumber: json['social_security_number'],
      position: json['position'],
      department: json['department'],
      manager: json['manager'],
      hireDate:
          json['hire_date'] != null ? DateTime.parse(json['hire_date']) : null,
      contractStartDate:
          json['contract_start_date'] != null
              ? DateTime.parse(json['contract_start_date'])
              : null,
      contractEndDate:
          json['contract_end_date'] != null
              ? DateTime.parse(json['contract_end_date'])
              : null,
      contractType: json['contract_type'],
      salary:
          json['salary'] != null
              ? (json['salary'] is String
                  ? double.tryParse(json['salary'] as String)
                  : (json['salary'] as num).toDouble())
              : null,
      currency: json['currency'],
      workSchedule: json['work_schedule'],
      status: json['status'] ?? 'active',
      profilePicture: json['profile_picture'],
      notes: json['notes'],
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updated_at'] ?? DateTime.now().toIso8601String(),
      ),
      documents:
          json['documents'] != null
              ? (json['documents'] as List)
                  .map((d) => EmployeeDocument.fromJson(d))
                  .toList()
              : null,
      leaves:
          json['leaves'] != null
              ? (json['leaves'] as List)
                  .map((l) => EmployeeLeave.fromJson(l))
                  .toList()
              : null,
      performances:
          json['performances'] != null
              ? (json['performances'] as List)
                  .map((p) => EmployeePerformance.fromJson(p))
                  .toList()
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'address': address,
      'birth_date': birthDate?.toIso8601String(),
      'gender': gender,
      'marital_status': maritalStatus,
      'nationality': nationality,
      'id_number': idNumber,
      'social_security_number': socialSecurityNumber,
      'position': position,
      'department': department,
      'manager': manager,
      'hire_date': hireDate?.toIso8601String(),
      'contract_start_date': contractStartDate?.toIso8601String(),
      'contract_end_date': contractEndDate?.toIso8601String(),
      'contract_type': contractType,
      'salary': salary,
      'currency': currency,
      'work_schedule': workSchedule,
      'status': status,
      'profile_picture': profilePicture,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'documents': documents?.map((d) => d.toJson()).toList(),
      'leaves': leaves?.map((l) => l.toJson()).toList(),
      'performances': performances?.map((p) => p.toJson()).toList(),
    };
  }

  // Propriétés calculées
  String get fullName => '$firstName $lastName';
  String get initials => '${firstName[0]}${lastName[0]}'.toUpperCase();

  int? get age {
    if (birthDate == null) return null;
    final now = DateTime.now();
    return now.year -
        birthDate!.year -
        (now.month < birthDate!.month ||
                (now.month == birthDate!.month && now.day < birthDate!.day)
            ? 1
            : 0);
  }

  String get statusText {
    switch (status) {
      case 'active':
        return 'Actif';
      case 'inactive':
        return 'Inactif';
      case 'terminated':
        return 'Terminé';
      case 'on_leave':
        return 'En congé';
      default:
        return status ?? 'Inconnu';
    }
  }

  String get statusColor {
    switch (status) {
      case 'active':
        return 'green';
      case 'inactive':
        return 'orange';
      case 'terminated':
        return 'red';
      case 'on_leave':
        return 'blue';
      default:
        return 'grey';
    }
  }

  String get statusIcon {
    switch (status) {
      case 'active':
        return 'check_circle';
      case 'inactive':
        return 'pause_circle';
      case 'terminated':
        return 'cancel';
      case 'on_leave':
        return 'event';
      default:
        return 'help';
    }
  }

  String get formattedSalary {
    if (salary == null) return 'Non défini';
    return '${salary!.toStringAsFixed(0)} ${currency ?? 'fcfa'}';
  }

  bool get isContractExpiring {
    if (contractEndDate == null) return false;
    final now = DateTime.now();
    final daysUntilExpiry = contractEndDate!.difference(now).inDays;
    return daysUntilExpiry <= 30 && daysUntilExpiry >= 0;
  }

  bool get isContractExpired {
    if (contractEndDate == null) return false;
    return DateTime.now().isAfter(contractEndDate!);
  }
}

class EmployeeDocument {
  final int? id;
  final int employeeId;
  final String name;
  final String type;
  final String? description;
  final String? filePath;
  final String? fileSize;
  final DateTime? expiryDate;
  final bool isRequired;
  final DateTime createdAt;
  final String? createdBy;

  const EmployeeDocument({
    this.id,
    required this.employeeId,
    required this.name,
    required this.type,
    this.description,
    this.filePath,
    this.fileSize,
    this.expiryDate,
    this.isRequired = false,
    required this.createdAt,
    this.createdBy,
  });

  factory EmployeeDocument.fromJson(Map<String, dynamic> json) {
    return EmployeeDocument(
      id: json['id'],
      employeeId: json['employee_id'] ?? 0,
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      description: json['description'],
      filePath: json['file_path'],
      fileSize: json['file_size'],
      expiryDate:
          json['expiry_date'] != null
              ? DateTime.parse(json['expiry_date'])
              : null,
      isRequired: json['is_required'] ?? false,
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      createdBy: json['created_by'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employee_id': employeeId,
      'name': name,
      'type': type,
      'description': description,
      'file_path': filePath,
      'file_size': fileSize,
      'expiry_date': expiryDate?.toIso8601String(),
      'is_required': isRequired,
      'created_at': createdAt.toIso8601String(),
      'created_by': createdBy,
    };
  }

  String get typeText {
    switch (type) {
      case 'contract':
        return 'Contrat';
      case 'id_card':
        return 'Carte d\'identité';
      case 'passport':
        return 'Passeport';
      case 'diploma':
        return 'Diplôme';
      case 'certificate':
        return 'Certificat';
      case 'medical':
        return 'Certificat médical';
      case 'other':
        return 'Autre';
      default:
        return type;
    }
  }

  bool get isExpiring {
    if (expiryDate == null) return false;
    final now = DateTime.now();
    final daysUntilExpiry = expiryDate!.difference(now).inDays;
    return daysUntilExpiry <= 30 && daysUntilExpiry >= 0;
  }

  bool get isExpired {
    if (expiryDate == null) return false;
    return DateTime.now().isAfter(expiryDate!);
  }
}

class EmployeeLeave {
  final int? id;
  final int employeeId;
  final String type;
  final DateTime startDate;
  final DateTime endDate;
  final int totalDays;
  final String? reason;
  final String status; // pending, approved, rejected
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? rejectionReason;
  final DateTime createdAt;
  final String? createdBy;

  const EmployeeLeave({
    this.id,
    required this.employeeId,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    this.reason,
    this.status = 'pending',
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
    required this.createdAt,
    this.createdBy,
  });

  factory EmployeeLeave.fromJson(Map<String, dynamic> json) {
    return EmployeeLeave(
      id: json['id'],
      employeeId: json['employee_id'] ?? 0,
      type: json['type'] ?? '',
      startDate: DateTime.parse(
        json['start_date'] ?? DateTime.now().toIso8601String(),
      ),
      endDate: DateTime.parse(
        json['end_date'] ?? DateTime.now().toIso8601String(),
      ),
      totalDays: json['total_days'] ?? 0,
      reason: json['reason'],
      status: json['status'] ?? 'pending',
      approvedBy: json['approved_by'],
      approvedAt:
          json['approved_at'] != null
              ? DateTime.parse(json['approved_at'])
              : null,
      rejectionReason: json['rejection_reason'],
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      createdBy: json['created_by'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employee_id': employeeId,
      'type': type,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'total_days': totalDays,
      'reason': reason,
      'status': status,
      'approved_by': approvedBy,
      'approved_at': approvedAt?.toIso8601String(),
      'rejection_reason': rejectionReason,
      'created_at': createdAt.toIso8601String(),
      'created_by': createdBy,
    };
  }

  String get typeText {
    switch (type) {
      case 'annual':
        return 'Congé annuel';
      case 'sick':
        return 'Congé maladie';
      case 'maternity':
        return 'Congé maternité';
      case 'paternity':
        return 'Congé paternité';
      case 'personal':
        return 'Congé personnel';
      case 'unpaid':
        return 'Congé sans solde';
      default:
        return type;
    }
  }

  String get statusText {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'approved':
        return 'Approuvé';
      case 'rejected':
        return 'Rejeté';
      default:
        return status;
    }
  }

  String get statusColor {
    switch (status) {
      case 'pending':
        return 'orange';
      case 'approved':
        return 'green';
      case 'rejected':
        return 'red';
      default:
        return 'grey';
    }
  }
}

class EmployeePerformance {
  final int? id;
  final int employeeId;
  final String period;
  final double rating;
  final String? comments;
  final String? goals;
  final String? achievements;
  final String? areasForImprovement;
  final String status; // draft, submitted, reviewed, approved
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime createdAt;
  final String? createdBy;

  const EmployeePerformance({
    this.id,
    required this.employeeId,
    required this.period,
    required this.rating,
    this.comments,
    this.goals,
    this.achievements,
    this.areasForImprovement,
    this.status = 'draft',
    this.reviewedBy,
    this.reviewedAt,
    required this.createdAt,
    this.createdBy,
  });

  factory EmployeePerformance.fromJson(Map<String, dynamic> json) {
    return EmployeePerformance(
      id: json['id'],
      employeeId: json['employee_id'] ?? 0,
      period: json['period'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      comments: json['comments'],
      goals: json['goals'],
      achievements: json['achievements'],
      areasForImprovement: json['areas_for_improvement'],
      status: json['status'] ?? 'draft',
      reviewedBy: json['reviewed_by'],
      reviewedAt:
          json['reviewed_at'] != null
              ? DateTime.parse(json['reviewed_at'])
              : null,
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      createdBy: json['created_by'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employee_id': employeeId,
      'period': period,
      'rating': rating,
      'comments': comments,
      'goals': goals,
      'achievements': achievements,
      'areas_for_improvement': areasForImprovement,
      'status': status,
      'reviewed_by': reviewedBy,
      'reviewed_at': reviewedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'created_by': createdBy,
    };
  }

  String get statusText {
    switch (status) {
      case 'draft':
        return 'Brouillon';
      case 'submitted':
        return 'Soumis';
      case 'reviewed':
        return 'Évalué';
      case 'approved':
        return 'Approuvé';
      default:
        return status;
    }
  }

  String get statusColor {
    switch (status) {
      case 'draft':
        return 'grey';
      case 'submitted':
        return 'orange';
      case 'reviewed':
        return 'blue';
      case 'approved':
        return 'green';
      default:
        return 'grey';
    }
  }
}

class EmployeeStats {
  final int totalEmployees;
  final int activeEmployees;
  final int inactiveEmployees;
  final int onLeaveEmployees;
  final int terminatedEmployees;
  final int newHiresThisMonth;
  final int departuresThisMonth;
  final double averageSalary;
  final List<String> departments;
  final List<String> positions;
  final int expiringContracts;
  final int expiringDocuments;

  const EmployeeStats({
    required this.totalEmployees,
    required this.activeEmployees,
    required this.inactiveEmployees,
    required this.onLeaveEmployees,
    required this.terminatedEmployees,
    required this.newHiresThisMonth,
    required this.departuresThisMonth,
    required this.averageSalary,
    required this.departments,
    required this.positions,
    required this.expiringContracts,
    required this.expiringDocuments,
  });

  factory EmployeeStats.fromJson(Map<String, dynamic> json) {
    return EmployeeStats(
      totalEmployees: json['total_employees'] ?? 0,
      activeEmployees: json['active_employees'] ?? 0,
      inactiveEmployees: json['inactive_employees'] ?? 0,
      onLeaveEmployees: json['on_leave_employees'] ?? 0,
      terminatedEmployees: json['terminated_employees'] ?? 0,
      newHiresThisMonth: json['new_hires_this_month'] ?? 0,
      departuresThisMonth: json['departures_this_month'] ?? 0,
      averageSalary: (json['average_salary'] ?? 0).toDouble(),
      departments:
          json['departments'] != null
              ? List<String>.from(json['departments'])
              : [],
      positions:
          json['positions'] != null ? List<String>.from(json['positions']) : [],
      expiringContracts: json['expiring_contracts'] ?? 0,
      expiringDocuments: json['expiring_documents'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_employees': totalEmployees,
      'active_employees': activeEmployees,
      'inactive_employees': inactiveEmployees,
      'on_leave_employees': onLeaveEmployees,
      'terminated_employees': terminatedEmployees,
      'new_hires_this_month': newHiresThisMonth,
      'departures_this_month': departuresThisMonth,
      'average_salary': averageSalary,
      'departments': departments,
      'positions': positions,
      'expiring_contracts': expiringContracts,
      'expiring_documents': expiringDocuments,
    };
  }
}
