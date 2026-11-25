-- 大学生实习过程与周报管理系统 初始化脚本
-- MySQL 8 / utf8mb4；库名 new_024，导入后即可用 admin/admin123 登录
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;
DROP DATABASE IF EXISTS new_024;
CREATE DATABASE new_024 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE new_024;


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
  ip VARCHAR(50) DEFAULT NULL COMMENT '来源IP',
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

SET FOREIGN_KEY_CHECKS = 1;

-- 组织
INSERT INTO sys_org (id,org_name,org_type,parent_id,contact,phone,create_time) VALUES (1,'计算机学院','学院',NULL,'王慧','0571-88001001','2026-02-20 10:00:00'),(2,'商学院','学院',NULL,'赵明','0571-88001002','2026-02-20 10:00:00'),(3,'教务处实习管理科','管理部门',NULL,'孙涛','0571-88001003','2026-02-20 10:00:00'),(4,'杭州云枢科技有限公司','企业',NULL,'周建国','0571-88002001','2026-02-20 10:00:00'),(5,'宁波甬信会计师事务所','企业',NULL,'王倩','0574-88002002','2026-02-20 10:00:00');

-- 角色
INSERT INTO sys_role (role_code,role_name,description,data_scope,create_time) VALUES ('admin','实习管理员','维护批次、企业库、导师、规则、风险企业与统计','ALL','2026-02-20 10:00:00'),('teacher','校内指导教师','审核申请、批阅周报、记录走访、完成校内评价','ORG','2026-02-20 10:00:00'),('mentor','企业导师','确认到岗、工作内容、考勤与企业评价','SELF','2026-02-20 10:00:00'),('student','学生','提交实习申请、周报、变更、请假、异常与结项材料','SELF','2026-02-20 10:00:00');

-- 菜单（菜单管理项对业务角色隐藏，由后端过滤）
INSERT INTO sys_menu (id,parent_id,menu_name,path,icon,menu_type,sort_no,visible,create_time) VALUES (1,0,'工作台','/dashboard','dashboard','MENU',1,1,'2026-02-20 10:00:00'),(2,0,'实习过程',NULL,'archive','DIR',2,1,'2026-02-20 10:00:00'),(3,2,'实习备案中心','/application','archive','MENU',1,1,'2026-02-20 10:00:00'),(4,2,'考勤汇总','/attendance','calendar','MENU',2,1,'2026-02-20 10:00:00'),(5,2,'变更审批','/change','flag','MENU',3,1,'2026-02-20 10:00:00'),(6,2,'异常关怀','/issue','alert','MENU',4,1,'2026-02-20 10:00:00'),(7,2,'走访记录','/visit','people','MENU',5,1,'2026-02-20 10:00:00'),(8,0,'周报评价',NULL,'report','DIR',3,1,'2026-02-20 10:00:00'),(9,8,'周报工作台','/report','report','MENU',1,1,'2026-02-20 10:00:00'),(10,8,'导师批阅','/review','check','MENU',2,1,'2026-02-20 10:00:00'),(11,8,'里程碑进度','/milestone','flag','MENU',3,1,'2026-02-20 10:00:00'),(12,8,'结项评价','/evaluation','shield','MENU',4,1,'2026-02-20 10:00:00'),(13,0,'基础数据',NULL,'building','DIR',4,1,'2026-02-20 10:00:00'),(14,13,'企业库','/company','building','MENU',1,1,'2026-02-20 10:00:00'),(15,13,'实习批次','/batch','calendar','MENU',2,1,'2026-02-20 10:00:00'),(16,0,'分析配置',NULL,'chart','DIR',5,1,'2026-02-20 10:00:00'),(17,16,'统计看板','/board','chart','MENU',1,1,'2026-02-20 10:00:00'),(18,16,'规则配置','/rule','rule','MENU',2,1,'2026-02-20 10:00:00'),(19,0,'系统管理',NULL,'log','DIR',6,1,'2026-02-20 10:00:00'),(20,19,'用户管理','/system/user','user','MENU',1,1,'2026-02-20 10:00:00'),(21,19,'角色管理','/system/role','shield','MENU',2,1,'2026-02-20 10:00:00'),(22,19,'菜单管理','/system/menu','menu','MENU',3,0,'2026-02-20 10:00:00'),(23,19,'字典管理','/system/dict','log','MENU',4,1,'2026-02-20 10:00:00'),(24,19,'操作日志','/system/log','log','MENU',5,1,'2026-02-20 10:00:00'),(25,0,'消息中心','/message','message','MENU',7,1,'2026-02-20 10:00:00'),(26,0,'个人中心','/profile','user','MENU',8,1,'2026-02-20 10:00:00');
INSERT INTO sys_role_menu (role_code,menu_id) VALUES ('admin',1),('admin',2),('admin',3),('admin',4),('admin',5),('admin',6),('admin',7),('admin',8),('admin',9),('admin',10),('admin',11),('admin',12),('admin',13),('admin',14),('admin',15),('admin',16),('admin',17),('admin',18),('admin',19),('admin',20),('admin',21),('admin',23),('admin',24),('admin',25),('admin',26),('teacher',1),('teacher',2),('teacher',3),('teacher',6),('teacher',7),('teacher',8),('teacher',9),('teacher',10),('teacher',11),('teacher',12),('teacher',25),('teacher',26),('mentor',1),('mentor',3),('mentor',4),('mentor',8),('mentor',9),('mentor',12),('mentor',25),('mentor',26),('student',1),('student',2),('student',3),('student',5),('student',6),('student',8),('student',9),('student',11),('student',12),('student',25),('student',26);

-- 字典
INSERT INTO sys_dict (dict_type,dict_label,dict_value,sort_no,status) VALUES ('internship_stage','实习备案','实习备案',1,1),('internship_stage','协议审核','协议审核',2,1),('internship_stage','过程周报','过程周报',3,1),('internship_stage','阶段检查','阶段检查',4,1),('internship_stage','企业评价','企业评价',5,1),('internship_stage','学校归档','学校归档',6,1),('internship_stage','已中止','已中止',7,1),('report_status','待提交','待提交',8,1),('report_status','待批阅','待批阅',9,1),('report_status','已批阅','已批阅',10,1),('report_status','已退修','已退修',11,1),('change_type','更换企业','更换企业',12,1),('change_type','更换岗位','更换岗位',13,1),('change_type','更换导师','更换导师',14,1),('change_type','中止实习','中止实习',15,1),('issue_type','岗位不符','岗位不符',16,1),('issue_type','安全问题','安全问题',17,1),('issue_type','薪资争议','薪资争议',18,1),('issue_type','无法联系','无法联系',19,1),('industry','信息技术','信息技术',20,1),('industry','制造','制造',21,1),('industry','金融','金融',22,1),('industry','教育','教育',23,1),('industry','医疗','医疗',24,1),('industry','文化传媒','文化传媒',25,1),('industry','建筑','建筑',26,1);

-- 用户：1 管理员 + 3 校内导师 + 4 企业导师 + 12 学生
INSERT INTO sys_user (username,password,real_name,phone,email,avatar,role_code,org_id,org_name,data_scope,
status,fail_count,lock_until,last_login_time,student_no,major,grade,company_id,create_time) VALUES 
('admin','$2b$10$SARYGfGxo.ZCdLvADa/EIeDLyIQNPOhNThQ2KCp7NYT8O5EdZm5FK','林致远','13900000001','admin@univ.edu.cn',NULL,'admin',3,'教务处实习管理科','ALL',1,0,NULL,'2026-10-30 09:12:00',NULL,NULL,NULL,NULL,'2026-02-20 09:00:00'),('limh','$2b$10$OjXQ.6V/xTxVakLiiFBqcOMn/BJ0k9fGKq7T1uQM6YVRrREgEfX7q','李明华','13900000011','limh@univ.edu.cn','/uploads/seed/avatar/03.jpg','teacher',1,'计算机学院','ORG',1,0,NULL,'2026-10-30 09:12:00',NULL,NULL,NULL,NULL,'2026-02-21 09:12:00'),('chenlq','$2b$10$OjXQ.6V/xTxVakLiiFBqcOMn/BJ0k9fGKq7T1uQM6YVRrREgEfX7q','陈立群','13900000012','chenlq@univ.edu.cn','/uploads/seed/avatar/04.jpg','teacher',1,'计算机学院','ORG',1,0,NULL,'2026-10-30 09:12:00',NULL,NULL,NULL,NULL,'2026-02-21 09:20:00'),('wangh','$2b$10$OjXQ.6V/xTxVakLiiFBqcOMn/BJ0k9fGKq7T1uQM6YVRrREgEfX7q','王慧','13900000013','wangh@univ.edu.cn','/uploads/seed/avatar/05.jpg','teacher',2,'商学院','ORG',1,0,NULL,'2026-10-30 09:12:00',NULL,NULL,NULL,NULL,'2026-02-21 09:26:00'),('zhoujg','$2b$10$OjXQ.6V/xTxVakLiiFBqcOMn/BJ0k9fGKq7T1uQM6YVRrREgEfX7q','周建国','13900000021','zhoujg@yusur.com','/uploads/seed/avatar/06.jpg','mentor',4,'杭州云枢科技有限公司','SELF',1,0,NULL,'2026-10-30 09:12:00',NULL,NULL,NULL,4,'2026-03-02 10:00:00'),('wangq','$2b$10$OjXQ.6V/xTxVakLiiFBqcOMn/BJ0k9fGKq7T1uQM6YVRrREgEfX7q','王倩','13900000022','wangq@yongxin.com','/uploads/seed/avatar/01.jpg','mentor',5,'宁波甬信会计师事务所','SELF',1,0,NULL,'2026-10-30 09:12:00',NULL,NULL,NULL,5,'2026-03-02 10:05:00'),('liuch','$2b$10$OjXQ.6V/xTxVakLiiFBqcOMn/BJ0k9fGKq7T1uQM6YVRrREgEfX7q','刘畅','13900000023','liuch@supcon.com','/uploads/seed/avatar/02.jpg','mentor',4,'杭州云枢科技有限公司','SELF',1,0,NULL,'2026-10-30 09:12:00',NULL,NULL,NULL,4,'2026-03-02 10:10:00'),('zhengn','$2b$10$OjXQ.6V/xTxVakLiiFBqcOMn/BJ0k9fGKq7T1uQM6YVRrREgEfX7q','郑楠','13900000024','zhengn@shiguang.com','/uploads/seed/avatar/03.jpg','mentor',4,'杭州云枢科技有限公司','SELF',1,0,NULL,NULL,NULL,NULL,NULL,4,'2026-03-05 10:00:00'),('chenzy','$2b$10$OjXQ.6V/xTxVakLiiFBqcOMn/BJ0k9fGKq7T1uQM6YVRrREgEfX7q','陈知远','13800001001','chenzy@stu.edu.cn','/uploads/seed/avatar/04.jpg','student',1,'计算机学院','SELF',1,0,NULL,NULL,'2022010312','软件工程','2022级',NULL,'2026-09-01 08:40:00'),('songyt','$2b$10$OjXQ.6V/xTxVakLiiFBqcOMn/BJ0k9fGKq7T1uQM6YVRrREgEfX7q','宋雨桐','13800001002','songyt@stu.edu.cn','/uploads/seed/avatar/05.jpg','student',2,'商学院','SELF',1,0,NULL,NULL,'2022010455','数据科学与大数据技术','2022级',NULL,'2026-09-01 08:42:00'),('zhaoym','$2b$10$OjXQ.6V/xTxVakLiiFBqcOMn/BJ0k9fGKq7T1uQM6YVRrREgEfX7q','赵一鸣','13800001003','zhaoym@stu.edu.cn','/uploads/seed/avatar/06.jpg','student',1,'计算机学院','SELF',1,0,NULL,NULL,'2022010388','网络工程','2022级',NULL,'2026-09-01 08:44:00'),('zhourh','$2b$10$OjXQ.6V/xTxVakLiiFBqcOMn/BJ0k9fGKq7T1uQM6YVRrREgEfX7q','周若菡','13800001004','zhourh@stu.edu.cn','/uploads/seed/avatar/01.jpg','student',2,'商学院','SELF',1,0,NULL,NULL,'2021010721','市场营销','2021级',NULL,'2026-09-01 08:46:00'),('linjh','$2b$10$OjXQ.6V/xTxVakLiiFBqcOMn/BJ0k9fGKq7T1uQM6YVRrREgEfX7q','林嘉禾','13800001005','linjh@stu.edu.cn','/uploads/seed/avatar/02.jpg','student',1,'计算机学院','SELF',1,0,NULL,NULL,'2022010522','软件工程','2022级',NULL,'2026-09-01 08:48:00'),('wucy','$2b$10$OjXQ.6V/xTxVakLiiFBqcOMn/BJ0k9fGKq7T1uQM6YVRrREgEfX7q','吴承宇','13800001006','wucy@stu.edu.cn','/uploads/seed/avatar/03.jpg','student',1,'计算机学院','SELF',1,0,NULL,NULL,'2021010666','软件工程','2021级',NULL,'2026-08-28 15:10:00'),('hsn','$2b$10$OjXQ.6V/xTxVakLiiFBqcOMn/BJ0k9fGKq7T1uQM6YVRrREgEfX7q','何书宁','13800001007','hsn@stu.edu.cn','/uploads/seed/avatar/04.jpg','student',1,'计算机学院','SELF',1,0,NULL,NULL,'2022010399','人工智能','2022级',NULL,'2026-08-28 15:14:00'),('zyh','$2b$10$OjXQ.6V/xTxVakLiiFBqcOMn/BJ0k9fGKq7T1uQM6YVRrREgEfX7q','郑亦航','13800001008','zyh@stu.edu.cn','/uploads/seed/avatar/05.jpg','student',1,'计算机学院','SELF',1,0,NULL,NULL,'2022010410','软件工程','2022级',NULL,'2026-08-28 15:18:00'),('xuly','$2b$10$OjXQ.6V/xTxVakLiiFBqcOMn/BJ0k9fGKq7T1uQM6YVRrREgEfX7q','徐乐言','13800001009','xuly@stu.edu.cn','/uploads/seed/avatar/06.jpg','student',2,'商学院','SELF',1,0,NULL,NULL,'2022010611','会计学','2022级',NULL,'2026-09-02 09:00:00'),('mengx','$2b$10$OjXQ.6V/xTxVakLiiFBqcOMn/BJ0k9fGKq7T1uQM6YVRrREgEfX7q','孟祥宇','13800001010','mengx@stu.edu.cn','/uploads/seed/avatar/01.jpg','student',1,'计算机学院','SELF',1,0,NULL,NULL,'2022010712','计算机科学与技术','2022级',NULL,'2026-09-02 09:05:00'),('fangyy','$2b$10$OjXQ.6V/xTxVakLiiFBqcOMn/BJ0k9fGKq7T1uQM6YVRrREgEfX7q','方雨欣','13800001011','fangyy@stu.edu.cn','/uploads/seed/avatar/02.jpg','student',2,'商学院','SELF',1,0,NULL,NULL,'2022010813','工商管理','2022级',NULL,'2026-09-02 09:08:00'),('tanjy','$2b$10$OjXQ.6V/xTxVakLiiFBqcOMn/BJ0k9fGKq7T1uQM6YVRrREgEfX7q','谭嘉懿','13800001012','tanjy@stu.edu.cn','/uploads/seed/avatar/03.jpg','student',1,'计算机学院','SELF',1,0,NULL,NULL,'2022010914','软件工程','2022级',NULL,'2026-09-02 09:12:00');

-- 实习批次
INSERT INTO internship_batch (batch_no,semester,departments,start_date,end_date,report_deadline,grace_days,
score_weights,required_materials,min_reports,status,create_time) VALUES
('B2026S1','2026-2027 学年第一学期','计算机学院 / 商学院','2026-09-01','2027-02-28','每周日 23:59',2,'40/40/20',
 '三方协议、人身意外险、结项报告',12,'启用','2026-08-20 10:00:00'),
('B2025S2','2025-2026 学年第二学期','计算机学院','2026-02-24','2026-07-10','每周日 23:59',2,'40/40/20',
 '三方协议、人身意外险、结项报告',12,'已归档','2026-02-10 10:00:00'),
('B2025S1','2025-2026 学年第一学期','全校','2025-09-01','2026-01-15','每周日 23:59',3,'50/30/20',
 '三方协议、人身意外险',12,'已归档','2025-08-18 10:00:00');

-- 企业库
INSERT INTO internship_company (company_no,company_name,industry,address,city,contact,phone,scale,past_students,
avg_score,risk_status,license_image,intro,create_time) VALUES 
('C0001','杭州云枢科技有限公司','信息技术','杭州市余杭区文一西路 969 号','杭州','周建国', '0571-88002001','500-1000 人',17,4.6,'正常','/uploads/seed/company/02.jpg','杭州云枢科技有限公司，主营信息技术相关业务，与学院保持多年实习合作。','2026-03-01 10:00:00'),('C0002','宁波甬信会计师事务所','金融','宁波市鄞州区首南街道泰康中路 558 号','宁波','王倩', '0574-88002002','100-500 人',9,4.2,'正常','/uploads/seed/company/03.jpg','宁波甬信会计师事务所，主营金融相关业务，与学院保持多年实习合作。','2026-03-01 10:00:00'),('C0003','浙江中控技术股份有限公司','制造','杭州市滨江区六和路 309 号','杭州','刘畅', '0571-88002003','1000 人以上',22,4.4,'正常','/uploads/seed/company/04.jpg','浙江中控技术股份有限公司，主营制造相关业务，与学院保持多年实习合作。','2026-03-01 10:00:00'),('C0004','杭州拾光传媒有限公司','文化传媒','杭州市西湖区文三路 90 号','杭州','郑楠', '0571-88002004','50-100 人',5,3.6,'关注','/uploads/seed/company/05.jpg','杭州拾光传媒有限公司，主营文化传媒相关业务，与学院保持多年实习合作。','2026-03-01 10:00:00'),('C0005','深圳恒瑞医疗器械有限公司','医疗','深圳市南山区科技园北区','深圳','黄磊', '0755-88002005','100-500 人',6,4.1,'正常','/uploads/seed/company/06.jpg','深圳恒瑞医疗器械有限公司，主营医疗相关业务，与学院保持多年实习合作。','2026-03-01 10:00:00'),('C0006','杭州同花顺网络信息股份有限公司','金融','杭州市余杭区五常街道同顺街 18 号','杭州','方晓', '0571-88002006','1000 人以上',31,4.5,'正常','/uploads/seed/company/01.jpg','杭州同花顺网络信息股份有限公司，主营金融相关业务，与学院保持多年实习合作。','2026-03-01 10:00:00'),('C0007','上海远景能源有限公司','制造','上海市浦东新区张江高科技园区','上海','孙悦', '021-88002007','1000 人以上',12,4.3,'正常','/uploads/seed/company/02.jpg','上海远景能源有限公司，主营制造相关业务，与学院保持多年实习合作。','2026-03-01 10:00:00'),('C0008','北京字节跳动科技有限公司','信息技术','北京市海淀区知春路甲 48 号','北京','张一凡', '010-88002008','1000 人以上',26,4.7,'正常','/uploads/seed/company/03.jpg','北京字节跳动科技有限公司，主营信息技术相关业务，与学院保持多年实习合作。','2026-03-01 10:00:00'),('C0009','杭州育才教育科技有限公司','教育','杭州市拱墅区莫干山路 972 号','杭州','钱蕾', '0571-88002009','100-500 人',8,3.9,'正常','/uploads/seed/company/04.jpg','杭州育才教育科技有限公司，主营教育相关业务，与学院保持多年实习合作。','2026-03-01 10:00:00'),('C0010','浙江建工集团第三建设有限公司','建筑','杭州市上城区秋涛北路 88 号','杭州','陆斌', '0571-88002010','1000 人以上',14,4.0,'正常','/uploads/seed/company/05.jpg','浙江建工集团第三建设有限公司，主营建筑相关业务，与学院保持多年实习合作。','2026-03-01 10:00:00'),('C0011','杭州星野网络科技工作室','信息技术','杭州市拱墅区祥园路 108 号','杭州','—', '0571-88002011','20 人以下',1,2.4,'风险','/uploads/seed/company/06.jpg','杭州星野网络科技工作室，主营信息技术相关业务，与学院保持多年实习合作。','2026-03-01 10:00:00'),('C0012','苏州精密仪器制造有限公司','制造','苏州市工业园区星湖街 328 号','苏州','毛骏', '0512-88002012','500-1000 人',11,4.1,'正常','/uploads/seed/company/01.jpg','苏州精密仪器制造有限公司，主营制造相关业务，与学院保持多年实习合作。','2026-03-01 10:00:00');

-- 实习档案（20 条，覆盖全部阶段）
INSERT INTO internship_application (internship_no,student_id,student_name,student_no,major,grade,company_id,
company_name,position,industry,city,teacher_id,teacher_name,mentor_id,mentor_name,batch_id,batch_no,start_date,end_date,
source,stage,report_status,agreement_file,insurance_file,accept_file,transition_reason,version,deleted,create_by,
create_time,update_time) VALUES 
('SI20260031',1,'陈知远','2022010312','软件工程','2022级',1,'杭州云枢科技有限公司','后端开发实习','信息技术','杭州',2,'李明华',5,'周建国',1,'B2026S1','2026-11-03','2027-02-28','集中实习','实习备案','待提交','/uploads/seed/work/02.jpg','/uploads/seed/work/04.jpg','/uploads/seed/work/06.jpg',NULL,1,0,1,'2026-10-26 12:48:00','2026-11-01 12:48:00'),
('SI20260030',2,'宋雨桐','2022010455','数据科学与大数据技术','2022级',2,'宁波甬信会计师事务所','数据分析助理','金融','宁波',4,'王慧',6,'王倩',1,'B2026S1','2026-10-26','2027-02-20','集中实习','协议审核','待提交','/uploads/seed/work/03.jpg','/uploads/seed/work/05.jpg','/uploads/seed/work/01.jpg',NULL,1,0,2,'2026-10-16 10:32:00','2026-10-17 10:32:00'),
('SI20260029',3,'赵一鸣','2022010388','网络工程','2022级',3,'浙江中控技术股份有限公司','运维实习','制造','杭州',3,'陈立群',7,'刘畅',1,'B2026S1','2026-09-15','2027-01-31','集中实习','过程周报','待批阅','/uploads/seed/work/04.jpg','/uploads/seed/work/06.jpg','/uploads/seed/work/02.jpg',NULL,1,0,3,'2026-09-08 12:30:00','2026-09-10 12:30:00'),
('SI20260028',4,'周若菡','2021010721','市场营销','2021级',7,'上海远景能源有限公司','产品运营实习','制造','上海',4,'王慧',NULL,'孙悦',1,'B2026S1','2026-09-08','2027-01-20','自主实习','过程周报','已批阅','/uploads/seed/work/05.jpg','/uploads/seed/work/01.jpg','/uploads/seed/work/03.jpg',NULL,1,0,4,'2026-09-02 10:58:00','2026-09-07 10:58:00'),
('SI20260027',5,'林嘉禾','2022010522','软件工程','2022级',4,'杭州拾光传媒有限公司','前端开发实习','文化传媒','杭州',2,'李明华',8,'郑楠',1,'B2026S1','2026-08-25','2026-12-31','自主实习','企业评价','已批阅','/uploads/seed/work/06.jpg','/uploads/seed/work/02.jpg','/uploads/seed/work/04.jpg',NULL,1,0,5,'2026-08-21 13:14:00','2026-08-22 13:14:00'),
('SI20260026',6,'吴承宇','2021010666','软件工程','2021级',5,'深圳恒瑞医疗器械有限公司','测试实习','医疗','深圳',4,'王慧',NULL,'黄磊',1,'B2026S1','2025-09-10','2026-01-10','集中实习','学校归档','已批阅','/uploads/seed/work/01.jpg','/uploads/seed/work/03.jpg','/uploads/seed/work/05.jpg',NULL,1,0,6,'2025-09-03 16:11:00','2025-09-07 16:11:00'),
('SI20260025',7,'何书宁','2022010399','人工智能','2022级',8,'北京字节跳动科技有限公司','算法实习','信息技术','北京',4,'王慧',NULL,'张一凡',1,'B2026S1','2026-07-01','2026-12-20','自主实习','已中止','已批阅','/uploads/seed/work/02.jpg','/uploads/seed/work/04.jpg','/uploads/seed/work/06.jpg','个人健康原因，经校内导师与管理员审批后中止',1,0,7,'2026-06-22 12:06:00','2026-06-23 12:06:00'),
('SI20260024',8,'郑亦航','2022010410','软件工程','2022级',6,'杭州同花顺网络信息股份有限公司','Java 开发实习','金融','杭州',2,'李明华',NULL,'方晓',1,'B2026S1','2026-09-01','2027-01-15','自主实习','过程周报','已退修','/uploads/seed/work/03.jpg','/uploads/seed/work/05.jpg','/uploads/seed/work/01.jpg',NULL,1,0,8,'2026-08-22 11:40:00','2026-08-26 11:40:00'),
('SI20260023',9,'徐乐言','2022010611','会计学','2022级',2,'宁波甬信会计师事务所','审计助理','金融','宁波',4,'王慧',6,'王倩',1,'B2026S1','2026-09-10','2027-01-10','集中实习','过程周报','已批阅','/uploads/seed/work/04.jpg','/uploads/seed/work/06.jpg','/uploads/seed/work/02.jpg',NULL,1,0,9,'2026-08-30 17:21:00','2026-09-03 17:21:00'),
('SI20260022',10,'孟祥宇','2022010712','计算机科学与技术','2022级',3,'浙江中控技术股份有限公司','嵌入式开发实习','制造','杭州',3,'陈立群',7,'刘畅',1,'B2026S1','2026-09-12','2027-01-20','集中实习','过程周报','待批阅','/uploads/seed/work/05.jpg','/uploads/seed/work/01.jpg','/uploads/seed/work/03.jpg',NULL,1,0,10,'2026-09-03 15:23:00','2026-09-09 15:23:00'),
('SI20260021',11,'方雨欣','2022010813','工商管理','2022级',9,'杭州育才教育科技有限公司','教务运营实习','教育','杭州',4,'王慧',NULL,'钱蕾',1,'B2026S1','2026-09-05','2027-01-05','自主实习','过程周报','已批阅','/uploads/seed/work/06.jpg','/uploads/seed/work/02.jpg','/uploads/seed/work/04.jpg',NULL,1,0,11,'2026-08-26 14:07:00','2026-08-31 14:07:00'),
('SI20260020',12,'谭嘉懿','2022010914','软件工程','2022级',1,'杭州云枢科技有限公司','前端开发实习','信息技术','杭州',2,'李明华',5,'周建国',1,'B2026S1','2026-09-01','2027-01-31','集中实习','阶段检查','已批阅','/uploads/seed/work/01.jpg','/uploads/seed/work/03.jpg','/uploads/seed/work/05.jpg',NULL,1,0,12,'2026-08-24 11:02:00','2026-08-28 11:02:00'),
('SI20260019',13,'陈知远','2022010312','软件工程','2022级',3,'浙江中控技术股份有限公司','测试开发实习','制造','杭州',3,'陈立群',7,'刘畅',1,'B2026S1','2026-04-01','2026-08-31','集中实习','已中止','逾期未交','/uploads/seed/work/02.jpg','/uploads/seed/work/04.jpg','/uploads/seed/work/06.jpg','个人健康原因，经校内导师与管理员审批后中止',1,0,13,'2026-03-27 13:24:00','2026-03-28 13:24:00'),
('SI20260018',14,'宋雨桐','2022010455','数据科学与大数据技术','2022级',6,'杭州同花顺网络信息股份有限公司','数据分析实习','金融','杭州',4,'王慧',NULL,'方晓',1,'B2026S1','2025-09-05','2026-01-08','自主实习','学校归档','已批阅','/uploads/seed/work/03.jpg','/uploads/seed/work/05.jpg','/uploads/seed/work/01.jpg',NULL,1,0,14,'2025-08-29 12:08:00','2025-08-30 12:08:00'),
('SI20260017',15,'周若菡','2021010721','市场营销','2021级',11,'杭州星野网络科技工作室','市场营销实习','信息技术','杭州',4,'王慧',NULL,'毛骏',1,'B2026S1','2026-08-20','2026-12-25','自主实习','企业评价','已批阅','/uploads/seed/work/04.jpg','/uploads/seed/work/06.jpg','/uploads/seed/work/02.jpg',NULL,1,0,15,'2026-08-08 12:05:00','2026-08-10 12:05:00'),
('SI20260016',16,'林嘉禾','2022010522','软件工程','2022级',4,'杭州拾光传媒有限公司','运营实习','文化传媒','杭州',2,'李明华',8,'郑楠',1,'B2026S1','2026-11-10','2027-03-10','自主实习','协议审核','待提交','/uploads/seed/work/05.jpg','/uploads/seed/work/01.jpg','/uploads/seed/work/03.jpg',NULL,1,0,16,'2026-10-29 12:55:00','2026-10-30 12:55:00'),
('SI20260015',17,'赵一鸣','2022010388','网络工程','2022级',10,'浙江建工集团第三建设有限公司','施工管理实习','建筑','杭州',3,'陈立群',NULL,'陆斌',1,'B2026S1','2026-11-15','2027-04-15','集中实习','实习备案','待提交','/uploads/seed/work/06.jpg','/uploads/seed/work/02.jpg','/uploads/seed/work/04.jpg',NULL,1,0,17,'2026-11-11 12:54:00','2026-11-17 12:54:00'),
('SI20260014',18,'吴承宇','2021010666','软件工程','2021级',12,'苏州精密仪器制造有限公司','工艺实习','制造','苏州',3,'陈立群',NULL,'毛骏',1,'B2026S1','2026-09-20','2027-02-10','集中实习','过程周报','已批阅','/uploads/seed/work/01.jpg','/uploads/seed/work/03.jpg','/uploads/seed/work/05.jpg',NULL,1,0,18,'2026-09-11 15:33:00','2026-09-16 15:33:00'),
('SI20260013',19,'孟祥宇','2022010712','计算机科学与技术','2022级',1,'杭州云枢科技有限公司','后端开发实习','信息技术','杭州',2,'李明华',5,'周建国',1,'B2026S1','2026-09-02','2027-02-01','集中实习','阶段检查','已批阅','/uploads/seed/work/02.jpg','/uploads/seed/work/04.jpg','/uploads/seed/work/06.jpg',NULL,1,0,19,'2026-08-26 10:21:00','2026-08-31 10:21:00'),
('SI20260012',20,'徐乐言','2022010611','会计学','2022级',10,'浙江建工集团第三建设有限公司','财务实习','建筑','杭州',4,'王慧',NULL,'陆斌',1,'B2026S1','2026-11-20','2027-04-20','自主实习','实习备案','待提交','/uploads/seed/work/03.jpg','/uploads/seed/work/05.jpg','/uploads/seed/work/01.jpg',NULL,1,0,20,'2026-11-08 12:13:00','2026-11-12 12:13:00');

-- 阶段里程碑（每个档案 4 项）
INSERT INTO internship_milestone (application_id,seq_no,title,plan_week,status,complete_date,delayed_days,create_time) VALUES 
(1,1,'入职与安全培训',3,'未开始',NULL,0,'2026-11-03 00:00:00'),
(1,2,'熟悉业务与代码结构',6,'未开始',NULL,0,'2026-11-03 00:00:00'),
(1,3,'独立承担核心任务',9,'未开始',NULL,0,'2026-11-03 00:00:00'),
(1,4,'成果汇报与复盘',12,'未开始',NULL,0,'2026-11-03 00:00:00'),
(2,1,'入职与安全培训',3,'未开始',NULL,0,'2026-10-26 00:00:00'),
(2,2,'熟悉业务与代码结构',6,'未开始',NULL,0,'2026-10-26 00:00:00'),
(2,3,'独立承担核心任务',9,'未开始',NULL,0,'2026-10-26 00:00:00'),
(2,4,'成果汇报与复盘',12,'未开始',NULL,0,'2026-10-26 00:00:00'),
(3,1,'入职与安全培训',3,'已完成','2026-09-29',0,'2026-09-15 00:00:00'),
(3,2,'熟悉业务与代码结构',6,'已完成','2026-10-20',0,'2026-09-15 00:00:00'),
(3,3,'独立承担核心任务',9,'进行中',NULL,0,'2026-09-15 00:00:00'),
(3,4,'成果汇报与复盘',12,'未开始',NULL,0,'2026-09-15 00:00:00'),
(4,1,'入职与安全培训',3,'已完成','2026-09-22',0,'2026-09-08 00:00:00'),
(4,2,'熟悉业务与代码结构',6,'已完成','2026-10-13',0,'2026-09-08 00:00:00'),
(4,3,'独立承担核心任务',9,'进行中',NULL,0,'2026-09-08 00:00:00'),
(4,4,'成果汇报与复盘',12,'未开始',NULL,0,'2026-09-08 00:00:00'),
(5,1,'入职与安全培训',3,'已完成','2026-09-08',0,'2026-08-25 00:00:00'),
(5,2,'熟悉业务与代码结构',6,'已完成','2026-09-29',0,'2026-08-25 00:00:00'),
(5,3,'独立承担核心任务',9,'进行中',NULL,0,'2026-08-25 00:00:00'),
(5,4,'成果汇报与复盘',12,'未开始',NULL,0,'2026-08-25 00:00:00'),
(6,1,'入职与安全培训',3,'已完成','2025-10-01',0,'2025-09-10 00:00:00'),
(6,2,'熟悉业务与代码结构',6,'已完成','2025-10-22',0,'2025-09-10 00:00:00'),
(6,3,'独立承担核心任务',9,'已完成','2025-11-12',0,'2025-09-10 00:00:00'),
(6,4,'成果汇报与复盘',12,'已完成','2025-12-03',0,'2025-09-10 00:00:00'),
(7,1,'入职与安全培训',3,'已完成','2026-07-15',0,'2026-07-01 00:00:00'),
(7,2,'熟悉业务与代码结构',6,'已完成','2026-07-29',0,'2026-07-01 00:00:00'),
(7,3,'独立承担核心任务',9,'未开始',NULL,0,'2026-07-01 00:00:00'),
(7,4,'成果汇报与复盘',12,'未开始',NULL,0,'2026-07-01 00:00:00'),
(8,1,'入职与安全培训',3,'已完成','2026-09-15',0,'2026-09-01 00:00:00'),
(8,2,'熟悉业务与代码结构',6,'已完成','2026-10-06',0,'2026-09-01 00:00:00'),
(8,3,'独立承担核心任务',9,'进行中',NULL,0,'2026-09-01 00:00:00'),
(8,4,'成果汇报与复盘',12,'未开始',NULL,0,'2026-09-01 00:00:00'),
(9,1,'入职与安全培训',3,'已完成','2026-09-24',0,'2026-09-10 00:00:00'),
(9,2,'熟悉业务与代码结构',6,'已完成','2026-10-15',0,'2026-09-10 00:00:00'),
(9,3,'独立承担核心任务',9,'进行中',NULL,0,'2026-09-10 00:00:00'),
(9,4,'成果汇报与复盘',12,'未开始',NULL,0,'2026-09-10 00:00:00'),
(10,1,'入职与安全培训',3,'已完成','2026-09-26',0,'2026-09-12 00:00:00'),
(10,2,'熟悉业务与代码结构',6,'已完成','2026-10-17',0,'2026-09-12 00:00:00'),
(10,3,'独立承担核心任务',9,'进行中',NULL,0,'2026-09-12 00:00:00'),
(10,4,'成果汇报与复盘',12,'未开始',NULL,0,'2026-09-12 00:00:00'),
(11,1,'入职与安全培训',3,'已完成','2026-09-19',0,'2026-09-05 00:00:00'),
(11,2,'熟悉业务与代码结构',6,'已完成','2026-10-10',0,'2026-09-05 00:00:00'),
(11,3,'独立承担核心任务',9,'进行中',NULL,0,'2026-09-05 00:00:00'),
(11,4,'成果汇报与复盘',12,'未开始',NULL,0,'2026-09-05 00:00:00'),
(12,1,'入职与安全培训',3,'已完成','2026-09-15',0,'2026-09-01 00:00:00'),
(12,2,'熟悉业务与代码结构',6,'已完成','2026-10-06',0,'2026-09-01 00:00:00'),
(12,3,'独立承担核心任务',9,'进行中',NULL,0,'2026-09-01 00:00:00'),
(12,4,'成果汇报与复盘',12,'未开始',NULL,0,'2026-09-01 00:00:00'),
(13,1,'入职与安全培训',3,'已完成','2026-04-15',0,'2026-04-01 00:00:00'),
(13,2,'熟悉业务与代码结构',6,'已完成','2026-04-29',0,'2026-04-01 00:00:00'),
(13,3,'独立承担核心任务',9,'未开始',NULL,0,'2026-04-01 00:00:00'),
(13,4,'成果汇报与复盘',12,'未开始',NULL,0,'2026-04-01 00:00:00'),
(14,1,'入职与安全培训',3,'已完成','2025-09-26',0,'2025-09-05 00:00:00'),
(14,2,'熟悉业务与代码结构',6,'已完成','2025-10-17',0,'2025-09-05 00:00:00'),
(14,3,'独立承担核心任务',9,'已完成','2025-11-07',0,'2025-09-05 00:00:00'),
(14,4,'成果汇报与复盘',12,'已完成','2025-11-28',0,'2025-09-05 00:00:00'),
(15,1,'入职与安全培训',3,'已完成','2026-09-03',0,'2026-08-20 00:00:00'),
(15,2,'熟悉业务与代码结构',6,'已完成','2026-09-24',0,'2026-08-20 00:00:00'),
(15,3,'独立承担核心任务',9,'进行中',NULL,0,'2026-08-20 00:00:00'),
(15,4,'成果汇报与复盘',12,'未开始',NULL,0,'2026-08-20 00:00:00'),
(16,1,'入职与安全培训',3,'未开始',NULL,0,'2026-11-10 00:00:00'),
(16,2,'熟悉业务与代码结构',6,'未开始',NULL,0,'2026-11-10 00:00:00'),
(16,3,'独立承担核心任务',9,'未开始',NULL,0,'2026-11-10 00:00:00'),
(16,4,'成果汇报与复盘',12,'未开始',NULL,0,'2026-11-10 00:00:00'),
(17,1,'入职与安全培训',3,'未开始',NULL,0,'2026-11-15 00:00:00'),
(17,2,'熟悉业务与代码结构',6,'未开始',NULL,0,'2026-11-15 00:00:00'),
(17,3,'独立承担核心任务',9,'未开始',NULL,0,'2026-11-15 00:00:00'),
(17,4,'成果汇报与复盘',12,'未开始',NULL,0,'2026-11-15 00:00:00'),
(18,1,'入职与安全培训',3,'已完成','2026-10-04',0,'2026-09-20 00:00:00'),
(18,2,'熟悉业务与代码结构',6,'已完成','2026-10-25',0,'2026-09-20 00:00:00'),
(18,3,'独立承担核心任务',9,'进行中',NULL,0,'2026-09-20 00:00:00'),
(18,4,'成果汇报与复盘',12,'未开始',NULL,0,'2026-09-20 00:00:00'),
(19,1,'入职与安全培训',3,'已完成','2026-09-16',0,'2026-09-02 00:00:00'),
(19,2,'熟悉业务与代码结构',6,'已完成','2026-10-07',0,'2026-09-02 00:00:00'),
(19,3,'独立承担核心任务',9,'进行中',NULL,0,'2026-09-02 00:00:00'),
(19,4,'成果汇报与复盘',12,'未开始',NULL,0,'2026-09-02 00:00:00'),
(20,1,'入职与安全培训',3,'未开始',NULL,0,'2026-11-20 00:00:00'),
(20,2,'熟悉业务与代码结构',6,'未开始',NULL,0,'2026-11-20 00:00:00'),
(20,3,'独立承担核心任务',9,'未开始',NULL,0,'2026-11-20 00:00:00'),
(20,4,'成果汇报与复盘',12,'未开始',NULL,0,'2026-11-20 00:00:00');

-- 周报（40+ 条，覆盖各状态与跨月份提交时间）
INSERT INTO weekly_report (report_no,application_id,internship_no,student_id,student_name,week_no,week_start,
week_end,task_content,harvest,problem,next_plan,attachment_image,attachment_file,submit_time,deadline,status,
review_score,review_comment,reviewer_id,reviewer_name,review_time,create_time) VALUES 
('WR20260921001',3,'SI20260029',3,'赵一鸣',1,'2026-09-15','2026-09-21','机房巡检 12 次，处理磁盘告警 2 起','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/02.jpg','/uploads/seed/work/05.jpg','2026-09-21 20:40:00','2026-09-22 23:59:00','已批阅',84,'任务描述具体，问题记录清楚，下周计划可执行。',3,'陈立群','2026-09-24 20:40:00','2026-09-15 00:00:00'),
('WR20260928002',3,'SI20260029',3,'赵一鸣',2,'2026-09-22','2026-09-28','重构前端公共表格组件，减少重复代码约 400 行','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/03.jpg','/uploads/seed/work/06.jpg','2026-09-28 21:37:00','2026-09-29 23:59:00','已批阅',80,'任务描述具体，问题记录清楚，下周计划可执行。',3,'陈立群','2026-09-30 21:37:00','2026-09-22 00:00:00'),
('WR20261005003',3,'SI20260029',3,'赵一鸣',3,'2026-09-29','2026-10-05','完成竞品调研报告，梳理 6 家同类产品功能矩阵','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/04.jpg','/uploads/seed/work/01.jpg','2026-10-05 22:09:00','2026-10-06 23:59:00','已批阅',80,'任务描述具体，问题记录清楚，下周计划可执行。',3,'陈立群','2026-10-07 22:09:00','2026-09-29 00:00:00'),
('WR20261012004',3,'SI20260029',3,'赵一鸣',4,'2026-10-06','2026-10-12','完成订单查询接口分页与排序，补充单元测试 12 条','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/05.jpg','/uploads/seed/work/02.jpg','2026-10-12 17:58:00','2026-10-13 23:59:00','已批阅',80,'任务描述具体，问题记录清楚，下周计划可执行。',3,'陈立群','2026-10-15 17:58:00','2026-10-06 00:00:00'),
('WR20261019005',3,'SI20260029',3,'赵一鸣',5,'2026-10-13','2026-10-19','参与需求评审，整理接口文档初稿','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/06.jpg','/uploads/seed/work/03.jpg','2026-10-19 17:00:00','2026-10-20 23:59:00','已批阅',82,'任务描述具体，问题记录清楚，下周计划可执行。',3,'陈立群','2026-10-21 17:00:00','2026-10-13 00:00:00'),
('WR20261026006',3,'SI20260029',3,'赵一鸣',6,'2026-10-20','2026-10-26','定位线上慢查询并补充索引，平均响应从 820ms 降到 210ms','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/01.jpg','/uploads/seed/work/04.jpg','2026-10-26 18:23:00','2026-10-27 23:59:00','已批阅',85,'任务描述具体，问题记录清楚，下周计划可执行。',3,'陈立群','2026-10-29 18:23:00','2026-10-20 00:00:00'),
('WR20261102007',3,'SI20260029',3,'赵一鸣',7,'2026-10-27','2026-11-02','完成客户流水抽样复核，输出差异说明','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/02.jpg','/uploads/seed/work/05.jpg','2026-11-02 21:22:00','2026-11-03 23:59:00','已批阅',86,'任务描述具体，问题记录清楚，下周计划可执行。',3,'陈立群','2026-11-03 21:22:00','2026-10-27 00:00:00'),
('WR20261109008',3,'SI20260029',3,'赵一鸣',8,'2026-11-03','2026-11-09','机房巡检 12 次，处理磁盘告警 2 起','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/03.jpg','/uploads/seed/work/06.jpg','2026-11-09 19:14:00','2026-11-10 23:59:00','待批阅',NULL,NULL,NULL,NULL,NULL,'2026-11-03 00:00:00'),
('WR20260914009',4,'SI20260028',4,'周若菡',1,'2026-09-08','2026-09-14','重构前端公共表格组件，减少重复代码约 400 行','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/04.jpg','/uploads/seed/work/01.jpg','2026-09-14 22:35:00','2026-09-15 23:59:00','已批阅',88,'任务描述具体，问题记录清楚，下周计划可执行。',4,'王慧','2026-09-17 22:35:00','2026-09-08 00:00:00'),
('WR20260921010',4,'SI20260028',4,'周若菡',2,'2026-09-15','2026-09-21','完成竞品调研报告，梳理 6 家同类产品功能矩阵','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/05.jpg','/uploads/seed/work/02.jpg','2026-09-21 19:52:00','2026-09-22 23:59:00','已批阅',84,'任务描述具体，问题记录清楚，下周计划可执行。',4,'王慧','2026-09-23 19:52:00','2026-09-15 00:00:00'),
('WR20260928011',4,'SI20260028',4,'周若菡',3,'2026-09-22','2026-09-28','完成订单查询接口分页与排序，补充单元测试 12 条','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/06.jpg','/uploads/seed/work/03.jpg','2026-09-28 22:29:00','2026-09-29 23:59:00','已批阅',80,'任务描述具体，问题记录清楚，下周计划可执行。',4,'王慧','2026-09-29 22:29:00','2026-09-22 00:00:00'),
('WR20261005012',4,'SI20260028',4,'周若菡',4,'2026-09-29','2026-10-05','参与需求评审，整理接口文档初稿','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/01.jpg','/uploads/seed/work/04.jpg','2026-10-05 17:18:00','2026-10-06 23:59:00','已批阅',92,'任务描述具体，问题记录清楚，下周计划可执行。',4,'王慧','2026-10-08 17:18:00','2026-09-29 00:00:00'),
('WR20261012013',4,'SI20260028',4,'周若菡',5,'2026-10-06','2026-10-12','定位线上慢查询并补充索引，平均响应从 820ms 降到 210ms','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/02.jpg','/uploads/seed/work/05.jpg','2026-10-12 21:17:00','2026-10-13 23:59:00','已批阅',82,'任务描述具体，问题记录清楚，下周计划可执行。',4,'王慧','2026-10-13 21:17:00','2026-10-06 00:00:00'),
('WR20261019014',4,'SI20260028',4,'周若菡',6,'2026-10-13','2026-10-19','完成客户流水抽样复核，输出差异说明','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/03.jpg','/uploads/seed/work/06.jpg','2026-10-19 21:14:00','2026-10-20 23:59:00','已批阅',86,'任务描述具体，问题记录清楚，下周计划可执行。',4,'王慧','2026-10-20 21:14:00','2026-10-13 00:00:00'),
('WR20261026015',4,'SI20260028',4,'周若菡',7,'2026-10-20','2026-10-26','机房巡检 12 次，处理磁盘告警 2 起','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/04.jpg','/uploads/seed/work/01.jpg','2026-10-26 21:16:00','2026-10-27 23:59:00','已批阅',90,'任务描述具体，问题记录清楚，下周计划可执行。',4,'王慧','2026-10-28 21:16:00','2026-10-20 00:00:00'),
('WR20261102016',4,'SI20260028',4,'周若菡',8,'2026-10-27','2026-11-02','重构前端公共表格组件，减少重复代码约 400 行','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/05.jpg','/uploads/seed/work/02.jpg','2026-11-02 20:13:00','2026-11-03 23:59:00','待批阅',NULL,NULL,NULL,NULL,NULL,'2026-10-27 00:00:00'),
('WR20260831017',5,'SI20260027',5,'林嘉禾',1,'2026-08-25','2026-08-31','完成竞品调研报告，梳理 6 家同类产品功能矩阵','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/06.jpg','/uploads/seed/work/03.jpg','2026-08-31 17:54:00','2026-09-01 23:59:00','已批阅',86,'任务描述具体，问题记录清楚，下周计划可执行。',2,'李明华','2026-09-03 17:54:00','2026-08-25 00:00:00'),
('WR20260907018',5,'SI20260027',5,'林嘉禾',2,'2026-09-01','2026-09-07','完成订单查询接口分页与排序，补充单元测试 12 条','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/01.jpg','/uploads/seed/work/04.jpg','2026-09-07 21:13:00','2026-09-08 23:59:00','已批阅',90,'任务描述具体，问题记录清楚，下周计划可执行。',2,'李明华','2026-09-08 21:13:00','2026-09-01 00:00:00'),
('WR20260914019',5,'SI20260027',5,'林嘉禾',3,'2026-09-08','2026-09-14','参与需求评审，整理接口文档初稿','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/02.jpg','/uploads/seed/work/05.jpg','2026-09-14 17:52:00','2026-09-15 23:59:00','已批阅',88,'任务描述具体，问题记录清楚，下周计划可执行。',2,'李明华','2026-09-16 17:52:00','2026-09-08 00:00:00'),
('WR20260921020',5,'SI20260027',5,'林嘉禾',4,'2026-09-15','2026-09-21','定位线上慢查询并补充索引，平均响应从 820ms 降到 210ms','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/03.jpg','/uploads/seed/work/06.jpg','2026-09-21 21:17:00','2026-09-22 23:59:00','已批阅',82,'任务描述具体，问题记录清楚，下周计划可执行。',2,'李明华','2026-09-23 21:17:00','2026-09-15 00:00:00'),
('WR20260928021',5,'SI20260027',5,'林嘉禾',5,'2026-09-22','2026-09-28','完成客户流水抽样复核，输出差异说明','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/04.jpg','/uploads/seed/work/01.jpg','2026-09-28 22:45:00','2026-09-29 23:59:00','已批阅',90,'任务描述具体，问题记录清楚，下周计划可执行。',2,'李明华','2026-09-30 22:45:00','2026-09-22 00:00:00'),
('WR20261005022',5,'SI20260027',5,'林嘉禾',6,'2026-09-29','2026-10-05','机房巡检 12 次，处理磁盘告警 2 起','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/05.jpg','/uploads/seed/work/02.jpg','2026-10-05 18:22:00','2026-10-06 23:59:00','已批阅',90,'任务描述具体，问题记录清楚，下周计划可执行。',2,'李明华','2026-10-06 18:22:00','2026-09-29 00:00:00'),
('WR20261012023',5,'SI20260027',5,'林嘉禾',7,'2026-10-06','2026-10-12','重构前端公共表格组件，减少重复代码约 400 行','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/06.jpg','/uploads/seed/work/03.jpg','2026-10-12 17:14:00','2026-10-13 23:59:00','已批阅',82,'任务描述具体，问题记录清楚，下周计划可执行。',2,'李明华','2026-10-13 17:14:00','2026-10-06 00:00:00'),
('WR20261019024',5,'SI20260027',5,'林嘉禾',8,'2026-10-13','2026-10-19','完成竞品调研报告，梳理 6 家同类产品功能矩阵','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/01.jpg','/uploads/seed/work/04.jpg','2026-10-19 19:15:00','2026-10-20 23:59:00','待批阅',NULL,NULL,NULL,NULL,NULL,'2026-10-13 00:00:00'),
('WR20250916025',6,'SI20260026',6,'吴承宇',1,'2025-09-10','2025-09-16','完成订单查询接口分页与排序，补充单元测试 12 条','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/02.jpg','/uploads/seed/work/05.jpg','2025-09-16 17:16:00','2025-09-17 23:59:00','已批阅',88,'任务描述具体，问题记录清楚，下周计划可执行。',4,'王慧','2025-09-17 17:16:00','2025-09-10 00:00:00'),
('WR20250923026',6,'SI20260026',6,'吴承宇',2,'2025-09-17','2025-09-23','参与需求评审，整理接口文档初稿','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/03.jpg','/uploads/seed/work/06.jpg','2025-09-23 19:32:00','2025-09-24 23:59:00','已批阅',88,'任务描述具体，问题记录清楚，下周计划可执行。',4,'王慧','2025-09-26 19:32:00','2025-09-17 00:00:00'),
('WR20250930027',6,'SI20260026',6,'吴承宇',3,'2025-09-24','2025-09-30','定位线上慢查询并补充索引，平均响应从 820ms 降到 210ms','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/04.jpg','/uploads/seed/work/01.jpg','2025-09-30 18:19:00','2025-10-01 23:59:00','已批阅',82,'任务描述具体，问题记录清楚，下周计划可执行。',4,'王慧','2025-10-01 18:19:00','2025-09-24 00:00:00'),
('WR20251007028',6,'SI20260026',6,'吴承宇',4,'2025-10-01','2025-10-07','完成客户流水抽样复核，输出差异说明','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/05.jpg','/uploads/seed/work/02.jpg','2025-10-07 18:02:00','2025-10-08 23:59:00','已批阅',85,'任务描述具体，问题记录清楚，下周计划可执行。',4,'王慧','2025-10-10 18:02:00','2025-10-01 00:00:00'),
('WR20251014029',6,'SI20260026',6,'吴承宇',5,'2025-10-08','2025-10-14','机房巡检 12 次，处理磁盘告警 2 起','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/06.jpg','/uploads/seed/work/03.jpg','2025-10-14 18:46:00','2025-10-15 23:59:00','已批阅',80,'任务描述具体，问题记录清楚，下周计划可执行。',4,'王慧','2025-10-17 18:46:00','2025-10-08 00:00:00'),
('WR20251021030',6,'SI20260026',6,'吴承宇',6,'2025-10-15','2025-10-21','重构前端公共表格组件，减少重复代码约 400 行','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/01.jpg','/uploads/seed/work/04.jpg','2025-10-21 20:35:00','2025-10-22 23:59:00','已批阅',80,'任务描述具体，问题记录清楚，下周计划可执行。',4,'王慧','2025-10-24 20:35:00','2025-10-15 00:00:00'),
('WR20251028031',6,'SI20260026',6,'吴承宇',7,'2025-10-22','2025-10-28','完成竞品调研报告，梳理 6 家同类产品功能矩阵','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/02.jpg','/uploads/seed/work/05.jpg','2025-10-28 22:16:00','2025-10-29 23:59:00','已批阅',86,'任务描述具体，问题记录清楚，下周计划可执行。',4,'王慧','2025-10-31 22:16:00','2025-10-22 00:00:00'),
('WR20251104032',6,'SI20260026',6,'吴承宇',8,'2025-10-29','2025-11-04','完成订单查询接口分页与排序，补充单元测试 12 条','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/03.jpg','/uploads/seed/work/06.jpg','2025-11-04 18:34:00','2025-11-05 23:59:00','已批阅',85,'任务描述具体，问题记录清楚，下周计划可执行。',4,'王慧','2025-11-05 18:34:00','2025-10-29 00:00:00'),
('WR20260707033',7,'SI20260025',7,'何书宁',1,'2026-07-01','2026-07-07','参与需求评审，整理接口文档初稿','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/04.jpg','/uploads/seed/work/01.jpg','2026-07-07 21:36:00','2026-07-08 23:59:00','已批阅',86,'任务描述具体，问题记录清楚，下周计划可执行。',4,'王慧','2026-07-09 21:36:00','2026-07-01 00:00:00'),
('WR20260714034',7,'SI20260025',7,'何书宁',2,'2026-07-08','2026-07-14','定位线上慢查询并补充索引，平均响应从 820ms 降到 210ms','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/05.jpg','/uploads/seed/work/02.jpg','2026-07-14 19:31:00','2026-07-15 23:59:00','已批阅',90,'任务描述具体，问题记录清楚，下周计划可执行。',4,'王慧','2026-07-17 19:31:00','2026-07-08 00:00:00'),
('WR20260721035',7,'SI20260025',7,'何书宁',3,'2026-07-15','2026-07-21','完成客户流水抽样复核，输出差异说明','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/06.jpg','/uploads/seed/work/03.jpg','2026-07-21 18:17:00','2026-07-22 23:59:00','已批阅',92,'任务描述具体，问题记录清楚，下周计划可执行。',4,'王慧','2026-07-23 18:17:00','2026-07-15 00:00:00'),
('WR20260728036',7,'SI20260025',7,'何书宁',4,'2026-07-22','2026-07-28','机房巡检 12 次，处理磁盘告警 2 起','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/01.jpg','/uploads/seed/work/04.jpg','2026-07-28 18:24:00','2026-07-29 23:59:00','已批阅',90,'任务描述具体，问题记录清楚，下周计划可执行。',4,'王慧','2026-07-31 18:24:00','2026-07-22 00:00:00'),
('WR20260804037',7,'SI20260025',7,'何书宁',5,'2026-07-29','2026-08-04','重构前端公共表格组件，减少重复代码约 400 行','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/02.jpg','/uploads/seed/work/05.jpg','2026-08-04 19:35:00','2026-08-05 23:59:00','已批阅',84,'任务描述具体，问题记录清楚，下周计划可执行。',4,'王慧','2026-08-06 19:35:00','2026-07-29 00:00:00'),
('WR20260907038',8,'SI20260024',8,'郑亦航',1,'2026-09-01','2026-09-07','定位线上慢查询并补充索引，平均响应从 820ms 降到 210ms','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/03.jpg','/uploads/seed/work/06.jpg','2026-09-07 22:18:00','2026-09-08 23:59:00','已批阅',92,'任务描述具体，问题记录清楚，下周计划可执行。',2,'李明华','2026-09-10 22:18:00','2026-09-01 00:00:00'),
('WR20260914039',8,'SI20260024',8,'郑亦航',2,'2026-09-08','2026-09-14','完成客户流水抽样复核，输出差异说明','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/04.jpg','/uploads/seed/work/01.jpg','2026-09-14 19:58:00','2026-09-15 23:59:00','已批阅',82,'任务描述具体，问题记录清楚，下周计划可执行。',2,'李明华','2026-09-16 19:58:00','2026-09-08 00:00:00'),
('WR20260921040',8,'SI20260024',8,'郑亦航',3,'2026-09-15','2026-09-21','机房巡检 12 次，处理磁盘告警 2 起','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/05.jpg','/uploads/seed/work/02.jpg','2026-09-21 21:18:00','2026-09-22 23:59:00','已批阅',85,'任务描述具体，问题记录清楚，下周计划可执行。',2,'李明华','2026-09-23 21:18:00','2026-09-15 00:00:00'),
('WR20260928041',8,'SI20260024',8,'郑亦航',4,'2026-09-22','2026-09-28','重构前端公共表格组件，减少重复代码约 400 行','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/06.jpg','/uploads/seed/work/03.jpg','2026-09-28 17:01:00','2026-09-29 23:59:00','已批阅',84,'任务描述具体，问题记录清楚，下周计划可执行。',2,'李明华','2026-10-01 17:01:00','2026-09-22 00:00:00'),
('WR20261005042',8,'SI20260024',8,'郑亦航',5,'2026-09-29','2026-10-05','完成竞品调研报告，梳理 6 家同类产品功能矩阵','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/01.jpg','/uploads/seed/work/04.jpg','2026-10-05 18:22:00','2026-10-06 23:59:00','已批阅',85,'任务描述具体，问题记录清楚，下周计划可执行。',2,'李明华','2026-10-08 18:22:00','2026-09-29 00:00:00'),
('WR20261012043',8,'SI20260024',8,'郑亦航',6,'2026-10-06','2026-10-12','完成订单查询接口分页与排序，补充单元测试 12 条','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/02.jpg','/uploads/seed/work/05.jpg','2026-10-12 17:09:00','2026-10-13 23:59:00','已批阅',92,'任务描述具体，问题记录清楚，下周计划可执行。',2,'李明华','2026-10-14 17:09:00','2026-10-06 00:00:00'),
('WR20261019044',8,'SI20260024',8,'郑亦航',7,'2026-10-13','2026-10-19','参与需求评审，整理接口文档初稿','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/03.jpg','/uploads/seed/work/06.jpg','2026-10-19 22:18:00','2026-10-20 23:59:00','已批阅',88,'任务描述具体，问题记录清楚，下周计划可执行。',2,'李明华','2026-10-22 22:18:00','2026-10-13 00:00:00'),
('WR20261026045',8,'SI20260024',8,'郑亦航',8,'2026-10-20','2026-10-26','定位线上慢查询并补充索引，平均响应从 820ms 降到 210ms','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/04.jpg','/uploads/seed/work/01.jpg','2026-10-26 19:22:00','2026-10-27 23:59:00','已退修',NULL,'附件缺少测试记录，请补充后重新提交。',2,'李明华','2026-10-28 19:22:00','2026-10-20 00:00:00'),
('WR20260916046',9,'SI20260023',9,'徐乐言',1,'2026-09-10','2026-09-16','完成客户流水抽样复核，输出差异说明','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/05.jpg','/uploads/seed/work/02.jpg','2026-09-16 19:40:00','2026-09-17 23:59:00','已批阅',88,'任务描述具体，问题记录清楚，下周计划可执行。',4,'王慧','2026-09-19 19:40:00','2026-09-10 00:00:00'),
('WR20260923047',9,'SI20260023',9,'徐乐言',2,'2026-09-17','2026-09-23','机房巡检 12 次，处理磁盘告警 2 起','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/06.jpg','/uploads/seed/work/03.jpg','2026-09-23 19:06:00','2026-09-24 23:59:00','已批阅',88,'任务描述具体，问题记录清楚，下周计划可执行。',4,'王慧','2026-09-24 19:06:00','2026-09-17 00:00:00'),
('WR20260930048',9,'SI20260023',9,'徐乐言',3,'2026-09-24','2026-09-30','重构前端公共表格组件，减少重复代码约 400 行','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/01.jpg','/uploads/seed/work/04.jpg','2026-09-30 20:00:00','2026-10-01 23:59:00','已批阅',86,'任务描述具体，问题记录清楚，下周计划可执行。',4,'王慧','2026-10-02 20:00:00','2026-09-24 00:00:00'),
('WR20261007049',9,'SI20260023',9,'徐乐言',4,'2026-10-01','2026-10-07','完成竞品调研报告，梳理 6 家同类产品功能矩阵','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/02.jpg','/uploads/seed/work/05.jpg','2026-10-07 22:44:00','2026-10-08 23:59:00','已批阅',80,'任务描述具体，问题记录清楚，下周计划可执行。',4,'王慧','2026-10-08 22:44:00','2026-10-01 00:00:00'),
('WR20261014050',9,'SI20260023',9,'徐乐言',5,'2026-10-08','2026-10-14','完成订单查询接口分页与排序，补充单元测试 12 条','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/03.jpg','/uploads/seed/work/06.jpg','2026-10-14 21:02:00','2026-10-15 23:59:00','已批阅',80,'任务描述具体，问题记录清楚，下周计划可执行。',4,'王慧','2026-10-15 21:02:00','2026-10-08 00:00:00'),
('WR20261021051',9,'SI20260023',9,'徐乐言',6,'2026-10-15','2026-10-21','参与需求评审，整理接口文档初稿','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/04.jpg','/uploads/seed/work/01.jpg','2026-10-21 18:43:00','2026-10-22 23:59:00','已批阅',90,'任务描述具体，问题记录清楚，下周计划可执行。',4,'王慧','2026-10-24 18:43:00','2026-10-15 00:00:00'),
('WR20261028052',9,'SI20260023',9,'徐乐言',7,'2026-10-22','2026-10-28','定位线上慢查询并补充索引，平均响应从 820ms 降到 210ms','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/05.jpg','/uploads/seed/work/02.jpg','2026-10-28 17:38:00','2026-10-29 23:59:00','已批阅',86,'任务描述具体，问题记录清楚，下周计划可执行。',4,'王慧','2026-10-31 17:38:00','2026-10-22 00:00:00'),
('WR20261104053',9,'SI20260023',9,'徐乐言',8,'2026-10-29','2026-11-04','完成客户流水抽样复核，输出差异说明','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/06.jpg','/uploads/seed/work/03.jpg','2026-11-04 18:17:00','2026-11-05 23:59:00','待批阅',NULL,NULL,NULL,NULL,NULL,'2026-10-29 00:00:00'),
('WR20260918054',10,'SI20260022',10,'孟祥宇',1,'2026-09-12','2026-09-18','机房巡检 12 次，处理磁盘告警 2 起','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/01.jpg','/uploads/seed/work/04.jpg','2026-09-18 22:58:00','2026-09-19 23:59:00','已批阅',88,'任务描述具体，问题记录清楚，下周计划可执行。',3,'陈立群','2026-09-19 22:58:00','2026-09-12 00:00:00'),
('WR20260925055',10,'SI20260022',10,'孟祥宇',2,'2026-09-19','2026-09-25','重构前端公共表格组件，减少重复代码约 400 行','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/02.jpg','/uploads/seed/work/05.jpg','2026-09-25 17:18:00','2026-09-26 23:59:00','已批阅',84,'任务描述具体，问题记录清楚，下周计划可执行。',3,'陈立群','2026-09-26 17:18:00','2026-09-19 00:00:00'),
('WR20261002056',10,'SI20260022',10,'孟祥宇',3,'2026-09-26','2026-10-02','完成竞品调研报告，梳理 6 家同类产品功能矩阵','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/03.jpg','/uploads/seed/work/06.jpg','2026-10-02 20:21:00','2026-10-03 23:59:00','已批阅',85,'任务描述具体，问题记录清楚，下周计划可执行。',3,'陈立群','2026-10-03 20:21:00','2026-09-26 00:00:00'),
('WR20261009057',10,'SI20260022',10,'孟祥宇',4,'2026-10-03','2026-10-09','完成订单查询接口分页与排序，补充单元测试 12 条','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/04.jpg','/uploads/seed/work/01.jpg','2026-10-09 19:53:00','2026-10-10 23:59:00','已批阅',82,'任务描述具体，问题记录清楚，下周计划可执行。',3,'陈立群','2026-10-10 19:53:00','2026-10-03 00:00:00'),
('WR20261016058',10,'SI20260022',10,'孟祥宇',5,'2026-10-10','2026-10-16','参与需求评审，整理接口文档初稿','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/05.jpg','/uploads/seed/work/02.jpg','2026-10-16 19:07:00','2026-10-17 23:59:00','已批阅',88,'任务描述具体，问题记录清楚，下周计划可执行。',3,'陈立群','2026-10-18 19:07:00','2026-10-10 00:00:00'),
('WR20261023059',10,'SI20260022',10,'孟祥宇',6,'2026-10-17','2026-10-23','定位线上慢查询并补充索引，平均响应从 820ms 降到 210ms','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/06.jpg','/uploads/seed/work/03.jpg','2026-10-23 17:44:00','2026-10-24 23:59:00','已批阅',86,'任务描述具体，问题记录清楚，下周计划可执行。',3,'陈立群','2026-10-25 17:44:00','2026-10-17 00:00:00'),
('WR20261030060',10,'SI20260022',10,'孟祥宇',7,'2026-10-24','2026-10-30','完成客户流水抽样复核，输出差异说明','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/01.jpg','/uploads/seed/work/04.jpg','2026-10-30 21:30:00','2026-10-31 23:59:00','已批阅',82,'任务描述具体，问题记录清楚，下周计划可执行。',3,'陈立群','2026-11-01 21:30:00','2026-10-24 00:00:00'),
('WR20261106061',10,'SI20260022',10,'孟祥宇',8,'2026-10-31','2026-11-06','机房巡检 12 次，处理磁盘告警 2 起','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/02.jpg','/uploads/seed/work/05.jpg','2026-11-06 21:54:00','2026-11-07 23:59:00','待批阅',NULL,NULL,NULL,NULL,NULL,'2026-10-31 00:00:00'),
('WR20260911062',11,'SI20260021',11,'方雨欣',1,'2026-09-05','2026-09-11','重构前端公共表格组件，减少重复代码约 400 行','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/03.jpg','/uploads/seed/work/06.jpg','2026-09-11 22:00:00','2026-09-12 23:59:00','已批阅',86,'任务描述具体，问题记录清楚，下周计划可执行。',4,'王慧','2026-09-12 22:00:00','2026-09-05 00:00:00'),
('WR20260918063',11,'SI20260021',11,'方雨欣',2,'2026-09-12','2026-09-18','完成竞品调研报告，梳理 6 家同类产品功能矩阵','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/04.jpg','/uploads/seed/work/01.jpg','2026-09-18 21:43:00','2026-09-19 23:59:00','已批阅',90,'任务描述具体，问题记录清楚，下周计划可执行。',4,'王慧','2026-09-19 21:43:00','2026-09-12 00:00:00'),
('WR20260925064',11,'SI20260021',11,'方雨欣',3,'2026-09-19','2026-09-25','完成订单查询接口分页与排序，补充单元测试 12 条','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/05.jpg','/uploads/seed/work/02.jpg','2026-09-25 19:59:00','2026-09-26 23:59:00','已批阅',90,'任务描述具体，问题记录清楚，下周计划可执行。',4,'王慧','2026-09-27 19:59:00','2026-09-19 00:00:00'),
('WR20261002065',11,'SI20260021',11,'方雨欣',4,'2026-09-26','2026-10-02','参与需求评审，整理接口文档初稿','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/06.jpg','/uploads/seed/work/03.jpg','2026-10-02 18:52:00','2026-10-03 23:59:00','已批阅',88,'任务描述具体，问题记录清楚，下周计划可执行。',4,'王慧','2026-10-03 18:52:00','2026-09-26 00:00:00'),
('WR20261009066',11,'SI20260021',11,'方雨欣',5,'2026-10-03','2026-10-09','定位线上慢查询并补充索引，平均响应从 820ms 降到 210ms','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/01.jpg','/uploads/seed/work/04.jpg','2026-10-09 18:06:00','2026-10-10 23:59:00','已批阅',80,'任务描述具体，问题记录清楚，下周计划可执行。',4,'王慧','2026-10-12 18:06:00','2026-10-03 00:00:00'),
('WR20261016067',11,'SI20260021',11,'方雨欣',6,'2026-10-10','2026-10-16','完成客户流水抽样复核，输出差异说明','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/02.jpg','/uploads/seed/work/05.jpg','2026-10-16 19:18:00','2026-10-17 23:59:00','已批阅',80,'任务描述具体，问题记录清楚，下周计划可执行。',4,'王慧','2026-10-19 19:18:00','2026-10-10 00:00:00'),
('WR20261023068',11,'SI20260021',11,'方雨欣',7,'2026-10-17','2026-10-23','机房巡检 12 次，处理磁盘告警 2 起','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/03.jpg','/uploads/seed/work/06.jpg','2026-10-23 19:50:00','2026-10-24 23:59:00','已批阅',88,'任务描述具体，问题记录清楚，下周计划可执行。',4,'王慧','2026-10-26 19:50:00','2026-10-17 00:00:00'),
('WR20261030069',11,'SI20260021',11,'方雨欣',8,'2026-10-24','2026-10-30','重构前端公共表格组件，减少重复代码约 400 行','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/04.jpg','/uploads/seed/work/01.jpg','2026-10-30 22:36:00','2026-10-31 23:59:00','待批阅',NULL,NULL,NULL,NULL,NULL,'2026-10-24 00:00:00'),
('WR20260907070',12,'SI20260020',12,'谭嘉懿',1,'2026-09-01','2026-09-07','完成竞品调研报告，梳理 6 家同类产品功能矩阵','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/05.jpg','/uploads/seed/work/02.jpg','2026-09-07 17:45:00','2026-09-08 23:59:00','已批阅',90,'任务描述具体，问题记录清楚，下周计划可执行。',2,'李明华','2026-09-09 17:45:00','2026-09-01 00:00:00'),
('WR20260914071',12,'SI20260020',12,'谭嘉懿',2,'2026-09-08','2026-09-14','完成订单查询接口分页与排序，补充单元测试 12 条','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/06.jpg','/uploads/seed/work/03.jpg','2026-09-14 19:47:00','2026-09-15 23:59:00','已批阅',84,'任务描述具体，问题记录清楚，下周计划可执行。',2,'李明华','2026-09-16 19:47:00','2026-09-08 00:00:00'),
('WR20260921072',12,'SI20260020',12,'谭嘉懿',3,'2026-09-15','2026-09-21','参与需求评审，整理接口文档初稿','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/01.jpg','/uploads/seed/work/04.jpg','2026-09-21 18:56:00','2026-09-22 23:59:00','已批阅',82,'任务描述具体，问题记录清楚，下周计划可执行。',2,'李明华','2026-09-23 18:56:00','2026-09-15 00:00:00'),
('WR20260928073',12,'SI20260020',12,'谭嘉懿',4,'2026-09-22','2026-09-28','定位线上慢查询并补充索引，平均响应从 820ms 降到 210ms','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/02.jpg','/uploads/seed/work/05.jpg','2026-09-28 20:00:00','2026-09-29 23:59:00','已批阅',80,'任务描述具体，问题记录清楚，下周计划可执行。',2,'李明华','2026-10-01 20:00:00','2026-09-22 00:00:00'),
('WR20261005074',12,'SI20260020',12,'谭嘉懿',5,'2026-09-29','2026-10-05','完成客户流水抽样复核，输出差异说明','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/03.jpg','/uploads/seed/work/06.jpg','2026-10-05 20:56:00','2026-10-06 23:59:00','已批阅',86,'任务描述具体，问题记录清楚，下周计划可执行。',2,'李明华','2026-10-06 20:56:00','2026-09-29 00:00:00'),
('WR20261012075',12,'SI20260020',12,'谭嘉懿',6,'2026-10-06','2026-10-12','机房巡检 12 次，处理磁盘告警 2 起','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/04.jpg','/uploads/seed/work/01.jpg','2026-10-12 19:42:00','2026-10-13 23:59:00','已批阅',88,'任务描述具体，问题记录清楚，下周计划可执行。',2,'李明华','2026-10-13 19:42:00','2026-10-06 00:00:00'),
('WR20261019076',12,'SI20260020',12,'谭嘉懿',7,'2026-10-13','2026-10-19','重构前端公共表格组件，减少重复代码约 400 行','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/05.jpg','/uploads/seed/work/02.jpg','2026-10-19 22:48:00','2026-10-20 23:59:00','已批阅',85,'任务描述具体，问题记录清楚，下周计划可执行。',2,'李明华','2026-10-20 22:48:00','2026-10-13 00:00:00'),
('WR20261026077',12,'SI20260020',12,'谭嘉懿',8,'2026-10-20','2026-10-26','完成竞品调研报告，梳理 6 家同类产品功能矩阵','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/06.jpg','/uploads/seed/work/03.jpg','2026-10-26 18:00:00','2026-10-27 23:59:00','待批阅',NULL,NULL,NULL,NULL,NULL,'2026-10-20 00:00:00'),
('WR20260407078',13,'SI20260019',13,'陈知远',1,'2026-04-01','2026-04-07','完成订单查询接口分页与排序，补充单元测试 12 条','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/01.jpg','/uploads/seed/work/04.jpg','2026-04-07 17:12:00','2026-04-08 23:59:00','已批阅',84,'任务描述具体，问题记录清楚，下周计划可执行。',3,'陈立群','2026-04-08 17:12:00','2026-04-01 00:00:00'),
('WR20260414079',13,'SI20260019',13,'陈知远',2,'2026-04-08','2026-04-14','参与需求评审，整理接口文档初稿','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/02.jpg','/uploads/seed/work/05.jpg','2026-04-14 18:27:00','2026-04-15 23:59:00','已批阅',82,'任务描述具体，问题记录清楚，下周计划可执行。',3,'陈立群','2026-04-17 18:27:00','2026-04-08 00:00:00'),
('WR20260421080',13,'SI20260019',13,'陈知远',3,'2026-04-15','2026-04-21','定位线上慢查询并补充索引，平均响应从 820ms 降到 210ms','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/03.jpg','/uploads/seed/work/06.jpg','2026-04-21 18:28:00','2026-04-22 23:59:00','已批阅',92,'任务描述具体，问题记录清楚，下周计划可执行。',3,'陈立群','2026-04-24 18:28:00','2026-04-15 00:00:00'),
('WR20260428081',13,'SI20260019',13,'陈知远',4,'2026-04-22','2026-04-28','完成客户流水抽样复核，输出差异说明','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/04.jpg','/uploads/seed/work/01.jpg','2026-04-28 19:54:00','2026-04-29 23:59:00','已批阅',80,'任务描述具体，问题记录清楚，下周计划可执行。',3,'陈立群','2026-04-29 19:54:00','2026-04-22 00:00:00'),
('WR20260505082',13,'SI20260019',13,'陈知远',5,'2026-04-29','2026-05-05','机房巡检 12 次，处理磁盘告警 2 起','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/05.jpg','/uploads/seed/work/02.jpg','2026-05-05 21:37:00','2026-05-06 23:59:00','已批阅',80,'任务描述具体，问题记录清楚，下周计划可执行。',3,'陈立群','2026-05-08 21:37:00','2026-04-29 00:00:00'),
('WR20250911083',14,'SI20260018',14,'宋雨桐',1,'2025-09-05','2025-09-11','参与需求评审，整理接口文档初稿','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/06.jpg','/uploads/seed/work/03.jpg','2025-09-11 19:59:00','2025-09-12 23:59:00','已批阅',90,'任务描述具体，问题记录清楚，下周计划可执行。',4,'王慧','2025-09-14 19:59:00','2025-09-05 00:00:00'),
('WR20250918084',14,'SI20260018',14,'宋雨桐',2,'2025-09-12','2025-09-18','定位线上慢查询并补充索引，平均响应从 820ms 降到 210ms','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/01.jpg','/uploads/seed/work/04.jpg','2025-09-18 22:23:00','2025-09-19 23:59:00','已批阅',86,'任务描述具体，问题记录清楚，下周计划可执行。',4,'王慧','2025-09-20 22:23:00','2025-09-12 00:00:00'),
('WR20250925085',14,'SI20260018',14,'宋雨桐',3,'2025-09-19','2025-09-25','完成客户流水抽样复核，输出差异说明','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/02.jpg','/uploads/seed/work/05.jpg','2025-09-25 20:53:00','2025-09-26 23:59:00','已批阅',80,'任务描述具体，问题记录清楚，下周计划可执行。',4,'王慧','2025-09-28 20:53:00','2025-09-19 00:00:00'),
('WR20251002086',14,'SI20260018',14,'宋雨桐',4,'2025-09-26','2025-10-02','机房巡检 12 次，处理磁盘告警 2 起','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/03.jpg','/uploads/seed/work/06.jpg','2025-10-02 17:50:00','2025-10-03 23:59:00','已批阅',85,'任务描述具体，问题记录清楚，下周计划可执行。',4,'王慧','2025-10-03 17:50:00','2025-09-26 00:00:00'),
('WR20251009087',14,'SI20260018',14,'宋雨桐',5,'2025-10-03','2025-10-09','重构前端公共表格组件，减少重复代码约 400 行','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/04.jpg','/uploads/seed/work/01.jpg','2025-10-09 18:21:00','2025-10-10 23:59:00','已批阅',92,'任务描述具体，问题记录清楚，下周计划可执行。',4,'王慧','2025-10-10 18:21:00','2025-10-03 00:00:00'),
('WR20251016088',14,'SI20260018',14,'宋雨桐',6,'2025-10-10','2025-10-16','完成竞品调研报告，梳理 6 家同类产品功能矩阵','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/05.jpg','/uploads/seed/work/02.jpg','2025-10-16 22:32:00','2025-10-17 23:59:00','已批阅',92,'任务描述具体，问题记录清楚，下周计划可执行。',4,'王慧','2025-10-19 22:32:00','2025-10-10 00:00:00'),
('WR20251023089',14,'SI20260018',14,'宋雨桐',7,'2025-10-17','2025-10-23','完成订单查询接口分页与排序，补充单元测试 12 条','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/06.jpg','/uploads/seed/work/03.jpg','2025-10-23 17:40:00','2025-10-24 23:59:00','已批阅',80,'任务描述具体，问题记录清楚，下周计划可执行。',4,'王慧','2025-10-25 17:40:00','2025-10-17 00:00:00'),
('WR20251030090',14,'SI20260018',14,'宋雨桐',8,'2025-10-24','2025-10-30','参与需求评审，整理接口文档初稿','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/01.jpg','/uploads/seed/work/04.jpg','2025-10-30 18:03:00','2025-10-31 23:59:00','已批阅',92,'任务描述具体，问题记录清楚，下周计划可执行。',4,'王慧','2025-11-01 18:03:00','2025-10-24 00:00:00'),
('WR20260826091',15,'SI20260017',15,'周若菡',1,'2026-08-20','2026-08-26','定位线上慢查询并补充索引，平均响应从 820ms 降到 210ms','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/02.jpg','/uploads/seed/work/05.jpg','2026-08-26 22:16:00','2026-08-27 23:59:00','已批阅',82,'任务描述具体，问题记录清楚，下周计划可执行。',4,'王慧','2026-08-27 22:16:00','2026-08-20 00:00:00'),
('WR20260902092',15,'SI20260017',15,'周若菡',2,'2026-08-27','2026-09-02','完成客户流水抽样复核，输出差异说明','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/03.jpg','/uploads/seed/work/06.jpg','2026-09-02 18:06:00','2026-09-03 23:59:00','已批阅',86,'任务描述具体，问题记录清楚，下周计划可执行。',4,'王慧','2026-09-03 18:06:00','2026-08-27 00:00:00'),
('WR20260909093',15,'SI20260017',15,'周若菡',3,'2026-09-03','2026-09-09','机房巡检 12 次，处理磁盘告警 2 起','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/04.jpg','/uploads/seed/work/01.jpg','2026-09-09 18:56:00','2026-09-10 23:59:00','已批阅',80,'任务描述具体，问题记录清楚，下周计划可执行。',4,'王慧','2026-09-12 18:56:00','2026-09-03 00:00:00'),
('WR20260916094',15,'SI20260017',15,'周若菡',4,'2026-09-10','2026-09-16','重构前端公共表格组件，减少重复代码约 400 行','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/05.jpg','/uploads/seed/work/02.jpg','2026-09-16 22:50:00','2026-09-17 23:59:00','已批阅',92,'任务描述具体，问题记录清楚，下周计划可执行。',4,'王慧','2026-09-17 22:50:00','2026-09-10 00:00:00'),
('WR20260923095',15,'SI20260017',15,'周若菡',5,'2026-09-17','2026-09-23','完成竞品调研报告，梳理 6 家同类产品功能矩阵','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/06.jpg','/uploads/seed/work/03.jpg','2026-09-23 21:29:00','2026-09-24 23:59:00','已批阅',85,'任务描述具体，问题记录清楚，下周计划可执行。',4,'王慧','2026-09-24 21:29:00','2026-09-17 00:00:00'),
('WR20260930096',15,'SI20260017',15,'周若菡',6,'2026-09-24','2026-09-30','完成订单查询接口分页与排序，补充单元测试 12 条','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/01.jpg','/uploads/seed/work/04.jpg','2026-09-30 22:23:00','2026-10-01 23:59:00','已批阅',84,'任务描述具体，问题记录清楚，下周计划可执行。',4,'王慧','2026-10-03 22:23:00','2026-09-24 00:00:00'),
('WR20261007097',15,'SI20260017',15,'周若菡',7,'2026-10-01','2026-10-07','参与需求评审，整理接口文档初稿','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/02.jpg','/uploads/seed/work/05.jpg','2026-10-07 18:54:00','2026-10-08 23:59:00','已批阅',80,'任务描述具体，问题记录清楚，下周计划可执行。',4,'王慧','2026-10-08 18:54:00','2026-10-01 00:00:00'),
('WR20261014098',15,'SI20260017',15,'周若菡',8,'2026-10-08','2026-10-14','定位线上慢查询并补充索引，平均响应从 820ms 降到 210ms','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/03.jpg','/uploads/seed/work/06.jpg','2026-10-14 17:21:00','2026-10-15 23:59:00','待批阅',NULL,NULL,NULL,NULL,NULL,'2026-10-08 00:00:00'),
('WR20260926099',18,'SI20260014',18,'吴承宇',1,'2026-09-20','2026-09-26','重构前端公共表格组件，减少重复代码约 400 行','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/04.jpg','/uploads/seed/work/01.jpg','2026-09-26 18:53:00','2026-09-27 23:59:00','已批阅',92,'任务描述具体，问题记录清楚，下周计划可执行。',3,'陈立群','2026-09-27 18:53:00','2026-09-20 00:00:00'),
('WR20261003100',18,'SI20260014',18,'吴承宇',2,'2026-09-27','2026-10-03','完成竞品调研报告，梳理 6 家同类产品功能矩阵','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/05.jpg','/uploads/seed/work/02.jpg','2026-10-03 20:24:00','2026-10-04 23:59:00','已批阅',90,'任务描述具体，问题记录清楚，下周计划可执行。',3,'陈立群','2026-10-05 20:24:00','2026-09-27 00:00:00'),
('WR20261010101',18,'SI20260014',18,'吴承宇',3,'2026-10-04','2026-10-10','完成订单查询接口分页与排序，补充单元测试 12 条','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/06.jpg','/uploads/seed/work/03.jpg','2026-10-10 20:17:00','2026-10-11 23:59:00','已批阅',90,'任务描述具体，问题记录清楚，下周计划可执行。',3,'陈立群','2026-10-11 20:17:00','2026-10-04 00:00:00'),
('WR20261017102',18,'SI20260014',18,'吴承宇',4,'2026-10-11','2026-10-17','参与需求评审，整理接口文档初稿','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/01.jpg','/uploads/seed/work/04.jpg','2026-10-17 21:50:00','2026-10-18 23:59:00','已批阅',80,'任务描述具体，问题记录清楚，下周计划可执行。',3,'陈立群','2026-10-20 21:50:00','2026-10-11 00:00:00'),
('WR20261024103',18,'SI20260014',18,'吴承宇',5,'2026-10-18','2026-10-24','定位线上慢查询并补充索引，平均响应从 820ms 降到 210ms','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/02.jpg','/uploads/seed/work/05.jpg','2026-10-24 22:37:00','2026-10-25 23:59:00','已批阅',80,'任务描述具体，问题记录清楚，下周计划可执行。',3,'陈立群','2026-10-26 22:37:00','2026-10-18 00:00:00'),
('WR20261031104',18,'SI20260014',18,'吴承宇',6,'2026-10-25','2026-10-31','完成客户流水抽样复核，输出差异说明','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/03.jpg','/uploads/seed/work/06.jpg','2026-10-31 19:16:00','2026-11-01 23:59:00','已批阅',90,'任务描述具体，问题记录清楚，下周计划可执行。',3,'陈立群','2026-11-03 19:16:00','2026-10-25 00:00:00'),
('WR20261107105',18,'SI20260014',18,'吴承宇',7,'2026-11-01','2026-11-07','机房巡检 12 次，处理磁盘告警 2 起','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/04.jpg','/uploads/seed/work/01.jpg','2026-11-07 20:55:00','2026-11-08 23:59:00','已批阅',92,'任务描述具体，问题记录清楚，下周计划可执行。',3,'陈立群','2026-11-09 20:55:00','2026-11-01 00:00:00'),
('WR20261114106',18,'SI20260014',18,'吴承宇',8,'2026-11-08','2026-11-14','重构前端公共表格组件，减少重复代码约 400 行','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/05.jpg','/uploads/seed/work/02.jpg','2026-11-14 18:13:00','2026-11-15 23:59:00','待批阅',NULL,NULL,NULL,NULL,NULL,'2026-11-08 00:00:00'),
('WR20260908107',19,'SI20260013',19,'孟祥宇',1,'2026-09-02','2026-09-08','完成竞品调研报告，梳理 6 家同类产品功能矩阵','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/06.jpg','/uploads/seed/work/03.jpg','2026-09-08 22:57:00','2026-09-09 23:59:00','已批阅',90,'任务描述具体，问题记录清楚，下周计划可执行。',2,'李明华','2026-09-10 22:57:00','2026-09-02 00:00:00'),
('WR20260915108',19,'SI20260013',19,'孟祥宇',2,'2026-09-09','2026-09-15','完成订单查询接口分页与排序，补充单元测试 12 条','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/01.jpg','/uploads/seed/work/04.jpg','2026-09-15 18:41:00','2026-09-16 23:59:00','已批阅',86,'任务描述具体，问题记录清楚，下周计划可执行。',2,'李明华','2026-09-16 18:41:00','2026-09-09 00:00:00'),
('WR20260922109',19,'SI20260013',19,'孟祥宇',3,'2026-09-16','2026-09-22','参与需求评审，整理接口文档初稿','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/02.jpg','/uploads/seed/work/05.jpg','2026-09-22 21:52:00','2026-09-23 23:59:00','已批阅',90,'任务描述具体，问题记录清楚，下周计划可执行。',2,'李明华','2026-09-23 21:52:00','2026-09-16 00:00:00'),
('WR20260929110',19,'SI20260013',19,'孟祥宇',4,'2026-09-23','2026-09-29','定位线上慢查询并补充索引，平均响应从 820ms 降到 210ms','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/03.jpg','/uploads/seed/work/06.jpg','2026-09-29 21:34:00','2026-09-30 23:59:00','已批阅',85,'任务描述具体，问题记录清楚，下周计划可执行。',2,'李明华','2026-10-02 21:34:00','2026-09-23 00:00:00'),
('WR20261006111',19,'SI20260013',19,'孟祥宇',5,'2026-09-30','2026-10-06','完成客户流水抽样复核，输出差异说明','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/04.jpg','/uploads/seed/work/01.jpg','2026-10-06 19:56:00','2026-10-07 23:59:00','已批阅',85,'任务描述具体，问题记录清楚，下周计划可执行。',2,'李明华','2026-10-08 19:56:00','2026-09-30 00:00:00'),
('WR20261013112',19,'SI20260013',19,'孟祥宇',6,'2026-10-07','2026-10-13','机房巡检 12 次，处理磁盘告警 2 起','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/05.jpg','/uploads/seed/work/02.jpg','2026-10-13 17:06:00','2026-10-14 23:59:00','已批阅',82,'任务描述具体，问题记录清楚，下周计划可执行。',2,'李明华','2026-10-16 17:06:00','2026-10-07 00:00:00'),
('WR20261020113',19,'SI20260013',19,'孟祥宇',7,'2026-10-14','2026-10-20','重构前端公共表格组件，减少重复代码约 400 行','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/06.jpg','/uploads/seed/work/03.jpg','2026-10-20 21:02:00','2026-10-21 23:59:00','已批阅',86,'任务描述具体，问题记录清楚，下周计划可执行。',2,'李明华','2026-10-21 21:02:00','2026-10-14 00:00:00'),
('WR20261027114',19,'SI20260013',19,'孟祥宇',8,'2026-10-21','2026-10-27','完成竞品调研报告，梳理 6 家同类产品功能矩阵','掌握分页插件用法与索引命中分析','联调环境数据为空导致总数为 0，已与测试同学确认为环境问题','接入缓存层并压测 QPS 200 场景','/uploads/seed/work/01.jpg','/uploads/seed/work/04.jpg','2026-10-27 17:08:00','2026-10-28 23:59:00','待批阅',NULL,NULL,NULL,NULL,NULL,'2026-10-21 00:00:00');

-- 月度考勤
INSERT INTO monthly_attendance (attendance_no,application_id,student_id,student_name,company_name,month,
should_days,actual_days,late_count,leave_days,remark,confirm_status,mentor_name,create_time) VALUES 
('AT202609001',3,3,'赵一鸣','浙江中控技术股份有限公司','2026-09',22,20,2,2,'—','学生已确认','刘畅','2026-09-28 00:00:00'),
('AT202610002',3,3,'赵一鸣','浙江中控技术股份有限公司','2026-10',22,20,2,2,'—','学生已确认','刘畅','2026-10-28 00:00:00'),
('AT202609003',4,4,'周若菡','上海远景能源有限公司','2026-09',22,21,2,1,'—','学生已确认','孙悦','2026-09-28 00:00:00'),
('AT202610004',4,4,'周若菡','上海远景能源有限公司','2026-10',22,22,0,0,'—','学生已确认','孙悦','2026-10-28 00:00:00'),
('AT202609005',5,5,'林嘉禾','杭州拾光传媒有限公司','2026-09',22,19,1,3,'—','待学生确认','郑楠','2026-09-28 00:00:00'),
('AT202610006',5,5,'林嘉禾','杭州拾光传媒有限公司','2026-10',22,14,1,8,'请假天数存在争议，学生申请复核','学生有异议','郑楠','2026-10-28 00:00:00'),
('AT202510007',6,6,'吴承宇','深圳恒瑞医疗器械有限公司','2025-10',22,22,0,0,'—','学生已确认','黄磊','2025-10-28 00:00:00'),
('AT202511008',6,6,'吴承宇','深圳恒瑞医疗器械有限公司','2025-11',22,20,2,2,'—','学生已确认','黄磊','2025-11-28 00:00:00'),
('AT202512009',6,6,'吴承宇','深圳恒瑞医疗器械有限公司','2025-12',22,21,2,1,'—','学生已确认','黄磊','2025-12-28 00:00:00'),
('AT202601010',6,6,'吴承宇','深圳恒瑞医疗器械有限公司','2026-01',22,22,0,0,'—','学生已确认','黄磊','2026-01-28 00:00:00'),
('AT202609011',7,7,'何书宁','北京字节跳动科技有限公司','2026-09',22,20,2,2,'—','学生已确认','张一凡','2026-09-28 00:00:00'),
('AT202610012',7,7,'何书宁','北京字节跳动科技有限公司','2026-10',22,21,2,1,'—','学生已确认','张一凡','2026-10-28 00:00:00'),
('AT202609013',8,8,'郑亦航','杭州同花顺网络信息股份有限公司','2026-09',22,22,0,0,'—','学生已确认','方晓','2026-09-28 00:00:00'),
('AT202610014',8,8,'郑亦航','杭州同花顺网络信息股份有限公司','2026-10',22,21,1,1,'—','学生已确认','方晓','2026-10-28 00:00:00'),
('AT202609015',9,9,'徐乐言','宁波甬信会计师事务所','2026-09',22,19,1,3,'—','学生已确认','王倩','2026-09-28 00:00:00'),
('AT202610016',9,9,'徐乐言','宁波甬信会计师事务所','2026-10',22,22,0,0,'—','学生已确认','王倩','2026-10-28 00:00:00'),
('AT202609017',10,10,'孟祥宇','浙江中控技术股份有限公司','2026-09',22,21,1,1,'—','待学生确认','刘畅','2026-09-28 00:00:00'),
('AT202610018',10,10,'孟祥宇','浙江中控技术股份有限公司','2026-10',22,19,2,3,'—','待学生确认','刘畅','2026-10-28 00:00:00'),
('AT202609019',11,11,'方雨欣','杭州育才教育科技有限公司','2026-09',22,19,2,3,'—','学生已确认','钱蕾','2026-09-28 00:00:00'),
('AT202610020',11,11,'方雨欣','杭州育才教育科技有限公司','2026-10',22,22,0,0,'—','学生已确认','钱蕾','2026-10-28 00:00:00'),
('AT202609021',12,12,'谭嘉懿','杭州云枢科技有限公司','2026-09',22,22,0,0,'—','学生已确认','周建国','2026-09-28 00:00:00'),
('AT202610022',12,12,'谭嘉懿','杭州云枢科技有限公司','2026-10',22,21,1,1,'—','学生已确认','周建国','2026-10-28 00:00:00'),
('AT202609023',13,13,'陈知远','浙江中控技术股份有限公司','2026-09',22,19,1,3,'—','学生已确认','刘畅','2026-09-28 00:00:00'),
('AT202610024',13,13,'陈知远','浙江中控技术股份有限公司','2026-10',22,20,2,2,'—','学生已确认','刘畅','2026-10-28 00:00:00'),
('AT202510025',14,14,'宋雨桐','杭州同花顺网络信息股份有限公司','2025-10',22,19,1,3,'—','学生已确认','方晓','2025-10-28 00:00:00'),
('AT202511026',14,14,'宋雨桐','杭州同花顺网络信息股份有限公司','2025-11',22,21,2,1,'—','学生已确认','方晓','2025-11-28 00:00:00'),
('AT202512027',14,14,'宋雨桐','杭州同花顺网络信息股份有限公司','2025-12',22,22,0,0,'—','学生已确认','方晓','2025-12-28 00:00:00'),
('AT202601028',14,14,'宋雨桐','杭州同花顺网络信息股份有限公司','2026-01',22,19,2,3,'—','学生已确认','方晓','2026-01-28 00:00:00'),
('AT202609029',15,15,'周若菡','杭州星野网络科技工作室','2026-09',22,20,1,2,'—','待学生确认','毛骏','2026-09-28 00:00:00'),
('AT202610030',15,15,'周若菡','杭州星野网络科技工作室','2026-10',22,21,2,1,'—','待学生确认','毛骏','2026-10-28 00:00:00'),
('AT202609031',18,18,'吴承宇','苏州精密仪器制造有限公司','2026-09',22,20,2,2,'—','学生已确认','毛骏','2026-09-28 00:00:00'),
('AT202610032',18,18,'吴承宇','苏州精密仪器制造有限公司','2026-10',22,20,2,2,'—','学生已确认','毛骏','2026-10-28 00:00:00'),
('AT202609033',19,19,'孟祥宇','杭州云枢科技有限公司','2026-09',22,22,0,0,'—','学生已确认','周建国','2026-09-28 00:00:00'),
('AT202610034',19,19,'孟祥宇','杭州云枢科技有限公司','2026-10',22,19,1,3,'—','学生已确认','周建国','2026-10-28 00:00:00');

-- 变更审批
INSERT INTO internship_change (change_no,application_id,student_name,change_type,before_value,after_value,reason,
attachment,current_node,status,apply_time,teacher_opinion,admin_opinion,effective_time,create_time) VALUES 
('CH20261028002',4,'周若菡','更换岗位','产品运营实习','产品经理实习','企业业务调整，岗位职责升级，与学生职业规划一致','/uploads/seed/work/02.jpg','校内审批','审批中','2026-10-28 15:20:00',NULL,NULL,NULL,'2026-10-28 15:20:00'),('CH20261026001',2,'宋雨桐','更换导师','王倩','陈默','原企业导师调岗离任，由项目经理接任','/uploads/seed/work/03.jpg','管理员审批','审批中','2026-10-26 10:05:00','同意，材料齐全',NULL,NULL,'2026-10-26 10:05:00'),('CH20261018003',7,'何书宁','中止实习','实习中','已中止','个人健康原因，已提交医院证明与家长知情书','/uploads/seed/work/04.jpg','已生效','已通过','2026-10-18 09:30:00','同意，材料齐全','同意变更','2026-10-18 09:30:00','2026-10-18 09:30:00'),('CH20261009004',8,'郑亦航','更换企业','杭州同花顺','浙江中控技术','原企业岗位与专业方向不符，经学院协调重新安排','/uploads/seed/work/05.jpg','已生效','已通过','2026-10-09 14:12:00','同意，材料齐全','同意变更','2026-10-09 14:12:00','2026-10-09 14:12:00'),('CH20260928005',5,'林嘉禾','更换导师','郑楠','郑楠','导师联系方式变更，仅更新联系方式','/uploads/seed/work/06.jpg','已驳回','已驳回','2026-09-28 11:00:00',NULL,NULL,NULL,'2026-09-28 11:00:00'),('CH20260915006',11,'方雨欣','更换岗位','教务运营实习','课程顾问实习','企业内轮岗，岗位内容相近','/uploads/seed/work/01.jpg','已生效','已通过','2026-09-15 16:40:00','同意，材料齐全','同意变更','2026-09-15 16:40:00','2026-09-15 16:40:00');

-- 异常关怀
INSERT INTO internship_issue (issue_no,application_id,student_name,company_name,issue_type,level,content,
report_time,handler_name,status,handle_record,close_time,create_time) VALUES 
('IS20261029001',5,'林嘉禾','杭州拾光传媒有限公司','薪资争议','高','企业按 80% 发放 9 月实习补贴，与协议约定不符','2026-10-29 11:20:00','李明华','处置中','2026-10-31 10:30 现场走访核实，企业承诺 11 月补发差额，等待整改回执',NULL,'2026-10-29 11:20:00'),('IS20261027002',3,'赵一鸣','浙江中控技术股份有限公司','岗位不符','中','实际工作以文档整理为主，与运维岗位描述差异较大','2026-10-27 09:05:00','陈立群','处置中','已电话联系企业人事，约定岗位调整方案',NULL,'2026-10-27 09:05:00'),('IS20261020003',7,'何书宁','北京字节跳动科技有限公司','无法联系','高','连续 5 天未提交周报且电话无法接通','2026-10-20 16:40:00','王慧','已关闭','已完成处置并回访确认，学生状态正常，工单关闭','2026-10-20 16:40:00','2026-10-20 16:40:00'),('IS20261011004',6,'吴承宇','深圳恒瑞医疗器械有限公司','安全问题','中','实验室未按规范配备防护用品','2026-10-11 14:12:00','王慧','已关闭','已完成处置并回访确认，学生状态正常，工单关闭','2026-10-11 14:12:00','2026-10-11 14:12:00'),('IS20260925005',8,'郑亦航','杭州同花顺网络信息股份有限公司','岗位不符','低','轮岗安排与原岗位不一致，已协调','2026-09-25 10:30:00','李明华','已关闭','已完成处置并回访确认，学生状态正常，工单关闭','2026-09-25 10:30:00','2026-09-25 10:30:00'),('IS20260918006',12,'谭嘉懿','杭州云枢科技有限公司','无法联系','中','企业导师出差，周报批阅延迟两周','2026-09-18 15:00:00','李明华','已关闭','已完成处置并回访确认，学生状态正常，工单关闭','2026-09-18 15:00:00','2026-09-18 15:00:00');

-- 走访记录
INSERT INTO visit_record (visit_no,application_id,student_name,company_name,visit_type,visit_date,participants,
student_performance,company_opinion,photo,teacher_id,teacher_name,create_time) VALUES 
('VS20261031001',5,'林嘉禾','杭州拾光传媒有限公司','现场','2026-10-31','李明华、郑楠','工作投入，沟通顺畅，对薪资问题表达合理诉求','认可能力，承诺 11 月补发差额并规范结算','/uploads/seed/visit/04.jpg',2,'李明华','2026-10-31 10:00:00'),('VS20261024002',3,'赵一鸣','浙江中控技术股份有限公司','电话','2026-10-24','陈立群','适应良好，夜班较多，希望增加轮岗','同意安排轮岗并明确岗位职责','/uploads/seed/visit/03.jpg',2,'王慧','2026-10-24 10:00:00'),('VS20261017003',1,'陈知远','杭州云枢科技有限公司','现场','2026-10-17','李明华','技术成长明显，能独立承担接口开发','建议加强文档习惯与代码评审参与度','/uploads/seed/visit/02.jpg',2,'李明华','2026-10-17 10:00:00'),('VS20261010004',4,'周若菡','上海远景能源有限公司','电话','2026-10-10','王慧','工作主动，能独立完成调研任务','希望学校增加数据分析相关课程','/uploads/seed/visit/01.jpg',2,'王慧','2026-10-10 10:00:00'),('VS20260926005',8,'郑亦航','杭州同花顺网络信息股份有限公司','现场','2026-09-26','李明华','基础扎实，需加强需求澄清主动性','愿意提供转正机会','/uploads/seed/visit/04.jpg',2,'李明华','2026-09-26 10:00:00'),('VS20260919006',2,'宋雨桐','宁波甬信会计师事务所','电话','2026-09-19','王慧','适应良好，能承担抽样复核工作','建议加强沟通表达','/uploads/seed/visit/03.jpg',2,'王慧','2026-09-19 10:00:00');

-- 结项评价
INSERT INTO final_evaluation (application_id,student_name,company_score,company_comment,company_evaluator,
company_time,school_score,school_comment,school_evaluator,school_time,report_score,total_score,grade,materials_ok,
status,create_time) VALUES 
(3,'赵一鸣',4.4,'工作认真，交付质量稳定，团队协作良好','刘畅',NULL,86,'全程按时提交周报，问题反馈及时','陈立群',NULL,93.0,NULL,NULL,0,'待评价','2026-09-15 09:00:00'),
(4,'周若菡',4.0,'工作认真，交付质量稳定，团队协作良好','孙悦',NULL,90,'全程按时提交周报，问题反馈及时','王慧',NULL,88.0,NULL,NULL,0,'待评价','2026-09-08 09:00:00'),
(5,'林嘉禾',4.4,'工作认真，交付质量稳定，团队协作良好','郑楠','2026-10-25 15:00:00',85,'全程按时提交周报，问题反馈及时','李明华','2026-10-27 10:00:00',93.0,87.8,'良好',0,'评价中','2026-08-25 09:00:00'),
(6,'吴承宇',4.0,'工作认真，交付质量稳定，团队协作良好','黄磊','2026-10-25 15:00:00',90,'全程按时提交周报，问题反馈及时','王慧','2026-10-27 10:00:00',93.0,86.6,'良好',1,'已结项','2025-09-10 09:00:00'),
(7,'何书宁',4.3,'工作认真，交付质量稳定，团队协作良好','张一凡',NULL,85,'全程按时提交周报，问题反馈及时','王慧',NULL,90.0,NULL,NULL,0,'待评价','2026-07-01 09:00:00'),
(8,'郑亦航',4.7,'工作认真，交付质量稳定，团队协作良好','方晓',NULL,85,'全程按时提交周报，问题反馈及时','李明华',NULL,90.0,NULL,NULL,0,'待评价','2026-09-01 09:00:00'),
(9,'徐乐言',3.9,'工作认真，交付质量稳定，团队协作良好','王倩',NULL,82,'全程按时提交周报，问题反馈及时','王慧',NULL,93.0,NULL,NULL,0,'待评价','2026-09-10 09:00:00'),
(10,'孟祥宇',4.7,'工作认真，交付质量稳定，团队协作良好','刘畅',NULL,85,'全程按时提交周报，问题反馈及时','陈立群',NULL,90.0,NULL,NULL,0,'待评价','2026-09-12 09:00:00'),
(11,'方雨欣',3.6,'工作认真，交付质量稳定，团队协作良好','钱蕾',NULL,85,'全程按时提交周报，问题反馈及时','王慧',NULL,93.0,NULL,NULL,0,'待评价','2026-09-05 09:00:00'),
(12,'谭嘉懿',3.8,'工作认真，交付质量稳定，团队协作良好','周建国','2026-10-25 15:00:00',90,'全程按时提交周报，问题反馈及时','李明华','2026-10-27 10:00:00',88.0,84.0,'良好',0,'评价中','2026-09-01 09:00:00'),
(13,'陈知远',4.6,'工作认真，交付质量稳定，团队协作良好','刘畅',NULL,86,'全程按时提交周报，问题反馈及时','陈立群',NULL,85.0,NULL,NULL,0,'待评价','2026-04-01 09:00:00'),
(14,'宋雨桐',4.7,'工作认真，交付质量稳定，团队协作良好','方晓','2026-10-25 15:00:00',88,'全程按时提交周报，问题反馈及时','王慧','2026-10-27 10:00:00',88.0,90.4,'优秀',1,'已结项','2025-09-05 09:00:00'),
(15,'周若菡',3.8,'工作认真，交付质量稳定，团队协作良好','毛骏','2026-10-25 15:00:00',86,'全程按时提交周报，问题反馈及时','王慧','2026-10-27 10:00:00',93.0,83.4,'良好',0,'评价中','2026-08-20 09:00:00'),
(18,'吴承宇',3.9,'工作认真，交付质量稳定，团队协作良好','毛骏',NULL,90,'全程按时提交周报，问题反馈及时','陈立群',NULL,85.0,NULL,NULL,0,'待评价','2026-09-20 09:00:00'),
(19,'孟祥宇',3.7,'工作认真，交付质量稳定，团队协作良好','周建国','2026-10-25 15:00:00',86,'全程按时提交周报，问题反馈及时','李明华','2026-10-27 10:00:00',93.0,82.6,'良好',0,'评价中','2026-09-02 09:00:00');

-- 创新点规则（v1~v3，仅 v3 生效）
INSERT INTO internship_rule (rule_name,version,weight_milestone,weight_continuity,weight_attachment,weight_feedback,
weight_delay,weight_company,threshold_good,threshold_mid,enabled,effective_time,create_by,create_time) VALUES
('周报里程碑完整度检查','v1',30,20,15,15,10,10,80,60,0,'2026-03-01 00:00:00','系统初始化','2026-03-01 00:00:00'),
('周报里程碑完整度检查','v2',25,20,20,15,10,10,80,60,0,'2026-06-15 00:00:00','王慧','2026-06-15 09:00:00'),
('周报里程碑完整度检查','v3',30,20,15,15,10,10,80,60,1,'2026-09-01 00:00:00','李明华','2026-09-01 09:00:00');

-- 完整度计算留痕（每个在岗档案 3 周，共 30+ 条）
INSERT INTO internship_score (application_id,student_name,rule_id,rule_version,input_json,detail_json,total_score,
grade,advice,manual_grade,manual_reason,manual_by,manual_time,calc_week,calc_time) VALUES 
(3,'赵一鸣',3,'v3','{"weekNo": 6, "milestoneDone": 2, "milestoneTotal": 4, "continuityWeeks": 6, "attachmentCount": 2, "feedbackScore": 4.5, "delayCount": 1, "companyScore": 4.3}','[{"key": "milestone", "label": "里程碑完成项", "value": "2/4", "weight": 30, "score": 15.0, "note": "已完成 2 项里程碑"}, {"key": "continuity", "label": "周报连续性", "value": "连续 6 周", "weight": 20, "score": 20.0, "note": "无缺交、无逾期"}, {"key": "attachment", "label": "附件数量", "value": "2 个", "weight": 15, "score": 15.0, "note": "附件数量满足要求"}, {"key": "feedback", "label": "导师反馈", "value": "4.5 分", "weight": 15, "score": 13.5, "note": "批阅及时，评语具体"}, {"key": "delay", "label": "延期任务", "value": "1 项", "weight": 10, "score": 6.0, "note": "接口联调延期 4 天"}, {"key": "company", "label": "企业评价", "value": "4.3 分", "weight": 10, "score": 8.6, "note": "企业导师月度评价"}]',80.7,'良好','将第 3 项里程碑拆分为两个子任务并提前一周排期；下周补充接口文档附件',NULL,NULL,NULL,NULL,6,'2026-10-23 09:00:00'),
(3,'赵一鸣',3,'v3','{"weekNo": 7, "milestoneDone": 3, "milestoneTotal": 4, "continuityWeeks": 7, "attachmentCount": 2, "feedbackScore": 4.5, "delayCount": 1, "companyScore": 4.3}','[{"key": "milestone", "label": "里程碑完成项", "value": "3/4", "weight": 30, "score": 22.5, "note": "已完成 3 项里程碑"}, {"key": "continuity", "label": "周报连续性", "value": "连续 7 周", "weight": 20, "score": 20.0, "note": "无缺交、无逾期"}, {"key": "attachment", "label": "附件数量", "value": "2 个", "weight": 15, "score": 15.0, "note": "附件数量满足要求"}, {"key": "feedback", "label": "导师反馈", "value": "4.5 分", "weight": 15, "score": 13.5, "note": "批阅及时，评语具体"}, {"key": "delay", "label": "延期任务", "value": "1 项", "weight": 10, "score": 6.0, "note": "接口联调延期 4 天"}, {"key": "company", "label": "企业评价", "value": "4.3 分", "weight": 10, "score": 8.6, "note": "企业导师月度评价"}]',85.3,'良好','将第 3 项里程碑拆分为两个子任务并提前一周排期；下周补充接口文档附件',NULL,NULL,NULL,NULL,7,'2026-10-24 09:00:00'),
(3,'赵一鸣',3,'v3','{"weekNo": 8, "milestoneDone": 3, "milestoneTotal": 4, "continuityWeeks": 8, "attachmentCount": 2, "feedbackScore": 4.5, "delayCount": 1, "companyScore": 4.3}','[{"key": "milestone", "label": "里程碑完成项", "value": "3/4", "weight": 30, "score": 22.5, "note": "已完成 3 项里程碑"}, {"key": "continuity", "label": "周报连续性", "value": "连续 8 周", "weight": 20, "score": 20.0, "note": "无缺交、无逾期"}, {"key": "attachment", "label": "附件数量", "value": "2 个", "weight": 15, "score": 15.0, "note": "附件数量满足要求"}, {"key": "feedback", "label": "导师反馈", "value": "4.5 分", "weight": 15, "score": 13.5, "note": "批阅及时，评语具体"}, {"key": "delay", "label": "延期任务", "value": "1 项", "weight": 10, "score": 6.0, "note": "接口联调延期 4 天"}, {"key": "company", "label": "企业评价", "value": "4.3 分", "weight": 10, "score": 8.6, "note": "企业导师月度评价"}]',89.5,'良好','将第 3 项里程碑拆分为两个子任务并提前一周排期；下周补充接口文档附件',NULL,NULL,NULL,NULL,8,'2026-10-31 09:00:00'),
(4,'周若菡',3,'v3','{"weekNo": 6, "milestoneDone": 2, "milestoneTotal": 4, "continuityWeeks": 6, "attachmentCount": 2, "feedbackScore": 4.5, "delayCount": 1, "companyScore": 4.3}','[{"key": "milestone", "label": "里程碑完成项", "value": "2/4", "weight": 30, "score": 15.0, "note": "已完成 2 项里程碑"}, {"key": "continuity", "label": "周报连续性", "value": "连续 6 周", "weight": 20, "score": 20.0, "note": "无缺交、无逾期"}, {"key": "attachment", "label": "附件数量", "value": "2 个", "weight": 15, "score": 15.0, "note": "附件数量满足要求"}, {"key": "feedback", "label": "导师反馈", "value": "4.5 分", "weight": 15, "score": 13.5, "note": "批阅及时，评语具体"}, {"key": "delay", "label": "延期任务", "value": "1 项", "weight": 10, "score": 6.0, "note": "接口联调延期 4 天"}, {"key": "company", "label": "企业评价", "value": "4.3 分", "weight": 10, "score": 8.6, "note": "企业导师月度评价"}]',84.5,'良好','将第 3 项里程碑拆分为两个子任务并提前一周排期；下周补充接口文档附件',NULL,NULL,NULL,NULL,6,'2026-10-23 09:00:00'),
(4,'周若菡',3,'v3','{"weekNo": 7, "milestoneDone": 3, "milestoneTotal": 4, "continuityWeeks": 7, "attachmentCount": 2, "feedbackScore": 4.5, "delayCount": 1, "companyScore": 4.3}','[{"key": "milestone", "label": "里程碑完成项", "value": "3/4", "weight": 30, "score": 22.5, "note": "已完成 3 项里程碑"}, {"key": "continuity", "label": "周报连续性", "value": "连续 7 周", "weight": 20, "score": 20.0, "note": "无缺交、无逾期"}, {"key": "attachment", "label": "附件数量", "value": "2 个", "weight": 15, "score": 15.0, "note": "附件数量满足要求"}, {"key": "feedback", "label": "导师反馈", "value": "4.5 分", "weight": 15, "score": 13.5, "note": "批阅及时，评语具体"}, {"key": "delay", "label": "延期任务", "value": "1 项", "weight": 10, "score": 6.0, "note": "接口联调延期 4 天"}, {"key": "company", "label": "企业评价", "value": "4.3 分", "weight": 10, "score": 8.6, "note": "企业导师月度评价"}]',91.4,'优秀','将第 3 项里程碑拆分为两个子任务并提前一周排期；下周补充接口文档附件',NULL,NULL,NULL,NULL,7,'2026-10-24 09:00:00'),
(4,'周若菡',3,'v3','{"weekNo": 8, "milestoneDone": 3, "milestoneTotal": 4, "continuityWeeks": 8, "attachmentCount": 2, "feedbackScore": 4.5, "delayCount": 1, "companyScore": 4.3}','[{"key": "milestone", "label": "里程碑完成项", "value": "3/4", "weight": 30, "score": 22.5, "note": "已完成 3 项里程碑"}, {"key": "continuity", "label": "周报连续性", "value": "连续 8 周", "weight": 20, "score": 20.0, "note": "无缺交、无逾期"}, {"key": "attachment", "label": "附件数量", "value": "2 个", "weight": 15, "score": 15.0, "note": "附件数量满足要求"}, {"key": "feedback", "label": "导师反馈", "value": "4.5 分", "weight": 15, "score": 13.5, "note": "批阅及时，评语具体"}, {"key": "delay", "label": "延期任务", "value": "1 项", "weight": 10, "score": 6.0, "note": "接口联调延期 4 天"}, {"key": "company", "label": "企业评价", "value": "4.3 分", "weight": 10, "score": 8.6, "note": "企业导师月度评价"}]',94.2,'优秀','将第 3 项里程碑拆分为两个子任务并提前一周排期；下周补充接口文档附件',NULL,NULL,NULL,NULL,8,'2026-10-31 09:00:00'),
(5,'林嘉禾',3,'v3','{"weekNo": 6, "milestoneDone": 2, "milestoneTotal": 4, "continuityWeeks": 6, "attachmentCount": 2, "feedbackScore": 4.5, "delayCount": 1, "companyScore": 4.3}','[{"key": "milestone", "label": "里程碑完成项", "value": "2/4", "weight": 30, "score": 15.0, "note": "已完成 2 项里程碑"}, {"key": "continuity", "label": "周报连续性", "value": "连续 6 周", "weight": 20, "score": 20.0, "note": "无缺交、无逾期"}, {"key": "attachment", "label": "附件数量", "value": "2 个", "weight": 15, "score": 15.0, "note": "附件数量满足要求"}, {"key": "feedback", "label": "导师反馈", "value": "4.5 分", "weight": 15, "score": 13.5, "note": "批阅及时，评语具体"}, {"key": "delay", "label": "延期任务", "value": "1 项", "weight": 10, "score": 6.0, "note": "接口联调延期 4 天"}, {"key": "company", "label": "企业评价", "value": "4.3 分", "weight": 10, "score": 8.6, "note": "企业导师月度评价"}]',69.7,'合格','将第 3 项里程碑拆分为两个子任务并提前一周排期；下周补充接口文档附件',NULL,NULL,NULL,NULL,6,'2026-10-23 09:00:00'),
(5,'林嘉禾',3,'v3','{"weekNo": 7, "milestoneDone": 3, "milestoneTotal": 4, "continuityWeeks": 7, "attachmentCount": 2, "feedbackScore": 4.5, "delayCount": 1, "companyScore": 4.3}','[{"key": "milestone", "label": "里程碑完成项", "value": "3/4", "weight": 30, "score": 22.5, "note": "已完成 3 项里程碑"}, {"key": "continuity", "label": "周报连续性", "value": "连续 7 周", "weight": 20, "score": 20.0, "note": "无缺交、无逾期"}, {"key": "attachment", "label": "附件数量", "value": "2 个", "weight": 15, "score": 15.0, "note": "附件数量满足要求"}, {"key": "feedback", "label": "导师反馈", "value": "4.5 分", "weight": 15, "score": 13.5, "note": "批阅及时，评语具体"}, {"key": "delay", "label": "延期任务", "value": "1 项", "weight": 10, "score": 6.0, "note": "接口联调延期 4 天"}, {"key": "company", "label": "企业评价", "value": "4.3 分", "weight": 10, "score": 8.6, "note": "企业导师月度评价"}]',72.4,'合格','将第 3 项里程碑拆分为两个子任务并提前一周排期；下周补充接口文档附件',NULL,NULL,NULL,NULL,7,'2026-10-24 09:00:00'),
(5,'林嘉禾',3,'v3','{"weekNo": 8, "milestoneDone": 3, "milestoneTotal": 4, "continuityWeeks": 8, "attachmentCount": 2, "feedbackScore": 4.5, "delayCount": 1, "companyScore": 4.3}','[{"key": "milestone", "label": "里程碑完成项", "value": "3/4", "weight": 30, "score": 22.5, "note": "已完成 3 项里程碑"}, {"key": "continuity", "label": "周报连续性", "value": "连续 8 周", "weight": 20, "score": 20.0, "note": "无缺交、无逾期"}, {"key": "attachment", "label": "附件数量", "value": "2 个", "weight": 15, "score": 15.0, "note": "附件数量满足要求"}, {"key": "feedback", "label": "导师反馈", "value": "4.5 分", "weight": 15, "score": 13.5, "note": "批阅及时，评语具体"}, {"key": "delay", "label": "延期任务", "value": "1 项", "weight": 10, "score": 6.0, "note": "接口联调延期 4 天"}, {"key": "company", "label": "企业评价", "value": "4.3 分", "weight": 10, "score": 8.6, "note": "企业导师月度评价"}]',78.0,'合格','将第 3 项里程碑拆分为两个子任务并提前一周排期；下周补充接口文档附件',NULL,NULL,NULL,NULL,8,'2026-10-31 09:00:00'),
(6,'吴承宇',3,'v3','{"weekNo": 6, "milestoneDone": 2, "milestoneTotal": 4, "continuityWeeks": 6, "attachmentCount": 2, "feedbackScore": 4.5, "delayCount": 1, "companyScore": 4.3}','[{"key": "milestone", "label": "里程碑完成项", "value": "2/4", "weight": 30, "score": 15.0, "note": "已完成 2 项里程碑"}, {"key": "continuity", "label": "周报连续性", "value": "连续 6 周", "weight": 20, "score": 20.0, "note": "无缺交、无逾期"}, {"key": "attachment", "label": "附件数量", "value": "2 个", "weight": 15, "score": 15.0, "note": "附件数量满足要求"}, {"key": "feedback", "label": "导师反馈", "value": "4.5 分", "weight": 15, "score": 13.5, "note": "批阅及时，评语具体"}, {"key": "delay", "label": "延期任务", "value": "1 项", "weight": 10, "score": 6.0, "note": "接口联调延期 4 天"}, {"key": "company", "label": "企业评价", "value": "4.3 分", "weight": 10, "score": 8.6, "note": "企业导师月度评价"}]',73.3,'合格','将第 3 项里程碑拆分为两个子任务并提前一周排期；下周补充接口文档附件',NULL,NULL,NULL,NULL,6,'2026-10-23 09:00:00'),
(6,'吴承宇',3,'v3','{"weekNo": 7, "milestoneDone": 3, "milestoneTotal": 4, "continuityWeeks": 7, "attachmentCount": 2, "feedbackScore": 4.5, "delayCount": 1, "companyScore": 4.3}','[{"key": "milestone", "label": "里程碑完成项", "value": "3/4", "weight": 30, "score": 22.5, "note": "已完成 3 项里程碑"}, {"key": "continuity", "label": "周报连续性", "value": "连续 7 周", "weight": 20, "score": 20.0, "note": "无缺交、无逾期"}, {"key": "attachment", "label": "附件数量", "value": "2 个", "weight": 15, "score": 15.0, "note": "附件数量满足要求"}, {"key": "feedback", "label": "导师反馈", "value": "4.5 分", "weight": 15, "score": 13.5, "note": "批阅及时，评语具体"}, {"key": "delay", "label": "延期任务", "value": "1 项", "weight": 10, "score": 6.0, "note": "接口联调延期 4 天"}, {"key": "company", "label": "企业评价", "value": "4.3 分", "weight": 10, "score": 8.6, "note": "企业导师月度评价"}]',78.2,'合格','将第 3 项里程碑拆分为两个子任务并提前一周排期；下周补充接口文档附件',NULL,NULL,NULL,NULL,7,'2026-10-24 09:00:00'),
(6,'吴承宇',3,'v3','{"weekNo": 8, "milestoneDone": 3, "milestoneTotal": 4, "continuityWeeks": 8, "attachmentCount": 2, "feedbackScore": 4.5, "delayCount": 1, "companyScore": 4.3}','[{"key": "milestone", "label": "里程碑完成项", "value": "3/4", "weight": 30, "score": 22.5, "note": "已完成 3 项里程碑"}, {"key": "continuity", "label": "周报连续性", "value": "连续 8 周", "weight": 20, "score": 20.0, "note": "无缺交、无逾期"}, {"key": "attachment", "label": "附件数量", "value": "2 个", "weight": 15, "score": 15.0, "note": "附件数量满足要求"}, {"key": "feedback", "label": "导师反馈", "value": "4.5 分", "weight": 15, "score": 13.5, "note": "批阅及时，评语具体"}, {"key": "delay", "label": "延期任务", "value": "1 项", "weight": 10, "score": 6.0, "note": "接口联调延期 4 天"}, {"key": "company", "label": "企业评价", "value": "4.3 分", "weight": 10, "score": 8.6, "note": "企业导师月度评价"}]',83.5,'良好','将第 3 项里程碑拆分为两个子任务并提前一周排期；下周补充接口文档附件',NULL,NULL,NULL,NULL,8,'2026-10-31 09:00:00'),
(7,'何书宁',3,'v3','{"weekNo": 6, "milestoneDone": 2, "milestoneTotal": 4, "continuityWeeks": 6, "attachmentCount": 2, "feedbackScore": 4.5, "delayCount": 1, "companyScore": 4.3}','[{"key": "milestone", "label": "里程碑完成项", "value": "2/4", "weight": 30, "score": 15.0, "note": "已完成 2 项里程碑"}, {"key": "continuity", "label": "周报连续性", "value": "连续 6 周", "weight": 20, "score": 20.0, "note": "无缺交、无逾期"}, {"key": "attachment", "label": "附件数量", "value": "2 个", "weight": 15, "score": 15.0, "note": "附件数量满足要求"}, {"key": "feedback", "label": "导师反馈", "value": "4.5 分", "weight": 15, "score": 13.5, "note": "批阅及时，评语具体"}, {"key": "delay", "label": "延期任务", "value": "1 项", "weight": 10, "score": 6.0, "note": "接口联调延期 4 天"}, {"key": "company", "label": "企业评价", "value": "4.3 分", "weight": 10, "score": 8.6, "note": "企业导师月度评价"}]',77.9,'合格','将第 3 项里程碑拆分为两个子任务并提前一周排期；下周补充接口文档附件',NULL,NULL,NULL,NULL,6,'2026-10-23 09:00:00'),
(7,'何书宁',3,'v3','{"weekNo": 7, "milestoneDone": 3, "milestoneTotal": 4, "continuityWeeks": 7, "attachmentCount": 2, "feedbackScore": 4.5, "delayCount": 1, "companyScore": 4.3}','[{"key": "milestone", "label": "里程碑完成项", "value": "3/4", "weight": 30, "score": 22.5, "note": "已完成 3 项里程碑"}, {"key": "continuity", "label": "周报连续性", "value": "连续 7 周", "weight": 20, "score": 20.0, "note": "无缺交、无逾期"}, {"key": "attachment", "label": "附件数量", "value": "2 个", "weight": 15, "score": 15.0, "note": "附件数量满足要求"}, {"key": "feedback", "label": "导师反馈", "value": "4.5 分", "weight": 15, "score": 13.5, "note": "批阅及时，评语具体"}, {"key": "delay", "label": "延期任务", "value": "1 项", "weight": 10, "score": 6.0, "note": "接口联调延期 4 天"}, {"key": "company", "label": "企业评价", "value": "4.3 分", "weight": 10, "score": 8.6, "note": "企业导师月度评价"}]',81.8,'良好','将第 3 项里程碑拆分为两个子任务并提前一周排期；下周补充接口文档附件',NULL,NULL,NULL,NULL,7,'2026-10-24 09:00:00'),
(7,'何书宁',3,'v3','{"weekNo": 8, "milestoneDone": 3, "milestoneTotal": 4, "continuityWeeks": 8, "attachmentCount": 2, "feedbackScore": 4.5, "delayCount": 1, "companyScore": 4.3}','[{"key": "milestone", "label": "里程碑完成项", "value": "3/4", "weight": 30, "score": 22.5, "note": "已完成 3 项里程碑"}, {"key": "continuity", "label": "周报连续性", "value": "连续 8 周", "weight": 20, "score": 20.0, "note": "无缺交、无逾期"}, {"key": "attachment", "label": "附件数量", "value": "2 个", "weight": 15, "score": 15.0, "note": "附件数量满足要求"}, {"key": "feedback", "label": "导师反馈", "value": "4.5 分", "weight": 15, "score": 13.5, "note": "批阅及时，评语具体"}, {"key": "delay", "label": "延期任务", "value": "1 项", "weight": 10, "score": 6.0, "note": "接口联调延期 4 天"}, {"key": "company", "label": "企业评价", "value": "4.3 分", "weight": 10, "score": 8.6, "note": "企业导师月度评价"}]',84.8,'良好','将第 3 项里程碑拆分为两个子任务并提前一周排期；下周补充接口文档附件','优秀','综合走访记录与企业反馈，实际表现优于计算结果','李明华','2026-10-31 15:20:00',8,'2026-10-31 09:00:00'),
(8,'郑亦航',3,'v3','{"weekNo": 6, "milestoneDone": 2, "milestoneTotal": 4, "continuityWeeks": 6, "attachmentCount": 2, "feedbackScore": 4.5, "delayCount": 1, "companyScore": 4.3}','[{"key": "milestone", "label": "里程碑完成项", "value": "2/4", "weight": 30, "score": 15.0, "note": "已完成 2 项里程碑"}, {"key": "continuity", "label": "周报连续性", "value": "连续 6 周", "weight": 20, "score": 20.0, "note": "无缺交、无逾期"}, {"key": "attachment", "label": "附件数量", "value": "2 个", "weight": 15, "score": 15.0, "note": "附件数量满足要求"}, {"key": "feedback", "label": "导师反馈", "value": "4.5 分", "weight": 15, "score": 13.5, "note": "批阅及时，评语具体"}, {"key": "delay", "label": "延期任务", "value": "1 项", "weight": 10, "score": 6.0, "note": "接口联调延期 4 天"}, {"key": "company", "label": "企业评价", "value": "4.3 分", "weight": 10, "score": 8.6, "note": "企业导师月度评价"}]',80.2,'良好','将第 3 项里程碑拆分为两个子任务并提前一周排期；下周补充接口文档附件',NULL,NULL,NULL,NULL,6,'2026-10-23 09:00:00'),
(8,'郑亦航',3,'v3','{"weekNo": 7, "milestoneDone": 3, "milestoneTotal": 4, "continuityWeeks": 7, "attachmentCount": 2, "feedbackScore": 4.5, "delayCount": 1, "companyScore": 4.3}','[{"key": "milestone", "label": "里程碑完成项", "value": "3/4", "weight": 30, "score": 22.5, "note": "已完成 3 项里程碑"}, {"key": "continuity", "label": "周报连续性", "value": "连续 7 周", "weight": 20, "score": 20.0, "note": "无缺交、无逾期"}, {"key": "attachment", "label": "附件数量", "value": "2 个", "weight": 15, "score": 15.0, "note": "附件数量满足要求"}, {"key": "feedback", "label": "导师反馈", "value": "4.5 分", "weight": 15, "score": 13.5, "note": "批阅及时，评语具体"}, {"key": "delay", "label": "延期任务", "value": "1 项", "weight": 10, "score": 6.0, "note": "接口联调延期 4 天"}, {"key": "company", "label": "企业评价", "value": "4.3 分", "weight": 10, "score": 8.6, "note": "企业导师月度评价"}]',86.2,'良好','将第 3 项里程碑拆分为两个子任务并提前一周排期；下周补充接口文档附件',NULL,NULL,NULL,NULL,7,'2026-10-24 09:00:00'),
(8,'郑亦航',3,'v3','{"weekNo": 8, "milestoneDone": 3, "milestoneTotal": 4, "continuityWeeks": 8, "attachmentCount": 2, "feedbackScore": 4.5, "delayCount": 1, "companyScore": 4.3}','[{"key": "milestone", "label": "里程碑完成项", "value": "3/4", "weight": 30, "score": 22.5, "note": "已完成 3 项里程碑"}, {"key": "continuity", "label": "周报连续性", "value": "连续 8 周", "weight": 20, "score": 20.0, "note": "无缺交、无逾期"}, {"key": "attachment", "label": "附件数量", "value": "2 个", "weight": 15, "score": 15.0, "note": "附件数量满足要求"}, {"key": "feedback", "label": "导师反馈", "value": "4.5 分", "weight": 15, "score": 13.5, "note": "批阅及时，评语具体"}, {"key": "delay", "label": "延期任务", "value": "1 项", "weight": 10, "score": 6.0, "note": "接口联调延期 4 天"}, {"key": "company", "label": "企业评价", "value": "4.3 分", "weight": 10, "score": 8.6, "note": "企业导师月度评价"}]',90.1,'优秀','将第 3 项里程碑拆分为两个子任务并提前一周排期；下周补充接口文档附件',NULL,NULL,NULL,NULL,8,'2026-10-31 09:00:00'),
(9,'徐乐言',3,'v3','{"weekNo": 6, "milestoneDone": 2, "milestoneTotal": 4, "continuityWeeks": 6, "attachmentCount": 2, "feedbackScore": 4.5, "delayCount": 1, "companyScore": 4.3}','[{"key": "milestone", "label": "里程碑完成项", "value": "2/4", "weight": 30, "score": 15.0, "note": "已完成 2 项里程碑"}, {"key": "continuity", "label": "周报连续性", "value": "连续 6 周", "weight": 20, "score": 20.0, "note": "无缺交、无逾期"}, {"key": "attachment", "label": "附件数量", "value": "2 个", "weight": 15, "score": 15.0, "note": "附件数量满足要求"}, {"key": "feedback", "label": "导师反馈", "value": "4.5 分", "weight": 15, "score": 13.5, "note": "批阅及时，评语具体"}, {"key": "delay", "label": "延期任务", "value": "1 项", "weight": 10, "score": 6.0, "note": "接口联调延期 4 天"}, {"key": "company", "label": "企业评价", "value": "4.3 分", "weight": 10, "score": 8.6, "note": "企业导师月度评价"}]',84.7,'良好','将第 3 项里程碑拆分为两个子任务并提前一周排期；下周补充接口文档附件',NULL,NULL,NULL,NULL,6,'2026-10-23 09:00:00'),
(9,'徐乐言',3,'v3','{"weekNo": 7, "milestoneDone": 3, "milestoneTotal": 4, "continuityWeeks": 7, "attachmentCount": 2, "feedbackScore": 4.5, "delayCount": 1, "companyScore": 4.3}','[{"key": "milestone", "label": "里程碑完成项", "value": "3/4", "weight": 30, "score": 22.5, "note": "已完成 3 项里程碑"}, {"key": "continuity", "label": "周报连续性", "value": "连续 7 周", "weight": 20, "score": 20.0, "note": "无缺交、无逾期"}, {"key": "attachment", "label": "附件数量", "value": "2 个", "weight": 15, "score": 15.0, "note": "附件数量满足要求"}, {"key": "feedback", "label": "导师反馈", "value": "4.5 分", "weight": 15, "score": 13.5, "note": "批阅及时，评语具体"}, {"key": "delay", "label": "延期任务", "value": "1 项", "weight": 10, "score": 6.0, "note": "接口联调延期 4 天"}, {"key": "company", "label": "企业评价", "value": "4.3 分", "weight": 10, "score": 8.6, "note": "企业导师月度评价"}]',88.8,'良好','将第 3 项里程碑拆分为两个子任务并提前一周排期；下周补充接口文档附件',NULL,NULL,NULL,NULL,7,'2026-10-24 09:00:00'),
(9,'徐乐言',3,'v3','{"weekNo": 8, "milestoneDone": 3, "milestoneTotal": 4, "continuityWeeks": 8, "attachmentCount": 2, "feedbackScore": 4.5, "delayCount": 1, "companyScore": 4.3}','[{"key": "milestone", "label": "里程碑完成项", "value": "3/4", "weight": 30, "score": 22.5, "note": "已完成 3 项里程碑"}, {"key": "continuity", "label": "周报连续性", "value": "连续 8 周", "weight": 20, "score": 20.0, "note": "无缺交、无逾期"}, {"key": "attachment", "label": "附件数量", "value": "2 个", "weight": 15, "score": 15.0, "note": "附件数量满足要求"}, {"key": "feedback", "label": "导师反馈", "value": "4.5 分", "weight": 15, "score": 13.5, "note": "批阅及时，评语具体"}, {"key": "delay", "label": "延期任务", "value": "1 项", "weight": 10, "score": 6.0, "note": "接口联调延期 4 天"}, {"key": "company", "label": "企业评价", "value": "4.3 分", "weight": 10, "score": 8.6, "note": "企业导师月度评价"}]',93.6,'优秀','将第 3 项里程碑拆分为两个子任务并提前一周排期；下周补充接口文档附件',NULL,NULL,NULL,NULL,8,'2026-10-31 09:00:00'),
(10,'孟祥宇',3,'v3','{"weekNo": 6, "milestoneDone": 2, "milestoneTotal": 4, "continuityWeeks": 6, "attachmentCount": 2, "feedbackScore": 4.5, "delayCount": 1, "companyScore": 4.3}','[{"key": "milestone", "label": "里程碑完成项", "value": "2/4", "weight": 30, "score": 15.0, "note": "已完成 2 项里程碑"}, {"key": "continuity", "label": "周报连续性", "value": "连续 6 周", "weight": 20, "score": 20.0, "note": "无缺交、无逾期"}, {"key": "attachment", "label": "附件数量", "value": "2 个", "weight": 15, "score": 15.0, "note": "附件数量满足要求"}, {"key": "feedback", "label": "导师反馈", "value": "4.5 分", "weight": 15, "score": 13.5, "note": "批阅及时，评语具体"}, {"key": "delay", "label": "延期任务", "value": "1 项", "weight": 10, "score": 6.0, "note": "接口联调延期 4 天"}, {"key": "company", "label": "企业评价", "value": "4.3 分", "weight": 10, "score": 8.6, "note": "企业导师月度评价"}]',70.4,'合格','将第 3 项里程碑拆分为两个子任务并提前一周排期；下周补充接口文档附件',NULL,NULL,NULL,NULL,6,'2026-10-23 09:00:00'),
(10,'孟祥宇',3,'v3','{"weekNo": 7, "milestoneDone": 3, "milestoneTotal": 4, "continuityWeeks": 7, "attachmentCount": 2, "feedbackScore": 4.5, "delayCount": 1, "companyScore": 4.3}','[{"key": "milestone", "label": "里程碑完成项", "value": "3/4", "weight": 30, "score": 22.5, "note": "已完成 3 项里程碑"}, {"key": "continuity", "label": "周报连续性", "value": "连续 7 周", "weight": 20, "score": 20.0, "note": "无缺交、无逾期"}, {"key": "attachment", "label": "附件数量", "value": "2 个", "weight": 15, "score": 15.0, "note": "附件数量满足要求"}, {"key": "feedback", "label": "导师反馈", "value": "4.5 分", "weight": 15, "score": 13.5, "note": "批阅及时，评语具体"}, {"key": "delay", "label": "延期任务", "value": "1 项", "weight": 10, "score": 6.0, "note": "接口联调延期 4 天"}, {"key": "company", "label": "企业评价", "value": "4.3 分", "weight": 10, "score": 8.6, "note": "企业导师月度评价"}]',74.3,'合格','将第 3 项里程碑拆分为两个子任务并提前一周排期；下周补充接口文档附件',NULL,NULL,NULL,NULL,7,'2026-10-24 09:00:00'),
(10,'孟祥宇',3,'v3','{"weekNo": 8, "milestoneDone": 3, "milestoneTotal": 4, "continuityWeeks": 8, "attachmentCount": 2, "feedbackScore": 4.5, "delayCount": 1, "companyScore": 4.3}','[{"key": "milestone", "label": "里程碑完成项", "value": "3/4", "weight": 30, "score": 22.5, "note": "已完成 3 项里程碑"}, {"key": "continuity", "label": "周报连续性", "value": "连续 8 周", "weight": 20, "score": 20.0, "note": "无缺交、无逾期"}, {"key": "attachment", "label": "附件数量", "value": "2 个", "weight": 15, "score": 15.0, "note": "附件数量满足要求"}, {"key": "feedback", "label": "导师反馈", "value": "4.5 分", "weight": 15, "score": 13.5, "note": "批阅及时，评语具体"}, {"key": "delay", "label": "延期任务", "value": "1 项", "weight": 10, "score": 6.0, "note": "接口联调延期 4 天"}, {"key": "company", "label": "企业评价", "value": "4.3 分", "weight": 10, "score": 8.6, "note": "企业导师月度评价"}]',76.5,'合格','将第 3 项里程碑拆分为两个子任务并提前一周排期；下周补充接口文档附件',NULL,NULL,NULL,NULL,8,'2026-10-31 09:00:00'),
(11,'方雨欣',3,'v3','{"weekNo": 6, "milestoneDone": 2, "milestoneTotal": 4, "continuityWeeks": 6, "attachmentCount": 2, "feedbackScore": 4.5, "delayCount": 1, "companyScore": 4.3}','[{"key": "milestone", "label": "里程碑完成项", "value": "2/4", "weight": 30, "score": 15.0, "note": "已完成 2 项里程碑"}, {"key": "continuity", "label": "周报连续性", "value": "连续 6 周", "weight": 20, "score": 20.0, "note": "无缺交、无逾期"}, {"key": "attachment", "label": "附件数量", "value": "2 个", "weight": 15, "score": 15.0, "note": "附件数量满足要求"}, {"key": "feedback", "label": "导师反馈", "value": "4.5 分", "weight": 15, "score": 13.5, "note": "批阅及时，评语具体"}, {"key": "delay", "label": "延期任务", "value": "1 项", "weight": 10, "score": 6.0, "note": "接口联调延期 4 天"}, {"key": "company", "label": "企业评价", "value": "4.3 分", "weight": 10, "score": 8.6, "note": "企业导师月度评价"}]',75.8,'合格','将第 3 项里程碑拆分为两个子任务并提前一周排期；下周补充接口文档附件',NULL,NULL,NULL,NULL,6,'2026-10-23 09:00:00'),
(11,'方雨欣',3,'v3','{"weekNo": 7, "milestoneDone": 3, "milestoneTotal": 4, "continuityWeeks": 7, "attachmentCount": 2, "feedbackScore": 4.5, "delayCount": 1, "companyScore": 4.3}','[{"key": "milestone", "label": "里程碑完成项", "value": "3/4", "weight": 30, "score": 22.5, "note": "已完成 3 项里程碑"}, {"key": "continuity", "label": "周报连续性", "value": "连续 7 周", "weight": 20, "score": 20.0, "note": "无缺交、无逾期"}, {"key": "attachment", "label": "附件数量", "value": "2 个", "weight": 15, "score": 15.0, "note": "附件数量满足要求"}, {"key": "feedback", "label": "导师反馈", "value": "4.5 分", "weight": 15, "score": 13.5, "note": "批阅及时，评语具体"}, {"key": "delay", "label": "延期任务", "value": "1 项", "weight": 10, "score": 6.0, "note": "接口联调延期 4 天"}, {"key": "company", "label": "企业评价", "value": "4.3 分", "weight": 10, "score": 8.6, "note": "企业导师月度评价"}]',77.7,'合格','将第 3 项里程碑拆分为两个子任务并提前一周排期；下周补充接口文档附件',NULL,NULL,NULL,NULL,7,'2026-10-24 09:00:00'),
(11,'方雨欣',3,'v3','{"weekNo": 8, "milestoneDone": 3, "milestoneTotal": 4, "continuityWeeks": 8, "attachmentCount": 2, "feedbackScore": 4.5, "delayCount": 1, "companyScore": 4.3}','[{"key": "milestone", "label": "里程碑完成项", "value": "3/4", "weight": 30, "score": 22.5, "note": "已完成 3 项里程碑"}, {"key": "continuity", "label": "周报连续性", "value": "连续 8 周", "weight": 20, "score": 20.0, "note": "无缺交、无逾期"}, {"key": "attachment", "label": "附件数量", "value": "2 个", "weight": 15, "score": 15.0, "note": "附件数量满足要求"}, {"key": "feedback", "label": "导师反馈", "value": "4.5 分", "weight": 15, "score": 13.5, "note": "批阅及时，评语具体"}, {"key": "delay", "label": "延期任务", "value": "1 项", "weight": 10, "score": 6.0, "note": "接口联调延期 4 天"}, {"key": "company", "label": "企业评价", "value": "4.3 分", "weight": 10, "score": 8.6, "note": "企业导师月度评价"}]',82.3,'良好','将第 3 项里程碑拆分为两个子任务并提前一周排期；下周补充接口文档附件',NULL,NULL,NULL,NULL,8,'2026-10-31 09:00:00'),
(12,'谭嘉懿',3,'v3','{"weekNo": 6, "milestoneDone": 2, "milestoneTotal": 4, "continuityWeeks": 6, "attachmentCount": 2, "feedbackScore": 4.5, "delayCount": 1, "companyScore": 4.3}','[{"key": "milestone", "label": "里程碑完成项", "value": "2/4", "weight": 30, "score": 15.0, "note": "已完成 2 项里程碑"}, {"key": "continuity", "label": "周报连续性", "value": "连续 6 周", "weight": 20, "score": 20.0, "note": "无缺交、无逾期"}, {"key": "attachment", "label": "附件数量", "value": "2 个", "weight": 15, "score": 15.0, "note": "附件数量满足要求"}, {"key": "feedback", "label": "导师反馈", "value": "4.5 分", "weight": 15, "score": 13.5, "note": "批阅及时，评语具体"}, {"key": "delay", "label": "延期任务", "value": "1 项", "weight": 10, "score": 6.0, "note": "接口联调延期 4 天"}, {"key": "company", "label": "企业评价", "value": "4.3 分", "weight": 10, "score": 8.6, "note": "企业导师月度评价"}]',79.0,'合格','将第 3 项里程碑拆分为两个子任务并提前一周排期；下周补充接口文档附件',NULL,NULL,NULL,NULL,6,'2026-10-23 09:00:00'),
(12,'谭嘉懿',3,'v3','{"weekNo": 7, "milestoneDone": 3, "milestoneTotal": 4, "continuityWeeks": 7, "attachmentCount": 2, "feedbackScore": 4.5, "delayCount": 1, "companyScore": 4.3}','[{"key": "milestone", "label": "里程碑完成项", "value": "3/4", "weight": 30, "score": 22.5, "note": "已完成 3 项里程碑"}, {"key": "continuity", "label": "周报连续性", "value": "连续 7 周", "weight": 20, "score": 20.0, "note": "无缺交、无逾期"}, {"key": "attachment", "label": "附件数量", "value": "2 个", "weight": 15, "score": 15.0, "note": "附件数量满足要求"}, {"key": "feedback", "label": "导师反馈", "value": "4.5 分", "weight": 15, "score": 13.5, "note": "批阅及时，评语具体"}, {"key": "delay", "label": "延期任务", "value": "1 项", "weight": 10, "score": 6.0, "note": "接口联调延期 4 天"}, {"key": "company", "label": "企业评价", "value": "4.3 分", "weight": 10, "score": 8.6, "note": "企业导师月度评价"}]',82.7,'良好','将第 3 项里程碑拆分为两个子任务并提前一周排期；下周补充接口文档附件',NULL,NULL,NULL,NULL,7,'2026-10-24 09:00:00'),
(12,'谭嘉懿',3,'v3','{"weekNo": 8, "milestoneDone": 3, "milestoneTotal": 4, "continuityWeeks": 8, "attachmentCount": 2, "feedbackScore": 4.5, "delayCount": 1, "companyScore": 4.3}','[{"key": "milestone", "label": "里程碑完成项", "value": "3/4", "weight": 30, "score": 22.5, "note": "已完成 3 项里程碑"}, {"key": "continuity", "label": "周报连续性", "value": "连续 8 周", "weight": 20, "score": 20.0, "note": "无缺交、无逾期"}, {"key": "attachment", "label": "附件数量", "value": "2 个", "weight": 15, "score": 15.0, "note": "附件数量满足要求"}, {"key": "feedback", "label": "导师反馈", "value": "4.5 分", "weight": 15, "score": 13.5, "note": "批阅及时，评语具体"}, {"key": "delay", "label": "延期任务", "value": "1 项", "weight": 10, "score": 6.0, "note": "接口联调延期 4 天"}, {"key": "company", "label": "企业评价", "value": "4.3 分", "weight": 10, "score": 8.6, "note": "企业导师月度评价"}]',85.7,'良好','将第 3 项里程碑拆分为两个子任务并提前一周排期；下周补充接口文档附件',NULL,NULL,NULL,NULL,8,'2026-10-31 09:00:00'),
(13,'陈知远',3,'v3','{"weekNo": 6, "milestoneDone": 2, "milestoneTotal": 4, "continuityWeeks": 6, "attachmentCount": 2, "feedbackScore": 4.5, "delayCount": 1, "companyScore": 4.3}','[{"key": "milestone", "label": "里程碑完成项", "value": "2/4", "weight": 30, "score": 15.0, "note": "已完成 2 项里程碑"}, {"key": "continuity", "label": "周报连续性", "value": "连续 6 周", "weight": 20, "score": 20.0, "note": "无缺交、无逾期"}, {"key": "attachment", "label": "附件数量", "value": "2 个", "weight": 15, "score": 15.0, "note": "附件数量满足要求"}, {"key": "feedback", "label": "导师反馈", "value": "4.5 分", "weight": 15, "score": 13.5, "note": "批阅及时，评语具体"}, {"key": "delay", "label": "延期任务", "value": "1 项", "weight": 10, "score": 6.0, "note": "接口联调延期 4 天"}, {"key": "company", "label": "企业评价", "value": "4.3 分", "weight": 10, "score": 8.6, "note": "企业导师月度评价"}]',82.5,'良好','将第 3 项里程碑拆分为两个子任务并提前一周排期；下周补充接口文档附件',NULL,NULL,NULL,NULL,6,'2026-10-23 09:00:00'),
(13,'陈知远',3,'v3','{"weekNo": 7, "milestoneDone": 3, "milestoneTotal": 4, "continuityWeeks": 7, "attachmentCount": 2, "feedbackScore": 4.5, "delayCount": 1, "companyScore": 4.3}','[{"key": "milestone", "label": "里程碑完成项", "value": "3/4", "weight": 30, "score": 22.5, "note": "已完成 3 项里程碑"}, {"key": "continuity", "label": "周报连续性", "value": "连续 7 周", "weight": 20, "score": 20.0, "note": "无缺交、无逾期"}, {"key": "attachment", "label": "附件数量", "value": "2 个", "weight": 15, "score": 15.0, "note": "附件数量满足要求"}, {"key": "feedback", "label": "导师反馈", "value": "4.5 分", "weight": 15, "score": 13.5, "note": "批阅及时，评语具体"}, {"key": "delay", "label": "延期任务", "value": "1 项", "weight": 10, "score": 6.0, "note": "接口联调延期 4 天"}, {"key": "company", "label": "企业评价", "value": "4.3 分", "weight": 10, "score": 8.6, "note": "企业导师月度评价"}]',87.8,'良好','将第 3 项里程碑拆分为两个子任务并提前一周排期；下周补充接口文档附件',NULL,NULL,NULL,NULL,7,'2026-10-24 09:00:00'),
(13,'陈知远',3,'v3','{"weekNo": 8, "milestoneDone": 3, "milestoneTotal": 4, "continuityWeeks": 8, "attachmentCount": 2, "feedbackScore": 4.5, "delayCount": 1, "companyScore": 4.3}','[{"key": "milestone", "label": "里程碑完成项", "value": "3/4", "weight": 30, "score": 22.5, "note": "已完成 3 项里程碑"}, {"key": "continuity", "label": "周报连续性", "value": "连续 8 周", "weight": 20, "score": 20.0, "note": "无缺交、无逾期"}, {"key": "attachment", "label": "附件数量", "value": "2 个", "weight": 15, "score": 15.0, "note": "附件数量满足要求"}, {"key": "feedback", "label": "导师反馈", "value": "4.5 分", "weight": 15, "score": 13.5, "note": "批阅及时，评语具体"}, {"key": "delay", "label": "延期任务", "value": "1 项", "weight": 10, "score": 6.0, "note": "接口联调延期 4 天"}, {"key": "company", "label": "企业评价", "value": "4.3 分", "weight": 10, "score": 8.6, "note": "企业导师月度评价"}]',90.0,'优秀','将第 3 项里程碑拆分为两个子任务并提前一周排期；下周补充接口文档附件',NULL,NULL,NULL,NULL,8,'2026-10-31 09:00:00'),
(14,'宋雨桐',3,'v3','{"weekNo": 6, "milestoneDone": 2, "milestoneTotal": 4, "continuityWeeks": 6, "attachmentCount": 2, "feedbackScore": 4.5, "delayCount": 1, "companyScore": 4.3}','[{"key": "milestone", "label": "里程碑完成项", "value": "2/4", "weight": 30, "score": 15.0, "note": "已完成 2 项里程碑"}, {"key": "continuity", "label": "周报连续性", "value": "连续 6 周", "weight": 20, "score": 20.0, "note": "无缺交、无逾期"}, {"key": "attachment", "label": "附件数量", "value": "2 个", "weight": 15, "score": 15.0, "note": "附件数量满足要求"}, {"key": "feedback", "label": "导师反馈", "value": "4.5 分", "weight": 15, "score": 13.5, "note": "批阅及时，评语具体"}, {"key": "delay", "label": "延期任务", "value": "1 项", "weight": 10, "score": 6.0, "note": "接口联调延期 4 天"}, {"key": "company", "label": "企业评价", "value": "4.3 分", "weight": 10, "score": 8.6, "note": "企业导师月度评价"}]',84.4,'良好','将第 3 项里程碑拆分为两个子任务并提前一周排期；下周补充接口文档附件',NULL,NULL,NULL,NULL,6,'2026-10-23 09:00:00'),
(14,'宋雨桐',3,'v3','{"weekNo": 7, "milestoneDone": 3, "milestoneTotal": 4, "continuityWeeks": 7, "attachmentCount": 2, "feedbackScore": 4.5, "delayCount": 1, "companyScore": 4.3}','[{"key": "milestone", "label": "里程碑完成项", "value": "3/4", "weight": 30, "score": 22.5, "note": "已完成 3 项里程碑"}, {"key": "continuity", "label": "周报连续性", "value": "连续 7 周", "weight": 20, "score": 20.0, "note": "无缺交、无逾期"}, {"key": "attachment", "label": "附件数量", "value": "2 个", "weight": 15, "score": 15.0, "note": "附件数量满足要求"}, {"key": "feedback", "label": "导师反馈", "value": "4.5 分", "weight": 15, "score": 13.5, "note": "批阅及时，评语具体"}, {"key": "delay", "label": "延期任务", "value": "1 项", "weight": 10, "score": 6.0, "note": "接口联调延期 4 天"}, {"key": "company", "label": "企业评价", "value": "4.3 分", "weight": 10, "score": 8.6, "note": "企业导师月度评价"}]',90.5,'优秀','将第 3 项里程碑拆分为两个子任务并提前一周排期；下周补充接口文档附件',NULL,NULL,NULL,NULL,7,'2026-10-24 09:00:00'),
(14,'宋雨桐',3,'v3','{"weekNo": 8, "milestoneDone": 3, "milestoneTotal": 4, "continuityWeeks": 8, "attachmentCount": 2, "feedbackScore": 4.5, "delayCount": 1, "companyScore": 4.3}','[{"key": "milestone", "label": "里程碑完成项", "value": "3/4", "weight": 30, "score": 22.5, "note": "已完成 3 项里程碑"}, {"key": "continuity", "label": "周报连续性", "value": "连续 8 周", "weight": 20, "score": 20.0, "note": "无缺交、无逾期"}, {"key": "attachment", "label": "附件数量", "value": "2 个", "weight": 15, "score": 15.0, "note": "附件数量满足要求"}, {"key": "feedback", "label": "导师反馈", "value": "4.5 分", "weight": 15, "score": 13.5, "note": "批阅及时，评语具体"}, {"key": "delay", "label": "延期任务", "value": "1 项", "weight": 10, "score": 6.0, "note": "接口联调延期 4 天"}, {"key": "company", "label": "企业评价", "value": "4.3 分", "weight": 10, "score": 8.6, "note": "企业导师月度评价"}]',93.3,'优秀','将第 3 项里程碑拆分为两个子任务并提前一周排期；下周补充接口文档附件','良好','综合走访记录与企业反馈，实际表现优于计算结果','李明华','2026-10-31 15:20:00',8,'2026-10-31 09:00:00'),
(15,'周若菡',3,'v3','{"weekNo": 6, "milestoneDone": 2, "milestoneTotal": 4, "continuityWeeks": 6, "attachmentCount": 2, "feedbackScore": 4.5, "delayCount": 1, "companyScore": 4.3}','[{"key": "milestone", "label": "里程碑完成项", "value": "2/4", "weight": 30, "score": 15.0, "note": "已完成 2 项里程碑"}, {"key": "continuity", "label": "周报连续性", "value": "连续 6 周", "weight": 20, "score": 20.0, "note": "无缺交、无逾期"}, {"key": "attachment", "label": "附件数量", "value": "2 个", "weight": 15, "score": 15.0, "note": "附件数量满足要求"}, {"key": "feedback", "label": "导师反馈", "value": "4.5 分", "weight": 15, "score": 13.5, "note": "批阅及时，评语具体"}, {"key": "delay", "label": "延期任务", "value": "1 项", "weight": 10, "score": 6.0, "note": "接口联调延期 4 天"}, {"key": "company", "label": "企业评价", "value": "4.3 分", "weight": 10, "score": 8.6, "note": "企业导师月度评价"}]',69.3,'合格','将第 3 项里程碑拆分为两个子任务并提前一周排期；下周补充接口文档附件',NULL,NULL,NULL,NULL,6,'2026-10-23 09:00:00'),
(15,'周若菡',3,'v3','{"weekNo": 7, "milestoneDone": 3, "milestoneTotal": 4, "continuityWeeks": 7, "attachmentCount": 2, "feedbackScore": 4.5, "delayCount": 1, "companyScore": 4.3}','[{"key": "milestone", "label": "里程碑完成项", "value": "3/4", "weight": 30, "score": 22.5, "note": "已完成 3 项里程碑"}, {"key": "continuity", "label": "周报连续性", "value": "连续 7 周", "weight": 20, "score": 20.0, "note": "无缺交、无逾期"}, {"key": "attachment", "label": "附件数量", "value": "2 个", "weight": 15, "score": 15.0, "note": "附件数量满足要求"}, {"key": "feedback", "label": "导师反馈", "value": "4.5 分", "weight": 15, "score": 13.5, "note": "批阅及时，评语具体"}, {"key": "delay", "label": "延期任务", "value": "1 项", "weight": 10, "score": 6.0, "note": "接口联调延期 4 天"}, {"key": "company", "label": "企业评价", "value": "4.3 分", "weight": 10, "score": 8.6, "note": "企业导师月度评价"}]',72.8,'合格','将第 3 项里程碑拆分为两个子任务并提前一周排期；下周补充接口文档附件',NULL,NULL,NULL,NULL,7,'2026-10-24 09:00:00'),
(15,'周若菡',3,'v3','{"weekNo": 8, "milestoneDone": 3, "milestoneTotal": 4, "continuityWeeks": 8, "attachmentCount": 2, "feedbackScore": 4.5, "delayCount": 1, "companyScore": 4.3}','[{"key": "milestone", "label": "里程碑完成项", "value": "3/4", "weight": 30, "score": 22.5, "note": "已完成 3 项里程碑"}, {"key": "continuity", "label": "周报连续性", "value": "连续 8 周", "weight": 20, "score": 20.0, "note": "无缺交、无逾期"}, {"key": "attachment", "label": "附件数量", "value": "2 个", "weight": 15, "score": 15.0, "note": "附件数量满足要求"}, {"key": "feedback", "label": "导师反馈", "value": "4.5 分", "weight": 15, "score": 13.5, "note": "批阅及时，评语具体"}, {"key": "delay", "label": "延期任务", "value": "1 项", "weight": 10, "score": 6.0, "note": "接口联调延期 4 天"}, {"key": "company", "label": "企业评价", "value": "4.3 分", "weight": 10, "score": 8.6, "note": "企业导师月度评价"}]',78.7,'合格','将第 3 项里程碑拆分为两个子任务并提前一周排期；下周补充接口文档附件',NULL,NULL,NULL,NULL,8,'2026-10-31 09:00:00'),
(18,'吴承宇',3,'v3','{"weekNo": 6, "milestoneDone": 2, "milestoneTotal": 4, "continuityWeeks": 6, "attachmentCount": 2, "feedbackScore": 4.5, "delayCount": 1, "companyScore": 4.3}','[{"key": "milestone", "label": "里程碑完成项", "value": "2/4", "weight": 30, "score": 15.0, "note": "已完成 2 项里程碑"}, {"key": "continuity", "label": "周报连续性", "value": "连续 6 周", "weight": 20, "score": 20.0, "note": "无缺交、无逾期"}, {"key": "attachment", "label": "附件数量", "value": "2 个", "weight": 15, "score": 15.0, "note": "附件数量满足要求"}, {"key": "feedback", "label": "导师反馈", "value": "4.5 分", "weight": 15, "score": 13.5, "note": "批阅及时，评语具体"}, {"key": "delay", "label": "延期任务", "value": "1 项", "weight": 10, "score": 6.0, "note": "接口联调延期 4 天"}, {"key": "company", "label": "企业评价", "value": "4.3 分", "weight": 10, "score": 8.6, "note": "企业导师月度评价"}]',82.4,'良好','将第 3 项里程碑拆分为两个子任务并提前一周排期；下周补充接口文档附件',NULL,NULL,NULL,NULL,6,'2026-10-23 09:00:00'),
(18,'吴承宇',3,'v3','{"weekNo": 7, "milestoneDone": 3, "milestoneTotal": 4, "continuityWeeks": 7, "attachmentCount": 2, "feedbackScore": 4.5, "delayCount": 1, "companyScore": 4.3}','[{"key": "milestone", "label": "里程碑完成项", "value": "3/4", "weight": 30, "score": 22.5, "note": "已完成 3 项里程碑"}, {"key": "continuity", "label": "周报连续性", "value": "连续 7 周", "weight": 20, "score": 20.0, "note": "无缺交、无逾期"}, {"key": "attachment", "label": "附件数量", "value": "2 个", "weight": 15, "score": 15.0, "note": "附件数量满足要求"}, {"key": "feedback", "label": "导师反馈", "value": "4.5 分", "weight": 15, "score": 13.5, "note": "批阅及时，评语具体"}, {"key": "delay", "label": "延期任务", "value": "1 项", "weight": 10, "score": 6.0, "note": "接口联调延期 4 天"}, {"key": "company", "label": "企业评价", "value": "4.3 分", "weight": 10, "score": 8.6, "note": "企业导师月度评价"}]',87.6,'良好','将第 3 项里程碑拆分为两个子任务并提前一周排期；下周补充接口文档附件',NULL,NULL,NULL,NULL,7,'2026-10-24 09:00:00'),
(18,'吴承宇',3,'v3','{"weekNo": 8, "milestoneDone": 3, "milestoneTotal": 4, "continuityWeeks": 8, "attachmentCount": 2, "feedbackScore": 4.5, "delayCount": 1, "companyScore": 4.3}','[{"key": "milestone", "label": "里程碑完成项", "value": "3/4", "weight": 30, "score": 22.5, "note": "已完成 3 项里程碑"}, {"key": "continuity", "label": "周报连续性", "value": "连续 8 周", "weight": 20, "score": 20.0, "note": "无缺交、无逾期"}, {"key": "attachment", "label": "附件数量", "value": "2 个", "weight": 15, "score": 15.0, "note": "附件数量满足要求"}, {"key": "feedback", "label": "导师反馈", "value": "4.5 分", "weight": 15, "score": 13.5, "note": "批阅及时，评语具体"}, {"key": "delay", "label": "延期任务", "value": "1 项", "weight": 10, "score": 6.0, "note": "接口联调延期 4 天"}, {"key": "company", "label": "企业评价", "value": "4.3 分", "weight": 10, "score": 8.6, "note": "企业导师月度评价"}]',88.8,'良好','将第 3 项里程碑拆分为两个子任务并提前一周排期；下周补充接口文档附件',NULL,NULL,NULL,NULL,8,'2026-10-31 09:00:00'),
(19,'孟祥宇',3,'v3','{"weekNo": 6, "milestoneDone": 2, "milestoneTotal": 4, "continuityWeeks": 6, "attachmentCount": 2, "feedbackScore": 4.5, "delayCount": 1, "companyScore": 4.3}','[{"key": "milestone", "label": "里程碑完成项", "value": "2/4", "weight": 30, "score": 15.0, "note": "已完成 2 项里程碑"}, {"key": "continuity", "label": "周报连续性", "value": "连续 6 周", "weight": 20, "score": 20.0, "note": "无缺交、无逾期"}, {"key": "attachment", "label": "附件数量", "value": "2 个", "weight": 15, "score": 15.0, "note": "附件数量满足要求"}, {"key": "feedback", "label": "导师反馈", "value": "4.5 分", "weight": 15, "score": 13.5, "note": "批阅及时，评语具体"}, {"key": "delay", "label": "延期任务", "value": "1 项", "weight": 10, "score": 6.0, "note": "接口联调延期 4 天"}, {"key": "company", "label": "企业评价", "value": "4.3 分", "weight": 10, "score": 8.6, "note": "企业导师月度评价"}]',85.9,'良好','将第 3 项里程碑拆分为两个子任务并提前一周排期；下周补充接口文档附件',NULL,NULL,NULL,NULL,6,'2026-10-23 09:00:00'),
(19,'孟祥宇',3,'v3','{"weekNo": 7, "milestoneDone": 3, "milestoneTotal": 4, "continuityWeeks": 7, "attachmentCount": 2, "feedbackScore": 4.5, "delayCount": 1, "companyScore": 4.3}','[{"key": "milestone", "label": "里程碑完成项", "value": "3/4", "weight": 30, "score": 22.5, "note": "已完成 3 项里程碑"}, {"key": "continuity", "label": "周报连续性", "value": "连续 7 周", "weight": 20, "score": 20.0, "note": "无缺交、无逾期"}, {"key": "attachment", "label": "附件数量", "value": "2 个", "weight": 15, "score": 15.0, "note": "附件数量满足要求"}, {"key": "feedback", "label": "导师反馈", "value": "4.5 分", "weight": 15, "score": 13.5, "note": "批阅及时，评语具体"}, {"key": "delay", "label": "延期任务", "value": "1 项", "weight": 10, "score": 6.0, "note": "接口联调延期 4 天"}, {"key": "company", "label": "企业评价", "value": "4.3 分", "weight": 10, "score": 8.6, "note": "企业导师月度评价"}]',89.7,'良好','将第 3 项里程碑拆分为两个子任务并提前一周排期；下周补充接口文档附件',NULL,NULL,NULL,NULL,7,'2026-10-24 09:00:00'),
(19,'孟祥宇',3,'v3','{"weekNo": 8, "milestoneDone": 3, "milestoneTotal": 4, "continuityWeeks": 8, "attachmentCount": 2, "feedbackScore": 4.5, "delayCount": 1, "companyScore": 4.3}','[{"key": "milestone", "label": "里程碑完成项", "value": "3/4", "weight": 30, "score": 22.5, "note": "已完成 3 项里程碑"}, {"key": "continuity", "label": "周报连续性", "value": "连续 8 周", "weight": 20, "score": 20.0, "note": "无缺交、无逾期"}, {"key": "attachment", "label": "附件数量", "value": "2 个", "weight": 15, "score": 15.0, "note": "附件数量满足要求"}, {"key": "feedback", "label": "导师反馈", "value": "4.5 分", "weight": 15, "score": 13.5, "note": "批阅及时，评语具体"}, {"key": "delay", "label": "延期任务", "value": "1 项", "weight": 10, "score": 6.0, "note": "接口联调延期 4 天"}, {"key": "company", "label": "企业评价", "value": "4.3 分", "weight": 10, "score": 8.6, "note": "企业导师月度评价"}]',95.8,'优秀','将第 3 项里程碑拆分为两个子任务并提前一周排期；下周补充接口文档附件',NULL,NULL,NULL,NULL,8,'2026-10-31 09:00:00');

-- 站内消息
INSERT INTO sys_message (title,content,msg_type,biz_no,link_url,receiver_id,is_read,create_time) VALUES 
('SI20260031 陈知远 提交实习备案，等待审核','实习备案待审核，请于 2 个工作日内处理','待审批','SI20260031','/application',1,00,'2026-10-31 09:12:00'),('WR20261030007 周报被退修：附件缺少测试记录','已标注缺项，学生需补充后重新提交','已退回','WR20261030007','/report',9,00,'2026-10-30 20:15:00'),('第 9 周周报将于 11-08 23:59 截止','请按时提交本周周报','即将超时','B2026S1','/report',9,00,'2026-10-30 08:00:00'),('CH20261018003 中止实习变更已生效','档案已转为已中止，材料已归档','处理完成','CH20261018003','/change',9,01,'2026-10-19 10:22:00'),('IS20261029001 薪资争议等待处置','已现场走访，等待企业整改回执','待审批','IS20261029001','/issue',1,01,'2026-10-31 10:35:00'),('10 月考勤已录入，请学生确认','应出勤 22 天，实出勤 21 天','待审批','AT202610001','/attendance',1,00,'2026-10-30 18:00:00');

-- 操作日志
INSERT INTO sys_log (user_id,user_name,action,method,params,cost_ms,create_time) VALUES 
(1,'李明华','登录系统','POST /api/auth/login','业务编号 SI20260030',435,'2026-10-31 20:00:00'),
(2,'林致远','提交实习备案','POST /api/application','业务编号 SI20260031',110,'2026-10-31 15:00:00'),
(3,'林致远','批阅周报','POST /api/report/review','业务编号 SI20260032',191,'2026-10-31 10:00:00'),
(4,'李明华','导入企业库','POST /api/company/import','业务编号 SI20260033',298,'2026-10-31 05:00:00'),
(5,'林致远','执行完整度计算','POST /api/score/evaluate','业务编号 SI20260034',227,'2026-10-31 00:00:00'),
(6,'林致远','分配角色菜单','POST /api/system/role/teacher/menus','业务编号 SI20260035',42,'2026-10-30 19:00:00'),
(7,'李明华','确认考勤','POST /api/attendance/confirm','业务编号 SI20260036',402,'2026-10-30 14:00:00'),
(8,'林致远','导出统计报表','GET /api/dashboard/export','业务编号 SI20260037',374,'2026-10-30 09:00:00'),
(1,'林致远','登录系统','POST /api/auth/login','业务编号 SI20260030',162,'2026-10-30 04:00:00'),
(2,'李明华','提交实习备案','POST /api/application','业务编号 SI20260031',192,'2026-10-29 23:00:00'),
(3,'林致远','批阅周报','POST /api/report/review','业务编号 SI20260032',454,'2026-10-29 18:00:00'),
(4,'林致远','导入企业库','POST /api/company/import','业务编号 SI20260033',342,'2026-10-29 13:00:00'),
(5,'李明华','执行完整度计算','POST /api/score/evaluate','业务编号 SI20260034',123,'2026-10-29 08:00:00'),
(6,'林致远','分配角色菜单','POST /api/system/role/teacher/menus','业务编号 SI20260035',157,'2026-10-29 03:00:00'),
(7,'林致远','确认考勤','POST /api/attendance/confirm','业务编号 SI20260036',475,'2026-10-28 22:00:00'),
(8,'李明华','导出统计报表','GET /api/dashboard/export','业务编号 SI20260037',201,'2026-10-28 17:00:00'),
(1,'林致远','登录系统','POST /api/auth/login','业务编号 SI20260030',302,'2026-10-28 12:00:00'),
(2,'林致远','提交实习备案','POST /api/application','业务编号 SI20260031',474,'2026-10-28 07:00:00'),
(3,'李明华','批阅周报','POST /api/report/review','业务编号 SI20260032',388,'2026-10-28 02:00:00'),
(4,'林致远','导入企业库','POST /api/company/import','业务编号 SI20260033',110,'2026-10-27 21:00:00'),
(5,'林致远','执行完整度计算','POST /api/score/evaluate','业务编号 SI20260034',315,'2026-10-27 16:00:00'),
(6,'李明华','分配角色菜单','POST /api/system/role/teacher/menus','业务编号 SI20260035',302,'2026-10-27 11:00:00'),
(7,'林致远','确认考勤','POST /api/attendance/confirm','业务编号 SI20260036',425,'2026-10-27 06:00:00'),
(8,'林致远','导出统计报表','GET /api/dashboard/export','业务编号 SI20260037',240,'2026-10-27 01:00:00'),
(1,'李明华','登录系统','POST /api/auth/login','业务编号 SI20260030',362,'2026-10-26 20:00:00'),
(2,'林致远','提交实习备案','POST /api/application','业务编号 SI20260031',347,'2026-10-26 15:00:00'),
(3,'林致远','批阅周报','POST /api/report/review','业务编号 SI20260032',282,'2026-10-26 10:00:00'),
(4,'李明华','导入企业库','POST /api/company/import','业务编号 SI20260033',76,'2026-10-26 05:00:00'),
(5,'林致远','执行完整度计算','POST /api/score/evaluate','业务编号 SI20260034',226,'2026-10-26 00:00:00'),
(6,'林致远','分配角色菜单','POST /api/system/role/teacher/menus','业务编号 SI20260035',32,'2026-10-25 19:00:00'),
(7,'李明华','确认考勤','POST /api/attendance/confirm','业务编号 SI20260036',432,'2026-10-25 14:00:00'),
(8,'林致远','导出统计报表','GET /api/dashboard/export','业务编号 SI20260037',316,'2026-10-25 09:00:00'),
(1,'林致远','登录系统','POST /api/auth/login','业务编号 SI20260030',316,'2026-10-25 04:00:00'),
(2,'李明华','提交实习备案','POST /api/application','业务编号 SI20260031',272,'2026-10-24 23:00:00'),
(3,'林致远','批阅周报','POST /api/report/review','业务编号 SI20260032',416,'2026-10-24 18:00:00'),
(4,'林致远','导入企业库','POST /api/company/import','业务编号 SI20260033',41,'2026-10-24 13:00:00'),
(5,'李明华','执行完整度计算','POST /api/score/evaluate','业务编号 SI20260034',46,'2026-10-24 08:00:00'),
(6,'林致远','分配角色菜单','POST /api/system/role/teacher/menus','业务编号 SI20260035',80,'2026-10-24 03:00:00'),
(7,'林致远','确认考勤','POST /api/attendance/confirm','业务编号 SI20260036',348,'2026-10-23 22:00:00'),
(8,'李明华','导出统计报表','GET /api/dashboard/export','业务编号 SI20260037',139,'2026-10-23 17:00:00');
