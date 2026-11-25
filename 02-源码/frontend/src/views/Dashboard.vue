<template>
  <div class="dash">
    <!-- 6 个核心指标 + 6 个图表，1440×900 一屏内 -->
    <div class="stat-grid">
      <div class="stat" v-for="s in kpis" :key="s.label">
        <div class="label">{{ s.label }}</div>
        <div class="value">{{ s.value }}<small v-if="s.unit">{{ s.unit }}</small></div>
        <div class="muted">{{ s.hint }}</div>
      </div>
    </div>

    <div class="todo-strip">
      <span class="tt">我的待办</span>
      <a @click="$router.push('/application')">待审实习档案 <b>{{ todo.apps || 0 }}</b></a>
      <a @click="$router.push('/review')">待批阅周报 <b>{{ todo.reports || 0 }}</b></a>
      <a @click="$router.push('/change')">待审批变更 <b>{{ todo.changes || 0 }}</b></a>
      <a @click="$router.push('/issue')">待处置异常 <b>{{ todo.issues || 0 }}</b></a>
      <span class="spacer"></span>
      <span class="muted">数据截至 {{ fmtDateTime(now) }}</span>
    </div>

    <div class="grid">
      <div class="card">
        <div class="card-title">实习人数月度趋势 <span class="sub">近 6 个月新增备案</span></div>
        <ChartBox :option="lineOpt" :height="196" />
      </div>
      <div class="card">
        <div class="card-title">实习阶段分布 <span class="sub">当前在库档案</span></div>
        <ChartBox :option="stageOpt" :height="196" />
      </div>
      <div class="card">
        <div class="card-title">周报按时提交率 <span class="sub">按周次</span></div>
        <ChartBox :option="weekOpt" :height="196" />
      </div>
      <div class="card">
        <div class="card-title">行业分布 <span class="sub">接收企业所属行业</span></div>
        <ChartBox :option="industryOpt" :height="196" />
      </div>
      <div class="card">
        <div class="card-title">实习成绩分布 <span class="sub">结项总评等级</span></div>
        <ChartBox :option="scoreOpt" :height="196" />
      </div>
      <div class="card">
        <div class="card-title">岗位类型分布 <span class="sub">实习岗位归类</span></div>
        <ChartBox :option="positionOpt" :height="196" />
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue'
import ChartBox from '../components/ChartBox.vue'
import { dashboardApi } from '../api'
import { fmtDateTime, fmtNum } from '../utils/format'

/**
 * 工作台：指标 + 图表全部由后端聚合（/api/dashboard），前端不做二次全表统计。
 * 图表点击后跳到对应明细列表，统计值与列表总数保持一致。
 */
const data = ref({ kpi: {}, charts: {} })
const todo = ref({})
const now = ref(new Date())

const kpi = computed(() => data.value.kpi || {})
const charts = computed(() => data.value.charts || {})

const kpis = computed(() => [
  { label: '在册实习人数', value: kpi.value.students ?? '-', unit: '人', hint: '全部有效档案' },
  { label: '周报提交率', value: fmtNum(kpi.value.reportRate, 1), unit: '%', hint: '近 8 周累计' },
  { label: '批阅及时率', value: fmtNum(kpi.value.reviewRate, 1), unit: '%', hint: '48 小时内批阅' },
  { label: '里程碑完成率', value: fmtNum(kpi.value.milestoneRate, 1), unit: '%', hint: '阶段任务达成' },
  { label: '异常实习数', value: kpi.value.abnormal ?? '-', unit: '例', hint: '在处置异常上报' },
  { label: '企业平均评分', value: fmtNum(kpi.value.companyScore, 2), unit: '分', hint: '满分 5 分' }
])

const base = { grid: { left: 8, right: 12, top: 16, bottom: 4, containLabel: true }, tooltip: { trigger: 'axis' } }

const lineOpt = computed(() => {
  const c = charts.value.monthlyTrend || { labels: [], values: [] }
  return {
    ...base,
    xAxis: { type: 'category', data: c.labels, axisLine: { lineStyle: { color: '#DCE7E0' } }, axisLabel: { color: '#63736B', fontSize: 11 } },
    yAxis: { type: 'value', splitLine: { lineStyle: { color: '#EEF5F0' } }, axisLabel: { color: '#63736B', fontSize: 11 } },
    series: [{
      type: 'line', data: c.values, smooth: true, symbolSize: 6,
      lineStyle: { width: 2.5 }, areaStyle: { color: 'rgba(58,125,90,.14)' }
    }]
  }
})

const stageOpt = computed(() => {
  const c = charts.value.stageDist || { labels: [], values: [] }
  return {
    tooltip: { trigger: 'item' },
    legend: { bottom: 0, itemWidth: 8, itemHeight: 8, textStyle: { fontSize: 11, color: '#63736B' } },
    series: [{
      type: 'pie', radius: ['42%', '66%'], center: ['50%', '44%'], avoidLabelOverlap: true,
      label: { show: false }, data: c.labels.map((l, i) => ({ name: l, value: c.values[i] }))
    }]
  }
})

const weekOpt = computed(() => {
  const c = charts.value.reportWeekly || { labels: [], values: [] }
  return {
    ...base,
    xAxis: { type: 'category', data: c.labels, axisLabel: { color: '#63736B', fontSize: 11 }, axisLine: { lineStyle: { color: '#DCE7E0' } } },
    yAxis: { type: 'value', max: 100, splitLine: { lineStyle: { color: '#EEF5F0' } }, axisLabel: { color: '#63736B', fontSize: 11, formatter: '{value}%' } },
    series: [{ type: 'bar', data: c.values, barWidth: 14, itemStyle: { borderRadius: [3, 3, 0, 0], color: '#3A7D5A' } }]
  }
})

const industryOpt = computed(() => {
  const c = charts.value.industryDist || { labels: [], values: [] }
  return {
    ...base,
    xAxis: { type: 'category', data: c.labels, axisLabel: { color: '#63736B', fontSize: 11, interval: 0 }, axisLine: { lineStyle: { color: '#DCE7E0' } } },
    yAxis: { type: 'value', splitLine: { lineStyle: { color: '#EEF5F0' } }, axisLabel: { color: '#63736B', fontSize: 11 } },
    series: [{ type: 'bar', data: c.values, barWidth: 18, itemStyle: { borderRadius: [3, 3, 0, 0], color: '#234E3B' } }]
  }
})

const scoreOpt = computed(() => {
  const c = charts.value.scoreDist || { labels: [], values: [] }
  return {
    tooltip: { trigger: 'item' },
    legend: { bottom: 0, itemWidth: 8, itemHeight: 8, textStyle: { fontSize: 11, color: '#63736B' } },
    series: [{
      type: 'pie', radius: ['46%', '70%'], center: ['50%', '44%'], label: { show: false },
      data: c.labels.map((l, i) => ({ name: l, value: c.values[i] })),
      color: ['#234E3B', '#3A7D5A', '#9DB8A8', '#B7791F']
    }]
  }
})

const positionOpt = computed(() => {
  const c = charts.value.positionDist || { labels: [], values: [] }
  return {
    ...base,
    xAxis: { type: 'value', splitLine: { lineStyle: { color: '#EEF5F0' } }, axisLabel: { color: '#63736B', fontSize: 11 } },
    yAxis: { type: 'category', data: c.labels, axisLabel: { color: '#63736B', fontSize: 11 }, axisLine: { lineStyle: { color: '#DCE7E0' } } },
    series: [{ type: 'bar', data: c.values, barWidth: 12, itemStyle: { borderRadius: [0, 3, 3, 0], color: '#315F4C' } }]
  }
})

onMounted(async () => {
  const [main, td] = await Promise.all([dashboardApi.main(), dashboardApi.todo()])
  data.value = main || {}
  todo.value = td || {}
  now.value = new Date()
})
</script>

<style scoped>
.dash { padding: 18px 24px 24px; }
.stat-grid { grid-template-columns: repeat(6, 1fr); }
.stat { padding: 12px 14px; }
.stat .value { font-size: 22px; margin-top: 4px; }

.todo-strip {
  display: flex; align-items: center; gap: 18px; background: #fff; border: 1px solid var(--line);
  border-radius: var(--radius); padding: 10px 16px; margin: 12px 0; font-size: 13px;
}
.todo-strip .tt { font-weight: 600; color: var(--primary); }
.todo-strip a { color: var(--text); cursor: pointer; }
.todo-strip a b { color: var(--primary); font-variant-numeric: tabular-nums; margin-left: 2px; }
.todo-strip .spacer { flex: 1; }

.grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 14px; }
.grid .card { padding: 12px 14px 6px; }
.grid .card-title { font-size: 13.5px; margin-bottom: 4px; }
</style>
