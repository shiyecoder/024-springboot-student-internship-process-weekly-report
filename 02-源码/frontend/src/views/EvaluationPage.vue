<template>
  <div class="page">
    <div class="card">
      <div class="card-title">结项评价 <span class="sub">企业导师与校内教师分别评分，系统按 40/40/20 加权计算总评</span></div>

      <el-table :data="rows" v-loading="loading" border stripe>
        <el-table-column prop="studentName" label="学生" min-width="90" />
        <el-table-column label="企业评分" min-width="96">
          <template #default="{ row }"><span class="num">{{ row.companyScore ?? '-' }} / 5</span></template>
        </el-table-column>
        <el-table-column prop="companyEvaluator" label="企业评价人" min-width="110" />
        <el-table-column prop="companyComment" label="企业评语" min-width="220" show-overflow-tooltip />
        <el-table-column label="校内评分" min-width="96">
          <template #default="{ row }"><span class="num">{{ row.schoolScore ?? '-' }} / 100</span></template>
        </el-table-column>
        <el-table-column prop="schoolEvaluator" label="校内评价人" min-width="110" />
        <el-table-column label="周报得分" min-width="92">
          <template #default="{ row }"><span class="num">{{ row.reportScore ?? '-' }}</span></template>
        </el-table-column>
        <el-table-column label="加权总评" min-width="110">
          <template #default="{ row }"><b class="num">{{ row.totalScore ?? '-' }}</b></template>
        </el-table-column>
        <el-table-column prop="grade" label="等级" min-width="90">
          <template #default="{ row }"><StatusTag :value="row.grade" /></template>
        </el-table-column>
        <el-table-column prop="status" label="状态" min-width="90">
          <template #default="{ row }"><StatusTag :value="row.status" /></template>
        </el-table-column>
        <el-table-column label="操作" min-width="110" fixed="right">
          <template #default="{ row }">
            <el-button link type="primary" @click="open(row)">{{ row.status === '已完成' ? '查看' : '评价' }}</el-button>
          </template>
        </el-table-column>
      </el-table>

      <div class="pager">
        <el-pagination background layout="total, sizes, prev, pager, next, jumper"
          :total="total" :current-page="page" :page-size="size" :page-sizes="[10, 20, 50]"
          @current-change="onPage" @size-change="onSize" />
      </div>
    </div>

    <el-drawer v-model="open1" title="结项评价" size="540px">
      <template v-if="cur">
        <div class="head"><b>档案 #{{ cur.applicationId }}</b><StatusTag :value="cur.status" /><span class="muted">{{ cur.studentName }}</span></div>
        <el-form label-width="100px">
          <el-form-item label="企业评分">
            <el-input-number v-model="form.companyScore" :min="0" :max="5" :step="0.1" :precision="1" />
            <span class="muted" style="margin-left: 10px">满分 5 分</span>
          </el-form-item>
          <el-form-item label="企业评语"><el-input v-model="form.companyComment" type="textarea" :rows="3" /></el-form-item>
          <el-form-item label="校内评分">
            <el-input-number v-model="form.schoolScore" :min="0" :max="100" />
            <span class="muted" style="margin-left: 10px">满分 100 分</span>
          </el-form-item>
          <el-form-item label="校内评语"><el-input v-model="form.schoolComment" type="textarea" :rows="3" /></el-form-item>
          <el-form-item label="锁定结项">
            <el-switch v-model="form.finalize" active-text="材料齐全后锁定" />
          </el-form-item>
        </el-form>
        <el-alert type="info" :closable="false" show-icon
          title="周报、考勤、双导师评价或结项材料缺失时不允许完成结项，后端会逐项校验" />
      </template>
      <template #footer>
        <el-button @click="open1 = false">关闭</el-button>
        <el-button type="primary" :loading="saving" @click="save">保存评价</el-button>
      </template>
    </el-drawer>
  </div>
</template>

<script setup>
import { onMounted, reactive, ref } from 'vue'
import { ElMessage } from 'element-plus'
import StatusTag from '../components/StatusTag.vue'
import { flowApi } from '../api'
import { useTable } from '../composables/useTable'

/** 结项评价：双导师分别评分，加权总评由后端计算，材料不全不得锁定 */
const { rows, total, loading, page, size, load, onPage, onSize } = useTable(flowApi.evalPage, {})
const open1 = ref(false)
const saving = ref(false)
const cur = ref(null)
const form = reactive({ companyScore: 4, companyComment: '', schoolScore: 85, schoolComment: '', finalize: false })

function open(row) {
  cur.value = row
  Object.assign(form, {
    companyScore: row.companyScore ?? 4, companyComment: row.companyComment || '',
    schoolScore: row.schoolScore ?? 85, schoolComment: row.schoolComment || '', finalize: false
  })
  open1.value = true
}

async function save() {
  saving.value = true
  try {
    await flowApi.saveEval(cur.value.applicationId, { ...form })
    ElMessage.success(form.finalize ? '已锁定结项' : '评价已保存')
    open1.value = false
    load()
  } finally { saving.value = false }
}

onMounted(load)
</script>

<style scoped>
.head { display: flex; align-items: center; gap: 10px; margin-bottom: 16px; }
</style>
