<template>
  <div class="page">
    <div class="card">
      <div class="card-title">操作日志 <span class="sub">关键流转、规则计算与人工修正都会写日志，普通用户不可修改</span></div>

      <el-form class="filter-bar" :inline="true">
        <el-form-item label="关键字">
          <el-input v-model="query.keyword" placeholder="操作人 / 行为 / 参数" clearable @keyup.enter="search" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="search">查询</el-button>
          <el-button @click="reset">重置</el-button>
        </el-form-item>
      </el-form>

      <el-table :data="rows" v-loading="loading" border stripe>
        <el-table-column prop="userName" label="操作人" min-width="100" />
        <el-table-column prop="action" label="操作行为" min-width="180" />
        <el-table-column prop="method" label="接口" min-width="240" show-overflow-tooltip />
        <el-table-column prop="params" label="参数 / 业务编号" min-width="240" show-overflow-tooltip />
        <el-table-column prop="ip" label="来源IP" min-width="120" />
        <el-table-column label="耗时" min-width="90">
          <template #default="{ row }"><span class="num">{{ row.costMs }} ms</span></template>
        </el-table-column>
        <el-table-column label="时间" min-width="160">
          <template #default="{ row }"><span class="num">{{ fmtDateTime(row.createTime) }}</span></template>
        </el-table-column>
      </el-table>

      <div class="pager">
        <el-pagination background layout="total, sizes, prev, pager, next, jumper"
          :total="total" :current-page="page" :page-size="size" :page-sizes="[10, 20, 50]"
          @current-change="onPage" @size-change="onSize" />
      </div>
    </div>
  </div>
</template>

<script setup>
import { onMounted } from 'vue'
import { systemApi } from '../../api'
import { useTable } from '../../composables/useTable'
import { fmtDateTime } from '../../utils/format'

/** 操作日志：只读，按时间倒序 */
const { rows, total, loading, page, size, query, load, search, reset, onPage, onSize } =
  useTable(systemApi.logPage, { keyword: '' })

onMounted(load)
</script>
