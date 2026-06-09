enum Collections {
  users,
  roles,
  designations,
  departments,
  subDepartments,
  employees,
  chats,
  messages,
  notifications,
  leadCategory,
  leadSource,
  leadStatus,
  leadPriority,
  dealStatus,
  leads,
  clients,
  deals,
  tasks,
  taskComments,
  taskHistory,
  comments,
  admins,
  projects,
  version,
  trash,
  workLogs,
  usersStatus,
  feed,
  loginLogs,
  activityLogs,
  settings,
  backups,
  recentActivity,
  errors,
  events,
  worktime,
  attendance,
  permission,
  worktimeFromHome,
  salaryLedger,
  companies,
  holidays,
}

enum StorageFolder {
  companyLogo,
  userPhotos,
  chats,
  leadAttachments,
  clientPhotos,
  clientCompanyLogos,
  dealAttachments,
  adminProfile,
  taskAttachments,
  feedAttachments,
}

enum LeadSource { email, google, facebook, phone, directVisit, other }

enum PlatformType { mobile, desktop }

enum UserType { admin, employee }

enum EventRepeatType { none, daily, weekly, monthly, yearly }

enum Calendar { day, week, month }

enum ChatAction { pin, favorite, delete }

enum ClientSection { contacts, company }

enum LeadCompletionStatus { won, lost, disqualified }

extension LeadCompletionStatusX on LeadCompletionStatus {
  String get label {
    switch (this) {
      case LeadCompletionStatus.won:
        return 'Won';
      case LeadCompletionStatus.lost:
        return 'Lost';
      case LeadCompletionStatus.disqualified:
        return 'Disqualified';
    }
  }
}

enum UserData { uid, name, img, mobileNumber, collectionId, type }

enum FilterRequirements { staff }

enum LeadActivityType { call, meeting, followUp, task }

enum DealActivityType { call, meeting, followUp, task }

enum HalfDaySession { morning, evening }

enum PermissionsStatus { pending, approved, rejected }

enum PermissionType {
  permission,
  leaveFullDay,
  leaveHalfDay,
  workFromHome,
  lateEntry,
  earlyExit,
}

enum AttendanceStatus {
  present,
  absent,
  leave,
  holiday,
  wfh,
  halfDay,
  late,
  earlyExit,
  lessHours,
  pending,
  rejected,
}

enum NotificationType {
  alert,
  info,
  openFile,
  task,
  permissionRequest,
  lead,
  eventReminder,
  deal,
  chat,
  success,
  warning,
  error,
  feed,
}
