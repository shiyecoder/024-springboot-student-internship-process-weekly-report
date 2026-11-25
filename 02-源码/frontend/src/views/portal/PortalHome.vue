<template>
  <div class="portal-home">
    <!-- 前台门户：导航 + 内容流，与后台管理风格明显区分 -->
    <section class="hero">
      <div class="wrap">
        <div class="hero-text">
          <h1>实习过程全留痕，周报评价可追溯</h1>
          <p>面向集中实习与自主实习的过程管理平台：企业备案、材料校验、周报批阅、考勤确认、异常关怀与双导师评价，一条链路走完。</p>
          <div class="hero-ops">
            <a href="#/login" class="btn">进入系统</a>
            <a href="#/portal/report" class="btn ghost">看优秀周报</a>
          </div>
        </div>
        <div class="hero-card">
          <div class="hc-title">本周待办提醒</div>
          <ul>
            <li><span>周报提交</span><b>周日 23:59 截止</b></li>
            <li><span>导师批阅</span><b>48 小时内完成</b></li>
            <li><span>考勤确认</span><b>次月 5 日前</b></li>
            <li><span>变更审批</span><b>教师 → 管理员两级</b></li>
          </ul>
        </div>
      </div>
    </section>

    <section class="wrap block">
      <h2>六步实习流程</h2>
      <p class="sub">每一步都有对应单据与责任人，越级操作会被系统拒绝</p>
      <div class="steps">
        <div v-for="(s, i) in steps" :key="s.t" class="step">
          <div class="no">{{ String(i + 1).padStart(2, '0') }}</div>
          <div class="t">{{ s.t }}</div>
          <div class="d">{{ s.d }}</div>
        </div>
      </div>
    </section>

    <section class="wrap block">
      <h2>合作企业（节选）</h2>
      <p class="sub">企业库记录资质、往年接收情况、学生评价与风险状态</p>
      <div class="companies">
        <div v-for="c in companies" :key="c.name" class="company">
          <img :src="c.img" :alt="c.name" />
          <div class="cinfo">
            <div class="cname">{{ c.name }}</div>
            <div class="cmeta">{{ c.industry }} · {{ c.city }} · 平均 {{ c.score }} 分</div>
          </div>
        </div>
      </div>
    </section>

    <section class="wrap block">
      <h2>常见问题</h2>
      <el-collapse>
        <el-collapse-item v-for="q in faqs" :key="q.q" :title="q.q">
          <p class="muted">{{ q.a }}</p>
        </el-collapse-item>
      </el-collapse>
    </section>
  </div>
</template>

<script setup>
/** 公开门户：不依赖登录态，图片使用本地 seed 文件，断网也能显示 */
const steps = [
  { t: '实习备案', d: '学生填写企业、岗位、时间与材料，提交后进入审核' },
  { t: '协议审核', d: '校内教师核验三方协议、意外险与接收函' },
  { t: '过程周报', d: '每周提交任务、收获、问题与下周计划，教师批阅或退修' },
  { t: '阶段检查', d: '按里程碑检查任务完成度，异常可上报关怀' },
  { t: '企业评价', d: '企业导师确认到岗、考勤与工作表现并评分' },
  { t: '学校归档', d: '校内教师评价后按 40/40/20 加权形成结项总评' }
]

const companies = [
  { name: '杭州云枢科技有限公司', industry: '信息技术', city: '杭州', score: 4.6, img: '/uploads/seed/company/01.jpg' },
  { name: '宁波甬信会计师事务所', industry: '会计', city: '宁波', score: 4.3, img: '/uploads/seed/company/02.jpg' },
  { name: '北京字节跳动科技有限公司', industry: '信息技术', city: '北京', score: 4.5, img: '/uploads/seed/company/03.jpg' },
  { name: '杭州拾光传媒有限公司', industry: '传媒', city: '杭州', score: 4.1, img: '/uploads/seed/company/04.jpg' },
  { name: '浙江建工集团第三建设有限公司', industry: '建筑', city: '杭州', score: 4.0, img: '/uploads/seed/company/05.jpg' },
  { name: '上海联影医疗科技股份有限公司', industry: '医疗', city: '上海', score: 4.4, img: '/uploads/seed/company/06.jpg' }
]

const faqs = [
  { q: '实习期间换企业怎么办？', a: '在系统提交变更申请，填写原因并上传证明。教师初审、管理员复审通过后生效，生效前原档案仍然有效，变更前后信息都会保留。' },
  { q: '周报可以补交吗？', a: '可以。批次设置了 2 天宽限期，超过宽限期会标记为逾期并计入完整度检查的连续性因素，不会直接判零分。' },
  { q: '为什么我的周报被退修？', a: '常见原因是任务描述过于笼统、未对应里程碑、缺少附件或问题与计划空白。退修意见会写明需要补充的内容，修改后可重新提交。' }
]
</script>

<style scoped>
.wrap { max-width: 1180px; margin: 0 auto; padding: 0 24px; }

.hero { background: linear-gradient(140deg, #1c3f2f 0%, #2a5f45 60%, #3a7d5a 100%); color: #fff; padding: 56px 0; }
.hero .wrap { display: flex; gap: 40px; align-items: center; }
.hero-text { flex: 1.4; }
.hero-text h1 { font-size: 30px; margin: 0 0 14px; letter-spacing: .5px; }
.hero-text p { font-size: 14px; line-height: 1.9; color: #d3e3d9; max-width: 560px; margin: 0 0 24px; }
.hero-ops { display: flex; gap: 12px; }
.btn { background: #fff; color: #1c3f2f; padding: 10px 22px; border-radius: 6px; font-size: 14px; font-weight: 500; }
.btn.ghost { background: transparent; color: #fff; border: 1px solid rgba(255,255,255,.55); }

.hero-card { flex: 1; background: rgba(255,255,255,.1); border: 1px solid rgba(255,255,255,.18); border-radius: 8px; padding: 18px 20px; }
.hc-title { font-size: 13px; color: #cfe3d7; margin-bottom: 10px; }
.hero-card ul { list-style: none; padding: 0; margin: 0; }
.hero-card li { display: flex; justify-content: space-between; font-size: 13px; padding: 9px 0; border-bottom: 1px dashed rgba(255,255,255,.16); }
.hero-card li:last-child { border-bottom: none; }
.hero-card b { color: #fff; font-weight: 500; }

.block { padding: 34px 0 6px; }
.block h2 { font-size: 19px; color: var(--primary); margin: 0 0 6px; }
.block .sub { font-size: 12.5px; color: var(--text-2); margin: 0 0 18px; }

.steps { display: grid; grid-template-columns: repeat(6, 1fr); gap: 12px; }
.step { background: #fff; border: 1px solid var(--line); border-radius: 8px; padding: 14px; }
.step .no { font-family: var(--mono); font-size: 12px; color: var(--secondary); }
.step .t { font-size: 13.5px; font-weight: 600; margin: 6px 0; }
.step .d { font-size: 12px; color: var(--text-2); line-height: 1.7; }

.companies { display: grid; grid-template-columns: repeat(3, 1fr); gap: 14px; }
.company { display: flex; gap: 12px; background: #fff; border: 1px solid var(--line); border-radius: 8px; padding: 12px; }
.company img { width: 76px; height: 56px; object-fit: cover; border-radius: 6px; }
.cname { font-size: 13px; font-weight: 500; }
.cmeta { font-size: 11.5px; color: var(--text-2); margin-top: 4px; }
</style>
