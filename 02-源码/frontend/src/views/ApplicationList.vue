<template>
  <div class="page">
    <!-- 实习备案中心：条件区 + 业务摘要 + 数据表格 -->
    <div class="summary">
      <div class="s-item"><span>档案总数</span><b>{{ total }}</b></div>
      <div class="s-item"><span>本页实习中</span><b>{{ inProgress }}</b></div>
      <div class="s-item"><span>当前筛选待批阅周报</span><b>{{ pendingReport }}</b></div>
      <div class="spacer"></div>
      <el-button type="primary" @click="openCreate">新建实习备案</el-button>
      <el-button :disabled="!selected.length" @click="batchDialog = true">批量流转（{{ selected.length }}）</el-button>
      <el-button @click="exportCsv">导出当前筛选</el-button>
    </div>

    <el-form class="filter-bar" :inline="true">
      <el-form-item label="关键字">
        <el-input v-model="query.keyword" placeholder="实习编号 / 学生姓名" clearable @keyup.enter="search" />
      </el-form-item>
      <el-form-item label="学院">
        <el-select v-model="query.department" placeholder="全部学院" clearable>
          <el-option v-for="o in colleges" :key="o.id" :label="o.orgName" :value="o.orgName" />
        </el-select>
      </el-form-item>
      <el-form-item label="企业">
        <el-input v-model="query.company" placeholder="企业名称" clearable @keyup.enter="search" />
      </el-form-item>
      <el-form-item label="岗位">
        <el-input v-model="query.position" placeholder="岗位关键字" clearable @keyup.enter="search" />
      </el-form-item>
      <el-form-item label="实习阶段">
        <el-select v-model="query.stage" placeholder="全部阶段" clearable>
          <el-option v-for="s in stages" :key="s" :label="s" :value="s" />
        </el-select>
      </el-form-item>
      <el-form-item label="周报状态">
        <el-select v-model="query.reportStatus" placeholder="全部状态" clearable>
          <el-option v-for="s in reportStatuses" :key="s" :label="s" :value="s" />
        </el-select>
      </el-form-item>
      <el-form-item label="开始日期">
        <el-date-picker v-model="range" type="daterange" value-format="YYYY-MM-DD" start-placeholder="起" end-placeholder="止" />
      </el-form-item>
      <el-form-item>
        <el-button type="primary" @click="search">查询</el-button>
        <el-button @click="resetAll">重置</el-button>
      </el-form-item>
    </el-form>

    <div class="card">
      <div class="toolbar">
        <div class="tabs">
          <el-radio-group v-model="quick" size="small" @change="applyQuick">
            <el-radio-button label="">全部</el-radio-button>
            <el-radio-button label="实习中">进行中</el-radio-button>
            <el-radio-button label="待审核">待审核</el-radio-button>
            <el-radio-button label="已中止">已中止</el-radio-button>
          </el-radio-group>
        </div>
        <span class="muted">共 {{ total }} 条，按更新时间倒序</span>
      </div>

      <el-table :data="rows" v-loading="loading" border stripe @selection-change="(v) => (selected = v)">
        <el-table-column type="selection" width="42" />
        <el-table-column prop="internshipNo" label="实习编号" min-width="128" fixed>
          <template #default="{ row }"><a class="no" @click="go(row)">{{ row.internshipNo }}</a></template>
        </el-table-column>
        <el-table-column prop="studentName" label="学生" min-width="90" />
        <el-table-column prop="studentNo" label="学号" min-width="118" />
        <el-table-column prop="major" label="专业" min-width="104" />
        <el-table-column prop="companyName" label="实习企业" min-width="220" show-overflow-tooltip />
        <el-table-column prop="position" label="岗位" min-width="130" show-overflow-tooltip />
        <el-table-column prop="teacherName" label="校内导师" min-width="96" />
        <el-table-column prop="mentorName" label="企业导师" min-width="96" />
        <el-table-column prop="stage" label="实习阶段" min-width="104">
          <template #default="{ row }"><StatusTag :value="row.stage" /></template>
        </el-table-column>
        <el-table-column prop="reportStatus" label="周报状态" min-width="96">
          <template #default="{ row }"><StatusTag :value="row.reportStatus" /></template>
        </el-table-column>
        <el-table-column label="实习周期" min-width="180">
          <template #default="{ row }"><span class="num">{{ row.startDate }} ~ {{ row.endDate }}</span></template>
        </el-table-column>
        <el-table-column label="更新时间" min-width="160">
          <template #default="{ row }"><span class="num">{{ fmtDateTime(row.updateTime) }}</span></template>
        </el-table-column>
        <el-table-column label="操作" min-width="140" fixed="right">
          <template #default="{ row }">
            <el-button link type="primary" @click="go(row)">查看</el-button>
            <el-button link type="primary" @click="openFlow(row)">流转</el-button>
          </template>
        </el-table-column>
      </el-table>

      <div class="pager">
        <el-pagination
          background layout="total, sizes, prev, pager, next, jumper"
          :total="total" :current-page="page" :page-size="size"
          :page-sizes="[10, 20, 50]" @current-change="onPage" @size-change="onSize"
        />
      </div>
    </div>

    <!-- 新建：右侧抽屉，关闭前检测未保存内容 -->
    <el-drawer v-model="createOpen" title="新建实习备案" size="560px" :before-close="confirmClose">
      <el-form ref="formRef" :model="form" :rules="rules" label-width="110px">
        <el-form-item label="实习编号" prop="internshipNo">
          <el-input v-model="form.internshipNo" placeholder="SI + 年份 + 序号" />
        </el-form-item>
        <el-form-item label="学生姓名" prop="studentName">
          <el-input v-model="form.studentName" />
        </el-form-item>
        <el-form-item label="学号" prop="studentNo"><el-input v-model="form.studentNo" /></el-form-item>
        <el-form-item label="专业" prop="major"><el-input v-model="form.major" /></el-form-item>
        <el-form-item label="实习企业" prop="companyName">
          <el-select v-model="form.companyName" filterable placeholder="从企业库选择" style="width: 100%">
            <el-option v-for="c in companies" :key="c.id" :label="c.companyName" :value="c.companyName" />
          </el-select>
        </el-form-item>
        <el-form-item label="岗位" prop="position"><el-input v-model="form.position" /></el-form-item>
        <el-form-item label="校内导师" prop="teacherName"><el-input v-model="form.teacherName" /></el-form-item>
        <el-form-item label="企业导师" prop="mentorName"><el-input v-model="form.mentorName" /></el-form-item>
        <el-form-item label="开始日期" prop="startDate">
          <el-date-picker v-model="form.startDate" type="date" value-format="YYYY-MM-DD" style="width: 100%" />
        </el-form-item>
        <el-form-item label="结束日期" prop="endDate">
          <el-date-picker v-model="form.endDate" type="date" value-format="YYYY-MM-DD" style="width: 100%" />
        </el-form-item>
        <el-form-item label="来源">
          <el-select v-model="form.source" style="width: 100%">
            <el-option label="集中实习" value="集中实习" />
            <el-option label="自主实习" value="自主实习" />
          </el-select>
        </el-form-item>
        <el-form-item label="协议附件">
          <UploadField v-model="form.agreementFile" biz-type="agreement" />
        </el-form-item>
        <el-form-item label="保险材料">
          <UploadField v-model="form.insuranceFile" biz-type="insurance" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="confirmClose(() => (createOpen = false))">取消</el-button>
        <el-button type="primary" :loading="saving" @click="save">提交备案</el-button>
      </template>
    </el-drawer>

    <!-- 流转：抽屉内展示单据摘要，原因不少于 5 字 -->
    <el-drawer v-model="flowOpen" title="档案状态流转" size="460px">
      <div v-if="current" class="flow-box">
        <div class="flow-head">
          <b>{{ current.internshipNo }}</b>
          <StatusTag :value="current.stage" />
        </div>
        <div class="muted">{{ current.studentName }} · {{ current.companyName }} · {{ current.position }}</div>
        <el-form label-width="90px" style="margin-top: 18px">
          <el-form-item label="目标阶段">
            <el-select v-model="flowForm.targetStage" style="width: 100%">
              <el-option v-for="s in stages" :key="s" :label="s" :value="s" />
              <el-option label="已中止" value="已中止" />
            </el-select>
          </el-form-item>
          <el-form-item label="流转原因">
            <el-input v-model="flowForm.reason" type="textarea" :rows="4" placeholder="不少于 5 个字，会写入操作日志" />
          </el-form-item>
        </el-form>
        <el-alert type="info" :closable="false" show-icon title="状态只能相邻推进或转已中止，越级会被后端拒绝" />
      </div>
      <template #footer>
        <el-button @click="flowOpen = false">取消</el-button>
        <el-button type="primary" :loading="saving" @click="doFlow">确认流转</el-button>
      </template>
    </el-drawer>

    <!-- 批量流转：逐条返回失败原因 -->
    <el-dialog v-model="batchDialog" title="批量流转" width="520px">
      <p class="muted">已选 {{ selected.length }} 条档案，将逐条执行并返回成功或失败原因。</p>
      <el-form label-width="90px">
        <el-form-item label="目标阶段">
          <el-select v-model="flowForm.targetStage" style="width: 100%">
            <el-option v-for="s in stages" :key="s" :label="s" :value="s" />
          </el-select>
        </el-form-item>
        <el-form-item label="流转原因">
          <el-input v-model="flowForm.reason" type="textarea" :rows="3" placeholder="不少于 5 个字" />
        </el-form-item>
      </el-form>
      <div v-if="batchResult.length" class="batch-result">
        <div v-for="(r, i) in batchResult" :key="i" :class="r.ok ? 'ok' : 'bad'">
          {{ r.ok ? '✓' : '✗' }} {{ r.id }} {{ r.message }}
        </div>
      </div>
      <template #footer>
        <el-button @click="batchDialog = false">关闭</el-button>
        <el-button type="primary" :loading="saving" @click="doBatch">确认批量流转</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { computed, onMounted, reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import StatusTag from '../components/StatusTag.vue'
import UploadField from '../components/UploadField.vue'
import { appApi, baseApi, systemApi } from '../api'
import { useTable } from '../composables/useTable'
import { fmtDateTime } from '../utils/format'

/**
 * 实习备案中心：服务端分页 + 多条件筛选 + 新建 + 单条/批量状态流转。
 * 所有校验（唯一性、起止顺序、不得越级、原因必填）都由后端执行，前端只做提示。
 */
const router = useRouter()
const { rows, total, loading, page, size, query, load, search, reset, onPage, onSize } =
  useTable(appApi.page, { keyword: '', department: '', company: '', position: '', stage: '', reportStatus: '', startDate: '', endDate: '' })

const range = ref([])
const stages = ref([])
const colleges = ref([])
const companies = ref([])
const selected = ref([])
const quick = ref('')
const cases = ['待提交', '待批阅', '已批阅', '已退修', '逾期']
const reportStatuses = cases

const createOpen = ref(false)
const flowOpen = ref(false)
const batchDialog = ref(false)
const saving = ref(false)
const current = ref(null)
const batchResult = ref([])
const formRef = ref()

const emptyForm = () => ({
  internshipNo: '', studentName: '', studentNo: '', major: '', companyName: '', position: '',
  teacherName: '', mentorName: '', startDate: '', endDate: '', source: '集中实习',
  stage: '实习备案', reportStatus: '待提交', agreementFile: '', insuranceFile: ''
})
const form = reactive(emptyForm())
const rules = {
  internshipNo: [{ required: true, message: '请填写实习编号', trigger: 'blur' }],
  studentName: [{ required: true, message: '请填写学生姓名', trigger: 'blur' }],
  companyName: [{ required: true, message: '请选择实习企业', trigger: 'change' }],
  position: [{ required: true, message: '请填写岗位', trigger: 'blur' }],
  teacherName: [{ required: true, message: '请填写校内导师', trigger: 'blur' }],
  mentorName: [{ required: true, message: '请填写企业导师', trigger: 'blur' }],
  startDate: [{ required: true, message: '请选择开始日期', trigger: 'change' }],
  endDate: [{ required: true, message: '请选择结束日期', trigger: 'change' }]
}
const flowForm = reactive({ targetStage: '协议审核', reason: '' })

const inProgress = computed(() => rows.value.filter((r) => r.stage === '实习中' || r.stage === '过程周报').length)
const pendingReport = computed(() => rows.value.filter((r) => r.reportStatus === '待批阅').length)

function go(row) {
  router.push(`/application/${row.id}`)
}

function applyQuick() {
  query.stage = quick.value
  search()
}

function resetAll() {
  range.value = []
  query.startDate = ''
  query.endDate = ''
  quick.value = ''
  reset()
}

function openCreate() {
  Object.assign(form, emptyForm())
  createOpen.value = true
}

async function confirmClose(done) {
  const touched = form.studentName || form.companyName || form.position
  if (!touched) return done()
  try {
    await ElMessageBox.confirm('表单有未保存内容，确认关闭吗？', '未保存提醒', { type: 'warning' })
    done()
  } catch (e) { /* 留在抽屉 */ }
}

async function save() {
  try { await formRef.value.validate() } catch (e) { return }
  saving.value = true
  try {
    await appApi.create({ ...form })
    ElMessage.success('备案已提交，等待教师审核')
    createOpen.value = false
    load()
  } catch (e) { /* 已提示 */ } finally { saving.value = false }
}

function openFlow(row) {
  current.value = row
  flowForm.targetStage = nextStage(row.stage)
  flowForm.reason = ''
  flowOpen.value = true
}

function nextStage(s) {
  const order = ['实习备案', '协议审核', '过程周报', '阶段检查', '企业评价', '学校归档']
  const i = order.indexOf(s)
  return i >= 0 && i < order.length - 1 ? order[i + 1] : '已中止'
}

async function doFlow() {
  if (flowForm.reason.trim().length < 5) return ElMessage.warning('请填写不少于 5 个字的流转原因')
  saving.value = true
  try {
    await appApi.transition(current.value.id, { ...flowForm })
    ElMessage.success('流转成功')
    flowOpen.value = false
    load()
  } catch (e) { /* 已提示 */ } finally { saving.value = false }
}

async function doBatch() {
  if (flowForm.reason.trim().length < 5) return ElMessage.warning('请填写不少于 5 个字的流转原因')
  saving.value = true
  batchResult.value = []
  try {
    const res = await appApi.batchTransition({
      ids: selected.value.map((r) => r.id),
      targetStage: flowForm.targetStage,
      reason: flowForm.reason
    })
    batchResult.value = (res || []).map((r) => ({ id: r.id || r.internshipNo, ok: r.ok !== false, message: r.message || '成功' }))
    const okCount = batchResult.value.filter((r) => r.ok).length
    ElMessage.success(`成功 ${okCount} 条，失败 ${batchResult.value.length - okCount} 条`)
    load()
  } catch (e) { /* 已提示 */ } finally { saving.value = false }
}

/** 导出当前筛选结果：按筛选条件再取一次全量，生成 CSV */
async function exportCsv() {
  const data = await appApi.page({ page: 1, size: 999, ...cleanQuery() })
  const head = ['实习编号', '学生', '学号', '专业', '企业', '岗位', '校内导师', '企业导师', '阶段', '周报状态', '开始日期', '结束日期']
  const lines = [head.join(',')]
  ;(data.records || []).forEach((r) => {
    lines.push([r.internshipNo, r.studentName, r.studentNo, r.major, r.companyName, r.position,
      r.teacherName, r.mentorName, r.stage, r.reportStatus, r.startDate, r.endDate].join(','))
  })
  const blob = new Blob(['\ufeff' + lines.join('\n')], { type: 'text/csv;charset=utf-8' })
  const a = document.createElement('a')
  a.href = URL.createObjectURL(blob)
  a.download = `实习档案_${new Date().toISOString().slice(0, 10)}.csv`
  a.click()
  URL.revokeObjectURL(a.href)
  ElMessage.success(`已导出 ${data.records.length} 条记录`)
}

function cleanQuery() {
  const out = {}
  Object.entries(query).forEach(([k, v]) => { if (v !== '' && v != null) out[k] = v })
  return out
}

onMounted(async () => {
  const [opt, orgs, comp] = await Promise.all([appApi.options(), systemApi.orgs(), baseApi.companyOptions()])
  stages.value = (opt && opt.stages) || []
  colleges.value = (orgs || []).filter((o) => o.orgType === '学院')
  companies.value = comp || []
  load()
})
</script>

<style scoped>
.summary {
  display: flex; align-items: center; gap: 26px; background: #fff; border: 1px solid var(--line);
  border-radius: var(--radius); padding: 12px 18px; margin-bottom: 14px;
}
.s-item span { font-size: 12px; color: var(--text-2); margin-right: 6px; }
.s-item b { font-size: 17px; color: var(--primary); font-variant-numeric: tabular-nums; }
.summary .spacer { flex: 1; }
.no { color: var(--accent); font-variant-numeric: tabular-nums; }
.flow-box .flow-head { display: flex; align-items: center; gap: 10px; font-size: 15px; margin-bottom: 4px; }
.batch-result { margin-top: 10px; max-height: 160px; overflow: auto; font-size: 12.5px; }
.batch-result .ok { color: var(--success); }
.batch-result .bad { color: var(--danger); }
</style>
