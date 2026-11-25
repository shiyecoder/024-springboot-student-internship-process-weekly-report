package com.grad.internship.controller;

import com.grad.internship.common.R;
import com.grad.internship.common.UserContext;
import com.grad.internship.service.DashboardService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/** 首页指标与统计看板。 */
@RestController
@RequestMapping("/api/dashboard")
@RequiredArgsConstructor
public class DashboardController {

    private final DashboardService service;

    @GetMapping
    public R<Map<String, Object>> dashboard(@RequestParam(required = false) String batchNo) {
        return R.ok(service.dashboard(batchNo));
    }

    @GetMapping("/board")
    public R<Map<String, Object>> board() {
        return R.ok(service.board());
    }

    @GetMapping("/todo")
    public R<Map<String, Object>> todo() {
        return R.ok(service.todo(UserContext.userId(), UserContext.roleCode()));
    }
}
