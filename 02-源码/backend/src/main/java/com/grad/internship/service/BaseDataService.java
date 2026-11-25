package com.grad.internship.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.grad.internship.common.BizException;
import com.grad.internship.common.PageResult;
import com.grad.internship.entity.*;
import com.grad.internship.mapper.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.time.LocalDateTime;
import java.util.*;

/** 基础数据：实习批次与企业库。 */
@Service
@RequiredArgsConstructor
public class BaseDataService {

    private final InternshipBatchMapper batchMapper;
    private final InternshipCompanyMapper companyMapper;
    private final InternshipApplicationMapper appMapper;

    // ---------------- 批次 ----------------

    public List<InternshipBatch> batches() {
        return batchMapper.selectList(new LambdaQueryWrapper<InternshipBatch>()
                .orderByDesc(InternshipBatch::getStartDate));
    }

    @Transactional
    public Long saveBatch(InternshipBatch req) {
        if (!StringUtils.hasText(req.getBatchNo())) {
            throw new BizException("批次编号必填");
        }
        if (req.getStartDate() != null && req.getEndDate() != null && req.getEndDate().isBefore(req.getStartDate())) {
            throw new BizException("结束日期不能早于开始日期");
        }
        Long dup = batchMapper.selectCount(new LambdaQueryWrapper<InternshipBatch>()
                .eq(InternshipBatch::getBatchNo, req.getBatchNo().trim())
                .ne(req.getId() != null, InternshipBatch::getId, req.getId()));
        if (dup != null && dup > 0) {
            throw new BizException("批次编号已存在");
        }
        if (req.getId() == null) {
            req.setCreateTime(LocalDateTime.now());
            req.setStatus(StringUtils.hasText(req.getStatus()) ? req.getStatus() : "启用");
            batchMapper.insert(req);
        } else {
            batchMapper.updateById(req);
        }
        return req.getId();
    }

    // ---------------- 企业库 ----------------

    public PageResult<Map<String, Object>> companyPage(int page, int size, String keyword, String industry,
                                                       String riskStatus) {
        LambdaQueryWrapper<InternshipCompany> q = new LambdaQueryWrapper<>();
        if (StringUtils.hasText(keyword)) {
            q.and(w -> w.like(InternshipCompany::getCompanyName, keyword)
                    .or().like(InternshipCompany::getContact, keyword));
        }
        q.eq(StringUtils.hasText(industry), InternshipCompany::getIndustry, industry);
        q.eq(StringUtils.hasText(riskStatus), InternshipCompany::getRiskStatus, riskStatus);
        q.orderByAsc(InternshipCompany::getCompanyNo);
        Page<InternshipCompany> p = companyMapper.selectPage(new Page<>(page, size), q);
        List<Map<String, Object>> rows = new ArrayList<>();
        for (InternshipCompany c : p.getRecords()) {
            rows.add(toMap(c));
        }
        return PageResult.of(p.getTotal(), page, size, rows);
    }

    private Map<String, Object> toMap(InternshipCompany c) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", c.getId());
        m.put("companyNo", c.getCompanyNo());
        m.put("companyName", c.getCompanyName());
        m.put("industry", c.getIndustry());
        m.put("address", c.getAddress());
        m.put("city", c.getCity());
        m.put("contact", c.getContact());
        m.put("phone", c.getPhone());
        m.put("scale", c.getScale());
        m.put("pastStudents", c.getPastStudents());
        m.put("avgScore", c.getAvgScore());
        m.put("riskStatus", c.getRiskStatus());
        m.put("licenseImage", c.getLicenseImage());
        m.put("intro", c.getIntro());
        m.put("createTime", c.getCreateTime());
        return m;
    }

    /** 删除前检查是否被实习档案引用（需求：删除主数据前检查引用） */
    @Transactional
    public void saveCompany(InternshipCompany req) {
        if (!StringUtils.hasText(req.getCompanyName())) {
            throw new BizException("企业名称必填");
        }
        if (!StringUtils.hasText(req.getLicenseImage())) {
            throw new BizException("请上传企业资质或办公环境图片");
        }
        if (req.getId() == null) {
            if (!StringUtils.hasText(req.getCompanyNo())) {
                long n = companyMapper.selectCount(null) + 1;
                req.setCompanyNo(String.format("C%04d", n));
            }
            req.setCreateTime(LocalDateTime.now());
            if (req.getPastStudents() == null) {
                req.setPastStudents(0);
            }
            if (req.getAvgScore() == null) {
                req.setAvgScore(java.math.BigDecimal.ZERO);
            }
            if (!StringUtils.hasText(req.getRiskStatus())) {
                req.setRiskStatus("正常");
            }
            companyMapper.insert(req);
        } else {
            companyMapper.updateById(req);
        }
    }

    @Transactional
    public void deleteCompany(Long id) {
        Long used = appMapper.selectCount(new LambdaQueryWrapper<InternshipApplication>()
                .eq(InternshipApplication::getCompanyId, id));
        if (used != null && used > 0) {
            throw new BizException("该企业已被 " + used + " 条实习档案引用，不能删除");
        }
        companyMapper.deleteById(id);
    }

    /** 企业下拉选项 */
    public List<Map<String, Object>> companyOptions() {
        List<Map<String, Object>> list = new ArrayList<>();
        for (InternshipCompany c : companyMapper.selectList(new LambdaQueryWrapper<InternshipCompany>()
                .orderByAsc(InternshipCompany::getCompanyNo))) {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("id", c.getId());
            m.put("companyName", c.getCompanyName());
            m.put("industry", c.getIndustry());
            m.put("city", c.getCity());
            m.put("riskStatus", c.getRiskStatus());
            m.put("licenseImage", c.getLicenseImage());
            list.add(m);
        }
        return list;
    }
}
