<template>
  <div class="page">
    <div class="card">
      <div class="card-title">企业库 <span class="sub">企业资质、往年接收情况、学生评价与风险状态</span>
        <el-button type="primary" @click="open()">新增企业</el-button>
      </div>

      <el-form class="filter-bar" :inline="true">
        <el-form-item label="关键字">
          <el-input v-model="query.keyword" placeholder="企业名称 / 编号" clearable @keyup.enter="search" />
        </el-form-item>
        <el-form-item label="行业">
          <el-select v-model="query.industry" clearable placeholder="全部行业">
            <el-option v-for="i in industries" :key="i" :label="i" :value="i" />
          </el-select>
        </el-form-item>
        <el-form-item label="风险状态">
          <el-select v-model="query.riskStatus" clearable placeholder="全部">
            <el-option label="正常" value="正常" />
            <el-option label="重点观察" value="重点观察" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="search">查询</el-button>
          <el-button @click="reset">重置</el-button>
        </el-form-item>
      </el-form>

      <el-table :data="rows" v-loading="loading" border stripe>
        <el-table-column label="资质" min-width="90">
          <template #default="{ row }">
            <el-image v-if="row.licenseImage" :src="row.licenseImage" :preview-src-list="[row.licenseImage]" fit="cover" class="thumb" />
            <span v-else class="muted">无</span>
          </template>
        </el-table-column>
        <el-table-column prop="companyNo" label="企业编号" min-width="96" />
        <el-table-column prop="companyName" label="企业名称" min-width="220" show-overflow-tooltip />
        <el-table-column prop="industry" label="行业" min-width="96" />
        <el-table-column prop="city" label="城市" min-width="80" />
        <el-table-column prop="contact" label="联系人" min-width="90" />
        <el-table-column prop="phone" label="联系电话" min-width="130" />
        <el-table-column prop="scale" label="规模" min-width="110" />
        <el-table-column prop="pastStudents" label="往年接收" min-width="96" />
        <el-table-column label="平均评分" min-width="96">
          <template #default="{ row }"><span class="num">{{ row.avgScore }}</span></template>
        </el-table-column>
        <el-table-column prop="riskStatus" label="风险状态" min-width="96">
          <template #default="{ row }"><StatusTag :value="row.riskStatus" /></template>
        </el-table-column>
        <el-table-column label="操作" min-width="120" fixed="right">
          <template #default="{ row }">
            <el-button link type="primary" @click="open(row)">编辑</el-button>
            <el-button link type="danger" @click="remove(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>

      <div class="pager">
        <el-pagination background layout="total, sizes, prev, pager, next, jumper"
          :total="total" :current-page="page" :page-size="size" :page-sizes="[10, 20, 50]"
          @current-change="onPage" @size-change="onSize" />
      </div>
    </div>

    <el-drawer v-model="open1" :title="form.id ? '编辑企业' : '新增企业'" size="520px">
      <el-form ref="formRef" :model="form" :rules="rules" label-width="100px">
        <el-form-item label="企业名称" prop="companyName"><el-input v-model="form.companyName" /></el-form-item>
        <el-form-item label="行业" prop="industry">
          <el-select v-model="form.industry" style="width: 100%">
            <el-option v-for="i in industries" :key="i" :label="i" :value="i" />
          </el-select>
        </el-form-item>
        <el-form-item label="城市"><el-input v-model="form.city" /></el-form-item>
        <el-form-item label="地址"><el-input v-model="form.address" /></el-form-item>
        <el-form-item label="联系人"><el-input v-model="form.contact" /></el-form-item>
        <el-form-item label="联系电话"><el-input v-model="form.phone" /></el-form-item>
        <el-form-item label="规模">
          <el-select v-model="form.scale" style="width: 100%">
            <el-option v-for="s in ['100 人以下', '100-500 人', '500-1000 人', '1000 人以上']" :key="s" :label="s" :value="s" />
          </el-select>
        </el-form-item>
        <el-form-item label="风险状态">
          <el-radio-group v-model="form.riskStatus">
            <el-radio label="正常">正常</el-radio>
            <el-radio label="重点观察">重点观察</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="营业执照"><UploadField v-model="form.licenseImage" biz-type="company" /></el-form-item>
        <el-form-item label="企业简介"><el-input v-model="form.intro" type="textarea" :rows="3" /></el-form-item>
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
import { ElMessage, ElMessageBox } from 'element-plus'
import StatusTag from '../components/StatusTag.vue'
import UploadField from '../components/UploadField.vue'
import { baseApi, systemApi } from '../api'
import { useTable } from '../composables/useTable'

/** 企业库：备案制，被档案引用的企业不允许物理删除（后端校验） */
const industries = ['信息技术', '制造', '金融', '医疗', '建筑', '教育', '传媒', '会计']
const { rows, total, loading, page, size, query, load, search, reset, onPage, onSize } =
  useTable(baseApi.companyPage, { keyword: '', industry: '', riskStatus: '' })

const open1 = ref(false)
const saving = ref(false)
const formRef = ref()
const empty = () => ({ id: null, companyName: '', industry: '信息技术', city: '杭州', address: '', contact: '', phone: '', scale: '100-500 人', riskStatus: '正常', licenseImage: '', intro: '' })
const form = reactive(empty())
const rules = {
  companyName: [{ required: true, message: '请填写企业名称', trigger: 'blur' }],
  industry: [{ required: true, message: '请选择行业', trigger: 'change' }]
}

function open(row) {
  Object.assign(form, empty(), row || {})
  open1.value = true
}

async function save() {
  try { await formRef.value.validate() } catch (e) { return }
  saving.value = true
  try {
    await baseApi.saveCompany({ ...form })
    ElMessage.success('已保存')
    open1.value = false
    load()
  } finally { saving.value = false }
}

async function remove(row) {
  try {
    await ElMessageBox.confirm(`确认删除「${row.companyName}」吗？已被实习档案引用时会被拒绝。`, '删除确认', { type: 'warning' })
    await baseApi.delCompany(row.id)
    ElMessage.success('已删除')
    load()
  } catch (e) { /* 取消或后端拒绝 */ }
}

onMounted(load)
</script>
