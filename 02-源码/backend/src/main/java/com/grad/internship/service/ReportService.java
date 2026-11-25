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

import java.time.LocalDateTime;
import java.util.*;

/**
 * 周报与月度考勤。
 * 规则（需求第 5 节第 2 条）：当周上一版未退修或未批阅时不得重复提交——同一 (档案, 周次) 只允许一条，
 * 已提交且处于「待批阅」时再次提交会被拒绝，必须等批阅或退修。
 */
@Service
@RequiredArgsConstructor
public class ReportService {

    private final WeeklyReportMapper reportMapper;
    private final MonthlyAttendanceMapper attendanceMapper;
    private final InternshipApplicationMapper appMapper;
    private final SysMessageMapper messageMapper;
    private final SysLogMapper logMapper;

    /** 列表：待本人处理优先、更新时间倒序；支持全部/待办/处理中/已完成/异常快捷标签 */
    public PageResult<Map<String, Object>> page(int page, int size, String tab, String keyword,
                                                Integer weekNo, String status) {
        LambdaQueryWrapper<WeeklyReport> q = new LambdaQueryWrapper<>();
        if (StringUtils.hasText(keyword)) {
            q.and(w -> w.like(WeeklyReport::getReportNo, keyword)
                    .or().like(WeeklyReport::getStudentName, keyword));
        }
        q.eq(weekNo != null, WeeklyReport::getWeekNo, weekNo);
        q.eq(StringUtils.hasText(status), WeeklyReport::getStatus, status);
        if (StringUtils.hasText(tab)) {
            switch (tab) {
                case "todo" -> q.in(WeeklyReport::getStatus, List.of("待批阅", "已退修"));
                case "doing" -> q.in(WeeklyReport::getStatus, List.of("草稿", "待批阅"));
                case "done" -> q.eq(WeeklyReport::getStatus, "已批阅");
                case "abnormal" -> q.in(WeeklyReport::getStatus, List.of("已退修", "逾期未交"));
                default -> { }
            }
        }
        // 数据范围：学生看本人，教师看本人指导学生，企业导师看本人负责学生
        String role = UserContext.roleCode();
        if (!"admin".equals(role)) {
            List<Long> appIds = scopedAppIds(role);
            if (appIds.isEmpty()) {
                return PageResult.of(0, page, size, List.of());
            }
            q.in(WeeklyReport::getApplicationId, appIds);
        }
        // 待本人处理优先：待批阅/已退修排前面，再按提交时间倒序
        q.last("order by field(status,'待批阅','已退修','草稿','逾期未交','已批阅') asc, submit_time desc");
        Page<WeeklyReport> p = reportMapper.selectPage(new Page<>(page, size), q);
        List<Map<String, Object>> rows = new ArrayList<>();
        for (WeeklyReport r : p.getRecords()) {
            rows.add(brief(r));
        }
        return PageResult.of(p.getTotal(), page, size, rows);
    }

    private List<Long> scopedAppIds(String role) {
        LambdaQueryWrapper<InternshipApplication> aq = new LambdaQueryWrapper<>();
        if ("student".equals(role)) {
            aq.eq(InternshipApplication::getStudentId, UserContext.userId());
        } else if ("teacher".equals(role)) {
            aq.eq(InternshipApplication::getTeacherId, UserContext.userId());
        } else if ("mentor".equals(role)) {
            aq.eq(InternshipApplication::getMentorId, UserContext.userId());
        }
        return appMapper.selectList(aq).stream().map(InternshipApplication::getId).toList();
    }

    private Map<String, Object> brief(WeeklyReport r) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", r.getId());
        m.put("reportNo", r.getReportNo());
        m.put("applicationId", r.getApplicationId());
        m.put("internshipNo", r.getInternshipNo());
        m.put("studentName", r.getStudentName());
        m.put("weekNo", r.getWeekNo());
        m.put("weekStart", r.getWeekStart());
        m.put("weekEnd", r.getWeekEnd());
        m.put("taskContent", r.getTaskContent());
        m.put("status", r.getStatus());
        m.put("submitTime", r.getSubmitTime());
        m.put("deadline", r.getDeadline());
        m.put("reviewScore", r.getReviewScore());
        return m;
    }

    public Map<String, Object> detail(Long id) {
        WeeklyReport r = reportMapper.selectById(id);
        if (r == null) {
            throw new BizException("周报不存在");
        }
        Map<String, Object> m = brief(r);
        m.put("harvest", r.getHarvest());
        m.put("problem", r.getProblem());
        m.put("nextPlan", r.getNextPlan());
        m.put("attachmentImage", r.getAttachmentImage());
        m.put("attachmentFile", r.getAttachmentFile());
        m.put("reviewComment", r.getReviewComment());
        m.put("reviewerName", r.getReviewerName());
        m.put("reviewTime", r.getReviewTime());
        InternshipApplication a = appMapper.selectById(r.getApplicationId());
        if (a != null) {
            Map<String, Object> info = new LinkedHashMap<>();
            info.put("internshipNo", a.getInternshipNo());
            info.put("companyName", a.getCompanyName());
            info.put("position", a.getPosition());
            info.put("teacherName", a.getTeacherName());
            info.put("mentorName", a.getMentorName());
            info.put("startDate", a.getStartDate());
            info.put("endDate", a.getEndDate());
            m.put("application", info);
        }
        // 里程碑覆盖检查，供批阅页展示缺项提示
        m.put("milestoneCheck", milestoneCoverage(r));
        return m;
    }

    /** 周报里程碑覆盖：任务 / 成果 / 问题 / 下周计划 / 附件 五项 */
    public Map<String, Object> milestoneCoverage(WeeklyReport r) {
        LinkedHashMap<String, Boolean> items = new LinkedHashMap<>();
        items.put("任务描述", StringUtils.hasText(r.getTaskContent()));
        items.put("阶段成果", StringUtils.hasText(r.getHarvest()));
        items.put("问题记录", StringUtils.hasText(r.getProblem()));
        items.put("下周计划", StringUtils.hasText(r.getNextPlan()));
        items.put("附件材料", StringUtils.hasText(r.getAttachmentImage()) || StringUtils.hasText(r.getAttachmentFile()));
        long ok = items.values().stream().filter(Boolean::booleanValue).count();
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("items", items);
        m.put("covered", ok);
        m.put("total", items.size());
        m.put("complete", ok == items.size());
        return m;
    }

    /** 提交：同周次未批阅/未退修时禁止重复提交 */
    @Transactional
    public Long submit(WeeklyReport req) {
        if (!StringUtils.hasText(req.getTaskContent())) {
            throw new BizException("本周任务不能为空");
        }
        InternshipApplication a = appMapper.selectById(req.getApplicationId());
        if (a == null) {
            throw new BizException("实习档案不存在");
        }
        if ("已中止".equals(a.getStage())) {
            throw new BizException("档案已中止，不能提交周报");
        }
        WeeklyReport exist = reportMapper.selectOne(new LambdaQueryWrapper<WeeklyReport>()
                .eq(WeeklyReport::getApplicationId, req.getApplicationId())
                .eq(WeeklyReport::getWeekNo, req.getWeekNo()).last("limit 1"));
        if (exist != null && !"已退修".equals(exist.getStatus()) && !"草稿".equals(exist.getStatus())) {
            throw new BizException("本周周报已提交且未退修，不能重复提交");
        }
        String no = exist != null ? exist.getReportNo() : "WR" + LocalDateTime.now().format(
                java.time.format.DateTimeFormatter.ofPattern("yyyyMMddHHmmss")) + String.format("%03d", req.getWeekNo());
        req.setId(exist == null ? null : exist.getId());
        req.setReportNo(no);
        req.setInternshipNo(a.getInternshipNo());
        req.setStudentId(a.getStudentId());
        req.setStudentName(a.getStudentName());
        req.setStatus("待批阅");
        req.setSubmitTime(LocalDateTime.now());
        if (req.getDeadline() == null) {
            req.setDeadline(LocalDateTime.now().plusDays(2));
        }
        if (exist == null) {
            req.setCreateTime(LocalDateTime.now());
            reportMapper.insert(req);
        } else {
            reportMapper.updateById(req);
        }
        // 同步档案的周报状态，列表可直接看到待批阅
        InternshipApplication upd = new InternshipApplication();
        upd.setId(a.getId());
        upd.setReportStatus("待批阅");
        upd.setUpdateTime(LocalDateTime.now());
        appMapper.updateById(upd);
        if (a.getTeacherId() != null) {
            push(a.getTeacherId(), "待批阅周报：" + no, a.getStudentName() + " 第 " + req.getWeekNo() + " 周周报已提交",
                    "待审批", no, "/review");
        }
        return req.getId();
    }

    /** 批阅：通过或退修，退修必须填写不少于 5 字的评语 */
    @Transactional
    public void review(Long id, boolean pass, Integer score, String comment) {
        WeeklyReport r = reportMapper.selectById(id);
        if (r == null) {
            throw new BizException("周报不存在");
        }
        if (!"待批阅".equals(r.getStatus())) {
            throw new BizException("该周报当前状态为「" + r.getStatus() + "」，不能重复批阅");
        }
        if (!pass && (!StringUtils.hasText(comment) || comment.trim().length() < 5)) {
            throw new BizException("退修必须填写不少于 5 个字的评语");
        }
        r.setStatus(pass ? "已批阅" : "已退修");
        r.setReviewScore(pass ? (score == null ? 85 : score) : null);
        r.setReviewComment(comment);
        r.setReviewerId(UserContext.userId());
        r.setReviewerName(UserContext.realName());
        r.setReviewTime(LocalDateTime.now());
        reportMapper.updateById(r);
        InternshipApplication a = appMapper.selectById(r.getApplicationId());
        if (a != null) {
            InternshipApplication upd = new InternshipApplication();
            upd.setId(a.getId());
            upd.setReportStatus(pass ? "已批阅" : "已退修");
            upd.setUpdateTime(LocalDateTime.now());
            appMapper.updateById(upd);
            push(a.getStudentId(), (pass ? "周报已批阅：" : "周报被退修：") + r.getReportNo(),
                    StringUtils.hasText(comment) ? comment : "请查看批阅结果", pass ? "处理完成" : "已退回",
                    r.getReportNo(), "/report");
        }
    }

    // ---------------- 月度考勤 ----------------

    public PageResult<Map<String, Object>> attendancePage(int page, int size, String month, String company,
                                                          String confirmStatus) {
        LambdaQueryWrapper<MonthlyAttendance> q = new LambdaQueryWrapper<>();
        q.eq(StringUtils.hasText(month), MonthlyAttendance::getMonth, month);
        q.like(StringUtils.hasText(company), MonthlyAttendance::getCompanyName, company);
        q.eq(StringUtils.hasText(confirmStatus), MonthlyAttendance::getConfirmStatus, confirmStatus);
        String role = UserContext.roleCode();
        if (!"admin".equals(role)) {
            List<Long> ids = scopedAppIds(role);
            if (ids.isEmpty()) {
                return PageResult.of(0, page, size, List.of());
            }
            q.in(MonthlyAttendance::getApplicationId, ids);
        }
        q.orderByDesc(MonthlyAttendance::getMonth).orderByAsc(MonthlyAttendance::getStudentName);
        Page<MonthlyAttendance> p = attendanceMapper.selectPage(new Page<>(page, size), q);
        List<Map<String, Object>> rows = new ArrayList<>();
        for (MonthlyAttendance a : p.getRecords()) {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("id", a.getId());
            m.put("attendanceNo", a.getAttendanceNo());
            m.put("applicationId", a.getApplicationId());
            m.put("studentName", a.getStudentName());
            m.put("companyName", a.getCompanyName());
            m.put("month", a.getMonth());
            m.put("shouldDays", a.getShouldDays());
            m.put("actualDays", a.getActualDays());
            m.put("lateCount", a.getLateCount());
            m.put("leaveDays", a.getLeaveDays());
            m.put("remark", a.getRemark());
            m.put("confirmStatus", a.getConfirmStatus());
            m.put("mentorName", a.getMentorName());
            m.put("createTime", a.getCreateTime());
            rows.add(m);
        }
        return PageResult.of(p.getTotal(), page, size, rows);
    }

    /** 企业导师录入：同一档案同一月份唯一 */
    @Transactional
    public Long saveAttendance(MonthlyAttendance req) {
        if (!StringUtils.hasText(req.getMonth())) {
            throw new BizException("请选择考勤月份");
        }
        MonthlyAttendance exist = attendanceMapper.selectOne(new LambdaQueryWrapper<MonthlyAttendance>()
                .eq(MonthlyAttendance::getApplicationId, req.getApplicationId())
                .eq(MonthlyAttendance::getMonth, req.getMonth()).last("limit 1"));
        req.setId(exist == null ? null : exist.getId());
        if (exist == null) {
            req.setAttendanceNo("AT" + req.getMonth().replace("-", "")
                    + String.format("%03d", (int) (Math.random() * 900) + 100));
            req.setConfirmStatus("待学生确认");
            req.setCreateTime(LocalDateTime.now());
            attendanceMapper.insert(req);
        } else {
            req.setConfirmStatus("待学生确认");
            attendanceMapper.updateById(req);
        }
        return req.getId();
    }

    /** 学生确认或提出异议；异议必须写备注 */
    @Transactional
    public void confirmAttendance(Long id, boolean agree, String remark) {
        MonthlyAttendance a = attendanceMapper.selectById(id);
        if (a == null) {
            throw new BizException("考勤记录不存在");
        }
        if (!agree && (!StringUtils.hasText(remark) || remark.trim().length() < 5)) {
            throw new BizException("提出异议必须填写不少于 5 个字的原因");
        }
        a.setConfirmStatus(agree ? "学生已确认" : "学生有异议");
        if (StringUtils.hasText(remark)) {
            a.setRemark(remark);
        }
        attendanceMapper.updateById(a);
        if (!agree) {
            List<InternshipApplication> apps = appMapper.selectList(new LambdaQueryWrapper<InternshipApplication>()
                    .eq(InternshipApplication::getId, a.getApplicationId()));
            if (!apps.isEmpty() && apps.get(0).getTeacherId() != null) {
                push(apps.get(0).getTeacherId(), "考勤异议：" + a.getStudentName(),
                        a.getMonth() + " 考勤存在异议：" + remark, "待审批", a.getAttendanceNo(), "/attendance");
            }
        }
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
}
