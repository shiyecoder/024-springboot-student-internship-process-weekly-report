package com.grad.internship.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
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

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.util.*;

/**
 * 流程类单据：变更审批、异常关怀、走访记录、结项评价。
 *
 * 变更生效规则（需求第 5 节第 3 条）：变更生效前原档案仍有效，生效后保留变更前后信息。
 * 因此这里只更新档案的岗位/导师/企业字段，同时把 before/after 留在 internship_change 里。
 */
@Service
@RequiredArgsConstructor
public class FlowService {

    private final InternshipChangeMapper changeMapper;
    private final InternshipIssueMapper issueMapper;
    private final VisitRecordMapper visitMapper;
    private final FinalEvaluationMapper evalMapper;
    private final InternshipApplicationMapper appMapper;
    private final WeeklyReportMapper reportMapper;
    private final MonthlyAttendanceMapper attendanceMapper;
    private final SysMessageMapper messageMapper;
    private final SysLogMapper logMapper;

    // ---------------- 变更 ----------------

    public PageResult<Map<String, Object>> changePage(int page, int size, String type, String node) {
        LambdaQueryWrapper<InternshipChange> q = new LambdaQueryWrapper<>();
        q.eq(StringUtils.hasText(type), InternshipChange::getChangeType, type);
        q.eq(StringUtils.hasText(node), InternshipChange::getCurrentNode, node);
        String role = UserContext.roleCode();
        if (!"admin".equals(role)) {
            List<Long> ids = scopedAppIds(role);
            if (ids.isEmpty()) {
                return PageResult.of(0, page, size, List.of());
            }
            q.in(InternshipChange::getApplicationId, ids);
        }
        q.orderByDesc(InternshipChange::getApplyTime);
        Page<InternshipChange> p = changeMapper.selectPage(new Page<>(page, size), q);
        List<Map<String, Object>> rows = new ArrayList<>();
        for (InternshipChange c : p.getRecords()) {
            rows.add(changeMap(c));
        }
        return PageResult.of(p.getTotal(), page, size, rows);
    }

    private Map<String, Object> changeMap(InternshipChange c) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", c.getId());
        m.put("changeNo", c.getChangeNo());
        m.put("applicationId", c.getApplicationId());
        m.put("studentName", c.getStudentName());
        m.put("changeType", c.getChangeType());
        m.put("beforeValue", c.getBeforeValue());
        m.put("afterValue", c.getAfterValue());
        m.put("reason", c.getReason());
        m.put("attachment", c.getAttachment());
        m.put("currentNode", c.getCurrentNode());
        m.put("status", c.getStatus());
        m.put("applyTime", c.getApplyTime());
        m.put("teacherOpinion", c.getTeacherOpinion());
        m.put("adminOpinion", c.getAdminOpinion());
        m.put("effectiveTime", c.getEffectiveTime());
        return m;
    }

    @Transactional
    public Long applyChange(InternshipChange req) {
        if (!StringUtils.hasText(req.getReason()) || req.getReason().trim().length() < 5) {
            throw new BizException("变更原因不能少于 5 个字");
        }
        InternshipApplication a = appMapper.selectById(req.getApplicationId());
        if (a == null) {
            throw new BizException("实习档案不存在");
        }
        req.setId(null);
        req.setChangeNo("CH" + LocalDateTime.now().format(java.time.format.DateTimeFormatter.ofPattern("yyyyMMddHHmmss")));
        req.setStudentName(a.getStudentName());
        req.setCurrentNode("校内审批");
        req.setStatus("审批中");
        req.setApplyTime(LocalDateTime.now());
        req.setCreateTime(LocalDateTime.now());
        changeMapper.insert(req);
        if (a.getTeacherId() != null) {
            push(a.getTeacherId(), "变更待审批：" + req.getChangeNo(),
                    a.getStudentName() + " 申请" + req.getChangeType(), "待审批", req.getChangeNo(), "/change");
        }
        return req.getId();
    }

    /** 审批：校内 → 管理员 → 生效；驳回必须写原因 */
    @Transactional
    public void approveChange(Long id, boolean pass, String opinion) {
        InternshipChange c = changeMapper.selectById(id);
        if (c == null) {
            throw new BizException("变更单不存在");
        }
        if ("已生效".equals(c.getCurrentNode()) || "已驳回".equals(c.getCurrentNode())) {
            throw new BizException("该变更已结束，不能重复审批");
        }
        if (!pass && (!StringUtils.hasText(opinion) || opinion.trim().length() < 5)) {
            throw new BizException("驳回必须填写不少于 5 个字的原因");
        }
        String role = UserContext.roleCode();
        if ("校内审批".equals(c.getCurrentNode())) {
            if (!pass) {
                c.setCurrentNode("已驳回");
                c.setStatus("已驳回");
                c.setTeacherOpinion(opinion);
            } else {
                c.setTeacherOpinion(opinion);
                // 更换导师由管理员终审，其余类型校内同意后直接进入管理员审批
                c.setCurrentNode("管理员审批");
            }
        } else if ("管理员审批".equals(c.getCurrentNode())) {
            if (!"admin".equals(role)) {
                throw new BizException("当前节点仅实习管理员可审批");
            }
            c.setAdminOpinion(opinion);
            if (!pass) {
                c.setCurrentNode("已驳回");
                c.setStatus("已驳回");
            } else {
                c.setCurrentNode("已生效");
                c.setStatus("已通过");
                c.setEffectiveTime(LocalDateTime.now());
                applyEffect(c);
            }
        } else {
            throw new BizException("当前节点无需审批");
        }
        changeMapper.updateById(c);
    }

    /** 变更生效：只改允许变更的字段，保留 before/after 于变更单 */
    private void applyEffect(InternshipChange c) {
        InternshipApplication a = appMapper.selectById(c.getApplicationId());
        if (a == null) {
            return;
        }
        InternshipApplication upd = new InternshipApplication();
        upd.setId(a.getId());
        upd.setVersion(a.getVersion() + 1);
        upd.setUpdateTime(LocalDateTime.now());
        switch (c.getChangeType()) {
            case "更换企业" -> {
                upd.setCompanyName(c.getAfterValue());
                upd.setPosition(a.getPosition());
            }
            case "更换岗位" -> upd.setPosition(c.getAfterValue());
            case "更换导师" -> upd.setMentorName(c.getAfterValue());
            case "中止实习" -> upd.setStage("已中止");
            default -> { }
        }
        appMapper.updateById(upd);
        push(a.getStudentId(), "变更已生效：" + c.getChangeNo(),
                c.getChangeType() + "：" + c.getBeforeValue() + " → " + c.getAfterValue(),
                "处理完成", c.getChangeNo(), "/application");
    }

    // ---------------- 异常 ----------------

    public PageResult<Map<String, Object>> issuePage(int page, int size, String type, String status) {
        LambdaQueryWrapper<InternshipIssue> q = new LambdaQueryWrapper<>();
        q.eq(StringUtils.hasText(type), InternshipIssue::getIssueType, type);
        q.eq(StringUtils.hasText(status), InternshipIssue::getStatus, status);
        if (!"admin".equals(UserContext.roleCode())) {
            List<Long> ids = scopedAppIds(UserContext.roleCode());
            if (ids.isEmpty()) {
                return PageResult.of(0, page, size, List.of());
            }
            q.in(InternshipIssue::getApplicationId, ids);
        }
        q.orderByDesc(InternshipIssue::getReportTime);
        Page<InternshipIssue> p = issueMapper.selectPage(new Page<>(page, size), q);
        List<Map<String, Object>> rows = new ArrayList<>();
        for (InternshipIssue i : p.getRecords()) {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("id", i.getId());
            m.put("issueNo", i.getIssueNo());
            m.put("applicationId", i.getApplicationId());
            m.put("studentName", i.getStudentName());
            m.put("companyName", i.getCompanyName());
            m.put("issueType", i.getIssueType());
            m.put("level", i.getLevel());
            m.put("content", i.getContent());
            m.put("reportTime", i.getReportTime());
            m.put("handlerName", i.getHandlerName());
            m.put("status", i.getStatus());
            m.put("handleRecord", i.getHandleRecord());
            m.put("closeTime", i.getCloseTime());
            rows.add(m);
        }
        return PageResult.of(p.getTotal(), page, size, rows);
    }

    @Transactional
    public Long reportIssue(InternshipIssue req) {
        if (!StringUtils.hasText(req.getContent()) || req.getContent().trim().length() < 5) {
            throw new BizException("异常描述不能少于 5 个字");
        }
        InternshipApplication a = appMapper.selectById(req.getApplicationId());
        if (a == null) {
            throw new BizException("实习档案不存在");
        }
        req.setId(null);
        req.setIssueNo("IS" + LocalDateTime.now().format(java.time.format.DateTimeFormatter.ofPattern("yyyyMMddHHmmss")));
        req.setStudentName(a.getStudentName());
        req.setCompanyName(a.getCompanyName());
        req.setStatus("待处置");
        req.setReportTime(LocalDateTime.now());
        req.setCreateTime(LocalDateTime.now());
        issueMapper.insert(req);
        if (a.getTeacherId() != null) {
            push(a.getTeacherId(), "异常上报：" + req.getIssueNo(),
                    req.getIssueType() + " · " + req.getContent(), "待审批", req.getIssueNo(), "/issue");
        }
        return req.getId();
    }

    /** 处置：追加处置记录，关闭时必须填写处置结论 */
    @Transactional
    public void handleIssue(Long id, String record, boolean close) {
        InternshipIssue i = issueMapper.selectById(id);
        if (i == null) {
            throw new BizException("异常单不存在");
        }
        if (!StringUtils.hasText(record) || record.trim().length() < 5) {
            throw new BizException("处置记录不能少于 5 个字");
        }
        String old = i.getHandleRecord() == null ? "" : i.getHandleRecord() + "\n";
        i.setHandleRecord(old + LocalDateTime.now().format(
                java.time.format.DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm")) + " " + record.trim());
        i.setHandlerName(UserContext.realName());
        i.setStatus(close ? "已关闭" : "处置中");
        if (close) {
            i.setCloseTime(LocalDateTime.now());
        }
        issueMapper.updateById(i);
        writeLog("处置异常 " + i.getIssueNo(), "POST /api/flow/issue/" + id + "/handle", record.trim());
    }

    // ---------------- 走访 ----------------

    public PageResult<Map<String, Object>> visitPage(int page, int size, String type) {
        LambdaQueryWrapper<VisitRecord> q = new LambdaQueryWrapper<>();
        q.eq(StringUtils.hasText(type), VisitRecord::getVisitType, type);
        String role = UserContext.roleCode();
        if ("teacher".equals(role)) {
            q.eq(VisitRecord::getTeacherId, UserContext.userId());
        } else if (!"admin".equals(role)) {
            List<Long> ids = scopedAppIds(role);
            if (ids.isEmpty()) {
                return PageResult.of(0, page, size, List.of());
            }
            q.in(VisitRecord::getApplicationId, ids);
        }
        q.orderByDesc(VisitRecord::getVisitDate);
        Page<VisitRecord> p = visitMapper.selectPage(new Page<>(page, size), q);
        List<Map<String, Object>> rows = new ArrayList<>();
        for (VisitRecord v : p.getRecords()) {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("id", v.getId());
            m.put("visitNo", v.getVisitNo());
            m.put("applicationId", v.getApplicationId());
            m.put("studentName", v.getStudentName());
            m.put("companyName", v.getCompanyName());
            m.put("visitType", v.getVisitType());
            m.put("visitDate", v.getVisitDate());
            m.put("participants", v.getParticipants());
            m.put("studentPerformance", v.getStudentPerformance());
            m.put("companyOpinion", v.getCompanyOpinion());
            m.put("photo", v.getPhoto());
            m.put("teacherName", v.getTeacherName());
            rows.add(m);
        }
        return PageResult.of(p.getTotal(), page, size, rows);
    }

    @Transactional
    public Long saveVisit(VisitRecord req) {
        if (!StringUtils.hasText(req.getStudentPerformance())) {
            throw new BizException("请填写学生表现");
        }
        if (!StringUtils.hasText(req.getPhoto())) {
            throw new BizException("请上传走访照片");
        }
        InternshipApplication a = appMapper.selectById(req.getApplicationId());
        if (a == null) {
            throw new BizException("实习档案不存在");
        }
        req.setId(null);
        req.setVisitNo("VS" + LocalDateTime.now().format(java.time.format.DateTimeFormatter.ofPattern("yyyyMMddHHmmss")));
        req.setStudentName(a.getStudentName());
        req.setCompanyName(a.getCompanyName());
        req.setTeacherId(UserContext.userId());
        req.setTeacherName(UserContext.realName());
        req.setCreateTime(LocalDateTime.now());
        visitMapper.insert(req);
        return req.getId();
    }

    // ---------------- 结项评价 ----------------

    public PageResult<Map<String, Object>> evaluationPage(int page, int size, String status, String keyword) {
        LambdaQueryWrapper<FinalEvaluation> q = new LambdaQueryWrapper<>();
        q.eq(StringUtils.hasText(status), FinalEvaluation::getStatus, status);
        q.like(StringUtils.hasText(keyword), FinalEvaluation::getStudentName, keyword);
        if (!"admin".equals(UserContext.roleCode())) {
            List<Long> ids = scopedAppIds(UserContext.roleCode());
            if (ids.isEmpty()) {
                return PageResult.of(0, page, size, List.of());
            }
            q.in(FinalEvaluation::getApplicationId, ids);
        }
        q.orderByDesc(FinalEvaluation::getId);
        Page<FinalEvaluation> p = evalMapper.selectPage(new Page<>(page, size), q);
        List<Map<String, Object>> rows = new ArrayList<>();
        for (FinalEvaluation e : p.getRecords()) {
            rows.add(evalMap(e));
        }
        return PageResult.of(p.getTotal(), page, size, rows);
    }

    private Map<String, Object> evalMap(FinalEvaluation e) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", e.getId());
        m.put("applicationId", e.getApplicationId());
        m.put("studentName", e.getStudentName());
        m.put("companyScore", e.getCompanyScore());
        m.put("companyComment", e.getCompanyComment());
        m.put("companyEvaluator", e.getCompanyEvaluator());
        m.put("companyTime", e.getCompanyTime());
        m.put("schoolScore", e.getSchoolScore());
        m.put("schoolComment", e.getSchoolComment());
        m.put("schoolEvaluator", e.getSchoolEvaluator());
        m.put("schoolTime", e.getSchoolTime());
        m.put("reportScore", e.getReportScore());
        m.put("totalScore", e.getTotalScore());
        m.put("grade", e.getGrade());
        m.put("materialsOk", e.getMaterialsOk());
        m.put("status", e.getStatus());
        return m;
    }

    /** 结项详情：材料校验清单 + 双导师评分 + 总评试算 */
    public Map<String, Object> evaluationDetail(Long applicationId) {
        InternshipApplication a = appMapper.selectById(applicationId);
        if (a == null) {
            throw new BizException("实习档案不存在");
        }
        FinalEvaluation e = evalMapper.selectOne(new LambdaQueryWrapper<FinalEvaluation>()
                .eq(FinalEvaluation::getApplicationId, applicationId).last("limit 1"));
        Long reportCount = reportMapper.selectCount(new LambdaQueryWrapper<WeeklyReport>()
                .eq(WeeklyReport::getApplicationId, applicationId).eq(WeeklyReport::getStatus, "已批阅"));
        Long attCount = attendanceMapper.selectCount(new LambdaQueryWrapper<MonthlyAttendance>()
                .eq(MonthlyAttendance::getApplicationId, applicationId));

        List<Map<String, Object>> materials = new ArrayList<>();
        materials.add(material("实习周报", "≥ 4 份", (reportCount == null ? 0 : reportCount) + " 份",
                reportCount != null && reportCount >= 4));
        materials.add(material("月度考勤", "≥ 1 个月", (attCount == null ? 0 : attCount) + " 个月",
                attCount != null && attCount >= 1));
        materials.add(material("企业导师评价", "必填",
                e != null && e.getCompanyScore() != null ? "已提交" : "待提交",
                e != null && e.getCompanyScore() != null));
        materials.add(material("校内教师评价", "必填",
                e != null && e.getSchoolScore() != null ? "已提交" : "待提交",
                e != null && e.getSchoolScore() != null));
        materials.add(material("协议与保险", "必填",
                StringUtils.hasText(a.getAgreementFile()) && StringUtils.hasText(a.getInsuranceFile()) ? "已上传" : "缺失",
                StringUtils.hasText(a.getAgreementFile()) && StringUtils.hasText(a.getInsuranceFile())));
        long missing = materials.stream().filter(m -> !(Boolean) m.get("ok")).count();

        Map<String, Object> m = new LinkedHashMap<>();
        m.put("applicationId", applicationId);
        m.put("studentName", a.getStudentName());
        m.put("internshipNo", a.getInternshipNo());
        m.put("companyName", a.getCompanyName());
        m.put("stage", a.getStage());
        m.put("materials", materials);
        m.put("missingCount", missing);
        m.put("materialsOk", missing == 0);
        m.put("evaluation", e == null ? null : evalMap(e));
        return m;
    }

    private Map<String, Object> material(String name, String require, String actual, boolean ok) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("name", name);
        m.put("require", require);
        m.put("actual", actual);
        m.put("ok", ok);
        return m;
    }

    /**
     * 保存评价：企业导师 40% + 校内教师 40% + 周报完成度 20%；
     * 材料不齐时不允许置为「已结项」。
     */
    @Transactional
    public Map<String, Object> saveEvaluation(Long applicationId, String companyComment, BigDecimal companyScore,
                                              Integer schoolScore, String schoolComment, boolean finalize) {
        InternshipApplication a = appMapper.selectById(applicationId);
        if (a == null) {
            throw new BizException("实习档案不存在");
        }
        FinalEvaluation e = evalMapper.selectOne(new LambdaQueryWrapper<FinalEvaluation>()
                .eq(FinalEvaluation::getApplicationId, applicationId).last("limit 1"));
        boolean create = e == null;
        if (create) {
            e = new FinalEvaluation();
            e.setApplicationId(applicationId);
            e.setStudentName(a.getStudentName());
            e.setCreateTime(LocalDateTime.now());
            e.setStatus("评价中");
        }
        if (companyScore != null) {
            e.setCompanyScore(companyScore);
            e.setCompanyComment(companyComment);
            e.setCompanyEvaluator(UserContext.realName());
            e.setCompanyTime(LocalDateTime.now());
        }
        if (schoolScore != null) {
            if (schoolScore < 0 || schoolScore > 100) {
                throw new BizException("校内评分必须在 0-100 之间");
            }
            e.setSchoolScore(schoolScore);
            e.setSchoolComment(schoolComment);
            e.setSchoolEvaluator(UserContext.realName());
            e.setSchoolTime(LocalDateTime.now());
        }
        // 周报完成度：已批阅周报数 / 批次最低周报数，上限 100
        Long reviewed = reportMapper.selectCount(new LambdaQueryWrapper<WeeklyReport>()
                .eq(WeeklyReport::getApplicationId, applicationId).eq(WeeklyReport::getStatus, "已批阅"));
        double rs = Math.min(100, (reviewed == null ? 0 : reviewed) * 100.0 / 12);
        e.setReportScore(BigDecimal.valueOf(rs).setScale(1, RoundingMode.HALF_UP));

        Map<String, Object> detail = evaluationDetail(applicationId);
        boolean materialsOk = (Boolean) detail.get("materialsOk");
        e.setMaterialsOk(materialsOk ? 1 : 0);

        if (e.getCompanyScore() != null && e.getSchoolScore() != null) {
            double total = e.getCompanyScore().doubleValue() / 5 * 40 + e.getSchoolScore() * 0.4 + rs * 0.2;
            total = BigDecimal.valueOf(total).setScale(1, RoundingMode.HALF_UP).doubleValue();
            e.setTotalScore(BigDecimal.valueOf(total));
            e.setGrade(total >= 90 ? "优秀" : total >= 80 ? "良好" : total >= 60 ? "合格" : "待改进");
        }
        if (finalize) {
            if (!materialsOk) {
                throw new BizException("结项材料或双导师评价不齐，不能结项");
            }
            if (e.getTotalScore() == null) {
                throw new BizException("企业导师与校内教师评分均完成后才能结项");
            }
            e.setStatus("已结项");
            InternshipApplication upd = new InternshipApplication();
            upd.setId(a.getId());
            upd.setStage("学校归档");
            upd.setVersion(a.getVersion() + 1);
            upd.setUpdateTime(LocalDateTime.now());
            upd.setTransitionReason("结项材料齐全，双导师评价完成，系统自动归档");
            appMapper.updateById(upd);
        } else {
            e.setStatus("评价中");
        }
        if (create) {
            evalMapper.insert(e);
        } else {
            evalMapper.updateById(e);
        }
        Map<String, Object> r = evalMap(e);
        r.put("materialsOk", materialsOk);
        return r;
    }

    // ---------------- 公共 ----------------

    private List<Long> scopedAppIds(String role) {
        LambdaQueryWrapper<InternshipApplication> q = new LambdaQueryWrapper<>();
        if ("student".equals(role)) {
            q.eq(InternshipApplication::getStudentId, UserContext.userId());
        } else if ("teacher".equals(role)) {
            q.eq(InternshipApplication::getTeacherId, UserContext.userId());
        } else if ("mentor".equals(role)) {
            q.eq(InternshipApplication::getMentorId, UserContext.userId());
        }
        return appMapper.selectList(q).stream().map(InternshipApplication::getId).toList();
    }

    private void push(Long receiverId, String title, String content, String type, String bizNo, String link) {
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
}
