<template>
  <div class="page" v-loading="loading">
    <div class="head" v-if="d.id">
      <div class="head-main">
        <div class="line1">
          <h2>{{ d.internshipNo }}</h2>
          <StatusTag :value="d.stage" />
          <el-tag size="small" type="info">周报：{{ d.reportStatus }}</el-tag>
        </div>
        <div class="line2">
          <span>{{ d.studentName }}（{{ d.studentNo }}）</span>
          <span>{{ d.major }} · {{ d.grade }}</span>
          <span>{{ d.companyName }} · {{ d.position }}</span>
        </div>
      </div>
      <div class="head-meta">
        <div>校内导师：{{ d.teacherName }}</div>
        <div>企业导师：{{ d.mentorName }}</div>
        <div class="muted">创建 {{ fmtDateTime(d.createTime) }} · 更新 {{ fmtDateTime(d.updateTime) }}</div>
      </div>
      <div class="head-ops">
        <el-button type="primary" @click="openFlow">状态流转</el-button>
        <el-button @click="$router.push('/milestone')">里程碑检查</el-button>
        <el-button @click="back">返回列表</el-button>
      </div>
    </div>

    <div class="cols">
      <div class="left">
        <div class="card">
          <div class="card-title">基础信息</div>
          <div class="kv">
            <div v-for="i in info" :key="i.k"><label>{{ i.k }}</label><span>{{ i.v || '-' }}</span></div>
          </div>
        </div>

        <div class="card">
          <div class="card-title">里程碑进度 <span class="sub">共 {{ d.milestones?.length || 0 }} 个阶段任务</span></div>
          <el-table :data="d.milestones || []" border size="small">
            <el-table-column prop="seqNo" label="序" min-width="52" />
            <el-table-column prop="milestoneName" label="里程碑" min-width="150" />
            <el-table-column prop="planWeek" label="计划周" min-width="80" />
            <el-table-column prop="status" label="状态" min-width="90">
              <template #default="{ row }"><StatusTag :value="row.status" /></template>
            </el-table-column>
            <el-table-column prop="finishDate" label="完成日期" min-width="110" />
          </el-table>
        </div>

        <div class="card">
          <div class="card-title">关联周报（最近 6 条）</div>
          <el-table :data="d.reports || []" border size="small">
            <el-table-column prop="reportNo" label="周报编号" min-width="150" />
            <el-table-column prop="weekNo" label="周次" min-width="70">
              <template #default="{ row }">第 {{ row.weekNo }} 周</template>
            </el-table-column>
            <el-table-column prop="status" label="状态" min-width="90">
              <template #default="{ row }"><StatusTag :value="row.status" /></template>
            </el-table-column>
            <el-table-column label="提交时间" min-width="160">
              <template #default="{ row }">{{ fmtDateTime(row.submitTime) }}</template>
            </el-table-column>
          </el-table>
          <div v-if="!(d.reports || []).length" class="empty-hint">该档案暂无周报记录，学生提交后在此展示</div>
        </div>

        <div class="card">
          <div class="card-title">操作时间轴 <span class="sub">事件不可修改</span></div>
          <div v-for="(t, i) in d.timeline || []" :key="i" class="timeline-item">
            <div class="t">{{ fmtDateTime(t.time) }} · {{ t.actor || '系统' }}</div>
            <div class="c"><b>{{ t.title }}</b></div>
            <div class="muted">{{ t.remark || '-' }}</div>
          </div>
        </div>
      </div>

      <div class="right">
        <div class="card">
          <div class="card-title">协议与材料</div>
          <div class="files">
            <div class="file" v-for="f in files" :key="f.label">
              <label>{{ f.label }}</label>
              <img v-if="f.url" :src="f.url" :alt="f.label" />
              <span v-else class="muted">未上传</span>
            </div>
          </div>
        </div>

        <div class="card">
          <div class="card-title">考勤汇总</div>
          <el-table :data="d.attendances || []" size="small" border>
            <el-table-column prop="month" label="月份" min-width="86" />
            <el-table-column prop="actualDays" label="实出勤" min-width="76" />
            <el-table-column prop="lateCount" label="迟到" min-width="64" />
            <el-table-column prop="confirmStatus" label="确认" min-width="96">
              <template #default="{ row }"><StatusTag :value="row.confirmStatus" /></template>
            </el-table-column>
          </el-table>
        </div>

        <div class="card">
          <div class="card-title">变更与异常</div>
          <div class="side-item" v-for="c in d.changes || []" :key="'c' + c.id">
            <el-tag size="small" type="warning">变更</el-tag>
            <span>{{ c.changeType }}：{{ c.beforeValue }} → {{ c.afterValue }}</span>
            <StatusTag :value="c.status" />
          </div>
          <div class="side-item" v-for="i in d.issues || []" :key="'i' + i.id">
            <el-tag size="small" type="danger">异常</el-tag>
            <span>{{ i.issueType }} · {{ i.content }}</span>
            <StatusTag :value="i.status" />
          </div>
          <div v-if="!(d.changes || []).length && !(d.issues || []).length" class="empty-hint">无变更与异常记录</div>
        </div>

        <div class="card">
          <div class="card-title">结项评价</div>
          <template v-if="d.evaluation">
            <div class="kv small">
              <div><label>企业评分</label><span>{{ d.evaluation.companyScore }} / 5</span></div>
              <div><label>校内评分</label><span>{{ d.evaluation.schoolScore }} / 100</span></div>
              <div><label>周报得分</label><span>{{ d.evaluation.reportScore }}</span></div>
              <div><label>加权总评</label><span>{{ d.evaluation.totalScore }}（{{ d.evaluation.grade }}）</span></div>
            </div>
            <p class="muted">{{ d.evaluation.companyComment }}</p>
            <p class="muted">{{ d.evaluation.schoolComment }}</p>
          </template>
          <div v-else class="empty-hint">尚未形成结项评价</div>
        </div>
      </div>
    </div>

    <el-dialog v-model="flowOpen" title="状态流转" width="480px">
      <el-form label-width="90px">
        <el-form-item label="目标阶段">
          <el-select v-model="flowForm.targetStage" style="width: 100%">
            <el-option v-for="s in [...stages, '已中止']" :key="s" :label="s" :value="s" />
          </el-select>
        </el-form-item>
        <el-form-item label="流转原因">
          <el-input v-model="flowForm.reason" type="textarea" :rows="3" placeholder="不少于 5 个字" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="flowOpen = false">取消</el-button>
        <el-button type="primary" :loading="saving" @click="doFlow">确认</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { computed, onMounted, reactive, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import StatusTag from '../components/StatusTag.vue'
import { appApi } from '../api'
import { fmtDateTime } from '../utils/format'

/**
 * 档案详情：顶部固定业务编号/状态/责任人，中部基础信息与业务过程，
 * 右侧材料、考勤、变更异常、结项评价，底部时间轴。不重复拼接列表页。
 */
const route = useRoute()
const router = useRouter()
const d = ref({})
const loading = ref(false)
const stages = ref(['实习备案', '协议审核', '过程周报', '阶段检查', '企业评价', '学校归档'])
const flowOpen = ref(false)
const saving = ref(false)
const flowForm = reactive({ targetStage: '协议审核', reason: '' })

const info = computed(() => [
  { k: '实习编号', v: d.value.internshipNo },
  { k: '所属批次', v: d.value.batchNo },
  { k: '学生', v: d.value.studentName },
  { k: '学号', v: d.value.studentNo },
  { k: '专业 / 年级', v: [d.value.major, d.value.grade].filter(Boolean).join(' · ') },
  { k: '实习企业', v: d.value.companyName },
  { k: '行业 / 城市', v: [d.value.industry, d.value.city].filter(Boolean).join(' · ') },
  { k: '岗位', v: d.value.position },
  { k: '实习来源', v: d.value.source },
  { k: '实习周期', v: [d.value.startDate, d.value.endDate].filter(Boolean).join(' ~ ') },
  { k: '校外导师', v: d.value.mentorName },
  { k: '最近流转原因', v: d.value.transitionReason }
])

const files = computed(() => [
  { label: '三方协议', url: d.value.agreementFile },
  { label: '意外保险', url: d.value.insuranceFile },
  { label: '接收函', url: d.value.acceptFile }
])

function back() {
  router.push('/application')
}

function openFlow() {
  flowForm.targetStage = '协议审核'
  flowForm.reason = ''
  flowOpen.value = true
}

async function doFlow() {
  if (flowForm.reason.trim().length < 5) return ElMessage.warning('请填写不少于 5 个字的流转原因')
  saving.value = true
  try {
    await appApi.transition(d.value.id, { ...flowForm })
    ElMessage.success('流转成功')
    flowOpen.value = false
    load()
  } finally {
    saving.value = false
  }
}

async function load() {
  loading.value = true
  try {
    d.value = await appApi.detail(route.params.id)
  } finally {
    loading.value = false
  }
}

onMounted(load)
</script>

<style scoped>
.head {
  display: flex; align-items: flex-start; gap: 24px; background: #fff; border: 1px solid var(--line);
  border-radius: var(--radius); padding: 16px 20px; margin-bottom: 16px;
}
.line1 { display: flex; align-items: center; gap: 10px; }
.line1 h2 { margin: 0; font-size: 18px; color: var(--primary); font-variant-numeric: tabular-nums; }
.line2 { display: flex; gap: 18px; font-size: 13px; color: var(--text-2); margin-top: 8px; flex-wrap: wrap; }
.head-meta { font-size: 12.5px; color: var(--text); line-height: 1.9; min-width: 220px; }
.head-ops { margin-left: auto; display: flex; gap: 8px; }

.cols { display: grid; grid-template-columns: minmax(0, 1.55fr) minmax(0, 1fr); gap: 16px; }
.left > .card, .right > .card { margin-bottom: 16px; }

.kv { display: grid; grid-template-columns: repeat(2, 1fr); gap: 10px 24px; }
.kv > div { display: flex; gap: 10px; font-size: 13px; }
.kv label { color: var(--text-2); min-width: 84px; }
.kv.small { grid-template-columns: repeat(2, 1fr); font-size: 12.5px; }

.files { display: flex; gap: 14px; flex-wrap: wrap; }
.files .file { font-size: 12px; color: var(--text-2); }
.files img { width: 128px; height: 90px; object-fit: cover; border-radius: 6px; border: 1px solid var(--line); display: block; margin-top: 6px; }

.side-item { display: flex; align-items: center; gap: 8px; font-size: 12.5px; padding: 6px 0; border-bottom: 1px dashed var(--line); }
</style>
