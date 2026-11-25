<template>
  <div class="page">
    <div class="card">
      <div class="card-title">走访记录 <span class="sub">电话/现场走访，需记录参与人、学生表现、企业意见与照片</span>
        <el-button type="primary" @click="open()">新增走访</el-button>
      </div>

      <el-table :data="rows" v-loading="loading" border stripe>
        <el-table-column prop="visitNo" label="走访编号" min-width="140" />
        <el-table-column prop="studentName" label="学生" min-width="90" />
        <el-table-column prop="companyName" label="企业" min-width="200" show-overflow-tooltip />
        <el-table-column prop="visitType" label="方式" min-width="80" />
        <el-table-column prop="visitDate" label="走访日期" min-width="110" />
        <el-table-column prop="participants" label="参与人" min-width="140" />
        <el-table-column prop="studentPerformance" label="学生表现" min-width="240" show-overflow-tooltip />
        <el-table-column prop="companyOpinion" label="企业意见" min-width="220" show-overflow-tooltip />
        <el-table-column label="照片" min-width="90">
          <template #default="{ row }">
            <el-image v-if="row.photo" :src="row.photo" :preview-src-list="[row.photo]" fit="cover" class="thumb" />
            <span v-else class="muted">无</span>
          </template>
        </el-table-column>
        <el-table-column prop="teacherName" label="记录人" min-width="96" />
      </el-table>

      <div class="pager">
        <el-pagination background layout="total, sizes, prev, pager, next, jumper"
          :total="total" :current-page="page" :page-size="size" :page-sizes="[10, 20, 50]"
          @current-change="onPage" @size-change="onSize" />
      </div>
    </div>

    <el-dialog v-model="open1" title="新增走访记录" width="560px">
      <el-form label-width="100px">
        <el-form-item label="实习档案">
          <el-select v-model="form.applicationId" filterable style="width: 100%">
            <el-option v-for="a in apps" :key="a.id" :label="`${a.internshipNo} · ${a.studentName}`" :value="a.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="走访方式">
          <el-radio-group v-model="form.visitType">
            <el-radio label="现场">现场</el-radio>
            <el-radio label="电话">电话</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="走访日期">
          <el-date-picker v-model="form.visitDate" type="date" value-format="YYYY-MM-DD" style="width: 100%" />
        </el-form-item>
        <el-form-item label="参与人"><el-input v-model="form.participants" placeholder="如 李明华、企业 HR" /></el-form-item>
        <el-form-item label="学生表现"><el-input v-model="form.studentPerformance" type="textarea" :rows="2" /></el-form-item>
        <el-form-item label="企业意见"><el-input v-model="form.companyOpinion" type="textarea" :rows="2" /></el-form-item>
        <el-form-item label="现场照片"><UploadField v-model="form.photo" biz-type="visit" /></el-form-item>
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
import { ElMessage } from 'element-plus'
import UploadField from '../components/UploadField.vue'
import { appApi, flowApi } from '../api'
import { useTable } from '../composables/useTable'

/** 走访记录：教师走访留痕，照片走上传组件，不填外链 */
const { rows, total, loading, page, size, load, onPage, onSize } = useTable(flowApi.visitPage, {})
const apps = ref([])
const open1 = ref(false)
const saving = ref(false)
const form = reactive({ applicationId: null, visitType: '现场', visitDate: '', participants: '', studentPerformance: '', companyOpinion: '', photo: '' })

function open() {
  Object.assign(form, { applicationId: apps.value[0]?.id || null, visitType: '现场', visitDate: '', participants: '', studentPerformance: '', companyOpinion: '', photo: '' })
  open1.value = true
}

async function save() {
  if (!form.applicationId || !form.visitDate) return ElMessage.warning('请选择档案与走访日期')
  saving.value = true
  try {
    await flowApi.saveVisit({ ...form })
    ElMessage.success('走访记录已保存')
    open1.value = false
    load()
  } finally { saving.value = false }
}

onMounted(async () => {
  load()
  const d = await appApi.page({ page: 1, size: 100 })
  apps.value = d.records || []
})
</script>
