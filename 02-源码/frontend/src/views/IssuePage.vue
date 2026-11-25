<template>
  <div class="page">
    <div class="card">
      <div class="card-title">异常关怀 <span class="sub">岗位不符、安全、薪资争议、长期无法联系均可上报并跟进处置</span>
        <el-button type="primary" @click="open()">上报异常</el-button>
      </div>

      <div class="toolbar">
        <el-radio-group v-model="query.status" size="small" @change="search">
          <el-radio-button label="">全部</el-radio-button>
          <el-radio-button label="待处置">待处置</el-radio-button>
          <el-radio-button label="处置中">处置中</el-radio-button>
          <el-radio-button label="已关闭">已关闭</el-radio-button>
        </el-radio-group>
        <span class="muted">共 {{ total }} 条，高风险优先</span>
      </div>

      <el-table :data="rows" v-loading="loading" border stripe>
        <el-table-column prop="issueNo" label="异常编号" min-width="140" />
        <el-table-column prop="studentName" label="学生" min-width="90" />
        <el-table-column prop="companyName" label="企业" min-width="200" show-overflow-tooltip />
        <el-table-column prop="issueType" label="类型" min-width="110" />
        <el-table-column prop="level" label="等级" min-width="80">
          <template #default="{ row }"><StatusTag :value="row.level" /></template>
        </el-table-column>
        <el-table-column prop="content" label="情况说明" min-width="280" show-overflow-tooltip />
        <el-table-column prop="status" label="状态" min-width="90">
          <template #default="{ row }"><StatusTag :value="row.status" /></template>
        </el-table-column>
        <el-table-column prop="handlerName" label="处置人" min-width="90" />
        <el-table-column label="上报时间" min-width="160">
          <template #default="{ row }">{{ fmtDateTime(row.reportTime) }}</template>
        </el-table-column>
        <el-table-column label="操作" min-width="100" fixed="right">
          <template #default="{ row }">
            <el-button v-if="row.status !== '已关闭'" link type="primary" @click="handle(row)">处置</el-button>
            <span v-else class="muted">已归档</span>
          </template>
        </el-table-column>
      </el-table>

      <div class="pager">
        <el-pagination background layout="total, sizes, prev, pager, next, jumper"
          :total="total" :current-page="page" :page-size="size" :page-sizes="[10, 20, 50]"
          @current-change="onPage" @size-change="onSize" />
      </div>
    </div>

    <el-dialog v-model="open1" title="上报异常" width="520px">
      <el-form label-width="100px">
        <el-form-item label="实习档案">
          <el-select v-model="form.applicationId" filterable style="width: 100%">
            <el-option v-for="a in apps" :key="a.id" :label="`${a.internshipNo} · ${a.studentName}`" :value="a.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="异常类型">
          <el-select v-model="form.issueType" style="width: 100%">
            <el-option v-for="t in ['岗位不符', '安全问题', '薪资争议', '无法联系', '其他']" :key="t" :label="t" :value="t" />
          </el-select>
        </el-form-item>
        <el-form-item label="紧急等级">
          <el-radio-group v-model="form.level">
            <el-radio v-for="l in ['高', '中', '低']" :key="l" :label="l">{{ l }}</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="情况说明">
          <el-input v-model="form.content" type="textarea" :rows="3" placeholder="不少于 5 个字" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="open1 = false">取消</el-button>
        <el-button type="primary" :loading="saving" @click="save">上报</el-button>
      </template>
    </el-dialog>

    <el-dialog v-model="handleOpen" title="处置异常" width="520px">
      <div v-if="cur" class="ap-head">
        <b>{{ cur.issueNo }}</b><StatusTag :value="cur.level" /><StatusTag :value="cur.status" />
        <p class="muted">{{ cur.content }}</p>
      </div>
      <el-form label-width="90px">
        <el-form-item label="处置记录">
          <el-input v-model="hForm.record" type="textarea" :rows="4" placeholder="记录走访、沟通与整改结果，不少于 5 个字" />
        </el-form-item>
        <el-form-item label="是否关闭">
          <el-switch v-model="hForm.close" active-text="关闭异常" inactive-text="继续跟进" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="handleOpen = false">取消</el-button>
        <el-button type="primary" :loading="saving" @click="doHandle">提交</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { onMounted, reactive, ref } from 'vue'
import { ElMessage } from 'element-plus'
import StatusTag from '../components/StatusTag.vue'
import { appApi, flowApi } from '../api'
import { useTable } from '../composables/useTable'
import { fmtDateTime } from '../utils/format'

/** 异常关怀：上报 → 处置 → 关闭，全过程留痕；同一档案可多次上报 */
const { rows, total, loading, page, size, query, load, search, onPage, onSize } =
  useTable(flowApi.issuePage, { status: '' })

const apps = ref([])
const open1 = ref(false)
const handleOpen = ref(false)
const saving = ref(false)
const cur = ref(null)
const form = reactive({ applicationId: null, issueType: '薪资争议', level: '中', content: '' })
const hForm = reactive({ record: '', close: false })

function open() {
  Object.assign(form, { applicationId: apps.value[0]?.id || null, issueType: '薪资争议', level: '中', content: '' })
  open1.value = true
}

async function save() {
  if (form.content.trim().length < 5) return ElMessage.warning('情况说明不少于 5 个字')
  saving.value = true
  try {
    await flowApi.saveIssue({ ...form })
    ElMessage.success('异常已上报，已推送到消息中心')
    open1.value = false
    load()
  } finally { saving.value = false }
}

function handle(row) {
  cur.value = row
  hForm.record = row.handleRecord || ''
  hForm.close = false
  handleOpen.value = true
}

async function doHandle() {
  if (hForm.record.trim().length < 5) return ElMessage.warning('处置记录不少于 5 个字')
  saving.value = true
  try {
    await flowApi.handleIssue(cur.value.id, { ...hForm })
    ElMessage.success(hForm.close ? '异常已关闭' : '处置记录已保存')
    handleOpen.value = false
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
.ap-head { margin-bottom: 12px; display: flex; gap: 10px; align-items: center; flex-wrap: wrap; }
.ap-head p { width: 100%; }
</style>
