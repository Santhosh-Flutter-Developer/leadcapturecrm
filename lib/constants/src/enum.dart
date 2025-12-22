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
}

enum StorageFolder {
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

enum CalendarView { day, week, month }

enum ChatAction { pin, favorite }

enum ClientSection { contacts, company }
