<template>
  <div class="page">
    <div class="card">
      <div class="card-title">用户管理 <span class="sub">账号、角色与数据范围；密码使用 BCrypt 保存，任何接口不返回密码</span>
        <el-button type="primary" @click="open()">新增用户</el-button>
      </div>

      <el-form class="filter-bar" :inline="true">
        <el-form-item label="关键字">
          <el-input v-model="query.keyword" placeholder="账号 / 姓名" clearable @keyup.enter="search" />
        </el-form-item>
        <el-form-item label="角色">
          <el-select v-model="query.roleCode" clearable placeholder="全部角色">
            <el-option v-for="r in roles" :key="r.roleCode" :label="r.roleName" :value="r.roleCode" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="search">查询</el-button>
          <el-button @click="reset">重置</el-button>
        </el-form-item>
      </el-form>

      <el-table :data="rows" v-loading="loading" border stripe>
        <el-table-column label="头像" min-width="72">
          <template #default="{ row }">
            <el-avatar :size="30" :src="row.avatar || undefined">{{ (row.realName || 'U').slice(0, 1) }}</el-avatar>
          </template>
        </el-table-column>
        <el-table-column prop="username" label="账号" min-width="110" />
        <el-table-column prop="realName" label="姓名" min-width="96" />
        <el-table-column prop="phone" label="手机号" min-width="130" />
        <el-table-column prop="email" label="邮箱" min-width="180" />
        <el-table-column prop="roleName" label="角色" min-width="120" />
        <el-table-column prop="orgName" label="所属组织" min-width="150" />
        <el-table-column prop="dataScope" label="数据范围" min-width="110">
          <template #default="{ row }">{{ scopeText[row.dataScope] || row.dataScope }}</template>
        </el-table-column>
        <el-table-column label="状态" min-width="86">
          <template #default="{ row }"><StatusTag :value="row.status === 1 ? '启用' : '停用'" /></template>
        </el-table-column>
        <el-table-column label="最近登录" min-width="160">
          <template #default="{ row }">{{ fmtDateTime(row.lastLoginTime) }}</template>
        </el-table-column>
        <el-table-column label="操作" min-width="150" fixed="right">
          <template #default="{ row }">
            <el-button link type="primary" @click="open(row)">编辑</el-button>
            <el-button link type="primary" @click="resetPwd(row)">重置密码</el-button>
          </template>
        </el-table-column>
      </el-table>

      <div class="pager">
        <el-pagination background layout="total, sizes, prev, pager, next, jumper"
          :total="total" :current-page="page" :page-size="size" :page-sizes="[10, 20, 50]"
          @current-change="onPage" @size-change="onSize" />
      </div>
    </div>

    <el-drawer v-model="open1" :title="form.id ? '编辑用户' : '新增用户'" size="480px">
      <el-form label-width="96px">
        <el-form-item label="账号"><el-input v-model="form.username" :disabled="!!form.id" /></el-form-item>
        <el-form-item label="姓名"><el-input v-model="form.realName" /></el-form-item>
        <el-form-item label="手机号"><el-input v-model="form.phone" /></el-form-item>
        <el-form-item label="邮箱"><el-input v-model="form.email" /></el-form-item>
        <el-form-item label="角色">
          <el-select v-model="form.roleCode" style="width: 100%">
            <el-option v-for="r in roles" :key="r.roleCode" :label="r.roleName" :value="r.roleCode" />
          </el-select>
        </el-form-item>
        <el-form-item label="所属组织">
          <el-select v-model="form.orgId" style="width: 100%">
            <el-option v-for="o in orgs" :key="o.id" :label="o.orgName" :value="o.id" />
          </el-select>
        </el-form-item>
        <el-form-item v-if="!form.id" label="初始密码"><el-input v-model="form.password" placeholder="默认 123456" /></el-form-item>
        <el-form-item label="状态">
          <el-switch v-model="form.status" :active-value="1" :inactive-value="0" active-text="启用" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="open1 = false">取消</el-button>
        <el-button type="primary" :loading="saving" @click="save">保存</el-button>
      </template>
    </el-drawer>
  </div>
</template>

<script setup>
import { onMounted, reactive, ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import StatusTag from '../../components/StatusTag.vue'
import { systemApi } from '../../api'
import { useTable } from '../../composables/useTable'
import { fmtDateTime } from '../../utils/format'

/** 用户管理：角色决定数据范围（ALL/ORG/SELF），菜单权限由角色分配页控制 */
const scopeText = { ALL: '全校', ORG: '本学院', SELF: '仅本人' }
const { rows, total, loading, page, size, query, load, search, reset, onPage, onSize } =
  useTable(systemApi.userPage, { keyword: '', roleCode: '' })

const roles = ref([])
const orgs = ref([])
const open1 = ref(false)
const saving = ref(false)
const empty = () => ({ id: null, username: '', realName: '', phone: '', email: '', roleCode: 'student', orgId: null, password: '123456', status: 1 })
const form = reactive(empty())

function open(row) {
  Object.assign(form, empty(), row || {})
  open1.value = true
}

async function save() {
  if (!form.username || !form.realName) return ElMessage.warning('请填写账号与姓名')
  saving.value = true
  try {
    if (form.id) await systemApi.updateUser(form.id, { ...form })
    else await systemApi.saveUser({ ...form })
    ElMessage.success('已保存')
    open1.value = false
    load()
  } finally { saving.value = false }
}

async function resetPwd(row) {
  try {
    await ElMessageBox.confirm(`确认将「${row.realName}」的密码重置为 123456 吗？`, '重置密码', { type: 'warning' })
    await systemApi.resetPassword(row.id)
    ElMessage.success('已重置为 123456')
  } catch (e) { /* 取消 */ }
}

onMounted(async () => {
  load()
  roles.value = (await systemApi.roles()) || []
  orgs.value = (await systemApi.orgs()) || []
})
</script>
