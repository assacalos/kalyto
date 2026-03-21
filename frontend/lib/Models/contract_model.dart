class Contract {
  final int? id;
  final String contractNumber;
  final int employeeId;
  final String employeeName;
  final String employeeEmail;
  final String
  contractType; // 'permanent', 'fixed_term', 'temporary', 'internship', 'consultant'
  final String position;
  final String department;
  final String jobTitle;
  final String jobDescription;
  final double grossSalary;
  final double netSalary;
  final String salaryCurrency;
  final String paymentFrequency; // 'monthly', 'weekly', 'daily', 'hourly'
  final DateTime startDate;
  final DateTime? endDate;
  final int? durationMonths;
  final String workLocation;
  final String workSchedule; // 'full_time', 'part_time', 'flexible'
  final int weeklyHours;
  final String probationPeriod; // 'none', '1_month', '3_months', '6_months'
  final String? reportingManager;
  final String? employeePhone;
  final String? healthInsurance;
  final String? retirementPlan;
  final int? vacationDays;
  final String? otherBenefits;
  final List<ContractHistory>? history;
  final String
  status; // 'draft', 'pending', 'active', 'expired', 'terminated', 'cancelled'
  final String? terminationReason;
  final DateTime? terminationDate;
  final String? notes;
  final String? contractTemplate;
  final List<ContractClause> clauses;
  final List<ContractAttachment> attachments;
  final DateTime? approvedAt;
  final int? approvedBy;
  final String? approvedByName;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ContractStats? stats;

  Contract({
    this.id,
    required this.contractNumber,
    required this.employeeId,
    required this.employeeName,
    required this.employeeEmail,
    required this.contractType,
    required this.position,
    required this.department,
    required this.jobTitle,
    required this.jobDescription,
    required this.grossSalary,
    required this.netSalary,
    required this.salaryCurrency,
    required this.paymentFrequency,
    required this.startDate,
    this.endDate,
    this.durationMonths,
    required this.workLocation,
    required this.workSchedule,
    required this.weeklyHours,
    required this.probationPeriod,
    this.reportingManager,
    this.employeePhone,
    this.healthInsurance,
    this.retirementPlan,
    this.vacationDays,
    this.otherBenefits,
    this.history,
    required this.status,
    this.terminationReason,
    this.terminationDate,
    this.notes,
    this.contractTemplate,
    this.clauses = const [],
    this.attachments = const [],
    this.approvedAt,
    this.approvedBy,
    this.approvedByName,
    this.rejectionReason,
    required this.createdAt,
    required this.updatedAt,
    this.stats,
  });

  factory Contract.fromJson(Map<String, dynamic> json) {
    return Contract(
      id: json['id'],
      contractNumber: json['contract_number'],
      employeeId: json['employee_id'],
      employeeName: json['employee_name'],
      employeeEmail: json['employee_email'],
      contractType: json['contract_type'],
      position: json['position'],
      department: json['department'],
      jobTitle: json['job_title'],
      jobDescription: json['job_description'],
      grossSalary: json['gross_salary']?.toDouble() ?? 0.0,
      netSalary: json['net_salary']?.toDouble() ?? 0.0,
      salaryCurrency: json['salary_currency'],
      paymentFrequency: json['payment_frequency'],
      startDate: DateTime.parse(json['start_date']),
      endDate:
          json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      durationMonths: json['duration_months'],
      workLocation: json['work_location'],
      workSchedule: json['work_schedule'],
      weeklyHours: json['weekly_hours'],
      probationPeriod: json['probation_period'],
      reportingManager: json['reporting_manager'],
      employeePhone: json['employee_phone'],
      healthInsurance: json['health_insurance'],
      retirementPlan: json['retirement_plan'],
      vacationDays: json['vacation_days'],
      otherBenefits: json['other_benefits'],
      history: (json['history'] as List<dynamic>?)
          ?.map((entry) => ContractHistory.fromJson(entry))
          .toList(),
      status: json['status'],
      terminationReason: json['termination_reason'],
      terminationDate:
          json['termination_date'] != null
              ? DateTime.parse(json['termination_date'])
              : null,
      notes: json['notes'],
      contractTemplate: json['contract_template'],
      clauses:
          (json['clauses'] as List<dynamic>?)
              ?.map((clause) => ContractClause.fromJson(clause))
              .toList() ??
          [],
      attachments:
          (json['attachments'] as List<dynamic>?)
              ?.map((attachment) => ContractAttachment.fromJson(attachment))
              .toList() ??
          [],
      approvedAt:
          json['approved_at'] != null
              ? DateTime.parse(json['approved_at'])
              : null,
      approvedBy: json['approved_by'],
      approvedByName: json['approved_by_name'],
      rejectionReason: json['rejection_reason'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      stats:
          json['stats'] != null ? ContractStats.fromJson(json['stats']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contract_number': contractNumber,
      'employee_id': employeeId,
      'employee_name': employeeName,
      'employee_email': employeeEmail,
      'contract_type': contractType,
      'position': position,
      'department': department,
      'job_title': jobTitle,
      'job_description': jobDescription,
      'gross_salary': grossSalary,
      'net_salary': netSalary,
      'salary_currency': salaryCurrency,
      'payment_frequency': paymentFrequency,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'duration_months': durationMonths,
      'work_location': workLocation,
      'work_schedule': workSchedule,
      'weekly_hours': weeklyHours,
      'probation_period': probationPeriod,
      'reporting_manager': reportingManager,
      'employee_phone': employeePhone,
      'health_insurance': healthInsurance,
      'retirement_plan': retirementPlan,
      'vacation_days': vacationDays,
      'other_benefits': otherBenefits,
      'status': status,
      'termination_reason': terminationReason,
      'termination_date': terminationDate?.toIso8601String(),
      'notes': notes,
      'contract_template': contractTemplate,
      'approved_at': approvedAt?.toIso8601String(),
      'approved_by': approvedBy,
      'rejection_reason': rejectionReason,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Getters pour l'affichage
  String get statusText {
    switch (status) {
      case 'draft':
        return 'Brouillon';
      case 'pending':
        return 'En attente';
      case 'active':
        return 'Actif';
      case 'expired':
        return 'Expiré';
      case 'terminated':
        return 'Résilié';
      case 'cancelled':
        return 'Annulé';
      default:
        return 'Inconnu';
    }
  }

  String get statusColor {
    switch (status) {
      case 'draft':
        return 'grey';
      case 'pending':
        return 'orange';
      case 'active':
        return 'green';
      case 'expired':
        return 'red';
      case 'terminated':
        return 'red';
      case 'cancelled':
        return 'grey';
      default:
        return 'grey';
    }
  }

  String get contractTypeText {
    switch (contractType) {
      case 'permanent':
        return 'CDI';
      case 'fixed_term':
        return 'CDD';
      case 'temporary':
        return 'Intérim';
      case 'internship':
        return 'Stage';
      case 'consultant':
        return 'Consultant';
      default:
        return contractType;
    }
  }

  String get paymentFrequencyText {
    switch (paymentFrequency) {
      case 'monthly':
        return 'Mensuel';
      case 'weekly':
        return 'Hebdomadaire';
      case 'daily':
        return 'Journalier';
      case 'hourly':
        return 'Horaire';
      default:
        return paymentFrequency;
    }
  }

  String get workScheduleText {
    switch (workSchedule) {
      case 'full_time':
        return 'Temps plein';
      case 'part_time':
        return 'Temps partiel';
      case 'flexible':
        return 'Flexible';
      default:
        return workSchedule;
    }
  }

  String get probationPeriodText {
    switch (probationPeriod) {
      case 'none':
        return 'Aucune';
      case '1_month':
        return '1 mois';
      case '3_months':
        return '3 mois';
      case '6_months':
        return '6 mois';
      default:
        return probationPeriod;
    }
  }

  bool get isDraft => status == 'draft';
  bool get isPending => status == 'pending';
  bool get isActive => status == 'active';
  bool get isExpired => status == 'expired';
  bool get isTerminated => status == 'terminated';
  bool get isCancelled => status == 'cancelled';

  bool get canEdit => isDraft;
  bool get canSubmit => isDraft;
  bool get canApprove => isPending;
  bool get canReject => isPending;
  bool get canTerminate => isActive;
  bool get canCancel => isDraft || isPending;

  bool get isExpiringSoon {
    if (endDate == null) return false;
    final daysUntilExpiry = endDate!.difference(DateTime.now()).inDays;
    return daysUntilExpiry <= 30 && daysUntilExpiry > 0;
  }

  bool get hasExpired {
    if (endDate == null) return false;
    return endDate!.isBefore(DateTime.now());
  }
}

class ContractClause {
  final int? id;
  final int contractId;
  final String title;
  final String content;
  final String type; // 'standard', 'custom', 'legal', 'benefit'
  final bool isMandatory;
  final int order;
  final DateTime createdAt;
  final DateTime updatedAt;

  ContractClause({
    this.id,
    required this.contractId,
    required this.title,
    required this.content,
    required this.type,
    required this.isMandatory,
    required this.order,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ContractClause.fromJson(Map<String, dynamic> json) {
    return ContractClause(
      id: json['id'],
      contractId: json['contract_id'],
      title: json['title'],
      content: json['content'],
      type: json['type'],
      isMandatory: json['is_mandatory'] ?? false,
      order: json['order'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contract_id': contractId,
      'title': title,
      'content': content,
      'type': type,
      'is_mandatory': isMandatory,
      'order': order,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class ContractAttachment {
  final int? id;
  final int contractId;
  final String fileName;
  final String filePath;
  final String fileType;
  final int fileSize;
  final String
  attachmentType; // 'contract', 'addendum', 'amendment', 'termination', 'other'
  final String? description;
  final DateTime uploadedAt;
  final int uploadedBy;
  final String uploadedByName;

  ContractAttachment({
    this.id,
    required this.contractId,
    required this.fileName,
    required this.filePath,
    required this.fileType,
    required this.fileSize,
    required this.attachmentType,
    this.description,
    required this.uploadedAt,
    required this.uploadedBy,
    required this.uploadedByName,
  });

  factory ContractAttachment.fromJson(Map<String, dynamic> json) {
    return ContractAttachment(
      id: json['id'],
      contractId: json['contract_id'],
      fileName: json['file_name'],
      filePath: json['file_path'],
      fileType: json['file_type'],
      fileSize: json['file_size'],
      attachmentType: json['attachment_type'],
      description: json['description'],
      uploadedAt: DateTime.parse(json['uploaded_at']),
      uploadedBy: json['uploaded_by'],
      uploadedByName: json['uploaded_by_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contract_id': contractId,
      'file_name': fileName,
      'file_path': filePath,
      'file_type': fileType,
      'file_size': fileSize,
      'attachment_type': attachmentType,
      'description': description,
      'uploaded_at': uploadedAt.toIso8601String(),
      'uploaded_by': uploadedBy,
      'uploaded_by_name': uploadedByName,
    };
  }

  String get attachmentTypeText {
    switch (attachmentType) {
      case 'contract':
        return 'Contrat';
      case 'addendum':
        return 'Avenant';
      case 'amendment':
        return 'Modification';
      case 'termination':
        return 'Résiliation';
      case 'other':
        return 'Autre';
      default:
        return attachmentType;
    }
  }
}

class ContractTemplate {
  final int? id;
  final String name;
  final String description;
  final String contractType;
  final String department;
  final String content;
  final bool isActive;
  final List<ContractClause> defaultClauses;
  final DateTime createdAt;
  final DateTime updatedAt;

  ContractTemplate({
    this.id,
    required this.name,
    required this.description,
    required this.contractType,
    required this.department,
    required this.content,
    required this.isActive,
    this.defaultClauses = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory ContractTemplate.fromJson(Map<String, dynamic> json) {
    return ContractTemplate(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      contractType: json['contract_type'],
      department: json['department'],
      content: json['content'],
      isActive: json['is_active'] ?? true,
      defaultClauses:
          (json['default_clauses'] as List<dynamic>?)
              ?.map((clause) => ContractClause.fromJson(clause))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'contract_type': contractType,
      'department': department,
      'content': content,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class ContractStats {
  final int totalContracts;
  final int draftContracts;
  final int pendingContracts;
  final int activeContracts;
  final int expiredContracts;
  final int terminatedContracts;
  final int contractsExpiringSoon;
  final double averageSalary;
  final Map<String, int> contractsByType;
  final Map<String, int> contractsByDepartment;
  final List<Contract> recentContracts;

  ContractStats({
    required this.totalContracts,
    required this.draftContracts,
    required this.pendingContracts,
    required this.activeContracts,
    required this.expiredContracts,
    required this.terminatedContracts,
    required this.contractsExpiringSoon,
    required this.averageSalary,
    required this.contractsByType,
    required this.contractsByDepartment,
    required this.recentContracts,
  });

  factory ContractStats.fromJson(Map<String, dynamic> json) {
    return ContractStats(
      totalContracts: json['total_contracts'],
      draftContracts: json['draft_contracts'],
      pendingContracts: json['pending_contracts'],
      activeContracts: json['active_contracts'],
      expiredContracts: json['expired_contracts'],
      terminatedContracts: json['terminated_contracts'],
      contractsExpiringSoon: json['contracts_expiring_soon'],
      averageSalary: json['average_salary']?.toDouble() ?? 0.0,
      contractsByType: Map<String, int>.from(json['contracts_by_type'] ?? {}),
      contractsByDepartment: Map<String, int>.from(
        json['contracts_by_department'] ?? {},
      ),
      recentContracts:
          (json['recent_contracts'] as List<dynamic>?)
              ?.map((contract) => Contract.fromJson(contract))
              .toList() ??
          [],
    );
  }
}

class ContractAmendment {
  final int? id;
  final int contractId;
  final String
  amendmentType; // 'salary', 'position', 'schedule', 'location', 'other'
  final String reason;
  final String description;
  final Map<String, dynamic> changes;
  final DateTime effectiveDate;
  final String status; // 'pending', 'approved', 'rejected'
  final String? approvalNotes;
  final DateTime? approvedAt;
  final int? approvedBy;
  final String? approvedByName;
  final DateTime createdAt;
  final DateTime updatedAt;

  ContractAmendment({
    this.id,
    required this.contractId,
    required this.amendmentType,
    required this.reason,
    required this.description,
    required this.changes,
    required this.effectiveDate,
    required this.status,
    this.approvalNotes,
    this.approvedAt,
    this.approvedBy,
    this.approvedByName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ContractAmendment.fromJson(Map<String, dynamic> json) {
    return ContractAmendment(
      id: json['id'],
      contractId: json['contract_id'],
      amendmentType: json['amendment_type'],
      reason: json['reason'],
      description: json['description'],
      changes: Map<String, dynamic>.from(json['changes'] ?? {}),
      effectiveDate: DateTime.parse(json['effective_date']),
      status: json['status'],
      approvalNotes: json['approval_notes'],
      approvedAt:
          json['approved_at'] != null
              ? DateTime.parse(json['approved_at'])
              : null,
      approvedBy: json['approved_by'],
      approvedByName: json['approved_by_name'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contract_id': contractId,
      'amendment_type': amendmentType,
      'reason': reason,
      'description': description,
      'changes': changes,
      'effective_date': effectiveDate.toIso8601String(),
      'status': status,
      'approval_notes': approvalNotes,
      'approved_at': approvedAt?.toIso8601String(),
      'approved_by': approvedBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get amendmentTypeText {
    switch (amendmentType) {
      case 'salary':
        return 'Salaire';
      case 'position':
        return 'Poste';
      case 'schedule':
        return 'Horaires';
      case 'location':
        return 'Lieu de travail';
      case 'other':
        return 'Autre';
      default:
        return amendmentType;
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
}

class ContractHistory {
  final int? id;
  final int contractId;
  final String action; // 'created', 'submitted', 'approved', 'rejected', 'terminated', 'cancelled'
  final String? actionText;
  final String? notes;
  final String? userName;
  final DateTime? createdAt;

  ContractHistory({
    this.id,
    required this.contractId,
    required this.action,
    this.actionText,
    this.notes,
    this.userName,
    this.createdAt,
  });

  factory ContractHistory.fromJson(Map<String, dynamic> json) {
    return ContractHistory(
      id: json['id'],
      contractId: json['contract_id'],
      action: json['action'],
      actionText: json['action_text'],
      notes: json['notes'],
      userName: json['user_name'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contract_id': contractId,
      'action': action,
      'action_text': actionText,
      'notes': notes,
      'user_name': userName,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
