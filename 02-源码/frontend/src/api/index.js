import request from '../utils/request'

/**
 * 接口层：一个模块一组方法，页面只调这里，不直接拼 URL。
 * 路径与后端 controller 一一对应（/api/...）。
 */

/* 认证与个人中心 */
export const authApi = {
  login: (data) => request.post('/api/auth/login', data),
  register: (data) => request.post('/api/auth/register', data),
  me: () => request.get('/api/auth/me'),
  updateProfile: (data) => request.put('/api/auth/profile', data),
  changePassword: (data) => request.put('/api/auth/password', data)
}

/* 看板 */
export const dashboardApi = {
  main: () => request.get('/api/dashboard'),
  board: () => request.get('/api/dashboard/board'),
  todo: () => request.get('/api/dashboard/todo')
}

/* 实习档案（核心主档） */
export const appApi = {
  page: (params) => request.get('/api/internship-process/page', { params }),
  detail: (id) => request.get(`/api/internship-process/${id}`),
  create: (data) => request.post('/api/internship-process', data),
  update: (id, data) => request.put(`/api/internship-process/${id}`, data),
  transition: (id, data) => request.post(`/api/internship-process/${id}/transition`, data),
  batchTransition: (data) => request.post('/api/internship-process/batch-transition', data),
  options: () => request.get('/api/internship-process/options')
}

/* 周报与考勤 */
export const reportApi = {
  page: (params) => request.get('/api/report/page', { params }),
  detail: (id) => request.get(`/api/report/${id}`),
  save: (data) => request.post('/api/report', data),
  review: (id, data) => request.post(`/api/report/${id}/review`, data),
  attendancePage: (params) => request.get('/api/attendance/page', { params }),
  saveAttendance: (data) => request.post('/api/attendance', data),
  confirmAttendance: (id) => request.post(`/api/attendance/${id}/confirm`)
}

/* 流程类单据：变更 / 异常 / 走访 / 结项评价 */
export const flowApi = {
  changePage: (params) => request.get('/api/flow/change/page', { params }),
  saveChange: (data) => request.post('/api/flow/change', data),
  approveChange: (id, data) => request.post(`/api/flow/change/${id}/approve`, data),
  issuePage: (params) => request.get('/api/flow/issue/page', { params }),
  saveIssue: (data) => request.post('/api/flow/issue', data),
  handleIssue: (id, data) => request.post(`/api/flow/issue/${id}/handle`, data),
  visitPage: (params) => request.get('/api/flow/visit/page', { params }),
  saveVisit: (data) => request.post('/api/flow/visit', data),
  evalPage: (params) => request.get('/api/flow/evaluation/page', { params }),
  getEval: (appId) => request.get(`/api/flow/evaluation/${appId}`),
  saveEval: (appId, data) => request.post(`/api/flow/evaluation/${appId}`, data)
}

/* 创新点：周报里程碑完整度检查 */
export const scoreApi = {
  rules: () => request.get('/api/score/rule/list'),
  currentRule: () => request.get('/api/score/rule/current'),
  saveRule: (data) => request.post('/api/score/rule', data),
  evaluate: (appId) => request.post(`/api/score/evaluate/${appId}`),
  history: (appId) => request.get(`/api/score/history/${appId}`),
  latest: (appId) => request.get(`/api/score/latest/${appId}`),
  adjust: (id, data) => request.post(`/api/score/${id}/adjust`, data),
  stats: () => request.get('/api/score/stats')
}

/* 基础数据：批次与企业库 */
export const baseApi = {
  batchList: () => request.get('/api/base/batch/list'),
  saveBatch: (data) => request.post('/api/base/batch', data),
  companyPage: (params) => request.get('/api/base/company/page', { params }),
  saveCompany: (data) => request.post('/api/base/company', data),
  delCompany: (id) => request.delete(`/api/base/company/${id}`),
  companyOptions: () => request.get('/api/base/company/options')
}

/* 系统管理 */
export const systemApi = {
  userPage: (params) => request.get('/api/system/user/page', { params }),
  saveUser: (data) => request.post('/api/system/user', data),
  updateUser: (id, data) => request.put(`/api/system/user/${id}`, data),
  resetPassword: (id) => request.post(`/api/system/user/${id}/reset-password`),
  roles: () => request.get('/api/system/role/list'),
  menus: () => request.get('/api/system/menu/list'),
  menuTree: () => request.get('/api/system/menu/tree'),
  roleMenus: (code) => request.get(`/api/system/role/${code}/menus`),
  saveRoleMenus: (code, ids) => request.post(`/api/system/role/${code}/menus`, { menuIds: ids }),
  dicts: (type) => request.get('/api/system/dict/list', { params: { type } }),
  saveDict: (data) => request.post('/api/system/dict', data),
  delDict: (id) => request.delete(`/api/system/dict/${id}`),
  orgs: () => request.get('/api/system/org/list'),
  messages: () => request.get('/api/system/message/list'),
  unread: () => request.get('/api/system/message/unread'),
  readOne: (id) => request.post(`/api/system/message/${id}/read`),
  readAll: () => request.post('/api/system/message/read-all'),
  logPage: (params) => request.get('/api/system/log/page', { params })
}

/* 文件上传（图片字段一律走这里，禁止外链） */
export const fileApi = {
  upload: (formData, bizType = 'internship') =>
    request.post(`/api/file/upload?bizType=${bizType}`, formData, {
      headers: { 'Content-Type': 'multipart/form-data' }
    })
}
