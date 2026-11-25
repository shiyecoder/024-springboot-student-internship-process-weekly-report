<template>
  <div class="page">
    <div class="cols">
      <div class="card">
        <div class="card-title">个人资料</div>
        <div class="avatar-row">
          <el-avatar :size="72" :src="form.avatar || undefined">{{ (form.realName || 'U').slice(0, 1) }}</el-avatar>
          <div>
            <UploadField v-model="form.avatar" biz-type="avatar" />
            <div class="muted" style="margin-top: 6px">头像上传成功后右上角立即同步</div>
          </div>
        </div>
        <el-form label-width="90px" style="margin-top: 16px">
          <el-form-item label="账号"><el-input :model-value="user.username" disabled /></el-form-item>
          <el-form-item label="姓名"><el-input v-model="form.realName" /></el-form-item>
          <el-form-item label="手机号"><el-input v-model="form.phone" /></el-form-item>
          <el-form-item label="邮箱"><el-input v-model="form.email" /></el-form-item>
          <el-form-item label="角色">
            <el-tag>{{ userStore.roleName }}</el-tag>
            <span class="muted" style="margin-left: 10px">{{ user.orgName }}</span>
          </el-form-item>
          <el-form-item>
            <el-button type="primary" :loading="saving" @click="saveProfile">保存资料</el-button>
          </el-form-item>
        </el-form>
      </div>

      <div class="card">
        <div class="card-title">修改密码 <span class="sub">密码使用 BCrypt 保存，接口不返回密码字段</span></div>
        <el-form label-width="90px">
          <el-form-item label="原密码"><el-input v-model="pwd.oldPassword" type="password" show-password /></el-form-item>
          <el-form-item label="新密码"><el-input v-model="pwd.newPassword" type="password" show-password placeholder="至少 6 位" /></el-form-item>
          <el-form-item label="确认密码"><el-input v-model="pwd.confirm" type="password" show-password /></el-form-item>
          <el-form-item>
            <el-button type="primary" :loading="saving2" @click="changePwd">修改密码</el-button>
          </el-form-item>
        </el-form>

        <div class="card-title" style="margin-top: 18px">账号信息</div>
        <div class="kv">
          <div><label>最近登录</label><span>{{ fmtDateTime(user.lastLoginTime) }}</span></div>
          <div><label>数据范围</label><span>{{ scopeText }}</span></div>
          <div><label>所属组织</label><span>{{ user.orgName || '-' }}</span></div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted, reactive, ref } from 'vue'
import { ElMessage } from 'element-plus'
import UploadField from '../components/UploadField.vue'
import { authApi } from '../api'
import { useUserStore } from '../store/user'
import { fmtDateTime } from '../utils/format'

/** 个人中心：改资料 / 改密码 / 上传头像，头像存本地 uploads 并同步右上角 */
const userStore = useUserStore()
const user = computed(() => userStore.user || {})
const form = reactive({ realName: '', phone: '', email: '', avatar: '' })
const pwd = reactive({ oldPassword: '', newPassword: '', confirm: '' })
const saving = ref(false)
const saving2 = ref(false)

const scopeText = computed(() => ({ ALL: '全校数据', ORG: '本学院数据', SELF: '仅本人数据' }[(user.value.dataScope || 'SELF')] ))

function fill() {
  Object.assign(form, {
    realName: user.value.realName || '', phone: user.value.phone || '',
    email: user.value.email || '', avatar: user.value.avatar || ''
  })
}

async function saveProfile() {
  saving.value = true
  try {
    await authApi.updateProfile({ ...form })
    userStore.patchUser({ ...form })
    ElMessage.success('资料已保存，右上角信息已同步')
  } finally { saving.value = false }
}

async function changePwd() {
  if (pwd.newPassword.length < 6) return ElMessage.warning('新密码至少 6 位')
  if (pwd.newPassword !== pwd.confirm) return ElMessage.warning('两次输入的新密码不一致')
  saving2.value = true
  try {
    await authApi.changePassword({ oldPassword: pwd.oldPassword, newPassword: pwd.newPassword })
    ElMessage.success('密码已修改，请重新登录')
    pwd.oldPassword = pwd.newPassword = pwd.confirm = ''
  } finally { saving2.value = false }
}

onMounted(async () => {
  if (!userStore.user) await userStore.fetchMe()
  fill()
})
</script>

<style scoped>
.cols { display: grid; grid-template-columns: minmax(0, 1fr) minmax(0, 1fr); gap: 16px; }
.avatar-row { display: flex; gap: 18px; align-items: flex-start; }
.kv { display: grid; gap: 8px; }
.kv > div { display: flex; justify-content: space-between; font-size: 13px; }
.kv label { color: var(--text-2); }
</style>
