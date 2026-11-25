#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""生成 sql/init.sql：建库建表 + 索引 + 字典 + 真实分布的测试数据。"""
import os, random, json
from datetime import date, datetime, timedelta

random.seed(20261031)
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "init.sql")

PW_ADMIN = "$2b$10$SARYGfGxo.ZCdLvADa/EIeDLyIQNPOhNThQ2KCp7NYT8O5EdZm5FK"   # admin123
PW_USER = "$2b$10$OjXQ.6V/xTxVakLiiFBqcOMn/BJ0k9fGKq7T1uQM6YVRrREgEfX7q"    # 123456

L = []
def w(s=""):
    L.append(s)

def q(v):
    if v is None:
        return "NULL"
    if isinstance(v, (int, float)):
        return str(v)
    return "'" + str(v).replace("\\", "\\\\").replace("'", "''") + "'"

def dt(d):  # date/datetime -> 'YYYY-MM-DD HH:MM:SS'
    if isinstance(d, datetime):
        return d.strftime("%Y-%m-%d %H:%M:%S")
    return d.strftime("%Y-%m-%d 00:00:00")

def suid(i):
    """档案序号 -> 学生 sys_user.id（学生账号 id 为 9..20，序号 1..12 循环）"""
    return ((int(i) - 1) % 12) + 9


def img(entity, i, n):
    return f"/uploads/seed/{entity}/{((i * 7) % n) + 1:02d}.jpg"

w("""-- 大学生实习过程与周报管理系统 初始化脚本
-- MySQL 8 / utf8mb4；库名 new_024，导入后即可用 admin/admin123 登录
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;
DROP DATABASE IF EXISTS new_024;
CREATE DATABASE new_024 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE new_024;
""")

SCHEMA = """
-- ============ 系统基础表 ============
CREATE TABLE sys_org (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  org_name VARCHAR(100) NOT NULL COMMENT '组织名称',
  org_type VARCHAR(30) NOT NULL COMMENT '类型：学院/企业/管理部门',
  parent_id BIGINT DEFAULT NULL COMMENT '上级组织',
  contact VARCHAR(30) DEFAULT NULL,
  phone VARCHAR(30) DEFAULT NULL,
  create_time DATETIME NOT NULL,
  KEY idx_org_parent (parent_id)
) ENGINE=InnoDB COMMENT='组织';

CREATE TABLE sys_user (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  username VARCHAR(50) NOT NULL COMMENT '登录账号',
  password VARCHAR(100) NOT NULL COMMENT 'BCrypt 密文',
  real_name VARCHAR(50) NOT NULL,
  phone VARCHAR(30) DEFAULT NULL,
  email VARCHAR(80) DEFAULT NULL,
  avatar VARCHAR(200) DEFAULT NULL COMMENT '头像相对路径',
  role_code VARCHAR(20) NOT NULL COMMENT 'admin/teacher/mentor/student',
  org_id BIGINT DEFAULT NULL,
  org_name VARCHAR(100) DEFAULT NULL,
  data_scope VARCHAR(10) NOT NULL DEFAULT 'SELF' COMMENT 'ALL/ORG/SELF',
  status TINYINT NOT NULL DEFAULT 1 COMMENT '1启用 0停用',
  fail_count INT NOT NULL DEFAULT 0,
  lock_until DATETIME DEFAULT NULL,
  last_login_time DATETIME DEFAULT NULL,
  student_no VARCHAR(30) DEFAULT NULL COMMENT '学号（学生）',
  major VARCHAR(60) DEFAULT NULL COMMENT '专业',
  grade VARCHAR(20) DEFAULT NULL COMMENT '年级',
  company_id BIGINT DEFAULT NULL COMMENT '所属企业（企业导师）',
  create_time DATETIME NOT NULL,
  UNIQUE KEY uk_user_username (username),
  KEY idx_user_role (role_code)
) ENGINE=InnoDB COMMENT='用户';

CREATE TABLE sys_role (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  role_code VARCHAR(20) NOT NULL,
  role_name VARCHAR(50) NOT NULL,
  description VARCHAR(200) DEFAULT NULL,
  data_scope VARCHAR(10) NOT NULL DEFAULT 'SELF',
  create_time DATETIME NOT NULL,
  UNIQUE KEY uk_role_code (role_code)
) ENGINE=InnoDB COMMENT='角色';

CREATE TABLE sys_menu (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  parent_id BIGINT NOT NULL DEFAULT 0,
  menu_name VARCHAR(50) NOT NULL,
  path VARCHAR(100) DEFAULT NULL,
  icon VARCHAR(50) DEFAULT NULL,
  menu_type VARCHAR(10) NOT NULL DEFAULT 'MENU' COMMENT 'DIR/MENU/BUTTON',
  sort_no INT NOT NULL DEFAULT 0,
  visible TINYINT NOT NULL DEFAULT 1,
  create_time DATETIME NOT NULL,
  KEY idx_menu_parent (parent_id)
) ENGINE=InnoDB COMMENT='菜单';

CREATE TABLE sys_role_menu (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  role_code VARCHAR(20) NOT NULL,
  menu_id BIGINT NOT NULL,
  UNIQUE KEY uk_role_menu (role_code, menu_id)
) ENGINE=InnoDB COMMENT='角色菜单';

CREATE TABLE sys_dict (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  dict_type VARCHAR(50) NOT NULL,
  dict_label VARCHAR(60) NOT NULL,
  dict_value VARCHAR(60) NOT NULL,
  sort_no INT NOT NULL DEFAULT 0,
  status TINYINT NOT NULL DEFAULT 1,
  KEY idx_dict_type (dict_type)
) ENGINE=InnoDB COMMENT='字典';

CREATE TABLE sys_message (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  title VARCHAR(200) NOT NULL,
  content VARCHAR(500) DEFAULT NULL,
  msg_type VARCHAR(20) NOT NULL COMMENT '待审批/即将超时/已退回/处理完成',
  biz_no VARCHAR(50) DEFAULT NULL,
  link_url VARCHAR(200) DEFAULT NULL,
  receiver_id BIGINT NOT NULL,
  is_read TINYINT NOT NULL DEFAULT 0,
  create_time DATETIME NOT NULL,
  KEY idx_msg_receiver (receiver_id, is_read)
) ENGINE=InnoDB COMMENT='站内消息';

CREATE TABLE sys_log (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  user_id BIGINT DEFAULT NULL,
  user_name VARCHAR(50) DEFAULT NULL,
  action VARCHAR(100) NOT NULL,
  method VARCHAR(100) DEFAULT NULL,
  params VARCHAR(500) DEFAULT NULL,
  cost_ms BIGINT DEFAULT 0,
  create_time DATETIME NOT NULL,
  KEY idx_log_time (create_time)
) ENGINE=InnoDB COMMENT='操作日志';

-- ============ 业务主数据 ============
CREATE TABLE internship_batch (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  batch_no VARCHAR(30) NOT NULL COMMENT '批次编号',
  semester VARCHAR(50) NOT NULL COMMENT '学期',
  departments VARCHAR(200) DEFAULT NULL COMMENT '适用院系',
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  report_deadline VARCHAR(50) DEFAULT '每周日 23:59' COMMENT '周报截止',
  grace_days INT NOT NULL DEFAULT 2 COMMENT '补交宽限天数',
  score_weights VARCHAR(50) DEFAULT '40/40/20' COMMENT '企业/校内/周报',
  required_materials VARCHAR(200) DEFAULT NULL,
  min_reports INT NOT NULL DEFAULT 12,
  status VARCHAR(20) NOT NULL DEFAULT '启用',
  create_time DATETIME NOT NULL,
  UNIQUE KEY uk_batch_no (batch_no)
) ENGINE=InnoDB COMMENT='实习批次';

CREATE TABLE internship_company (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  company_no VARCHAR(30) NOT NULL,
  company_name VARCHAR(120) NOT NULL,
  industry VARCHAR(50) NOT NULL,
  address VARCHAR(200) DEFAULT NULL,
  city VARCHAR(50) DEFAULT NULL,
  contact VARCHAR(30) DEFAULT NULL,
  phone VARCHAR(30) DEFAULT NULL,
  scale VARCHAR(50) DEFAULT NULL,
  past_students INT NOT NULL DEFAULT 0 COMMENT '往年接收人数',
  avg_score DECIMAL(3,2) NOT NULL DEFAULT 0 COMMENT '学生评价均分',
  risk_status VARCHAR(20) NOT NULL DEFAULT '正常' COMMENT '正常/关注/风险',
  license_image VARCHAR(200) DEFAULT NULL COMMENT '企业资质/办公环境图片',
  intro VARCHAR(500) DEFAULT NULL,
  create_time DATETIME NOT NULL,
  UNIQUE KEY uk_company_no (company_no),
  KEY idx_company_industry (industry)
) ENGINE=InnoDB COMMENT='企业库';

CREATE TABLE internship_application (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  internship_no VARCHAR(50) NOT NULL COMMENT '实习编号',
  student_id BIGINT NOT NULL,
  student_name VARCHAR(50) NOT NULL,
  student_no VARCHAR(30) DEFAULT NULL,
  major VARCHAR(60) DEFAULT NULL,
  grade VARCHAR(20) DEFAULT NULL,
  company_id BIGINT NOT NULL,
  company_name VARCHAR(120) NOT NULL,
  position VARCHAR(80) NOT NULL,
  industry VARCHAR(50) DEFAULT NULL,
  city VARCHAR(50) DEFAULT NULL,
  teacher_id BIGINT DEFAULT NULL COMMENT '校内导师',
  teacher_name VARCHAR(50) DEFAULT NULL,
  mentor_id BIGINT DEFAULT NULL COMMENT '企业导师',
  mentor_name VARCHAR(50) DEFAULT NULL,
  batch_id BIGINT DEFAULT NULL,
  batch_no VARCHAR(30) DEFAULT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  source VARCHAR(20) NOT NULL DEFAULT '集中实习' COMMENT '集中/自主',
  stage VARCHAR(20) NOT NULL DEFAULT '实习备案',
  report_status VARCHAR(20) NOT NULL DEFAULT '待提交',
  agreement_file VARCHAR(200) DEFAULT NULL,
  insurance_file VARCHAR(200) DEFAULT NULL,
  accept_file VARCHAR(200) DEFAULT NULL,
  transition_reason VARCHAR(300) DEFAULT NULL,
  version INT NOT NULL DEFAULT 1 COMMENT '乐观锁版本号',
  deleted TINYINT NOT NULL DEFAULT 0,
  create_by BIGINT DEFAULT NULL,
  create_time DATETIME NOT NULL,
  update_time DATETIME NOT NULL,
  UNIQUE KEY uk_app_no (internship_no),
  KEY idx_app_stage (stage),
  KEY idx_app_student (student_id),
  KEY idx_app_teacher (teacher_id)
) ENGINE=InnoDB COMMENT='实习档案主表';

CREATE TABLE internship_milestone (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  application_id BIGINT NOT NULL,
  seq_no INT NOT NULL,
  title VARCHAR(120) NOT NULL,
  plan_week INT NOT NULL COMMENT '计划周次',
  status VARCHAR(20) NOT NULL DEFAULT '未开始' COMMENT '未开始/进行中/已完成/已延期',
  complete_date DATE DEFAULT NULL,
  delayed_days INT NOT NULL DEFAULT 0,
  create_time DATETIME NOT NULL,
  KEY idx_ms_app (application_id)
) ENGINE=InnoDB COMMENT='阶段里程碑';

CREATE TABLE weekly_report (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  report_no VARCHAR(50) NOT NULL,
  application_id BIGINT NOT NULL,
  internship_no VARCHAR(50) DEFAULT NULL,
  student_id BIGINT NOT NULL,
  student_name VARCHAR(50) NOT NULL,
  week_no INT NOT NULL,
  week_start DATE NOT NULL,
  week_end DATE NOT NULL,
  task_content VARCHAR(1000) NOT NULL COMMENT '本周任务',
  harvest VARCHAR(1000) DEFAULT NULL COMMENT '学习收获',
  problem VARCHAR(1000) DEFAULT NULL COMMENT '遇到的问题',
  next_plan VARCHAR(1000) DEFAULT NULL COMMENT '下周计划',
  attachment_image VARCHAR(200) DEFAULT NULL COMMENT '工作场景照片',
  attachment_file VARCHAR(200) DEFAULT NULL,
  submit_time DATETIME DEFAULT NULL,
  deadline DATETIME DEFAULT NULL,
  status VARCHAR(20) NOT NULL DEFAULT '草稿' COMMENT '草稿/待批阅/已批阅/已退修/逾期未交',
  review_score INT DEFAULT NULL,
  review_comment VARCHAR(500) DEFAULT NULL,
  reviewer_id BIGINT DEFAULT NULL,
  reviewer_name VARCHAR(50) DEFAULT NULL,
  review_time DATETIME DEFAULT NULL,
  create_time DATETIME NOT NULL,
  UNIQUE KEY uk_report_app_week (application_id, week_no),
  KEY idx_report_status (status)
) ENGINE=InnoDB COMMENT='周报';

CREATE TABLE monthly_attendance (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  attendance_no VARCHAR(50) NOT NULL,
  application_id BIGINT NOT NULL,
  student_id BIGINT NOT NULL,
  student_name VARCHAR(50) NOT NULL,
  company_name VARCHAR(120) DEFAULT NULL,
  month VARCHAR(10) NOT NULL COMMENT 'yyyy-MM',
  should_days INT NOT NULL DEFAULT 22,
  actual_days INT NOT NULL DEFAULT 22,
  late_count INT NOT NULL DEFAULT 0,
  leave_days INT NOT NULL DEFAULT 0,
  remark VARCHAR(300) DEFAULT NULL,
  confirm_status VARCHAR(20) NOT NULL DEFAULT '待学生确认' COMMENT '待学生确认/学生已确认/学生有异议',
  mentor_name VARCHAR(50) DEFAULT NULL,
  create_time DATETIME NOT NULL,
  UNIQUE KEY uk_att_app_month (application_id, month)
) ENGINE=InnoDB COMMENT='月度考勤';

CREATE TABLE internship_change (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  change_no VARCHAR(50) NOT NULL,
  application_id BIGINT NOT NULL,
  student_name VARCHAR(50) NOT NULL,
  change_type VARCHAR(20) NOT NULL COMMENT '更换企业/更换岗位/更换导师/中止实习',
  before_value VARCHAR(200) DEFAULT NULL,
  after_value VARCHAR(200) DEFAULT NULL,
  reason VARCHAR(300) NOT NULL,
  attachment VARCHAR(200) DEFAULT NULL,
  current_node VARCHAR(30) NOT NULL DEFAULT '校内审批' COMMENT '校内审批/管理员审批/已生效/已驳回',
  status VARCHAR(20) NOT NULL DEFAULT '审批中',
  apply_time DATETIME NOT NULL,
  teacher_opinion VARCHAR(300) DEFAULT NULL,
  admin_opinion VARCHAR(300) DEFAULT NULL,
  effective_time DATETIME DEFAULT NULL,
  create_time DATETIME NOT NULL,
  UNIQUE KEY uk_change_no (change_no),
  KEY idx_change_app (application_id)
) ENGINE=InnoDB COMMENT='实习变更';

CREATE TABLE internship_issue (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  issue_no VARCHAR(50) NOT NULL,
  application_id BIGINT NOT NULL,
  student_name VARCHAR(50) NOT NULL,
  company_name VARCHAR(120) DEFAULT NULL,
  issue_type VARCHAR(20) NOT NULL COMMENT '岗位不符/安全问题/薪资争议/无法联系',
  level VARCHAR(10) NOT NULL DEFAULT '中' COMMENT '高/中/低',
  content VARCHAR(500) NOT NULL,
  report_time DATETIME NOT NULL,
  handler_name VARCHAR(50) DEFAULT NULL,
  status VARCHAR(20) NOT NULL DEFAULT '待处置' COMMENT '待处置/处置中/已关闭',
  handle_record VARCHAR(1000) DEFAULT NULL,
  close_time DATETIME DEFAULT NULL,
  create_time DATETIME NOT NULL,
  UNIQUE KEY uk_issue_no (issue_no),
  KEY idx_issue_status (status)
) ENGINE=InnoDB COMMENT='异常关怀';

CREATE TABLE visit_record (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  visit_no VARCHAR(50) NOT NULL,
  application_id BIGINT NOT NULL,
  student_name VARCHAR(50) NOT NULL,
  company_name VARCHAR(120) DEFAULT NULL,
  visit_type VARCHAR(20) NOT NULL COMMENT '电话/现场',
  visit_date DATE NOT NULL,
  participants VARCHAR(100) DEFAULT NULL,
  student_performance VARCHAR(300) DEFAULT NULL,
  company_opinion VARCHAR(300) DEFAULT NULL,
  photo VARCHAR(200) DEFAULT NULL COMMENT '走访照片',
  teacher_id BIGINT DEFAULT NULL,
  teacher_name VARCHAR(50) DEFAULT NULL,
  create_time DATETIME NOT NULL,
  UNIQUE KEY uk_visit_no (visit_no),
  KEY idx_visit_app (application_id)
) ENGINE=InnoDB COMMENT='走访记录';

CREATE TABLE final_evaluation (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  application_id BIGINT NOT NULL,
  student_name VARCHAR(50) NOT NULL,
  company_score DECIMAL(4,1) DEFAULT NULL COMMENT '企业评价（5 分制）',
  company_comment VARCHAR(500) DEFAULT NULL,
  company_evaluator VARCHAR(50) DEFAULT NULL,
  company_time DATETIME DEFAULT NULL,
  school_score INT DEFAULT NULL COMMENT '校内评价（百分制）',
  school_comment VARCHAR(500) DEFAULT NULL,
  school_evaluator VARCHAR(50) DEFAULT NULL,
  school_time DATETIME DEFAULT NULL,
  report_score DECIMAL(5,1) DEFAULT NULL COMMENT '周报完成度',
  total_score DECIMAL(5,1) DEFAULT NULL,
  grade VARCHAR(20) DEFAULT NULL COMMENT '优秀/良好/合格/待改进',
  materials_ok TINYINT NOT NULL DEFAULT 0 COMMENT '结项材料是否齐全',
  status VARCHAR(20) NOT NULL DEFAULT '待评价' COMMENT '待评价/评价中/已结项',
  create_time DATETIME NOT NULL,
  UNIQUE KEY uk_eval_app (application_id)
) ENGINE=InnoDB COMMENT='结项评价';

-- ============ 创新点：周报里程碑完整度检查 ============
CREATE TABLE internship_rule (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  rule_name VARCHAR(100) NOT NULL,
  version VARCHAR(20) NOT NULL,
  weight_milestone INT NOT NULL DEFAULT 30,
  weight_continuity INT NOT NULL DEFAULT 20,
  weight_attachment INT NOT NULL DEFAULT 15,
  weight_feedback INT NOT NULL DEFAULT 15,
  weight_delay INT NOT NULL DEFAULT 10,
  weight_company INT NOT NULL DEFAULT 10,
  threshold_good DECIMAL(4,1) NOT NULL DEFAULT 80,
  threshold_mid DECIMAL(4,1) NOT NULL DEFAULT 60,
  enabled TINYINT NOT NULL DEFAULT 1,
  effective_time DATETIME NOT NULL,
  create_by VARCHAR(50) DEFAULT NULL,
  create_time DATETIME NOT NULL,
  UNIQUE KEY uk_rule_version (version)
) ENGINE=InnoDB COMMENT='完整度规则';

CREATE TABLE internship_score (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  application_id BIGINT NOT NULL,
  student_name VARCHAR(50) NOT NULL,
  rule_id BIGINT NOT NULL,
  rule_version VARCHAR(20) NOT NULL,
  input_json TEXT COMMENT '输入快照',
  detail_json TEXT COMMENT '明细分与解释',
  total_score DECIMAL(5,1) NOT NULL,
  grade VARCHAR(20) NOT NULL,
  advice VARCHAR(500) DEFAULT NULL COMMENT '可改进项',
  manual_grade VARCHAR(20) DEFAULT NULL COMMENT '人工调整后等级',
  manual_reason VARCHAR(300) DEFAULT NULL,
  manual_by VARCHAR(50) DEFAULT NULL,
  manual_time DATETIME DEFAULT NULL,
  calc_week INT NOT NULL DEFAULT 1,
  calc_time DATETIME NOT NULL,
  KEY idx_score_app (application_id, calc_week)
) ENGINE=InnoDB COMMENT='完整度计算留痕';
"""

w(SCHEMA)
w("SET FOREIGN_KEY_CHECKS = 1;")

# ---------------- 组织 ----------------
w("\n-- 组织")
orgs = [(1, "计算机学院", "学院", None, "王慧", "0571-88001001"),
        (2, "商学院", "学院", None, "赵明", "0571-88001002"),
        (3, "教务处实习管理科", "管理部门", None, "孙涛", "0571-88001003"),
        (4, "杭州云枢科技有限公司", "企业", None, "周建国", "0571-88002001"),
        (5, "宁波甬信会计师事务所", "企业", None, "王倩", "0574-88002002")]
rows = ",".join(f"({i},{q(n)},{q(t)},{q(p)},{q(c)},{q(ph)},'2026-02-20 10:00:00')" for i, n, t, p, c, ph in orgs)
w("INSERT INTO sys_org (id,org_name,org_type,parent_id,contact,phone,create_time) VALUES " + rows + ";")

# ---------------- 角色 ----------------
w("\n-- 角色")
roles = [("admin", "实习管理员", "维护批次、企业库、导师、规则、风险企业与统计", "ALL"),
         ("teacher", "校内指导教师", "审核申请、批阅周报、记录走访、完成校内评价", "ORG"),
         ("mentor", "企业导师", "确认到岗、工作内容、考勤与企业评价", "SELF"),
         ("student", "学生", "提交实习申请、周报、变更、请假、异常与结项材料", "SELF")]
rows = ",".join(f"({q(c)},{q(n)},{q(d)},{q(s)},'2026-02-20 10:00:00')" for c, n, d, s in roles)
w("INSERT INTO sys_role (role_code,role_name,description,data_scope,create_time) VALUES " + rows + ";")

# ---------------- 菜单 ----------------
w("\n-- 菜单（菜单管理项对业务角色隐藏，由后端过滤）")
menus = [
    (1, 0, "工作台", "/dashboard", "dashboard", "MENU", 1),
    (2, 0, "实习过程", None, "archive", "DIR", 2),
    (3, 2, "实习备案中心", "/application", "archive", "MENU", 1),
    (4, 2, "考勤汇总", "/attendance", "calendar", "MENU", 2),
    (5, 2, "变更审批", "/change", "flag", "MENU", 3),
    (6, 2, "异常关怀", "/issue", "alert", "MENU", 4),
    (7, 2, "走访记录", "/visit", "people", "MENU", 5),
    (8, 0, "周报评价", None, "report", "DIR", 3),
    (9, 8, "周报工作台", "/report", "report", "MENU", 1),
    (10, 8, "导师批阅", "/review", "check", "MENU", 2),
    (11, 8, "里程碑进度", "/milestone", "flag", "MENU", 3),
    (12, 8, "结项评价", "/evaluation", "shield", "MENU", 4),
    (13, 0, "基础数据", None, "building", "DIR", 4),
    (14, 13, "企业库", "/company", "building", "MENU", 1),
    (15, 13, "实习批次", "/batch", "calendar", "MENU", 2),
    (16, 0, "分析配置", None, "chart", "DIR", 5),
    (17, 16, "统计看板", "/board", "chart", "MENU", 1),
    (18, 16, "规则配置", "/rule", "rule", "MENU", 2),
    (19, 0, "系统管理", None, "log", "DIR", 6),
    (20, 19, "用户管理", "/system/user", "user", "MENU", 1),
    (21, 19, "角色管理", "/system/role", "shield", "MENU", 2),
    (22, 19, "菜单管理", "/system/menu", "menu", "MENU", 3),
    (23, 19, "字典管理", "/system/dict", "log", "MENU", 4),
    (24, 19, "操作日志", "/system/log", "log", "MENU", 5),
    (25, 0, "消息中心", "/message", "message", "MENU", 7),
    (26, 0, "个人中心", "/profile", "user", "MENU", 8),
]
rows = ",".join(f"({i},{p},{q(n)},{q(pa)},{q(ic)},{q(t)},{s},1,'2026-02-20 10:00:00')"
                for i, p, n, pa, ic, t, s in menus)
w("INSERT INTO sys_menu (id,parent_id,menu_name,path,icon,menu_type,sort_no,visible,create_time) VALUES " + rows + ";")

role_menus = {
    "admin": [m[0] for m in menus],
    "teacher": [1, 2, 3, 6, 7, 8, 9, 10, 11, 12, 25, 26],
    "mentor": [1, 3, 4, 8, 9, 12, 25, 26],
    "student": [1, 8, 9, 11, 12, 25, 26],
}
pairs = []
for r, ids in role_menus.items():
    for i in ids:
        pairs.append(f"({q(r)},{i})")
w("INSERT INTO sys_role_menu (role_code,menu_id) VALUES " + ",".join(pairs) + ";")

# ---------------- 字典 ----------------
w("\n-- 字典")
dicts = [("internship_stage", "实习备案", "实习备案"), ("internship_stage", "协议审核", "协议审核"),
         ("internship_stage", "过程周报", "过程周报"), ("internship_stage", "阶段检查", "阶段检查"),
         ("internship_stage", "企业评价", "企业评价"), ("internship_stage", "学校归档", "学校归档"),
         ("internship_stage", "已中止", "已中止"),
         ("report_status", "待提交", "待提交"), ("report_status", "待批阅", "待批阅"),
         ("report_status", "已批阅", "已批阅"), ("report_status", "已退修", "已退修"),
         ("change_type", "更换企业", "更换企业"), ("change_type", "更换岗位", "更换岗位"),
         ("change_type", "更换导师", "更换导师"), ("change_type", "中止实习", "中止实习"),
         ("issue_type", "岗位不符", "岗位不符"), ("issue_type", "安全问题", "安全问题"),
         ("issue_type", "薪资争议", "薪资争议"), ("issue_type", "无法联系", "无法联系"),
         ("industry", "信息技术", "信息技术"), ("industry", "制造", "制造"), ("industry", "金融", "金融"),
         ("industry", "教育", "教育"), ("industry", "医疗", "医疗"), ("industry", "文化传媒", "文化传媒"),
         ("industry", "建筑", "建筑")]
rows = ",".join(f"({q(t)},{q(l)},{q(v)},{i},1)" for i, (t, l, v) in enumerate(dicts, 1))
w("INSERT INTO sys_dict (dict_type,dict_label,dict_value,sort_no,status) VALUES " + rows + ";")

# ---------------- 用户 ----------------
w("\n-- 用户：1 管理员 + 3 校内导师 + 4 企业导师 + 12 学生")
users = [
    ("admin", PW_ADMIN, "林致远", "13900000001", "admin@univ.edu.cn", "admin", 3, "教务处实习管理科", "ALL", "2026-02-20 09:00:00", None, None, None, None),
    ("limh", PW_USER, "李明华", "13900000011", "limh@univ.edu.cn", "teacher", 1, "计算机学院", "ORG", "2026-02-21 09:12:00", None, None, None, None),
    ("chenlq", PW_USER, "陈立群", "13900000012", "chenlq@univ.edu.cn", "teacher", 1, "计算机学院", "ORG", "2026-02-21 09:20:00", None, None, None, None),
    ("wangh", PW_USER, "王慧", "13900000013", "wangh@univ.edu.cn", "teacher", 2, "商学院", "ORG", "2026-02-21 09:26:00", None, None, None, None),
    ("zhoujg", PW_USER, "周建国", "13900000021", "zhoujg@yusur.com", "mentor", 4, "杭州云枢科技有限公司", "SELF", "2026-03-02 10:00:00", None, None, None, 4),
    ("wangq", PW_USER, "王倩", "13900000022", "wangq@yongxin.com", "mentor", 5, "宁波甬信会计师事务所", "SELF", "2026-03-02 10:05:00", None, None, None, 5),
    ("liuch", PW_USER, "刘畅", "13900000023", "liuch@supcon.com", "mentor", 4, "杭州云枢科技有限公司", "SELF", "2026-03-02 10:10:00", None, None, None, 4),
    ("zhengn", PW_USER, "郑楠", "13900000024", "zhengn@shiguang.com", "mentor", 4, "杭州云枢科技有限公司", "SELF", "2026-03-05 10:00:00", None, None, None, 4),
    ("chenzy", PW_USER, "陈知远", "13800001001", "chenzy@stu.edu.cn", "student", 1, "计算机学院", "SELF", "2026-09-01 08:40:00", "2022010312", "软件工程", "2022级", None),
    ("songyt", PW_USER, "宋雨桐", "13800001002", "songyt@stu.edu.cn", "student", 2, "商学院", "SELF", "2026-09-01 08:42:00", "2022010455", "数据科学与大数据技术", "2022级", None),
    ("zhaoym", PW_USER, "赵一鸣", "13800001003", "zhaoym@stu.edu.cn", "student", 1, "计算机学院", "SELF", "2026-09-01 08:44:00", "2022010388", "网络工程", "2022级", None),
    ("zhourh", PW_USER, "周若菡", "13800001004", "zhourh@stu.edu.cn", "student", 2, "商学院", "SELF", "2026-09-01 08:46:00", "2021010721", "市场营销", "2021级", None),
    ("linjh", PW_USER, "林嘉禾", "13800001005", "linjh@stu.edu.cn", "student", 1, "计算机学院", "SELF", "2026-09-01 08:48:00", "2022010522", "软件工程", "2022级", None),
    ("wucy", PW_USER, "吴承宇", "13800001006", "wucy@stu.edu.cn", "student", 1, "计算机学院", "SELF", "2026-08-28 15:10:00", "2021010666", "软件工程", "2021级", None),
    ("hsn", PW_USER, "何书宁", "13800001007", "hsn@stu.edu.cn", "student", 1, "计算机学院", "SELF", "2026-08-28 15:14:00", "2022010399", "人工智能", "2022级", None),
    ("zyh", PW_USER, "郑亦航", "13800001008", "zyh@stu.edu.cn", "student", 1, "计算机学院", "SELF", "2026-08-28 15:18:00", "2022010410", "软件工程", "2022级", None),
    ("xuly", PW_USER, "徐乐言", "13800001009", "xuly@stu.edu.cn", "student", 2, "商学院", "SELF", "2026-09-02 09:00:00", "2022010611", "会计学", "2022级", None),
    ("mengx", PW_USER, "孟祥宇", "13800001010", "mengx@stu.edu.cn", "student", 1, "计算机学院", "SELF", "2026-09-02 09:05:00", "2022010712", "计算机科学与技术", "2022级", None),
    ("fangyy", PW_USER, "方雨欣", "13800001011", "fangyy@stu.edu.cn", "student", 2, "商学院", "SELF", "2026-09-02 09:08:00", "2022010813", "工商管理", "2022级", None),
    ("tanjy", PW_USER, "谭嘉懿", "13800001012", "tanjy@stu.edu.cn", "student", 1, "计算机学院", "SELF", "2026-09-02 09:12:00", "2022010914", "软件工程", "2022级", None),
]
rows = []
for i, (un, pw, rn, ph, em, rc, oid, on, ds, ct, sno, mj, gr, cid) in enumerate(users, 1):
    avail = "NULL"
    if rc in ("student", "teacher", "mentor"):
        avail = q(img("avatar", i, 6))
    rows.append(f"({q(un)},{q(pw)},{q(rn)},{q(ph)},{q(em)},{avail},{q(rc)},{oid},{q(on)},{q(ds)},1,0,NULL,"
                f"{q('2026-10-30 09:12:00') if i < 8 else 'NULL'},{q(sno)},{q(mj)},{q(gr)},{q(cid)},{q(ct)})")
w("""INSERT INTO sys_user (username,password,real_name,phone,email,avatar,role_code,org_id,org_name,data_scope,
status,fail_count,lock_until,last_login_time,student_no,major,grade,company_id,create_time) VALUES """)
w(",".join(rows) + ";")

# ---------------- 批次 ----------------
w("\n-- 实习批次")
w("""INSERT INTO internship_batch (batch_no,semester,departments,start_date,end_date,report_deadline,grace_days,
score_weights,required_materials,min_reports,status,create_time) VALUES
('B2026S1','2026-2027 学年第一学期','计算机学院 / 商学院','2026-09-01','2027-02-28','每周日 23:59',2,'40/40/20',
 '三方协议、人身意外险、结项报告',12,'启用','2026-08-20 10:00:00'),
('B2025S2','2025-2026 学年第二学期','计算机学院','2026-02-24','2026-07-10','每周日 23:59',2,'40/40/20',
 '三方协议、人身意外险、结项报告',12,'已归档','2026-02-10 10:00:00'),
('B2025S1','2025-2026 学年第一学期','全校','2025-09-01','2026-01-15','每周日 23:59',3,'50/30/20',
 '三方协议、人身意外险',12,'已归档','2025-08-18 10:00:00');""")

# ---------------- 企业 ----------------
w("\n-- 企业库")
comps = [
    ("C0001", "杭州云枢科技有限公司", "信息技术", "杭州市余杭区文一西路 969 号", "杭州", "周建国", "0571-88002001", "500-1000 人", 17, 4.60, "正常"),
    ("C0002", "宁波甬信会计师事务所", "金融", "宁波市鄞州区首南街道泰康中路 558 号", "宁波", "王倩", "0574-88002002", "100-500 人", 9, 4.20, "正常"),
    ("C0003", "浙江中控技术股份有限公司", "制造", "杭州市滨江区六和路 309 号", "杭州", "刘畅", "0571-88002003", "1000 人以上", 22, 4.40, "正常"),
    ("C0004", "杭州拾光传媒有限公司", "文化传媒", "杭州市西湖区文三路 90 号", "杭州", "郑楠", "0571-88002004", "50-100 人", 5, 3.60, "关注"),
    ("C0005", "深圳恒瑞医疗器械有限公司", "医疗", "深圳市南山区科技园北区", "深圳", "黄磊", "0755-88002005", "100-500 人", 6, 4.10, "正常"),
    ("C0006", "杭州同花顺网络信息股份有限公司", "金融", "杭州市余杭区五常街道同顺街 18 号", "杭州", "方晓", "0571-88002006", "1000 人以上", 31, 4.50, "正常"),
    ("C0007", "上海远景能源有限公司", "制造", "上海市浦东新区张江高科技园区", "上海", "孙悦", "021-88002007", "1000 人以上", 12, 4.30, "正常"),
    ("C0008", "北京字节跳动科技有限公司", "信息技术", "北京市海淀区知春路甲 48 号", "北京", "张一凡", "010-88002008", "1000 人以上", 26, 4.70, "正常"),
    ("C0009", "杭州育才教育科技有限公司", "教育", "杭州市拱墅区莫干山路 972 号", "杭州", "钱蕾", "0571-88002009", "100-500 人", 8, 3.90, "正常"),
    ("C0010", "浙江建工集团第三建设有限公司", "建筑", "杭州市上城区秋涛北路 88 号", "杭州", "陆斌", "0571-88002010", "1000 人以上", 14, 4.00, "正常"),
    ("C0011", "杭州星野网络科技工作室", "信息技术", "杭州市拱墅区祥园路 108 号", "杭州", "—", "0571-88002011", "20 人以下", 1, 2.40, "风险"),
    ("C0012", "苏州精密仪器制造有限公司", "制造", "苏州市工业园区星湖街 328 号", "苏州", "毛骏", "0512-88002012", "500-1000 人", 11, 4.10, "正常"),
]
rows = ",".join(
    f"({q(no)},{q(n)},{q(ind)},{q(addr)},{q(city)},{q(c)}, {q(ph)},{q(sc)},{past},{sc2},{q(risk)},{q(img('company', i, 6))},"
    f"{q(n + '，主营' + ind + '相关业务，与学院保持多年实习合作。')},'2026-03-01 10:00:00')"
    for i, (no, n, ind, addr, city, c, ph, sc, past, sc2, risk) in enumerate(comps, 1))
w("""INSERT INTO internship_company (company_no,company_name,industry,address,city,contact,phone,scale,past_students,
avg_score,risk_status,license_image,intro,create_time) VALUES """)
w(rows + ";")

# ---------------- 实习档案 ----------------
w("\n-- 实习档案（20 条，覆盖全部阶段）")
apps = [
    # no, 学生key, 公司idx, 岗位, 阶段, 周报状态, 开始, 结束, 来源, 导师, 企业导师
    ("SI20260031", "chenzy", 1, "后端开发实习", "实习备案", "待提交", "2026-11-03", "2027-02-28", "集中实习", "limh", "zhoujg"),
    ("SI20260030", "songyt", 2, "数据分析助理", "协议审核", "待提交", "2026-10-26", "2027-02-20", "集中实习", "wangh", "wangq"),
    ("SI20260029", "zhaoym", 3, "运维实习", "过程周报", "待批阅", "2026-09-15", "2027-01-31", "集中实习", "chenlq", "liuch"),
    ("SI20260028", "zhourh", 7, "产品运营实习", "过程周报", "已批阅", "2026-09-08", "2027-01-20", "自主实习", "wangh", "sunyue"),
    ("SI20260027", "linjh", 4, "前端开发实习", "企业评价", "已批阅", "2026-08-25", "2026-12-31", "自主实习", "limh", "zhengn"),
    ("SI20260026", "wucy", 5, "测试实习", "学校归档", "已批阅", "2025-09-10", "2026-01-10", "集中实习", "wangh", "huanglei"),
    ("SI20260025", "hsn", 8, "算法实习", "已中止", "已批阅", "2026-07-01", "2026-12-20", "自主实习", "wangh", "zhangyf"),
    ("SI20260024", "zyh", 6, "Java 开发实习", "过程周报", "已退修", "2026-09-01", "2027-01-15", "自主实习", "limh", "fangx"),
    ("SI20260023", "xuly", 2, "审计助理", "过程周报", "已批阅", "2026-09-10", "2027-01-10", "集中实习", "wangh", "wangq"),
    ("SI20260022", "mengx", 3, "嵌入式开发实习", "过程周报", "待批阅", "2026-09-12", "2027-01-20", "集中实习", "chenlq", "liuch"),
    ("SI20260021", "fangyy", 9, "教务运营实习", "过程周报", "已批阅", "2026-09-05", "2027-01-05", "自主实习", "wangh", "qianlei"),
    ("SI20260020", "tanjy", 1, "前端开发实习", "阶段检查", "已批阅", "2026-09-01", "2027-01-31", "集中实习", "limh", "zhoujg"),
    ("SI20260019", "chenzy", 3, "测试开发实习", "已中止", "逾期未交", "2026-04-01", "2026-08-31", "集中实习", "chenlq", "liuch"),
    ("SI20260018", "songyt", 6, "数据分析实习", "学校归档", "已批阅", "2025-09-05", "2026-01-08", "自主实习", "wangh", "fangx"),
    ("SI20260017", "zhourh", 11, "市场营销实习", "企业评价", "已批阅", "2026-08-20", "2026-12-25", "自主实习", "wangh", "maojun"),
    ("SI20260016", "linjh", 4, "运营实习", "协议审核", "待提交", "2026-11-10", "2027-03-10", "自主实习", "limh", "zhengn"),
    ("SI20260015", "zhaoym", 10, "施工管理实习", "实习备案", "待提交", "2026-11-15", "2027-04-15", "集中实习", "chenlq", "lubin"),
    ("SI20260014", "wucy", 12, "工艺实习", "过程周报", "已批阅", "2026-09-20", "2027-02-10", "集中实习", "chenlq", "maojun"),
    ("SI20260013", "mengx", 1, "后端开发实习", "阶段检查", "已批阅", "2026-09-02", "2027-02-01", "集中实习", "limh", "zhoujg"),
    ("SI20260012", "xuly", 10, "财务实习", "实习备案", "待提交", "2026-11-20", "2027-04-20", "自主实习", "wangh", "lubin"),
]
app_rows = []
app_meta = []
for i, (no, sk, ci, pos, stage, rs, sd, ed, src, t, m) in enumerate(apps, 1):
    u = users[[x[0] for x in users].index(sk)]
    name, sno, mj, gr = u[2], u[10], u[11], u[12]
    comp = comps[ci - 1]
    teacher = {"limh": 2, "chenlq": 3, "wangh": 4}[t]
    mentor_id = {"zhoujg": 5, "wangq": 6, "liuch": 7, "zhengn": 8}.get(m, None)
    mentor_name = {"zhoujg": "周建国", "wangq": "王倩", "liuch": "刘畅", "zhengn": "郑楠",
                   "sunyue": "孙悦", "huanglei": "黄磊", "zhangyf": "张一凡", "fangx": "方晓",
                   "qianlei": "钱蕾", "lubin": "陆斌", "maojun": "毛骏"}[m]
    tname = {"limh": "李明华", "chenlq": "陈立群", "wangh": "王慧"}[t]
    created = datetime.strptime(sd, "%Y-%m-%d") - timedelta(days=random.randint(4, 12))
    created = created.replace(hour=random.randint(9, 17), minute=random.randint(0, 59))
    reason = None
    if stage == "已中止":
        reason = "个人健康原因，经校内导师与管理员审批后中止"
    app_rows.append(
        f"({q(no)},{suid(i)},{q(name)},{q(sno)},{q(mj)},{q(gr)},{ci},{q(comp[1])},{q(pos)},{q(comp[2])},{q(comp[4])},"
        f"{teacher},{q(tname)},{q(mentor_id)},{q(mentor_name)},1,'B2026S1',{q(sd)},{q(ed)},{q(src)},{q(stage)},{q(rs)},"
        f"{q('/uploads/seed/work/%02d.jpg' % (((i*7) % 6) + 1))},"
        f"{q('/uploads/seed/work/%02d.jpg' % ((((i+2)*7) % 6) + 1))},"
        f"{q('/uploads/seed/work/%02d.jpg' % ((((i+4)*7) % 6) + 1))},"
        f"{q(reason)},1,0,{i},{q(dt(created))},{q(dt(created + timedelta(days=random.randint(1, 6))))})")
    app_meta.append(dict(id=i, no=no, name=name, stage=stage, company=comp[1], industry=comp[2],
                         city=comp[4], sd=sd, ed=ed, teacher=teacher, tname=tname,
                         mentor_name=mentor_name, pos=pos, rs=rs))
w("""INSERT INTO internship_application (internship_no,student_id,student_name,student_no,major,grade,company_id,
company_name,position,industry,city,teacher_id,teacher_name,mentor_id,mentor_name,batch_id,batch_no,start_date,end_date,
source,stage,report_status,agreement_file,insurance_file,accept_file,transition_reason,version,deleted,create_by,
create_time,update_time) VALUES """)
w(",\n".join(app_rows) + ";")

# ---------------- 里程碑 ----------------
w("\n-- 阶段里程碑（每个档案 4 项）")
ms_rows = []
titles = ["入职与安全培训", "熟悉业务与代码结构", "独立承担核心任务", "成果汇报与复盘"]
for a in app_meta:
    started = datetime.strptime(a["sd"], "%Y-%m-%d")
    for k, ttl in enumerate(titles, 1):
        if a["stage"] in ("实习备案", "协议审核"):
            st, cd, delay = "未开始", None, 0
        elif a["stage"] == "已中止":
            st = "已完成" if k <= 2 else "未开始"
            cd = (started + timedelta(weeks=k * 2)).date() if k <= 2 else None
            delay = 0
        elif a["stage"] == "学校归档":
            st, cd, delay = "已完成", (started + timedelta(weeks=k * 3)).date(), 0
        else:
            if k <= 2:
                st, cd, delay = "已完成", (started + timedelta(weeks=k * 3 - 1)).date(), 0
            elif k == 3:
                st, cd, delay = "进行中", None, 0
            else:
                st, cd, delay = "未开始", None, 0
        ms_rows.append(f"({a['id']},{k},{q(ttl)},{k*3},{q(st)},{q(cd)},{delay},{q(dt(started))})")
w("INSERT INTO internship_milestone (application_id,seq_no,title,plan_week,status,complete_date,delayed_days,create_time) VALUES ")
w(",\n".join(ms_rows) + ";")

# ---------------- 周报 ----------------
w("\n-- 周报（40+ 条，覆盖各状态与跨月份提交时间）")
rep_rows = []
report_meta = []
rno = 1
for a in app_meta:
    if a["stage"] in ("实习备案", "协议审核"):
        continue
    started = datetime.strptime(a["sd"], "%Y-%m-%d")
    weeks = 8
    for wk in range(1, weeks + 1):
        ws = started + timedelta(weeks=wk - 1)
        we = ws + timedelta(days=6)
        submit = datetime.combine(we, datetime.min.time()) + timedelta(hours=random.randint(17, 22), minutes=random.randint(0, 59))
        deadline = datetime.combine(we + timedelta(days=1), datetime.min.time()).replace(hour=23, minute=59)
        if a["stage"] == "已中止" and wk > 5:
            continue
        status = "已批阅"
        if wk == weeks:
            status = {"待批阅": "待批阅", "已退修": "已退修", "逾期未交": "逾期未交", "待提交": "待批阅"}.get(a["rs"], "待批阅")
        if a["stage"] == "学校归档":
            status = "已批阅"
        if status == "逾期未交":
            submit_time = None
        else:
            submit_time = submit
        score = random.choice([80, 82, 84, 85, 86, 88, 90, 92]) if status == "已批阅" else None
        comment = None
        reviewer = None
        rtime = None
        if status == "已批阅":
            comment = "任务描述具体，问题记录清楚，下周计划可执行。"
            reviewer = a["tname"]
            rtime = submit + timedelta(days=random.randint(1, 3))
        elif status == "已退修":
            comment = "附件缺少测试记录，请补充后重新提交。"
            reviewer = a["tname"]
            rtime = submit + timedelta(days=2)
        tasks = [
            "完成订单查询接口分页与排序，补充单元测试 12 条",
            "参与需求评审，整理接口文档初稿",
            "定位线上慢查询并补充索引，平均响应从 820ms 降到 210ms",
            "完成客户流水抽样复核，输出差异说明",
            "机房巡检 12 次，处理磁盘告警 2 起",
            "重构前端公共表格组件，减少重复代码约 400 行",
            "完成竞品调研报告，梳理 6 家同类产品功能矩阵",
        ]
        rep_no = f"WR{we.strftime('%Y%m%d')}{rno:03d}"
        rep_rows.append(
            f"({q(rep_no)},{a['id']},{q(a['no'])},{suid(a['id'])},{q(a['name'])},{wk},{q(ws.date())},{q(we.date())},"
            f"{q(tasks[(wk + a['id']) % len(tasks)])},{q('掌握分页插件用法与索引命中分析')},"
            f"{q('联调环境数据为空导致总数为 0，已与测试同学确认为环境问题')},{q('接入缓存层并压测 QPS 200 场景')},"
            f"{q('/uploads/seed/work/%02d.jpg' % (((rno*7) % 6) + 1))},{q('/uploads/seed/work/%02d.jpg' % ((((rno+3)*7) % 6) + 1))},"
            f"{q(dt(submit_time)) if submit_time else 'NULL'},{q(dt(deadline))},{q(status)},{q(score)},{q(comment)},"
            f"{q(a['teacher'] if reviewer else None)},{q(reviewer)},{q(dt(rtime)) if rtime else 'NULL'},{q(dt(ws))})")
        report_meta.append(dict(no=rep_no, app=a["id"], student=a["name"], status=status, week=wk, submit=submit_time))
        rno += 1
w("""INSERT INTO weekly_report (report_no,application_id,internship_no,student_id,student_name,week_no,week_start,
week_end,task_content,harvest,problem,next_plan,attachment_image,attachment_file,submit_time,deadline,status,
review_score,review_comment,reviewer_id,reviewer_name,review_time,create_time) VALUES """)
w(",\n".join(rep_rows) + ";")

# ---------------- 考勤 ----------------
w("\n-- 月度考勤")
att_rows = []
ano = 1
for a in app_meta:
    if a["stage"] in ("实习备案", "协议审核"):
        continue
    months = ["2026-09", "2026-10"]
    if a["stage"] == "学校归档":
        months = ["2025-10", "2025-11", "2025-12", "2026-01"]
    for m in months:
        should = 22
        actual = random.choice([22, 22, 21, 20, 19])
        late = 0 if actual == 22 else random.choice([1, 2])
        leave = should - actual
        cs = "学生已确认"
        remark = "—"
        if a["name"] == "林嘉禾" and m == "2026-10":
            cs, actual, leave, remark = "学生有异议", 14, 8, "请假天数存在争议，学生申请复核"
        elif a["id"] % 5 == 0:
            cs = "待学生确认"
        att_rows.append(f"({q('AT' + m.replace('-', '') + f'{ano:03d}')},{a['id']},{suid(a['id'])},{q(a['name'])},"
                        f"{q(a['company'])},{q(m)},{should},{actual},{late},{leave},{q(remark)},{q(cs)},"
                        f"{q(a['mentor_name'])},{q(dt(datetime.strptime(m + '-28', '%Y-%m-%d')) )})")
        ano += 1
w("""INSERT INTO monthly_attendance (attendance_no,application_id,student_id,student_name,company_name,month,
should_days,actual_days,late_count,leave_days,remark,confirm_status,mentor_name,create_time) VALUES """)
w(",\n".join(att_rows) + ";")

# ---------------- 变更 ----------------
w("\n-- 变更审批")
changes = [
    ("CH20261028002", 4, "周若菡", "更换岗位", "产品运营实习", "产品经理实习", "企业业务调整，岗位职责升级，与学生职业规划一致", "校内审批", "审批中", "2026-10-28 15:20:00"),
    ("CH20261026001", 2, "宋雨桐", "更换导师", "王倩", "陈默", "原企业导师调岗离任，由项目经理接任", "管理员审批", "审批中", "2026-10-26 10:05:00"),
    ("CH20261018003", 7, "何书宁", "中止实习", "实习中", "已中止", "个人健康原因，已提交医院证明与家长知情书", "已生效", "已通过", "2026-10-18 09:30:00"),
    ("CH20261009004", 8, "郑亦航", "更换企业", "杭州同花顺", "浙江中控技术", "原企业岗位与专业方向不符，经学院协调重新安排", "已生效", "已通过", "2026-10-09 14:12:00"),
    ("CH20260928005", 5, "林嘉禾", "更换导师", "郑楠", "郑楠", "导师联系方式变更，仅更新联系方式", "已驳回", "已驳回", "2026-09-28 11:00:00"),
    ("CH20260915006", 11, "方雨欣", "更换岗位", "教务运营实习", "课程顾问实习", "企业内轮岗，岗位内容相近", "已生效", "已通过", "2026-09-15 16:40:00"),
]
rows = ",".join(
    f"({q(no)},{aid},{q(nm)},{q(t)},{q(b)},{q(af)},{q(r)},{q('/uploads/seed/work/%02d.jpg' % ((i*7)%6+1))},"
    f"{q(node)},{q(st)},{q(at)},{q('同意，材料齐全' if node in ('管理员审批','已生效') else None)},"
    f"{q('同意变更' if node == '已生效' else None)},{q(at) if node == '已生效' else 'NULL'},{q(at)})"
    for i, (no, aid, nm, t, b, af, r, node, st, at) in enumerate(changes, 1))
w("""INSERT INTO internship_change (change_no,application_id,student_name,change_type,before_value,after_value,reason,
attachment,current_node,status,apply_time,teacher_opinion,admin_opinion,effective_time,create_time) VALUES """)
w(rows + ";")

# ---------------- 异常 ----------------
w("\n-- 异常关怀")
issues = [
    ("IS20261029001", 5, "林嘉禾", "杭州拾光传媒有限公司", "薪资争议", "高", "企业按 80% 发放 9 月实习补贴，与协议约定不符", "2026-10-29 11:20:00", "李明华", "处置中"),
    ("IS20261027002", 3, "赵一鸣", "浙江中控技术股份有限公司", "岗位不符", "中", "实际工作以文档整理为主，与运维岗位描述差异较大", "2026-10-27 09:05:00", "陈立群", "处置中"),
    ("IS20261020003", 7, "何书宁", "北京字节跳动科技有限公司", "无法联系", "高", "连续 5 天未提交周报且电话无法接通", "2026-10-20 16:40:00", "王慧", "已关闭"),
    ("IS20261011004", 6, "吴承宇", "深圳恒瑞医疗器械有限公司", "安全问题", "中", "实验室未按规范配备防护用品", "2026-10-11 14:12:00", "王慧", "已关闭"),
    ("IS20260925005", 8, "郑亦航", "杭州同花顺网络信息股份有限公司", "岗位不符", "低", "轮岗安排与原岗位不一致，已协调", "2026-09-25 10:30:00", "李明华", "已关闭"),
    ("IS20260918006", 12, "谭嘉懿", "杭州云枢科技有限公司", "无法联系", "中", "企业导师出差，周报批阅延迟两周", "2026-09-18 15:00:00", "李明华", "已关闭"),
]
rows = []
for no, aid, nm, comp, t, lv, content, rt, handler, st in issues:
    record = ("2026-10-31 10:30 现场走访核实，企业承诺 11 月补发差额，等待整改回执" if no == "IS20261029001"
              else "已电话联系企业人事，约定岗位调整方案" if st == "处置中"
              else "已完成处置并回访确认，学生状态正常，工单关闭")
    close = rt if st == "已关闭" else None
    rows.append(f"({q(no)},{aid},{q(nm)},{q(comp)},{q(t)},{q(lv)},{q(content)},{q(rt)},{q(handler)},{q(st)},"
                f"{q(record)},{q(close)},{q(rt)})")
w("""INSERT INTO internship_issue (issue_no,application_id,student_name,company_name,issue_type,level,content,
report_time,handler_name,status,handle_record,close_time,create_time) VALUES """)
w(",".join(rows) + ";")

# ---------------- 走访 ----------------
w("\n-- 走访记录")
visits = [
    ("VS20261031001", 5, "林嘉禾", "杭州拾光传媒有限公司", "现场", "2026-10-31", "李明华、郑楠", "工作投入，沟通顺畅，对薪资问题表达合理诉求", "认可能力，承诺 11 月补发差额并规范结算", 2),
    ("VS20261024002", 3, "赵一鸣", "浙江中控技术股份有限公司", "电话", "2026-10-24", "陈立群", "适应良好，夜班较多，希望增加轮岗", "同意安排轮岗并明确岗位职责", 3),
    ("VS20261017003", 1, "陈知远", "杭州云枢科技有限公司", "现场", "2026-10-17", "李明华", "技术成长明显，能独立承担接口开发", "建议加强文档习惯与代码评审参与度", 1),
    ("VS20261010004", 4, "周若菡", "上海远景能源有限公司", "电话", "2026-10-10", "王慧", "工作主动，能独立完成调研任务", "希望学校增加数据分析相关课程", 2),
    ("VS20260926005", 8, "郑亦航", "杭州同花顺网络信息股份有限公司", "现场", "2026-09-26", "李明华", "基础扎实，需加强需求澄清主动性", "愿意提供转正机会", 3),
    ("VS20260919006", 2, "宋雨桐", "宁波甬信会计师事务所", "电话", "2026-09-19", "王慧", "适应良好，能承担抽样复核工作", "建议加强沟通表达", 1),
]
rows = ",".join(
    f"({q(no)},{aid},{q(nm)},{q(comp)},{q(t)},{q(vd)},{q(pp)},{q(sp)},{q(co)},{q('/uploads/seed/visit/%02d.jpg' % ((i*7)%4+1))},"
    f"2,{q('李明华' if i % 2 else '王慧')},{q(vd + ' 10:00:00')})"
    for i, (no, aid, nm, comp, t, vd, pp, sp, co, _x) in enumerate(visits, 1))
w("""INSERT INTO visit_record (visit_no,application_id,student_name,company_name,visit_type,visit_date,participants,
student_performance,company_opinion,photo,teacher_id,teacher_name,create_time) VALUES """)
w(rows + ";")

# ---------------- 结项评价 ----------------
w("\n-- 结项评价")
rows = []
for a in app_meta:
    if a["stage"] not in ("企业评价", "学校归档", "阶段检查", "过程周报", "已中止"):
        continue
    cs = round(random.uniform(3.6, 4.8), 1)
    ss = random.choice([82, 85, 86, 88, 90, 92])
    rs = random.choice([85.0, 88.0, 90.0, 93.0])
    if a["stage"] == "学校归档":
        total = round(cs / 5 * 40 + ss * 0.4 + rs * 0.2, 1)
        grade = "优秀" if total >= 90 else "良好" if total >= 80 else "合格"
        st, ok = "已结项", 1
    elif a["stage"] in ("企业评价", "阶段检查"):
        total = round(cs / 5 * 40 + ss * 0.4 + rs * 0.2, 1)
        grade = "良好" if total >= 80 else "合格"
        st, ok = "评价中", 0
    else:
        total, grade, st, ok = None, None, "待评价", 0
    rows.append(f"({a['id']},{q(a['name'])},{cs},{q('工作认真，交付质量稳定，团队协作良好')},{q(a['mentor_name'])},"
                f"{q('2026-10-25 15:00:00') if st != '待评价' else 'NULL'},{ss},"
                f"{q('全程按时提交周报，问题反馈及时')},{q(a['tname'])},"
                f"{q('2026-10-27 10:00:00') if st != '待评价' else 'NULL'},{rs},{q(total)},{q(grade)},{ok},{q(st)},"
                f"{q(a['sd'] + ' 09:00:00')})")
w("""INSERT INTO final_evaluation (application_id,student_name,company_score,company_comment,company_evaluator,
company_time,school_score,school_comment,school_evaluator,school_time,report_score,total_score,grade,materials_ok,
status,create_time) VALUES """)
w(",\n".join(rows) + ";")

# ---------------- 规则 ----------------
w("\n-- 创新点规则（v1~v3，仅 v3 生效）")
w("""INSERT INTO internship_rule (rule_name,version,weight_milestone,weight_continuity,weight_attachment,weight_feedback,
weight_delay,weight_company,threshold_good,threshold_mid,enabled,effective_time,create_by,create_time) VALUES
('周报里程碑完整度检查','v1',30,20,15,15,10,10,80,60,0,'2026-03-01 00:00:00','系统初始化','2026-03-01 00:00:00'),
('周报里程碑完整度检查','v2',25,20,20,15,10,10,80,60,0,'2026-06-15 00:00:00','王慧','2026-06-15 09:00:00'),
('周报里程碑完整度检查','v3',30,20,15,15,10,10,80,60,1,'2026-09-01 00:00:00','李明华','2026-09-01 09:00:00');""")

# ---------------- 计算留痕 ----------------
w("\n-- 完整度计算留痕（每个在岗档案 3 周，共 30+ 条）")
score_rows = []
for a in app_meta:
    if a["stage"] in ("实习备案", "协议审核"):
        continue
    base = 70 + (a["id"] % 5) * 4
    for wkn in range(6, 9):
        ms_done = 2 if wkn == 6 else 3 if wkn == 7 else 3
        total = round(min(98, base + (wkn - 6) * 4 + random.uniform(-2, 2)), 1)
        grade = "优秀" if total >= 90 else "良好" if total >= 80 else "合格" if total >= 60 else "待改进"
        detail = [
            {"key": "milestone", "label": "里程碑完成项", "value": f"{ms_done}/4", "weight": 30,
             "score": round(ms_done / 4 * 30, 1), "note": f"已完成 {ms_done} 项里程碑"},
            {"key": "continuity", "label": "周报连续性", "value": f"连续 {wkn} 周", "weight": 20,
             "score": 20.0 if wkn >= 4 else 12.0, "note": "无缺交、无逾期"},
            {"key": "attachment", "label": "附件数量", "value": "2 个", "weight": 15, "score": 15.0, "note": "附件数量满足要求"},
            {"key": "feedback", "label": "导师反馈", "value": "4.5 分", "weight": 15,
             "score": round(4.5 / 5 * 15, 1), "note": "批阅及时，评语具体"},
            {"key": "delay", "label": "延期任务", "value": "1 项", "weight": 10, "score": 6.0, "note": "接口联调延期 4 天"},
            {"key": "company", "label": "企业评价", "value": "4.3 分", "weight": 10,
             "score": round(4.3 / 5 * 10, 1), "note": "企业导师月度评价"},
        ]
        snap = {"weekNo": wkn, "milestoneDone": ms_done, "milestoneTotal": 4, "continuityWeeks": wkn,
                "attachmentCount": 2, "feedbackScore": 4.5, "delayCount": 1, "companyScore": 4.3}
        advice = "将第 3 项里程碑拆分为两个子任务并提前一周排期；下周补充接口文档附件"
        manual = None
        mreason = None
        mby = None
        mtime = None
        if a["id"] % 7 == 0 and wkn == 8:
            manual = "优秀" if total < 90 else "良好"
            mreason = "综合走访记录与企业反馈，实际表现优于计算结果"
            mby = "李明华"
            mtime = f"2026-10-31 15:20:00"
        score_rows.append(
            f"({a['id']},{q(a['name'])},3,'v3',{q(json.dumps(snap, ensure_ascii=False))},"
            f"{q(json.dumps(detail, ensure_ascii=False))},{total},{q(grade)},{q(advice)},{q(manual)},{q(mreason)},"
            f"{q(mby)},{q(mtime)},{wkn},{q(f'2026-10-{24 + wkn - 7:02d} 09:00:00') if wkn < 8 else q('2026-10-31 09:00:00')})")
w("""INSERT INTO internship_score (application_id,student_name,rule_id,rule_version,input_json,detail_json,total_score,
grade,advice,manual_grade,manual_reason,manual_by,manual_time,calc_week,calc_time) VALUES """)
w(",\n".join(score_rows) + ";")

# ---------------- 消息 ----------------
w("\n-- 站内消息")
msgs = [
    ("SI20260031 陈知远 提交实习备案，等待审核", "实习备案待审核，请于 2 个工作日内处理", "待审批", "SI20260031", "/application", 1, 0, "2026-10-31 09:12:00"),
    ("WR20261030007 周报被退修：附件缺少测试记录", "已标注缺项，学生需补充后重新提交", "已退回", "WR20261030007", "/report", 9, 0, "2026-10-30 20:15:00"),
    ("第 9 周周报将于 11-08 23:59 截止", "请按时提交本周周报", "即将超时", "B2026S1", "/report", 9, 0, "2026-10-30 08:00:00"),
    ("CH20261018003 中止实习变更已生效", "档案已转为已中止，材料已归档", "处理完成", "CH20261018003", "/change", 9, 1, "2026-10-19 10:22:00"),
    ("IS20261029001 薪资争议等待处置", "已现场走访，等待企业整改回执", "待审批", "IS20261029001", "/issue", 1, 1, "2026-10-31 10:35:00"),
    ("10 月考勤已录入，请学生确认", "应出勤 22 天，实出勤 21 天", "待审批", "AT202610001", "/attendance", 1, 0, "2026-10-30 18:00:00"),
]
rows = ",".join(f"({q(t)},{q(c)},{q(tp)},{q(bz)},{q(lu)},{rc},0{rd},{q(ct)})"
                for t, c, tp, bz, lu, rc, rd, ct in [(m[0], m[1], m[2], m[3], m[4], m[5], m[6], m[7]) for m in msgs])
w("""INSERT INTO sys_message (title,content,msg_type,biz_no,link_url,receiver_id,is_read,create_time) VALUES """)
w(rows + ";")

# ---------------- 日志 ----------------
w("\n-- 操作日志")
log_rows = []
actions = [("登录系统", "POST /api/auth/login", 0), ("提交实习备案", "POST /api/application", 1),
           ("批阅周报", "POST /api/report/review", 1), ("导入企业库", "POST /api/company/import", 0),
           ("执行完整度计算", "POST /api/score/evaluate", 1), ("分配角色菜单", "POST /api/system/role/teacher/menus", 0),
           ("确认考勤", "POST /api/attendance/confirm", 1), ("导出统计报表", "GET /api/dashboard/export", 0)]
for i in range(40):
    a = actions[i % len(actions)]
    t = datetime(2026, 10, 31, 20, 0) - timedelta(hours=i * 5)
    log_rows.append(f"({(i % 8) + 1},{q('林致远' if i % 3 else '李明华')},{q(a[0])},{q(a[1])},"
                    f"{q('业务编号 SI2026' + f'{30 + i % 8:04d}')},{random.randint(12, 480)},{q(dt(t))})")
w("INSERT INTO sys_log (user_id,user_name,action,method,params,cost_ms,create_time) VALUES ")
w(",\n".join(log_rows) + ";")

with open(OUT, "w", encoding="utf-8") as f:
    f.write("\n".join(L) + "\n")

print("sql written:", OUT, len("\n".join(L)), "chars")
print("apps", len(app_meta), "reports", len(rep_rows), "scores", len(score_rows), "milestones", len(ms_rows))
