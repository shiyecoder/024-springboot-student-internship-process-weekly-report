package com.grad.internship.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.grad.internship.entity.*;
import com.grad.internship.mapper.*;
import lombok.RequiredArgsConstructor;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.*;

/**
 * 首页与统计看板。
 * 需求：6 个核心指标 + 5-7 个图表，全部在后端聚合，禁止前端拉全表二次聚合；
 * 图表点击后跳转的明细列表总数，必须与图上数值一致（因此图表用同一份分组 SQL）。
 */
@Service
@RequiredArgsConstructor
public class DashboardService {

    private final InternshipApplicationMapper appMapper;
    private final WeeklyReportMapper reportMapper;
    private final InternshipIssueMapper issueMapper;
    private final InternshipChangeMapper changeMapper;
    private final InternshipMilestoneMapper milestoneMapper;
    private final InternshipCompanyMapper companyMapper;
    private final InternshipScoreMapper scoreMapper;
    private final FinalEvaluationMapper evalMapper;
    private final JdbcTemplate jdbc;

    public Map<String, Object> dashboard(String batchNo) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("kpi", kpi());
        m.put("charts", charts());
        return m;
    }

    /** 六个核心指标 */
    private Map<String, Object> kpi() {
        Map<String, Object> k = new LinkedHashMap<>();
        long students = count("select count(*) from internship_application where deleted = 0");
        long reports = count("select count(*) from weekly_report");
        long submitted = count("select count(*) from weekly_report where status in ('待批阅','已批阅','已退修')");
        long reviewed = count("select count(*) from weekly_report where status = '已批阅'");
        long onTime = count("select count(*) from weekly_report where status = '已批阅' and review_time is not null "
                + "and review_time <= date_add(deadline, interval 2 day)");
        long msTotal = count("select count(*) from internship_milestone");
        long msDone = count("select count(*) from internship_milestone where status = '已完成'");
        long issues = count("select count(*) from internship_issue where status <> '已关闭'");
        BigDecimal avgCompany = jdbc.queryForObject(
                "select coalesce(avg(avg_score),0) from internship_company where avg_score > 0", BigDecimal.class);

        k.put("students", students);
        k.put("reportRate", pct(submitted, reports));
        k.put("reviewRate", pct(onTime, Math.max(1, reviewed)));
        k.put("milestoneRate", pct(msDone, Math.max(1, msTotal)));
        k.put("abnormal", issues);
        k.put("companyScore", avgCompany == null ? 0 : avgCompany.setScale(2, RoundingMode.HALF_UP));
        return k;
    }

    /** 图表数据：每个图给出 labels + values + 对应跳转筛选 */
    private Map<String, Object> charts() {
        Map<String, Object> c = new LinkedHashMap<>();
        c.put("monthlyTrend", group("""
                select date_format(start_date,'%Y-%m') label, count(*) value
                from internship_application where deleted = 0 and start_date >= date_sub(curdate(), interval 6 month)
                group by label order by label"""));
        c.put("stageDist", group("""
                select stage label, count(*) value from internship_application where deleted = 0
                group by stage order by value desc"""));
        c.put("reportWeekly", group("""
                select concat('第',week_no,'周') label,
                       round(sum(case when status in ('待批阅','已批阅','已退修') then 1 else 0 end)*100.0/count(*),1) value
                from weekly_report where week_no <= 8 group by week_no order by week_no"""));
        c.put("industryDist", group("""
                select industry label, count(*) value from internship_company
                group by industry order by value desc limit 6"""));
        c.put("companyScoreRange", group("""
                select case when avg_score >= 4.5 then '4.5 分以上'
                            when avg_score >= 4.0 then '4.0-4.5'
                            when avg_score >= 3.5 then '3.5-4.0'
                            when avg_score > 0 then '3.5 分以下' else '暂无评分' end label,
                       count(*) value
                from internship_company group by label order by value desc"""));
        c.put("scoreDist", group("""
                select grade label, count(*) value from internship_score group by grade
                order by field(grade,'优秀','良好','合格','待改进')"""));
        // 统计看板额外图表
        c.put("cityDist", group("""
                select city label, count(*) value from internship_application where deleted = 0
                group by city order by value desc limit 6"""));
        c.put("positionDist", group("""
                select case when position like '%开发%' then '开发'
                            when position like '%数据%' then '数据'
                            when position like '%测试%' then '测试'
                            when position like '%运维%' then '运维'
                            when position like '%运营%' then '运营'
                            when position like '%设计%' then '设计'
                            else '其他' end label, count(*) value
                from internship_application where deleted = 0 group by label order by value desc"""));
        c.put("issueType", group("""
                select issue_type label, count(*) value from internship_issue group by issue_type order by value desc"""));
        c.put("gradeDist", group("""
                select grade label, count(*) value from final_evaluation
                where grade is not null group by grade order by field(grade,'优秀','良好','合格','待改进')"""));
        return c;
    }

    /** 统计看板附加指标：变更率、异常率、创新采纳率 */
    public Map<String, Object> board() {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("kpi", kpi());
        m.put("charts", charts());
        long apps = Math.max(1, count("select count(*) from internship_application where deleted = 0"));
        long changes = count("select count(*) from internship_change");
        long scores = Math.max(1, count("select count(*) from internship_score"));
        long manual = count("select count(*) from internship_score where manual_grade is not null");
        long reviewed = Math.max(1, count("select count(*) from weekly_report where status = '已批阅'"));
        long onTime = count("select count(*) from weekly_report where status = '已批阅' and review_time is not null "
                + "and review_time <= date_add(deadline, interval 2 day)");
        Map<String, Object> extra = new LinkedHashMap<>();
        extra.put("changeRate", pct(changes, apps));
        extra.put("adoptRate", pct(scores - manual, scores));
        extra.put("adjustRate", pct(manual, scores));
        extra.put("reviewOnTimeRate", pct(onTime, reviewed));
        BigDecimal avgTotal = jdbc.queryForObject(
                "select coalesce(avg(total_score),0) from final_evaluation where total_score is not null", BigDecimal.class);
        extra.put("avgTotalScore", avgTotal == null ? 0 : avgTotal.setScale(1, RoundingMode.HALF_UP));
        m.put("extra", extra);
        return m;
    }

    /** 分组查询统一返回 {labels:[], values:[]} */
    private Map<String, Object> group(String sql) {
        List<Map<String, Object>> rows = jdbc.queryForList(sql);
        List<Object> labels = new ArrayList<>();
        List<Object> values = new ArrayList<>();
        for (Map<String, Object> r : rows) {
            labels.add(r.get("label"));
            values.add(r.get("value"));
        }
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("labels", labels);
        m.put("values", values);
        return m;
    }

    private long count(String sql) {
        Long v = jdbc.queryForObject(sql, Long.class);
        return v == null ? 0 : v;
    }

    private double pct(long a, long b) {
        if (b == 0) {
            return 0;
        }
        return BigDecimal.valueOf(a * 100.0 / b).setScale(1, RoundingMode.HALF_UP).doubleValue();
    }

    /** 我的待办：按角色返回待处理单据数量，用于工作台 */
    public Map<String, Object> todo(Long userId, String role) {
        Map<String, Object> m = new LinkedHashMap<>();
        if ("teacher".equals(role)) {
            m.put("reports", reportMapper.selectCount(new LambdaQueryWrapper<WeeklyReport>()
                    .eq(WeeklyReport::getStatus, "待批阅")));
            m.put("changes", changeMapper.selectCount(new LambdaQueryWrapper<InternshipChange>()
                    .eq(InternshipChange::getCurrentNode, "校内审批")));
            m.put("issues", issueMapper.selectCount(new LambdaQueryWrapper<InternshipIssue>()
                    .eq(InternshipIssue::getStatus, "待处置")));
        } else if ("mentor".equals(role)) {
            m.put("attendances", 0);
            m.put("reports", reportMapper.selectCount(new LambdaQueryWrapper<WeeklyReport>()
                    .eq(WeeklyReport::getStatus, "待批阅")));
        } else {
            m.put("apps", appMapper.selectCount(new LambdaQueryWrapper<InternshipApplication>()
                    .eq(InternshipApplication::getStage, "实习备案").eq(InternshipApplication::getDeleted, 0)));
            m.put("reports", reportMapper.selectCount(new LambdaQueryWrapper<WeeklyReport>()
                    .eq(WeeklyReport::getStatus, "待批阅")));
            m.put("changes", changeMapper.selectCount(new LambdaQueryWrapper<InternshipChange>()
                    .eq(InternshipChange::getCurrentNode, "管理员审批")));
            m.put("issues", issueMapper.selectCount(new LambdaQueryWrapper<InternshipIssue>()
                    .ne(InternshipIssue::getStatus, "已关闭")));
        }
        return m;
    }
}
