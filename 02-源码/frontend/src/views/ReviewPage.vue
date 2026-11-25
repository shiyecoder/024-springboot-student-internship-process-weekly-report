<template>
  <div class="page">
    <div class="card">
      <div class="card-title">导师批阅 <span class="sub">待批阅优先，退修必须写明不少于 5 个字的原因</span></div>

      <el-form class="filter-bar" :inline="true">
        <el-form-item label="状态">
          <el-select v-model="query.status" clearable placeholder="全部状态">
            <el-option label="待批阅" value="待批阅" />
            <el-option label="已批阅" value="已批阅" />
            <el-option label="已退修" value="已退修" />
          </el-select>
        </el-form-item>
        <el-form-item label="关键字">
          <el-input v-model="query.keyword" placeholder="周报编号 / 学生" clearable @keyup.enter="search" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="search">查询</el-button>
          <el-button @click="reset">重置</el-button>
        </el-form-item>
      </el-form>

      <el-table :data="rows" v-loading="loading" border stripe>
        <el-table-column prop="reportNo" label="周报编号" min-width="150" />
        <el-table-column prop="studentName" label="学生" min-width="90" />
        <el-table-column prop="internshipNo" label="实习编号" min-width="128" />
        <el-table-column label="周次" min-width="76">
          <template #default="{ row }">第 {{ row.weekNo }} 周</template>
        </el-table-column>
        <el-table-column prop="taskContent" label="本周任务" min-width="280" show-overflow-tooltip />
        <el-table-column prop="status" label="状态" min-width="90">
          <template #default="{ row }"><StatusTag :value="row.status" /></template>
        </el-table-column>
        <el-table-column label="提交时间" min-width="160">
          <template #default="{ row }"><span class="num">{{ fmtDateTime(row.submitTime) }}</span></template>
        </el-table-column>
        <el-table-column prop="reviewScore" label="得分" min-width="76">
          <template #default="{ row }">{{ row.reviewScore ?? '-' }}</template>
        </el-table-column>
        <el-table-column label="操作" min-width="110" fixed="right">
          <template #default="{ row }">
            <el-button link type="primary" @click="open(row)">{{ row.status === '待批阅' ? '批阅' : '查看' }}</el-button>
          </template>
        </el-table-column>
      </el-table>

      <div class="pager">
        <el-pagination background layout="total, sizes, prev, pager, next, jumper"
          :total="total" :current-page="page" :page-size="size" :page-sizes="[10, 20, 50]"
          @current-change="onPage" @size-change="onSize" />
      </div>
    </div>

    <!-- 批阅抽屉：顶部摘要 + 正文 + 意见，避免来回切页 -->
    <el-drawer v-model="open1" title="周报批阅" size="600px">
      <template v-if="cur">
        <div class="head">
          <b>{{ cur.reportNo }}</b>
          <StatusTag :value="cur.status" />
          <span class="muted">{{ cur.studentName }} · 第 {{ cur.weekNo }} 周</span>
        </div>
        <div class="sec"><label>本周任务</label><p>{{ cur.taskContent || '-' }}</p></div>
        <div class="sec"><label>学习收获</label><p>{{ cur.harvest || '-' }}</p></div>
        <div class="sec"><label>遇到问题</label><p>{{ cur.problem || '-' }}</p></div>
        <div class="sec"><label>下周计划</label><p>{{ cur.nextPlan || '-' }}</p></div>

        <el-divider />
        <el-form label-width="90px" v-if="cur.status === '待批阅'">
          <el-form-item label="批阅结果">
            <el-radio-group v-model="review.pass">
              <el-radio :label="true">通过</el-radio>
              <el-radio :label="false">退修</el-radio>
            </el-radio-group>
          </el-form-item>
          <el-form-item label="评分" v-if="review.pass">
            <el-input-number v-model="review.score" :min="0" :max="100" />
            <span class="muted" style="margin-left: 10px">计入实习档案周报得分</span>
          </el-form-item>
          <el-form-item label="评语">
            <el-input v-model="review.comment" type="textarea" :rows="4" placeholder="退修时必须填写不少于 5 个字的原因" />
          </el-form-item>
        </el-form>
        <el-alert v-else type="info" :closable="false" show-icon :title="`该周报已${cur.status === '已批阅' ? '批阅' : '退修'}，不能重复批阅`" />
      </template>
      <template #footer>
        <el-button @click="open1 = false">关闭</el-button>
        <el-button v-if="cur && cur.status === '待批阅'" type="primary" :loading="saving" @click="submit">提交批阅</el-button>
      </template>
    </el-drawer>
  </div>
</template>

<script setup>
import { onMounted, reactive, ref } from 'vue'
import { ElMessage } from 'element-plus'
import StatusTag from '../components/StatusTag.vue'
import { reportApi } from '../api'
import { useTable } from '../composables/useTable'
import { fmtDateTime } from '../utils/format'

/** 导师批阅：通过需评分，退修必须有原因；重复批阅由后端拦截 */
const { rows, total, loading, page, size, query, load, search, reset, onPage, onSize } =
  useTable(reportApi.page, { status: '待批阅', keyword: '' })

const open1 = ref(false)
const saving = ref(false)
const cur = ref(null)
const review = reactive({ pass: true, score: 88, comment: '' })

function open(row) {
  cur.value = row
  review.pass = true
  review.score = row.reviewScore || 88
  review.comment = ''
  open1.value = true
}

async function submit() {
  if (!review.pass && review.comment.trim().length < 5) return ElMessage.warning('退修必须填写不少于 5 个字的评语')
  saving.value = true
  try {
    await reportApi.review(cur.value.id, { ...review })
    ElMessage.success(review.pass ? '已通过并记分' : '已退修给学生')
    open1.value = false
    load()
  } finally { saving.value = false }
}

onMounted(load)
</script>

<style scoped>
.head { display: flex; align-items: center; gap: 10px; margin-bottom: 14px; font-size: 14px; }
.sec { margin-bottom: 12px; }
.sec label { display: block; font-size: 12px; color: var(--text-2); margin-bottom: 4px; }
.sec p { margin: 0; font-size: 13px; line-height: 1.8; background: #f8fbf9; padding: 8px 12px; border-radius: 6px; }
</style>
