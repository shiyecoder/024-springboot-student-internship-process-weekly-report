import { defineStore } from 'pinia'
import request from '../utils/request'

/**
 * 登录态、用户信息与角色菜单。
 * 菜单由后端按 roleCode 下发（sys_menu + sys_role_menu），前端只负责渲染，
 * 不在前端硬编码可访问菜单——权限判定仍以后端为准。
 */
const ROLE_LABEL = {
  admin: '实习管理员',
  teacher: '校内指导教师',
  mentor: '企业导师',
  student: '学生'
}

export const useUserStore = defineStore('user', {
  state: () => ({
    token: localStorage.getItem('at_token') || '',
    user: JSON.parse(localStorage.getItem('at_user') || 'null'),
    menus: JSON.parse(localStorage.getItem('at_menus') || '[]')
  }),
  getters: {
    isLogin: (s) => !!s.token,
    roleCode: (s) => (s.user && s.user.roleCode) || '',
    roleName: (s) => ROLE_LABEL[(s.user && s.user.roleCode) || ''] || '用户',
    realName: (s) => (s.user && s.user.realName) || '',
    avatar: (s) => (s.user && s.user.avatar) || '',
    isAdmin: (s) => (s.user && s.user.roleCode) === 'admin'
  },
  actions: {
    async login(payload) {
      const data = await request.post('/api/auth/login', payload)
      this.token = data.token
      this.user = data.user
      this.menus = data.menus || []
      localStorage.setItem('at_token', data.token)
      localStorage.setItem('at_user', JSON.stringify(data.user))
      localStorage.setItem('at_menus', JSON.stringify(this.menus))
      return data
    },
    async fetchMe() {
      const data = await request.get('/api/auth/me')
      this.user = data.user || data
      this.menus = data.menus || []
      localStorage.setItem('at_user', JSON.stringify(this.user))
      localStorage.setItem('at_menus', JSON.stringify(this.menus))
      return data
    },
    /** 头像与资料更新后同步右上角 */
    patchUser(patch) {
      this.user = { ...(this.user || {}), ...patch }
      localStorage.setItem('at_user', JSON.stringify(this.user))
    },
    logout() {
      this.token = ''
      this.user = null
      this.menus = []
      localStorage.removeItem('at_token')
      localStorage.removeItem('at_user')
      localStorage.removeItem('at_menus')
    }
  }
})
