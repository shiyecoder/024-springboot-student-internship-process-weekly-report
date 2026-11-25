package com.grad.internship.controller;

import com.grad.internship.common.R;
import com.grad.internship.entity.InternshipRule;
import com.grad.internship.service.ScoreService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/** 创新点：周报里程碑完整度检查 —— 规则配置、计算、留痕、人工修正。 */
@RestController
@RequestMapping("/api/score")
@RequiredArgsConstructor
public class ScoreController {

    private final ScoreService service;

    @GetMapping("/rule/list")
    public R<List<InternshipRule>> rules() {
        return R.ok(service.rules());
    }

    @GetMapping("/rule/current")
    public R<InternshipRule> current() {
        return R.ok(service.currentRule());
    }

    @PostMapping("/rule")
    public R<InternshipRule> saveRule(@RequestBody InternshipRule req) {
        return R.ok(service.saveRule(req));
    }

    @PostMapping("/evaluate/{applicationId}")
    public R<Map<String, Object>> evaluate(@PathVariable Long applicationId,
                                           @RequestParam(required = false) Integer weekNo) {
        return R.ok(service.evaluate(applicationId, weekNo));
    }

    @GetMapping("/history/{applicationId}")
    public R<Map<String, Object>> history(@PathVariable Long applicationId) {
        return R.ok(service.history(applicationId));
    }

    @GetMapping("/latest/{applicationId}")
    public R<Map<String, Object>> latest(@PathVariable Long applicationId) {
        return R.ok(service.latest(applicationId));
    }

    @PostMapping("/{id}/adjust")
    public R<Void> adjust(@PathVariable Long id, @RequestBody Map<String, String> body) {
        service.adjust(id, body.get("grade"), body.get("reason"));
        return R.ok();
    }

    @GetMapping("/stats")
    public R<Map<String, Object>> stats() {
        return R.ok(service.stats());
    }
}
