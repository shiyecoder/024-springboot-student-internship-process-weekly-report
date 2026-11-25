<template>
  <div class="page">
    <!-- 创新点：周报里程碑完整度检查 —— 输入依据 / 计算结果 / 等级说明 / 人工调整 -->
    <div class="card head-card">
      <div class="left">
        <h2>周报里程碑完整度检查</h2>
        <p class="muted">
          按当前生效规则版本 <b>{{ rule.version || '-' }}</b> 计算：里程碑完成项 {{ rule.weightMilestone }}% ·
          周报连续性 {{ rule.weightContinuity }}% · 附件数量 {{ rule.weightAttachment }}% ·
          导师反馈 {{ rule.weightFeedback }}% · 延期任务 {{ rule.weightDelay }}% · 企业评价 {{ rule.weightCompany }}%
        </p>
      </div>
      <div class="right">
        <el-select v-model="appId" filterable placeholder="选择实习档案" style="width: 280px" @change="loadAll">
          <el-option v-for="a in apps" :key="a.id" :label="`${a.internshipNo} · ${a.studentName}`" :value="a.id" />
        </el-select>
        <el-button type="primary" :loading="calculating" @click="evaluate">执行计算</el-button>
        <el-button @click="$router.push('/rule')">规则配置</el-button>
      </div>
    </div>

    <div class="grid">
      <div class="left-col">
        <div class="card">
          <div class="card-title">
            计算结果
            <span class="sub" v-if="latest">规则版本 {{ latest.ruleVersion }} · {{ fmtDateTime(latest.calcTime) }}</span>
          </div>
          <div v-if="latest" class="score-head">
            <div class="big">
              <div class="num">{{ latest.totalScore }}</div>
              <div class="grade">
                <el-tag :type="statusType(finalGrade)" size="large">{{ finalGrade }}</el-tag>
                <span v-if="latest.manualGrade" class="muted">（人工调整为 {{ latest.manualGrade }}，原始结果不覆盖）</span>
              </div>
            </div>
            <div class="advice">
              <div class="label">主要影响因素</div>
              <div class="chips">
                <span v-for="d in topFactors" :key="d.key" class="chip">{{ d.label }} {{ d.score }}/{{ d.weight }}</span>
              </div>
              <div class="label" style="margin-top: 10px">可改进项</div>
              <p class="muted">{{ latest.advice || '暂无建议' }}</p>
            </div>
          </div>
          <div v-else class="empty-hint">选择档案后点击「执行计算」，结果会同时保存输入快照与规则版本</div>

          <el-table v-if="latest" :data="latest.detail || []" border size="small" style="margin-top: 12px">
            <el-table-column prop="label" label="输入因素" min-width="130" />
            <el-table-column prop="value" label="实际取值" min-width="130" />
            <el-table-column prop="weight" label="权重" min-width="70">
              <template #default="{ row }">{{ row.weight }}%</template>
            </el-table-column>
            <el-table-column prop="score" label="得分" min-width="80" />
            <el-table-column prop="note" label="判定说明" min-width="220" show-overflow-tooltip />
            <el-table-column label="是否达标" min-width="96">
              <template #default="{ row }">
                <el-tag size="small" :type="row.score >= row.weight * 0.8 ? 'success' : row.score >= row.weight * 0.6 ? 'warning' : 'danger'">
                  {{ row.score >= row.weight * 0.8 ? '达标' : row.score >= row.weight * 0.6 ? '基本达标' : '未达标' }}
                </el-tag>
              </template>
            </el-table-column>
          </el-table>
        </div>

        <div class="card">
          <div class="card-title">计算留痕历史 <span class="sub">每次计算保存输入快照，相同输入与规则版本结果一致</span></div>
          <el-table :data="history" border size="small">
            <el-table-column prop="weekNo" label="周次" min-width="76">
              <template #default="{ row }">第 {{ row.weekNo }} 周</template>
            </el-table-column>
            <el-table-column prop="totalScore" label="总分" min-width="80" />
            <el-table-column prop="grade" label="系统等级" min-width="96" />
            <el-table-column prop="ruleVersion" label="规则版本" min-width="90" />
            <el-table-column label="计算时间" min-width="160">
              <template #default="{ row }">{{ fmtDateTime(row.calcTime) }}</template>
            </el-table-column>
            <el-table-column label="人工调整" min-width="150">
              <template #default="{ row }">
                <span v-if="row.manualGrade">{{ row.manualGrade }} · {{ row.manualBy }}</span>
                <span v-else class="muted">未调整</span>
              </template>
            </el-table-column>
            <el-table-column label="操作" min-width="96">
              <template #default="{ row }">
                <el-button link type="primary" @click="openAdjust(row)">人工修正</el-button>
              </template>
            </el-table-column>
          </el-table>
        </div>
      </div>

      <div class="right-col">
        <div class="card">
          <div class="card-title">等级说明</div>
          <div class="rule-line"><span>优秀</span><b>≥ {{ rule.thresholdGood }}</b></div>
          <div class="rule-line"><span>良好</span><b>≥ {{ rule.thresholdMid }} 且 &lt; {{ rule.thresholdGood }}</b></div>
          <div class="rule-line"><span>合格</span><b>&lt; {{ rule.thresholdMid }}</b></div>
          <p class="muted" style="margin-top: 10px">
            等级由系统按阈值自动判定；业务负责人可人工修正，但必须填写原因，原始得分与明细不会被覆盖。
          </p>
        </div>

        <div class="card">
          <div class="card-title">效果统计</div>
          <div class="stat-mini">
            <div><label>累计计算</label><b>{{ stats.total || 0 }}</b></div>
            <div><label>推荐采纳率</label><b>{{ fmtNum(stats.adoptRate, 1) }}%</b></div>
            <div><label>人工调整率</label><b>{{ fmtNum(stats.adjustRate, 1) }}%</b></div>
          </div>
          <ChartBox v-if="stats.distribution" :option="distOpt" :height="180" />
        </div>

        <div class="card">
          <div class="card-title">输入依据</div>
          <div class="kv">
            <div><label>里程碑</label><span>{{ msDone }}/{{ milestones.length }} 已完成</span></div>
            <div><label>延期任务</label><span>{{ msDelayed }} 项</span></div>
            <div><label>已批阅周报</label><span>{{ reviewedCount }} 篇</span></div>
            <div><label>附件数量</label><span>{{ attachCount }} 个</span></div>
          </div>
          <p class="muted" style="margin-top: 8px">数据缺失时该项不参与计算，结果页会提示补录。</p>
        </div>
      </div>
    </div>

    <el-dialog v-model="adjustOpen" title="人工修正最终结果" width="480px">
      <el-form label-width="96px">
        <el-form-item label="原始结果">
          <span class="num">{{ adjusting.totalScore }} 分 · {{ adjusting.grade }}</span>
        </el-form-item>
        <el-form-item label="修正等级">
          <el-select v-model="adjustForm.grade" style="width: 100%">
            <el-option v-for="g in ['优秀', '良好', '合格', '待改进']" :key="g" :label="g" :value="g" />
          </el-select>
        </el-form-item>
        <el-form-item label="修正原因">
          <el-input v-model="adjustForm.reason" type="textarea" :rows="3" placeholder="不少于 5 个字，会记录修正人与时间" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="adjustOpen = false">取消</el-button>
        <el-button type="primary" :loading="saving" @click="doAdjust">确认修正</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { computed, onMounted, reactive, ref } from 'vue'
import { ElMessage } from 'element-plus'
import ChartBox from '../components/ChartBox.vue'
import { appApi, scoreApi } from '../api'
import { fmtDateTime, fmtNum, statusType } from '../utils/format'

/**
 * 创新点页面：规则配置 → 计算 → 结果解释 → 人工修正 → 效果统计，形成闭环。
 * 只展示一个分数是不合格的，因此这里同时给出明细表、主要影响因素与可改进项。
 */
const apps = ref([])
const appId = ref(null)
const rule = ref({})
const latest = ref(null)
const history = ref([])
const stats = ref({})
const milestones = ref([])
const calculating = ref(false)
const saving = ref(false)
const adjustOpen = ref(false)
const adjusting = ref({})
const adjustForm = reactive({ grade: '良好', reason: '' })

const finalGrade = computed(() => (latest.value && (latest.value.manualGrade || latest.value.grade)) || '-')
const topFactors = computed(() => {
  const d = (latest.value && latest.value.detail) || []
  return [...d].sort((a, b) => b.weight - a.weight).slice(0, 4)
})
const msDone = computed(() => milestones.value.filter((m) => m.status === '已完成').length)
const msDelayed = computed(() => milestones.value.filter((m) => m.status === '已延期' || (m.delayedDays || 0) > 0).length)
const reviewedCount = computed(() => history.value.length)
const attachCount = computed(() => {
  const d = (latest.value && latest.value.detail) || []
  const a = d.find((x) => x.key === 'attachment')
  return a ? a.value : '-'
})

const distOpt = computed(() => {
  const dist = (stats.value && stats.value.distribution) || {}
  return {
    tooltip: { trigger: 'item' },
    legend: { bottom: 0, itemWidth: 8, itemHeight: 8, textStyle: { fontSize: 11, color: '#63736B' } },
    series: [{
      type: 'pie', radius: ['44%', '68%'], center: ['50%', '42%'], label: { show: false },
      data: Object.entries(dist).map(([k, v]) => ({ name: k, value: v })),
      color: ['#234E3B', '#3A7D5A', '#9DB8A8', '#B7791F']
    }]
  }
})

async function loadAll() {
  if (!appId.value) return
  const [h, l] = await Promise.all([scoreApi.history(appId.value), scoreApi.latest(appId.value).catch(() => null)])
  history.value = (h && h.records) || []
  latest.value = (h && h.latest) || l || null
  const detail = await appApi.detail(appId.value)
  milestones.value = detail.milestones || []
}

async function evaluate() {
  if (!appId.value) return ElMessage.warning('请先选择实习档案')
  calculating.value = true
  try {
    await scoreApi.evaluate(appId.value)
    ElMessage.success('已按当前规则版本完成计算，结果已留痕')
    await loadAll()
  } finally { calculating.value = false }
}

function openAdjust(row) {
  adjusting.value = row
  adjustForm.grade = row.manualGrade || row.grade
  adjustForm.reason = ''
  adjustOpen.value = true
}

async function doAdjust() {
  if (adjustForm.reason.trim().length < 5) return ElMessage.warning('请填写不少于 5 个字的修正原因')
  saving.value = true
  try {
    await scoreApi.adjust(adjusting.value.id, { ...adjustForm })
    ElMessage.success('已人工修正，原始结果保留')
    adjustOpen.value = false
    await loadAll()
  } finally { saving.value = false }
}

onMounted(async () => {
  rule.value = (await scoreApi.currentRule()) || {}
  stats.value = (await scoreApi.stats()) || {}
  const data = await appApi.page({ page: 1, size: 100 })
  apps.value = data.records || []
  // 默认选中已有批阅周报的档案，避免落到刚建的空档案上看不到计算结果
  const withData = apps.value.find((a) => a.reportStatus === '已批阅') || apps.value[0]
  if (withData) {
    appId.value = withData.id
    await loadAll()
  }
})
</script>

<style scoped>
.head-card { display: flex; align-items: center; justify-content: space-between; gap: 20px; margin-bottom: 16px; }
.head-card h2 { margin: 0 0 6px; font-size: 17px; color: var(--primary); }
.head-card .right { display: flex; gap: 10px; align-items: center; }

.grid { display: grid; grid-template-columns: minmax(0, 1.7fr) minmax(0, 1fr); gap: 16px; }
.left-col > .card, .right-col > .card { margin-bottom: 16px; }

.score-head { display: flex; gap: 26px; align-items: flex-start; }
.score-head .big .num { font-size: 44px; font-weight: 600; color: var(--primary); line-height: 1; font-variant-numeric: tabular-nums; }
.score-head .big .grade { margin-top: 10px; display: flex; flex-direction: column; gap: 6px; }
.score-head .advice { flex: 1; }
.score-head .advice .label { font-size: 12px; color: var(--text-2); margin-bottom: 6px; }
.chips { display: flex; flex-wrap: wrap; gap: 8px; }
.chip { font-size: 12px; padding: 3px 10px; border-radius: 4px; background: #eef5f0; color: var(--primary); }

.rule-line { display: flex; justify-content: space-between; font-size: 13px; padding: 8px 0; border-bottom: 1px dashed var(--line); }
.rule-line b { font-variant-numeric: tabular-nums; color: var(--primary); }
.stat-mini { display: grid; grid-template-columns: repeat(3, 1fr); gap: 10px; }
.stat-mini div { text-align: center; }
.stat-mini label { display: block; font-size: 11.5px; color: var(--text-2); }
.stat-mini b { font-size: 18px; color: var(--primary); font-variant-numeric: tabular-nums; }
.kv { display: grid; grid-template-columns: 1fr; gap: 8px; }
.kv > div { display: flex; justify-content: space-between; font-size: 12.5px; }
.kv label { color: var(--text-2); }
</style>
