class LeaveRequest {
  final int? id;
  final int employeeId;
  final String employeeName;
  final String leaveType;
  final DateTime startDate;
  final DateTime endDate;
  final int totalDays;
  final String reason;
  final String status; // 'pending', 'approved', 'rejected', 'cancelled'
  final String? comments;
  final String? rejectionReason;
  final DateTime? approvedAt;
  final int? approvedBy;
  final String? approvedByName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<LeaveAttachment> attachments;
  final LeaveBalance? leaveBalance;

  LeaveRequest({
    this.id,
    required this.employeeId,
    required this.employeeName,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    required this.reason,
    required this.status,
    this.comments,
    this.rejectionReason,
    this.approvedAt,
    this.approvedBy,
    this.approvedByName,
    required this.createdAt,
    required this.updatedAt,
    this.attachments = const [],
    this.leaveBalance,
  });

  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    return LeaveRequest(
      id: json['id'],
      employeeId: json['employee_id'],
      employeeName: json['employee_name'] ?? '',
      leaveType: json['leave_type'],
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      totalDays: json['total_days'],
      reason: json['reason'],
      status: json['status'],
      comments: json['comments'],
      rejectionReason: json['rejection_reason'],
      approvedAt: json['approved_at'] != null ? DateTime.parse(json['approved_at']) : null,
      approvedBy: json['approved_by'],
      approvedByName: json['approved_by_name'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      attachments: (json['attachments'] as List<dynamic>?)
          ?.map((attachment) => LeaveAttachment.fromJson(attachment))
          .toList() ?? [],
      leaveBalance: json['leave_balance'] != null 
          ? LeaveBalance.fromJson(json['leave_balance']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employee_id': employeeId,
      'leave_type': leaveType,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'total_days': totalDays,
      'reason': reason,
      'status': status,
      'comments': comments,
      'rejection_reason': rejectionReason,
      'approved_at': approvedAt?.toIso8601String(),
      'approved_by': approvedBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Getters pour l'affichage
  String get statusText {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'approved':
        return 'Approuvé';
      case 'rejected':
        return 'Rejeté';
      case 'cancelled':
        return 'Annulé';
      default:
        return 'Inconnu';
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
      case 'cancelled':
        return 'grey';
      default:
        return 'grey';
    }
  }

  String get leaveTypeText {
    switch (leaveType) {
      case 'annual':
        return 'Congés payés';
      case 'sick':
        return 'Congé maladie';
      case 'maternity':
        return 'Congé maternité';
      case 'paternity':
        return 'Congé paternité';
      case 'personal':
        return 'Congé personnel';
      case 'emergency':
        return 'Congé d\'urgence';
      case 'unpaid':
        return 'Congé sans solde';
      default:
        return leaveType;
    }
  }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get isCancelled => status == 'cancelled';

  bool get canApprove => isPending;
  bool get canReject => isPending;
  bool get canCancel => isPending || isApproved;
}

class LeaveAttachment {
  final int? id;
  final int leaveRequestId;
  final String fileName;
  final String filePath;
  final String fileType;
  final int fileSize;
  final DateTime uploadedAt;

  LeaveAttachment({
    this.id,
    required this.leaveRequestId,
    required this.fileName,
    required this.filePath,
    required this.fileType,
    required this.fileSize,
    required this.uploadedAt,
  });

  factory LeaveAttachment.fromJson(Map<String, dynamic> json) {
    return LeaveAttachment(
      id: json['id'],
      leaveRequestId: json['leave_request_id'],
      fileName: json['file_name'],
      filePath: json['file_path'],
      fileType: json['file_type'],
      fileSize: json['file_size'],
      uploadedAt: DateTime.parse(json['uploaded_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'leave_request_id': leaveRequestId,
      'file_name': fileName,
      'file_path': filePath,
      'file_type': fileType,
      'file_size': fileSize,
      'uploaded_at': uploadedAt.toIso8601String(),
    };
  }
}

class LeaveBalance {
  final int employeeId;
  final String employeeName;
  final int annualLeaveDays;
  final int usedAnnualLeave;
  final int remainingAnnualLeave;
  final int sickLeaveDays;
  final int usedSickLeave;
  final int remainingSickLeave;
  final int personalLeaveDays;
  final int usedPersonalLeave;
  final int remainingPersonalLeave;
  final DateTime lastUpdated;

  LeaveBalance({
    required this.employeeId,
    required this.employeeName,
    required this.annualLeaveDays,
    required this.usedAnnualLeave,
    required this.remainingAnnualLeave,
    required this.sickLeaveDays,
    required this.usedSickLeave,
    required this.remainingSickLeave,
    required this.personalLeaveDays,
    required this.usedPersonalLeave,
    required this.remainingPersonalLeave,
    required this.lastUpdated,
  });

  factory LeaveBalance.fromJson(Map<String, dynamic> json) {
    return LeaveBalance(
      employeeId: json['employee_id'],
      employeeName: json['employee_name'] ?? '',
      annualLeaveDays: json['annual_leave_days'],
      usedAnnualLeave: json['used_annual_leave'],
      remainingAnnualLeave: json['remaining_annual_leave'],
      sickLeaveDays: json['sick_leave_days'],
      usedSickLeave: json['used_sick_leave'],
      remainingSickLeave: json['remaining_sick_leave'],
      personalLeaveDays: json['personal_leave_days'],
      usedPersonalLeave: json['used_personal_leave'],
      remainingPersonalLeave: json['remaining_personal_leave'],
      lastUpdated: DateTime.parse(json['last_updated']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'employee_id': employeeId,
      'annual_leave_days': annualLeaveDays,
      'used_annual_leave': usedAnnualLeave,
      'remaining_annual_leave': remainingAnnualLeave,
      'sick_leave_days': sickLeaveDays,
      'used_sick_leave': usedSickLeave,
      'remaining_sick_leave': remainingSickLeave,
      'personal_leave_days': personalLeaveDays,
      'used_personal_leave': usedPersonalLeave,
      'remaining_personal_leave': remainingPersonalLeave,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }
}

class LeaveStats {
  final int totalRequests;
  final int pendingRequests;
  final int approvedRequests;
  final int rejectedRequests;
  final int cancelledRequests;
  final double averageApprovalTime;
  final Map<String, int> requestsByType;
  final Map<String, int> requestsByMonth;
  final List<LeaveRequest> recentRequests;

  LeaveStats({
    required this.totalRequests,
    required this.pendingRequests,
    required this.approvedRequests,
    required this.rejectedRequests,
    required this.cancelledRequests,
    required this.averageApprovalTime,
    required this.requestsByType,
    required this.requestsByMonth,
    required this.recentRequests,
  });

  factory LeaveStats.fromJson(Map<String, dynamic> json) {
    return LeaveStats(
      totalRequests: json['total_requests'],
      pendingRequests: json['pending_requests'],
      approvedRequests: json['approved_requests'],
      rejectedRequests: json['rejected_requests'],
      cancelledRequests: json['cancelled_requests'],
      averageApprovalTime: json['average_approval_time']?.toDouble() ?? 0.0,
      requestsByType: Map<String, int>.from(json['requests_by_type'] ?? {}),
      requestsByMonth: Map<String, int>.from(json['requests_by_month'] ?? {}),
      recentRequests: (json['recent_requests'] as List<dynamic>?)
          ?.map((request) => LeaveRequest.fromJson(request))
          .toList() ?? [],
    );
  }
}

class LeaveType {
  final String value;
  final String label;
  final String description;
  final bool requiresApproval;
  final int maxDays;
  final bool isPaid;

  LeaveType({
    required this.value,
    required this.label,
    required this.description,
    required this.requiresApproval,
    required this.maxDays,
    required this.isPaid,
  });

  static List<LeaveType> get leaveTypes => [
    LeaveType(
      value: 'annual',
      label: 'Congés payés',
      description: 'Congés annuels payés',
      requiresApproval: true,
      maxDays: 30,
      isPaid: true,
    ),
    LeaveType(
      value: 'sick',
      label: 'Congé maladie',
      description: 'Congé pour maladie',
      requiresApproval: true,
      maxDays: 90,
      isPaid: true,
    ),
    LeaveType(
      value: 'maternity',
      label: 'Congé maternité',
      description: 'Congé de maternité',
      requiresApproval: true,
      maxDays: 98,
      isPaid: true,
    ),
    LeaveType(
      value: 'paternity',
      label: 'Congé paternité',
      description: 'Congé de paternité',
      requiresApproval: true,
      maxDays: 11,
      isPaid: true,
    ),
    LeaveType(
      value: 'personal',
      label: 'Congé personnel',
      description: 'Congé pour affaires personnelles',
      requiresApproval: true,
      maxDays: 5,
      isPaid: false,
    ),
    LeaveType(
      value: 'emergency',
      label: 'Congé d\'urgence',
      description: 'Congé pour urgence familiale',
      requiresApproval: true,
      maxDays: 3,
      isPaid: false,
    ),
    LeaveType(
      value: 'unpaid',
      label: 'Congé sans solde',
      description: 'Congé non rémunéré',
      requiresApproval: true,
      maxDays: 30,
      isPaid: false,
    ),
  ];
}
