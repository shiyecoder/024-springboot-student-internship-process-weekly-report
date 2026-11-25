package com.grad.internship.controller;

import com.grad.internship.common.PageResult;
import com.grad.internship.common.R;
import com.grad.internship.entity.MonthlyAttendance;
import com.grad.internship.entity.WeeklyReport;
import com.grad.internship.service.ReportService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/** 周报与考勤接口。 */
@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
public class ReportController {

    private final ReportService service;

    @GetMapping("/report/page")
    public R<PageResult<Map<String, Object>>> page(@RequestParam(defaultValue = "1") int page,
                                                   @RequestParam(defaultValue = "10") int size,
                                                   @RequestParam(required = false) String tab,
                                                   @RequestParam(required = false) String keyword,
                                                   @RequestParam(required = false) Integer weekNo,
                                                   @RequestParam(required = false) String status) {
        return R.ok(service.page(page, size, tab, keyword, weekNo, status));
    }

    @GetMapping("/report/{id}")
    public R<Map<String, Object>> detail(@PathVariable Long id) {
        return R.ok(service.detail(id));
    }

    @PostMapping("/report")
    public R<Long> submit(@RequestBody WeeklyReport req) {
        return R.ok(service.submit(req));
    }

    @PostMapping("/report/{id}/review")
    public R<Void> review(@PathVariable Long id, @RequestBody Map<String, Object> body) {
        boolean pass = Boolean.TRUE.equals(body.get("pass"));
        Integer score = body.get("score") == null ? null : ((Number) body.get("score")).intValue();
        service.review(id, pass, score, (String) body.get("comment"));
        return R.ok();
    }

    @GetMapping("/attendance/page")
    public R<PageResult<Map<String, Object>>> attendance(@RequestParam(defaultValue = "1") int page,
                                                         @RequestParam(defaultValue = "10") int size,
                                                         @RequestParam(required = false) String month,
                                                         @RequestParam(required = false) String company,
                                                         @RequestParam(required = false) String confirmStatus) {
        return R.ok(service.attendancePage(page, size, month, company, confirmStatus));
    }

    @PostMapping("/attendance")
    public R<Long> saveAttendance(@RequestBody MonthlyAttendance req) {
        return R.ok(service.saveAttendance(req));
    }

    @PostMapping("/attendance/{id}/confirm")
    public R<Void> confirm(@PathVariable Long id, @RequestBody Map<String, Object> body) {
        boolean agree = Boolean.TRUE.equals(body.get("agree"));
        service.confirmAttendance(id, agree, (String) body.get("remark"));
        return R.ok();
    }
}
