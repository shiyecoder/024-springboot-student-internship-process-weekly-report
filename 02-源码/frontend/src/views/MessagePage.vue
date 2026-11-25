<template>
  <div class="page">
    <div class="card">
      <div class="card-title">消息中心 <span class="sub">待审批、即将超时、已退回、处理完成等事件都会进入消息中心</span>
        <el-button @click="readAll">全部标为已读</el-button>
      </div>

      <el-radio-group v-model="type" size="small" style="margin-bottom: 12px">
        <el-radio-button label="">全部</el-radio-button>
        <el-radio-button label="待审批">待审批</el-radio-button>
        <el-radio-button label="即将超时">即将超时</el-radio-button>
        <el-radio-button label="处理完成">处理完成</el-radio-button>
      </el-radio-group>

      <div v-if="!filtered.length" class="empty-hint">当前条件下没有消息，切换标签或等待业务事件产生</div>
      <div v-for="m in filtered" :key="m.id" class="msg" :class="{ unread: !m.isRead }" @click="open(m)">
        <div class="l">
          <el-tag size="small" :type="statusType(m.msgType)">{{ m.msgType }}</el-tag>
          <div>
            <div class="t">{{ m.title }}</div>
            <div class="c">{{ m.content }}</div>
          </div>
        </div>
        <div class="r">
          <span class="num">{{ fmtDateTime(m.createTime) }}</span>
          <el-button v-if="m.linkUrl" link type="primary" @click.stop="go(m)">去处理 →</el-button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { systemApi } from '../api'
import { fmtDateTime, statusType } from '../utils/format'

/** 消息中心：消息带业务编号与详情跳转地址，已读状态入库 */
const router = useRouter()
const list = ref([])
const type = ref('')

const filtered = computed(() => (type.value ? list.value.filter((m) => m.msgType === type.value) : list.value))

async function load() {
  list.value = (await systemApi.messages()) || []
}

function open(m) {
  if (!m.isRead) {
    systemApi.readOne(m.id).then(load)
  }
}

function go(m) {
  open(m)
  if (m.linkUrl) router.push(m.linkUrl)
}

async function readAll() {
  await systemApi.readAll()
  load()
}

onMounted(load)
</script>

<style scoped>
.msg { display: flex; justify-content: space-between; gap: 16px; padding: 12px 14px; border: 1px solid var(--line); border-radius: 6px; margin-bottom: 10px; cursor: pointer; }
.msg.unread { background: #f5fbf7; border-left: 3px solid var(--secondary); }
.msg .l { display: flex; gap: 12px; align-items: flex-start; }
.msg .t { font-size: 13.5px; font-weight: 500; }
.msg .c { font-size: 12.5px; color: var(--text-2); margin-top: 3px; }
.msg .r { display: flex; align-items: center; gap: 12px; font-size: 12px; color: var(--text-2); white-space: nowrap; }
.card-title .el-button { margin-left: auto; }
</style>
