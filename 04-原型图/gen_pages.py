#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""生成 design/pages 下的可交互 HTML 原型。所有页面共用 ../mock.css。"""
import os

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "pages")
os.makedirs(OUT, exist_ok=True)

NAV_ADMIN = [
    ("工作台", [("/pages/02_dashboard.html", "实习质量看板", ""), ("/pages/05_report.html", "周报工作台", "6")]),
    ("实习过程", [("/pages/03_application.html", "实习备案中心", ""), ("/pages/04_detail.html", "档案详情", ""),
                  ("/pages/10_attendance.html", "考勤汇总", ""), ("/pages/11_change.html", "变更审批", "2"),
                  ("/pages/12_issue.html", "异常关怀", "1"), ("/pages/13_visit.html", "走访记录", "")]),
    ("周报评价", [("/pages/06_review.html", "导师批阅", ""), ("/pages/07_milestone.html", "里程碑进度", ""),
                  ("/pages/14_evaluation.html", "结项评价", "")]),
    ("基础数据", [("/pages/08_company.html", "企业库", ""), ("/pages/09_batch.html", "实习批次", "")]),
    ("分析配置", [("/pages/16_board.html", "统计看板", ""), ("/pages/15_rule.html", "规则配置", "")]),
    ("系统", [("/pages/19_role.html", "角色管理", ""), ("/pages/20_message.html", "消息中心", "3"),
              ("/pages/18_profile.html", "个人中心", "")]),
]

NAV_TEACHER = [
    ("工作台", [("/pages/02_dashboard.html", "待批阅工作台", "9")]),
    ("实习过程", [("/pages/03_application.html", "我的学生", ""), ("/pages/12_issue.html", "异常关怀", ""),
                  ("/pages/13_visit.html", "走访记录", "")]),
    ("周报评价", [("/pages/06_review.html", "周报批阅", ""), ("/pages/07_milestone.html", "里程碑进度", ""),
                  ("/pages/14_evaluation.html", "校内评价", "")]),
    ("系统", [("/pages/20_message.html", "消息中心", ""), ("/pages/18_profile.html", "个人中心", "")]),
]


def nav(groups, active):
    buf = ['<nav class="nav">']
    for g, items in groups:
        buf.append(f'<div class="group">{g}</div>')
        for href, label, badge in items:
            on = " on" if label == active else ""
            b = f'<span class="badge">{badge}</span>' if badge else ""
            buf.append(f'<a class="{on.strip()}" href="{href}">{label}{b}</a>')
    buf.append("</nav>")
    return "\n".join(buf)


def shell(title, body, active, role="实习管理员", groups=NAV_ADMIN, crumb=None):
    crumb = crumb or title
    return f"""<!DOCTYPE html>
<html lang="zh-CN"><head><meta charset="utf-8"><title>{title} · 实习管理系统</title>
<link rel="stylesheet" href="../mock.css"></head>
<body><div class="shell">
<aside class="side">
  <div class="brand"><span class="mark">实习</span>实习过程管理</div>
  {nav(groups, active)}
</aside>
<div class="main">
  <header class="top">
    <div class="crumb">实习过程管理 / <b>{crumb}</b></div>
    <div class="spacer"></div>
    <a class="icon-btn" href="/pages/20_message.html" title="消息">✉</a>
    <span class="hint">{role}</span><div class="avatar">林</div>
  </header>
  <main class="content">{body}</main>
</div></div></body></html>"""


def portal_shell(title, body, active="我的实习"):
    links = ["首页", "我的实习", "周报提交", "考勤确认", "结项材料"]
    navs = "".join(
        f'<a class="{"on" if l == active else ""}" href="/pages/17_portal.html">{l}</a>' for l in links)
    return f"""<!DOCTYPE html>
<html lang="zh-CN"><head><meta charset="utf-8"><title>{title} · 学生实习门户</title>
<link rel="stylesheet" href="../mock.css"></head>
<body class="portal">
<div class="pnav"><div class="logo">实习过程管理 · 学生端</div>{navs}
<div style="flex:1"></div><span class="hint">2026 春季批次</span><div class="avatar">陈</div></div>
<div class="pwrap">{body}</div></body></html>"""


def kpi(label, value, delta=""):
    d = f'<div class="delta">{delta}</div>' if delta else ""
    return f'<div class="kpi"><div class="label">{label}</div><div class="value">{value}</div>{d}</div>'


def bars(vals):
    return '<div class="bars">' + "".join(f'<i style="height:{v}%"></i>' for v in vals) + "</div>"


def pager(total="共 128 条"):
    return (f'<div class="pager"><span>{total}</span><span class="pg">‹</span>'
            '<span class="pg on">1</span><span class="pg">2</span><span class="pg">3</span>'
            '<span class="pg">›</span><span>每页 10 条</span></div>')


PAGES = {}

# 01 登录
PAGES["01_login"] = """<!DOCTYPE html><html lang="zh-CN"><head><meta charset="utf-8">
<title>登录 · 实习过程管理系统</title><link rel="stylesheet" href="../mock.css">
<style>
body{margin:0;min-height:100vh;display:grid;grid-template-columns:1.1fr .9fr;font-family:-apple-system,"PingFang SC",sans-serif}
.l{background:linear-gradient(150deg,#1B3E2F,#234E3B 45%,#3A7D5A);color:#fff;padding:56px 64px;display:flex;flex-direction:column;justify-content:space-between;position:relative;overflow:hidden}
.l::after{content:"";position:absolute;right:-120px;bottom:-160px;width:420px;height:420px;border:1px solid rgba(255,255,255,.14);border-radius:50%}
.l::before{content:"";position:absolute;right:-40px;bottom:-240px;width:520px;height:520px;border:1px solid rgba(255,255,255,.09);border-radius:50%}
.l h1{font-size:30px;line-height:42px;margin:0 0 12px;font-weight:600}
.l p{color:#BFD9CB;font-size:14px;max-width:420px}
.l .steps{display:flex;gap:8px;flex-wrap:wrap;font-size:12px;color:#D7E9DE}
.l .steps span{border:1px solid rgba(255,255,255,.28);border-radius:14px;padding:3px 12px}
.r{display:grid;place-items:center;background:#F7FAF8}
.form{width:360px}
.form h2{font-size:22px;margin:0 0 6px}
.form .tip{color:#63736B;font-size:13px;margin-bottom:26px}
.form input{width:100%;height:44px;margin-bottom:14px;border:1px solid #DCE7E0;border-radius:8px;padding:0 14px;font-size:14px}
.form .btn{width:100%;height:44px;font-size:15px;border-radius:8px;background:#234E3B;color:#fff;border:0}
.roles{display:flex;gap:6px;margin-bottom:18px;font-size:12px;color:#63736B}
.roles span{border:1px solid #DCE7E0;border-radius:12px;padding:2px 10px;background:#fff}
.roles span.on{border-color:#3A7D5A;color:#234E3B;background:#E6F3EB}
</style></head><body>
<div class="l">
  <div><div style="display:flex;align-items:center;gap:10px;margin-bottom:48px">
    <div style="width:30px;height:30px;border-radius:8px;background:#8FC7A8"></div>
    <b style="font-size:16px">实习过程与周报管理系统</b></div>
    <h1>实习开始之后，<br>每一步都有留痕</h1>
    <p>企业与岗位备案、协议材料、周报批阅、月度考勤、变更审批、双导师评价与结项归档，一条链路闭环。</p></div>
  <div class="steps"><span>实习备案</span><span>协议审核</span><span>过程周报</span><span>阶段检查</span><span>企业评价</span><span>学校归档</span></div>
</div>
<div class="r"><form class="form">
  <h2>登录</h2><div class="tip">使用学校统一分配的实习系统账号</div>
  <div class="roles"><span class="on">学生</span><span>校内导师</span><span>企业导师</span><span>管理员</span></div>
  <input placeholder="账号 / 学号" value="2022010312">
  <input type="password" placeholder="密码" value="123456">
  <button class="btn" type="button" onclick="location.href='02_dashboard.html'">登 录</button>
  <div style="margin-top:16px;font-size:12px;color:#63736B">连续 5 次失败将锁定 10 分钟 · 忘记密码联系院系管理员</div>
</form></div></body></html>"""

# 02 看板
cards = "".join([
    '<div class="chart"><div class="ct">近 6 个月实习人数<span>人</span></div>' + bars([42, 58, 65, 71, 88, 96]) +
    '<div class="legend"><span><i style="background:#3A7D5A"></i>在岗人数</span></div></div>',
    '<div class="chart"><div class="ct">实习阶段分布<span>共 128 人</span></div><div class="donut"></div>'
    '<div class="legend"><span><i style="background:#234E3B"></i>实习中 42%</span><span><i style="background:#3A7D5A"></i>待结项 26%</span>'
    '<span><i style="background:#9DB8A8"></i>待审核 18%</span><span><i style="background:#C9DBD0"></i>已完成 14%</span></div></div>',
    '<div class="chart"><div class="ct">周报提交及时率<span>近 8 周</span></div>' + bars([72, 78, 69, 84, 88, 81, 92, 90]) + '</div>',
    '<div class="chart"><div class="ct">行业分布 Top6<span>企业数</span></div>' + bars([90, 76, 62, 54, 40, 28]) +
    '<div class="legend"><span><i style="background:#3A7D5A"></i>信息技术 · 制造 · 金融 · 教育 · 医疗 · 建筑</span></div></div>',
    '<div class="chart"><div class="ct">企业评分区间<span>家</span></div>' + bars([30, 55, 68, 82, 46]) + '</div>',
    '<div class="chart"><div class="ct">里程碑完整度结果<span>创新模块</span></div>' + bars([26, 48, 72, 58, 34]) +
    '<div class="legend"><span><i style="background:#234E3B"></i>优秀 26 · 良好 48 · 合格 72 · 待改进 58 · 不推荐 34</span></div></div>',
])

PAGES["02_dashboard"] = shell("实习质量看板", f"""
<h1>实习质量看板</h1><div class="sub">2026 春季批次 · 数据截至 2026-10-31 20:00 · 默认展示最近 30 天</div>
<div class="toolbar"><select><option>2026 春季批次</option><option>2025 秋季批次</option></select>
<select><option>全部院系</option><option>计算机学院</option></select>
<select><option>最近 30 天</option><option>本季度</option><option>本年</option></select>
<button class="btn ghost">导出</button><div style="flex:1"></div>
<button class="btn primary" onclick="location.href='03_application.html'">新建实习备案</button></div>
<div class="kpis">{kpi("实习人数", "128", "环比 +8")}{kpi("周报提交率", "92.4%", "环比 +3.1pp")}
{kpi("批阅及时率", "86.7%", "环比 +1.4pp")}{kpi("里程碑完成率", "74.2%", "")}
{kpi("异常实习数", "6", "较上周 -2")}{kpi("企业平均评分", "4.32", "满分 5")}</div>
<div class="grid" style="grid-template-columns:repeat(3,1fr)">{cards}</div>
""", "实习质量看板")

# 03 实习备案中心
rows = [
    ("SI20260031", "陈知远", "2022 级软件工程", "杭州云枢科技", "后端开发实习", "李明华", "周建国", "待审核", "t-amber", "2026-10-28"),
    ("SI20260030", "宋雨桐", "2022 级数据科学", "宁波甬信会计师事务所", "数据分析助理", "李明华", "王倩", "协议审核", "t-blue", "2026-10-26"),
    ("SI20260029", "赵一鸣", "2022 级网络工程", "浙江中控技术", "运维实习", "陈立群", "刘畅", "实习中", "t-green", "2026-10-21"),
    ("SI20260028", "周若菡", "2021 级计算机", "上海远景能源", "产品运营实习", "陈立群", "孙悦", "实习中", "t-green", "2026-10-18"),
    ("SI20260027", "林嘉禾", "2022 级软件工程", "杭州拾光传媒", "前端开发实习", "李明华", "郑楠", "待结项", "t-blue", "2026-10-12"),
    ("SI20260026", "吴承宇", "2021 级软件工程", "深圳恒瑞医疗", "测试实习", "王慧", "黄磊", "已完成", "t-gray", "2026-09-30"),
    ("SI20260025", "何书宁", "2022 级人工智能", "北京字节跳动", "算法实习", "王慧", "张一凡", "已中止", "t-red", "2026-09-24"),
    ("SI20260024", "郑亦航", "2022 级软件工程", "杭州同花顺", "Java 开发实习", "李明华", "方晓", "实习中", "t-green", "2026-09-18"),
]
tr = "".join(f"""<tr><td><a href="04_detail.html">{no}</a></td><td>{name}</td><td>{major}</td><td>{comp}</td>
<td>{pos}</td><td>{t1}</td><td>{t2}</td><td><span class="tag {cls}">{st}</span></td><td class="num">{d}</td>
<td><button class="btn sm">查看</button> <button class="btn sm ghost">流转</button></td></tr>"""
             for no, name, major, comp, pos, t1, t2, st, cls, d in rows)

PAGES["03_application"] = shell("实习备案中心", f"""
<h1>实习备案中心</h1><div class="sub">共 128 条实习档案 · 待审核 6 条 · 今日新增 3 条</div>
<div class="card" style="margin-bottom:16px">
  <div class="toolbar" style="margin-bottom:0">
    <input class="search" placeholder="实习编号 / 学生姓名">
    <select><option>全部学院</option><option>计算机学院</option><option>商学院</option></select>
    <select><option>全部企业</option></select>
    <select><option>全部阶段</option><option>待审核</option><option>待到岗</option><option>实习中</option><option>待结项</option><option>已完成</option></select>
    <select><option>周报状态</option><option>待提交</option><option>待批阅</option><option>已退修</option></select>
    <input type="date" value="2026-05-01" style="width:150px"><span class="hint">至</span><input type="date" value="2026-10-31" style="width:150px">
    <button class="btn primary">查询</button><button class="btn">重置</button>
    <div style="flex:1"></div><button class="btn ghost">高级筛选</button><button class="btn">导出当前结果</button>
  </div>
</div>
<div class="card">
<table><thead><tr><th>实习编号</th><th>学生</th><th>专业</th><th>企业</th><th>岗位</th><th>校内导师</th><th>企业导师</th><th>当前阶段</th><th>开始日期</th><th>操作</th></tr></thead>
<tbody>{tr}</tbody></table>{pager("共 128 条")}
</div>""", "实习备案中心")

# 04 详情
PAGES["04_detail"] = shell("实习档案详情", """
<h1>SI20260031 · 陈知远</h1>
<div class="sub">状态 <span class="tag t-amber">待审核</span> · 责任人 李明华（校内导师）· 创建 2026-10-28 09:12:04 · 最近更新 2026-10-30 16:40:11</div>
<div class="flow" style="margin-bottom:16px">
  <span class="st on">实习备案</span><span class="arw">→</span><span class="st">协议审核</span><span class="arw">→</span>
  <span class="st">过程周报</span><span class="arw">→</span><span class="st">阶段检查</span><span class="arw">→</span>
  <span class="st">企业评价</span><span class="arw">→</span><span class="st">学校归档</span></div>
<div class="split">
 <div class="card">
  <h2>基础信息</h2>
  <div class="kv">
    <div><span>学生</span>陈知远 / 2022010312</div><div><span>学院</span>计算机学院</div><div><span>专业</span>软件工程</div>
    <div><span>企业</span>杭州云枢科技有限公司</div><div><span>岗位</span>后端开发实习</div><div><span>企业风险</span><span class="tag t-green">正常</span></div>
    <div><span>校内导师</span>李明华</div><div><span>企业导师</span>周建国</div><div><span>开始日期</span>2026-11-03</div>
    <div><span>结束日期</span>2027-02-28</div><div><span>实习来源</span>集中实习</div><div><span>保险</span><span class="tag t-green">已上传</span></div>
  </div>
  <div class="note" style="margin-top:14px">协议附件：实习三方协议.pdf（2.1MB）· 人身意外险保单.pdf（860KB）· 企业接收函.pdf（410KB）</div>
  <h2 style="margin-top:20px">阶段里程碑</h2>
  <table><thead><tr><th>序号</th><th>里程碑</th><th>计划周次</th><th>状态</th><th>完成时间</th></tr></thead><tbody>
   <tr><td>1</td><td>入职与安全培训</td><td>第 1 周</td><td><span class="tag t-green">已完成</span></td><td class="num">2026-11-05</td></tr>
   <tr><td>2</td><td>熟悉订单服务代码</td><td>第 3 周</td><td><span class="tag t-green">已完成</span></td><td class="num">2026-11-19</td></tr>
   <tr><td>3</td><td>独立完成查询接口</td><td>第 6 周</td><td><span class="tag t-amber">进行中</span></td><td class="num">—</td></tr>
   <tr><td>4</td><td>性能优化与复盘</td><td>第 10 周</td><td><span class="tag t-gray">未开始</span></td><td class="num">—</td></tr>
  </tbody></table>
 </div>
 <div>
  <div class="card" style="margin-bottom:16px"><h2>附件</h2>
   <div class="row" style="gap:10px">
    <div style="width:104px"><div style="height:72px;background:#EEF2F0;border-radius:4px;display:grid;place-items:center;color:#63736B">协议</div><div class="hint" style="margin-top:4px">三方协议.pdf</div></div>
    <div style="width:104px"><div style="height:72px;background:#EEF2F0;border-radius:4px;display:grid;place-items:center;color:#63736B">保单</div><div class="hint" style="margin-top:4px">意外险.pdf</div></div>
    <div style="width:104px"><div style="height:72px;background:#EEF2F0;border-radius:4px;display:grid;place-items:center;color:#63736B">接收函</div><div class="hint" style="margin-top:4px">接收函.pdf</div></div>
   </div></div>
  <div class="card" style="margin-bottom:16px"><h2>关联单据</h2>
   <table><tbody>
    <tr><td>周报</td><td><a href="06_review.html">WR20261109001</a></td><td><span class="tag t-green">已批阅</span></td></tr>
    <tr><td>周报</td><td><a href="06_review.html">WR20261116002</a></td><td><span class="tag t-amber">待批阅</span></td></tr>
    <tr><td>考勤</td><td><a href="10_attendance.html">AT202611</a></td><td><span class="tag t-blue">待确认</span></td></tr>
    <tr><td>变更</td><td><a href="11_change.html">CH202612001</a></td><td><span class="tag t-gray">已生效</span></td></tr>
   </tbody></table></div>
  <div class="card"><h2>操作日志</h2>
   <ul class="timeline">
    <li><b>提交备案</b><div class="m">陈知远 · 2026-10-28 09:12:04 · 待建 → 待审核</div></li>
    <li><b>补充协议材料</b><div class="m">陈知远 · 2026-10-29 14:02:55 · 上传三方协议</div></li>
    <li><b>校内导师初审通过</b><div class="m">李明华 · 2026-10-30 16:40:11 · 待审核 → 协议审核</div></li>
   </ul></div>
 </div></div>""", "档案详情")

# 05 周报工作台
wr = [("WR20261030008", "陈知远", "第 8 周 · 订单查询接口联调", "待批阅", "t-amber", "2026-10-30 18:22"),
      ("WR20261030007", "宋雨桐", "第 8 周 · 客户流水抽样复核", "已退修", "t-red", "2026-10-30 17:05"),
      ("WR20261030006", "赵一鸣", "第 8 周 · 机房巡检与告警处理", "已批阅", "t-green", "2026-10-30 10:41"),
      ("WR20261023005", "周若菡", "第 7 周 · 竞品调研与需求梳理", "已批阅", "t-green", "2026-10-23 19:10"),
      ("WR20261023004", "林嘉禾", "第 7 周 · 组件库重构", "逾期未交", "t-red", "2026-10-23 00:00")]
wtr = "".join(f"""<tr><td><a href="06_review.html">{no}</a></td><td>{n}</td><td>{t}</td>
<td><span class="tag {c}">{s}</span></td><td class="num">{d}</td>
<td><button class="btn sm">查看</button> <button class="btn sm ghost">批阅</button></td></tr>""" for no, n, t, s, c, d in wr)
PAGES["05_report"] = shell("周报工作台", f"""
<h1>周报工作台</h1><div class="sub">待本人处理优先 · 更新时间倒序 · 本周应收 128 份，已收 118 份</div>
<div class="toolbar">
  <span class="tag t-green">全部 128</span><span class="tag t-amber">待批阅 6</span>
  <span class="tag t-red">已退修 4</span><span class="tag t-gray">逾期 3</span>
  <div style="flex:1"></div><select><option>第 8 周</option><option>第 7 周</option></select>
  <button class="btn primary">批量批阅</button>
</div>
<div class="card"><table><thead><tr><th>周报编号</th><th>学生</th><th>周次 / 本周任务</th><th>状态</th><th>提交时间</th><th>操作</th></tr></thead>
<tbody>{wtr}</tbody></table>{pager("共 128 条")}</div>""", "周报工作台")

# 06 导师批阅
PAGES["06_review"] = shell("导师批阅", """
<h1>WR20261030008 · 第 8 周周报</h1>
<div class="sub">陈知远 · 杭州云枢科技 · 企业导师 周建国 · 提交于 2026-10-30 18:22:41 · <span class="tag t-amber">待批阅</span></div>
<div class="split">
 <div class="card">
  <h2>本周任务</h2>
  <p style="margin:0 0 14px">完成订单查询接口的分页与排序能力，补充单元测试 12 条，覆盖空结果与超时分支。</p>
  <h2>学习收获</h2>
  <p style="margin:0 0 14px">掌握 MyBatis 分页插件与索引命中分析，理解了慢查询日志的读法。</p>
  <h2>遇到的问题</h2>
  <p style="margin:0 0 14px">联调环境中订单表数据量为 0，分页总数始终为 0，已与测试同学确认为环境问题。</p>
  <h2>下周计划</h2>
  <p style="margin:0 0 14px">接入缓存层，压测 QPS 200 场景；补充接口文档。</p>
  <h2>附件</h2>
  <div class="row"><div style="width:120px"><div style="height:80px;background:#EEF2F0;border-radius:4px"></div><div class="hint">联调截图.png</div></div>
  <div style="width:120px"><div style="height:80px;background:#EEF2F0;border-radius:4px"></div><div class="hint">测试报告.pdf</div></div></div>
  <div class="note" style="margin-top:16px">里程碑覆盖检查：任务 ✅ · 成果 ✅ · 问题 ✅ · 下周计划 ✅ · 附件 ✅ — 5/5 完整</div>
 </div>
 <div class="card">
  <h2>批阅</h2>
  <label class="f"><span>批阅结论</span><select style="width:100%"><option>通过</option><option>退修</option></select></label>
  <label class="f"><span>评分</span><input value="88" style="width:120px"></label>
  <div class="hint" style="margin:0 0 6px">评语（退修时必填，不少于 5 字）</div>
  <textarea style="width:100%;height:96px;border:1px solid #DCE7E0;border-radius:6px;padding:8px;font:13px/20px inherit">接口实现完整，问题描述清楚。建议补充慢查询前后的执行计划对比。</textarea>
  <div class="row" style="margin-top:12px"><button class="btn primary" style="flex:1">提交批阅</button><button class="btn danger">退修</button></div>
  <h2 style="margin-top:22px">审批与执行记录</h2>
  <ul class="timeline">
   <li><b>学生提交周报</b><div class="m">陈知远 · 2026-10-30 18:22:41</div></li>
   <li><b>企业导师确认工作内容</b><div class="m">周建国 · 2026-10-30 19:05:12</div></li>
   <li><b>校内导师批阅</b><div class="m">李明华 · 待处理</div></li>
  </ul>
 </div></div>""", "导师批阅")

# 07 里程碑进度（创新点）
fac = [("里程碑完成项", "3 / 4 项", "30%", "3 of 4 里程碑已完成，第 3 项进行中", "24.0"),
       ("周报连续性", "连续 8 周按时提交", "20%", "无缺交、无逾期", "20.0"),
       ("附件数量", "本周 2 个附件", "15%", "附件数量满足要求", "15.0"),
       ("导师反馈", "近 4 周平均 4.5 分", "15%", "批阅及时，评语具体", "13.5"),
       ("延期任务", "1 项任务延期 4 天", "10%", "接口联调延期 4 天", "6.0"),
       ("企业评价", "4.3 / 5", "10%", "企业导师月度评价", "8.6")]
ftr = "".join(f"""<tr><td>{n}</td><td>{v}</td><td class="num">{w}</td><td>{e}</td><td class="num">{s}</td></tr>""" for n, v, w, e, s in fac)
PAGES["07_milestone"] = shell("里程碑进度", f"""
<h1>周报里程碑完整度检查</h1>
<div class="sub">SI20260031 · 陈知远 · 第 8 周 · 规则版本 v3（2026-09-01 生效）· 计算于 2026-10-31 09:00:12</div>
<div class="kpis" style="grid-template-columns:repeat(4,1fr)">
 <div class="kpi"><div class="label">综合得分</div><div class="value">87.1</div><div class="delta">等级：良好</div></div>
 <div class="kpi"><div class="label">推荐结果</div><div class="value" style="font-size:20px;line-height:34px">通过检查</div><div class="delta">不阻断提交</div></div>
 <div class="kpi"><div class="label">未满足条件</div><div class="value">1</div><div class="delta" style="color:#B7791F">延期任务超阈值</div></div>
 <div class="kpi"><div class="label">人工调整</div><div class="value" style="font-size:20px;line-height:34px">未调整</div><div class="delta">原始结果保留</div></div>
</div>
<div class="split">
 <div class="card"><h2>输入依据与得分明细</h2>
  <table><thead><tr><th>输入因素</th><th>取值</th><th>权重</th><th>说明</th><th>得分</th></tr></thead><tbody>{ftr}</tbody></table>
  <div class="note" style="margin-top:12px">计算口径：各项得分 = 归一化取值 × 权重；缺少数据项不参与计算并在结果中标注「数据缺失」。相同输入与规则版本结果可复现。</div>
  <h2 style="margin-top:20px">规则权重（合计 100%）</h2>
  <div class="progress"><i style="width:100%"></i></div>
  <div class="hint" style="margin-top:6px">里程碑 30% · 连续性 20% · 附件 15% · 导师反馈 15% · 延期 10% · 企业评价 10%</div>
 </div>
 <div>
  <div class="card" style="margin-bottom:16px"><h2>结果解释</h2>
   <p style="margin:0 0 8px"><b>主要影响因素</b>：里程碑完成项（24.0 / 30）、周报连续性（20.0 / 20）。</p>
   <p style="margin:0 0 8px"><b>未满足条件</b>：延期任务 1 项，超过「延期 ≤ 0 项」阈值，扣 4.0 分。</p>
   <p style="margin:0"><b>可改进项</b>：将第 3 项里程碑拆分为两个子任务并提前一周排期；下周至少补充 1 份接口文档附件。</p>
  </div>
  <div class="card" style="margin-bottom:16px"><h2>人工修正</h2>
   <div class="hint">业务负责人可调整最终结果，必须填写原因；原始计算结果不被覆盖。</div>
   <label class="f" style="margin-top:10px"><span>调整后等级</span><select style="width:100%"><option>保持原结果</option><option>优秀</option><option>合格</option><option>待改进</option></select></label>
   <textarea style="width:100%;height:70px;border:1px solid #DCE7E0;border-radius:6px;padding:8px;font:13px/20px inherit" placeholder="调整原因（不少于 5 个字）"></textarea>
   <button class="btn primary" style="margin-top:10px;width:100%">保存修正</button>
  </div>
  <div class="card"><h2>历史计算</h2>
   <table><tbody>
    <tr><td>第 8 周</td><td class="num">87.1</td><td><span class="tag t-green">良好</span></td><td class="num">10-31 09:00</td></tr>
    <tr><td>第 7 周</td><td class="num">82.4</td><td><span class="tag t-green">良好</span></td><td class="num">10-24 09:00</td></tr>
    <tr><td>第 6 周</td><td class="num">76.0</td><td><span class="tag t-amber">合格</span></td><td class="num">10-17 09:00</td></tr>
    <tr><td>第 5 周</td><td class="num">68.5</td><td><span class="tag t-amber">合格</span></td><td class="num">10-10 09:00</td></tr>
   </tbody></table></div>
 </div></div>""", "里程碑进度")

# 08 企业库
comps = [("C0001", "杭州云枢科技有限公司", "信息技术", "杭州市余杭区", "周建国", "17", "4.6", "正常", "t-green"),
         ("C0002", "宁波甬信会计师事务所", "金融", "宁波市鄞州区", "王倩", "9", "4.2", "正常", "t-green"),
         ("C0003", "浙江中控技术股份有限公司", "制造", "杭州市滨江区", "刘畅", "22", "4.4", "正常", "t-green"),
         ("C0004", "杭州拾光传媒有限公司", "文化传媒", "杭州市西湖区", "郑楠", "5", "3.6", "关注", "t-amber"),
         ("C0005", "深圳恒瑞医疗器械", "医疗", "深圳市南山区", "黄磊", "6", "4.1", "正常", "t-green"),
         ("C0006", "某网络科技工作室", "信息技术", "杭州市拱墅区", "—", "1", "2.4", "风险", "t-red")]
ctr = "".join(f"""<tr><td>{i}</td><td>{n}</td><td>{ind}</td><td>{addr}</td><td>{c}</td>
<td class="num">{y}</td><td class="num">{s}</td><td><span class="tag {cls}">{st}</span></td>
<td><button class="btn sm">查看</button> <button class="btn sm ghost">编辑</button></td></tr>""" for i, n, ind, addr, c, y, s, st, cls in comps)
PAGES["08_company"] = shell("企业库", f"""
<h1>企业库</h1><div class="sub">共 46 家 · 风险企业 1 家 · 本年新增 12 家</div>
<div class="toolbar"><input class="search" placeholder="企业名称 / 联系人">
<select><option>全部行业</option><option>信息技术</option><option>制造</option></select>
<select><option>全部风险状态</option><option>正常</option><option>关注</option><option>风险</option></select>
<button class="btn primary">查询</button><div style="flex:1"></div><button class="btn primary">新增企业</button></div>
<div class="card"><table><thead><tr><th>企业编号</th><th>企业名称</th><th>行业</th><th>地址</th><th>联系人</th><th>往年接收</th><th>学生评价</th><th>风险状态</th><th>操作</th></tr></thead>
<tbody>{ctr}</tbody></table>{pager("共 46 条")}</div>""", "企业库")

# 09 批次
PAGES["09_batch"] = shell("实习批次", """
<h1>实习批次</h1><div class="sub">按学期维护批次规则，学生备案时继承批次配置</div>
<div class="toolbar"><button class="btn primary">新建批次</button><div style="flex:1"></div>
<span class="hint">当前生效：2026 春季批次（2026-09-01 ~ 2027-02-28）</span></div>
<div class="card" style="margin-bottom:16px">
<h2>2026 春季批次</h2>
<div class="kv">
 <div><span>学期</span>2026-2027 学年第一学期</div><div><span>适用院系</span>计算机学院 / 商学院</div><div><span>起止日期</span>2026-09-01 ~ 2027-02-28</div>
 <div><span>周报截止</span>每周日 23:59</div><div><span>补交宽限</span>2 天</div><div><span>状态</span><span class="tag t-green">启用</span></div>
 <div><span>评分构成</span>企业 40% / 校内 40% / 周报 20%</div><div><span>最低周报数</span>12 份</div><div><span>必交材料</span>协议、保险、结项报告</div>
</div></div>
<div class="card"><h2>批次列表</h2>
<table><thead><tr><th>批次编号</th><th>学期</th><th>院系</th><th>起止</th><th>周报截止</th><th>评分构成</th><th>状态</th><th>操作</th></tr></thead><tbody>
<tr><td>B2026S1</td><td>2026-2027 第一学期</td><td>计算机学院 / 商学院</td><td class="num">2026-09-01 ~ 2027-02-28</td><td>周日 23:59</td><td>40/40/20</td><td><span class="tag t-green">启用</span></td><td><button class="btn sm">编辑</button></td></tr>
<tr><td>B2025S2</td><td>2025-2026 第二学期</td><td>计算机学院</td><td class="num">2026-02-24 ~ 2026-07-10</td><td>周日 23:59</td><td>40/40/20</td><td><span class="tag t-gray">已归档</span></td><td><button class="btn sm">查看</button></td></tr>
<tr><td>B2025S1</td><td>2025-2026 第一学期</td><td>全校</td><td class="num">2025-09-01 ~ 2026-01-15</td><td>周日 23:59</td><td>50/30/20</td><td><span class="tag t-gray">已归档</span></td><td><button class="btn sm">查看</button></td></tr>
</tbody></table></div>""", "实习批次")

# 10 考勤
PAGES["10_attendance"] = shell("考勤汇总", """
<h1>考勤汇总</h1><div class="sub">2026 年 10 月 · 企业导师录入后由学生确认，异常需附说明</div>
<div class="toolbar"><select><option>2026 年 10 月</option><option>2026 年 09 月</option></select>
<select><option>全部企业</option></select><button class="btn primary">查询</button>
<div style="flex:1"></div><button class="btn ghost">导出汇总</button><button class="btn primary">录入考勤</button></div>
<div class="card"><table><thead><tr><th>学生</th><th>企业</th><th>月份</th><th>应出勤</th><th>实出勤</th><th>迟到</th><th>请假</th><th>确认状态</th><th>备注</th></tr></thead><tbody>
<tr><td>陈知远</td><td>杭州云枢科技</td><td>2026-10</td><td class="num">22</td><td class="num">21</td><td class="num">1</td><td class="num">1</td><td><span class="tag t-green">学生已确认</span></td><td>10-18 事假 1 天</td></tr>
<tr><td>宋雨桐</td><td>宁波甬信会计师事务所</td><td>2026-10</td><td class="num">22</td><td class="num">22</td><td class="num">0</td><td class="num">0</td><td><span class="tag t-amber">待学生确认</span></td><td>—</td></tr>
<tr><td>赵一鸣</td><td>浙江中控技术</td><td>2026-10</td><td class="num">22</td><td class="num">19</td><td class="num">2</td><td class="num">1</td><td><span class="tag t-green">学生已确认</span></td><td>机房夜班调休</td></tr>
<tr><td>周若菡</td><td>上海远景能源</td><td>2026-10</td><td class="num">22</td><td class="num">22</td><td class="num">0</td><td class="num">0</td><td><span class="tag t-green">学生已确认</span></td><td>—</td></tr>
<tr><td>林嘉禾</td><td>杭州拾光传媒</td><td>2026-10</td><td class="num">22</td><td class="num">14</td><td class="num">0</td><td class="num">8</td><td><span class="tag t-red">学生有异议</span></td><td>请假天数存在争议</td></tr>
</tbody></table></div>""", "考勤汇总")

# 11 变更
PAGES["11_change"] = shell("变更审批", """
<h1>变更审批</h1><div class="sub">变更生效前原档案仍有效，生效后保留变更前后信息</div>
<div class="toolbar"><span class="tag t-amber">待校内审批 2</span><span class="tag t-blue">待管理员审批 1</span>
<span class="tag t-green">已生效 7</span><div style="flex:1"></div><select><option>全部类型</option><option>更换企业</option><option>更换岗位</option><option>更换导师</option><option>中止实习</option></select></div>
<div class="card"><table><thead><tr><th>变更编号</th><th>学生</th><th>类型</th><th>变更前</th><th>变更后</th><th>原因</th><th>当前节点</th><th>操作</th></tr></thead><tbody>
<tr><td>CH20261028002</td><td>周若菡</td><td>更换岗位</td><td>产品运营实习</td><td>产品经理实习</td><td>企业业务调整，岗位职责升级</td><td><span class="tag t-amber">校内审批</span></td><td><button class="btn sm">审批</button></td></tr>
<tr><td>CH20261026001</td><td>宋雨桐</td><td>更换企业导师</td><td>王倩</td><td>陈默</td><td>原导师调岗离任</td><td><span class="tag t-blue">管理员审批</span></td><td><button class="btn sm">审批</button></td></tr>
<tr><td>CH20261018003</td><td>何书宁</td><td>中止实习</td><td>实习中</td><td>已中止</td><td>个人健康原因，已提交医院证明</td><td><span class="tag t-green">已生效</span></td><td><button class="btn sm">查看</button></td></tr>
<tr><td>CH20261009004</td><td>郑亦航</td><td>更换企业</td><td>杭州同花顺</td><td>浙江中控技术</td><td>原企业岗位与专业不符</td><td><span class="tag t-green">已生效</span></td><td><button class="btn sm">查看</button></td></tr>
</tbody></table></div>
<div class="card" style="margin-top:16px"><h2>审批抽屉预览（CH20261028002）</h2>
<div class="kv"><div><span>学生</span>周若菡</div><div><span>原岗位</span>产品运营实习</div><div><span>新岗位</span>产品经理实习</div>
<div><span>申请时间</span>2026-10-28 15:20</div><div><span>附件</span>企业岗位调整说明.pdf</div><div><span>状态</span><span class="tag t-amber">校内审批</span></div></div>
<div class="row" style="margin-top:14px"><button class="btn primary">通过并流转</button><button class="btn danger">驳回（填原因）</button></div></div>""", "变更审批")

# 12 异常
PAGES["12_issue"] = shell("异常关怀", """
<h1>异常关怀</h1><div class="sub">岗位不符、安全、薪资争议、长期无法联系四类异常的上报与处置台账</div>
<div class="toolbar"><select><option>全部类型</option><option>岗位不符</option><option>安全问题</option><option>薪资争议</option><option>无法联系</option></select>
<select><option>全部状态</option><option>待处置</option><option>处置中</option><option>已关闭</option></select>
<button class="btn primary">查询</button><div style="flex:1"></div><button class="btn danger">上报异常</button></div>
<div class="card"><table><thead><tr><th>编号</th><th>学生</th><th>企业</th><th>类型</th><th>等级</th><th>上报时间</th><th>处理人</th><th>状态</th><th>操作</th></tr></thead><tbody>
<tr><td>IS20261029001</td><td>林嘉禾</td><td>杭州拾光传媒</td><td>薪资争议</td><td><span class="tag t-red">高</span></td><td class="num">2026-10-29 11:20</td><td>李明华</td><td><span class="tag t-amber">处置中</span></td><td><button class="btn sm">处置</button></td></tr>
<tr><td>IS20261027002</td><td>赵一鸣</td><td>浙江中控技术</td><td>岗位不符</td><td><span class="tag t-amber">中</span></td><td class="num">2026-10-27 09:05</td><td>陈立群</td><td><span class="tag t-amber">处置中</span></td><td><button class="btn sm">处置</button></td></tr>
<tr><td>IS20261020003</td><td>何书宁</td><td>北京字节跳动</td><td>无法联系</td><td><span class="tag t-red">高</span></td><td class="num">2026-10-20 16:40</td><td>王慧</td><td><span class="tag t-green">已关闭</span></td><td><button class="btn sm">查看</button></td></tr>
<tr><td>IS20261011004</td><td>吴承宇</td><td>深圳恒瑞医疗</td><td>安全问题</td><td><span class="tag t-amber">中</span></td><td class="num">2026-10-11 14:12</td><td>王慧</td><td><span class="tag t-green">已关闭</span></td><td><button class="btn sm">查看</button></td></tr>
</tbody></table></div>
<div class="card" style="margin-top:16px"><h2>处置记录（IS20261029001）</h2>
<ul class="timeline">
<li><b>学生上报薪资争议</b><div class="m">林嘉禾 · 2026-10-29 11:20 · 附聊天记录截图 2 张</div></li>
<li><b>校内导师电话联系企业</b><div class="m">李明华 · 2026-10-29 15:02 · 约定 10-31 现场走访</div></li>
<li><b>现场走访核实</b><div class="m">李明华 · 2026-10-31 10:30 · 企业承诺 11 月补发差额</div></li>
<li><b>等待企业整改回执</b><div class="m">系统 · 2026-10-31 10:35 · 状态：处置中</div></li>
</ul></div>""", "异常关怀")

# 13 走访
PAGES["13_visit"] = shell("走访记录", """
<h1>走访记录</h1><div class="sub">电话走访与现场走访留痕，照片通过上传组件提交</div>
<div class="toolbar"><select><option>全部方式</option><option>电话</option><option>现场</option></select>
<select><option>全部导师</option></select><button class="btn primary">查询</button><div style="flex:1"></div><button class="btn primary">新增走访</button></div>
<div class="card"><table><thead><tr><th>编号</th><th>学生</th><th>企业</th><th>方式</th><th>走访日期</th><th>参与人</th><th>学生表现</th><th>企业意见</th><th>照片</th></tr></thead><tbody>
<tr><td>VS20261031001</td><td>林嘉禾</td><td>杭州拾光传媒</td><td><span class="tag t-blue">现场</span></td><td class="num">2026-10-31</td><td>李明华、郑楠</td><td>工作投入，沟通顺畅</td><td>认可能力，承诺改善薪资结算</td><td>3 张</td></tr>
<tr><td>VS20261024002</td><td>赵一鸣</td><td>浙江中控技术</td><td><span class="tag t-gray">电话</span></td><td class="num">2026-10-24</td><td>陈立群</td><td>适应良好，夜班较多</td><td>希望增加轮岗机会</td><td>—</td></tr>
<tr><td>VS20261017003</td><td>陈知远</td><td>杭州云枢科技</td><td><span class="tag t-blue">现场</span></td><td class="num">2026-10-17</td><td>李明华</td><td>技术成长明显</td><td>建议加强文档习惯</td><td>2 张</td></tr>
</tbody></table></div>""", "走访记录")

# 14 结项评价
PAGES["14_evaluation"] = shell("结项评价", """
<h1>结项评价</h1><div class="sub">企业导师与校内教师分别评分，系统结合周报完成度计算总评；材料缺失不得结项</div>
<div class="split">
 <div class="card"><h2>SI20260027 · 林嘉禾 · 结项材料校验</h2>
 <table><thead><tr><th>材料</th><th>要求</th><th>状态</th></tr></thead><tbody>
  <tr><td>实习周报</td><td>≥ 12 份</td><td><span class="tag t-green">14 份 · 通过</span></td></tr>
  <tr><td>月度考勤</td><td>≥ 4 个月</td><td><span class="tag t-green">4 个月 · 通过</span></td></tr>
  <tr><td>企业导师评价</td><td>必填</td><td><span class="tag t-green">已提交 4.2 分</span></td></tr>
  <tr><td>校内教师评价</td><td>必填</td><td><span class="tag t-amber">待提交</span></td></tr>
  <tr><td>结项报告</td><td>必填</td><td><span class="tag t-red">未上传</span></td></tr>
 </tbody></table>
 <div class="note" style="margin-top:12px;border-left-color:#A93226">当前存在 2 项缺失，结项按钮不可用。补齐后系统自动解锁。</div>
 <h2 style="margin-top:20px">企业导师评价</h2>
 <div class="kv"><div><span>评分</span>4.2 / 5</div><div><span>评价人</span>郑楠</div><div><span>时间</span>2026-10-25</div></div>
 <p style="margin:10px 0 0">前端基础扎实，交付质量稳定；建议提升需求澄清阶段的主动性。</p>
 </div>
 <div class="card"><h2>校内教师评价</h2>
 <label class="f"><span>周报完成度</span><input value="93" style="width:120px"></label>
 <label class="f"><span>过程规范</span><input value="88" style="width:120px"></label>
 <label class="f"><span>综合评分</span><input value="90" style="width:120px"></label>
 <div class="hint" style="margin-bottom:6px">评语</div>
 <textarea style="width:100%;height:80px;border:1px solid #DCE7E0;border-radius:6px;padding:8px;font:13px/20px inherit">全程按时提交周报，问题反馈及时，结项报告结构完整。</textarea>
 <h2 style="margin-top:20px">总评计算</h2>
 <table><tbody>
  <tr><td>企业评价（40%）</td><td class="num">4.2 / 5</td><td class="num">33.6</td></tr>
  <tr><td>校内评价（40%）</td><td class="num">90</td><td class="num">36.0</td></tr>
  <tr><td>周报完成度（20%）</td><td class="num">93</td><td class="num">18.6</td></tr>
  <tr><td><b>总评</b></td><td></td><td class="num"><b>88.2 · 良好</b></td></tr>
 </tbody></table>
 <button class="btn" style="margin-top:14px;width:100%" disabled>结项归档（材料未齐）</button>
 </div></div>""", "结项评价")

# 15 规则配置
PAGES["15_rule"] = shell("规则配置", """
<h1>规则配置 · 周报里程碑完整度检查</h1><div class="sub">权重合计必须等于 100%；修改后记录版本与生效时间，只影响新计算或主动重算的数据</div>
<div class="split">
 <div class="card"><h2>权重配置（v3 · 生效中）</h2>
 <table><thead><tr><th>输入因素</th><th>权重</th><th>阈值</th><th>数据来源</th></tr></thead><tbody>
  <tr><td>里程碑完成项</td><td><input value="30" style="width:80px">%</td><td>≥ 3 项</td><td>internship_milestone</td></tr>
  <tr><td>周报连续性</td><td><input value="20" style="width:80px">%</td><td>连续 ≥ 4 周</td><td>weekly_report</td></tr>
  <tr><td>附件数量</td><td><input value="15" style="width:80px">%</td><td>≥ 1 个 / 周</td><td>weekly_report</td></tr>
  <tr><td>导师反馈</td><td><input value="15" style="width:80px">%</td><td>≥ 4.0 分</td><td>weekly_report.review_score</td></tr>
  <tr><td>延期任务</td><td><input value="10" style="width:80px">%</td><td>≤ 0 项</td><td>internship_milestone</td></tr>
  <tr><td>企业评价</td><td><input value="10" style="width:80px">%</td><td>≥ 4.0 分</td><td>final_evaluation</td></tr>
 </tbody></table>
 <div class="row" style="margin-top:14px"><div class="note" style="flex:1">当前合计 <b>100%</b>，校验通过。</div>
 <button class="btn primary">保存为新版本</button></div>
 </div>
 <div>
  <div class="card" style="margin-bottom:16px"><h2>等级阈值</h2>
   <div class="kv" style="grid-template-columns:1fr 1fr">
    <div><span>优秀</span>≥ 90</div><div><span>良好</span>80 – 89</div>
    <div><span>合格</span>60 – 79</div><div><span>待改进</span>&lt; 60</div></div>
   <div class="hint" style="margin-top:10px">缺少必要数据时该因素不参与计算，并在结果页标注。</div></div>
  <div class="card"><h2>版本历史</h2>
   <table><tbody>
    <tr><td>v3</td><td class="num">2026-09-01</td><td>李明华</td><td><span class="tag t-green">生效中</span></td></tr>
    <tr><td>v2</td><td class="num">2026-06-15</td><td>王慧</td><td><span class="tag t-gray">已停用</span></td></tr>
    <tr><td>v1</td><td class="num">2026-03-01</td><td>系统初始化</td><td><span class="tag t-gray">已停用</span></td></tr>
   </tbody></table></div>
 </div></div>""", "规则配置")

# 16 统计看板
PAGES["16_board"] = shell("统计看板", f"""
<h1>统计看板</h1><div class="sub">点击任一图形跳转到对应筛选条件的明细列表，统计值与明细总数一致</div>
<div class="kpis" style="grid-template-columns:repeat(4,1fr)">
{kpi("异常类型分布 Top1", "薪资争议", "占 38%")}{kpi("变更率", "7.8%", "环比 -0.6pp")}
{kpi("周报及时率", "92.4%", "")}{kpi("成绩分布均值", "84.6", "")}</div>
<div class="grid" style="grid-template-columns:repeat(3,1fr)">
<div class="chart"><div class="ct">行业分布<span>人</span></div>{bars([92, 74, 66, 50, 38, 24])}<div class="legend"><span>信息技术 / 制造 / 金融 / 教育 / 医疗 / 建筑</span></div></div>
<div class="chart"><div class="ct">地区分布<span>人</span></div>{bars([88, 62, 44, 30, 22, 14])}<div class="legend"><span>杭州 / 宁波 / 上海 / 深圳 / 北京 / 其他</span></div></div>
<div class="chart"><div class="ct">岗位类型<span>人</span></div>{bars([70, 58, 46, 32, 26, 18])}<div class="legend"><span>开发 / 数据 / 测试 / 运维 / 运营 / 设计</span></div></div>
<div class="chart"><div class="ct">创新结果分布<span>份</span></div>{bars([26, 48, 72, 58, 34])}<div class="legend"><span>优秀 / 良好 / 合格 / 待改进 / 不推荐</span></div></div>
<div class="chart"><div class="ct">推荐采纳率<span>近 6 周</span></div>{bars([68, 72, 74, 79, 82, 86])}<div class="legend"><span>人工调整率 12.4%</span></div></div>
<div class="chart"><div class="ct">成绩分布<span>人</span></div>{bars([12, 26, 48, 34, 8])}<div class="legend"><span>90+ / 80-89 / 70-79 / 60-69 / &lt;60</span></div></div>
</div>""", "统计看板")

# 17 学生门户
PAGES["17_portal"] = portal_shell("我的实习", """
<div class="hero"><div><h2>陈知远，第 8 周周报已提交</h2>
<p>实习企业 杭州云枢科技有限公司 · 岗位 后端开发实习 · 本周里程碑覆盖 5/5 完整</p></div>
<button class="btn">填写本周周报</button></div>
<div class="grid" style="grid-template-columns:repeat(4,1fr);margin-top:16px">
<div class="card"><div class="label" style="color:#63736B;font-size:12px">实习进度</div><div style="font-size:22px;font-weight:600">第 8 / 20 周</div><div class="progress"><i style="width:40%"></i></div></div>
<div class="card"><div class="label" style="color:#63736B;font-size:12px">周报完成</div><div style="font-size:22px;font-weight:600">8 / 14</div><div class="progress"><i style="width:57%"></i></div></div>
<div class="card"><div class="label" style="color:#63736B;font-size:12px">里程碑完整度</div><div style="font-size:22px;font-weight:600">87.1 良好</div><div class="progress"><i style="width:87%"></i></div></div>
<div class="card"><div class="label" style="color:#63736B;font-size:12px">考勤确认</div><div style="font-size:22px;font-weight:600">10 月待确认</div><div class="hint" style="margin-top:6px">应出勤 22 · 实出勤 21</div></div>
</div>
<div class="split" style="margin-top:16px">
<div class="card"><h2>我的周报</h2>
<table><thead><tr><th>周次</th><th>本周任务</th><th>状态</th><th>导师评分</th></tr></thead><tbody>
<tr><td>第 8 周</td><td>订单查询接口联调</td><td><span class="tag t-amber">待批阅</span></td><td class="num">—</td></tr>
<tr><td>第 7 周</td><td>缓存层接入预研</td><td><span class="tag t-green">已批阅</span></td><td class="num">90</td></tr>
<tr><td>第 6 周</td><td>分页与排序实现</td><td><span class="tag t-green">已批阅</span></td><td class="num">88</td></tr>
<tr><td>第 5 周</td><td>订单服务代码通读</td><td><span class="tag t-green">已批阅</span></td><td class="num">85</td></tr>
</tbody></table></div>
<div class="card"><h2>待办与提醒</h2>
<ul class="timeline">
<li><b>确认 10 月考勤</b><div class="m">截止 2026-11-02 · 企业导师已录入</div></li>
<li><b>补充结项报告</b><div class="m">结项前必须上传，当前未提交</div></li>
<li><b>提交第 9 周周报</b><div class="m">截止 2026-11-08 23:59</div></li>
</ul></div></div>""")

# 18 个人中心
PAGES["18_profile"] = shell("个人中心", """
<h1>个人中心</h1><div class="sub">修改资料、密码与头像，头像上传后立即同步到右上角</div>
<div class="split">
<div class="card"><h2>基本资料</h2>
<div class="row" style="align-items:center;margin-bottom:18px">
 <div class="avatar" style="width:64px;height:64px;font-size:20px">陈</div>
 <div><button class="btn">上传头像</button><div class="hint" style="margin-top:6px">支持 jpg/png，≤ 2MB</div></div></div>
<label class="f"><span>姓名</span><input value="陈知远"></label>
<label class="f"><span>学号</span><input value="2022010312" disabled></label>
<label class="f"><span>手机号</span><input value="13800001234"></label>
<label class="f"><span>邮箱</span><input value="chenzy@stu.edu.cn"></label>
<label class="f"><span>角色</span><input value="学生" disabled></label>
<button class="btn primary">保存资料</button></div>
<div class="card"><h2>修改密码</h2>
<label class="f"><span>原密码</span><input type="password" value="······"></label>
<label class="f"><span>新密码</span><input type="password"></label>
<label class="f"><span>确认密码</span><input type="password"></label>
<button class="btn primary">提交</button>
<div class="note" style="margin-top:16px">密码使用 BCrypt 保存，任何接口与日志均不返回密码字段；连续 5 次登录失败锁定 10 分钟。</div></div>
</div>""", "个人中心")

# 19 角色管理
PAGES["19_role"] = shell("角色管理", """
<h1>角色管理</h1><div class="sub">菜单权限与数据范围分别控制；只有菜单权限不能直接调用写接口</div>
<div class="row" style="align-items:flex-start">
<div class="card" style="flex:1"><h2>角色列表</h2>
<table><thead><tr><th>角色编码</th><th>角色名称</th><th>数据范围</th><th>用户数</th><th>操作</th></tr></thead><tbody>
<tr><td>admin</td><td>实习管理员</td><td><span class="tag t-blue">全部</span></td><td class="num">2</td><td><button class="btn sm">分配菜单</button></td></tr>
<tr><td>teacher</td><td>校内指导教师</td><td><span class="tag t-blue">本部门</span></td><td class="num">9</td><td><button class="btn sm">分配菜单</button></td></tr>
<tr><td>mentor</td><td>企业导师</td><td><span class="tag t-gray">本人负责</span></td><td class="num">23</td><td><button class="btn sm">分配菜单</button></td></tr>
<tr><td>student</td><td>学生</td><td><span class="tag t-gray">本人</span></td><td class="num">128</td><td><button class="btn sm">分配菜单</button></td></tr>
</tbody></table></div>
<div class="card" style="width:420px"><h2>为「校内指导教师」分配菜单</h2>
<div style="border:1px solid #DCE7E0;border-radius:6px;padding:10px 12px;font-size:13px;line-height:26px">
<label><input type="checkbox" checked> 工作台</label><br>
<label><input type="checkbox" checked> 实习过程</label><br>
<div style="padding-left:20px"><label><input type="checkbox" checked> 我的学生</label><br>
<label><input type="checkbox" checked> 异常关怀</label><br>
<label><input type="checkbox" checked> 走访记录</label></div>
<label><input type="checkbox" checked> 周报评价</label><br>
<div style="padding-left:20px"><label><input type="checkbox" checked> 周报批阅</label><br>
<label><input type="checkbox" checked> 里程碑进度</label><br>
<label><input type="checkbox" checked> 校内评价</label></div>
<label style="color:#9AA8A0"><input type="checkbox" disabled> 菜单管理（系统内置隐藏）</label>
</div>
<div class="row" style="margin-top:12px"><button class="btn primary">保存</button><button class="btn">重置</button></div>
</div></div>""", "角色管理")

# 20 消息
PAGES["20_message"] = shell("消息中心", """
<h1>消息中心</h1><div class="sub">未读 3 条 · 消息包含业务编号与详情跳转地址</div>
<div class="toolbar"><span class="tag t-green">全部</span><span class="tag t-amber">待审批 2</span>
<span class="tag t-red">已退回 1</span><span class="tag t-gray">处理完成</span>
<div style="flex:1"></div><button class="btn">全部标记已读</button></div>
<div class="card">
<table><thead><tr><th>类型</th><th>标题</th><th>业务编号</th><th>时间</th><th>状态</th><th>操作</th></tr></thead><tbody>
<tr><td><span class="tag t-amber">待审批</span></td><td>SI20260031 陈知远 提交实习备案，等待审核</td><td>SI20260031</td><td class="num">2026-10-31 09:12</td><td>未读</td><td><button class="btn sm">查看</button></td></tr>
<tr><td><span class="tag t-red">已退回</span></td><td>WR20261030007 周报被退修：附件缺少测试记录</td><td>WR20261030007</td><td class="num">2026-10-30 20:15</td><td>未读</td><td><button class="btn sm">查看</button></td></tr>
<tr><td><span class="tag t-amber">即将超时</span></td><td>第 9 周周报将于 11-08 23:59 截止</td><td>B2026S1</td><td class="num">2026-10-30 08:00</td><td>未读</td><td><button class="btn sm">查看</button></td></tr>
<tr><td><span class="tag t-green">处理完成</span></td><td>CH20261018003 中止实习变更已生效</td><td>CH20261018003</td><td class="num">2026-10-19 10:22</td><td>已读</td><td><button class="btn sm">查看</button></td></tr>
</tbody></table></div>""", "消息中心")

# 学生端周报页（补充）
PAGES["21_portal_report"] = portal_shell("周报提交", """
<div class="row" style="justify-content:space-between;align-items:center"><h1 style="margin:0">第 9 周周报</h1>
<span class="tag t-amber">草稿 · 未提交</span></div>
<div class="sub">截止 2026-11-08 23:59 · 周报正文限 2000 字、图片最多 6 张</div>
<div class="split">
<div class="card"><h2>本周内容</h2>
<label class="f"><span>本周任务</span><textarea style="width:420px;height:70px;border:1px solid #DCE7E0;border-radius:6px;padding:8px"></textarea></label>
<label class="f"><span>学习收获</span><textarea style="width:420px;height:70px;border:1px solid #DCE7E0;border-radius:6px;padding:8px"></textarea></label>
<label class="f"><span>遇到的问题</span><textarea style="width:420px;height:70px;border:1px solid #DCE7E0;border-radius:6px;padding:8px"></textarea></label>
<label class="f"><span>下周计划</span><textarea style="width:420px;height:70px;border:1px solid #DCE7E0;border-radius:6px;padding:8px"></textarea></label>
<label class="f"><span>附件</span><button class="btn">上传图片 / PDF</button></label>
<div class="row"><button class="btn">保存草稿</button><button class="btn primary">提交周报</button></div>
</div>
<div class="card"><h2>里程碑覆盖检查</h2>
<table><tbody>
<tr><td>任务描述</td><td><span class="tag t-green">已填写</span></td></tr>
<tr><td>阶段成果</td><td><span class="tag t-red">缺项</span></td></tr>
<tr><td>问题记录</td><td><span class="tag t-green">已填写</span></td></tr>
<tr><td>下周计划</td><td><span class="tag t-green">已填写</span></td></tr>
<tr><td>附件材料</td><td><span class="tag t-red">缺项</span></td></tr>
</tbody></table>
<div class="note" style="margin-top:12px">当前覆盖 3/5，提交后完整度预计 72 分（合格）。补齐「阶段成果」与附件可提升至 88 分。</div>
</div></div>""", "周报提交")

for name, html in PAGES.items():
    with open(os.path.join(OUT, f"{name}.html"), "w", encoding="utf-8") as f:
        f.write(html)

# 索引页
idx = ['<!DOCTYPE html><html lang="zh-CN"><head><meta charset="utf-8"><title>设计稿索引</title>',
       '<link rel="stylesheet" href="mock.css"></head><body><div class="content">',
       '<h1>大学生实习过程与周报管理系统 · 设计稿索引</h1>',
       '<div class="sub">共 %d 张可交互 HTML 原型，点击进入；内置假数据，可跨页跳转。</div>' % len(PAGES),
       '<div class="card"><table><thead><tr><th>#</th><th>页面</th><th>文件</th><th>角色</th></tr></thead><tbody>']
role_map = {"01": "公开", "17": "学生", "21": "学生", "02": "管理员/导师", "05": "管理员/导师", "06": "校内导师",
            "07": "管理员/导师", "14": "导师/管理员", "18": "全角色", "19": "管理员", "20": "全角色"}
for i, (name, _) in enumerate(sorted(PAGES.items()), 1):
    no = name[:2]
    idx.append(f'<tr><td>{i}</td><td>{name[3:].replace("_", " ")}</td>'
               f'<td><a href="pages/{name}.html">pages/{name}.html</a></td><td>{role_map.get(no, "管理员")}</td></tr>')
idx.append('</tbody></table></div></div></body></html>')
with open(os.path.join(os.path.dirname(OUT), "index.html"), "w", encoding="utf-8") as f:
    f.write("\n".join(idx))

print("pages:", len(PAGES))
