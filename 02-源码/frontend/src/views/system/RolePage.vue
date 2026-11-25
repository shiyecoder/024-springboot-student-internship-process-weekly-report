<template>
  <div class="page">
    <div class="card">
      <div class="card-title">角色管理 <span class="sub">四个业务角色，数据范围与菜单权限分别控制</span></div>
      <el-table :data="roles" v-loading="loading" border stripe>
        <el-table-column prop="roleCode" label="角色编码" min-width="120" />
        <el-table-column prop="roleName" label="角色名称" min-width="140" />
        <el-table-column prop="description" label="职责说明" min-width="320" show-overflow-tooltip />
        <el-table-column prop="dataScope" label="数据范围" min-width="110">
          <template #default="{ row }">{{ scopeText[row.dataScope] || row.dataScope }}</template>
        </el-table-column>
        <el-table-column label="创建时间" min-width="160">
          <template #default="{ row }">{{ fmtDateTime(row.createTime) }}</template>
        </el-table-column>
        <el-table-column label="操作" min-width="140" fixed="right">
          <template #default="{ row }">
            <el-button link type="primary" @click="openAssign(row)">分配菜单</el-button>
          </template>
        </el-table-column>
      </el-table>
    </div>

    <!-- 分配菜单：树形勾选，保存后该角色重新登录即生效；不展示菜单管理本身 -->
    <el-drawer v-model="open1" :title="`为「${cur?.roleName || ''}」分配菜单`" size="440px">
      <div class="muted" style="margin-bottom: 12px">勾选后可访问的页面。仅菜单权限不含按钮权限，写接口仍由后端校验角色。</div>
      <el-tree
        ref="treeRef" :data="menuTree" show-checkbox node-key="id" default-expand-all
        :props="{ label: 'name', children: 'children' }" :default-checked-keys="checkedIds"
      />
      <template #footer>
        <el-button @click="open1 = false">取消</el-button>
        <el-button type="primary" :loading="saving" @click="save">保存</el-button>
      </template>
    </el-drawer>
  </div>
</template>

<script setup>
import { onMounted, ref } from 'vue'
import { ElMessage } from 'element-plus'
import { systemApi } from '../../api'
import { fmtDateTime } from '../../utils/format'

/** 角色管理：菜单按角色动态下发，前端不硬编码 */
const scopeText = { ALL: '全校', ORG: '本学院', SELF: '仅本人' }
const roles = ref([])
const menuTree = ref([])
const checkedIds = ref([])
const loading = ref(false)
const saving = ref(false)
const open1 = ref(false)
const cur = ref(null)
const treeRef = ref()

/** 菜单管理自身不应出现在分配列表里（需求：隐藏菜单管理选项） */
function prune(nodes) {
  return (nodes || [])
    .filter((n) => n.path !== '/system/menu' && n.name !== '菜单管理')
    .map((n) => ({ ...n, children: prune(n.children) }))
}

async function openAssign(row) {
  cur.value = row
  const ids = (await systemApi.roleMenus(row.roleCode)) || []
  checkedIds.value = ids.map((x) => (typeof x === 'object' ? x.id : x))
  open1.value = true
}

async function save() {
  const ids = [...(treeRef.value?.getCheckedKeys() || []), ...(treeRef.value?.getHalfCheckedKeys() || [])]
  saving.value = true
  try {
    await systemApi.saveRoleMenus(cur.value.roleCode, ids)
    ElMessage.success('已保存，该角色重新登录后生效')
    open1.value = false
  } finally { saving.value = false }
}

onMounted(async () => {
  loading.value = true
  try {
    roles.value = (await systemApi.roles()) || []
    menuTree.value = prune(await systemApi.menuTree())
  } finally { loading.value = false }
})
</script>
