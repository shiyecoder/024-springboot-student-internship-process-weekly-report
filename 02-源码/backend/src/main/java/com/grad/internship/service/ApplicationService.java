package com.grad.internship.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.grad.internship.common.BizException;
import com.grad.internship.common.PageResult;
import com.grad.internship.common.UserContext;
import com.grad.internship.entity.*;
import com.grad.internship.mapper.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;

/**
 * 实习档案：列表、详情、新建、编辑、状态流转。
 *
 * 状态机（需求文档第 5 节）：
 *   实习备案 → 协议审核 → 过程周报 → 阶段检查 → 企业评价 → 学校归档，任一阶段可转「已中止」。
 * 所有流转都必须是相邻一步或转中止，禁止越级；且必须填写 ≥5 字的原因，留痕到 transition_reason 与操作日志。
 */
@Service
@RequiredArgsConstructor
public class ApplicationService {

    private final InternshipApplicationMapper appMapper;
    private final InternshipMilestoneMapper milestoneMapper;
    private final WeeklyReportMapper reportMapper;
    private final MonthlyAttendanceMapper attendanceMapper;
    private final InternshipChangeMapper changeMapper;
    private final InternshipIssueMapper issueMapper;
    private final VisitRecordMapper visitMapper;
    private final FinalEvaluationMapper evalMapper;
    private final SysLogMapper logMapper;
    private final SysMessageMapper messageMapper;

    /** 合法阶段顺序，用于校验「不得越级」 */
    private static final List<String> STAGES = List.of(
            "实习备案", "协议审核", "过程周报", "阶段检查", "企业评价", "学校归档");

    public PageResult<Map<String, Object>> page(int page, int size, String keyword, String department,
                                                String company, String position, String stage,
                                                String reportStatus, String startDate, String endDate) {
        LambdaQueryWrapper<InternshipApplication> q = new LambdaQueryWrapper<>();
        q.eq(InternshipApplication::getDeleted, 0);
        if (StringUtils.hasText(keyword)) {
            q.and(w -> w.like(InternshipApplication::getInternshipNo, keyword)
                    .or().like(InternshipApplication::getStudentName, keyword));
        }
        q.eq(StringUtils.hasText(department), InternshipApplication::getMajor, department);
        q.like(StringUtils.hasText(company), InternshipApplication::getCompanyName, company);
        q.like(StringUtils.hasText(position), InternshipApplication::getPosition, position);
        q.eq(StringUtils.hasText(stage), InternshipApplication::getStage, stage);
        q.eq(StringUtils.hasText(reportStatus), InternshipApplication::getReportStatus, reportStatus);
        q.ge(StringUtils.hasText(startDate), InternshipApplication::getStartDate, startDate);
        q.le(StringUtils.hasText(endDate), InternshipApplication::getEndDate, endDate);
        // 学生只能看到本人档案；教师看本人指导学生；企业导师看本人负责学生；管理员全量
        String role = UserContext.roleCode();
        if ("student".equals(role)) {
            q.eq(InternshipApplication::getStudentId, UserContext.userId());
        } else if ("teacher".equals(role)) {
            q.eq(InternshipApplication::getTeacherId, UserContext.userId());
        } else if ("mentor".equals(role)) {
            q.eq(InternshipApplication::getMentorId, UserContext.userId());
        }
        q.orderByDesc(InternshipApplication::getUpdateTime);
        Page<InternshipApplication> p = appMapper.selectPage(new Page<>(page, size), q);
        List<Map<String, Object>> rows = new ArrayList<>();
        for (InternshipApplication a : p.getRecords()) {
            rows.add(brief(a));
        }
        return PageResult.of(p.getTotal(), page, size, rows);
    }

    private Map<String, Object> brief(InternshipApplication a) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", a.getId());
        m.put("internshipNo", a.getInternshipNo());
        m.put("studentName", a.getStudentName());
        m.put("studentNo", a.getStudentNo());
        m.put("major", a.getMajor());
        m.put("grade", a.getGrade());
        m.put("companyName", a.getCompanyName());
        m.put("position", a.getPosition());
        m.put("industry", a.getIndustry());
        m.put("city", a.getCity());
        m.put("teacherName", a.getTeacherName());
        m.put("mentorName", a.getMentorName());
        m.put("stage", a.getStage());
        m.put("reportStatus", a.getReportStatus());
        m.put("source", a.getSource());
        m.put("startDate", a.getStartDate());
        m.put("endDate", a.getEndDate());
        m.put("createTime", a.getCreateTime());
        m.put("updateTime", a.getUpdateTime());
        m.put("version", a.getVersion());
        return m;
    }

    /** 详情：基础信息 + 里程碑 + 关联单据 + 操作日志（需求：详情页不得重复拼接列表页） */
    public Map<String, Object> detail(Long id) {
        InternshipApplication a = appMapper.selectById(id);
        if (a == null || (a.getDeleted() != null && a.getDeleted() == 1)) {
            throw new BizException("实习档案不存在");
        }
        if ("student".equals(UserContext.roleCode()) && !Objects.equals(a.getStudentId(), UserContext.userId())) {
            throw new BizException(403, "无权查看他人实习档案");
        }
        Map<String, Object> m = brief(a);
        m.put("agreementFile", a.getAgreementFile());
        m.put("insuranceFile", a.getInsuranceFile());
        m.put("acceptFile", a.getAcceptFile());
        m.put("transitionReason", a.getTransitionReason());
        m.put("batchNo", a.getBatchNo());

        List<InternshipMilestone> ms = milestoneMapper.selectList(new LambdaQueryWrapper<InternshipMilestone>()
                .eq(InternshipMilestone::getApplicationId, id).orderByAsc(InternshipMilestone::getSeqNo));
        m.put("milestones", ms);

        List<Map<String, Object>> reports = new ArrayList<>();
        for (WeeklyReport r : reportMapper.selectList(new LambdaQueryWrapper<WeeklyReport>()
                .eq(WeeklyReport::getApplicationId, id).orderByDesc(WeeklyReport::getWeekNo).last("limit 6"))) {
            Map<String, Object> x = new LinkedHashMap<>();
            x.put("id", r.getId());
            x.put("reportNo", r.getReportNo());
            x.put("weekNo", r.getWeekNo());
            x.put("status", r.getStatus());
            x.put("submitTime", r.getSubmitTime());
            reports.add(x);
        }
        m.put("reports", reports);

        m.put("attendances", attendanceMapper.selectList(new LambdaQueryWrapper<MonthlyAttendance>()
                .eq(MonthlyAttendance::getApplicationId, id).orderByDesc(MonthlyAttendance::getMonth)));
        m.put("changes", changeMapper.selectList(new LambdaQueryWrapper<InternshipChange>()
                .eq(InternshipChange::getApplicationId, id).orderByDesc(InternshipChange::getApplyTime)));
        m.put("issues", issueMapper.selectList(new LambdaQueryWrapper<InternshipIssue>()
                .eq(InternshipIssue::getApplicationId, id).orderByDesc(InternshipIssue::getReportTime)));
        m.put("visits", visitMapper.selectList(new LambdaQueryWrapper<VisitRecord>()
                .eq(VisitRecord::getApplicationId, id).orderByDesc(VisitRecord::getVisitDate)));
        m.put("evaluation", evalMapper.selectOne(new LambdaQueryWrapper<FinalEvaluation>()
                .eq(FinalEvaluation::getApplicationId, id).last("limit 1")));
        m.put("timeline", timeline(a));
        return m;
    }

    /** 时间轴：创建、提交、审批、退回、中止等事件，普通用户不可修改 */
    private List<Map<String, Object>> timeline(InternshipApplication a) {
        List<Map<String, Object>> list = new ArrayList<>();
        list.add(event("创建实习备案", a.getStudentName(), a.getCreateTime(), a.getStage()));
        if (a.getTransitionReason() != null) {
            list.add(event("状态流转", a.getTeacherName(), a.getUpdateTime(), a.getTransitionReason()));
        }
        for (InternshipChange c : changeMapper.selectList(new LambdaQueryWrapper<InternshipChange>()
                .eq(InternshipChange::getApplicationId, a.getId()))) {
            list.add(event(c.getChangeType() + "：" + c.getStatus(), c.getStudentName(), c.getApplyTime(), c.getReason()));
        }
        for (VisitRecord v : visitMapper.selectList(new LambdaQueryWrapper<VisitRecord>()
                .eq(VisitRecord::getApplicationId, a.getId()))) {
            list.add(event("走访记录（" + v.getVisitType() + "）", v.getTeacherName(),
                    v.getVisitDate() == null ? null : v.getVisitDate().atStartOfDay(), v.getStudentPerformance()));
        }
        list.sort(Comparator.comparing((Map<String, Object> e) -> (LocalDateTime) e.get("time"),
                Comparator.nullsLast(Comparator.naturalOrder())));
        return list;
    }

    private Map<String, Object> event(String title, String actor, LocalDateTime time, String remark) {
        Map<String, Object> e = new LinkedHashMap<>();
        e.put("title", title);
        e.put("actor", actor);
        e.put("time", time);
        e.put("remark", remark);
        return e;
    }

    /** 新建：编号后端生成、唯一性校验、默认进入实习备案 */
    @Transactional
    public Long create(InternshipApplication req) {
        if (!StringUtils.hasText(req.getInternshipNo())) {
            throw new BizException("实习编号必填");
        }
        String no = req.getInternshipNo().trim();
        if (no.length() > 50) {
            throw new BizException("实习编号长度不能超过 50 个字符");
        }
        Long exist = appMapper.selectCount(new LambdaQueryWrapper<InternshipApplication>()
                .eq(InternshipApplication::getInternshipNo, no)
                .eq(InternshipApplication::getDeleted, 0));
        if (exist != null && exist > 0) {
            throw new BizException("实习编号已存在");
        }
        if (req.getStartDate() != null && req.getEndDate() != null
                && req.getEndDate().isBefore(req.getStartDate())) {
            throw new BizException("结束日期不能早于开始日期");
        }
        req.setId(null);
        req.setInternshipNo(no);
        req.setStage("实习备案");
        req.setReportStatus("待提交");
        req.setVersion(1);
        req.setDeleted(0);
        req.setCreateBy(UserContext.userId());
        req.setCreateTime(LocalDateTime.now());
        req.setUpdateTime(LocalDateTime.now());
        appMapper.insert(req);
        // 默认生成 4 项里程碑，便于周报完整度检查有依据
        String[] titles = {"入职与安全培训", "熟悉业务与代码结构", "独立承担核心任务", "成果汇报与复盘"};
        for (int i = 1; i <= 4; i++) {
            InternshipMilestone ms = new InternshipMilestone();
            ms.setApplicationId(req.getId());
            ms.setSeqNo(i);
            ms.setTitle(titles[i - 1]);
            ms.setPlanWeek(i * 3);
            ms.setStatus("未开始");
            ms.setDelayedDays(0);
            ms.setCreateTime(LocalDateTime.now());
            milestoneMapper.insert(ms);
        }
        writeLog("新建实习备案", "POST /api/internship-process", no);
        return req.getId();
    }

    /** 更新：校验版本号，发现被他人更新则要求刷新，不允许覆盖提交 */
    @Transactional
    public void update(Long id, InternshipApplication req) {
        InternshipApplication old = appMapper.selectById(id);
        if (old == null) {
            throw new BizException("实习档案不存在");
        }
        if (req.getVersion() != null && !Objects.equals(req.getVersion(), old.getVersion())) {
            throw new BizException("数据已被他人更新，请刷新后重试");
        }
        if (req.getStartDate() != null && req.getEndDate() != null
                && req.getEndDate().isBefore(req.getStartDate())) {
            throw new BizException("结束日期不能早于开始日期");
        }
        req.setId(id);
        req.setVersion(old.getVersion() + 1);
        req.setUpdateTime(LocalDateTime.now());
        appMapper.updateById(req);
        writeLog("编辑实习备案", "PUT /api/internship-process/" + id, old.getInternshipNo());
    }

    /**
     * 状态流转：只允许前进一格或转「已中止」，原因不少于 5 个字。
     * 结项前校验材料与周报，缺失不得进入学校归档（需求第 5 节第 4 条）。
     */
    @Transactional
    public Map<String, Object> transition(Long id, String targetStage, String reason) {
        InternshipApplication a = appMapper.selectById(id);
        if (a == null) {
            throw new BizException("实习档案不存在");
        }
        if (!StringUtils.hasText(reason) || reason.trim().length() < 5) {
            throw new BizException("流转原因不能少于 5 个字");
        }
        String cur = a.getStage();
        if (Objects.equals(cur, targetStage)) {
            throw new BizException("当前已处于该阶段");
        }
        boolean abort = "已中止".equals(targetStage);
        if (!abort) {
            int ci = STAGES.indexOf(cur);
            int ti = STAGES.indexOf(targetStage);
            if (ci < 0 || ti < 0) {
                throw new BizException("非法的阶段取值");
            }
            if (ti != ci + 1) {
                throw new BizException("不允许越级流转，当前阶段只能进入「" + STAGES.get(ci + 1) + "」");
            }
            if ("学校归档".equals(targetStage)) {
                checkBeforeArchive(a);
            }
        }
        LambdaUpdateWrapper<InternshipApplication> uw = new LambdaUpdateWrapper<InternshipApplication>()
                .eq(InternshipApplication::getId, id)
                .eq(InternshipApplication::getVersion, a.getVersion())
                .set(InternshipApplication::getStage, targetStage)
                .set(InternshipApplication::getVersion, a.getVersion() + 1)
                .set(InternshipApplication::getTransitionReason, reason.trim())
                .set(InternshipApplication::getUpdateTime, LocalDateTime.now());
        int n = appMapper.update(null, uw);
        if (n == 0) {
            throw new BizException("数据已被他人更新，请刷新后重试");
        }
        writeLog("状态流转 " + cur + "→" + targetStage, "POST /api/internship-process/" + id + "/transition", a.getInternshipNo());
        // 流转后给相关人推送站内消息
        if (a.getTeacherId() != null) {
            pushMessage(a.getTeacherId(), "实习档案状态变更：" + a.getInternshipNo(),
                    cur + " → " + targetStage, "待审批", a.getInternshipNo(), "/application");
        }
        Map<String, Object> r = new LinkedHashMap<>();
        r.put("id", id);
        r.put("from", cur);
        r.put("to", targetStage);
        return r;
    }

    /** 结项前校验：周报、考勤、双导师评价、结项材料缺一不可 */
    private void checkBeforeArchive(InternshipApplication a) {
        Long reports = reportMapper.selectCount(new LambdaQueryWrapper<WeeklyReport>()
                .eq(WeeklyReport::getApplicationId, a.getId())
                .eq(WeeklyReport::getStatus, "已批阅"));
        if (reports == null || reports < 4) {
            throw new BizException("周报已批阅数量不足（当前 " + (reports == null ? 0 : reports) + " 份），不得结项");
        }
        Long att = attendanceMapper.selectCount(new LambdaQueryWrapper<MonthlyAttendance>()
                .eq(MonthlyAttendance::getApplicationId, a.getId()));
        if (att == null || att < 1) {
            throw new BizException("缺少月度考勤记录，不得结项");
        }
        FinalEvaluation e = evalMapper.selectOne(new LambdaQueryWrapper<FinalEvaluation>()
                .eq(FinalEvaluation::getApplicationId, a.getId()).last("limit 1"));
        if (e == null || e.getCompanyScore() == null || e.getSchoolScore() == null) {
            throw new BizException("企业导师与校内教师评价未完成，不得结项");
        }
        if (!StringUtils.hasText(a.getAgreementFile()) || !StringUtils.hasText(a.getInsuranceFile())) {
            throw new BizException("协议或保险材料缺失，不得结项");
        }
    }

    /** 批量流转：逐条返回成功或失败原因，禁止整批静默失败 */
    @Transactional
    public List<Map<String, Object>> batchTransition(List<Long> ids, String targetStage, String reason) {
        List<Map<String, Object>> result = new ArrayList<>();
        for (Long id : ids) {
            Map<String, Object> r = new LinkedHashMap<>();
            r.put("id", id);
            try {
                transition(id, targetStage, reason);
                r.put("success", true);
                r.put("message", "成功");
            } catch (Exception ex) {
                r.put("success", false);
                r.put("message", ex.getMessage());
            }
            result.add(r);
        }
        return result;
    }

    private void pushMessage(Long receiverId, String title, String content, String type, String bizNo, String link) {
        SysMessage m = new SysMessage();
        m.setTitle(title);
        m.setContent(content);
        m.setMsgType(type);
        m.setBizNo(bizNo);
        m.setLinkUrl(link);
        m.setReceiverId(receiverId);
        m.setIsRead(0);
        m.setCreateTime(LocalDateTime.now());
        messageMapper.insert(m);
    }

    private void writeLog(String action, String method, String params) {
        SysLog log = new SysLog();
        log.setUserId(UserContext.userId());
        log.setUserName(UserContext.realName());
        log.setAction(action);
        log.setMethod(method);
        log.setParams(params);
        log.setCostMs(0L);
        log.setCreateTime(LocalDateTime.now());
        logMapper.insert(log);
    }

    /** 选项：供下拉框使用（企业、导师、批次） */
    public Map<String, Object> options() {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("today", LocalDate.now());
        m.put("stages", STAGES);
        return m;
    }
}
