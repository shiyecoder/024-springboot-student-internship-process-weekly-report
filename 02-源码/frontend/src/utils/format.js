/**
 * 全局时间与数值格式化函数，全系统统一调用，禁止各页面各写一套。
 * 时间统一 yyyy-MM-dd HH:mm:ss（需求文档 227 行）。
 */
export function fmtDateTime(v) {
  if (!v) return '-'
  const d = typeof v === 'string' ? new Date(v.replace(/-/g, '/')) : new Date(v)
  if (isNaN(d.getTime())) return String(v).replace('T', ' ').slice(0, 19)
  const p = (n) => String(n).padStart(2, '0')
  return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())} ${p(d.getHours())}:${p(d.getMinutes())}:${p(d.getSeconds())}`
}

export function fmtDate(v) {
  if (!v) return '-'
  return fmtDateTime(v).slice(0, 10)
}

/** 相对时间，用于消息与时间轴 */
export function fromNow(v) {
  if (!v) return '-'
  const d = new Date(String(v).replace('T', ' ').replace(/-/g, '/'))
  const diff = Date.now() - d.getTime()
  if (isNaN(diff)) return '-'
  const m = Math.floor(diff / 60000)
  if (m < 1) return '刚刚'
  if (m < 60) return m + ' 分钟前'
  const h = Math.floor(m / 60)
  if (h < 24) return h + ' 小时前'
  const day = Math.floor(h / 24)
  if (day < 30) return day + ' 天前'
  return fmtDate(v)
}

export function fmtNum(v, digits = 2) {
  if (v === null || v === undefined || v === '') return '-'
  const n = Number(v)
  if (isNaN(n)) return '-'
  return n.toLocaleString('zh-CN', { minimumFractionDigits: 0, maximumFractionDigits: digits })
}

/** 状态 → Element Plus tag 类型；状态不只靠颜色表达，中文标签同步显示 */
export function statusType(status) {
  const map = {
    // 通用正向
    已完成: 'success', 已通过: 'success', 已批阅: 'success', 已生效: 'success',
    已关闭: 'success', 正常: 'success', 优秀: 'success', 启用: 'success', 学生已确认: 'success',
    // 进行中
    实习中: 'primary', 过程周报: 'primary', 阶段检查: 'primary', 企业评价: 'primary',
    处置中: 'primary', 评价中: 'primary', 审批中: 'primary', 协议审核: 'primary', 学校归档: 'primary',
    // 待办 / 警示
    实习备案: 'warning', 待审核: 'warning', 待批阅: 'warning', 待提交: 'warning',
    待评价: 'warning', 待处置: 'warning', 待确认: 'warning', 即将超时: 'warning', 中: 'warning',
    良好: 'primary', 合格: 'info', 低: 'info',
    // 异常
    已退修: 'danger', 已驳回: 'danger', 已中止: 'danger', 逾期: 'danger', 异常: 'danger',
    材料不全: 'danger', 高: 'danger', 停用: 'danger', 待改进: 'danger'
  }
  return map[status] || 'info'
}

/** 百分比展示，后端已算好比例时不重复计算 */
export function fmtPct(v, digits = 1) {
  if (v === null || v === undefined || v === '') return '-'
  const n = Number(v)
  return isNaN(n) ? '-' : n.toFixed(digits) + '%'
}
