<template>
  <div class="page">
    <div class="card">
      <div class="card-title">考勤汇总 <span class="sub">企业导师按月录入，学生确认后计入学分核算</span>
        <el-button type="primary" @click="open()">录入考勤</el-button>
      </div>

      <el-form class="filter-bar" :inline="true">
        <el-form-item label="月份">
          <el-date-picker v-model="query.month" type="month" value-format="YYYY-MM" placeholder="全部月份" />
        </el-form-item>
        <el-form-item label="确认状态">
          <el-select v-model="query.confirmStatus" clearable placeholder="全部">
            <el-option label="待确认" value="待确认" />
            <el-option label="学生已确认" value="学生已确认" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="search">查询</el-button>
          <el-button @click="reset">重置</el-button>
        </el-form-item>
      </el-form>

      <el-table :data="rows" v-loading="loading" border stripe>
        <el-table-column prop="attendanceNo" label="考勤编号" min-width="140" />
        <el-table-column prop="studentName" label="学生" min-width="90" />
        <el-table-column prop="companyName" label="实习企业" min-width="220" show-overflow-tooltip />
        <el-table-column prop="month" label="月份" min-width="90" />
        <el-table-column prop="shouldDays" label="应出勤" min-width="84" />
        <el-table-column prop="actualDays" label="实出勤" min-width="84" />
        <el-table-column prop="lateCount" label="迟到" min-width="70" />
        <el-table-column prop="leaveDays" label="请假" min-width="70" />
        <el-table-column prop="remark" label="备注" min-width="160" show-overflow-tooltip />
        <el-table-column prop="confirmStatus" label="确认状态" min-width="110">
          <template #default="{ row }"><StatusTag :value="row.confirmStatus" /></template>
        </el-table-column>
        <el-table-column label="操作" min-width="100" fixed="right">
          <template #default="{ row }">
            <el-button v-if="row.confirmStatus !== '学生已确认'" link type="primary" @click="confirm(row)">学生确认</el-button>
            <span v-else class="muted">已确认</span>
          </template>
        </el-table-column>
      </el-table>

      <div class="pager">
        <el-pagination background layout="total, sizes, prev, pager, next, jumper"
          :total="total" :current-page="page" :page-size="size" :page-sizes="[10, 20, 50]"
          @current-change="onPage" @size-change="onSize" />
      </div>
    </div>

    <el-dialog v-model="open1" title="录入月度考勤" width="520px">
      <el-form label-width="100px">
        <el-form-item label="实习档案">
          <el-select v-model="form.applicationId" filterable style="width: 100%">
            <el-option v-for="a in apps" :key="a.id" :label="`${a.internshipNo} · ${a.studentName}`" :value="a.id" @click="pick(a)" />
          </el-select>
        </el-form-item>
        <el-form-item label="月份">
          <el-date-picker v-model="form.month" type="month" value-format="YYYY-MM" style="width: 100%" />
        </el-form-item>
        <el-form-item label="应出勤"><el-input-number v-model="form.shouldDays" :min="0" :max="31" /></el-form-item>
        <el-form-item label="实出勤"><el-input-number v-model="form.actualDays" :min="0" :max="31" /></el-form-item>
        <el-form-item label="迟到次数"><el-input-number v-model="form.lateCount" :min="0" :max="31" /></el-form-item>
        <el-form-item label="请假天数"><el-input-number v-model="form.leaveDays" :min="0" :max="31" /></el-form-item>
        <el-form-item label="备注"><el-input v-model="form.remark" type="textarea" :rows="2" /></el-form-item>
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
import StatusTag from '../components/StatusTag.vue'
import { appApi, reportApi } from '../api'
import { useTable } from '../composables/useTable'

/** 考勤汇总：按档案 + 月份唯一，学生确认后不可再改 */
const { rows, total, loading, page, size, query, load, search, reset, onPage, onSize } =
  useTable(reportApi.attendancePage, { month: '', confirmStatus: '' })

const apps = ref([])
const open1 = ref(false)
const saving = ref(false)
const form = reactive({ applicationId: null, studentName: '', companyName: '', month: '', shouldDays: 22, actualDays: 22, lateCount: 0, leaveDays: 0, remark: '', confirmStatus: '待确认' })

function pick(a) {
  form.studentName = a.studentName
  form.companyName = a.companyName
}

function open() {
  Object.assign(form, { applicationId: apps.value[0]?.id || null, studentName: apps.value[0]?.studentName || '', companyName: apps.value[0]?.companyName || '', month: '', shouldDays: 22, actualDays: 22, lateCount: 0, leaveDays: 0, remark: '' })
  open1.value = true
}

async function save() {
  if (!form.applicationId || !form.month) return ElMessage.warning('请选择档案与月份')
  if (form.actualDays > form.shouldDays) return ElMessage.warning('实出勤不能大于应出勤')
  saving.value = true
  try {
    await reportApi.saveAttendance({ ...form })
    ElMessage.success('考勤已保存，等待学生确认')
    open1.value = false
    load()
  } finally { saving.value = false }
}

async function confirm(row) {
  try {
    await ElMessageBox.confirm(`确认 ${row.studentName} ${row.month} 的考勤记录吗？确认后不可修改。`, '学生确认', { type: 'warning' })
    await reportApi.confirmAttendance(row.id, { agree: true, remark: '学生已核对无误' })
    ElMessage.success('已确认')
    load()
  } catch (e) { /* 取消 */ }
}

onMounted(async () => {
  load()
  const d = await appApi.page({ page: 1, size: 100 })
  apps.value = d.records || []
})
</script>
