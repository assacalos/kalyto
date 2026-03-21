class RecruitmentRequest {
  final int? id;
  final String title;
  final String department;
  final String position;
  final String description;
  final String requirements;
  final String responsibilities;
  final int numberOfPositions;
  final String
  employmentType; // 'full_time', 'part_time', 'contract', 'internship'
  final String experienceLevel; // 'entry', 'junior', 'mid', 'senior', 'expert'
  final String salaryRange;
  final String location;
  final DateTime applicationDeadline;
  final String status; // , 'pending', 'validated', 'rejected',
  final String? rejectionReason;
  final DateTime? publishedAt;
  final int? publishedBy;
  final String? publishedByName;
  final DateTime? approvedAt;
  final int? approvedBy;
  final String? approvedByName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<RecruitmentApplication> applications;
  final RecruitmentStats? stats;

  RecruitmentRequest({
    this.id,
    required this.title,
    required this.department,
    required this.position,
    required this.description,
    required this.requirements,
    required this.responsibilities,
    required this.numberOfPositions,
    required this.employmentType,
    required this.experienceLevel,
    required this.salaryRange,
    required this.location,
    required this.applicationDeadline,
    required this.status,
    this.rejectionReason,
    this.publishedAt,
    this.publishedBy,
    this.publishedByName,
    this.approvedAt,
    this.approvedBy,
    this.approvedByName,
    required this.createdAt,
    required this.updatedAt,
    this.applications = const [],
    this.stats,
  });

  factory RecruitmentRequest.fromJson(Map<String, dynamic> json) {
    return RecruitmentRequest(
      id: json['id'],
      title: json['title'],
      department: json['department'],
      position: json['position'],
      description: json['description'],
      requirements: json['requirements'],
      responsibilities: json['responsibilities'],
      numberOfPositions: json['number_of_positions'],
      employmentType: json['employment_type'],
      experienceLevel: json['experience_level'],
      salaryRange: json['salary_range'],
      location: json['location'],
      applicationDeadline: DateTime.parse(json['application_deadline']),
      status: json['status'],
      rejectionReason: json['rejection_reason'],
      publishedAt:
          json['published_at'] != null
              ? DateTime.parse(json['published_at'])
              : null,
      publishedBy: json['published_by'],
      publishedByName: json['published_by_name'],
      approvedAt:
          json['approved_at'] != null
              ? DateTime.parse(json['approved_at'])
              : null,
      approvedBy: json['approved_by'],
      approvedByName: json['approved_by_name'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      applications:
          (json['applications'] as List<dynamic>?)
              ?.map((app) => RecruitmentApplication.fromJson(app))
              .toList() ??
          [],
      stats:
          json['stats'] != null
              ? RecruitmentStats.fromJson(json['stats'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'department': department,
      'position': position,
      'description': description,
      'requirements': requirements,
      'responsibilities': responsibilities,
      'number_of_positions': numberOfPositions,
      'employment_type': employmentType,
      'experience_level': experienceLevel,
      'salary_range': salaryRange,
      'location': location,
      'application_deadline': applicationDeadline.toIso8601String(),
      'status': status,
      'rejection_reason': rejectionReason,
      'published_at': publishedAt?.toIso8601String(),
      'published_by': publishedBy,
      'approved_at': approvedAt?.toIso8601String(),
      'approved_by': approvedBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Getters pour l'affichage
  String get statusText {
    switch (status) {
      case 'draft':
        return 'Brouillon';
      case 'published':
        return 'Publié';
      case 'closed':
        return 'Fermé';
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
      case 'published':
        return 'green';
      case 'closed':
        return 'red';
      case 'cancelled':
        return 'orange';
      default:
        return 'grey';
    }
  }

  String get employmentTypeText {
    switch (employmentType) {
      case 'full_time':
        return 'Temps plein';
      case 'part_time':
        return 'Temps partiel';
      case 'contract':
        return 'Contrat';
      case 'internship':
        return 'Stage';
      default:
        return employmentType;
    }
  }

  String get experienceLevelText {
    switch (experienceLevel) {
      case 'entry':
        return 'Débutant';
      case 'junior':
        return 'Junior (0-2 ans)';
      case 'mid':
        return 'Intermédiaire (2-5 ans)';
      case 'senior':
        return 'Senior (5-10 ans)';
      case 'expert':
        return 'Expert (10+ ans)';
      default:
        return experienceLevel;
    }
  }

  bool get isDraft => status == 'draft';
  bool get isPublished => status == 'published';
  bool get isClosed => status == 'closed';
  bool get isCancelled => status == 'cancelled';

  bool get canPublish => isDraft;
  bool get canClose => isPublished;
  bool get canCancel => isDraft || isPublished;
  bool get canEdit => isDraft;
}

class RecruitmentApplication {
  final int? id;
  final int recruitmentRequestId;
  final String candidateName;
  final String candidateEmail;
  final String candidatePhone;
  final String? candidateAddress;
  final String? coverLetter;
  final String? resumePath;
  final String? portfolioUrl;
  final String? linkedinUrl;
  final String
  status; // 'pending', 'reviewed', 'shortlisted', 'interviewed', 'rejected', 'hired'
  final String? notes;
  final String? rejectionReason;
  final DateTime? reviewedAt;
  final int? reviewedBy;
  final String? reviewedByName;
  final DateTime? interviewScheduledAt;
  final DateTime? interviewCompletedAt;
  final String? interviewNotes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<RecruitmentDocument> documents;

  RecruitmentApplication({
    this.id,
    required this.recruitmentRequestId,
    required this.candidateName,
    required this.candidateEmail,
    required this.candidatePhone,
    this.candidateAddress,
    this.coverLetter,
    this.resumePath,
    this.portfolioUrl,
    this.linkedinUrl,
    required this.status,
    this.notes,
    this.rejectionReason,
    this.reviewedAt,
    this.reviewedBy,
    this.reviewedByName,
    this.interviewScheduledAt,
    this.interviewCompletedAt,
    this.interviewNotes,
    required this.createdAt,
    required this.updatedAt,
    this.documents = const [],
  });

  factory RecruitmentApplication.fromJson(Map<String, dynamic> json) {
    return RecruitmentApplication(
      id: json['id'],
      recruitmentRequestId: json['recruitment_request_id'],
      candidateName: json['candidate_name'],
      candidateEmail: json['candidate_email'],
      candidatePhone: json['candidate_phone'],
      candidateAddress: json['candidate_address'],
      coverLetter: json['cover_letter'],
      resumePath: json['resume_path'],
      portfolioUrl: json['portfolio_url'],
      linkedinUrl: json['linkedin_url'],
      status: json['status'],
      notes: json['notes'],
      rejectionReason: json['rejection_reason'],
      reviewedAt:
          json['reviewed_at'] != null
              ? DateTime.parse(json['reviewed_at'])
              : null,
      reviewedBy: json['reviewed_by'],
      reviewedByName: json['reviewed_by_name'],
      interviewScheduledAt:
          json['interview_scheduled_at'] != null
              ? DateTime.parse(json['interview_scheduled_at'])
              : null,
      interviewCompletedAt:
          json['interview_completed_at'] != null
              ? DateTime.parse(json['interview_completed_at'])
              : null,
      interviewNotes: json['interview_notes'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      documents:
          (json['documents'] as List<dynamic>?)
              ?.map((doc) => RecruitmentDocument.fromJson(doc))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recruitment_request_id': recruitmentRequestId,
      'candidate_name': candidateName,
      'candidate_email': candidateEmail,
      'candidate_phone': candidatePhone,
      'candidate_address': candidateAddress,
      'cover_letter': coverLetter,
      'resume_path': resumePath,
      'portfolio_url': portfolioUrl,
      'linkedin_url': linkedinUrl,
      'status': status,
      'notes': notes,
      'rejection_reason': rejectionReason,
      'reviewed_at': reviewedAt?.toIso8601String(),
      'reviewed_by': reviewedBy,
      'interview_scheduled_at': interviewScheduledAt?.toIso8601String(),
      'interview_completed_at': interviewCompletedAt?.toIso8601String(),
      'interview_notes': interviewNotes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Getters pour l'affichage
  String get statusText {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'reviewed':
        return 'Examiné';
      case 'shortlisted':
        return 'Pré-sélectionné';
      case 'interviewed':
        return 'Interviewé';
      case 'rejected':
        return 'Rejeté';
      case 'hired':
        return 'Embauché';
      default:
        return 'Inconnu';
    }
  }

  String get statusColor {
    switch (status) {
      case 'pending':
        return 'orange';
      case 'reviewed':
        return 'blue';
      case 'shortlisted':
        return 'green';
      case 'interviewed':
        return 'purple';
      case 'rejected':
        return 'red';
      case 'hired':
        return 'green';
      default:
        return 'grey';
    }
  }

  bool get isPending => status == 'pending';
  bool get isReviewed => status == 'reviewed';
  bool get isShortlisted => status == 'shortlisted';
  bool get isInterviewed => status == 'interviewed';
  bool get isRejected => status == 'rejected';
  bool get isHired => status == 'hired';

  bool get canReview => isPending;
  bool get canShortlist => isReviewed;
  bool get canInterview => isShortlisted;
  bool get canReject =>
      isPending || isReviewed || isShortlisted || isInterviewed;
  bool get canHire => isInterviewed;

  get user => null;
}

class RecruitmentDocument {
  final int? id;
  final int applicationId;
  final String fileName;
  final String filePath;
  final String fileType;
  final int fileSize;
  final DateTime uploadedAt;

  RecruitmentDocument({
    this.id,
    required this.applicationId,
    required this.fileName,
    required this.filePath,
    required this.fileType,
    required this.fileSize,
    required this.uploadedAt,
  });

  factory RecruitmentDocument.fromJson(Map<String, dynamic> json) {
    return RecruitmentDocument(
      id: json['id'],
      applicationId: json['application_id'],
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
      'application_id': applicationId,
      'file_name': fileName,
      'file_path': filePath,
      'file_type': fileType,
      'file_size': fileSize,
      'uploaded_at': uploadedAt.toIso8601String(),
    };
  }
}

class RecruitmentStats {
  final int totalRequests;
  final int draftRequests;
  final int publishedRequests;
  final int closedRequests;
  final int totalApplications;
  final int pendingApplications;
  final int shortlistedApplications;
  final int interviewedApplications;
  final int hiredApplications;
  final int rejectedApplications;
  final double averageApplicationTime;
  final Map<String, int> applicationsByDepartment;
  final Map<String, int> applicationsByPosition;
  final List<RecruitmentApplication> recentApplications;

  RecruitmentStats({
    required this.totalRequests,
    required this.draftRequests,
    required this.publishedRequests,
    required this.closedRequests,
    required this.totalApplications,
    required this.pendingApplications,
    required this.shortlistedApplications,
    required this.interviewedApplications,
    required this.hiredApplications,
    required this.rejectedApplications,
    required this.averageApplicationTime,
    required this.applicationsByDepartment,
    required this.applicationsByPosition,
    required this.recentApplications,
  });

  factory RecruitmentStats.fromJson(Map<String, dynamic> json) {
    return RecruitmentStats(
      totalRequests: json['total_requests'],
      draftRequests: json['draft_requests'],
      publishedRequests: json['published_requests'],
      closedRequests: json['closed_requests'],
      totalApplications: json['total_applications'],
      pendingApplications: json['pending_applications'],
      shortlistedApplications: json['shortlisted_applications'],
      interviewedApplications: json['interviewed_applications'],
      hiredApplications: json['hired_applications'],
      rejectedApplications: json['rejected_applications'],
      averageApplicationTime:
          json['average_application_time']?.toDouble() ?? 0.0,
      applicationsByDepartment: Map<String, int>.from(
        json['applications_by_department'] ?? {},
      ),
      applicationsByPosition: Map<String, int>.from(
        json['applications_by_position'] ?? {},
      ),
      recentApplications:
          (json['recent_applications'] as List<dynamic>?)
              ?.map((app) => RecruitmentApplication.fromJson(app))
              .toList() ??
          [],
    );
  }
}

class RecruitmentInterview {
  final int? id;
  final int applicationId;
  final DateTime scheduledAt;
  final String location;
  final String type; // 'phone', 'video', 'in_person'
  final String? meetingLink;
  final String? notes;
  final String status; // 'scheduled', 'completed', 'cancelled'
  final String? feedback;
  final int? interviewerId;
  final String? interviewerName;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  RecruitmentInterview({
    this.id,
    required this.applicationId,
    required this.scheduledAt,
    required this.location,
    required this.type,
    this.meetingLink,
    this.notes,
    required this.status,
    this.feedback,
    this.interviewerId,
    this.interviewerName,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RecruitmentInterview.fromJson(Map<String, dynamic> json) {
    return RecruitmentInterview(
      id: json['id'],
      applicationId: json['application_id'],
      scheduledAt: DateTime.parse(json['scheduled_at']),
      location: json['location'],
      type: json['type'],
      meetingLink: json['meeting_link'],
      notes: json['notes'],
      status: json['status'],
      feedback: json['feedback'],
      interviewerId: json['interviewer_id'],
      interviewerName: json['interviewer_name'],
      completedAt:
          json['completed_at'] != null
              ? DateTime.parse(json['completed_at'])
              : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'application_id': applicationId,
      'scheduled_at': scheduledAt.toIso8601String(),
      'location': location,
      'type': type,
      'meeting_link': meetingLink,
      'notes': notes,
      'status': status,
      'feedback': feedback,
      'interviewer_id': interviewerId,
      'completed_at': completedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get statusText {
    switch (status) {
      case 'scheduled':
        return 'Programmé';
      case 'completed':
        return 'Terminé';
      case 'cancelled':
        return 'Annulé';
      default:
        return 'Inconnu';
    }
  }

  String get typeText {
    switch (type) {
      case 'phone':
        return 'Téléphonique';
      case 'video':
        return 'Vidéo';
      case 'in_person':
        return 'En personne';
      default:
        return type;
    }
  }
}
