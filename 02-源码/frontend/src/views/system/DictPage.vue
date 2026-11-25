<template>
  <div class="page">
    <div class="card">
      <div class="card-title">字典管理 <span class="sub">前端下拉与状态标签统一取字典，禁止硬编码未定义值</span>
        <el-button type="primary" @click="open()">新增字典项</el-button>
      </div>

      <el-radio-group v-model="type" size="small" style="margin-bottom: 12px" @change="load">
        <el-radio-button v-for="t in types" :key="t" :label="t">{{ typeLabel[t] || t }}</el-radio-button>
      </el-radio-group>

      <el-table :data="rows" v-loading="loading" border stripe>
        <el-table-column prop="dictType" label="字典类型" min-width="140" />
        <el-table-column prop="dictLabel" label="显示名称" min-width="160" />
        <el-table-column prop="dictValue" label="字典值" min-width="160" />
        <el-table-column prop="sortNo" label="排序" min-width="80" />
        <el-table-column label="状态" min-width="90">
          <template #default="{ row }"><StatusTag :value="row.status === 1 ? '启用' : '停用'" /></template>
        </el-table-column>
        <el-table-column label="操作" min-width="90" fixed="right">
          <template #default="{ row }"><el-button link type="danger" @click="remove(row)">删除</el-button></template>
        </el-table-column>
      </el-table>
    </div>

    <el-dialog v-model="open1" title="新增字典项" width="420px">
      <el-form label-width="90px">
        <el-form-item label="类型"><el-input v-model="form.dictType" /></el-form-item>
        <el-form-item label="显示名称"><el-input v-model="form.dictLabel" /></el-form-item>
        <el-form-item label="字典值"><el-input v-model="form.dictValue" /></el-form-item>
        <el-form-item label="排序"><el-input-number v-model="form.sortNo" :min="0" /></el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="open1 = false">取消</el-button>
        <el-button type="primary" :loading="saving" @click="save">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { onMounted, reactive, ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import StatusTag from '../../components/StatusTag.vue'
import { systemApi } from '../../api'

/** 字典管理：行业、变更类型、异常类型等枚举集中维护 */
const types = ['industry', 'change_type', 'issue_type', 'visit_type', 'stage']
const typeLabel = { industry: '行业', change_type: '变更类型', issue_type: '异常类型', visit_type: '走访方式', stage: '实习阶段' }
const rows = ref([])
const type = ref('industry')
const loading = ref(false)
const open1 = ref(false)
const saving = ref(false)
const form = reactive({ dictType: 'industry', dictLabel: '', dictValue: '', sortNo: 100 })

async function load() {
  loading.value = true
  try { rows.value = (await systemApi.dicts(type.value)) || [] } finally { loading.value = false }
}

function open() {
  Object.assign(form, { dictType: type.value, dictLabel: '', dictValue: '', sortNo: 100 })
  open1.value = true
}

async function save() {
  if (!form.dictLabel) return ElMessage.warning('请填写显示名称')
  saving.value = true
  try {
    await systemApi.saveDict({ ...form, dictValue: form.dictValue || form.dictLabel, status: 1 })
    ElMessage.success('已保存')
    open1.value = false
    load()
  } finally { saving.value = false }
}

async function remove(row) {
  try {
    await ElMessageBox.confirm(`确认删除字典项「${row.dictLabel}」吗？`, '删除确认', { type: 'warning' })
    await systemApi.delDict(row.id)
    ElMessage.success('已删除')
    load()
  } catch (e) { /* 取消 */ }
}

onMounted(load)
</script>
