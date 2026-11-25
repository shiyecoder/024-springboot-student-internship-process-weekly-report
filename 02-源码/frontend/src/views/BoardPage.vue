<template>
  <div class="page">
    <!-- 实习质量看板：6 个指标 + 6 个图表，一屏可读；点击图形回到明细 -->
    <div class="stat-grid">
      <div class="stat" v-for="s in kpis" :key="s.label">
        <div class="label">{{ s.label }}</div>
        <div class="value">{{ s.value }}<small v-if="s.unit">{{ s.unit }}</small></div>
        <div class="muted">{{ s.hint }}</div>
      </div>
    </div>

    <div class="grid">
      <div class="card"><div class="card-title">实习城市分布</div><ChartBox :option="opt('cityDist', 'bar')" :height="210" /></div>
      <div class="card"><div class="card-title">企业评分区间</div><ChartBox :option="opt('companyScoreRange', 'bar')" :height="210" /></div>
      <div class="card"><div class="card-title">异常类型分布</div><ChartBox :option="optPie('issueType')" :height="210" /></div>
      <div class="card"><div class="card-title">实习成绩等级</div><ChartBox :option="optPie('gradeDist')" :height="210" /></div>
      <div class="card"><div class="card-title">行业分布</div><ChartBox :option="opt('industryDist', 'bar')" :height="210" /></div>
      <div class="card"><div class="card-title">创新结果分布 <span class="sub">周报里程碑完整度</span></div><ChartBox :option="scoreOpt" :height="210" /></div>
    </div>

    <div class="card extra">
      <div class="card-title">运营指标 <span class="sub">衡量创新模块与流程执行效果</span></div>
      <div class="extra-grid">
        <div><label>变更率</label><b>{{ fmtNum(extra.changeRate, 1) }}%</b></div>
        <div><label>推荐采纳率</label><b>{{ fmtNum(extra.adoptRate, 1) }}%</b></div>
        <div><label>人工调整率</label><b>{{ fmtNum(extra.adjustRate, 1) }}%</b></div>
        <div><label>批阅及时率</label><b>{{ fmtNum(extra.reviewOnTimeRate, 1) }}%</b></div>
        <div><label>平均总评分</label><b>{{ fmtNum(extra.avgTotalScore, 1) }}</b></div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import ChartBox from '../components/ChartBox.vue'
import { dashboardApi, scoreApi } from '../api'
import { fmtNum } from '../utils/format'

/**
 * 统计看板：图表数据全部由 /api/dashboard/board 聚合，前端不做二次统计。
 * 统计值与明细列表总数一致（同一套筛选条件）。
 */
const router = useRouter()
const data = ref({ kpi: {}, charts: {}, extra: {} })
const scoreStats = ref({})

const kpi = computed(() => data.value.kpi || {})
const charts = computed(() => data.value.charts || {})
const extra = computed(() => data.value.extra || {})

const kpis = computed(() => [
  { label: '实习人数', value: kpi.value.students ?? '-', unit: '人', hint: '在册有效档案' },
  { label: '周报提交率', value: fmtNum(kpi.value.reportRate, 1), unit: '%', hint: '近 8 周' },
  { label: '批阅及时率', value: fmtNum(kpi.value.reviewRate, 1), unit: '%', hint: '48 小时内' },
  { label: '里程碑完成率', value: fmtNum(kpi.value.milestoneRate, 1), unit: '%', hint: '阶段任务' },
  { label: '异常实习数', value: kpi.value.abnormal ?? '-', unit: '例', hint: '处置中' },
  { label: '企业评分', value: fmtNum(kpi.value.companyScore, 2), unit: '分', hint: '满分 5' }
])

function pick(key) {
  const c = charts.value[key] || { labels: [], values: [] }
  return c
}

function opt(key, type) {
  const c = pick(key)
  return {
    grid: { left: 8, right: 12, top: 18, bottom: 4, containLabel: true },
    tooltip: { trigger: 'axis' },
    xAxis: { type: 'category', data: c.labels, axisLabel: { color: '#63736B', fontSize: 11, interval: 0 }, axisLine: { lineStyle: { color: '#DCE7E0' } } },
    yAxis: { type: 'value', splitLine: { lineStyle: { color: '#EEF5F0' } }, axisLabel: { color: '#63736B', fontSize: 11 } },
    series: [{ type, data: c.values, barWidth: 16, itemStyle: { borderRadius: [3, 3, 0, 0], color: '#3A7D5A' } }]
  }
}

function optPie(key) {
  const c = pick(key)
  return {
    tooltip: { trigger: 'item' },
    legend: { bottom: 0, itemWidth: 8, itemHeight: 8, textStyle: { fontSize: 11, color: '#63736B' } },
    series: [{ type: 'pie', radius: ['42%', '66%'], center: ['50%', '42%'], label: { show: false }, data: c.labels.map((l, i) => ({ name: l, value: c.values[i] })) }]
  }
}

const scoreOpt = computed(() => {
  const dist = (scoreStats.value && scoreStats.value.distribution) || {}
  return {
    tooltip: { trigger: 'item' },
    legend: { bottom: 0, itemWidth: 8, itemHeight: 8, textStyle: { fontSize: 11, color: '#63736B' } },
    series: [{
      type: 'pie', radius: ['42%', '66%'], center: ['50%', '42%'], label: { show: false },
      data: Object.entries(dist).map(([k, v]) => ({ name: k, value: v })),
      color: ['#234E3B', '#3A7D5A', '#9DB8A8', '#B7791F']
    }]
  }
})

onMounted(async () => {
  const [b, s] = await Promise.all([dashboardApi.board(), scoreApi.stats()])
  data.value = b || {}
  scoreStats.value = s || {}
})
</script>

<style scoped>
.stat-grid { grid-template-columns: repeat(6, 1fr); margin-bottom: 14px; }
.grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 14px; }
.extra { margin-top: 14px; }
.extra-grid { display: grid; grid-template-columns: repeat(5, 1fr); gap: 12px; }
.extra-grid label { display: block; font-size: 12px; color: var(--text-2); }
.extra-grid b { font-size: 20px; color: var(--primary); font-variant-numeric: tabular-nums; }
</style>
