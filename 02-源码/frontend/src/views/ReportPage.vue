<template>
  <div class="page">
    <div class="card">
      <div class="card-title">
        周报工作台
        <span class="sub">按待本人处理优先、提交时间倒序排列</span>
        <el-button type="primary" @click="openCreate">提交周报</el-button>
      </div>

      <div class="toolbar">
        <div class="tabs">
          <el-radio-group v-model="query.status" size="small" @change="search">
            <el-radio-button label="">全部</el-radio-button>
            <el-radio-button label="待提交">待提交</el-radio-button>
            <el-radio-button label="待批阅">待批阅</el-radio-button>
            <el-radio-button label="已批阅">已批阅</el-radio-button>
            <el-radio-button label="已退修">已退修</el-radio-button>
            <el-radio-button label="逾期">逾期</el-radio-button>
          </el-radio-group>
        </div>
        <div class="search">
          <el-input v-model="query.keyword" placeholder="周报编号 / 学生" clearable style="width: 220px" @keyup.enter="search" />
          <el-button @click="search">查询</el-button>
        </div>
      </div>

      <el-table :data="rows" v-loading="loading" border stripe>
        <el-table-column prop="reportNo" label="周报编号" min-width="150" />
        <el-table-column prop="internshipNo" label="实习编号" min-width="128" />
        <el-table-column prop="studentName" label="学生" min-width="90" />
        <el-table-column label="周次" min-width="80">
          <template #default="{ row }">第 {{ row.weekNo }} 周</template>
        </el-table-column>
        <el-table-column label="周期" min-width="180">
          <template #default="{ row }"><span class="num">{{ row.weekStart }} ~ {{ row.weekEnd }}</span></template>
        </el-table-column>
        <el-table-column prop="taskContent" label="本周任务" min-width="260" show-overflow-tooltip />
        <el-table-column prop="status" label="状态" min-width="90">
          <template #default="{ row }"><StatusTag :value="row.status" /></template>
        </el-table-column>
        <el-table-column label="提交时间" min-width="160">
          <template #default="{ row }"><span class="num">{{ fmtDateTime(row.submitTime) }}</span></template>
        </el-table-column>
        <el-table-column label="截止时间" min-width="160">
          <template #default="{ row }"><span class="num">{{ fmtDateTime(row.deadline) }}</span></template>
        </el-table-column>
        <el-table-column prop="reviewScore" label="批阅得分" min-width="92">
          <template #default="{ row }"><span class="num">{{ row.reviewScore ?? '-' }}</span></template>
        </el-table-column>
        <el-table-column label="操作" min-width="120" fixed="right">
          <template #default="{ row }">
            <el-button link type="primary" @click="openDetail(row)">查看</el-button>
            <el-button v-if="row.status === '已退修' || row.status === '待提交'" link type="primary" @click="openCreate(row)">重新提交</el-button>
          </template>
        </el-table-column>
      </el-table>

      <div class="pager">
        <el-pagination background layout="total, sizes, prev, pager, next, jumper"
          :total="total" :current-page="page" :page-size="size" :page-sizes="[10, 20, 50]"
          @current-change="onPage" @size-change="onSize" />
      </div>
    </div>

    <!-- 提交周报：富文本限制字数与图片数，附件走上传组件 -->
    <el-drawer v-model="createOpen" title="提交周报" size="600px">
      <el-form ref="formRef" :model="form" :rules="rules" label-width="100px">
        <el-form-item label="实习档案" prop="applicationId">
          <el-select v-model="form.applicationId" filterable style="width: 100%" placeholder="选择本人实习档案">
            <el-option v-for="a in myApps" :key="a.id" :label="`${a.internshipNo} · ${a.companyName}`" :value="a.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="周次" prop="weekNo">
          <el-input-number v-model="form.weekNo" :min="1" :max="30" />
          <span class="muted" style="margin-left: 10px">系统按周次与档案校验是否重复提交</span>
        </el-form-item>
        <el-form-item label="周期" prop="weekStart">
          <el-date-picker v-model="form.weekStart" type="date" value-format="YYYY-MM-DD" placeholder="周一" style="width: 46%" />
          <el-date-picker v-model="form.weekEnd" type="date" value-format="YYYY-MM-DD" placeholder="周日" style="width: 46%; margin-left: 8px" />
        </el-form-item>
        <el-form-item label="本周任务" prop="taskContent">
          <el-input v-model="form.taskContent" type="textarea" :rows="3" maxlength="300" show-word-limit placeholder="具体做了哪些事，对应哪个里程碑" />
        </el-form-item>
        <el-form-item label="学习收获">
          <el-input v-model="form.harvest" type="textarea" :rows="3" maxlength="300" show-word-limit />
        </el-form-item>
        <el-form-item label="遇到问题">
          <el-input v-model="form.problem" type="textarea" :rows="2" maxlength="200" show-word-limit />
        </el-form-item>
        <el-form-item label="下周计划">
          <el-input v-model="form.nextPlan" type="textarea" :rows="2" maxlength="200" show-word-limit />
        </el-form-item>
        <el-form-item label="本周图片">
          <UploadField v-model="form.attachmentImage" biz-type="report" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="createOpen = false">取消</el-button>
        <el-button type="primary" :loading="saving" @click="save">提交周报</el-button>
      </template>
    </el-drawer>

    <el-dialog v-model="detailOpen" title="周报详情" width="640px">
      <template v-if="cur">
        <div class="d-head">
          <b>{{ cur.reportNo }}</b>
          <StatusTag :value="cur.status" />
          <span class="muted">第 {{ cur.weekNo }} 周 · {{ cur.weekStart }} ~ {{ cur.weekEnd }}</span>
        </div>
        <div class="d-sec"><label>本周任务</label><p>{{ cur.taskContent || '-' }}</p></div>
        <div class="d-sec"><label>学习收获</label><p>{{ cur.harvest || '-' }}</p></div>
        <div class="d-sec"><label>遇到问题</label><p>{{ cur.problem || '-' }}</p></div>
        <div class="d-sec"><label>下周计划</label><p>{{ cur.nextPlan || '-' }}</p></div>
        <div class="d-sec" v-if="cur.attachmentImage">
          <label>本周图片</label><img class="big" :src="cur.attachmentImage" alt="周报图片" />
        </div>
        <div class="d-sec" v-if="cur.reviewComment">
          <label>批阅意见</label><p>{{ cur.reviewComment }}（{{ cur.reviewerName }} · {{ fmtDateTime(cur.reviewTime) }}）</p>
        </div>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { onMounted, reactive, ref } from 'vue'
import { ElMessage } from 'element-plus'
import StatusTag from '../components/StatusTag.vue'
import UploadField from '../components/UploadField.vue'
import { appApi, reportApi } from '../api'
import { useTable } from '../composables/useTable'
import { fmtDateTime } from '../utils/format'

/**
 * 周报工作台：学生提交/重提，教师与管理员查看。
 * 重复提交校验（同一周次上一版未批阅不得再提交）由后端负责。
 */
const { rows, total, loading, page, size, query, load, search, onPage, onSize } =
  useTable(reportApi.page, { status: '', keyword: '' })

const myApps = ref([])
const createOpen = ref(false)
const detailOpen = ref(false)
const saving = ref(false)
const cur = ref(null)
const formRef = ref()

const form = reactive({
  applicationId: null, weekNo: 1, weekStart: '', weekEnd: '',
  taskContent: '', harvest: '', problem: '', nextPlan: '', attachmentImage: ''
})
const rules = {
  applicationId: [{ required: true, message: '请选择实习档案', trigger: 'change' }],
  weekStart: [{ required: true, message: '请选择周期开始日期', trigger: 'change' }],
  taskContent: [{ required: true, message: '请填写本周任务', trigger: 'blur' }]
}

function openCreate(row) {
  Object.assign(form, {
    applicationId: row ? row.applicationId : (myApps.value[0] && myApps.value[0].id) || null,
    weekNo: row ? row.weekNo : 1, weekStart: row ? row.weekStart : '', weekEnd: row ? row.weekEnd : '',
    taskContent: row ? row.taskContent : '', harvest: '', problem: '', nextPlan: '', attachmentImage: ''
  })
  createOpen.value = true
}

function openDetail(row) {
  cur.value = row
  detailOpen.value = true
}

async function save() {
  try { await formRef.value.validate() } catch (e) { return }
  saving.value = true
  try {
    await reportApi.save({ ...form, status: '待批阅' })
    ElMessage.success('周报已提交，等待导师批阅')
    createOpen.value = false
    load()
  } catch (e) { /* 已提示 */ } finally { saving.value = false }
}

onMounted(async () => {
  load()
  const data = await appApi.page({ page: 1, size: 100 })
  myApps.value = data.records || []
})
</script>

<style scoped>
.search { display: flex; gap: 8px; }
.card-title .el-button { margin-left: auto; }
.d-head { display: flex; align-items: center; gap: 10px; margin-bottom: 14px; font-size: 14px; }
.d-sec { margin-bottom: 12px; }
.d-sec label { display: block; font-size: 12px; color: var(--text-2); margin-bottom: 4px; }
.d-sec p { margin: 0; font-size: 13px; line-height: 1.8; background: #f8fbf9; padding: 8px 12px; border-radius: 6px; }
.d-sec .big { max-width: 100%; border-radius: 6px; border: 1px solid var(--line); }
</style>
