<template>
  <div class="portal">
    <!-- 前台门户：导航 + 内容流，与后台管理风格明显区分 -->
    <header class="nav">
      <div class="wrap">
        <div class="brand">
          <div class="mark">实</div>
          <div class="txt">
            <strong>大学生实习过程与周报管理系统</strong>
            <span>Internship Process & Weekly Report Platform</span>
          </div>
        </div>
        <nav class="links">
          <router-link to="/portal">实习信息公开</router-link>
          <router-link to="/portal/report">优秀周报样例</router-link>
          <a href="#/login" class="enter">进入系统</a>
        </nav>
      </div>
    </header>

    <router-view />

    <footer class="foot">
      <div class="wrap">
        <span>教务处实习管理科 · 实习过程留痕平台</span>
        <span>数据来源于实习档案、周报与双导师评价，每日同步</span>
      </div>
    </footer>
  </div>
</template>

<script setup>
// 公开门户布局：不依赖登录态，供学生与企业查看实习公开信息
</script>

<style scoped>
.portal { min-height: 100vh; background: var(--bg); display: flex; flex-direction: column; }
.nav { background: #1c3f2f; color: #fff; }
.wrap { max-width: 1180px; margin: 0 auto; padding: 0 24px; display: flex; align-items: center; justify-content: space-between; height: 68px; }
.brand { display: flex; align-items: center; gap: 12px; }
.mark { width: 36px; height: 36px; border-radius: 8px; background: #3a7d5a; display: grid; place-items: center; font-weight: 700; }
.txt strong { display: block; font-size: 15px; letter-spacing: .3px; }
.txt span { font-size: 10.5px; color: #9dbfab; letter-spacing: .4px; }
.links { display: flex; align-items: center; gap: 26px; font-size: 13.5px; }
.links a { color: #d6e6dc; }
.links a.router-link-active { color: #fff; font-weight: 600; }
.links .enter { border: 1px solid #5b9a7a; border-radius: 6px; padding: 6px 14px; color: #fff; }
.foot { background: #fff; border-top: 1px solid var(--line); margin-top: 32px; }
.foot .wrap { height: 60px; font-size: 12px; color: var(--text-2); }
</style>
