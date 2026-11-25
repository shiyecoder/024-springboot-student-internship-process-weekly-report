<template>
  <div class="layout" :class="{ collapsed }">
    <!-- 左侧菜单 220px（折叠 64px），菜单项来自后端按角色下发 -->
    <aside class="sidebar">
      <div class="brand">
        <div class="logo">实</div>
        <div class="brand-text" v-show="!collapsed">
          <div class="name">实习过程管理</div>
          <div class="sub">Internship Process</div>
        </div>
      </div>

      <el-scrollbar class="menu-scroll">
        <el-menu
          :default-active="route.path"
          :collapse="collapsed"
          :collapse-transition="false"
          background-color="transparent"
          text-color="#c8dbcf"
          active-text-color="#ffffff"
          router
        >
          <template v-for="m in menus" :key="m.id">
            <el-sub-menu v-if="m.children && m.children.length" :index="'g' + m.id">
              <template #title>
                <el-icon><component :is="iconOf(m.icon)" /></el-icon>
                <span>{{ m.name }}</span>
              </template>
              <el-menu-item v-for="c in m.children" :key="c.id" :index="c.path">
                <el-icon><component :is="iconOf(c.icon)" /></el-icon>
                <template #title>{{ c.name }}</template>
              </el-menu-item>
            </el-sub-menu>
            <el-menu-item v-else :index="m.path">
              <el-icon><component :is="iconOf(m.icon)" /></el-icon>
              <template #title>{{ m.name }}</template>
            </el-menu-item>
          </template>
        </el-menu>
      </el-scrollbar>

      <div class="role-badge" v-show="!collapsed">{{ userStore.roleName }}</div>
    </aside>

    <section class="main">
      <!-- 顶部栏 56px：面包屑 + 消息 + 头像 -->
      <header class="topbar">
        <div class="left">
          <el-icon class="fold" @click="collapsed = !collapsed">
            <component :is="collapsed ? Expand : Fold" />
          </el-icon>
          <el-breadcrumb separator="/">
            <el-breadcrumb-item>{{ groupName }}</el-breadcrumb-item>
            <el-breadcrumb-item>{{ pageTitle }}</el-breadcrumb-item>
          </el-breadcrumb>
        </div>
        <div class="right">
          <el-popover placement="bottom-end" :width="340" trigger="click">
            <template #reference>
              <div class="bell">
                <el-badge :value="unread" :hidden="!unread" :max="99">
                  <el-icon :size="18"><Bell /></el-icon>
                </el-badge>
              </div>
            </template>
            <div class="msg-pop">
              <div class="msg-head">
                <span>站内消息</span>
                <el-button link type="primary" size="small" @click="readAll">全部已读</el-button>
              </div>
              <div v-if="!msgs.length" class="empty-hint">暂无未读消息</div>
              <div v-for="m in msgs.slice(0, 6)" :key="m.id" class="msg-item" @click="openMsg(m)">
                <div class="t"><el-tag size="small" :type="statusType(m.msgType)">{{ m.msgType }}</el-tag>{{ m.title }}</div>
                <div class="c">{{ m.content }}</div>
                <div class="d">{{ fmtDateTime(m.createTime) }}</div>
              </div>
              <el-button link type="primary" class="more" @click="$router.push('/message')">查看全部消息 →</el-button>
            </div>
          </el-popover>

          <el-dropdown @command="onCommand">
            <div class="user">
              <el-avatar :size="30" :src="userStore.avatar || undefined">
                {{ (userStore.realName || 'U').slice(0, 1) }}
              </el-avatar>
              <div class="uinfo">
                <div class="uname">{{ userStore.realName }}</div>
                <div class="urole">{{ userStore.roleName }}</div>
              </div>
              <el-icon><ArrowDown /></el-icon>
            </div>
            <template #dropdown>
              <el-dropdown-menu>
                <el-dropdown-item command="profile">个人中心</el-dropdown-item>
                <el-dropdown-item command="message">消息中心</el-dropdown-item>
                <el-dropdown-item command="portal">公开门户</el-dropdown-item>
                <el-dropdown-item command="logout" divided>退出登录</el-dropdown-item>
              </el-dropdown-menu>
            </template>
          </el-dropdown>
        </div>
      </header>

      <el-scrollbar class="content">
        <router-view v-slot="{ Component }">
          <component :is="Component" />
        </router-view>
      </el-scrollbar>
    </section>
  </div>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Bell, Fold, Expand, ArrowDown } from '@element-plus/icons-vue'
import { useUserStore } from '../store/user'
import { systemApi } from '../api'
import { fmtDateTime, statusType } from '../utils/format'

/**
 * 后台布局：220px 侧边栏 + 56px 顶栏 + 自适应内容区。
 * 菜单按角色从 /api/auth/me 返回的 menus 渲染，管理员能看到系统管理，学生只看到本人相关项。
 */
const route = useRoute()
const router = useRouter()
const userStore = useUserStore()
const collapsed = ref(false)
const msgs = ref([])
const unread = ref(0)

/** 后端 icon 字段 → Element Plus 图标组件 */
const ICONS = {
  dashboard: 'Odometer', archive: 'Folder', calendar: 'Calendar', flag: 'Flag',
  alert: 'Warning', people: 'User', report: 'Document', check: 'Checked',
  shield: 'Lock', building: 'OfficeBuilding', chart: 'TrendCharts', rule: 'SetUp',
  user: 'UserFilled', message: 'ChatDotRound', log: 'Tickets'
}
const iconOf = (k) => ICONS[k] || 'Menu'

const menus = computed(() => userStore.menus || [])
const pageTitle = computed(() => route.meta.title || '工作台')
const groupName = computed(() => {
  for (const m of menus.value) {
    for (const c of m.children || []) if (c.path === route.path) return m.name
  }
  return '实习过程'
})

async function loadMsgs() {
  try {
    msgs.value = (await systemApi.messages()) || []
    unread.value = (await systemApi.unread()) || 0
  } catch (e) { /* 消息失败不阻塞主流程 */ }
}

async function readAll() {
  await systemApi.readAll()
  loadMsgs()
  ElMessage.success('已全部标记为已读')
}

function openMsg(m) {
  systemApi.readOne(m.id)
  loadMsgs()
  if (m.linkUrl) router.push(m.linkUrl)
}

async function onCommand(cmd) {
  if (cmd === 'profile') return router.push('/profile')
  if (cmd === 'message') return router.push('/message')
  if (cmd === 'portal') return router.push('/portal')
  if (cmd === 'logout') {
    try {
      await ElMessageBox.confirm('确认退出当前账号吗？', '退出登录', { type: 'warning' })
      userStore.logout()
      router.push('/login')
    } catch (e) { /* 取消 */ }
  }
}

onMounted(async () => {
  if (!userStore.user) {
    try { await userStore.fetchMe() } catch (e) { /* 由拦截器跳登录 */ }
  }
  loadMsgs()
})
</script>

<style scoped>
.layout { display: flex; height: 100vh; overflow: hidden; background: var(--bg); }

.sidebar {
  width: 220px; flex: 0 0 220px; background: #1c3f2f; display: flex; flex-direction: column;
  transition: width .18s ease, flex-basis .18s ease;
}
.collapsed .sidebar { width: 64px; flex-basis: 64px; }

.brand { height: 56px; display: flex; align-items: center; gap: 10px; padding: 0 14px; border-bottom: 1px solid rgba(255,255,255,.08); }
.logo {
  width: 30px; height: 30px; border-radius: 6px; background: #3a7d5a; color: #fff;
  display: grid; place-items: center; font-weight: 700; font-size: 15px; flex: 0 0 30px;
}
.brand-text .name { color: #fff; font-size: 14px; font-weight: 600; letter-spacing: .3px; }
.brand-text .sub { color: #8fb3a0; font-size: 10px; letter-spacing: .5px; }

.menu-scroll { flex: 1; }
:deep(.el-menu) { border-right: none; }
:deep(.el-menu-item), :deep(.el-sub-menu__title) { height: 44px; line-height: 44px; font-size: 13.5px; }
:deep(.el-menu-item.is-active) { background: #3a7d5a !important; color: #fff !important; border-radius: 6px; margin: 0 8px; }
:deep(.el-menu--collapse .el-menu-item) { margin: 0 4px; }
:deep(.el-sub-menu .el-menu-item) { padding-left: 42px !important; }
:deep(.el-menu-item:hover), :deep(.el-sub-menu__title:hover) { background: rgba(255,255,255,.06) !important; }

.role-badge {
  margin: 10px 12px 14px; padding: 6px 10px; border-radius: 6px; font-size: 12px;
  color: #b7d2c2; background: rgba(255,255,255,.06); text-align: center;
}

.main { flex: 1; min-width: 0; display: flex; flex-direction: column; }

.topbar {
  height: 56px; flex: 0 0 56px; background: #fff; border-bottom: 1px solid var(--line);
  display: flex; align-items: center; justify-content: space-between; padding: 0 20px;
}
.topbar .left { display: flex; align-items: center; gap: 14px; }
.fold { cursor: pointer; color: var(--text-2); font-size: 17px; }
.topbar .right { display: flex; align-items: center; gap: 18px; }
.bell { cursor: pointer; color: var(--text-2); display: flex; }

.user { display: flex; align-items: center; gap: 8px; cursor: pointer; }
.uinfo { line-height: 1.2; }
.uname { font-size: 13px; color: var(--text); font-weight: 500; }
.urole { font-size: 11px; color: var(--text-2); }

.content { flex: 1; background: var(--bg); }

.msg-pop .msg-head { display: flex; justify-content: space-between; align-items: center; font-weight: 600; margin-bottom: 8px; }
.msg-item { padding: 8px 0; border-bottom: 1px dashed var(--line); cursor: pointer; }
.msg-item .t { font-size: 13px; display: flex; gap: 6px; align-items: center; }
.msg-item .c { font-size: 12px; color: var(--text-2); margin-top: 3px; }
.msg-item .d { font-size: 11px; color: #9aa8a1; margin-top: 2px; }
.more { margin-top: 8px; }
</style>
