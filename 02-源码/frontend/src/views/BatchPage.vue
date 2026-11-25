<template>
  <div class="page">
    <div class="card">
      <div class="card-title">实习批次 <span class="sub">学期、院系、起止日期、周报截止时间、评分构成与必交材料</span>
        <el-button type="primary" @click="open()">新建批次</el-button>
      </div>

      <el-table :data="rows" v-loading="loading" border stripe>
        <el-table-column prop="batchNo" label="批次号" min-width="100" />
        <el-table-column prop="semester" label="学期" min-width="200" />
        <el-table-column prop="departments" label="覆盖院系" min-width="220" show-overflow-tooltip />
        <el-table-column label="起止日期" min-width="190">
          <template #default="{ row }"><span class="num">{{ row.startDate }} ~ {{ row.endDate }}</span></template>
        </el-table-column>
        <el-table-column prop="reportDeadline" label="周报截止" min-width="130" />
        <el-table-column prop="graceDays" label="宽限天数" min-width="90" />
        <el-table-column prop="scoreWeights" label="评分构成" min-width="110" />
        <el-table-column prop="requiredMaterials" label="必交材料" min-width="240" show-overflow-tooltip />
        <el-table-column prop="minReports" label="最少周报" min-width="92" />
        <el-table-column prop="status" label="状态" min-width="90">
          <template #default="{ row }"><StatusTag :value="row.status" /></template>
        </el-table-column>
        <el-table-column label="操作" min-width="90" fixed="right">
          <template #default="{ row }"><el-button link type="primary" @click="open(row)">编辑</el-button></template>
        </el-table-column>
      </el-table>
    </div>

    <el-drawer v-model="open1" :title="form.id ? '编辑批次' : '新建批次'" size="500px">
      <el-form label-width="110px">
        <el-form-item label="批次号"><el-input v-model="form.batchNo" placeholder="B2026S1" /></el-form-item>
        <el-form-item label="学期"><el-input v-model="form.semester" placeholder="2026-2027 学年第一学期" /></el-form-item>
        <el-form-item label="覆盖院系"><el-input v-model="form.departments" placeholder="计算机学院 / 商学院" /></el-form-item>
        <el-form-item label="开始日期">
          <el-date-picker v-model="form.startDate" type="date" value-format="YYYY-MM-DD" style="width: 100%" />
        </el-form-item>
        <el-form-item label="结束日期">
          <el-date-picker v-model="form.endDate" type="date" value-format="YYYY-MM-DD" style="width: 100%" />
        </el-form-item>
        <el-form-item label="周报截止"><el-input v-model="form.reportDeadline" placeholder="每周日 23:59" /></el-form-item>
        <el-form-item label="宽限天数"><el-input-number v-model="form.graceDays" :min="0" :max="7" /></el-form-item>
        <el-form-item label="评分构成"><el-input v-model="form.scoreWeights" placeholder="40/40/20" /></el-form-item>
        <el-form-item label="必交材料"><el-input v-model="form.requiredMaterials" type="textarea" :rows="2" /></el-form-item>
        <el-form-item label="最少周报数"><el-input-number v-model="form.minReports" :min="1" :max="30" /></el-form-item>
        <el-form-item label="状态">
          <el-radio-group v-model="form.status">
            <el-radio label="启用">启用</el-radio>
            <el-radio label="已归档">已归档</el-radio>
          </el-radio-group>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="open1 = false">取消</el-button>
        <el-button type="primary" :loading="saving" @click="save">保存</el-button>
      </template>
    </el-drawer>
  </div>
</template>

<script setup>
import { onMounted, reactive, ref } from 'vue'
import { ElMessage } from 'element-plus'
import StatusTag from '../components/StatusTag.vue'
import { baseApi } from '../api'

/** 实习批次：一个学期一条批次，档案创建时挂批次号 */
const rows = ref([])
const loading = ref(false)
const open1 = ref(false)
const saving = ref(false)
const empty = () => ({ id: null, batchNo: '', semester: '', departments: '', startDate: '', endDate: '', reportDeadline: '每周日 23:59', graceDays: 2, scoreWeights: '40/40/20', requiredMaterials: '三方协议、人身意外险、结项报告', minReports: 12, status: '启用' })
const form = reactive(empty())

function open(row) {
  Object.assign(form, empty(), row || {})
  open1.value = true
}

async function save() {
  if (!form.batchNo || !form.semester) return ElMessage.warning('请填写批次号与学期')
  saving.value = true
  try {
    await baseApi.saveBatch({ ...form })
    ElMessage.success('已保存')
    open1.value = false
    load()
  } finally { saving.value = false }
}

async function load() {
  loading.value = true
  try { rows.value = (await baseApi.batchList()) || [] } finally { loading.value = false }
}

onMounted(load)
</script>
