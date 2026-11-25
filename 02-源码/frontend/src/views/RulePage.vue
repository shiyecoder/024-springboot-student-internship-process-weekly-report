<template>
  <div class="page">
    <div class="card">
      <div class="card-title">规则配置 · 周报里程碑完整度检查 <span class="sub">权重合计必须等于 100%，修改后记录版本与生效时间</span></div>

      <div class="rule-body">
        <el-form label-width="140px" class="form">
          <el-form-item label="规则名称"><el-input v-model="form.ruleName" /></el-form-item>
          <el-form-item v-for="w in weights" :key="w.key" :label="w.label">
            <el-slider v-model="form[w.key]" :max="60" show-input :show-input-controls="false" style="width: 420px" />
            <span class="unit">%</span>
          </el-form-item>
          <el-form-item label="优秀阈值">
            <el-input-number v-model="form.thresholdGood" :min="0" :max="100" />
            <span class="muted" style="margin-left: 10px">总分 ≥ 该值判为优秀</span>
          </el-form-item>
          <el-form-item label="合格阈值">
            <el-input-number v-model="form.thresholdMid" :min="0" :max="100" />
            <span class="muted" style="margin-left: 10px">低于该值判为合格及以下</span>
          </el-form-item>
          <el-form-item label="权重合计">
            <b :class="total === 100 ? 'ok' : 'bad'">{{ total }}%</b>
            <span class="muted" style="margin-left: 10px">{{ total === 100 ? '可以保存' : '必须调整为 100% 才能保存' }}</span>
          </el-form-item>
          <el-form-item>
            <el-button type="primary" :disabled="total !== 100" :loading="saving" @click="save">保存新版本并生效</el-button>
          </el-form-item>
        </el-form>

        <div class="side">
          <div class="side-title">当前生效规则</div>
          <div class="kv">
            <div><label>版本</label><span>{{ current.version }}</span></div>
            <div><label>生效时间</label><span>{{ fmtDateTime(current.effectiveTime) }}</span></div>
            <div><label>创建人</label><span>{{ current.createBy }}</span></div>
            <div><label>状态</label><span>{{ current.enabled ? '启用' : '停用' }}</span></div>
          </div>
          <p class="muted">修改权重后只影响新计算或主动重新计算的数据，历史留痕不回溯。</p>

          <div class="side-title" style="margin-top: 18px">历史版本</div>
          <div v-for="r in rules" :key="r.id" class="ver">
            <span class="v">{{ r.version }}</span>
            <span class="muted">{{ r.effectiveTime?.slice(0, 10) }} · 合计 {{ sumOf(r) }}%</span>
            <el-tag v-if="r.enabled" size="small" type="success">生效中</el-tag>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted, reactive, ref } from 'vue'
import { ElMessage } from 'element-plus'
import { scoreApi } from '../api'
import { fmtDateTime } from '../utils/format'

/**
 * 规则配置：六项权重之和必须等于 100，保存后生成新版本并记录生效时间。
 * 计算留痕记录规则版本，因此历史结果可复现。
 */
const weights = [
  { key: 'weightMilestone', label: '里程碑完成项' },
  { key: 'weightContinuity', label: '周报连续性' },
  { key: 'weightAttachment', label: '附件数量' },
  { key: 'weightFeedback', label: '导师反馈' },
  { key: 'weightDelay', label: '延期任务' },
  { key: 'weightCompany', label: '企业评价' }
]

const current = ref({})
const rules = ref([])
const saving = ref(false)
const form = reactive({
  ruleName: '周报里程碑完整度检查', weightMilestone: 30, weightContinuity: 20,
  weightAttachment: 15, weightFeedback: 15, weightDelay: 10, weightCompany: 10,
  thresholdGood: 80, thresholdMid: 60
})

const total = computed(() => weights.reduce((s, w) => s + Number(form[w.key] || 0), 0))
const sumOf = (r) => weights.reduce((s, w) => s + Number(r[w.key] || 0), 0)

async function load() {
  const [cur, list] = await Promise.all([scoreApi.currentRule(), scoreApi.rules()])
  current.value = cur || {}
  rules.value = list || []
  if (cur) {
    Object.assign(form, {
      ruleName: cur.ruleName, weightMilestone: cur.weightMilestone, weightContinuity: cur.weightContinuity,
      weightAttachment: cur.weightAttachment, weightFeedback: cur.weightFeedback,
      weightDelay: cur.weightDelay, weightCompany: cur.weightCompany,
      thresholdGood: cur.thresholdGood, thresholdMid: cur.thresholdMid
    })
  }
}

async function save() {
  if (total.value !== 100) return ElMessage.warning('权重合计必须等于 100%')
  saving.value = true
  try {
    await scoreApi.saveRule({ ...form })
    ElMessage.success('已生成新规则版本并生效')
    await load()
  } finally { saving.value = false }
}

onMounted(load)
</script>

<style scoped>
.rule-body { display: grid; grid-template-columns: minmax(0, 1.5fr) minmax(0, 1fr); gap: 28px; }
.unit { margin-left: 8px; color: var(--text-2); }
.ok { color: var(--success); font-size: 18px; }
.bad { color: var(--danger); font-size: 18px; }
.side { background: #f8fbf9; border: 1px solid var(--line); border-radius: 6px; padding: 16px; }
.side-title { font-size: 13px; font-weight: 600; color: var(--primary); margin-bottom: 10px; }
.side .kv { display: grid; gap: 8px; }
.side .kv > div { display: flex; justify-content: space-between; font-size: 12.5px; }
.side .kv label { color: var(--text-2); }
.ver { display: flex; align-items: center; gap: 10px; font-size: 12.5px; padding: 6px 0; border-bottom: 1px dashed var(--line); }
.ver .v { font-weight: 600; color: var(--primary); width: 34px; }
</style>
