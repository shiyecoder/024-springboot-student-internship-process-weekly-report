import { createRouter, createWebHashHistory } from 'vue-router'

/**
 * 路由表：后台走 AdminLayout，公开门户走 PortalLayout。
 * 路径与 sys_menu 表里的 path 一一对应，菜单由后端按角色下发，前端不写死可访问范围。
 */
const routes = [
  { path: '/login', component: () => import('../views/Login.vue'), meta: { public: true, title: '登录' } },
  {
    path: '/portal',
    component: () => import('../layout/PortalLayout.vue'),
    meta: { public: true },
    children: [
      { path: '', component: () => import('../views/portal/PortalHome.vue'), meta: { public: true, title: '实习信息公开' } },
      { path: 'report', component: () => import('../views/portal/PortalReport.vue'), meta: { public: true, title: '周报样例' } }
    ]
  },
  {
    path: '/',
    component: () => import('../layout/AdminLayout.vue'),
    redirect: '/dashboard',
    children: [
      { path: 'dashboard', component: () => import('../views/Dashboard.vue'), meta: { title: '工作台' } },
      { path: 'application', component: () => import('../views/ApplicationList.vue'), meta: { title: '实习备案中心' } },
      { path: 'application/:id', component: () => import('../views/ApplicationDetail.vue'), meta: { title: '实习档案详情' } },
      { path: 'attendance', component: () => import('../views/AttendancePage.vue'), meta: { title: '考勤汇总' } },
      { path: 'change', component: () => import('../views/ChangePage.vue'), meta: { title: '变更审批' } },
      { path: 'issue', component: () => import('../views/IssuePage.vue'), meta: { title: '异常关怀' } },
      { path: 'visit', component: () => import('../views/VisitPage.vue'), meta: { title: '走访记录' } },
      { path: 'report', component: () => import('../views/ReportPage.vue'), meta: { title: '周报工作台' } },
      { path: 'review', component: () => import('../views/ReviewPage.vue'), meta: { title: '导师批阅' } },
      { path: 'milestone', component: () => import('../views/MilestonePage.vue'), meta: { title: '里程碑进度' } },
      { path: 'evaluation', component: () => import('../views/EvaluationPage.vue'), meta: { title: '结项评价' } },
      { path: 'company', component: () => import('../views/CompanyPage.vue'), meta: { title: '企业库' } },
      { path: 'batch', component: () => import('../views/BatchPage.vue'), meta: { title: '实习批次' } },
      { path: 'board', component: () => import('../views/BoardPage.vue'), meta: { title: '统计看板' } },
      { path: 'rule', component: () => import('../views/RulePage.vue'), meta: { title: '规则配置' } },
      { path: 'system/user', component: () => import('../views/system/UserPage.vue'), meta: { title: '用户管理' } },
      { path: 'system/role', component: () => import('../views/system/RolePage.vue'), meta: { title: '角色管理' } },
      { path: 'system/dict', component: () => import('../views/system/DictPage.vue'), meta: { title: '字典管理' } },
      { path: 'system/log', component: () => import('../views/system/LogPage.vue'), meta: { title: '操作日志' } },
      { path: 'message', component: () => import('../views/MessagePage.vue'), meta: { title: '消息中心' } },
      { path: 'profile', component: () => import('../views/ProfilePage.vue'), meta: { title: '个人中心' } }
    ]
  },
  { path: '/:pathMatch(.*)*', redirect: '/dashboard' }
]

const router = createRouter({ history: createWebHashHistory(), routes })

// 登录校验：公开页面直接放行，其余必须带 token
router.beforeEach((to, from, next) => {
  const isPublic = to.matched.some((r) => r.meta && r.meta.public)
  const token = localStorage.getItem('at_token')
  if (isPublic || token) return next()
  next('/login')
})

export default router
