<template>
  <div class="login-page">
    <!-- 左侧品牌区：实习过程主题背景图 + 流程说明 -->
    <div class="brand-side">
      <div class="bg" :style="{ backgroundImage: 'url(/login-bg.jpg)' }"></div>
      <div class="brand-inner">
        <div class="mark">
          <span class="box">实</span>
          <div>
            <h1>大学生实习过程与周报管理</h1>
            <p class="en">INTERNSHIP PROCESS & WEEKLY REPORT</p>
          </div>
        </div>
        <p class="slogan">从实习备案到学校归档，把每一份周报、每一次走访、每一轮评价都留在链路里。</p>
        <ul class="steps">
          <li><b>01</b> 实习备案 · 协议审核</li>
          <li><b>02</b> 过程周报 · 阶段检查</li>
          <li><b>03</b> 双导师评价 · 学校归档</li>
        </ul>
        <div class="quote">
          <span>“</span>
          周报不是形式，是实习过程唯一可追溯的证据。
        </div>
      </div>
    </div>

    <!-- 右侧表单区 -->
    <div class="form-side">
      <div class="form-box">
        <div class="tabs">
          <button :class="{ on: mode === 'login' }" @click="mode = 'login'">账号登录</button>
          <button :class="{ on: mode === 'register' }" @click="mode = 'register'">学生注册</button>
        </div>

        <template v-if="mode === 'login'">
          <h2>欢迎回来</h2>
          <p class="sub">请使用学校统一分配的实习系统账号登录</p>
          <el-form ref="formRef" :model="form" :rules="rules" label-position="top" @keyup.enter="submit">
            <el-form-item label="账号" prop="username">
              <el-input v-model="form.username" size="large" placeholder="学号 / 工号" :prefix-icon="User" clearable />
            </el-form-item>
            <el-form-item label="密码" prop="password">
              <el-input v-model="form.password" type="password" size="large" show-password placeholder="登录密码" :prefix-icon="Lock" />
            </el-form-item>
            <div class="row">
              <el-checkbox v-model="remember">记住账号</el-checkbox>
              <a class="link" @click="tip">忘记密码？</a>
            </div>
            <el-button type="primary" size="large" class="submit" :loading="loading" @click="submit">登录系统</el-button>
          </el-form>

          <div class="demo">
            <div class="demo-title">演示账号（点击填入）</div>
            <div class="demo-list">
              <span v-for="d in demos" :key="d.u" @click="fill(d)">{{ d.r }} {{ d.u }}</span>
            </div>
            <div class="demo-pwd">统一密码：admin123 / 123456</div>
          </div>
        </template>

        <template v-else>
          <h2>学生注册</h2>
          <p class="sub">注册后由学院管理员分配实习批次与指导教师</p>
          <el-form ref="regRef" :model="reg" :rules="regRules" label-position="top">
            <el-form-item label="学号 / 账号" prop="username">
              <el-input v-model="reg.username" size="large" placeholder="例如 2022010101" />
            </el-form-item>
            <el-form-item label="姓名" prop="realName">
              <el-input v-model="reg.realName" size="large" placeholder="真实姓名" />
            </el-form-item>
            <el-form-item label="手机号" prop="phone">
              <el-input v-model="reg.phone" size="large" placeholder="用于接收站内消息提醒" />
            </el-form-item>
            <el-form-item label="密码" prop="password">
              <el-input v-model="reg.password" type="password" size="large" show-password placeholder="至少 6 位" />
            </el-form-item>
            <el-button type="primary" size="large" class="submit" :loading="loading" @click="doRegister">提交注册</el-button>
          </el-form>
        </template>

        <div class="foot-links">
          <a href="#/portal">查看实习信息公开页 →</a>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { User, Lock } from '@element-plus/icons-vue'
import { useUserStore } from '../store/user'
import { authApi } from '../api'

/**
 * 登录 / 注册页：贴合实习过程主题重新设计，不使用默认表单样式。
 * 登录成功后按角色跳转不同首页——管理员与教师进看板，学生进周报工作台，
 * 这里只做默认落地页选择，具体可见菜单仍由后端下发。
 */
const router = useRouter()
const userStore = useUserStore()
const mode = ref('login')
const loading = ref(false)
const remember = ref(true)
const formRef = ref()
const regRef = ref()

const form = reactive({
  username: localStorage.getItem('at_last_user') || 'admin',
  password: 'admin123'
})

const reg = reactive({ username: '', realName: '', phone: '', password: '' })

const rules = {
  username: [{ required: true, message: '请输入账号', trigger: 'blur' }],
  password: [{ required: true, message: '请输入密码', trigger: 'blur' }]
}
const regRules = {
  username: [{ required: true, message: '请输入学号', trigger: 'blur' }],
  realName: [{ required: true, message: '请输入姓名', trigger: 'blur' }],
  phone: [{ pattern: /^1[3-9]\d{9}$/, message: '手机号格式不正确', trigger: 'blur' }],
  password: [{ min: 6, message: '密码至少 6 位', trigger: 'blur' }]
}

const demos = [
  { r: '管理员', u: 'admin', p: 'admin123' },
  { r: '校内教师', u: 'limh', p: '123456' },
  { r: '企业导师', u: 'zhoujg', p: '123456' },
  { r: '学生', u: 'chenzy', p: '123456' }
]

function fill(d) {
  form.username = d.u
  form.password = d.p
}

function tip() {
  ElMessage.info('请联系学院实习管理员重置密码，重置后为初始密码 123456')
}

async function submit() {
  try {
    await formRef.value.validate()
  } catch (e) { return }
  loading.value = true
  try {
    const data = await userStore.login({ username: form.username.trim(), password: form.password })
    if (remember.value) localStorage.setItem('at_last_user', form.username.trim())
    ElMessage.success('登录成功，欢迎 ' + (data.user.realName || form.username))
    const role = data.user.roleCode
    router.push(role === 'student' ? '/report' : '/dashboard')
  } catch (e) {
    /* 错误提示由请求拦截器统一弹出 */
  } finally {
    loading.value = false
  }
}

async function doRegister() {
  try {
    await regRef.value.validate()
  } catch (e) { return }
  loading.value = true
  try {
    await authApi.register({ ...reg, roleCode: 'student' })
    ElMessage.success('注册成功，请使用该账号登录')
    mode.value = 'login'
    form.username = reg.username
    form.password = reg.password
  } catch (e) {
    /* 已提示 */
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.login-page { display: flex; height: 100vh; background: #f4f8f5; }

.brand-side { position: relative; flex: 1.15; overflow: hidden; background: #16332a; color: #fff; }
.bg { position: absolute; inset: 0; background-size: cover; background-position: center; opacity: .34; transform: scale(1.02); }
.brand-side::after {
  content: ''; position: absolute; inset: 0;
  background: linear-gradient(115deg, rgba(22,51,42,.94) 30%, rgba(28,63,47,.62) 100%);
}
.brand-inner { position: relative; z-index: 2; padding: 64px 56px; height: 100%; display: flex; flex-direction: column; }
.mark { display: flex; align-items: center; gap: 14px; }
.mark .box { width: 46px; height: 46px; border-radius: 10px; background: #3a7d5a; display: grid; place-items: center; font-size: 20px; font-weight: 700; }
.mark h1 { font-size: 21px; margin: 0; letter-spacing: .5px; font-weight: 600; }
.mark .en { margin: 4px 0 0; font-size: 10.5px; letter-spacing: 2px; color: #8fb3a0; }
.slogan { margin: 44px 0 0; font-size: 15px; line-height: 1.9; color: #d3e3d9; max-width: 430px; }
.steps { list-style: none; padding: 0; margin: 34px 0 0; }
.steps li { font-size: 13.5px; color: #c6dace; padding: 9px 0; border-bottom: 1px solid rgba(255,255,255,.09); max-width: 400px; }
.steps b { color: #7fbf9b; font-family: var(--mono); margin-right: 12px; font-weight: 600; }
.quote { margin-top: auto; font-size: 13px; color: #9dbfab; max-width: 420px; line-height: 1.8; border-left: 2px solid #3a7d5a; padding-left: 14px; }
.quote span { font-size: 30px; color: #3a7d5a; line-height: 0; position: relative; top: 8px; margin-right: 4px; }

.form-side { flex: 0 0 480px; display: flex; align-items: center; justify-content: center; background: #fff; }
.form-box { width: 340px; }
.tabs { display: flex; gap: 26px; margin-bottom: 26px; border-bottom: 1px solid var(--line); }
.tabs button {
  background: none; border: none; padding: 0 0 12px; font-size: 14px; color: var(--text-2);
  cursor: pointer; position: relative; font-family: inherit;
}
.tabs button.on { color: var(--primary); font-weight: 600; }
.tabs button.on::after { content: ''; position: absolute; left: 0; right: 0; bottom: -1px; height: 2px; background: var(--primary); }
h2 { font-size: 22px; margin: 0 0 6px; color: var(--text); }
.sub { color: var(--text-2); font-size: 12.5px; margin: 0 0 24px; }
.row { display: flex; justify-content: space-between; align-items: center; margin: -4px 0 18px; font-size: 13px; }
.link { color: var(--accent); cursor: pointer; }
.submit { width: 100%; height: 44px; font-size: 15px; letter-spacing: 2px; }
.demo { margin-top: 26px; border-top: 1px dashed var(--line); padding-top: 16px; }
.demo-title { font-size: 12px; color: var(--text-2); margin-bottom: 8px; }
.demo-list { display: flex; flex-wrap: wrap; gap: 8px; }
.demo-list span {
  font-size: 12px; padding: 4px 10px; border: 1px solid var(--line); border-radius: 4px;
  cursor: pointer; color: var(--accent); background: #f8fbf9;
}
.demo-list span:hover { border-color: var(--secondary); background: #eff7f2; }
.demo-pwd { font-size: 11px; color: #93a49b; margin-top: 8px; }
.foot-links { margin-top: 22px; font-size: 12.5px; }
.foot-links a { color: var(--accent); }

@media (max-width: 980px) {
  .brand-side { display: none; }
  .form-side { flex: 1; }
}
</style>
