package com.grad.internship.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.grad.internship.common.BizException;
import com.grad.internship.common.UserContext;
import com.grad.internship.entity.*;
import com.grad.internship.mapper.*;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.util.*;

/**
 * 创新点：周报里程碑完整度检查。
 *
 * 六个输入因素（需求「创新点设计」一节）：
 *   里程碑完成项 / 周报连续性 / 附件数量 / 导师反馈 / 延期任务 / 企业评价，
 * 权重在规则配置页可调且必须合计 100%，修改后生成新版本并记录生效时间。
 *
 * 每次计算都落一条 internship_score：输入快照 + 规则版本 + 各明细得分 + 总分等级 + 生成时间，
 * 保证「相同输入 + 相同规则版本 = 相同结果」，且历史结果可追溯、不被覆盖。
 */
@Service
@RequiredArgsConstructor
public class ScoreService {

    private final InternshipRuleMapper ruleMapper;
    private final InternshipScoreMapper scoreMapper;
    private final InternshipApplicationMapper appMapper;
    private final InternshipMilestoneMapper milestoneMapper;
    private final WeeklyReportMapper reportMapper;
    private final FinalEvaluationMapper evalMapper;
    private final ObjectMapper json = new ObjectMapper();

    // ---------------- 规则配置 ----------------

    public List<InternshipRule> rules() {
        return ruleMapper.selectList(new LambdaQueryWrapper<InternshipRule>()
                .orderByDesc(InternshipRule::getEffectiveTime));
    }

    public InternshipRule currentRule() {
        InternshipRule r = ruleMapper.selectOne(new LambdaQueryWrapper<InternshipRule>()
                .eq(InternshipRule::getEnabled, 1).orderByDesc(InternshipRule::getId).last("limit 1"));
        if (r == null) {
            throw new BizException("缺少可用的完整度规则，请先在规则配置页创建");
        }
        return r;
    }

    /** 保存新版本：权重必须合计 100%，旧版本停用，记录生效时间与操作人 */
    @Transactional
    public InternshipRule saveRule(InternshipRule req) {
        int sum = nz(req.getWeightMilestone()) + nz(req.getWeightContinuity()) + nz(req.getWeightAttachment())
                + nz(req.getWeightFeedback()) + nz(req.getWeightDelay()) + nz(req.getWeightCompany());
        if (sum != 100) {
            throw new BizException("各项权重合计必须等于 100%，当前为 " + sum + "%");
        }
        int maxVer = rules().stream().mapToInt(r -> {
            try {
                return Integer.parseInt(r.getVersion().replace("v", ""));
            } catch (Exception e) {
                return 0;
            }
        }).max().orElse(0);
        ruleMapper.update(null, new LambdaUpdateWrapper<InternshipRule>()
                .eq(InternshipRule::getEnabled, 1).set(InternshipRule::getEnabled, 0));
        req.setId(null);
        req.setVersion("v" + (maxVer + 1));
        req.setRuleName(StringUtils.hasText(req.getRuleName()) ? req.getRuleName() : "周报里程碑完整度检查");
        req.setEnabled(1);
        req.setEffectiveTime(LocalDateTime.now());
        req.setCreateBy(UserContext.realName());
        req.setCreateTime(LocalDateTime.now());
        if (req.getThresholdGood() == null) {
            req.setThresholdGood(new BigDecimal("80"));
        }
        if (req.getThresholdMid() == null) {
            req.setThresholdMid(new BigDecimal("60"));
        }
        ruleMapper.insert(req);
        return req;
    }

    // ---------------- 计算 ----------------

    /**
     * 执行计算：读取业务数据 → 按规则版本打分 → 落库留痕。
     * 缺失的必要数据不参与计算（分母剔除）并在结果里标注，不静默按 0 分处理。
     */
    @Transactional
    public Map<String, Object> evaluate(Long applicationId, Integer weekNo) {
        InternshipApplication app = appMapper.selectById(applicationId);
        if (app == null) {
            throw new BizException("实习档案不存在");
        }
        InternshipRule rule = currentRule();
        int week = weekNo == null ? currentWeek(app) : weekNo;

        List<InternshipMilestone> ms = milestoneMapper.selectList(new LambdaQueryWrapper<InternshipMilestone>()
                .eq(InternshipMilestone::getApplicationId, applicationId).orderByAsc(InternshipMilestone::getSeqNo));
        long msDone = ms.stream().filter(m -> "已完成".equals(m.getStatus())).count();
        int msTotal = ms.size();
        long delayed = ms.stream().filter(m -> "已延期".equals(m.getStatus()) || (m.getDelayedDays() != null && m.getDelayedDays() > 0)).count();

        List<WeeklyReport> reports = reportMapper.selectList(new LambdaQueryWrapper<WeeklyReport>()
                .eq(WeeklyReport::getApplicationId, applicationId).orderByAsc(WeeklyReport::getWeekNo));
        // 连续性：从第 1 周起连续「已批阅/待批阅」且未逾期的周数
        int continuity = 0;
        for (int w = 1; w <= week; w++) {
            final int cw = w;
            boolean ok = reports.stream().anyMatch(r -> Objects.equals(r.getWeekNo(), cw)
                    && !"逾期未交".equals(r.getStatus()) && !"草稿".equals(r.getStatus()));
            if (ok) {
                continuity++;
            } else {
                break;
            }
        }
        WeeklyReport current = reports.stream().filter(r -> Objects.equals(r.getWeekNo(), week)).findFirst().orElse(null);
        int attach = 0;
        if (current != null) {
            if (StringUtils.hasText(current.getAttachmentImage())) {
                attach++;
            }
            if (StringUtils.hasText(current.getAttachmentFile())) {
                attach++;
            }
        }
        // 导师反馈：最近 4 份已批阅周报的平均分（百分制）
        List<Integer> scores = reports.stream().filter(r -> r.getReviewScore() != null)
                .map(WeeklyReport::getReviewScore).toList();
        double feedback = scores.isEmpty() ? -1 : scores.stream()
                .skip(Math.max(0, scores.size() - 4)).mapToInt(Integer::intValue).average().orElse(-1);
        FinalEvaluation eval = evalMapper.selectOne(new LambdaQueryWrapper<FinalEvaluation>()
                .eq(FinalEvaluation::getApplicationId, applicationId).last("limit 1"));
        double company = (eval != null && eval.getCompanyScore() != null) ? eval.getCompanyScore().doubleValue() : -1;

        List<Map<String, Object>> detail = new ArrayList<>();
        double total = 0;
        int weightUsed = 0;
        List<String> missing = new ArrayList<>();

        // 里程碑完成项：完成比例 × 权重
        double msRatio = msTotal == 0 ? 0 : (double) msDone / msTotal;
        total += addDetail(detail, "milestone", "里程碑完成项", msDone + "/" + msTotal,
                rule.getWeightMilestone(), msRatio, "已完成 " + msDone + " 项里程碑");
        weightUsed += rule.getWeightMilestone();

        double contRatio = Math.min(1.0, continuity / 8.0);
        total += addDetail(detail, "continuity", "周报连续性", "连续 " + continuity + " 周",
                rule.getWeightContinuity(), contRatio, continuity >= 4 ? "无缺交、无逾期" : "存在缺交或逾期");
        weightUsed += rule.getWeightContinuity();

        double attRatio = Math.min(1.0, attach / 2.0);
        total += addDetail(detail, "attachment", "附件数量", attach + " 个",
                rule.getWeightAttachment(), attRatio, attach >= 1 ? "附件数量满足要求" : "本周未上传附件");
        weightUsed += rule.getWeightAttachment();

        if (feedback < 0) {
            missing.add("导师反馈");
        } else {
            total += addDetail(detail, "feedback", "导师反馈", String.format("%.1f 分", feedback),
                    rule.getWeightFeedback(), feedback / 100.0, "最近 4 次批阅平均分");
            weightUsed += rule.getWeightFeedback();
        }

        // 延期任务：0 项满分，1 项 60%，2 项及以上 0 分
        double delayRatio = delayed == 0 ? 1.0 : delayed == 1 ? 0.6 : 0.0;
        total += addDetail(detail, "delay", "延期任务", delayed + " 项",
                rule.getWeightDelay(), delayRatio, delayed == 0 ? "无延期任务" : "存在延期任务 " + delayed + " 项");
        weightUsed += rule.getWeightDelay();

        if (company < 0) {
            missing.add("企业评价");
        } else {
            total += addDetail(detail, "company", "企业评价", String.format("%.1f 分", company),
                    rule.getWeightCompany(), company / 5.0, "企业导师评价（5 分制）");
            weightUsed += rule.getWeightCompany();
        }

        // 缺失项剔除后按实际参与权重归一，避免「缺数据等于低分」
        double normalized = weightUsed == 0 ? 0 : total / weightUsed * 100.0;
        double finalScore = round1(Math.min(100, normalized));
        String grade = gradeOf(finalScore, rule);

        Map<String, Object> snapshot = new LinkedHashMap<>();
        snapshot.put("applicationId", applicationId);
        snapshot.put("weekNo", week);
        snapshot.put("milestoneDone", msDone);
        snapshot.put("milestoneTotal", msTotal);
        snapshot.put("continuityWeeks", continuity);
        snapshot.put("attachmentCount", attach);
        snapshot.put("feedbackScore", feedback < 0 ? null : round1(feedback));
        snapshot.put("delayCount", delayed);
        snapshot.put("companyScore", company < 0 ? null : company);
        snapshot.put("missing", missing);

        List<String> unsatisfied = new ArrayList<>();
        if (delayed > 0) {
            unsatisfied.add("延期任务 " + delayed + " 项，超过「无延期」要求");
        }
        if (attach == 0) {
            unsatisfied.add("本周未上传任何附件");
        }
        if (!missing.isEmpty()) {
            unsatisfied.add("缺少数据：" + String.join("、", missing));
        }
        String advice = buildAdvice(msDone, msTotal, attach, delayed, continuity);
        String explain = buildExplain(detail, finalScore, grade, unsatisfied, advice);

        InternshipScore s = new InternshipScore();
        s.setApplicationId(applicationId);
        s.setStudentName(app.getStudentName());
        s.setRuleId(rule.getId());
        s.setRuleVersion(rule.getVersion());
        s.setInputJson(toJson(snapshot));
        s.setDetailJson(toJson(detail));
        s.setTotalScore(BigDecimal.valueOf(finalScore));
        s.setGrade(grade);
        s.setAdvice(advice);
        s.setCalcWeek(week);
        s.setCalcTime(LocalDateTime.now());
        scoreMapper.insert(s);

        Map<String, Object> r = new LinkedHashMap<>();
        r.put("id", s.getId());
        r.put("totalScore", finalScore);
        r.put("grade", grade);
        r.put("ruleVersion", rule.getVersion());
        r.put("ruleId", rule.getId());
        r.put("weekNo", week);
        r.put("detail", detail);
        r.put("snapshot", snapshot);
        r.put("unsatisfied", unsatisfied);
        r.put("advice", advice);
        r.put("explain", explain);
        r.put("calcTime", s.getCalcTime());
        return r;
    }

    private double addDetail(List<Map<String, Object>> detail, String key, String label, String value,
                             Integer weight, double ratio, String note) {
        double sc = round1(weight * Math.max(0, Math.min(1, ratio)));
        Map<String, Object> d = new LinkedHashMap<>();
        d.put("key", key);
        d.put("label", label);
        d.put("value", value);
        d.put("weight", weight);
        d.put("score", sc);
        d.put("note", note);
        detail.add(d);
        return sc;
    }

    private String gradeOf(double score, InternshipRule rule) {
        double good = rule.getThresholdGood() == null ? 80 : rule.getThresholdGood().doubleValue();
        double mid = rule.getThresholdMid() == null ? 60 : rule.getThresholdMid().doubleValue();
        if (score >= 90) {
            return "优秀";
        }
        if (score >= good) {
            return "良好";
        }
        if (score >= mid) {
            return "合格";
        }
        return "待改进";
    }

    private String buildAdvice(long done, int total, int attach, long delayed, int continuity) {
        List<String> a = new ArrayList<>();
        if (done < total) {
            a.add("剩余 " + (total - done) + " 项里程碑拆成两个子任务并提前一周排期");
        }
        if (attach < 2) {
            a.add("补充接口文档或测试记录作为周报附件");
        }
        if (delayed > 0) {
            a.add("与导师确认延期原因并重排计划");
        }
        if (continuity < 4) {
            a.add("恢复每周按时提交周报，避免连续性中断");
        }
        return a.isEmpty() ? "保持当前节奏，无需改进" : String.join("；", a);
    }

    private String buildExplain(List<Map<String, Object>> detail, double score, String grade,
                                List<String> unsatisfied, String advice) {
        Map<String, Object> top = detail.stream()
                .max(Comparator.comparingDouble(d -> ((Number) d.get("score")).doubleValue()))
                .orElse(null);
        StringBuilder sb = new StringBuilder();
        sb.append("综合得分 ").append(score).append("，等级「").append(grade).append("」。");
        if (top != null) {
            sb.append("主要影响因素：").append(top.get("label")).append("（")
              .append(top.get("score")).append(" / ").append(top.get("weight")).append("）。");
        }
        if (unsatisfied.isEmpty()) {
            sb.append("未发现未满足条件。");
        } else {
            sb.append("未满足条件：").append(String.join("；", unsatisfied)).append("。");
        }
        sb.append("可改进项：").append(advice).append("。");
        return sb.toString();
    }

    private int currentWeek(InternshipApplication app) {
        if (app.getStartDate() == null) {
            return 1;
        }
        long days = java.time.temporal.ChronoUnit.DAYS.between(app.getStartDate(), java.time.LocalDate.now());
        return (int) Math.max(1, Math.min(26, days / 7 + 1));
    }

    private double round1(double v) {
        return BigDecimal.valueOf(v).setScale(1, RoundingMode.HALF_UP).doubleValue();
    }

    private int nz(Integer v) {
        return v == null ? 0 : v;
    }

    // ---------------- 结果查询与人工修正 ----------------

    public Map<String, Object> history(Long applicationId) {
        List<InternshipScore> list = scoreMapper.selectList(new LambdaQueryWrapper<InternshipScore>()
                .eq(InternshipScore::getApplicationId, applicationId)
                .orderByDesc(InternshipScore::getCalcWeek).orderByDesc(InternshipScore::getId));
        List<Map<String, Object>> rows = new ArrayList<>();
        for (InternshipScore s : list) {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("id", s.getId());
            m.put("weekNo", s.getCalcWeek());
            m.put("totalScore", s.getTotalScore());
            m.put("grade", s.getGrade());
            m.put("ruleVersion", s.getRuleVersion());
            m.put("calcTime", s.getCalcTime());
            m.put("manualGrade", s.getManualGrade());
            m.put("manualReason", s.getManualReason());
            m.put("manualBy", s.getManualBy());
            m.put("manualTime", s.getManualTime());
            rows.add(m);
        }
        Map<String, Object> r = new LinkedHashMap<>();
        r.put("records", rows);
        if (!list.isEmpty()) {
            InternshipScore latest = list.get(0);
            Map<String, Object> l = new LinkedHashMap<>();
            l.put("id", latest.getId());
            l.put("weekNo", latest.getCalcWeek());
            l.put("totalScore", latest.getTotalScore());
            l.put("grade", latest.getGrade());
            l.put("ruleVersion", latest.getRuleVersion());
            l.put("detail", readJson(latest.getDetailJson()));
            l.put("snapshot", readJson(latest.getInputJson()));
            l.put("advice", latest.getAdvice());
            l.put("calcTime", latest.getCalcTime());
            l.put("manualGrade", latest.getManualGrade());
            l.put("manualReason", latest.getManualReason());
            l.put("manualBy", latest.getManualBy());
            l.put("manualTime", latest.getManualTime());
            l.put("unsatisfied", calcUnsatisfied(latest.getDetailJson()));
            r.put("latest", l);
        }
        return r;
    }

    /** 最新一次计算详情：明细分 + 解释 + 快照，供里程碑进度页展示 */
    public Map<String, Object> latest(Long applicationId) {
        InternshipScore s = scoreMapper.selectOne(new LambdaQueryWrapper<InternshipScore>()
                .eq(InternshipScore::getApplicationId, applicationId)
                .orderByDesc(InternshipScore::getCalcWeek).orderByDesc(InternshipScore::getId).last("limit 1"));
        if (s == null) {
            return evaluate(applicationId, currentWeek(appMapper.selectById(applicationId)));
        }
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", s.getId());
        m.put("totalScore", s.getTotalScore());
        m.put("grade", s.getGrade());
        m.put("ruleVersion", s.getRuleVersion());
        m.put("weekNo", s.getCalcWeek());
        m.put("advice", s.getAdvice());
        m.put("calcTime", s.getCalcTime());
        m.put("detail", readJson(s.getDetailJson()));
        m.put("snapshot", readJson(s.getInputJson()));
        m.put("manualGrade", s.getManualGrade());
        m.put("manualReason", s.getManualReason());
        m.put("manualBy", s.getManualBy());
        m.put("manualTime", s.getManualTime());
        m.put("unsatisfied", calcUnsatisfied(s.getDetailJson()));
        return m;
    }

    private List<String> calcUnsatisfied(String detailJson) {
        List<String> out = new ArrayList<>();
        Object d = readJson(detailJson);
        if (d instanceof List<?> list) {
            for (Object o : list) {
                if (o instanceof Map<?, ?> m) {
                    String key = String.valueOf(m.get("key"));
                    if ("delay".equals(key) && !"0 项".equals(String.valueOf(m.get("value")))) {
                        out.add("延期任务 " + m.get("value") + "，超过「无延期」要求");
                    }
                    if ("attachment".equals(key) && "0 个".equals(String.valueOf(m.get("value")))) {
                        out.add("本周未上传任何附件");
                    }
                }
            }
        }
        return out;
    }

    /** 人工修正：必须填原因，原始计算结果不覆盖（单独字段保存） */
    @Transactional
    public void adjust(Long id, String grade, String reason) {
        if (!StringUtils.hasText(reason) || reason.trim().length() < 5) {
            throw new BizException("人工调整必须填写不少于 5 个字的原因");
        }
        InternshipScore s = scoreMapper.selectById(id);
        if (s == null) {
            throw new BizException("计算记录不存在");
        }
        s.setManualGrade(grade);
        s.setManualReason(reason.trim());
        s.setManualBy(UserContext.realName());
        s.setManualTime(LocalDateTime.now());
        scoreMapper.updateById(s);
    }

    /** 看板统计：等级分布、推荐采纳率与人工调整率 */
    public Map<String, Object> stats() {
        List<InternshipScore> all = scoreMapper.selectList(new LambdaQueryWrapper<>());
        Map<String, Integer> dist = new LinkedHashMap<>();
        for (String g : List.of("优秀", "良好", "合格", "待改进")) {
            dist.put(g, 0);
        }
        int manual = 0;
        for (InternshipScore s : all) {
            dist.merge(s.getGrade(), 1, Integer::sum);
            if (StringUtils.hasText(s.getManualGrade())) {
                manual++;
            }
        }
        Map<String, Object> r = new LinkedHashMap<>();
        r.put("distribution", dist);
        r.put("total", all.size());
        r.put("adoptRate", all.isEmpty() ? 0 : round1((all.size() - manual) * 100.0 / all.size()));
        r.put("adjustRate", all.isEmpty() ? 0 : round1(manual * 100.0 / all.size()));
        return r;
    }

    private String toJson(Object o) {
        try {
            return json.writeValueAsString(o);
        } catch (Exception e) {
            return "{}";
        }
    }

    private Object readJson(String s) {
        if (!StringUtils.hasText(s)) {
            return null;
        }
        try {
            return json.readValue(s, new TypeReference<Object>() { });
        } catch (Exception e) {
            return null;
        }
    }
}
