package com.grad.internship.controller;

import com.grad.internship.common.PageResult;
import com.grad.internship.common.R;
import com.grad.internship.entity.*;
import com.grad.internship.service.FlowService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.Map;

/** 变更、异常、走访、结项评价接口。 */
@RestController
@RequestMapping("/api/flow")
@RequiredArgsConstructor
public class FlowController {

    private final FlowService service;

    @GetMapping("/change/page")
    public R<PageResult<Map<String, Object>>> changePage(@RequestParam(defaultValue = "1") int page,
                                                         @RequestParam(defaultValue = "10") int size,
                                                         @RequestParam(required = false) String type,
                                                         @RequestParam(required = false) String node) {
        return R.ok(service.changePage(page, size, type, node));
    }

    @PostMapping("/change")
    public R<Long> applyChange(@RequestBody InternshipChange req) {
        return R.ok(service.applyChange(req));
    }

    @PostMapping("/change/{id}/approve")
    public R<Void> approve(@PathVariable Long id, @RequestBody Map<String, Object> body) {
        service.approveChange(id, Boolean.TRUE.equals(body.get("pass")), (String) body.get("opinion"));
        return R.ok();
    }

    @GetMapping("/issue/page")
    public R<PageResult<Map<String, Object>>> issuePage(@RequestParam(defaultValue = "1") int page,
                                                        @RequestParam(defaultValue = "10") int size,
                                                        @RequestParam(required = false) String type,
                                                        @RequestParam(required = false) String status) {
        return R.ok(service.issuePage(page, size, type, status));
    }

    @PostMapping("/issue")
    public R<Long> reportIssue(@RequestBody InternshipIssue req) {
        return R.ok(service.reportIssue(req));
    }

    @PostMapping("/issue/{id}/handle")
    public R<Void> handle(@PathVariable Long id, @RequestBody Map<String, Object> body) {
        service.handleIssue(id, (String) body.get("record"), Boolean.TRUE.equals(body.get("close")));
        return R.ok();
    }

    @GetMapping("/visit/page")
    public R<PageResult<Map<String, Object>>> visitPage(@RequestParam(defaultValue = "1") int page,
                                                        @RequestParam(defaultValue = "10") int size,
                                                        @RequestParam(required = false) String type) {
        return R.ok(service.visitPage(page, size, type));
    }

    @PostMapping("/visit")
    public R<Long> saveVisit(@RequestBody VisitRecord req) {
        return R.ok(service.saveVisit(req));
    }

    @GetMapping("/evaluation/page")
    public R<PageResult<Map<String, Object>>> evaluationPage(@RequestParam(defaultValue = "1") int page,
                                                             @RequestParam(defaultValue = "10") int size,
                                                             @RequestParam(required = false) String status,
                                                             @RequestParam(required = false) String keyword) {
        return R.ok(service.evaluationPage(page, size, status, keyword));
    }

    @GetMapping("/evaluation/{applicationId}")
    public R<Map<String, Object>> evaluationDetail(@PathVariable Long applicationId) {
        return R.ok(service.evaluationDetail(applicationId));
    }

    @PostMapping("/evaluation/{applicationId}")
    public R<Map<String, Object>> saveEvaluation(@PathVariable Long applicationId,
                                                 @RequestBody Map<String, Object> body) {
        String companyComment = (String) body.get("companyComment");
        BigDecimal companyScore = body.get("companyScore") == null ? null
                : new BigDecimal(body.get("companyScore").toString());
        Integer schoolScore = body.get("schoolScore") == null ? null
                : ((Number) body.get("schoolScore")).intValue();
        String schoolComment = (String) body.get("schoolComment");
        boolean finalize = Boolean.TRUE.equals(body.get("finalize"));
        return R.ok(service.saveEvaluation(applicationId, companyComment, companyScore, schoolScore, schoolComment, finalize));
    }
}
