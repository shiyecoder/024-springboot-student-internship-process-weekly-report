<template>
  <div class="page">
    <div class="card">
      <div class="card-title">变更审批 <span class="sub">变更生效前原档案仍有效，生效后保留变更前后信息</span>
        <el-button type="primary" @click="open()">提交变更申请</el-button>
      </div>

      <div class="toolbar">
        <el-radio-group v-model="query.status" size="small" @change="search">
          <el-radio-button label="">全部</el-radio-button>
          <el-radio-button label="审批中">审批中</el-radio-button>
          <el-radio-button label="已通过">已通过</el-radio-button>
          <el-radio-button label="已驳回">已驳回</el-radio-button>
        </el-radio-group>
        <span class="muted">共 {{ total }} 条</span>
      </div>

      <el-table :data="rows" v-loading="loading" border stripe>
        <el-table-column prop="changeNo" label="变更编号" min-width="140" />
        <el-table-column prop="studentName" label="学生" min-width="90" />
        <el-table-column prop="changeType" label="变更类型" min-width="100" />
        <el-table-column label="变更前后" min-width="260">
          <template #default="{ row }">
            <span class="muted">{{ row.beforeValue }}</span> → <b>{{ row.afterValue }}</b>
          </template>
        </el-table-column>
        <el-table-column prop="reason" label="申请原因" min-width="280" show-overflow-tooltip />
        <el-table-column prop="currentNode" label="当前节点" min-width="100" />
        <el-table-column prop="status" label="状态" min-width="90">
          <template #default="{ row }"><StatusTag :value="row.status" /></template>
        </el-table-column>
        <el-table-column label="附件" min-width="86">
          <template #default="{ row }">
            <el-image v-if="row.attachment" :src="row.attachment" :preview-src-list="[row.attachment]" fit="cover" class="thumb" />
            <span v-else class="muted">无</span>
          </template>
        </el-table-column>
        <el-table-column label="申请时间" min-width="160">
          <template #default="{ row }">{{ fmtDateTime(row.applyTime) }}</template>
        </el-table-column>
        <el-table-column label="操作" min-width="100" fixed="right">
          <template #default="{ row }">
            <el-button v-if="row.status === '审批中'" link type="primary" @click="approve(row)">审批</el-button>
            <span v-else class="muted">{{ row.teacherOpinion || '已处理' }}</span>
          </template>
        </el-table-column>
      </el-table>

      <div class="pager">
        <el-pagination background layout="total, sizes, prev, pager, next, jumper"
          :total="total" :current-page="page" :page-size="size" :page-sizes="[10, 20, 50]"
          @current-change="onPage" @size-change="onSize" />
      </div>
    </div>

    <el-dialog v-model="open1" title="提交变更申请" width="520px">
      <el-form label-width="100px">
        <el-form-item label="实习档案">
          <el-select v-model="form.applicationId" filterable style="width: 100%">
            <el-option v-for="a in apps" :key="a.id" :label="`${a.internshipNo} · ${a.studentName}`" :value="a.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="变更类型">
          <el-select v-model="form.changeType" style="width: 100%">
            <el-option v-for="t in ['更换企业', '更换岗位', '更换导师', '中止实习']" :key="t" :label="t" :value="t" />
          </el-select>
        </el-form-item>
        <el-form-item label="变更前"><el-input v-model="form.beforeValue" /></el-form-item>
        <el-form-item label="变更后"><el-input v-model="form.afterValue" /></el-form-item>
        <el-form-item label="申请原因">
          <el-input v-model="form.reason" type="textarea" :rows="3" placeholder="不少于 5 个字" />
        </el-form-item>
        <el-form-item label="证明材料"><UploadField v-model="form.attachment" biz-type="change" /></el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="open1 = false">取消</el-button>
        <el-button type="primary" :loading="saving" @click="save">提交</el-button>
      </template>
    </el-dialog>

    <el-dialog v-model="approveOpen" title="审批变更" width="480px">
      <div v-if="cur" class="ap-head">
        <b>{{ cur.changeNo }}</b><StatusTag :value="cur.status" />
        <div class="muted">{{ cur.changeType }}：{{ cur.beforeValue }} → {{ cur.afterValue }}</div>
      </div>
      <el-form label-width="90px">
        <el-form-item label="审批结果">
          <el-radio-group v-model="apForm.pass">
            <el-radio :label="true">通过</el-radio>
            <el-radio :label="false">驳回</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="审批意见">
          <el-input v-model="apForm.opinion" type="textarea" :rows="3" placeholder="驳回必须填写不少于 5 个字的原因" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="approveOpen = false">取消</el-button>
        <el-button type="primary" :loading="saving" @click="doApprove">提交审批</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { onMounted, reactive, ref } from 'vue'
import { ElMessage } from 'element-plus'
import StatusTag from '../components/StatusTag.vue'
import UploadField from '../components/UploadField.vue'
import { appApi, flowApi } from '../api'
import { useTable } from '../composables/useTable'
import { fmtDateTime } from '../utils/format'

/** 变更审批：教师初审 + 管理员复审，生效后写回档案并留痕 */
const { rows, total, loading, page, size, query, load, search, onPage, onSize } =
  useTable(flowApi.changePage, { status: '' })

const apps = ref([])
const open1 = ref(false)
const approveOpen = ref(false)
const saving = ref(false)
const cur = ref(null)
const form = reactive({ applicationId: null, changeType: '更换岗位', beforeValue: '', afterValue: '', reason: '', attachment: '' })
const apForm = reactive({ pass: true, opinion: '' })

function open() {
  Object.assign(form, { applicationId: apps.value[0]?.id || null, changeType: '更换岗位', beforeValue: '', afterValue: '', reason: '', attachment: '' })
  open1.value = true
}

async function save() {
  if (form.reason.trim().length < 5) return ElMessage.warning('申请原因不少于 5 个字')
  saving.value = true
  try {
    await flowApi.saveChange({ ...form })
    ElMessage.success('变更申请已提交')
    open1.value = false
    load()
  } finally { saving.value = false }
}

function approve(row) {
  cur.value = row
  apForm.pass = true
  apForm.opinion = ''
  approveOpen.value = true
}

async function doApprove() {
  if (!apForm.pass && apForm.opinion.trim().length < 5) return ElMessage.warning('驳回必须填写不少于 5 个字的原因')
  saving.value = true
  try {
    await flowApi.approveChange(cur.value.id, { ...apForm })
    ElMessage.success('审批已提交')
    approveOpen.value = false
    load()
  } finally { saving.value = false }
}

onMounted(async () => {
  load()
  const d = await appApi.page({ page: 1, size: 100 })
  apps.value = d.records || []
})
</script>

<style scoped>
.ap-head { margin-bottom: 14px; display: flex; gap: 10px; align-items: center; flex-wrap: wrap; }
</style>
