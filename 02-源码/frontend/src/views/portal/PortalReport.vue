<template>
  <div class="wrap">
    <h2>优秀周报样例</h2>
    <p class="sub">结构完整、任务可验证、问题与计划具体的周报更容易通过批阅，并在里程碑完整度检查中得分更高。</p>

    <div class="reports">
      <article v-for="r in reports" :key="r.no" class="rep">
        <img :src="r.img" :alt="r.title" />
        <div class="body">
          <div class="top">
            <span class="no">{{ r.no }}</span>
            <el-tag size="small" type="success">{{ r.grade }}</el-tag>
          </div>
          <h3>{{ r.title }}</h3>
          <div class="meta">{{ r.company }} · 第 {{ r.week }} 周</div>
          <dl>
            <dt>本周任务</dt><dd>{{ r.task }}</dd>
            <dt>学习收获</dt><dd>{{ r.harvest }}</dd>
            <dt>遇到问题</dt><dd>{{ r.problem }}</dd>
            <dt>下周计划</dt><dd>{{ r.plan }}</dd>
          </dl>
          <div class="score">完整度得分 <b>{{ r.score }}</b> / 100</div>
        </div>
      </article>
    </div>
  </div>
</template>

<script setup>
/** 公开门户周报样例：内容与图片均取自本地种子资源，不依赖登录态与外链 */
const reports = [
  {
    no: 'WR20261031106', week: 8, grade: '优秀', score: 92.5,
    title: '完成订单模块接口联调与压测',
    company: '杭州云枢科技有限公司',
    task: '完成订单查询、退款两个接口的联调；补齐 12 条边界用例；把慢查询从 1.8s 优化到 240ms。',
    harvest: '学会用执行计划定位索引失效，理解了分页深翻页的性能问题。',
    problem: '退款回调偶发重复，排查发现是幂等键设计缺失，已补上唯一约束。',
    plan: '下周完成对账任务，并把压测脚本沉淀到团队仓库。',
    img: '/uploads/seed/work/01.jpg'
  },
  {
    no: 'WR20261024105', week: 7, grade: '优秀', score: 89.0,
    title: '完成月度凭证核对与差异分析',
    company: '宁波甬信会计师事务所',
    task: '核对 3 家客户共 1260 张凭证，整理差异清单 27 条，输出差异说明表。',
    harvest: '熟悉了抽查底稿的编制规范，学会用透视表快速定位异常科目。',
    problem: '有一类费用科目口径不一致，已向项目经理确认统一口径。',
    plan: '下周跟进差异回函，并补齐抽查底稿的签字页。',
    img: '/uploads/seed/work/02.jpg'
  },
  {
    no: 'WR20261017104', week: 6, grade: '良好', score: 85.5,
    title: '参与短视频选题会与脚本撰写',
    company: '杭州拾光传媒有限公司',
    task: '参加 2 次选题会，独立完成 3 条短视频脚本，其中 1 条已进入拍摄。',
    harvest: '学会了从用户评论里提炼选题，脚本节奏控制在 45 秒内更易完播。',
    problem: '脚本被退改两次，主要问题是开头 3 秒钩子不够。',
    plan: '下周复盘已发布视频的数据，产出 5 个钩子模板。',
    img: '/uploads/seed/work/03.jpg'
  }
]
</script>

<style scoped>
.wrap { max-width: 1180px; margin: 0 auto; padding: 32px 24px 0; }
h2 { font-size: 19px; color: var(--primary); margin: 0 0 6px; }
.sub { font-size: 12.5px; color: var(--text-2); margin: 0 0 22px; }
.reports { display: grid; grid-template-columns: repeat(3, 1fr); gap: 16px; }
.rep { background: #fff; border: 1px solid var(--line); border-radius: 8px; overflow: hidden; }
.rep img { width: 100%; height: 148px; object-fit: cover; display: block; }
.rep .body { padding: 14px 16px 16px; }
.top { display: flex; justify-content: space-between; align-items: center; }
.no { font-family: var(--mono); font-size: 11.5px; color: var(--text-2); }
.rep h3 { font-size: 14px; margin: 8px 0 4px; }
.meta { font-size: 11.5px; color: var(--text-2); margin-bottom: 10px; }
dl { margin: 0; font-size: 12.5px; line-height: 1.75; }
dt { color: var(--secondary); font-weight: 600; margin-top: 6px; }
dd { margin: 0; color: var(--text); }
.score { margin-top: 12px; font-size: 12.5px; color: var(--text-2); border-top: 1px dashed var(--line); padding-top: 10px; }
.score b { color: var(--primary); font-size: 16px; }
</style>
