package com.grad.internship.controller;

import com.grad.internship.common.PageResult;
import com.grad.internship.common.R;
import com.grad.internship.entity.InternshipApplication;
import com.grad.internship.service.ApplicationService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * 实习档案接口。路径按需求文档「REST 接口建议」。
 */
@RestController
@RequestMapping("/api/internship-process")
@RequiredArgsConstructor
public class ApplicationController {

    private final ApplicationService service;

    @GetMapping("/page")
    public R<PageResult<Map<String, Object>>> page(@RequestParam(defaultValue = "1") int page,
                                                   @RequestParam(defaultValue = "10") int size,
                                                   @RequestParam(required = false) String keyword,
                                                   @RequestParam(required = false) String department,
                                                   @RequestParam(required = false) String company,
                                                   @RequestParam(required = false) String position,
                                                   @RequestParam(required = false) String stage,
                                                   @RequestParam(required = false) String reportStatus,
                                                   @RequestParam(required = false) String startDate,
                                                   @RequestParam(required = false) String endDate) {
        return R.ok(service.page(page, size, keyword, department, company, position, stage, reportStatus, startDate, endDate));
    }

    @GetMapping("/{id}")
    public R<Map<String, Object>> detail(@PathVariable Long id) {
        return R.ok(service.detail(id));
    }

    @PostMapping
    public R<Long> create(@RequestBody InternshipApplication req) {
        return R.ok(service.create(req));
    }

    @PutMapping("/{id}")
    public R<Void> update(@PathVariable Long id, @RequestBody InternshipApplication req) {
        service.update(id, req);
        return R.ok();
    }

    @PostMapping("/{id}/transition")
    public R<Map<String, Object>> transition(@PathVariable Long id, @RequestBody Map<String, String> body) {
        return R.ok(service.transition(id, body.get("targetStage"), body.get("reason")));
    }

    @PostMapping("/batch-transition")
    public R<List<Map<String, Object>>> batch(@RequestBody Map<String, Object> body) {
        @SuppressWarnings("unchecked")
        List<Integer> raw = (List<Integer>) body.get("ids");
        List<Long> ids = raw.stream().map(x -> x.longValue()).toList();
        return R.ok(service.batchTransition(ids, (String) body.get("targetStage"), (String) body.get("reason")));
    }

    @GetMapping("/options")
    public R<Map<String, Object>> options() {
        return R.ok(service.options());
    }
}
