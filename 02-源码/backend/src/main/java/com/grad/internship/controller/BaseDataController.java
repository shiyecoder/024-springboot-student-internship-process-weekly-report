package com.grad.internship.controller;

import com.grad.internship.common.PageResult;
import com.grad.internship.common.R;
import com.grad.internship.entity.InternshipBatch;
import com.grad.internship.entity.InternshipCompany;
import com.grad.internship.service.BaseDataService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/** 基础数据：批次与企业库。 */
@RestController
@RequestMapping("/api/base")
@RequiredArgsConstructor
public class BaseDataController {

    private final BaseDataService service;

    @GetMapping("/batch/list")
    public R<List<InternshipBatch>> batches() {
        return R.ok(service.batches());
    }

    @PostMapping("/batch")
    public R<Long> saveBatch(@RequestBody InternshipBatch req) {
        return R.ok(service.saveBatch(req));
    }

    @GetMapping("/company/page")
    public R<PageResult<Map<String, Object>>> companyPage(@RequestParam(defaultValue = "1") int page,
                                                          @RequestParam(defaultValue = "10") int size,
                                                          @RequestParam(required = false) String keyword,
                                                          @RequestParam(required = false) String industry,
                                                          @RequestParam(required = false) String riskStatus) {
        return R.ok(service.companyPage(page, size, keyword, industry, riskStatus));
    }

    @PostMapping("/company")
    public R<Void> saveCompany(@RequestBody InternshipCompany req) {
        service.saveCompany(req);
        return R.ok();
    }

    @DeleteMapping("/company/{id}")
    public R<Void> deleteCompany(@PathVariable Long id) {
        service.deleteCompany(id);
        return R.ok();
    }

    @GetMapping("/company/options")
    public R<List<Map<String, Object>>> companyOptions() {
        return R.ok(service.companyOptions());
    }
}
